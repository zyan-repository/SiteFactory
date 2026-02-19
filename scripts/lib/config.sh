#!/usr/bin/env bash
# config.sh - Parse config.yaml and export variables for all scripts.
# Usage: source scripts/lib/config.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/config.yaml"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: config.yaml not found. Run: cp config.example.yaml config.yaml"
  exit 1
fi

if ! command -v yq &>/dev/null; then
  echo "ERROR: yq is required. Install: brew install yq"
  exit 1
fi

# Export all config values as environment variables
export SF_DOMAIN=$(yq '.domain.name' "$CONFIG_FILE")
export SF_NAMESILO_API_KEY=$(yq '.domain.namesilo_api_key' "$CONFIG_FILE")
export SF_VERCEL_TOKEN=$(yq '.vercel.token' "$CONFIG_FILE")
export SF_VERCEL_TEAM_ID=$(yq '.vercel.team_id // ""' "$CONFIG_FILE")
export SF_ADSENSE_PUB_ID=$(yq '.adsense.publisher_id' "$CONFIG_FILE")
export SF_ADSENSE_ENABLED=$(yq '.adsense.enabled' "$CONFIG_FILE")
export SF_GA_ID=$(yq '.analytics.google_analytics_id' "$CONFIG_FILE")
export SF_GSC_VERIFICATION=$(yq '.analytics.google_search_console_verification // ""' "$CONFIG_FILE")
export SF_CLAUDE_API_KEY=$(yq '.claude.api_key // ""' "$CONFIG_FILE")
export SF_CLAUDE_MODEL=$(yq '.claude.model // "claude-sonnet-4-20250514"' "$CONFIG_FILE")
export SF_UPTIMEROBOT_API_KEY=$(yq '.monitoring.uptimerobot_api_key // ""' "$CONFIG_FILE")
export SF_N8N_BASE_URL=$(yq '.n8n.base_url // "http://localhost:5678"' "$CONFIG_FILE")
export SF_DEFAULT_LANG=$(yq '.defaults.language // "en"' "$CONFIG_FILE")
export SF_TIMEZONE=$(yq '.defaults.timezone // "America/New_York"' "$CONFIG_FILE")
export SF_AUTHOR_NAME=$(yq '.defaults.author.name // "SiteFactory"' "$CONFIG_FILE")
export SF_AUTHOR_EMAIL=$(yq '.defaults.author.email // ""' "$CONFIG_FILE")
