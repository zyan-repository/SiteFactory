#!/usr/bin/env bash
# new-site.sh - Create a new Hugo site from the template.
# Usage: ./scripts/new-site.sh <site-name> "<Site Title>" "<Description>" [language]
#
# Steps:
# 1. Copies _template/ to sites/<site-name>/
# 2. Replaces placeholder values with real config
# 3. Creates site.yaml metadata
# (DNS + Vercel deploy handled by deploy.sh separately)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/platform.sh"

SITE_NAME="${1:?Usage: new-site.sh <site-name> \"<title>\" \"<description>\" [language]}"
SITE_TITLE="${2:?Please provide a site title}"
SITE_DESC="${3:?Please provide a site description}"
SITE_LANG="${4:-en}"

SITE_DIR="$REPO_ROOT/sites/$SITE_NAME"
TEMPLATE_DIR="$REPO_ROOT/sites/_template"

# Validate site name
if [[ ! "$SITE_NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
  log_error "Site name must be lowercase alphanumeric with hyphens (e.g., 'tech-tips')"
  exit 1
fi

if [[ -d "$SITE_DIR" ]]; then
  log_error "Site '$SITE_NAME' already exists at $SITE_DIR"
  exit 1
fi

# Load config if available
if [[ -f "$REPO_ROOT/config.yaml" ]]; then
  source "$REPO_ROOT/scripts/lib/config.sh"
else
  log_warn "config.yaml not found, using defaults"
  SF_DOMAIN="example.com"
  SF_ADSENSE_PUB_ID=""
  SF_ADSENSE_ENABLED="false"
  SF_GA_ID=""
  SF_GSC_VERIFICATION=""
  SF_AUTHOR_NAME="Author"
  SF_AUTHOR_EMAIL=""
fi

DATE=$(date +%Y-%m-%d)

# Step 1: Copy template (only content, static, config — layouts/assets/i18n come from theme)
log_step "Copying template..."
mkdir -p "$SITE_DIR"
for item in content static hugo.toml archetypes; do
  if [[ -e "$TEMPLATE_DIR/$item" ]]; then
    cp -r "$TEMPLATE_DIR/$item" "$SITE_DIR/$item"
  fi
done

# Step 2: Configure hugo.toml
log_step "Configuring site..."
PUB_NUMERIC="${SF_ADSENSE_PUB_ID#ca-pub-}"

# Replace values in hugo.toml
sed_inplace \
  -e "s|SITE_NAME.example.com|${SITE_NAME}.${SF_DOMAIN}|g" \
  -e "s|languageCode = \"en\"|languageCode = \"${SITE_LANG}\"|g" \
  -e "s|title = \"Site Title\"|title = \"${SITE_TITLE}\"|g" \
  -e "s|description = \"Site description goes here\"|description = \"${SITE_DESC}\"|g" \
  -e "s|author = \"Author Name\"|author = \"${SF_AUTHOR_NAME}\"|g" \
  -e "s|adsenseEnabled = false|adsenseEnabled = ${SF_ADSENSE_ENABLED}|g" \
  -e "s|adsensePubId = \"\"|adsensePubId = \"${SF_ADSENSE_PUB_ID}\"|g" \
  -e "s|googleAnalyticsId = \"\"|googleAnalyticsId = \"${SF_GA_ID}\"|g" \
  -e "s|googleSearchConsoleVerification = \"\"|googleSearchConsoleVerification = \"${SF_GSC_VERIFICATION}\"|g" \
  -e "s|siteName = \"\"|siteName = \"${SITE_NAME}\"|g" \
  "$SITE_DIR/hugo.toml"

# Replace placeholders in content files
find "$SITE_DIR/content" -name "*.md" -type f | while read -r file; do
  sed_inplace \
    -e "s|{{SITE_TITLE}}|${SITE_TITLE}|g" \
    -e "s|{{SITE_NAME}}|${SITE_NAME}|g" \
    -e "s|{{SITE_DESCRIPTION}}|${SITE_DESC}|g" \
    -e "s|{{AUTHOR_NAME}}|${SF_AUTHOR_NAME}|g" \
    -e "s|{{AUTHOR_EMAIL}}|${SF_AUTHOR_EMAIL}|g" \
    -e "s|{{DATE}}|${DATE}|g" \
    "$file"
done

# Replace in ads.txt
if [[ -n "$PUB_NUMERIC" ]]; then
  sed_inplace "s|{{ADSENSE_PUB_ID_NUMERIC}}|${PUB_NUMERIC}|g" "$SITE_DIR/static/ads.txt"
else
  echo "# AdSense ads.txt - configure publisher ID in config.yaml" > "$SITE_DIR/static/ads.txt"
fi

# Step 3: Create site.yaml
cat > "$SITE_DIR/site.yaml" << EOF
type: hugo
name: ${SITE_NAME}
title: "${SITE_TITLE}"
description: "${SITE_DESC}"
source: template
language: ${SITE_LANG}
created: ${DATE}
EOF

# Step 4: Generate OG image
source "$REPO_ROOT/scripts/lib/og-image.sh"
log_step "Generating OG image..."
if generate_og_image "$SITE_TITLE" "$SITE_DIR/static/og-default.png"; then
  log_ok "  OG image generated"
else
  log_warn "  OG image generation failed (non-critical)"
fi

# Step 5: Register in theme data/sites.yaml
SITES_YAML="$REPO_ROOT/themes/sitefactory/data/sites.yaml"
if [[ -f "$SITES_YAML" ]] && command -v yq &>/dev/null; then
  if ! yq -e ".sites[] | select(.name == \"$SITE_NAME\")" "$SITES_YAML" &>/dev/null; then
    yq -i ".sites += [{\"name\": \"$SITE_NAME\", \"title\": \"$SITE_TITLE\", \"description\": \"$SITE_DESC\", \"type\": \"hugo\", \"category\": \"content\"}]" "$SITES_YAML"
    log_ok "  Registered in theme data/sites.yaml"
  fi
fi

# Step 5: AI content generation (optional, requires AI config)
# Content plans are stored in content-plans/ (outside sites/)
if [[ -f "$REPO_ROOT/config.yaml" ]] && command -v yq &>/dev/null; then
  AI_KEY=$(yq ".ai.providers.$(yq '.ai.provider' "$REPO_ROOT/config.yaml").api_key // \"\"" "$REPO_ROOT/config.yaml" 2>/dev/null || echo "")
  if [[ -n "$AI_KEY" && "$AI_KEY" != "null" && "$AI_KEY" != *"XXXX"* ]]; then
    # Use global defaults from config.yaml (content.default_*)
    TOPIC_COUNT=$(yq '.content.default_topic_count // "25"' "$REPO_ROOT/config.yaml")
    SEED_COUNT=$(yq '.content.default_seed_articles // "5"' "$REPO_ROOT/config.yaml")
    SCHEDULE=$(yq '.content.default_schedule // "weekly"' "$REPO_ROOT/config.yaml")

    log_step "Generating content plan via AI..."
    "$REPO_ROOT/scripts/generate-content-plan.sh" "$SITE_NAME" "$TOPIC_COUNT" "$SCHEDULE" \
      || log_warn "Content plan generation failed (non-critical)"

    log_step "Generating seed content via AI..."
    "$REPO_ROOT/scripts/generate-seed-content.sh" "$SITE_NAME" "$SEED_COUNT" \
      || log_warn "Seed content generation failed (non-critical)"
  else
    log_warn "AI not configured. Skipping content generation."
    log_info "  Run later: ./scripts/generate-content-plan.sh $SITE_NAME"
    log_info "             ./scripts/generate-seed-content.sh $SITE_NAME"
  fi
else
  log_info "AI content generation skipped (config.yaml or yq not available)"
  log_info "  Run later: ./scripts/generate-content-plan.sh $SITE_NAME"
  log_info "             ./scripts/generate-seed-content.sh $SITE_NAME"
fi

# Verify build
log_step "Verifying build..."
HUGO_CMD=$(find_hugo)
if [[ -z "$HUGO_CMD" ]]; then
  log_error "Hugo not found. Install Hugo and ensure it is in your PATH."
  exit 1
fi
BUILD_OUTPUT=$(mktemp)
if $HUGO_CMD -s "$SITE_DIR" --gc --minify --quiet 2>"$BUILD_OUTPUT"; then
  rm -f "$BUILD_OUTPUT"
  log_ok "Site '$SITE_NAME' created successfully at $SITE_DIR"
  echo ""
  echo "  Preview:  hugo server -s sites/$SITE_NAME"
  echo "  Build:    hugo -s sites/$SITE_NAME --gc --minify"
  echo "  Deploy:   ./scripts/deploy.sh $SITE_NAME"
else
  log_error "Build failed. Hugo errors:"
  cat "$BUILD_OUTPUT" >&2
  rm -f "$BUILD_OUTPUT"
  exit 1
fi
