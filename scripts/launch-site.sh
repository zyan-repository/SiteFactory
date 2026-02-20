#!/usr/bin/env bash
# launch-site.sh - One-command site creation + deployment + verification pipeline.
# Combines create → deploy → DNS → verify into a single step.
#
# Usage:
#   ./scripts/launch-site.sh fork <github-url> <name> ["title"] ["description"]
#   ./scripts/launch-site.sh hugo <name> ["title"] ["description"] [language]
#
# Options:
#   --skip-verify   Skip DNS and HTTP verification phases
#   --root          Also bind root/apex domain to this site
#
# Environment:
#   SF_JSON_OUTPUT=true   Output machine-readable JSON summary

set -euo pipefail
SECONDS=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

# --- Parse arguments (extract flags, then positional args) ---
SKIP_VERIFY=false
ROOT_FLAG=""
POSITIONAL_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --skip-verify) SKIP_VERIFY=true ;;
    --root) ROOT_FLAG="--root" ;;
    *) POSITIONAL_ARGS+=("$arg") ;;
  esac
done

MODE="${POSITIONAL_ARGS[0]:?Usage: launch-site.sh <fork|hugo> ...}"

case "$MODE" in
  fork)
    REPO_URL="${POSITIONAL_ARGS[1]:?Usage: launch-site.sh fork <github-url> <name> [\"title\"] [\"description\"]}"
    SITE_NAME="${POSITIONAL_ARGS[2]:?Please provide a site name}"
    SITE_TITLE="${POSITIONAL_ARGS[3]:-$SITE_NAME}"
    SITE_DESC="${POSITIONAL_ARGS[4]:-A useful web tool}"
    ;;
  hugo)
    SITE_NAME="${POSITIONAL_ARGS[1]:?Usage: launch-site.sh hugo <name> [\"title\"] [\"description\"] [language]}"
    SITE_TITLE="${POSITIONAL_ARGS[2]:-$SITE_NAME}"
    SITE_DESC="${POSITIONAL_ARGS[3]:-A new site}"
    SITE_LANG="${POSITIONAL_ARGS[4]:-en}"
    ;;
  *)
    log_error "Unknown mode: $MODE. Use 'fork' or 'hugo'."
    exit 1
    ;;
esac

# Load config for domain
if [[ -f "$REPO_ROOT/config.yaml" ]]; then
  source "$REPO_ROOT/scripts/lib/config.sh"
fi
source "$REPO_ROOT/scripts/lib/verify.sh"

CUSTOM_DOMAIN="${SITE_NAME}.${SF_DOMAIN:-example.com}"
ROOT_DOMAIN="${SF_DOMAIN:-example.com}"

# Auto-detect --root from site.yaml if not explicitly passed
if [[ -z "$ROOT_FLAG" ]] && [[ -f "$REPO_ROOT/sites/$SITE_NAME/site.yaml" ]] && \
   grep -q "^root_domain: true" "$REPO_ROOT/sites/$SITE_NAME/site.yaml" 2>/dev/null; then
  ROOT_FLAG="--root"
fi

log_info "=== SiteFactory Launch: $SITE_NAME ($MODE) ==="
echo ""

# --- Phase 1: Create site ---
log_step "Phase 1/6: Creating site..."
case "$MODE" in
  fork)
    "$REPO_ROOT/scripts/fork-site.sh" "$REPO_URL" "$SITE_NAME" "$SITE_TITLE" "$SITE_DESC"
    ;;
  hugo)
    "$REPO_ROOT/scripts/new-site.sh" "$SITE_NAME" "$SITE_TITLE" "$SITE_DESC" "$SITE_LANG"
    ;;
esac
echo ""

# --- Phase 2: Deploy ---
log_step "Phase 2/6: Deploying to production..."
"$REPO_ROOT/scripts/deploy.sh" "$SITE_NAME" $ROOT_FLAG
echo ""

# --- Phase 3: DNS ---
log_step "Phase 3/6: Setting up DNS..."
"$REPO_ROOT/scripts/dns-setup.sh" "$SITE_NAME" $ROOT_FLAG
echo ""

# --- Phase 4: Verify DNS ---
DNS_OK=false
if [[ "$SKIP_VERIFY" == "false" ]]; then
  log_step "Phase 4/6: Verifying DNS propagation..."
  if verify_dns_poll "$CUSTOM_DOMAIN" "cname.vercel-dns.com" 12 10; then
    echo ""
    log_ok "DNS verified: $CUSTOM_DOMAIN"
    DNS_OK=true
  else
    log_warn "DNS not yet propagated (this is normal, may take up to 48h)"
    log_info "Check manually: dig CNAME $CUSTOM_DOMAIN"
  fi
  if [[ -n "$ROOT_FLAG" ]]; then
    if verify_dns_a_poll "$ROOT_DOMAIN" "76.76.21.21" 12 10; then
      echo ""
      log_ok "Root DNS verified: $ROOT_DOMAIN"
    else
      log_warn "Root DNS not yet propagated. Check: dig A $ROOT_DOMAIN"
    fi
  fi
  echo ""
else
  log_info "Phase 4/6: DNS verification skipped (--skip-verify)"
  echo ""
fi

# --- Phase 5: HTTP Health Check ---
HTTP_OK=false
if [[ "$SKIP_VERIFY" == "false" ]]; then
  log_step "Phase 5/6: Verifying site is live..."
  SITE_URL="https://$CUSTOM_DOMAIN"
  if verify_http_poll "$SITE_URL" 6 10; then
    echo ""
    log_ok "Site is live: $SITE_URL"
    HTTP_OK=true
  else
    log_warn "Site not yet accessible at $SITE_URL"
    log_info "This will resolve once DNS fully propagates"
  fi
  if [[ -n "$ROOT_FLAG" ]]; then
    ROOT_URL="https://$ROOT_DOMAIN"
    if verify_http_poll "$ROOT_URL" 6 10; then
      echo ""
      log_ok "Root domain is live: $ROOT_URL"
    else
      log_warn "Root domain not yet accessible at $ROOT_URL"
    fi
  fi
  echo ""
else
  log_info "Phase 5/6: HTTP verification skipped (--skip-verify)"
  echo ""
fi

# --- Phase 6: Lighthouse (optional, non-blocking) ---
if [[ "$SKIP_VERIFY" == "false" ]] && [[ "$HTTP_OK" == "true" ]] && command -v npx &>/dev/null; then
  log_step "Phase 6/6: Running Lighthouse audit..."
  if "$REPO_ROOT/scripts/lighthouse-check.sh" "$SITE_NAME" 2>/dev/null; then
    log_ok "Lighthouse audit complete"
  else
    log_warn "Lighthouse audit skipped or failed (non-critical)"
  fi
  echo ""
else
  log_info "Phase 6/6: Lighthouse skipped"
  echo ""
fi

# --- Summary ---
ELAPSED=$SECONDS
log_ok "=== Launch complete! ($((ELAPSED))s) ==="
echo ""
echo "  +------------------------------------------+"
echo "  | Site:    $SITE_NAME"
echo "  | Type:    $MODE"
echo "  | URL:     https://$CUSTOM_DOMAIN"
if [[ -n "$ROOT_FLAG" ]]; then
echo "  | Root:    https://$ROOT_DOMAIN"
fi
echo "  | Dir:     sites/$SITE_NAME"
echo "  | DNS:     $(if [[ "$DNS_OK" == "true" ]]; then echo "verified"; else echo "pending"; fi)"
echo "  | HTTP:    $(if [[ "$HTTP_OK" == "true" ]]; then echo "live"; else echo "pending"; fi)"
echo "  | Time:    ${ELAPSED}s"
echo "  +------------------------------------------+"
echo ""
echo "  Next steps:"
echo "    1. Submit sitemap to Google Search Console"
echo "    2. Wait 1-2 weeks, then apply for AdSense"
echo "    3. Monitor: ./scripts/lighthouse-check.sh $SITE_NAME"

# JSON output for automation (CI, etc.)
if [[ "${SF_JSON_OUTPUT:-false}" == "true" ]] && command -v jq &>/dev/null; then
  ROOT_URL_VAL=""
  [[ -n "$ROOT_FLAG" ]] && ROOT_URL_VAL="https://$ROOT_DOMAIN"
  jq -n \
    --arg name "$SITE_NAME" \
    --arg type "$MODE" \
    --arg url "https://$CUSTOM_DOMAIN" \
    --arg root_url "$ROOT_URL_VAL" \
    --arg dir "sites/$SITE_NAME" \
    --argjson elapsed "$ELAPSED" \
    --argjson dns_ok "$DNS_OK" \
    --argjson http_ok "$HTTP_OK" \
    '{success: true, site_name: $name, site_type: $type, url: $url, root_url: $root_url, directory: $dir, elapsed_seconds: $elapsed, dns_verified: $dns_ok, http_verified: $http_ok}'
fi
