#!/usr/bin/env bash
# post-process-articles.sh - Apply dates, images, and shortcodes to generated articles
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

POST_DIR="$REPO_ROOT/sites/adsense-home/content/posts"

log_info "=== Post-processing articles ==="

# === 1. DATE DISTRIBUTION (Oct 2025 - Mar 2026) ===
log_step "Applying date distribution..."

# Format: slug|date|lastmod (lastmod empty means same as date)
DATES="how-to-use-advanced-search-operators-for-better-results|2025-10-15|2026-02-20
comparing-top-search-engines-google-bing-duckduckgo|2025-10-23|2026-03-01
boolean-search-explained-a-beginners-guide-for-better-querie|2025-11-04|2026-01-15
top-10-free-online-tools-for-productivity-in-2024|2025-11-12|
how-to-search-the-deep-web-safely-and-effectively|2025-11-29|
a-complete-guide-to-reverse-image-search-on-any-device|2025-12-19|
best-free-alternatives-to-popular-paid-software-tools|2026-01-05|2026-02-10
organize-bookmarks-system|2026-01-08|
how-to-create-custom-search-engines-for-your-projects|2026-01-13|
top-5-online-calculators-for-finance-and-everyday-math|2026-01-19|
how-to-use-search-to-fact-check-information-online|2026-01-25|
a-guide-to-using-wayback-machine-and-internet-archives|2026-01-31|
best-browser-extensions-to-enhance-your-search-experience|2026-02-08|
hidden-google-search-tricks|2026-02-12|
how-to-find-academic-papers-and-research-for-free|2026-02-14|
how-to-search-for-government-data-and-public-records|2026-02-19|
real-cost-free-vpns|2026-02-22|
how-to-set-up-and-use-rss-feeds-for-news-and-updates|2026-02-24|
top-10-niche-search-engines-you-probably-dont-know|2026-02-28|
10-email-productivity-hacks-to-save-hours-every-week|2026-03-02|
search-engine-week-test|2026-03-04|
best-free-online-file-converters-pdf-image-video-audio|2026-03-06|
research-workflow-from-scratch|2026-03-09|
complete-guide-to-password-managers|2026-03-11|2026-03-14
how-to-choose-and-use-a-vpn-for-online-privacy|2026-03-16|"

echo "$DATES" | while IFS='|' read -r slug target_date lastmod; do
  file="$POST_DIR/${slug}.md"
  [[ ! -f "$file" ]] && continue

  # Fix date
  sed -i '' "s/^date: .*/date: ${target_date}/" "$file"

  # Fix lastmod
  if [[ -n "$lastmod" ]]; then
    if grep -q '^lastmod:' "$file"; then
      sed -i '' "s/^lastmod: .*/lastmod: ${lastmod}/" "$file"
    else
      sed -i '' "/^date: /a\\
lastmod: ${lastmod}" "$file"
    fi
  else
    if grep -q '^lastmod:' "$file"; then
      sed -i '' "s/^lastmod: .*/lastmod: ${target_date}/" "$file"
    fi
  fi

  echo "  Date: $slug -> $target_date"
done
log_ok "Dates applied"

# === 2. IMAGE MAPPING ===
log_step "Applying hero images..."

# Map: slug -> image file
IMAGES="how-to-use-advanced-search-operators-for-better-results|search-operators
comparing-top-search-engines-google-bing-duckduckgo|search-engines
boolean-search-explained-a-beginners-guide-for-better-querie|boolean-search
top-10-free-online-tools-for-productivity-in-2024|productivity-tools
how-to-search-the-deep-web-safely-and-effectively|deep-web
a-complete-guide-to-reverse-image-search-on-any-device|reverse-image
best-free-alternatives-to-popular-paid-software-tools|free-alternatives
organize-bookmarks-system|bookmarks
how-to-create-custom-search-engines-for-your-projects|custom-search
top-5-online-calculators-for-finance-and-everyday-math|calculators
how-to-use-search-to-fact-check-information-online|fact-check
a-guide-to-using-wayback-machine-and-internet-archives|wayback-machine
best-browser-extensions-to-enhance-your-search-experience|browser-extensions
hidden-google-search-tricks|google-tricks
how-to-find-academic-papers-and-research-for-free|academic-papers
how-to-search-for-government-data-and-public-records|government-data
real-cost-free-vpns|free-vpns
how-to-set-up-and-use-rss-feeds-for-news-and-updates|rss-feeds
top-10-niche-search-engines-you-probably-dont-know|niche-engines
10-email-productivity-hacks-to-save-hours-every-week|email-hacks
search-engine-week-test|search-engine-test
best-free-online-file-converters-pdf-image-video-audio|file-converters
research-workflow-from-scratch|research-workflow
complete-guide-to-password-managers|password-managers
how-to-choose-and-use-a-vpn-for-online-privacy|vpn-privacy"

echo "$IMAGES" | while IFS='|' read -r slug img_name; do
  file="$POST_DIR/${slug}.md"
  [[ ! -f "$file" ]] && continue

  img_path="/images/posts/${img_name}.jpg"

  # Update image frontmatter field (replace empty string or existing value)
  if grep -q '^image:' "$file"; then
    sed -i '' "s|^image: .*|image: \"${img_path}\"|" "$file"
  else
    sed -i '' "/^date: /a\\
image: \"${img_path}\"" "$file"
  fi

  # Add image reference in body if not present (for verify-content-quality.sh)
  if ! grep -q '!\[' "$file"; then
    # Get the title for alt text
    title=$(grep '^title:' "$file" | head -1 | sed 's/^title: *"*//;s/"*$//')
    # Insert image reference after the first H2 heading
    sed -i '' "0,/^## /{s/^## \(.*\)/## \1\n\n![${title}](${img_path})\n/}" "$file"
  fi

  echo "  Image: $slug -> $img_path"
done
log_ok "Images applied"

# === 3. EMBED TOOL SHORTCODES ===
log_step "Embedding tool shortcodes..."

# Search Builder in advanced search operators article
SEARCH_FILE="$POST_DIR/how-to-use-advanced-search-operators-for-better-results.md"
if [[ -f "$SEARCH_FILE" ]] && ! grep -q 'search-builder' "$SEARCH_FILE"; then
  cat >> "$SEARCH_FILE" << 'EOF'

## Try It: Search Operator Builder {#search-builder}

Instead of memorizing all these operators, use the interactive tool below. Select your search engine, pick the operators you need, and it generates the query for you.

{{< search-builder >}}

I built this tool after realizing I kept forgetting the exact syntax for filetype and inurl operators. It saves me about 30 seconds per complex search.
EOF
  log_ok "  Embedded search-builder shortcode"
fi

# Password Checker in password managers article
PWD_FILE="$POST_DIR/complete-guide-to-password-managers.md"
if [[ -f "$PWD_FILE" ]] && ! grep -q 'password-checker' "$PWD_FILE"; then
  cat >> "$PWD_FILE" << 'EOF'

## Check Your Password Strength {#password-checker}

Before choosing a password manager, test how strong your current passwords really are. This tool runs entirely in your browser — nothing is sent to any server.

{{< password-checker >}}

When I tested my own "strong" passwords with this tool, I was surprised to find that two of them scored below 50 bits of entropy. That is what convinced me to switch to a password manager.
EOF
  log_ok "  Embedded password-checker shortcode"
fi

log_ok "=== Post-processing complete ==="
