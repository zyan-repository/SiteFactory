#!/usr/bin/env bash
# setup.sh - One-time environment setup for SiteFactory.
# Checks prerequisites, creates config.yaml, validates credentials.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

log_info "=== SiteFactory Setup ==="

# 1. Check prerequisites
log_step "Checking prerequisites..."

MISSING=()
command -v /opt/homebrew/bin/hugo &>/dev/null || command -v hugo &>/dev/null || MISSING+=("hugo (brew install hugo)")
command -v yq &>/dev/null || MISSING+=("yq (brew install yq)")
command -v jq &>/dev/null || MISSING+=("jq (brew install jq)")
command -v npx &>/dev/null || MISSING+=("node/npx (brew install node)")
command -v git &>/dev/null || MISSING+=("git")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  log_error "Missing required tools:"
  for tool in "${MISSING[@]}"; do
    echo "  - $tool"
  done
  echo ""
  log_info "Install all with: brew install hugo yq jq node"
  exit 1
fi
log_ok "All prerequisites installed"

# 2. Config file
if [[ ! -f "$REPO_ROOT/config.yaml" ]]; then
  log_step "Creating config.yaml from template..."
  cp "$REPO_ROOT/config.example.yaml" "$REPO_ROOT/config.yaml"
  log_warn "config.yaml created. Please edit it with your credentials:"
  echo ""
  echo "  Required:"
  echo "    - domain.name           (your NameSilo domain)"
  echo "    - domain.namesilo_api_key"
  echo "    - vercel.token          (from vercel.com/account/tokens)"
  echo "    - adsense.publisher_id  (ca-pub-XXXXXXXX)"
  echo "    - analytics.google_analytics_id (G-XXXXXXXXXX)"
  echo ""
  echo "  Optional (for content generation):"
  echo "    - claude.api_key"
  echo "    - monitoring.uptimerobot_api_key"
  echo ""
  echo "  Edit: $REPO_ROOT/config.yaml"
  echo "  Then re-run: ./scripts/setup.sh"
  exit 0
fi

# 3. Load and validate config
source "$REPO_ROOT/scripts/lib/config.sh"
log_step "Validating configuration..."

ERRORS=()
[[ "$SF_DOMAIN" == "example.com" ]] && ERRORS+=("domain.name is still the placeholder")
[[ "$SF_NAMESILO_API_KEY" == YOUR_* ]] && ERRORS+=("domain.namesilo_api_key not set")
[[ "$SF_VERCEL_TOKEN" == YOUR_* ]] && ERRORS+=("vercel.token not set")
[[ "$SF_ADSENSE_PUB_ID" == *XXXX* ]] && ERRORS+=("adsense.publisher_id not set")
[[ "$SF_GA_ID" == *XXXX* ]] && ERRORS+=("analytics.google_analytics_id not set")

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  log_error "Config validation failed:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  echo ""
  echo "  Edit: $REPO_ROOT/config.yaml"
  exit 1
fi
log_ok "Config values present"

# 4. Verify Vercel token
log_step "Verifying Vercel token..."
VERCEL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $SF_VERCEL_TOKEN" \
  "https://api.vercel.com/v2/user" 2>/dev/null || echo "000")
if [[ "$VERCEL_STATUS" == "200" ]]; then
  log_ok "Vercel token verified"
else
  log_error "Vercel token invalid (HTTP $VERCEL_STATUS)"
  log_info "Get a token at: https://vercel.com/account/tokens"
  exit 1
fi

# 5. Verify NameSilo API key
log_step "Verifying NameSilo API key..."
NS_RESPONSE=$(curl -s "https://www.namesilo.com/api/getDomainInfo?version=1&type=xml&key=${SF_NAMESILO_API_KEY}&domain=${SF_DOMAIN}" 2>/dev/null || echo "")
if echo "$NS_RESPONSE" | grep -q "<code>300</code>"; then
  log_ok "NameSilo API key verified for domain $SF_DOMAIN"
elif echo "$NS_RESPONSE" | grep -q "<code>200</code>"; then
  log_warn "NameSilo returned code 200 - domain may not be in your account"
else
  log_warn "Could not verify NameSilo API key (non-critical, DNS may still work)"
fi

# 6. Hugo version
log_step "Checking Hugo..."
HUGO_VERSION=$(/opt/homebrew/bin/hugo version 2>/dev/null || hugo version 2>/dev/null || echo "unknown")
log_ok "Hugo: $HUGO_VERSION"

log_ok "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Create a Hugo site:  ./scripts/new-site.sh my-blog \"My Blog\" \"A great blog\""
echo "  2. Fork a project:      ./scripts/fork-site.sh <github-url> <name> \"Title\""
echo "  3. Deploy a site:       ./scripts/deploy.sh <name>"
echo "  4. Check compatibility: ./scripts/check-repo.sh <github-url>"
