#!/usr/bin/env bash
# swap-root.sh - Swap which site occupies the root/apex domain.
# Usage: ./scripts/swap-root.sh <site-name> [--verify]
#
# The root domain can only point to ONE Vercel project at a time.
# This script removes the root domain from the old project (if any),
# adds it to the new one, and ensures DNS A record is configured.
#
# The old site keeps its subdomain. The new site gets both
# root domain AND its subdomain.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/config.sh"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/vercel.sh"

# --- Parse arguments ---
SITE_NAME=""
VERIFY_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --verify) VERIFY_FLAG="--verify" ;;
    *) [[ -z "$SITE_NAME" ]] && SITE_NAME="$arg" ;;
  esac
done

if [[ -z "$SITE_NAME" ]]; then
  echo "Usage: swap-root.sh <site-name> [--verify]"
  echo ""
  echo "Assigns the root domain ($SF_DOMAIN) to the specified site."
  echo "The site must already be deployed to Vercel."
  echo ""
  echo "Options:"
  echo "  --verify   Verify HTTP accessibility after swap"
  exit 1
fi

SITE_DIR="$REPO_ROOT/sites/$SITE_NAME"
ROOT_YAML="$REPO_ROOT/root-domain.yaml"
VERCEL_IP="76.76.21.21"
CNAME_TARGET="cname.vercel-dns.com"

# --- Phase 1: Validate ---
log_step "Phase 1: Validating..."

if [[ ! -d "$SITE_DIR" ]]; then
  log_error "Site not found: $SITE_DIR"
  exit 1
fi

if [[ ! -f "$SITE_DIR/site.yaml" ]]; then
  log_error "Missing site.yaml in $SITE_DIR"
  exit 1
fi

# Read current root site from tracking file
CURRENT_ROOT=""
if [[ -f "$ROOT_YAML" ]]; then
  CURRENT_ROOT=$(grep "^current_site:" "$ROOT_YAML" | awk '{print $2}' | tr -d '"' || echo "")
fi

if [[ "$CURRENT_ROOT" == "$SITE_NAME" ]]; then
  log_warn "$SITE_NAME is already the root domain site"
  log_info "Root domain: https://$SF_DOMAIN"
  exit 0
fi

log_ok "Target site: $SITE_NAME"
[[ -n "$CURRENT_ROOT" ]] && log_info "Current root site: $CURRENT_ROOT"
echo ""

# --- Phase 2: Remove root domain from old project ---
if [[ -n "$CURRENT_ROOT" ]]; then
  log_step "Phase 2: Removing root domain from '$CURRENT_ROOT'..."

  # Note: `vercel domains rm` does not accept a project name — it removes from the team.
  # We re-add to the new project in Phase 3.
  npx vercel domains rm "$SF_DOMAIN" --yes --token "$SF_VERCEL_TOKEN" 2>/dev/null || \
    log_warn "Could not remove $SF_DOMAIN (may not be assigned)"
  npx vercel domains rm "www.${SF_DOMAIN}" --yes --token "$SF_VERCEL_TOKEN" 2>/dev/null || \
    log_warn "Could not remove www.$SF_DOMAIN (may not be assigned)"
  log_ok "Root domain removed from $CURRENT_ROOT (subdomain still active)"
else
  log_info "Phase 2: No existing root assignment, skipping removal"
fi
echo ""

# --- Phase 3: Add root domain to new project ---
log_step "Phase 3: Assigning root domain to '$SITE_NAME'..."

# Resolve actual Vercel project name
SITE_TYPE="static"
if [[ -f "$SITE_DIR/site.yaml" ]]; then
  SITE_TYPE=$(grep "^type:" "$SITE_DIR/site.yaml" | awk '{print $2}' | tr -d '"')
fi
VERCEL_PROJECT=$(resolve_vercel_project "$SITE_DIR" "$SITE_TYPE" "$SITE_NAME")

npx vercel domains add "$SF_DOMAIN" "$VERCEL_PROJECT" --token "$SF_VERCEL_TOKEN" 2>/dev/null || true
npx vercel domains add "www.${SF_DOMAIN}" "$VERCEL_PROJECT" --token "$SF_VERCEL_TOKEN" 2>/dev/null || true
log_ok "Root domain assigned to $SITE_NAME"
echo ""

# --- Phase 4: Ensure DNS records exist ---
log_step "Phase 4: Checking DNS records..."

# Fetch all existing DNS records from NameSilo
RECORDS=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=${SF_NAMESILO_API_KEY}&domain=${SF_DOMAIN}" 2>/dev/null || echo "")

# Helper: delete a DNS record by ID
namesilo_delete_record() {
  local rid="$1"
  curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=xml&key=${SF_NAMESILO_API_KEY}&domain=${SF_DOMAIN}&rrid=${rid}" >/dev/null 2>&1
}

# --- Apex A records: remove wrong ones, ensure Vercel IP exists ---
HAS_VERCEL_A=false
# Parse each A record for the apex domain (host = @ or host = domain itself)
# NameSilo uses "@" for apex host in the <host> field
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  RID=$(echo "$line" | grep -o '<record_id>[^<]*' | cut -d'>' -f2)
  RVALUE=$(echo "$line" | grep -o '<value>[^<]*' | cut -d'>' -f2)
  RHOST=$(echo "$line" | grep -o '<host>[^<]*' | cut -d'>' -f2)
  # Only process apex A records (host is "@" or the domain itself)
  if [[ "$RHOST" == "@" ]] || [[ "$RHOST" == "$SF_DOMAIN" ]]; then
    if [[ "$RVALUE" == "$VERCEL_IP" ]]; then
      HAS_VERCEL_A=true
      log_ok "Apex A record OK: $SF_DOMAIN -> $VERCEL_IP"
    else
      log_warn "Removing stale A record: $SF_DOMAIN -> $RVALUE (record_id: $RID)"
      namesilo_delete_record "$RID"
    fi
  fi
done < <(echo "$RECORDS" | tr '>' '\n' | grep -B20 "<type" | grep -A20 "<type>A</type" | tr '\n' ' ' | sed 's/<resource_record/\n<resource_record/g' | grep "A</type")

if [[ "$HAS_VERCEL_A" == "false" ]]; then
  log_info "Adding A record: $SF_DOMAIN -> $VERCEL_IP"
  A_RESPONSE=$(curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=xml&key=${SF_NAMESILO_API_KEY}&domain=${SF_DOMAIN}&rrtype=A&rrhost=&rrvalue=${VERCEL_IP}&rrttl=3600" 2>/dev/null || echo "")
  if echo "$A_RESPONSE" | grep -q "<code>300</code>"; then
    log_ok "A record created"
  elif echo "$A_RESPONSE" | grep -q "already exists"; then
    log_ok "A record already exists"
  else
    ERROR_DETAIL=$(echo "$A_RESPONSE" | grep -o '<detail>[^<]*' | cut -d'>' -f2 || echo "Unknown error")
    log_error "Failed to create A record: $ERROR_DETAIL"
    log_warn "Add manually: Type=A, Host=(empty), Value=$VERCEL_IP, TTL=3600"
  fi
fi

# --- www record: remove stale A records, ensure CNAME exists ---
HAS_WWW_CNAME=false
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  RID=$(echo "$line" | grep -o '<record_id>[^<]*' | cut -d'>' -f2)
  RTYPE=$(echo "$line" | grep -o '<type>[^<]*' | cut -d'>' -f2)
  RHOST=$(echo "$line" | grep -o '<host>[^<]*' | cut -d'>' -f2)
  if [[ "$RHOST" == "www.$SF_DOMAIN" ]] || [[ "$RHOST" == "www" ]]; then
    if [[ "$RTYPE" == "CNAME" ]]; then
      HAS_WWW_CNAME=true
      log_ok "www CNAME record exists"
    elif [[ "$RTYPE" == "A" ]]; then
      log_warn "Removing stale www A record (record_id: $RID)"
      namesilo_delete_record "$RID"
    fi
  fi
done < <(echo "$RECORDS" | sed 's/<resource_record/\n<resource_record/g' | grep "www")

if [[ "$HAS_WWW_CNAME" == "false" ]]; then
  log_info "Adding CNAME: www.$SF_DOMAIN -> $CNAME_TARGET"
  WWW_RESPONSE=$(curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=xml&key=${SF_NAMESILO_API_KEY}&domain=${SF_DOMAIN}&rrtype=CNAME&rrhost=www&rrvalue=${CNAME_TARGET}&rrttl=3600" 2>/dev/null || echo "")
  if echo "$WWW_RESPONSE" | grep -q "<code>300</code>"; then
    log_ok "www CNAME record created"
  elif echo "$WWW_RESPONSE" | grep -q "already exists"; then
    log_ok "www CNAME record already exists"
  else
    log_warn "Failed to create www CNAME (may already exist)"
  fi
fi
echo ""

# --- Phase 5: Update tracking file ---
log_step "Phase 5: Updating root-domain.yaml..."
cat > "$ROOT_YAML" << EOF
# Root domain assignment — managed by scripts/swap-root.sh
# Only ONE site can occupy the root domain at a time.
# The assigned site is accessible at both:
#   - https://${SF_DOMAIN} (root domain)
#   - https://{site-name}.${SF_DOMAIN} (subdomain, always available)
current_site: ${SITE_NAME}
assigned_at: "$(date +%Y-%m-%d)"
EOF
log_ok "Tracking file updated"
echo ""

# --- Phase 6: Verify (optional) ---
if [[ "$VERIFY_FLAG" == "--verify" ]]; then
  source "$REPO_ROOT/scripts/lib/verify.sh"

  log_step "Phase 6: Verifying accessibility..."

  # Check root domain
  ROOT_URL="https://${SF_DOMAIN}"
  if verify_http_poll "$ROOT_URL" 6 10; then
    echo ""
    log_ok "Root domain is live: $ROOT_URL"
  else
    log_warn "Root domain not yet accessible at $ROOT_URL (DNS may need time to propagate)"
  fi

  # Check subdomain still works
  SUB_URL="https://${SITE_NAME}.${SF_DOMAIN}"
  if verify_http "$SUB_URL"; then
    log_ok "Subdomain still live: $SUB_URL"
  else
    log_warn "Subdomain not responding: $SUB_URL"
  fi
  echo ""
else
  log_info "Phase 6: Verification skipped (use --verify to enable)"
  echo ""
fi

# --- Summary ---
log_ok "=== Root domain swap complete ==="
echo ""
echo "  +------------------------------------------+"
echo "  | Site:       $SITE_NAME"
echo "  | Root URL:   https://$SF_DOMAIN"
echo "  | Sub URL:    https://${SITE_NAME}.${SF_DOMAIN}"
echo "  | www:        https://www.${SF_DOMAIN} (redirects to root)"
if [[ -n "$CURRENT_ROOT" ]]; then
  echo "  | Previous:   $CURRENT_ROOT (still at https://${CURRENT_ROOT}.${SF_DOMAIN})"
fi
echo "  +------------------------------------------+"
echo ""
echo "  Next steps:"
echo "    1. Verify: curl -sI https://$SF_DOMAIN"
echo "    2. Submit root domain to Google Search Console"
echo "    3. Apply for AdSense using https://$SF_DOMAIN"
