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

# Generate text from LLM. Output goes to stdout.
# Usage: llm_generate <system_prompt> <user_prompt>
# Returns: exit 0 on success (text on stdout), exit 1 on failure (error on stderr)
llm_generate() {
  local system_prompt="$1"
  local user_prompt="$2"

  if [[ -z "$SF_AI_API_KEY" ]] || [[ "$SF_AI_API_KEY" == *"XXXX"* ]]; then
    echo "ERROR: AI API key not configured. Set ai.providers.${SF_AI_PROVIDER}.api_key in config.yaml" >&2
    return 1
  fi

  case "$SF_AI_PROVIDER" in
    openai|deepseek|moonshot|zhipu)
      _llm_openai_compatible "$system_prompt" "$user_prompt"
      ;;
    claude)
      _llm_claude "$system_prompt" "$user_prompt"
      ;;
    gemini)
      _llm_gemini "$system_prompt" "$user_prompt"
      ;;
    *)
      echo "ERROR: Unknown AI provider: $SF_AI_PROVIDER" >&2
      return 1
      ;;
  esac
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

  local response
  response=$(curl -s --max-time 120 \
    -H "Authorization: Bearer ${SF_AI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "${base_url}/chat/completions" 2>/dev/null)

  local text
  text=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

  if [[ -z "$text" ]]; then
    local err
    err=$(echo "$response" | jq -r '.error.message // .error // "Unknown error"' 2>/dev/null)
    echo "ERROR: ${SF_AI_PROVIDER} API failed: $err" >&2
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

  local response
  response=$(curl -s --max-time 120 \
    -H "x-api-key: ${SF_AI_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "https://api.anthropic.com/v1/messages" 2>/dev/null)

  local text
  text=$(echo "$response" | jq -r '.content[]? | select(.type == "text") | .text' 2>/dev/null | head -1)

  if [[ -z "$text" ]]; then
    local err
    err=$(echo "$response" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
    echo "ERROR: Claude API failed: $err" >&2
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

  local response
  response=$(curl -s --max-time 120 \
    -H "Content-Type: application/json" \
    -d "$body" \
    "https://generativelanguage.googleapis.com/v1beta/models/${SF_AI_MODEL}:generateContent?key=${SF_AI_API_KEY}" 2>/dev/null)

  local text
  text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)

  if [[ -z "$text" ]]; then
    local err
    err=$(echo "$response" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
    echo "ERROR: Gemini API failed: $err" >&2
    return 1
  fi

  echo "$text"
}
