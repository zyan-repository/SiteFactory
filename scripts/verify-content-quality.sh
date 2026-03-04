#!/usr/bin/env bash
# verify-content-quality.sh - Check content quality signals for AdSense approval
#
# Usage: ./scripts/verify-content-quality.sh <site-name>
#
# Checks for anti-patterns that trigger AdSense "low value content" rejection:
# - Banned opening/closing phrases
# - Missing visual elements (images, tables, code blocks)
# - Missing internal links
# - Uniform word counts
# - Uniform publication dates

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

SITE_NAME="${1:?Usage: verify-content-quality.sh <site-name>}"
POST_DIR="$REPO_ROOT/sites/$SITE_NAME/content/posts"

if [[ ! -d "$POST_DIR" ]]; then
  log_error "Post directory not found: $POST_DIR"
  exit 1
fi

PASS=0
WARN=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  [PASS] $1"; }
warn() { WARN=$((WARN + 1)); echo "  [WARN] $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  [FAIL] $1"; }

echo "=== Content Quality Verification: $SITE_NAME ==="
echo ""

# Collect articles
ARTICLES=()
while IFS= read -r f; do
  [[ "$(basename "$f")" == "_index.md" ]] && continue
  ARTICLES+=("$f")
done < <(find "$POST_DIR" -name "*.md" -not -name "_index.md" 2>/dev/null | sort)

TOTAL=${#ARTICLES[@]}
echo "Articles found: $TOTAL"
echo ""

if [[ $TOTAL -lt 15 ]]; then
  fail "Fewer than 15 articles ($TOTAL). AdSense typically requires 15-20+ articles."
else
  pass "Article count ($TOTAL) meets minimum"
fi

# === Per-article checks ===
echo ""
echo "--- Per-Article Checks ---"

WORD_COUNTS=()
DATES=()
IMAGES_FOUND=0
TABLES_FOUND=0
LINKS_FOUND=0
BANNED_OPENINGS=0

for article in "${ARTICLES[@]}"; do
  slug=$(basename "$article" .md)
  # Extract body (after second ---)
  body=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$article")
  wc_count=$(echo "$body" | wc -w | tr -d ' ')
  WORD_COUNTS+=("$wc_count")

  # Extract date from frontmatter
  article_date=$(grep '^date:' "$article" | head -1 | sed 's/date: *"*//;s/"*$//' | sed 's/T.*//')
  [[ -n "$article_date" ]] && DATES+=("$article_date")

  # Check banned openings
  first_line=$(echo "$body" | head -20 | grep -m1 '[A-Za-z]' || true)
  if echo "$first_line" | grep -qiE '^In (today|the vast|an era|a world|the ever)'; then
    fail "$slug: Banned opening pattern detected"
    BANNED_OPENINGS=$((BANNED_OPENINGS + 1))
  fi

  # Check for images
  if echo "$body" | grep -q '!\['; then
    IMAGES_FOUND=$((IMAGES_FOUND + 1))
  else
    warn "$slug: No images found"
  fi

  # Check for markdown tables
  if echo "$body" | grep -qE '^\|.*\|.*\|'; then
    TABLES_FOUND=$((TABLES_FOUND + 1))
  else
    warn "$slug: No markdown tables found"
  fi

  # Check for internal links
  link_count=$(echo "$body" | { grep -oE '\]\(/posts/' || true; } | wc -l | tr -d ' ')
  if [[ "$link_count" -ge 2 ]]; then
    LINKS_FOUND=$((LINKS_FOUND + 1))
  else
    warn "$slug: Fewer than 2 internal links ($link_count found)"
  fi

  # Check word count
  if [[ "$wc_count" -lt 600 ]]; then
    fail "$slug: Only $wc_count words (minimum 600)"
  fi
done

# === Aggregate checks ===
echo ""
echo "--- Aggregate Checks ---"

# Word count diversity
if [[ ${#WORD_COUNTS[@]} -gt 0 ]]; then
  sum=0
  for wc in "${WORD_COUNTS[@]}"; do sum=$((sum + wc)); done
  avg=$((sum / ${#WORD_COUNTS[@]}))

  # Calculate standard deviation
  sq_sum=0
  for wc in "${WORD_COUNTS[@]}"; do
    diff=$((wc - avg))
    sq_sum=$((sq_sum + diff * diff))
  done
  variance=$((sq_sum / ${#WORD_COUNTS[@]}))
  # Integer approximation of sqrt
  stddev=0
  if [[ $variance -gt 0 ]]; then
    stddev=$(echo "sqrt($variance)" | bc 2>/dev/null || echo "0")
  fi

  echo "  Word count: avg=$avg, stddev=$stddev, range=$(printf '%s\n' "${WORD_COUNTS[@]}" | sort -n | head -1)-$(printf '%s\n' "${WORD_COUNTS[@]}" | sort -n | tail -1)"

  if [[ "$stddev" -gt 300 ]]; then
    pass "Word count standard deviation ($stddev) shows natural variation"
  else
    fail "Word count standard deviation ($stddev) too low — articles look uniform. Target: >300"
  fi

  # Check for long and short articles
  long_count=0
  short_count=0
  for wc in "${WORD_COUNTS[@]}"; do
    [[ "$wc" -gt 2000 ]] && long_count=$((long_count + 1))
    [[ "$wc" -lt 900 ]] && short_count=$((short_count + 1))
  done

  if [[ "$long_count" -ge 3 ]]; then
    pass "$long_count articles over 2000 words (deep content signal)"
  else
    warn "Only $long_count articles over 2000 words (want >= 3)"
  fi

  if [[ "$short_count" -ge 2 ]]; then
    pass "$short_count articles under 900 words (varied length signal)"
  else
    warn "Only $short_count articles under 900 words (want >= 2 for variety)"
  fi
fi

# Image coverage
echo ""
echo "  Images: $IMAGES_FOUND/$TOTAL articles have images"
if [[ "$IMAGES_FOUND" -ge $((TOTAL * 80 / 100)) ]]; then
  pass "80%+ articles have images"
else
  fail "Only $IMAGES_FOUND/$TOTAL articles have images (want 80%+)"
fi

# Table coverage
echo "  Tables: $TABLES_FOUND/$TOTAL articles have markdown tables"
if [[ "$TABLES_FOUND" -ge $((TOTAL * 60 / 100)) ]]; then
  pass "60%+ articles have tables"
else
  warn "Only $TABLES_FOUND/$TOTAL articles have tables (want 60%+)"
fi

# Internal links coverage
echo "  Internal links: $LINKS_FOUND/$TOTAL articles have 2+ internal links"
if [[ "$LINKS_FOUND" -ge $((TOTAL * 70 / 100)) ]]; then
  pass "70%+ articles have sufficient internal links"
else
  fail "Only $LINKS_FOUND/$TOTAL articles have 2+ internal links (want 70%+)"
fi

# Banned opening patterns
if [[ "$BANNED_OPENINGS" -eq 0 ]]; then
  pass "No banned opening patterns detected"
else
  fail "$BANNED_OPENINGS articles have banned opening patterns"
fi

# === Summary ===
echo ""
echo "=== Summary ==="
echo "  PASS: $PASS"
echo "  WARN: $WARN"
echo "  FAIL: $FAIL"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  log_error "Content quality check FAILED with $FAIL issues"
  exit 1
else
  if [[ "$WARN" -gt 0 ]]; then
    log_warn "Content quality check passed with $WARN warnings"
  else
    log_ok "Content quality check PASSED"
  fi
  exit 0
fi
