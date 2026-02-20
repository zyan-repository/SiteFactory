#!/usr/bin/env bash
# fork-site.sh - Fork a GitHub project and adapt it for SiteFactory.
# Usage: ./scripts/fork-site.sh <github-url> <site-name> ["Site Title"] ["Description"]
#
# Steps:
# 1. Run compatibility check
# 2. Clone and strip .git
# 3. Inject AdSense, Analytics, SEO meta
# 4. Add privacy policy and about pages
# 5. Create ads.txt and site.yaml
# 6. Add license attribution

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/platform.sh"
source "$REPO_ROOT/scripts/lib/inject.sh"

REPO_URL="${1:?Usage: fork-site.sh <github-url> <site-name> [\"title\"] [\"description\"]}"
SITE_NAME="${2:?Please provide a site name}"
SITE_TITLE="${3:-$SITE_NAME}"
SITE_DESC="${4:-A useful web tool}"

SITE_DIR="$REPO_ROOT/sites/$SITE_NAME"

# Validate site name
if [[ ! "$SITE_NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
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
  SF_AUTHOR_NAME="Author"
  SF_AUTHOR_EMAIL=""
fi

DATE=$(date +%Y-%m-%d)

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

# Step 3: Inject AdSense + Analytics into all HTML files
log_step "Injecting AdSense, Analytics, and SEO meta..."
find "$SITE_DIR" -name "*.html" -maxdepth 2 -type f | while read -r html_file; do
  inject_all "$html_file" "$SF_ADSENSE_PUB_ID" "$SF_GA_ID" "$SITE_TITLE" "$SITE_DESC"
done

# Step 4: Add compliance pages
log_step "Adding compliance pages..."
SHARED_DIR="$REPO_ROOT/sites/_shared"

for page in privacy-policy.html about.html; do
  if [[ -f "$SHARED_DIR/$page" ]]; then
    cp "$SHARED_DIR/$page" "$SITE_DIR/$page"
    sed_inplace \
      -e "s|{{SITE_TITLE}}|${SITE_TITLE}|g" \
      -e "s|{{AUTHOR_EMAIL}}|${SF_AUTHOR_EMAIL}|g" \
      -e "s|{{DATE}}|${DATE}|g" \
      "$SITE_DIR/$page"
    log_ok "  Added $page"
  fi
done

# Step 5: Create ads.txt
PUB_NUMERIC="${SF_ADSENSE_PUB_ID#ca-pub-}"
if [[ -n "$PUB_NUMERIC" ]] && [[ "$PUB_NUMERIC" != *"XXXX"* ]]; then
  echo "google.com, $PUB_NUMERIC, DIRECT, f08c47fec0942fa0" > "$SITE_DIR/ads.txt"
  log_ok "  Created ads.txt"
fi

# Step 6: Create site.yaml
cat > "$SITE_DIR/site.yaml" << EOF
type: static
name: ${SITE_NAME}
title: "${SITE_TITLE}"
description: "${SITE_DESC}"
source: ${REPO_URL}
license: ${LICENSE_TYPE}
language: en
created: ${DATE}
EOF
log_ok "  Created site.yaml"

# Step 7: Add attribution to README
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

log_ok "=== Fork complete: $SITE_NAME ==="
echo ""
echo "  Directory: sites/$SITE_NAME"
echo "  Deploy:    ./scripts/deploy.sh $SITE_NAME"
echo "  Preview:   open sites/$SITE_NAME/index.html"
