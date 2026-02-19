#!/usr/bin/env bash
# check-repo.sh - Evaluate a GitHub project for SiteFactory compatibility.
# Usage: ./scripts/check-repo.sh <github-url>
#
# Checks: license, backend files, database deps, frontend-only validation.
# Output: Colored report with final verdict (COMPATIBLE / NEEDS REVIEW / INCOMPATIBLE).
# Read-only: clones to temp dir and cleans up.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

REPO_URL="${1:?Usage: check-repo.sh <github-url>}"
TMPDIR=$(mktemp -d)
SCORE=0
ISSUES=()
WARNINGS=()

# shellcheck disable=SC2317,SC2329 # Called indirectly via trap
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

log_info "=== SiteFactory Compatibility Check ==="
log_info "Repository: $REPO_URL"
echo ""

# Clone (shallow)
log_step "Cloning repository..."
if ! git clone --depth 1 --quiet "$REPO_URL" "$TMPDIR/repo" 2>/dev/null; then
  log_error "Failed to clone repository"
  exit 1
fi

REPO="$TMPDIR/repo"

# --- Check 1: License ---
log_step "Checking license..."
LICENSE_FILE=""
for f in LICENSE LICENSE.md LICENSE.txt LICENCE LICENCE.md; do
  [[ -f "$REPO/$f" ]] && LICENSE_FILE="$REPO/$f" && break
done

if [[ -z "$LICENSE_FILE" ]]; then
  ISSUES+=("No LICENSE file found")
  log_error "  No LICENSE file found"
else
  LICENSE_CONTENT=$(head -20 "$LICENSE_FILE" | tr '[:upper:]' '[:lower:]')
  if echo "$LICENSE_CONTENT" | grep -q "mit license\|permission is hereby granted"; then
    log_ok "  License: MIT"
    SCORE=$((SCORE + 20))
  elif echo "$LICENSE_CONTENT" | grep -q "apache license"; then
    log_ok "  License: Apache 2.0"
    SCORE=$((SCORE + 20))
  elif echo "$LICENSE_CONTENT" | grep -q "bsd"; then
    log_ok "  License: BSD"
    SCORE=$((SCORE + 20))
  elif echo "$LICENSE_CONTENT" | grep -q "gpl\|gnu general public"; then
    ISSUES+=("GPL license - not compatible with commercial use")
    log_error "  License: GPL (INCOMPATIBLE)"
  else
    WARNINGS+=("Unknown license - manual review needed")
    log_warn "  License: Unknown (review manually)"
    SCORE=$((SCORE + 5))
  fi
fi

# --- Check 2: Backend files ---
log_step "Scanning for backend components..."
BACKEND_FILES=()
for pattern in "server.js" "server.ts" "app.py" "main.py" "manage.py" "main.go" \
               "docker-compose.yml" "Dockerfile" "Gemfile" "go.mod" \
               "requirements.txt" "Pipfile" "pom.xml" "build.gradle"; do
  found=$(find "$REPO" -name "$pattern" -maxdepth 3 2>/dev/null | head -3)
  [[ -n "$found" ]] && BACKEND_FILES+=("$pattern")
done

if [[ ${#BACKEND_FILES[@]} -eq 0 ]]; then
  log_ok "  No backend files detected"
  SCORE=$((SCORE + 20))
else
  for f in "${BACKEND_FILES[@]}"; do
    log_warn "  Found: $f"
  done
  # Check if it's just a dev tool (e.g., Dockerfile for static build)
  if [[ ${#BACKEND_FILES[@]} -le 1 ]] && echo "${BACKEND_FILES[*]}" | grep -q "Dockerfile"; then
    WARNINGS+=("Dockerfile found - might be build-only")
    SCORE=$((SCORE + 10))
  else
    ISSUES+=("Backend files detected: ${BACKEND_FILES[*]}")
  fi
fi

# --- Check 3: Server-side dependencies in package.json ---
log_step "Analyzing package.json dependencies..."
if [[ -f "$REPO/package.json" ]]; then
  SERVER_DEPS=""
  for dep in express koa fastify next nuxt nest hapi restify; do
    if grep -q "\"$dep\"" "$REPO/package.json" 2>/dev/null; then
      SERVER_DEPS="$SERVER_DEPS $dep"
    fi
  done
  if [[ -z "$SERVER_DEPS" ]]; then
    log_ok "  No server-side frameworks in package.json"
    SCORE=$((SCORE + 15))
  else
    ISSUES+=("Server frameworks found:$SERVER_DEPS")
    log_error "  Server frameworks found:$SERVER_DEPS"
  fi
else
  log_ok "  No package.json (pure HTML/CSS/JS)"
  SCORE=$((SCORE + 15))
fi

# --- Check 4: Database references ---
log_step "Scanning for database dependencies..."
DB_FOUND=false
for db_keyword in DATABASE_URL MONGODB MYSQL POSTGRES REDIS_URL; do
  if find "$REPO" -maxdepth 3 -name "*.js" -o -name "*.ts" -o -name "*.json" 2>/dev/null \
    | grep -v node_modules \
    | head -50 \
    | xargs grep -l "$db_keyword" 2>/dev/null | head -1 | grep -q .; then
    DB_FOUND=true
    break
  fi
done

if [[ "$DB_FOUND" == "false" ]]; then
  log_ok "  No database references found"
  SCORE=$((SCORE + 15))
else
  ISSUES+=("Database references detected")
  log_error "  Database references detected"
fi

# --- Check 5: index.html exists ---
log_step "Checking for index.html..."
if [[ -f "$REPO/index.html" ]]; then
  log_ok "  index.html found at root"
  SCORE=$((SCORE + 10))
elif find "$REPO" -name "index.html" -maxdepth 2 2>/dev/null | head -1 | grep -q .; then
  log_ok "  index.html found (not at root)"
  SCORE=$((SCORE + 5))
else
  WARNINGS+=("No index.html found - might need build step")
  log_warn "  No index.html found"
fi

# --- Check 6: File statistics ---
log_step "File statistics..."
HTML_COUNT=$(find "$REPO" -name "*.html" | wc -l | tr -d ' ')
CSS_COUNT=$(find "$REPO" -name "*.css" | wc -l | tr -d ' ')
JS_COUNT=$(find "$REPO" -name "*.js" -not -path "*/node_modules/*" | wc -l | tr -d ' ')
TOTAL_SIZE=$(du -sh "$REPO" 2>/dev/null | cut -f1)
echo "  HTML: $HTML_COUNT | CSS: $CSS_COUNT | JS: $JS_COUNT | Total: $TOTAL_SIZE"

if [[ "$JS_COUNT" -lt 20 ]]; then
  log_ok "  Codebase is small (easy to adapt)"
  SCORE=$((SCORE + 10))
else
  log_info "  Larger codebase (more effort to adapt)"
  SCORE=$((SCORE + 5))
fi

# --- Check 7: API calls pattern ---
log_step "Checking API call patterns..."
HAS_INTERNAL_API=false
HAS_EXTERNAL_API=false

# Check for internal API calls (/api/ or localhost)
if find "$REPO" -maxdepth 3 \( -name "*.js" -o -name "*.html" \) 2>/dev/null \
  | grep -v node_modules \
  | head -50 \
  | xargs grep -l '/api/' 2>/dev/null | head -1 | grep -q .; then
  HAS_INTERNAL_API=true
fi

# Check for external API calls (fetch to https://)
if find "$REPO" -maxdepth 3 \( -name "*.js" -o -name "*.html" \) 2>/dev/null \
  | grep -v node_modules \
  | head -50 \
  | xargs grep -l 'fetch(' 2>/dev/null | head -1 | grep -q .; then
  HAS_EXTERNAL_API=true
fi

if [[ "$HAS_INTERNAL_API" == "true" ]]; then
  ISSUES+=("Internal API calls (/api/) detected - may need custom backend")
  log_error "  Internal API calls found - may need custom backend"
elif [[ "$HAS_EXTERNAL_API" == "true" ]]; then
  log_ok "  Uses external/public APIs - good"
  SCORE=$((SCORE + 10))
else
  log_ok "  No API calls detected (fully self-contained)"
  SCORE=$((SCORE + 10))
fi

# --- Final Verdict ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Score: $SCORE / 100"

if [[ ${#ISSUES[@]} -gt 0 ]]; then
  echo ""
  log_error "Issues:"
  for issue in "${ISSUES[@]}"; do
    echo "    - $issue"
  done
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo ""
  log_warn "Warnings:"
  for warn in "${WARNINGS[@]}"; do
    echo "    - $warn"
  done
fi

echo ""
if [[ $SCORE -ge 70 ]] && [[ ${#ISSUES[@]} -eq 0 ]]; then
  log_ok "Verdict: COMPATIBLE - Ready to fork"
  echo "  Run: ./scripts/fork-site.sh $REPO_URL <site-name> \"<title>\""
  exit 0
elif [[ $SCORE -ge 40 ]] || [[ ${#ISSUES[@]} -le 1 ]]; then
  log_warn "Verdict: NEEDS REVIEW - Check issues above before forking"
  exit 0
else
  log_error "Verdict: INCOMPATIBLE - Not suitable for SiteFactory"
  exit 1
fi
