#!/usr/bin/env bash
# dns-setup.sh - Add CNAME record for a subdomain via NameSilo API.
# Usage: ./scripts/dns-setup.sh <site-name> [--verify]
# Creates: <site-name>.example.com -> cname.vercel-dns.com

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/config.sh"
source "$REPO_ROOT/scripts/lib/logging.sh"

# --- Parse arguments ---
SITE_NAME=""
VERIFY_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --verify) VERIFY_FLAG="--verify" ;;
    *) [[ -z "$SITE_NAME" ]] && SITE_NAME="$arg" ;;
  esac
done
[[ -z "$SITE_NAME" ]] && { echo "Usage: dns-setup.sh <site-name> [--verify]"; exit 1; }

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

# Optional DNS propagation verification
if [[ "$VERIFY_FLAG" == "--verify" ]]; then
  source "$REPO_ROOT/scripts/lib/verify.sh"
  log_step "Verifying DNS propagation (polling up to 2 minutes)..."
  if verify_dns_poll "${SITE_NAME}.${SF_DOMAIN}" "$CNAME_TARGET" 12 10; then
    echo ""
    log_ok "DNS verified: ${SITE_NAME}.${SF_DOMAIN}"
  else
    log_warn "DNS not yet propagated. Check: dig CNAME ${SITE_NAME}.${SF_DOMAIN}"
  fi
fi
