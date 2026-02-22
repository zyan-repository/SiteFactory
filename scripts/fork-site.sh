#!/usr/bin/env bash
# fork-site.sh - Fork a GitHub project and adapt it for SiteFactory.
# Usage: ./scripts/fork-site.sh <github-url> <site-name> ["Site Title"] ["Description"] [language]
#
# Steps:
# 1. Run compatibility check
# 2. Clone and strip .git
# 3. Inject AdSense, Analytics, SEO meta (with full OG, canonical, JSON-LD)
# 4. Add privacy policy and about pages (language-aware)
# 5. Create ads.txt and site.yaml
# 6. Add license attribution
# 7. Register in theme data/sites.yaml

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/platform.sh"
source "$REPO_ROOT/scripts/lib/inject.sh"

REPO_URL="${1:?Usage: fork-site.sh <github-url> <site-name> [\"title\"] [\"description\"] [language]}"
SITE_NAME="${2:?Please provide a site name}"
SITE_TITLE="${3:-$SITE_NAME}"
SITE_DESC="${4:-A useful web tool}"
SITE_LANG="${5:-en}"

SITE_DIR="$REPO_ROOT/sites/$SITE_NAME"

# Validate site name
if [[ ! "$SITE_NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  log_error "Site name must be lowercase alphanumeric with hyphens (e.g., 'web-weather')"
  exit 1
fi

if [[ -d "$SITE_DIR" ]]; then
  log_error "Site '$SITE_NAME' already exists at $SITE_DIR"
  exit 1
fi

# Load config
if [[ -f "$REPO_ROOT/config.yaml" ]]; then
  source "$REPO_ROOT/scripts/lib/config.sh"
else
  log_warn "config.yaml not found, using defaults (no AdSense/Analytics injection)"
  SF_DOMAIN="example.com"
  SF_ADSENSE_PUB_ID=""
  SF_GA_ID=""
  SF_AUTHOR_EMAIL=""
fi

DATE=$(date +%Y-%m-%d)
SITE_URL="https://${SITE_NAME}.${SF_DOMAIN}/"

# Step 1: Compatibility check
log_info "=== Forking: $REPO_URL ==="
log_step "Running compatibility check..."
if ! "$REPO_ROOT/scripts/check-repo.sh" "$REPO_URL"; then
  log_error "Compatibility check failed. Aborting."
  exit 1
fi
echo ""

# Step 2: Clone
log_step "Cloning repository..."
git clone --depth 1 --quiet --recurse-submodules --shallow-submodules "$REPO_URL" "$SITE_DIR"
rm -rf "$SITE_DIR/.git"

# Clean up upstream artifacts that don't belong in our deployment
rm -f "$SITE_DIR/CNAME" "$SITE_DIR/.gitmodules" "$SITE_DIR/.nojekyll"
# Remove Google site verification files from the original project
find "$SITE_DIR" -maxdepth 1 -name "google*.html" -size -1k -delete

# Detect license
LICENSE_TYPE="Unknown"
for f in LICENSE LICENSE.md LICENSE.txt LICENCE; do
  if [[ -f "$SITE_DIR/$f" ]]; then
    if head -5 "$SITE_DIR/$f" | grep -qi "mit"; then
      LICENSE_TYPE="MIT"
    elif head -5 "$SITE_DIR/$f" | grep -qi "apache"; then
      LICENSE_TYPE="Apache-2.0"
    elif head -5 "$SITE_DIR/$f" | grep -qi "bsd"; then
      LICENSE_TYPE="BSD"
    fi
    break
  fi
done

# Step 3: Inject AdSense + Analytics + full SEO into all HTML files
log_step "Injecting AdSense, Analytics, and SEO meta..."
INJECT_COUNT=0
while IFS= read -r html_file; do
  inject_all "$html_file" "$SF_ADSENSE_PUB_ID" "$SF_GA_ID" "$SITE_TITLE" "$SITE_DESC" \
    "$SITE_URL" "$SITE_TITLE" "$SF_DOMAIN"
  INJECT_COUNT=$((INJECT_COUNT + 1))
done < <(find "$SITE_DIR" -name "*.html" -maxdepth 2 -type f)
if [[ "$INJECT_COUNT" -eq 0 ]]; then
  log_warn "No HTML files found in $SITE_DIR (depth <= 2). AdSense/Analytics not injected."
  log_warn "The forked project may require a build step first."
fi

# Step 4: Add compliance pages (language-aware)
log_step "Adding compliance pages..."
SHARED_DIR="$REPO_ROOT/sites/_shared"

for base_page in privacy-policy about; do
  # Try language-specific version, fall back to English
  local_page="${base_page}.${SITE_LANG}.html"
  if [[ ! -f "$SHARED_DIR/$local_page" ]]; then
    local_page="${base_page}.en.html"
  fi
  if [[ -f "$SHARED_DIR/$local_page" ]]; then
    cp "$SHARED_DIR/$local_page" "$SITE_DIR/${base_page}.html"
    sed_inplace \
      -e "s|{{SITE_TITLE}}|${SITE_TITLE}|g" \
      -e "s|{{AUTHOR_EMAIL}}|${SF_AUTHOR_EMAIL}|g" \
      -e "s|{{DATE}}|${DATE}|g" \
      -e "s|{{DOMAIN}}|${SF_DOMAIN}|g" \
      -e "s|{{LANGUAGE}}|${SITE_LANG}|g" \
      "$SITE_DIR/${base_page}.html"
    log_ok "  Added ${base_page}.html (${local_page})"
  fi
done

# Step 5: Generate OG image
source "$REPO_ROOT/scripts/lib/og-image.sh"
log_step "Generating OG image..."
if generate_og_image "$SITE_TITLE" "$SITE_DIR/og-default.png"; then
  log_ok "  OG image generated"
else
  log_warn "  OG image generation failed (non-critical)"
fi

# Step 6: Create ads.txt
PUB_NUMERIC="${SF_ADSENSE_PUB_ID#ca-pub-}"
if [[ -n "$PUB_NUMERIC" ]] && [[ "$PUB_NUMERIC" != *"XXXX"* ]]; then
  echo "google.com, $PUB_NUMERIC, DIRECT, f08c47fec0942fa0" > "$SITE_DIR/ads.txt"
  log_ok "  Created ads.txt"
fi

# Step 7: Create site.yaml
cat > "$SITE_DIR/site.yaml" << EOF
type: static
name: ${SITE_NAME}
title: "${SITE_TITLE}"
description: "${SITE_DESC}"
source: ${REPO_URL}
license: ${LICENSE_TYPE}
language: ${SITE_LANG}
created: ${DATE}
EOF
log_ok "  Created site.yaml"

# Step 8: Add attribution to README
if [[ -f "$SITE_DIR/README.md" ]]; then
  # Prepend attribution
  TMPFILE=$(mktemp)
  cat > "$TMPFILE" << EOF
> **Note**: This site is adapted from [$(basename "$REPO_URL")](${REPO_URL})
> under the ${LICENSE_TYPE} license. Original copyright and license terms apply.
> Modified by SiteFactory for deployment and monetization.

---

EOF
  cat "$SITE_DIR/README.md" >> "$TMPFILE"
  mv "$TMPFILE" "$SITE_DIR/README.md"
  log_ok "  Added attribution to README.md"
fi

# Step 9: Register in theme data/sites.yaml
SITES_YAML="$REPO_ROOT/themes/sitefactory/data/sites.yaml"
if [[ -f "$SITES_YAML" ]] && command -v yq &>/dev/null; then
  if ! yq -e ".sites[] | select(.name == \"$SITE_NAME\")" "$SITES_YAML" &>/dev/null; then
    yq -i ".sites += [{\"name\": \"$SITE_NAME\", \"title\": \"$SITE_TITLE\", \"description\": \"$SITE_DESC\", \"type\": \"static\", \"category\": \"tool\", \"language\": \"$SITE_LANG\"}]" "$SITES_YAML"

    # Generate multilingual titles via LLM
    if [[ -f "$REPO_ROOT/config.yaml" ]]; then
      source "$REPO_ROOT/scripts/lib/config.sh"
      source "$REPO_ROOT/scripts/lib/llm.sh"
      if [[ -n "${SF_AI_API_KEY:-}" && "$SF_AI_API_KEY" != *"XXXX"* ]]; then
        log_info "  Generating multilingual titles via LLM..."
        LANGS=("en" "zh" "ja")
        TITLES_JSON=$(llm_generate \
          "You are a translator. Output ONLY valid JSON with no extra text." \
          "Translate this site title into 3 languages. Title: \"$SITE_TITLE\" (original language: $SITE_LANG). Return JSON: {\"en\": \"...\", \"zh\": \"...\", \"ja\": \"...\"}" \
          2>/dev/null || echo "")
        if [[ -n "$TITLES_JSON" ]] && echo "$TITLES_JSON" | jq -e . &>/dev/null; then
          for lang in "${LANGS[@]}"; do
            lang_title=$(echo "$TITLES_JSON" | jq -r ".${lang} // empty")
            if [[ -n "$lang_title" ]]; then
              yq -i "(.sites[] | select(.name == \"$SITE_NAME\")).titles.$lang = \"$lang_title\"" "$SITES_YAML"
            fi
          done
          log_ok "  Multilingual titles generated"
        else
          log_warn "  LLM title translation failed, using original title only"
        fi
      fi
    fi

    log_ok "  Registered in theme data/sites.yaml"
  else
    log_info "  Already registered in data/sites.yaml"
  fi
fi

log_ok "=== Fork complete: $SITE_NAME ==="
echo ""
echo "  Directory: sites/$SITE_NAME"
echo "  Deploy:    ./scripts/deploy.sh $SITE_NAME"
echo "  Preview:   open sites/$SITE_NAME/index.html"
