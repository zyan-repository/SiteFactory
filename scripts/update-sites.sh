#!/usr/bin/env bash
# update-sites.sh - Re-apply injections and updates to all sites.
# Hugo sites: no-op (theme handles updates automatically on next build).
# Fork (static) sites: re-run inject_all with enhanced SEO elements.
# All functions are idempotent — safe to run repeatedly.
#
# Usage: ./scripts/update-sites.sh [site-name]
#   No arguments: update all sites
#   With argument: update only the specified site

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/platform.sh"
source "$REPO_ROOT/scripts/lib/inject.sh"

# Load config
if [[ -f "$REPO_ROOT/config.yaml" ]]; then
  source "$REPO_ROOT/scripts/lib/config.sh"
else
  log_warn "config.yaml not found, using defaults"
  SF_DOMAIN="example.com"
  SF_ADSENSE_PUB_ID=""
  SF_GA_ID=""
  SF_AUTHOR_EMAIL=""
fi

TARGET_SITE="${1:-}"
UPDATED=0
SKIPPED=0

update_static_site() {
  local site_dir="$1"
  local site_name
  site_name=$(basename "$site_dir")

  if [[ ! -f "$site_dir/site.yaml" ]]; then
    return 0
  fi

  local site_type
  site_type=$(grep '^type:' "$site_dir/site.yaml" | awk '{print $2}' | tr -d '"')

  if [[ "$site_type" == "hugo" ]]; then
    log_info "  [$site_name] Hugo site — uses theme, auto-updated on build"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  log_step "Updating $site_name..."

  local site_title site_desc site_lang
  site_title=$(grep '^title:' "$site_dir/site.yaml" | sed 's/^title: *//' | tr -d '"')
  site_desc=$(grep '^description:' "$site_dir/site.yaml" | sed 's/^description: *//' | tr -d '"')
  site_lang=$(grep '^language:' "$site_dir/site.yaml" | awk '{print $2}' | tr -d '"')
  site_lang="${site_lang:-en}"

  local site_url="https://${site_name}.${SF_DOMAIN}/"

  # Re-inject SEO into all HTML files (idempotent)
  local inject_count=0
  while IFS= read -r html_file; do
    # Skip compliance pages (they get replaced entirely)
    local fname
    fname=$(basename "$html_file")
    if [[ "$fname" == "privacy-policy.html" ]] || [[ "$fname" == "about.html" ]]; then
      continue
    fi
    inject_all "$html_file" "$SF_ADSENSE_PUB_ID" "$SF_GA_ID" "$site_title" "$site_desc" \
      "$site_url" "$site_title" "$SF_DOMAIN"
    inject_count=$((inject_count + 1))
  done < <(find "$site_dir" -name "*.html" -maxdepth 2 -type f)
  log_ok "  Processed $inject_count HTML files"

  # Update compliance pages (language-aware)
  local shared_dir="$REPO_ROOT/sites/_shared"
  local date
  date=$(date +%Y-%m-%d)
  for base_page in privacy-policy about; do
    local local_page="${base_page}.${site_lang}.html"
    if [[ ! -f "$shared_dir/$local_page" ]]; then
      local_page="${base_page}.en.html"
    fi
    if [[ -f "$shared_dir/$local_page" ]]; then
      cp "$shared_dir/$local_page" "$site_dir/${base_page}.html"
      sed_inplace \
        -e "s|{{SITE_TITLE}}|${site_title}|g" \
        -e "s|{{AUTHOR_EMAIL}}|${SF_AUTHOR_EMAIL}|g" \
        -e "s|{{DATE}}|${date}|g" \
        -e "s|{{DOMAIN}}|${SF_DOMAIN}|g" \
        -e "s|{{LANGUAGE}}|${site_lang}|g" \
        "$site_dir/${base_page}.html"
    fi
  done
  log_ok "  Updated compliance pages (${site_lang})"

  # Update ads.txt
  local pub_numeric="${SF_ADSENSE_PUB_ID#ca-pub-}"
  if [[ -n "$pub_numeric" ]] && [[ "$pub_numeric" != *"XXXX"* ]]; then
    echo "google.com, $pub_numeric, DIRECT, f08c47fec0942fa0" > "$site_dir/ads.txt"
  fi

  UPDATED=$((UPDATED + 1))
}

log_info "=== Updating SiteFactory sites ==="

if [[ -n "$TARGET_SITE" ]]; then
  # Update single site
  site_dir="$REPO_ROOT/sites/$TARGET_SITE"
  if [[ ! -d "$site_dir" ]]; then
    log_error "Site '$TARGET_SITE' not found at $site_dir"
    exit 1
  fi
  update_static_site "$site_dir"
else
  # Update all sites
  for site_dir in "$REPO_ROOT"/sites/*/; do
    site_name=$(basename "$site_dir")
    [[ "$site_name" == "_template" || "$site_name" == "_shared" ]] && continue
    update_static_site "$site_dir"
  done
fi

log_ok "=== Update complete: $UPDATED updated, $SKIPPED skipped (Hugo) ==="
