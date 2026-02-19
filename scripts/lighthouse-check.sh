#!/usr/bin/env bash
# lighthouse-check.sh - Run Lighthouse audit on deployed site(s).
# Usage: ./scripts/lighthouse-check.sh <site-name|--all>
# Requires: npx lighthouse (auto-installed via npx)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

if [[ -f "$REPO_ROOT/config.yaml" ]]; then
  source "$REPO_ROOT/scripts/lib/config.sh"
else
  SF_DOMAIN="example.com"
fi

TARGET="${1:?Usage: lighthouse-check.sh <site-name|--all>}"

run_lighthouse() {
  local name="$1"
  local url="https://${name}.${SF_DOMAIN}"
  local output_dir="$REPO_ROOT/dashboard/data/lighthouse"
  mkdir -p "$output_dir"

  log_info "Auditing: $url"

  if ! npx lighthouse "$url" \
    --only-categories=performance,seo,accessibility,best-practices \
    --output=json \
    --output-path="$output_dir/${name}.json" \
    --chrome-flags="--headless --no-sandbox" \
    --quiet 2>/dev/null; then
    log_error "  Lighthouse audit failed for $name"
    return 1
  fi

  # Extract and display scores
  local perf seo a11y bp
  perf=$(jq '.categories.performance.score * 100 | floor' "$output_dir/${name}.json" 2>/dev/null || echo "?")
  seo=$(jq '.categories.seo.score * 100 | floor' "$output_dir/${name}.json" 2>/dev/null || echo "?")
  a11y=$(jq '.categories.accessibility.score * 100 | floor' "$output_dir/${name}.json" 2>/dev/null || echo "?")
  bp=$(jq '.categories["best-practices"].score * 100 | floor' "$output_dir/${name}.json" 2>/dev/null || echo "?")

  echo "  Performance: ${perf}  SEO: ${seo}  Accessibility: ${a11y}  Best Practices: ${bp}"

  # Warn on low scores
  for score_name in perf seo a11y bp; do
    local val=${!score_name}
    if [[ "$val" != "?" ]] && [[ "$val" -lt 80 ]]; then
      log_warn "  $score_name score ($val) is below 80 - needs attention"
    fi
  done
}

if [[ "$TARGET" == "--all" ]]; then
  for site_dir in "$REPO_ROOT/sites"/*/; do
    name=$(basename "$site_dir")
    [[ "$name" == "_template" ]] && continue
    [[ "$name" == "_shared" ]] && continue
    [[ ! -f "$site_dir/site.yaml" ]] && continue
    run_lighthouse "$name"
    echo ""
  done
else
  run_lighthouse "$TARGET"
fi
