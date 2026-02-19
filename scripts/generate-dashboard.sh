#!/usr/bin/env bash
# generate-dashboard.sh - Collect metrics and generate dashboard HTML.
# Pulls uptime data from UptimeRobot API, scans sites/, generates dashboard.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/logging.sh"

DASHBOARD_DIR="$REPO_ROOT/dashboard"
DATA_DIR="$DASHBOARD_DIR/data"
OUTPUT_FILE="$DASHBOARD_DIR/index.html"
METRICS_FILE="$DATA_DIR/metrics.json"

mkdir -p "$DATA_DIR"

# Load config (optional - dashboard works without credentials)
SF_DOMAIN="example.com"
SF_UPTIMEROBOT_API_KEY=""
if [[ -f "$REPO_ROOT/config.yaml" ]]; then
  source "$REPO_ROOT/scripts/lib/config.sh" 2>/dev/null || true
fi

# 1. Collect site list
log_step "Scanning sites..."
SITES_JSON="["
FIRST=true
for site_dir in "$REPO_ROOT/sites"/*/; do
  name=$(basename "$site_dir")
  [[ "$name" == "_template" ]] && continue
  [[ "$name" == "_shared" ]] && continue
  [[ ! -f "$site_dir/site.yaml" ]] && continue

  site_type=$(grep "^type:" "$site_dir/site.yaml" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "unknown")
  site_title=$(grep "^title:" "$site_dir/site.yaml" 2>/dev/null | sed 's/^title: *//' | tr -d '"' || echo "$name")

  [[ "$FIRST" == "true" ]] && FIRST=false || SITES_JSON="$SITES_JSON,"
  SITES_JSON="$SITES_JSON{\"name\":\"$name\",\"type\":\"$site_type\",\"title\":\"$site_title\"}"
done
SITES_JSON="$SITES_JSON]"

# 2. Collect UptimeRobot data
MONITORS_JSON="[]"
if [[ -n "$SF_UPTIMEROBOT_API_KEY" ]] && [[ "$SF_UPTIMEROBOT_API_KEY" != YOUR_* ]]; then
  log_step "Fetching UptimeRobot data..."
  UPTIME_RESPONSE=$(curl -s -X POST "https://api.uptimerobot.com/v2/getMonitors" \
    -H "Content-Type: application/json" \
    -d "{\"api_key\":\"$SF_UPTIMEROBOT_API_KEY\",\"format\":\"json\",\"custom_uptime_ratios\":\"7-30-90\"}" 2>/dev/null || echo "{}")

  if echo "$UPTIME_RESPONSE" | jq -e '.monitors' >/dev/null 2>&1; then
    MONITORS_JSON=$(echo "$UPTIME_RESPONSE" | jq '.monitors')
    MONITOR_COUNT=$(echo "$MONITORS_JSON" | jq 'length')
    log_ok "  Retrieved $MONITOR_COUNT monitors"
  else
    log_warn "  Could not parse UptimeRobot response"
  fi
else
  log_warn "No UptimeRobot API key configured (dashboard will show without uptime data)"
fi

# 3. Build metrics JSON
log_step "Building metrics JSON..."
GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$METRICS_FILE" << EOF
{
  "generated_at": "$GENERATED_AT",
  "domain": "$SF_DOMAIN",
  "sites": $SITES_JSON,
  "monitors": $MONITORS_JSON
}
EOF
log_ok "  Wrote $METRICS_FILE"

# 4. Generate HTML
log_step "Generating dashboard HTML..."
if [[ ! -f "$DASHBOARD_DIR/template.html" ]]; then
  log_error "Template not found: $DASHBOARD_DIR/template.html"
  exit 1
fi

# Use python for safe replacement (sed struggles with JSON)
python3 -c "
import sys
with open('$DASHBOARD_DIR/template.html') as f:
    template = f.read()
with open('$METRICS_FILE') as f:
    metrics = f.read()
result = template.replace('{{METRICS_JSON}}', metrics)
with open('$OUTPUT_FILE', 'w') as f:
    f.write(result)
"

log_ok "Dashboard generated: $OUTPUT_FILE"
log_info "Open: file://$OUTPUT_FILE"
