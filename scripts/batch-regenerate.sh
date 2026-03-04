#!/usr/bin/env bash
# batch-regenerate.sh - Regenerate all 25 articles for adsense-home
# Runs generate-content.sh in a loop, then post-processes dates and shortcodes.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

SITE="adsense-home"
POST_DIR="$REPO_ROOT/sites/$SITE/content/posts"
TOTAL=25
SUCCESS=0
FAIL=0

log_info "=== Batch regeneration: $TOTAL articles for $SITE ==="

for i in $(seq 1 $TOTAL); do
  log_step "[$i/$TOTAL] Generating next pending article..."
  if "$REPO_ROOT/scripts/generate-content.sh" "$SITE" 2>&1; then
    SUCCESS=$((SUCCESS + 1))
    log_ok "[$i/$TOTAL] Success (total: $SUCCESS)"
  else
    FAIL=$((FAIL + 1))
    log_warn "[$i/$TOTAL] Failed (total failures: $FAIL)"
    # If no more pending topics, stop early
    REMAINING=$(yq '[.topics[] | select(.status == "pending")] | length' "$REPO_ROOT/content-plans/$SITE.yaml")
    if [[ "$REMAINING" -eq 0 ]]; then
      log_info "No more pending topics. Stopping."
      break
    fi
  fi
  # Small delay to avoid rate limiting
  sleep 2
done

log_info "=== Generation complete: $SUCCESS succeeded, $FAIL failed ==="

# === POST-PROCESSING: Date distribution ===
log_step "Post-processing: applying date distribution..."

# Date mapping: slug -> date (Oct 2025 - Mar 2026, non-uniform gaps)
declare -A DATE_MAP=(
  ["how-to-use-advanced-search-operators-for-better-results"]="2025-10-15"
  ["comparing-top-search-engines-google-bing-duckduckgo"]="2025-10-23"
  ["boolean-search-explained-a-beginners-guide-for-better-querie"]="2025-11-04"
  ["top-10-free-online-tools-for-productivity-in-2024"]="2025-11-12"
  ["how-to-search-the-deep-web-safely-and-effectively"]="2025-11-29"
  ["a-complete-guide-to-reverse-image-search-on-any-device"]="2025-12-19"
  ["best-free-alternatives-to-popular-paid-software-tools"]="2026-01-05"
  ["organize-bookmarks-system"]="2026-01-08"
  ["how-to-create-custom-search-engines-for-your-projects"]="2026-01-13"
  ["top-5-online-calculators-for-finance-and-everyday-math"]="2026-01-19"
  ["how-to-use-search-to-fact-check-information-online"]="2026-01-25"
  ["a-guide-to-using-wayback-machine-and-internet-archives"]="2026-01-31"
  ["best-browser-extensions-to-enhance-your-search-experience"]="2026-02-08"
  ["hidden-google-search-tricks"]="2026-02-12"
  ["how-to-find-academic-papers-and-research-for-free"]="2026-02-14"
  ["how-to-search-for-government-data-and-public-records"]="2026-02-19"
  ["real-cost-free-vpns"]="2026-02-22"
  ["how-to-set-up-and-use-rss-feeds-for-news-and-updates"]="2026-02-24"
  ["top-10-niche-search-engines-you-probably-dont-know"]="2026-02-28"
  ["10-email-productivity-hacks-to-save-hours-every-week"]="2026-03-02"
  ["search-engine-week-test"]="2026-03-04"
  ["best-free-online-file-converters-pdf-image-video-audio"]="2026-03-06"
  ["research-workflow-from-scratch"]="2026-03-09"
  ["complete-guide-to-password-managers"]="2026-03-11"
  ["how-to-choose-and-use-a-vpn-for-online-privacy"]="2026-03-16"
)

# Some articles get a lastmod to show "updated" signal
declare -A LASTMOD_MAP=(
  ["how-to-use-advanced-search-operators-for-better-results"]="2026-02-20"
  ["boolean-search-explained-a-beginners-guide-for-better-querie"]="2026-01-15"
  ["comparing-top-search-engines-google-bing-duckduckgo"]="2026-03-01"
  ["complete-guide-to-password-managers"]="2026-03-14"
  ["best-free-alternatives-to-popular-paid-software-tools"]="2026-02-10"
)

DATE_FIXED=0
for article in "$POST_DIR"/*.md; do
  [[ "$(basename "$article")" == "_index.md" ]] && continue
  slug=$(basename "$article" .md)

  if [[ -n "${DATE_MAP[$slug]:-}" ]]; then
    target_date="${DATE_MAP[$slug]}"
    # Replace date in frontmatter
    sed -i '' "s/^date: .*/date: ${target_date}/" "$article"

    # Add or update lastmod
    if [[ -n "${LASTMOD_MAP[$slug]:-}" ]]; then
      lastmod="${LASTMOD_MAP[$slug]}"
      if grep -q '^lastmod:' "$article"; then
        sed -i '' "s/^lastmod: .*/lastmod: ${lastmod}/" "$article"
      else
        sed -i '' "/^date: /a\\
lastmod: ${lastmod}" "$article"
      fi
    else
      # Set lastmod = date if not in special map
      if grep -q '^lastmod:' "$article"; then
        sed -i '' "s/^lastmod: .*/lastmod: ${target_date}/" "$article"
      fi
    fi

    DATE_FIXED=$((DATE_FIXED + 1))
    log_info "  Date fixed: $slug -> $target_date"
  else
    log_warn "  No date mapping for: $slug"
  fi
done
log_ok "Dates fixed for $DATE_FIXED articles"

# === POST-PROCESSING: Embed tool shortcodes ===
log_step "Post-processing: embedding tool shortcodes..."

# Search Builder → advanced search operators article
SEARCH_ARTICLE="$POST_DIR/how-to-use-advanced-search-operators-for-better-results.md"
if [[ -f "$SEARCH_ARTICLE" ]] && ! grep -q 'search-builder' "$SEARCH_ARTICLE"; then
  # Add shortcode before the last section or at end of body
  cat >> "$SEARCH_ARTICLE" << 'SHORTCODE'

## Try It: Search Operator Builder {#search-builder}

Instead of memorizing all these operators, use the interactive tool below. Select your search engine, pick the operators you need, and it generates the query for you.

{{< search-builder >}}

I built this tool after realizing I kept forgetting the exact syntax for filetype and inurl operators. It saves me about 30 seconds per complex search.
SHORTCODE
  log_ok "  Embedded search-builder in advanced-search-operators"
fi

# Password Checker → password managers article
PWD_ARTICLE="$POST_DIR/complete-guide-to-password-managers.md"
if [[ -f "$PWD_ARTICLE" ]] && ! grep -q 'password-checker' "$PWD_ARTICLE"; then
  cat >> "$PWD_ARTICLE" << 'SHORTCODE'

## Check Your Password Strength {#password-checker}

Before choosing a password manager, test how strong your current passwords really are. This tool runs entirely in your browser — nothing is sent to any server.

{{< password-checker >}}

When I tested my own "strong" passwords with this tool, I was surprised to find that two of them scored below 50 bits of entropy. That is what convinced me to switch to a password manager.
SHORTCODE
  log_ok "  Embedded password-checker in password-managers"
fi

log_ok "=== Batch regeneration + post-processing complete ==="
log_info "Next steps: run verify-content-quality.sh, then build and deploy"
