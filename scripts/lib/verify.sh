#!/usr/bin/env bash
# verify.sh - Post-deployment verification helpers (DNS polling, HTTP health check).
# Usage: source scripts/lib/verify.sh

# Check if a DNS CNAME record resolves to the expected target.
# Uses dig (macOS built-in), falls back to nslookup.
# Returns 0 if resolved, 1 if not.
verify_dns() {
  local hostname="$1"
  local expected="$2"

  if command -v dig &>/dev/null; then
    dig CNAME +short "$hostname" 2>/dev/null | grep -qi "$expected"
  elif command -v nslookup &>/dev/null; then
    nslookup -type=CNAME "$hostname" 2>/dev/null | grep -qi "$expected"
  else
    # No DNS tools available, skip check
    return 1
  fi
}

# Poll DNS until resolved or timeout.
# Returns 0 if resolved, 1 if timed out.
verify_dns_poll() {
  local hostname="$1"
  local expected="${2:-cname.vercel-dns.com}"
  local max_attempts="${3:-12}"
  local interval="${4:-10}"

  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    if verify_dns "$hostname" "$expected"; then
      return 0
    fi
    local remaining=$(( (max_attempts - attempt) * interval ))
    printf "\r  Waiting for DNS propagation... attempt %d/%d (up to %ds remaining)" \
      "$attempt" "$max_attempts" "$remaining"
    sleep "$interval"
    attempt=$((attempt + 1))
  done
  echo ""
  return 1
}

# HTTP health check: verify a URL returns 2xx/3xx.
# Returns 0 on success, 1 on failure.
verify_http() {
  local url="$1"
  local timeout="${2:-15}"

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null || echo "000")

  [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 400 ]]
}

# HTTP health check with retries for newly deployed sites.
# Returns 0 if site responds, 1 if timed out.
verify_http_poll() {
  local url="$1"
  local max_attempts="${2:-6}"
  local interval="${3:-10}"

  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    if verify_http "$url"; then
      return 0
    fi
    local remaining=$(( (max_attempts - attempt) * interval ))
    printf "\r  Waiting for site to respond... attempt %d/%d (up to %ds remaining)" \
      "$attempt" "$max_attempts" "$remaining"
    sleep "$interval"
    attempt=$((attempt + 1))
  done
  echo ""
  return 1
}
