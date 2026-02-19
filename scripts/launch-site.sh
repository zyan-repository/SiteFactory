#!/usr/bin/env bash
# launch-site.sh - One-command site creation + deployment pipeline.
# Combines check → create → deploy into a single step.
#
# Usage:
#   ./scripts/launch-site.sh fork <github-url> <name> ["title"] ["description"]
#   ./scripts/launch-site.sh hugo <name> ["title"] ["description"] [language]
#
# Output: JSON-like summary with site URL and deploy status.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

# --- Parse arguments ---
MODE="${1:?Usage: launch-site.sh <fork|hugo> ...}"
shift

case "$MODE" in
  fork)
    REPO_URL="${1:?Usage: launch-site.sh fork <github-url> <name> [\"title\"] [\"description\"]}"
    SITE_NAME="${2:?Please provide a site name}"
    SITE_TITLE="${3:-$SITE_NAME}"
    SITE_DESC="${4:-A useful web tool}"
    ;;
  hugo)
    SITE_NAME="${1:?Usage: launch-site.sh hugo <name> [\"title\"] [\"description\"] [language]}"
    SITE_TITLE="${2:-$SITE_NAME}"
    SITE_DESC="${3:-A new site}"
    SITE_LANG="${4:-en}"
    ;;
  *)
    log_error "Unknown mode: $MODE. Use 'fork' or 'hugo'."
    exit 1
    ;;
esac

log_info "=== SiteFactory Launch: $SITE_NAME ($MODE) ==="
echo ""

# --- Phase 1: Create site ---
log_step "Phase 1: Creating site..."
case "$MODE" in
  fork)
    "$REPO_ROOT/scripts/fork-site.sh" "$REPO_URL" "$SITE_NAME" "$SITE_TITLE" "$SITE_DESC"
    ;;
  hugo)
    "$REPO_ROOT/scripts/new-site.sh" "$SITE_NAME" "$SITE_TITLE" "$SITE_DESC" "$SITE_LANG"
    ;;
esac
echo ""

# --- Phase 2: Deploy ---
log_step "Phase 2: Deploying to production..."
"$REPO_ROOT/scripts/deploy.sh" "$SITE_NAME"
echo ""

# --- Phase 3: DNS ---
log_step "Phase 3: Setting up DNS..."
"$REPO_ROOT/scripts/dns-setup.sh" "$SITE_NAME"
echo ""

# --- Summary ---
# Load config for domain
if [[ -f "$REPO_ROOT/config.yaml" ]]; then
  source "$REPO_ROOT/scripts/lib/config.sh"
fi
CUSTOM_DOMAIN="${SITE_NAME}.${SF_DOMAIN:-example.com}"

log_ok "=== Launch complete! ==="
echo ""
echo "  Site:   https://$CUSTOM_DOMAIN"
echo "  Type:   $MODE"
echo "  Dir:    sites/$SITE_NAME"
