#!/usr/bin/env bash
# deploy-all.sh - Deploy all sites to Vercel.

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

  log_info "Deploying: $site_name"
  if "$REPO_ROOT/scripts/deploy.sh" "$site_name" 2>&1; then
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
