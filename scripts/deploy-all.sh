#!/usr/bin/env bash
# deploy-all.sh - Deploy all sites to Vercel with DNS setup.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

SITES_DIR="$REPO_ROOT/sites"
FAILED=()
SUCCEEDED=0

log_info "=== Deploying all sites ==="

for site_dir in "$SITES_DIR"/*/; do
  site_name=$(basename "$site_dir")

  # Skip special directories
  [[ "$site_name" == "_template" ]] && continue
  [[ "$site_name" == "_shared" ]] && continue
  [[ ! -f "$site_dir/site.yaml" ]] && continue

  # Detect root domain flag from site.yaml
  ROOT_FLAG=""
  if grep -q "^root_domain: true" "$site_dir/site.yaml" 2>/dev/null; then
    ROOT_FLAG="--root"
  fi

  log_info "Deploying: $site_name${ROOT_FLAG:+ (root domain)}"
  if "$REPO_ROOT/scripts/deploy.sh" "$site_name" $ROOT_FLAG 2>&1; then
    # Setup DNS after successful deploy
    "$REPO_ROOT/scripts/dns-setup.sh" "$site_name" $ROOT_FLAG 2>&1 || true
    ((SUCCEEDED++))
  else
    log_error "  Deploy failed for $site_name"
    FAILED+=("$site_name")
  fi
  echo ""
done

log_info "Results: $SUCCEEDED deployed, ${#FAILED[@]} failed"
if [[ ${#FAILED[@]} -gt 0 ]]; then
  log_error "Failed: ${FAILED[*]}"
  exit 1
fi
log_ok "All sites deployed"
