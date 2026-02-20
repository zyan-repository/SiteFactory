#!/usr/bin/env bash
# vercel.sh - Vercel project management helpers.
# Ensures deploy directories are linked to correctly-named Vercel projects.
# Usage: source scripts/lib/vercel.sh

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
