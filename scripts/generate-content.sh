#!/usr/bin/env bash
# generate-content.sh - Generate an SEO blog article using AI and save to a Hugo site.
#
# Usage:
#   ./scripts/generate-content.sh <site-name> "<topic>" ["keyword1,keyword2"] [word_count]
#   ./scripts/generate-content.sh <site-name>   # Plan mode: pick next pending topic
#
# In plan mode, reads from content-plans/{site-name}.yaml (outside sites/).
# The AI provider is configured in config.yaml under ai.provider.
# Supports: openai, claude, gemini, deepseek, moonshot, zhipu

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/config.sh"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/llm.sh"

# Generate a URL-safe slug from a topic title.
# Priority: 1) pre-generated slug from content plan, 2) ASCII extraction, 3) md5 hash fallback
generate_slug() {
  local topic="$1"
  local plan_slug="${2:-}"
  local slug=""

  # Priority 1: use pre-generated slug from content plan
  if [[ -n "$plan_slug" && "$plan_slug" != "null" ]]; then
    slug=$(echo "$plan_slug" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | sed 's/-\{2,\}/-/g' | sed 's/^-//;s/-$//' | cut -c1-60)
  fi

  # Priority 2: extract ASCII characters from topic
  if [[ -z "$slug" ]]; then
    slug=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | sed 's/ /-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-//;s/-$//' | cut -c1-60)
  fi

  # Priority 3: hash-based fallback for non-ASCII topics
  if [[ -z "$slug" ]]; then
    local hash
    hash=$(printf '%s' "$topic" | md5sum 2>/dev/null || printf '%s' "$topic" | md5)
    slug="post-${hash%% *}"
    slug="${slug:0:20}"
  fi

  echo "$slug"
}

SITE_NAME="${1:?Usage: generate-content.sh <site-name> [\"<topic>\"] [\"keywords\"] [word_count]}"
TOPIC="${2:-}"
KEYWORDS="${3:-}"
WORD_COUNT="${4:-1500}"
MIN_WORD_COUNT=300

# Count words/characters depending on content language.
# CJK languages: count characters (wc -m) since there are no word-separating spaces.
# Latin languages: count words (wc -w) as usual.
count_words() {
  local file="$1"
  local lang="${2:-en}"
  case "$lang" in
    zh*|ja*|ko*) wc -m < "$file" | tr -d ' ' ;;
    *)           wc -w < "$file" | tr -d ' ' ;;
  esac
}

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

# Plan mode: if no topic provided, read from content plan
PLAN_INDEX=""
NICHE=""
SITE_TITLE_CONTEXT=""
PLAN_FILE="$REPO_ROOT/content-plans/$SITE_NAME.yaml"
SITE_YAML="$SITE_DIR/site.yaml"
SITE_LANG="en"
if [[ -f "$SITE_DIR/site.yaml" ]]; then
  SITE_LANG=$(yq '.language // "en"' "$SITE_DIR/site.yaml")
fi

if [[ -z "$TOPIC" ]]; then
  if [[ ! -f "$PLAN_FILE" ]]; then
    log_error "No topic provided and no content plan found at $PLAN_FILE"
    log_info "Run: ./scripts/generate-content-plan.sh $SITE_NAME"
    exit 1
  fi

  NICHE=$(yq '.niche // ""' "$PLAN_FILE")

  # Read site title for context
  if [[ -f "$SITE_YAML" ]]; then
    SITE_TITLE_CONTEXT=$(yq '.title // ""' "$SITE_YAML" 2>/dev/null || echo "")
  fi

  # Find the first pending topic whose article doesn't already exist
  PENDING_COUNT=$(yq '[.topics[] | select(.status == "pending")] | length' "$PLAN_FILE")
  FOUND=false
  for idx in $(seq 0 $((PENDING_COUNT - 1))); do
    CANDIDATE=$(yq "[.topics[] | select(.status == \"pending\")][$idx].title // \"\"" "$PLAN_FILE")
    [[ -z "$CANDIDATE" || "$CANDIDATE" == "null" ]] && continue

    # Check if article file already exists (dedup by slug)
    CANDIDATE_PLAN_SLUG=$(yq "[.topics[] | select(.status == \"pending\")][$idx].slug // \"\"" "$PLAN_FILE")
    CANDIDATE_SLUG=$(generate_slug "$CANDIDATE" "$CANDIDATE_PLAN_SLUG")
    if [[ -f "$POST_DIR/${CANDIDATE_SLUG}.md" ]]; then
      log_info "Skipping '$CANDIDATE' (article already exists)"
      # Mark as published since the article exists
      SKIP_INDEX=$(yq ".topics | to_entries[] | select(.value.title == \"$CANDIDATE\") | .key" "$PLAN_FILE")
      if [[ -n "$SKIP_INDEX" && "$SKIP_INDEX" != "null" ]]; then
        yq -i ".topics[$SKIP_INDEX].status = \"published\"" "$PLAN_FILE"
      fi
      continue
    fi

    TOPIC="$CANDIDATE"
    KEYWORDS=$(yq "[.topics[] | select(.status == \"pending\")][$idx].keywords // \"\"" "$PLAN_FILE")
    PLAN_SLUG=$(yq "[.topics[] | select(.status == \"pending\")][$idx].slug // \"\"" "$PLAN_FILE")
    PLAN_INDEX=$(yq ".topics | to_entries[] | select(.value.title == \"$TOPIC\") | .key" "$PLAN_FILE")
    FOUND=true
    break
  done

  if [[ "$FOUND" != "true" ]]; then
    log_warn "No pending topics (or all already have articles) for '$SITE_NAME'"
    log_info "Run: ./scripts/generate-content-plan.sh $SITE_NAME"
    exit 0
  fi

  # Mark as in_progress
  if [[ -n "$PLAN_INDEX" && "$PLAN_INDEX" != "null" ]]; then
    yq -i ".topics[$PLAN_INDEX].status = \"in_progress\"" "$PLAN_FILE"
  fi

  log_info "Plan mode: selected topic '$TOPIC'"
else
  # Manual mode: try to read niche context if available
  if [[ -f "$PLAN_FILE" ]]; then
    NICHE=$(yq '.niche // ""' "$PLAN_FILE" 2>/dev/null || echo "")
  fi
  if [[ -f "$SITE_YAML" ]]; then
    SITE_TITLE_CONTEXT=$(yq '.title // ""' "$SITE_YAML" 2>/dev/null || echo "")
  fi
fi

# Generate slug from topic (uses plan slug if available, falls back to hash for non-ASCII)
SLUG=$(generate_slug "$TOPIC" "${PLAN_SLUG:-}")
DATE=$(date +%Y-%m-%d)

log_info "Generating article: $TOPIC"
log_info "Provider: $SF_AI_PROVIDER ($SF_AI_MODEL)"

# Build prompts with niche context
NICHE_CONTEXT=""
if [[ -n "$NICHE" && "$NICHE" != "null" ]]; then
  NICHE_CONTEXT=" specializing in ${NICHE}"
fi

SITE_CONTEXT=""
if [[ -n "$SITE_TITLE_CONTEXT" && "$SITE_TITLE_CONTEXT" != "null" ]]; then
  SITE_CONTEXT=" You are writing for the website '${SITE_TITLE_CONTEXT}'."
fi

# Collect existing article slugs for internal linking
EXISTING_SLUGS=""
if [[ -d "$POST_DIR" ]]; then
  EXISTING_SLUGS=$(find "$POST_DIR" -name "*.md" -not -name "_index.md" -exec basename {} .md \; 2>/dev/null | tr '\n' ', ')
fi

# Collect tool information from sites.yaml for cross-references
TOOLS_INFO=""
SITES_YAML="$REPO_ROOT/themes/sitefactory/data/sites.yaml"
if [[ -f "$SITES_YAML" ]] && command -v yq &>/dev/null; then
  DOMAIN=$(yq '.domain // ""' "$SITES_YAML" 2>/dev/null || echo "")
  if [[ -n "$DOMAIN" && "$DOMAIN" != "null" ]]; then
    TOOLS_INFO=$(yq -r ".sites[] | select(.type == \"static\") | .title + \" (\" + .description + \") - https://\" + .name + \".${DOMAIN}/\"" "$SITES_YAML" 2>/dev/null | tr '\n' '; ')
  fi
fi

SYSTEM_PROMPT="You are an expert SEO content writer${NICHE_CONTEXT}. Generate a high-quality, SEO-optimized blog article in Markdown format.${SITE_CONTEXT} The article MUST begin with Hugo-compatible YAML frontmatter enclosed in --- delimiters. Follow these rules:

1. Frontmatter must include: title, date (use ${DATE}), description (compelling meta description under 160 chars), tags (array of relevant tags), categories (array), draft: false
2. Use proper heading hierarchy (H2, H3 - never H1 since the title serves as H1)
3. Include a compelling introduction that hooks the reader
4. Use short paragraphs (2-3 sentences) for readability
5. Include bullet points and numbered lists where appropriate
6. Add a conclusion with a call-to-action
7. Naturally incorporate the provided keywords without keyword stuffing
8. You MUST write at least ${WORD_COUNT} words. This is a hard minimum requirement, not a suggestion. Articles under ${MIN_WORD_COUNT} words will be rejected
9. Write in a professional yet accessible tone
10. Vary article structure — use a MIX of: listicles, how-to guides, comparisons, deep dives, problem-solution. Do NOT always follow the same template
11. Include 2-3 internal links to related articles from this site using markdown links (format: [text](/posts/slug/)). I will provide a list of existing article slugs
12. Write with a personal voice — use \"I\" occasionally, share brief observations from testing. Avoid generic AI prose patterns like \"In today's digital world\" or \"In this comprehensive guide\"
13. Include 1-2 data points or statistics with approximate attribution
14. If any available tools on the site network are relevant to the topic, mention and link to them naturally"

USER_PROMPT="Write a blog article about the following topic:

Topic: ${TOPIC}
Target keywords: ${KEYWORDS}
Target word count: ${WORD_COUNT}"

# Add existing article slugs for internal linking
if [[ -n "$EXISTING_SLUGS" ]]; then
  USER_PROMPT="${USER_PROMPT}

Existing articles on this site (use for internal links where relevant): ${EXISTING_SLUGS}"
fi

# Add tool references
if [[ -n "$TOOLS_INFO" ]]; then
  USER_PROMPT="${USER_PROMPT}

Available tools on the site network (link if relevant to the topic): ${TOOLS_INFO}"
fi

USER_PROMPT="${USER_PROMPT}

Please output ONLY the markdown content (with frontmatter). No explanations or extra text."

# Call LLM
log_step "Calling ${SF_AI_PROVIDER} API..."
MARKDOWN=$(llm_generate "$SYSTEM_PROMPT" "$USER_PROMPT")

if [[ -z "$MARKDOWN" ]]; then
  # Revert in_progress status on failure
  if [[ -n "$PLAN_INDEX" && "$PLAN_INDEX" != "null" ]]; then
    yq -i ".topics[$PLAN_INDEX].status = \"pending\"" "$PLAN_FILE"
  fi
  log_error "AI returned empty content"
  exit 1
fi

# Strip markdown code fences if AI wrapped the output
MARKDOWN=$(echo "$MARKDOWN" | sed '/^```.*$/d')

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

ACTUAL_WORDS=$(count_words "$FILE_PATH" "$SITE_LANG")
WORD_UNIT="words"
case "$SITE_LANG" in zh*|ja*|ko*) WORD_UNIT="chars" ;; esac

# Reject articles that are too short (LLM didn't follow word count instruction)
if [[ "$ACTUAL_WORDS" -lt "$MIN_WORD_COUNT" ]]; then
  rm -f "$FILE_PATH"
  # Revert in_progress status on failure
  if [[ -n "${PLAN_INDEX:-}" && "$PLAN_INDEX" != "null" ]]; then
    yq -i ".topics[$PLAN_INDEX].status = \"pending\"" "$PLAN_FILE"
  fi
  log_error "Article too short: $ACTUAL_WORDS $WORD_UNIT (minimum $MIN_WORD_COUNT). Deleted and reverted to pending."
  exit 1
fi

log_ok "Article saved: $FILE_PATH ($ACTUAL_WORDS $WORD_UNIT)"

# Update content plan status if in plan mode
if [[ -n "$PLAN_INDEX" && "$PLAN_INDEX" != "null" ]]; then
  yq -i ".topics[$PLAN_INDEX].status = \"published\"" "$PLAN_FILE"
  yq -i ".last_generated = \"$DATE\"" "$PLAN_FILE"
  log_info "Content plan updated: topic marked as published"
fi

# Git commit (article + content plan update)
log_step "Committing to git..."
cd "$REPO_ROOT"
git add "$FILE_PATH" 2>/dev/null || true
git add "$PLAN_FILE" 2>/dev/null || true
git commit -m "content(${SITE_NAME}): add article '${SLUG}'" --quiet 2>/dev/null || log_warn "Git commit skipped (nothing to commit or not a git repo)"

log_ok "Done! Article '${SLUG}' generated for ${SITE_NAME}"
