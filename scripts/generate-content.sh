#!/usr/bin/env bash
# generate-content.sh - Generate an SEO blog article using AI and save to a Hugo site.
# Usage: ./scripts/generate-content.sh <site-name> "<topic>" ["keyword1,keyword2"] [word_count]
#
# The AI provider is configured in config.yaml under ai.provider.
# Supports: openai, claude, gemini, deepseek, moonshot, zhipu

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/config.sh"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/llm.sh"

SITE_NAME="${1:?Usage: generate-content.sh <site-name> \"<topic>\" [\"keywords\"] [word_count]}"
TOPIC="${2:?Please provide a topic}"
KEYWORDS="${3:-}"
WORD_COUNT="${4:-1200}"

SITE_DIR="$REPO_ROOT/sites/$SITE_NAME"
POST_DIR="$SITE_DIR/content/posts"

if [[ ! -d "$SITE_DIR" ]]; then
  log_error "Site not found: $SITE_DIR"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  log_error "jq is required. Install: brew install jq (macOS) / apt install jq (Linux)"
  exit 1
fi

# Generate slug from topic
SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | sed 's/ /-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-//;s/-$//' | cut -c1-60)
DATE=$(date +%Y-%m-%d)

log_info "Generating article: $TOPIC"
log_info "Provider: $SF_AI_PROVIDER ($SF_AI_MODEL)"

# Build prompts
SYSTEM_PROMPT="You are an expert SEO content writer. Generate a high-quality, SEO-optimized blog article in Markdown format. The article MUST begin with Hugo-compatible YAML frontmatter enclosed in --- delimiters. Follow these rules:

1. Frontmatter must include: title, date (use ${DATE}), description (compelling meta description under 160 chars), tags (array of relevant tags), categories (array), draft: false
2. Use proper heading hierarchy (H2, H3 - never H1 since the title serves as H1)
3. Include a compelling introduction that hooks the reader
4. Use short paragraphs (2-3 sentences) for readability
5. Include bullet points and numbered lists where appropriate
6. Add a conclusion with a call-to-action
7. Naturally incorporate the provided keywords without keyword stuffing
8. Target the specified word count (approximate is fine)
9. Write in a professional yet accessible tone"

USER_PROMPT="Write a blog article about the following topic:

Topic: ${TOPIC}
Target keywords: ${KEYWORDS}
Target word count: ${WORD_COUNT}

Please output ONLY the markdown content (with frontmatter). No explanations or extra text."

# Call LLM
log_step "Calling ${SF_AI_PROVIDER} API..."
MARKDOWN=$(llm_generate "$SYSTEM_PROMPT" "$USER_PROMPT")

if [[ -z "$MARKDOWN" ]]; then
  log_error "AI returned empty content"
  exit 1
fi

# Ensure frontmatter exists
if [[ ! "$MARKDOWN" == ---* ]]; then
  log_warn "No frontmatter detected, adding default..."
  FRONTMATTER="---
title: \"${TOPIC}\"
date: ${DATE}
description: \"${TOPIC}\"
tags: [$(echo "$KEYWORDS" | sed 's/,/", "/g' | sed 's/^/"/;s/$/"/')]
categories: [\"blog\"]
draft: false
---

"
  MARKDOWN="${FRONTMATTER}${MARKDOWN}"
fi

# Write file
mkdir -p "$POST_DIR"
FILE_PATH="$POST_DIR/${SLUG}.md"
echo "$MARKDOWN" > "$FILE_PATH"

ACTUAL_WORDS=$(wc -w < "$FILE_PATH" | tr -d ' ')
log_ok "Article saved: $FILE_PATH ($ACTUAL_WORDS words)"

# Git commit
log_step "Committing to git..."
cd "$REPO_ROOT"
git add "$FILE_PATH" 2>/dev/null || true
git commit -m "feat(content): add article '${SLUG}' to ${SITE_NAME}" --quiet 2>/dev/null || log_warn "Git commit skipped (nothing to commit or not a git repo)"

log_ok "Done! Article '${SLUG}' generated for ${SITE_NAME}"
