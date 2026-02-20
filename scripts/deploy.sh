#!/usr/bin/env bash
# deploy.sh - Deploy a site to Vercel. Auto-detects Hugo vs static type.
# Usage: ./scripts/deploy.sh <site-name> [--preview]

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/config.sh"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/platform.sh"

SITE_NAME="${1:?Usage: deploy.sh <site-name> [--preview]}"
PREVIEW_FLAG="${2:-}"
SITE_DIR="$REPO_ROOT/sites/$SITE_NAME"

if [[ ! -d "$SITE_DIR" ]]; then
  log_error "Site not found: $SITE_DIR"
  exit 1
fi

# Detect site type from site.yaml
SITE_TYPE="static"
if [[ -f "$SITE_DIR/site.yaml" ]]; then
  SITE_TYPE=$(grep "^type:" "$SITE_DIR/site.yaml" | awk '{print $2}' | tr -d '"')
elif [[ -f "$SITE_DIR/hugo.toml" ]]; then
  SITE_TYPE="hugo"
fi

# Determine deploy directory
DEPLOY_DIR="$SITE_DIR"
if [[ "$SITE_TYPE" == "hugo" ]]; then
  log_step "Building Hugo site '$SITE_NAME'..."
  HUGO_CMD=$(find_hugo)
  if [[ -z "$HUGO_CMD" ]]; then
    log_error "Hugo not found. Install Hugo and ensure it is in your PATH."
    exit 1
  fi
  $HUGO_CMD -s "$SITE_DIR" --gc --minify --quiet
  DEPLOY_DIR="$SITE_DIR/public"
  log_ok "Build successful"
fi

# Deploy
PROD_FLAG=""
if [[ "$PREVIEW_FLAG" != "--preview" ]]; then
  PROD_FLAG="--prod"
fi

CUSTOM_DOMAIN="${SITE_NAME}.${SF_DOMAIN}"

log_step "Deploying to Vercel${PROD_FLAG:+ (production)}..."
log_info "This may take a minute, showing Vercel output below..."
echo ""

# Build vercel command
VERCEL_ARGS=("$DEPLOY_DIR" "--token" "$SF_VERCEL_TOKEN" "--yes" "--name" "$SITE_NAME")
[[ -n "$PROD_FLAG" ]] && VERCEL_ARGS+=("$PROD_FLAG")

# Stream output in real-time while capturing the deploy URL (last line)
VERCEL_OUTPUT_FILE=$(mktemp)
npx vercel "${VERCEL_ARGS[@]}" 2>&1 | tee "$VERCEL_OUTPUT_FILE"
DEPLOY_URL=$(tail -1 "$VERCEL_OUTPUT_FILE")
rm -f "$VERCEL_OUTPUT_FILE"

echo ""

# Add custom domain for production deploys
if [[ -n "$PROD_FLAG" ]]; then
  log_step "Configuring custom domain: $CUSTOM_DOMAIN"
  npx vercel domains add "$CUSTOM_DOMAIN" --token "$SF_VERCEL_TOKEN" --yes 2>/dev/null || true
fi

log_ok "Deployed: $DEPLOY_URL"
log_ok "Custom domain: https://$CUSTOM_DOMAIN"
echo ""
echo "  Check status: npx vercel ls --token \$SF_VERCEL_TOKEN"
