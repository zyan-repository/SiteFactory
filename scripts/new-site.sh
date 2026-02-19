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

# Step 1: Copy template
log_step "Copying template..."
cp -r "$TEMPLATE_DIR" "$SITE_DIR"

# Step 2: Configure hugo.toml
log_step "Configuring site..."
PUB_NUMERIC="${SF_ADSENSE_PUB_ID#ca-pub-}"

# Replace values in hugo.toml
sed -i '' \
  -e "s|SITE_NAME.example.com|${SITE_NAME}.${SF_DOMAIN}|g" \
  -e "s|languageCode = \"en\"|languageCode = \"${SITE_LANG}\"|g" \
  -e "s|title = \"Site Title\"|title = \"${SITE_TITLE}\"|g" \
  -e "s|description = \"Site description goes here\"|description = \"${SITE_DESC}\"|g" \
  -e "s|author = \"Author Name\"|author = \"${SF_AUTHOR_NAME}\"|g" \
  -e "s|adsenseEnabled = false|adsenseEnabled = ${SF_ADSENSE_ENABLED}|g" \
  -e "s|adsensePubId = \"\"|adsensePubId = \"${SF_ADSENSE_PUB_ID}\"|g" \
  -e "s|googleAnalyticsId = \"\"|googleAnalyticsId = \"${SF_GA_ID}\"|g" \
  -e "s|googleSearchConsoleVerification = \"\"|googleSearchConsoleVerification = \"${SF_GSC_VERIFICATION}\"|g" \
  "$SITE_DIR/hugo.toml"

# Replace placeholders in content files
find "$SITE_DIR/content" -name "*.md" -type f | while read -r file; do
  sed -i '' \
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
  sed -i '' "s|{{ADSENSE_PUB_ID_NUMERIC}}|${PUB_NUMERIC}|g" "$SITE_DIR/static/ads.txt"
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

# Verify build
log_step "Verifying build..."
if /opt/homebrew/bin/hugo -s "$SITE_DIR" --gc --minify --quiet 2>/dev/null; then
  log_ok "Site '$SITE_NAME' created successfully at $SITE_DIR"
  echo ""
  echo "  Preview:  hugo server -s sites/$SITE_NAME"
  echo "  Build:    hugo -s sites/$SITE_NAME --gc --minify"
  echo "  Deploy:   ./scripts/deploy.sh $SITE_NAME"
else
  log_error "Build failed. Check $SITE_DIR for errors."
  exit 1
fi
