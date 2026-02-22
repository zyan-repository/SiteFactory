#!/usr/bin/env bash
# gsc.sh - Google Search Console API helpers (sitemap submission, site management).
# Usage: source scripts/lib/gsc.sh
#
# Requires: config.sh sourced first (for SF_GSC_KEY_FILE), openssl, jq, curl
#
# Functions:
#   gsc_get_token          - Get OAuth2 access token from Service Account JSON
#   gsc_add_site <url>     - Add a site property to GSC
#   gsc_submit_sitemap <site_url> <sitemap_url> - Submit sitemap to GSC

# Get OAuth2 access token from Google Service Account JSON key file.
# Outputs access token to stdout. Returns 1 on failure.
gsc_get_token() {
  local key_file="${SF_GSC_KEY_FILE:-}"

  if [[ -z "$key_file" || ! -f "$key_file" ]]; then
    echo "ERROR: GSC key file not found: $key_file" >&2
    return 1
  fi

  for cmd in openssl jq curl; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "ERROR: $cmd is required for GSC integration" >&2
      return 1
    fi
  done

  local client_email private_key
  client_email=$(jq -r '.client_email' "$key_file")
  private_key=$(jq -r '.private_key' "$key_file")

  if [[ -z "$client_email" || "$client_email" == "null" ]]; then
    echo "ERROR: Invalid service account JSON (missing client_email)" >&2
    return 1
  fi

  # Build JWT
  local now exp header claims
  now=$(date +%s)
  exp=$((now + 3600))

  header=$(printf '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
  claims=$(printf '{"iss":"%s","scope":"https://www.googleapis.com/auth/webmasters","aud":"https://oauth2.googleapis.com/token","iat":%d,"exp":%d}' \
    "$client_email" "$now" "$exp" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

  # Sign with RS256
  local key_file_tmp signature
  key_file_tmp=$(mktemp)
  printf '%s' "$private_key" > "$key_file_tmp"
  signature=$(printf '%s.%s' "$header" "$claims" | \
    openssl dgst -sha256 -sign "$key_file_tmp" -binary | \
    openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
  rm -f "$key_file_tmp"

  local jwt="${header}.${claims}.${signature}"

  # Exchange JWT for access token
  local response access_token
  response=$(curl -s -X POST "https://oauth2.googleapis.com/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}")

  access_token=$(echo "$response" | jq -r '.access_token // empty')

  if [[ -z "$access_token" ]]; then
    echo "ERROR: Failed to get access token: $(echo "$response" | jq -r '.error_description // .error // "unknown error"')" >&2
    return 1
  fi

  echo "$access_token"
}

# Add a site property to GSC. Idempotent (no error if already exists).
# Usage: gsc_add_site "https://example.com/"
gsc_add_site() {
  local site_url="$1"
  local token
  token=$(gsc_get_token) || return 1

  local encoded_url
  encoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$site_url', safe=''))" 2>/dev/null || \
    printf '%s' "$site_url" | jq -sRr @uri)

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    "https://www.googleapis.com/webmasters/v3/sites/${encoded_url}" \
    -H "Authorization: Bearer $token" \
    -H "Content-Length: 0")

  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    return 0
  else
    echo "WARN: GSC add site returned HTTP $http_code (may already exist)" >&2
    return 0  # Non-fatal: site may already be added
  fi
}

# Submit a sitemap to GSC.
# Usage: gsc_submit_sitemap "https://example.com/" "https://example.com/sitemap.xml"
gsc_submit_sitemap() {
  local site_url="$1"
  local sitemap_url="$2"
  local token
  token=$(gsc_get_token) || return 1

  local encoded_site encoded_sitemap
  encoded_site=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$site_url', safe=''))" 2>/dev/null || \
    printf '%s' "$site_url" | jq -sRr @uri)
  encoded_sitemap=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$sitemap_url', safe=''))" 2>/dev/null || \
    printf '%s' "$sitemap_url" | jq -sRr @uri)

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    "https://www.googleapis.com/webmasters/v3/sites/${encoded_site}/sitemaps/${encoded_sitemap}" \
    -H "Authorization: Bearer $token" \
    -H "Content-Length: 0")

  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    return 0
  else
    echo "ERROR: GSC submit sitemap returned HTTP $http_code" >&2
    return 1
  fi
}
