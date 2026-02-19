#!/usr/bin/env bash
# inject.sh - HTML injection functions for fork sites.
# Injects AdSense, Analytics, SEO meta, and compliance pages into HTML files.
# Usage: source scripts/lib/inject.sh

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
    sed -i '' "s|</head>|${snippet}\n</head>|i" "$file"
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

  local snippet='<script async src="https://www.googletagmanager.com/gtag/js?id='"$ga_id"'"></script>\n<script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag("js",new Date());gtag("config","'"$ga_id"'");</script>'

  if grep -qi "</head>" "$file"; then
    sed -i '' "s|</head>|${snippet}\n</head>|i" "$file"
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
      sed -i '' "s|</head>|<meta name=\"description\" content=\"${description}\">\n</head>|i" "$file"
    fi
  fi

  # Add OG tags if missing
  if ! grep -qi 'property="og:title"' "$file" 2>/dev/null; then
    if grep -qi "</head>" "$file"; then
      local og_tags='<meta property="og:title" content="'"$title"'">\n<meta property="og:description" content="'"$description"'">\n<meta property="og:type" content="website">'
      sed -i '' "s|</head>|${og_tags}\n</head>|i" "$file"
    fi
  fi

  log_ok "  Injected SEO meta into $(basename "$file")"
}

# Add privacy policy link before </body>
inject_privacy_link() {
  local file="$1"

  if grep -q "privacy-policy" "$file" 2>/dev/null; then
    return 0
  fi

  local link='<div style="text-align:center;padding:1rem;font-size:0.8rem;color:#666;"><a href="/privacy-policy.html">Privacy Policy</a> | <a href="/about.html">About</a></div>'

  if grep -qi "</body>" "$file"; then
    sed -i '' "s|</body>|${link}\n</body>|i" "$file"
    log_ok "  Injected privacy link into $(basename "$file")"
  fi
}

# Inject all standard elements into an HTML file
inject_all() {
  local file="$1"
  local pub_id="$2"
  local ga_id="$3"
  local title="$4"
  local description="$5"

  inject_adsense "$file" "$pub_id"
  inject_analytics "$file" "$ga_id"
  inject_meta "$file" "$title" "$description"
  inject_privacy_link "$file"
}
