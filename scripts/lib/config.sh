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
  echo "ERROR: yq is required. Install: brew install yq (macOS) / apt install yq (Linux)"
  exit 1
fi

# Export all config values as environment variables
# Declare and assign separately to avoid masking return values (SC2155)
SF_DOMAIN=$(yq '.domain.name' "$CONFIG_FILE")
SF_NAMESILO_API_KEY=$(yq '.domain.namesilo_api_key' "$CONFIG_FILE")
SF_VERCEL_TOKEN=$(yq '.vercel.token' "$CONFIG_FILE")
SF_VERCEL_TEAM_ID=$(yq '.vercel.team_id // ""' "$CONFIG_FILE")
SF_ADSENSE_PUB_ID=$(yq '.adsense.publisher_id' "$CONFIG_FILE")
SF_ADSENSE_ENABLED=$(yq '.adsense.enabled' "$CONFIG_FILE")
SF_GA_ID=$(yq '.analytics.google_analytics_id' "$CONFIG_FILE")
SF_GSC_VERIFICATION=$(yq '.analytics.google_search_console_verification // ""' "$CONFIG_FILE")
SF_GSC_KEY_FILE=$(yq '.analytics.google_search_console_key_file // ""' "$CONFIG_FILE")
SF_AI_PROVIDER=$(yq '.ai.provider // "claude"' "$CONFIG_FILE")
SF_AI_API_KEY=$(yq ".ai.providers.${SF_AI_PROVIDER}.api_key // \"\"" "$CONFIG_FILE")
SF_AI_MODEL=$(yq ".ai.providers.${SF_AI_PROVIDER}.model // \"\"" "$CONFIG_FILE")
SF_AI_BASE_URL=$(yq ".ai.providers.${SF_AI_PROVIDER}.base_url // \"\"" "$CONFIG_FILE")
SF_UPTIMEROBOT_API_KEY=$(yq '.monitoring.uptimerobot_api_key // ""' "$CONFIG_FILE")
SF_DEFAULT_LANG=$(yq '.defaults.language // "en"' "$CONFIG_FILE")
SF_TIMEZONE=$(yq '.defaults.timezone // "America/New_York"' "$CONFIG_FILE")
SF_AUTHOR_NAME=$(yq '.defaults.author.name // "SiteFactory"' "$CONFIG_FILE")
SF_AUTHOR_EMAIL=$(yq '.defaults.author.email // ""' "$CONFIG_FILE")
SF_CONTENT_SCHEDULE=$(yq '.content.default_schedule // "weekly"' "$CONFIG_FILE")
SF_CONTENT_TOPIC_COUNT=$(yq '.content.default_topic_count // "25"' "$CONFIG_FILE")
SF_CONTENT_SEED_ARTICLES=$(yq '.content.default_seed_articles // "5"' "$CONFIG_FILE")

# Validate critical fields (yq returns literal "null" for missing keys)
for _var in SF_DOMAIN SF_VERCEL_TOKEN; do
  if [[ "${!_var}" == "null" || -z "${!_var}" ]]; then
    echo "ERROR: Required config field missing or null: $_var"
    echo "Check your config.yaml — see config.example.yaml for reference."
    exit 1
  fi
done

export SF_DOMAIN SF_NAMESILO_API_KEY SF_VERCEL_TOKEN SF_VERCEL_TEAM_ID
export SF_ADSENSE_PUB_ID SF_ADSENSE_ENABLED SF_GA_ID SF_GSC_VERIFICATION SF_GSC_KEY_FILE
export SF_AI_PROVIDER SF_AI_API_KEY SF_AI_MODEL SF_AI_BASE_URL
export SF_UPTIMEROBOT_API_KEY
export SF_DEFAULT_LANG SF_TIMEZONE SF_AUTHOR_NAME SF_AUTHOR_EMAIL
export SF_CONTENT_SCHEDULE SF_CONTENT_TOPIC_COUNT SF_CONTENT_SEED_ARTICLES
