#!/usr/bin/env bash
# dns-setup.sh - Add DNS records for a site via NameSilo API.
# Usage: ./scripts/dns-setup.sh <site-name> [--root] [--verify]
# Default: Creates CNAME for <site-name>.example.com -> cname.vercel-dns.com
# --root:  Also creates A record for apex domain and CNAME for www

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/config.sh"
source "$REPO_ROOT/scripts/lib/logging.sh"

# --- Parse arguments ---
SITE_NAME=""
VERIFY_FLAG=""
ROOT_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --verify) VERIFY_FLAG="--verify" ;;
    --root) ROOT_FLAG="--root" ;;
    *) [[ -z "$SITE_NAME" ]] && SITE_NAME="$arg" ;;
  esac
done
[[ -z "$SITE_NAME" ]] && { echo "Usage: dns-setup.sh <site-name> [--root] [--verify]"; exit 1; }

CNAME_TARGET="cname.vercel-dns.com"

log_info "Adding CNAME: ${SITE_NAME}.${SF_DOMAIN} -> ${CNAME_TARGET}"

RESPONSE=$(curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=xml&key=${SF_NAMESILO_API_KEY}&domain=${SF_DOMAIN}&rrtype=CNAME&rrhost=${SITE_NAME}&rrvalue=${CNAME_TARGET}&rrttl=3600" 2>/dev/null || echo "")

if echo "$RESPONSE" | grep -q "<code>300</code>"; then
  RECORD_ID=$(echo "$RESPONSE" | grep -o '<record_id>[^<]*' | cut -d'>' -f2)
  log_ok "CNAME record created (record_id: $RECORD_ID)"
elif echo "$RESPONSE" | grep -q "already exists"; then
  log_warn "CNAME record already exists for ${SITE_NAME}.${SF_DOMAIN}"
else
  ERROR_DETAIL=$(echo "$RESPONSE" | grep -o '<detail>[^<]*' | cut -d'>' -f2 || echo "Unknown error")
  log_error "Failed to create CNAME: $ERROR_DETAIL"
  log_warn "You may need to add the CNAME manually in NameSilo dashboard:"
  echo "  Host:  $SITE_NAME"
  echo "  Type:  CNAME"
  echo "  Value: $CNAME_TARGET"
  echo "  TTL:   3600"
fi

# --- Root domain DNS (apex A record + www CNAME) ---
if [[ "$ROOT_FLAG" == "--root" ]]; then
  VERCEL_IP="76.76.21.21"

  log_info "Adding A record: ${SF_DOMAIN} -> ${VERCEL_IP}"
  A_RESPONSE=$(curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=xml&key=${SF_NAMESILO_API_KEY}&domain=${SF_DOMAIN}&rrtype=A&rrhost=&rrvalue=${VERCEL_IP}&rrttl=3600" 2>/dev/null || echo "")

  if echo "$A_RESPONSE" | grep -q "<code>300</code>"; then
    log_ok "A record created for ${SF_DOMAIN}"
  elif echo "$A_RESPONSE" | grep -q "already exists"; then
    log_warn "A record already exists for ${SF_DOMAIN}"
  else
    ERROR_DETAIL=$(echo "$A_RESPONSE" | grep -o '<detail>[^<]*' | cut -d'>' -f2 || echo "Unknown error")
    log_error "Failed to create A record: $ERROR_DETAIL"
    log_warn "Add manually: Type=A, Host=(empty), Value=$VERCEL_IP, TTL=3600"
  fi

  log_info "Adding CNAME: www.${SF_DOMAIN} -> ${CNAME_TARGET}"
  WWW_RESPONSE=$(curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=xml&key=${SF_NAMESILO_API_KEY}&domain=${SF_DOMAIN}&rrtype=CNAME&rrhost=www&rrvalue=${CNAME_TARGET}&rrttl=3600" 2>/dev/null || echo "")

  if echo "$WWW_RESPONSE" | grep -q "<code>300</code>"; then
    log_ok "www CNAME record created"
  elif echo "$WWW_RESPONSE" | grep -q "already exists"; then
    log_warn "www CNAME record already exists"
  else
    log_warn "Failed to create www CNAME (may already exist)"
  fi
fi

# Optional DNS propagation verification
if [[ "$VERIFY_FLAG" == "--verify" ]]; then
  source "$REPO_ROOT/scripts/lib/verify.sh"

  log_step "Verifying subdomain DNS propagation (polling up to 2 minutes)..."
  if verify_dns_poll "${SITE_NAME}.${SF_DOMAIN}" "$CNAME_TARGET" 12 10; then
    echo ""
    log_ok "DNS verified: ${SITE_NAME}.${SF_DOMAIN}"
  else
    log_warn "DNS not yet propagated. Check: dig CNAME ${SITE_NAME}.${SF_DOMAIN}"
  fi

  if [[ "$ROOT_FLAG" == "--root" ]]; then
    log_step "Verifying apex DNS propagation..."
    if verify_dns_a_poll "${SF_DOMAIN}" "76.76.21.21" 12 10; then
      echo ""
      log_ok "DNS verified: ${SF_DOMAIN}"
    else
      log_warn "Apex DNS not yet propagated. Check: dig A ${SF_DOMAIN}"
    fi
  fi
fi
