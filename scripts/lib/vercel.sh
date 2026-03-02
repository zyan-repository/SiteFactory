#!/usr/bin/env bash
# vercel.sh - Vercel project management helpers.
# Ensures deploy directories are linked to correctly-named Vercel projects.
# Requires: logging.sh must be sourced before this file.
# Usage: source scripts/lib/vercel.sh

# Verify that the Vercel API token is valid and not expired.
# Makes a lightweight HTTP call to the Vercel user endpoint.
# Returns 1 with a clear error message if the token is invalid.
# Network failures are non-fatal (token may still be valid).
#
# Usage: verify_vercel_token <token> || exit 1
verify_vercel_token() {
  local token="$1"

  if [[ -z "$token" ]]; then
    log_error "Vercel token is empty. Check config.yaml or SF_VERCEL_TOKEN env var."
    log_info "Generate a token at: https://vercel.com/account/tokens"
    return 1
  fi

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -H "Authorization: Bearer $token" \
    "https://api.vercel.com/v2/user" 2>/dev/null || echo "000")

  case "$http_code" in
    200)
      return 0
      ;;
    401|403)
      log_error "Vercel token is invalid or expired (HTTP $http_code)."
      log_info "Generate a new token at: https://vercel.com/account/tokens"
      log_info "Then update config.yaml -> vercel.token (or SF_VERCEL_TOKEN in CI secrets)."
      return 1
      ;;
    000)
      log_warn "Could not reach Vercel API (network issue). Proceeding anyway."
      return 0
      ;;
    *)
      log_warn "Vercel API returned unexpected HTTP $http_code. Proceeding anyway."
      return 0
      ;;
  esac
}

# Check Vercel CLI output for authentication error patterns.
# Returns 0 if auth errors found (meaning: there IS a problem), 1 if clean.
#
# Usage: if check_vercel_auth_error "$output_file"; then exit 1; fi
check_vercel_auth_error() {
  local output_file="$1"

  if [[ ! -f "$output_file" ]]; then
    return 1
  fi

  if grep -qiE "not_authorized|invalid_token|The specified token is not valid|token is not valid|forbidden" "$output_file"; then
    log_error "Vercel authentication failed. Your token is invalid or expired."
    log_info "Generate a new token at: https://vercel.com/account/tokens"
    log_info "Then update config.yaml -> vercel.token (or SF_VERCEL_TOKEN in CI secrets)."
    return 0
  fi

  return 1
}

# Link a deploy directory to a Vercel project with the correct name.
# This creates .vercel/project.json in the target directory, ensuring
# subsequent `vercel deploy` commands use the right project name.
#
# For Hugo sites deployed from sites/{name}/public/, this prevents
# Vercel from auto-naming the project "public" (the directory name)
# instead of the actual site name.
#
# Usage: vercel_link_project <deploy_dir> <project_name> <token>
vercel_link_project() {
  local deploy_dir="$1"
  local project_name="$2"
  local token="$3"

  # Detect scope from existing .vercel/project.json or SF_VERCEL_TEAM_ID
  local scope_args=()
  local existing_json="$deploy_dir/.vercel/project.json"
  if [[ -n "${SF_VERCEL_TEAM_ID:-}" ]]; then
    scope_args=("--scope" "$SF_VERCEL_TEAM_ID")
  elif [[ -f "$existing_json" ]] && command -v jq &>/dev/null; then
    local org_id
    org_id=$(jq -r '.orgId // empty' "$existing_json" 2>/dev/null)
    if [[ -n "$org_id" ]]; then
      scope_args=("--scope" "$org_id")
    fi
  fi

  npx vercel link --project "$project_name" --yes --cwd "$deploy_dir" --token "$token" "${scope_args[@]}" 2>/dev/null || {
    log_warn "Could not link project '$project_name' — Vercel will auto-detect"
    return 1
  }
}

# Resolve the actual Vercel project name for a given site.
# Reads from .vercel/project.json in the appropriate directory.
#
# For Hugo sites: reads sites/{name}/public/.vercel/project.json
# For static sites: reads sites/{name}/.vercel/project.json
# Falls back to the logical site name if no project.json exists.
#
# Usage: VERCEL_PROJECT=$(resolve_vercel_project <site_dir> <site_type> <site_name>)
resolve_vercel_project() {
  local site_dir="$1"
  local site_type="$2"
  local site_name="$3"

  local project_json
  if [[ "$site_type" == "hugo" ]]; then
    project_json="$site_dir/public/.vercel/project.json"
  else
    project_json="$site_dir/.vercel/project.json"
  fi

  if [[ -f "$project_json" ]] && command -v jq &>/dev/null; then
    local name
    name=$(jq -r '.projectName // empty' "$project_json" 2>/dev/null)
    if [[ -n "$name" ]]; then
      echo "$name"
      return 0
    fi
  fi

  # Fallback: use logical site name
  echo "$site_name"
}
