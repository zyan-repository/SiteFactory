#!/usr/bin/env bash
# deploy.sh - Deploy a site to Vercel. Auto-detects Hugo vs static type.
# Usage: ./scripts/deploy.sh <site-name> [--preview] [--verify] [--root]

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/config.sh"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/platform.sh"
source "$REPO_ROOT/scripts/lib/vercel.sh"

# --- Parse arguments (order-independent) ---
SITE_NAME=""
PREVIEW_FLAG=""
VERIFY_FLAG=""
ROOT_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --preview) PREVIEW_FLAG="--preview" ;;
    --verify) VERIFY_FLAG="--verify" ;;
    --root) ROOT_FLAG="--root" ;;
    *) [[ -z "$SITE_NAME" ]] && SITE_NAME="$arg" ;;
  esac
done
[[ -z "$SITE_NAME" ]] && { echo "Usage: deploy.sh <site-name> [--preview] [--verify] [--root]"; exit 1; }

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

  # Save .vercel/ before Hugo build (Hugo clears public/ on rebuild)
  VERCEL_BACKUP=""
  if [[ -d "$SITE_DIR/public/.vercel" ]]; then
    VERCEL_BACKUP=$(mktemp -d)
    cp -r "$SITE_DIR/public/.vercel" "$VERCEL_BACKUP/.vercel"
  fi

  # Clean up temp backup on exit (prevents leak if Hugo build fails)
  cleanup_vercel_backup() { [[ -n "${VERCEL_BACKUP:-}" ]] && rm -rf "$VERCEL_BACKUP"; }
  trap cleanup_vercel_backup EXIT

  $HUGO_CMD -s "$SITE_DIR" --gc --minify --quiet
  DEPLOY_DIR="$SITE_DIR/public"
  log_ok "Build successful"

  # Restore .vercel/ after build
  if [[ -n "$VERCEL_BACKUP" ]] && [[ -d "$VERCEL_BACKUP/.vercel" ]]; then
    cp -r "$VERCEL_BACKUP/.vercel" "$DEPLOY_DIR/.vercel"
    rm -rf "$VERCEL_BACKUP"
    VERCEL_BACKUP=""  # Prevent double-cleanup by trap
  fi
  trap - EXIT

  # Link deploy directory to correct Vercel project name.
  # Without this, Vercel auto-names Hugo projects "public" (from the directory name).
  log_step "Linking Vercel project '$SITE_NAME'..."
  vercel_link_project "$DEPLOY_DIR" "$SITE_NAME" "$SF_VERCEL_TOKEN" || true
fi

# Deploy
PROD_FLAG=""
if [[ "$PREVIEW_FLAG" != "--preview" ]]; then
  PROD_FLAG="--prod"
fi

CUSTOM_DOMAIN="${SITE_NAME}.${SF_DOMAIN}"

# Detect root domain from --root flag or site.yaml
IS_ROOT=false
if [[ "$ROOT_FLAG" == "--root" ]]; then
  IS_ROOT=true
elif [[ -f "$SITE_DIR/site.yaml" ]] && grep -q "^root_domain: true" "$SITE_DIR/site.yaml" 2>/dev/null; then
  IS_ROOT=true
fi

log_step "Deploying to Vercel${PROD_FLAG:+ (production)}..."
log_info "This may take a minute, showing Vercel output below..."
echo ""

# Detect Vercel scope (required for non-interactive token-based deploys)
VERCEL_SCOPE=""
if [[ -n "${SF_VERCEL_TEAM_ID:-}" ]]; then
  VERCEL_SCOPE="$SF_VERCEL_TEAM_ID"
elif [[ -f "$DEPLOY_DIR/.vercel/project.json" ]] && command -v jq &>/dev/null; then
  VERCEL_SCOPE=$(jq -r '.orgId // empty' "$DEPLOY_DIR/.vercel/project.json" 2>/dev/null)
fi

# Build vercel command
VERCEL_ARGS=("$DEPLOY_DIR" "--token" "$SF_VERCEL_TOKEN" "--yes")
[[ -n "$VERCEL_SCOPE" ]] && VERCEL_ARGS+=("--scope" "$VERCEL_SCOPE")
[[ -n "$PROD_FLAG" ]] && VERCEL_ARGS+=("$PROD_FLAG")

# Stream output in real-time while capturing the deploy URL
VERCEL_OUTPUT_FILE=$(mktemp)
npx vercel "${VERCEL_ARGS[@]}" 2>&1 | tee "$VERCEL_OUTPUT_FILE"
# Extract the last https:// URL from output (the production/preview URL)
DEPLOY_URL=$(grep -oE 'https://[^ ]+' "$VERCEL_OUTPUT_FILE" | tail -1)
rm -f "$VERCEL_OUTPUT_FILE"

echo ""

# Resolve the actual Vercel project name (may differ from site name for legacy deployments)
VERCEL_PROJECT=$(resolve_vercel_project "$SITE_DIR" "$SITE_TYPE" "$SITE_NAME")

# Add custom domain for production deploys
if [[ -n "$PROD_FLAG" ]]; then
  log_step "Configuring custom domain: $CUSTOM_DOMAIN"
  npx vercel domains add "$CUSTOM_DOMAIN" "$VERCEL_PROJECT" --token "$SF_VERCEL_TOKEN" 2>/dev/null || true

  if [[ "$IS_ROOT" == "true" ]]; then
    log_step "Configuring root domain: $SF_DOMAIN"
    npx vercel domains add "$SF_DOMAIN" "$VERCEL_PROJECT" --token "$SF_VERCEL_TOKEN" 2>/dev/null || true
    npx vercel domains add "www.${SF_DOMAIN}" "$VERCEL_PROJECT" --token "$SF_VERCEL_TOKEN" 2>/dev/null || true
  fi
fi

log_ok "Deployed: $DEPLOY_URL"
log_ok "Custom domain: https://$CUSTOM_DOMAIN"
if [[ "$IS_ROOT" == "true" ]]; then
  log_ok "Root domain: https://$SF_DOMAIN"
fi

# Post-deploy HTTP health check (optional)
if [[ "$VERIFY_FLAG" == "--verify" ]] && [[ -n "$DEPLOY_URL" ]]; then
  source "$REPO_ROOT/scripts/lib/verify.sh"
  log_step "Verifying deployment..."
  if verify_http_poll "$DEPLOY_URL" 4 5; then
    echo ""
    log_ok "Verified: $DEPLOY_URL responds OK"
  else
    log_warn "Site not yet responding at $DEPLOY_URL (may need a few more seconds)"
  fi
fi

echo ""
echo "  Check status: npx vercel ls --token \$SF_VERCEL_TOKEN"
