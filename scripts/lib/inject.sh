#!/usr/bin/env bash
# inject.sh - HTML injection functions for fork sites.
# Injects AdSense, Analytics, SEO meta, and compliance pages into HTML files.
# Usage: source scripts/lib/inject.sh

# Load dependencies
# shellcheck source=scripts/lib/logging.sh
source "${BASH_SOURCE[0]%/*}/logging.sh"
# shellcheck source=scripts/lib/platform.sh
source "${BASH_SOURCE[0]%/*}/platform.sh"

# Inject AdSense Auto-Ads script before </head>
inject_adsense() {
  local file="$1"
  local pub_id="$2"

  if [[ -z "$pub_id" ]] || [[ "$pub_id" == *"XXXX"* ]]; then
    log_warn "Skipping AdSense injection (no valid publisher ID)"
    return 0
  fi

  # Skip if already injected
  if grep -q "adsbygoogle" "$file" 2>/dev/null; then
    log_info "  AdSense already present in $(basename "$file")"
    return 0
  fi

  local snippet='<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client='"$pub_id"'" crossorigin="anonymous"></script>'

  if grep -qi "</head>" "$file"; then
    inject_before_tag "</head>" "$snippet" "$file"
    log_ok "  Injected AdSense into $(basename "$file")"
  else
    log_warn "  No </head> tag found in $(basename "$file")"
  fi
}

# Inject Google Analytics gtag.js before </head>
inject_analytics() {
  local file="$1"
  local ga_id="$2"

  if [[ -z "$ga_id" ]] || [[ "$ga_id" == *"XXXX"* ]]; then
    log_warn "Skipping Analytics injection (no valid GA ID)"
    return 0
  fi

  if grep -q "googletagmanager" "$file" 2>/dev/null; then
    log_info "  Analytics already present in $(basename "$file")"
    return 0
  fi

  local snippet
  snippet='<script async src="https://www.googletagmanager.com/gtag/js?id='"$ga_id"'"></script>
<script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag("js",new Date());gtag("config","'"$ga_id"'");</script>'

  if grep -qi "</head>" "$file"; then
    inject_before_tag "</head>" "$snippet" "$file"
    log_ok "  Injected Analytics into $(basename "$file")"
  else
    log_warn "  No </head> tag found in $(basename "$file")"
  fi
}

# Inject or update meta description and Open Graph tags
inject_meta() {
  local file="$1"
  local title="$2"
  local description="$3"

  # Add meta description if missing
  if ! grep -qi 'name="description"' "$file" 2>/dev/null; then
    if grep -qi "</head>" "$file"; then
      inject_before_tag "</head>" '<meta name="description" content="'"${description}"'">' "$file"
    fi
  fi

  # Add OG tags if missing
  if ! grep -qi 'property="og:title"' "$file" 2>/dev/null; then
    if grep -qi "</head>" "$file"; then
      local og_tags
      og_tags='<meta property="og:title" content="'"$title"'">
<meta property="og:description" content="'"$description"'">
<meta property="og:type" content="website">'
      inject_before_tag "</head>" "$og_tags" "$file"
    fi
  fi

  log_ok "  Injected SEO meta into $(basename "$file")"
}

# Inject canonical URL before </head>
inject_canonical() {
  local file="$1"
  local url="$2"

  if [[ -z "$url" ]]; then
    return 0
  fi

  if grep -qi 'rel="canonical"' "$file" 2>/dev/null; then
    log_info "  Canonical already present in $(basename "$file")"
    return 0
  fi

  if grep -qi "</head>" "$file"; then
    inject_before_tag "</head>" '<link rel="canonical" href="'"$url"'">' "$file"
    log_ok "  Injected canonical URL into $(basename "$file")"
  fi
}

# Inject full Open Graph and Twitter Card tags
inject_full_og() {
  local file="$1"
  local title="$2"
  local description="$3"
  local site_url="$4"
  local site_name="$5"

  if [[ -z "$site_url" ]]; then
    return 0
  fi

  # Add og:url if missing
  if ! grep -qi 'property="og:url"' "$file" 2>/dev/null; then
    if grep -qi "</head>" "$file"; then
      inject_before_tag "</head>" '<meta property="og:url" content="'"$site_url"'">' "$file"
    fi
  fi

  # Add og:site_name if missing
  if ! grep -qi 'property="og:site_name"' "$file" 2>/dev/null; then
    if [[ -n "$site_name" ]] && grep -qi "</head>" "$file"; then
      inject_before_tag "</head>" '<meta property="og:site_name" content="'"$site_name"'">' "$file"
    fi
  fi

  # Add og:locale if missing
  if ! grep -qi 'property="og:locale"' "$file" 2>/dev/null; then
    if grep -qi "</head>" "$file"; then
      inject_before_tag "</head>" '<meta property="og:locale" content="en_US">' "$file"
    fi
  fi

  # Add Twitter Card if missing
  if ! grep -qi 'name="twitter:card"' "$file" 2>/dev/null; then
    if grep -qi "</head>" "$file"; then
      local twitter_tags
      twitter_tags='<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="'"$title"'">
<meta name="twitter:description" content="'"$description"'">'
      inject_before_tag "</head>" "$twitter_tags" "$file"
    fi
  fi

  log_ok "  Injected full OG/Twitter into $(basename "$file")"
}

# Inject JSON-LD structured data (WebApplication schema for tools)
inject_json_ld() {
  local file="$1"
  local title="$2"
  local description="$3"
  local site_url="$4"

  if [[ -z "$site_url" ]]; then
    return 0
  fi

  if grep -qi 'application/ld+json' "$file" 2>/dev/null; then
    log_info "  JSON-LD already present in $(basename "$file")"
    return 0
  fi

  if grep -qi "</head>" "$file"; then
    local json_ld
    json_ld='<script type="application/ld+json">{"@context":"https://schema.org","@type":"WebApplication","name":"'"$title"'","url":"'"$site_url"'","description":"'"$description"'","applicationCategory":"UtilityApplication","operatingSystem":"All","offers":{"@type":"Offer","price":"0","priceCurrency":"USD"}}</script>'
    inject_before_tag "</head>" "$json_ld" "$file"
    log_ok "  Injected JSON-LD into $(basename "$file")"
  fi
}

# Inject viewport meta if missing
inject_viewport() {
  local file="$1"

  if grep -qi 'name="viewport"' "$file" 2>/dev/null; then
    return 0
  fi

  if grep -qi "</head>" "$file"; then
    inject_before_tag "</head>" '<meta name="viewport" content="width=device-width, initial-scale=1.0">' "$file"
    log_ok "  Injected viewport meta into $(basename "$file")"
  fi
}

# Inject theme-color meta if missing
inject_theme_color() {
  local file="$1"

  if grep -qi 'name="theme-color"' "$file" 2>/dev/null; then
    return 0
  fi

  if grep -qi "</head>" "$file"; then
    inject_before_tag "</head>" '<meta name="theme-color" content="#0066cc">' "$file"
    log_ok "  Injected theme-color into $(basename "$file")"
  fi
}

# Add privacy policy link before </body>, with optional main domain link
inject_privacy_link() {
  local file="$1"
  local main_domain="${2:-}"

  if grep -q "privacy-policy" "$file" 2>/dev/null; then
    return 0
  fi

  local link
  if [[ -n "$main_domain" ]]; then
    link='<div style="text-align:center;padding:1rem;font-size:0.8rem;color:#666;"><a href="/privacy-policy.html">Privacy Policy</a> | <a href="/about.html">About</a> | <a href="https://'"$main_domain"'/tools/">More Tools</a></div>'
  else
    link='<div style="text-align:center;padding:1rem;font-size:0.8rem;color:#666;"><a href="/privacy-policy.html">Privacy Policy</a> | <a href="/about.html">About</a></div>'
  fi

  if grep -qi "</body>" "$file"; then
    inject_before_tag "</body>" "$link" "$file"
    log_ok "  Injected privacy link into $(basename "$file")"
  fi
}

# Inject all standard elements into an HTML file.
# Args: file pub_id ga_id title description [site_url] [site_name] [main_domain]
inject_all() {
  local file="$1"
  local pub_id="$2"
  local ga_id="$3"
  local title="$4"
  local description="$5"
  local site_url="${6:-}"
  local site_name="${7:-}"
  local main_domain="${8:-}"

  inject_viewport "$file"
  inject_theme_color "$file"
  inject_adsense "$file" "$pub_id"
  inject_analytics "$file" "$ga_id"
  inject_meta "$file" "$title" "$description"
  inject_canonical "$file" "$site_url"
  inject_full_og "$file" "$title" "$description" "$site_url" "$site_name"
  inject_json_ld "$file" "$title" "$description" "$site_url"
  inject_privacy_link "$file" "$main_domain"
}
