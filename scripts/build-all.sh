#!/usr/bin/env bash
# build-all.sh - Build all Hugo sites under sites/.
# Static (fork) sites are skipped (no build needed).

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/platform.sh"

SITES_DIR="$REPO_ROOT/sites"
FAILED=()
SUCCEEDED=0
SKIPPED=0

HUGO_CMD=$(find_hugo)
if [[ -z "$HUGO_CMD" ]]; then
  log_error "Hugo not found. Install Hugo and ensure it is in your PATH."
  exit 1
fi

log_info "=== Building all sites ==="

for site_dir in "$SITES_DIR"/*/; do
  site_name=$(basename "$site_dir")

  # Skip special directories
  [[ "$site_name" == "_template" ]] && continue
  [[ "$site_name" == "_shared" ]] && continue

  # Check site type
  if [[ -f "$site_dir/site.yaml" ]]; then
    site_type=$(grep "^type:" "$site_dir/site.yaml" | awk '{print $2}' | tr -d '"')
  elif [[ -f "$site_dir/hugo.toml" ]]; then
    site_type="hugo"
  else
    site_type="static"
  fi

  if [[ "$site_type" == "static" ]]; then
    log_info "Skipping (static): $site_name"
    ((SKIPPED++))
    continue
  fi

  log_info "Building: $site_name"
  if $HUGO_CMD -s "$site_dir" --gc --minify --quiet 2>/dev/null; then
    log_ok "  OK"
    ((SUCCEEDED++))
  else
    log_error "  FAILED"
    FAILED+=("$site_name")
  fi
done

echo ""
log_info "Results: $SUCCEEDED built, $SKIPPED skipped (static), ${#FAILED[@]} failed"
if [[ ${#FAILED[@]} -gt 0 ]]; then
  log_error "Failed sites: ${FAILED[*]}"
  exit 1
fi
log_ok "All sites OK"
