#!/usr/bin/env bash
# llm.sh - Unified LLM API wrapper supporting multiple providers.
# Usage: source scripts/lib/llm.sh
#        llm_generate "system prompt" "user prompt"
#
# Requires: config.sh sourced first (for SF_AI_* variables), curl, jq
#
# Supported providers:
#   OpenAI-compatible: openai, deepseek, moonshot, zhipu
#   Native:           claude, gemini
#
# Provider functions return: 0=success, 1=non-retryable error, 2=retryable error

LLM_TIMEOUT=300

# Generate text from LLM with automatic retry on transient failures.
# Output goes to stdout.
# Usage: llm_generate <system_prompt> <user_prompt>
# Returns: exit 0 on success (text on stdout), exit 1 on failure (error on stderr)
llm_generate() {
  local system_prompt="$1"
  local user_prompt="$2"
  local max_retries=2

  if [[ -z "$SF_AI_API_KEY" ]] || [[ "$SF_AI_API_KEY" == *"XXXX"* ]]; then
    echo "ERROR: AI API key not configured. Set ai.providers.${SF_AI_PROVIDER}.api_key in config.yaml" >&2
    return 1
  fi

  local attempt=0
  while [[ "$attempt" -le "$max_retries" ]]; do
    if [[ "$attempt" -gt 0 ]]; then
      local wait_secs=$((attempt * 30))
      echo "Retrying in ${wait_secs}s (attempt $((attempt + 1))/$((max_retries + 1)))..." >&2
      sleep "$wait_secs"
    fi

    local result=0
    case "$SF_AI_PROVIDER" in
      openai|deepseek|moonshot|zhipu)
        _llm_openai_compatible "$system_prompt" "$user_prompt"
        result=$?
        ;;
      claude)
        _llm_claude "$system_prompt" "$user_prompt"
        result=$?
        ;;
      gemini)
        _llm_gemini "$system_prompt" "$user_prompt"
        result=$?
        ;;
      *)
        echo "ERROR: Unknown AI provider: $SF_AI_PROVIDER" >&2
        return 1
        ;;
    esac

    [[ "$result" -eq 0 ]] && return 0
    [[ "$result" -eq 1 ]] && return 1
    # result=2: retryable error, continue loop
    attempt=$((attempt + 1))
  done

  echo "ERROR: All $((max_retries + 1)) attempts failed for ${SF_AI_PROVIDER}" >&2
  return 1
}

# OpenAI-compatible API (works for openai, deepseek, moonshot, zhipu)
_llm_openai_compatible() {
  local system_prompt="$1"
  local user_prompt="$2"
  local base_url="${SF_AI_BASE_URL:-https://api.openai.com/v1}"

  local body
  body=$(jq -n \
    --arg model "$SF_AI_MODEL" \
    --arg sys "$system_prompt" \
    --arg usr "$user_prompt" \
    '{
      model: $model,
      messages: [
        { role: "system", content: $sys },
        { role: "user", content: $usr }
      ]
    }')

  local tmpfile curl_exit=0
  tmpfile=$(mktemp)
  local http_code
  http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" --max-time "$LLM_TIMEOUT" \
    -H "Authorization: Bearer ${SF_AI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "${base_url}/chat/completions") || curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    rm -f "$tmpfile"
    _llm_curl_error "$curl_exit"
    return 2
  fi

  local response
  response=$(cat "$tmpfile")
  rm -f "$tmpfile"

  if [[ "$http_code" =~ ^5 ]]; then
    _llm_server_error "$http_code" "$response"
    return 2
  fi

  local text
  text=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

  if [[ -z "$text" ]]; then
    local err
    err=$(echo "$response" | jq -r '.error.message // .error // "Unknown error"' 2>/dev/null)
    echo "ERROR: ${SF_AI_PROVIDER} API failed (HTTP $http_code): $err" >&2
    return 1
  fi

  echo "$text"
}

# Anthropic Claude API
_llm_claude() {
  local system_prompt="$1"
  local user_prompt="$2"

  local body
  body=$(jq -n \
    --arg model "$SF_AI_MODEL" \
    --arg sys "$system_prompt" \
    --arg usr "$user_prompt" \
    '{
      model: $model,
      max_tokens: 4096,
      system: $sys,
      messages: [
        { role: "user", content: $usr }
      ]
    }')

  local tmpfile curl_exit=0
  tmpfile=$(mktemp)
  local http_code
  http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" --max-time "$LLM_TIMEOUT" \
    -H "x-api-key: ${SF_AI_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "https://api.anthropic.com/v1/messages") || curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    rm -f "$tmpfile"
    _llm_curl_error "$curl_exit"
    return 2
  fi

  local response
  response=$(cat "$tmpfile")
  rm -f "$tmpfile"

  if [[ "$http_code" =~ ^5 ]]; then
    _llm_server_error "$http_code" "$response"
    return 2
  fi

  local text
  text=$(echo "$response" | jq -r '.content[]? | select(.type == "text") | .text' 2>/dev/null | head -1)

  if [[ -z "$text" ]]; then
    local err
    err=$(echo "$response" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
    echo "ERROR: Claude API failed (HTTP $http_code): $err" >&2
    return 1
  fi

  echo "$text"
}

# Google Gemini API
_llm_gemini() {
  local system_prompt="$1"
  local user_prompt="$2"

  local body
  body=$(jq -n \
    --arg sys "$system_prompt" \
    --arg usr "$user_prompt" \
    '{
      system_instruction: { parts: { text: $sys } },
      contents: [
        { parts: [{ text: $usr }] }
      ]
    }')

  local tmpfile curl_exit=0
  tmpfile=$(mktemp)
  local http_code
  http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" --max-time "$LLM_TIMEOUT" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "https://generativelanguage.googleapis.com/v1beta/models/${SF_AI_MODEL}:generateContent?key=${SF_AI_API_KEY}") || curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    rm -f "$tmpfile"
    _llm_curl_error "$curl_exit"
    return 2
  fi

  local response
  response=$(cat "$tmpfile")
  rm -f "$tmpfile"

  if [[ "$http_code" =~ ^5 ]]; then
    _llm_server_error "$http_code" "$response"
    return 2
  fi

  local text
  text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)

  if [[ -z "$text" ]]; then
    local err
    err=$(echo "$response" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
    echo "ERROR: Gemini API failed (HTTP $http_code): $err" >&2
    return 1
  fi

  echo "$text"
}

# Helper: report curl connection/timeout errors
_llm_curl_error() {
  local exit_code="$1"
  if [[ "$exit_code" -eq 28 ]]; then
    echo "ERROR: ${SF_AI_PROVIDER} API timed out after ${LLM_TIMEOUT}s" >&2
  else
    echo "ERROR: ${SF_AI_PROVIDER} API connection failed (curl exit $exit_code)" >&2
  fi
}

# Helper: report 5xx server errors
_llm_server_error() {
  local http_code="$1"
  local response="$2"
  local err
  err=$(echo "$response" | jq -r '.error.message // .error // "Server error"' 2>/dev/null)
  echo "ERROR: ${SF_AI_PROVIDER} API server error (HTTP $http_code): $err" >&2
}
