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
WORD_COUNT="${4:-2000}"
MIN_WORD_COUNT=800

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
# shellcheck disable=SC2034
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
    ARCHETYPE=$(yq "[.topics[] | select(.status == \"pending\")][$idx].archetype // \"\"" "$PLAN_FILE")
    WORD_COUNT_MIN=$(yq "[.topics[] | select(.status == \"pending\")][$idx].word_count_min // \"\"" "$PLAN_FILE")
    WORD_COUNT_MAX=$(yq "[.topics[] | select(.status == \"pending\")][$idx].word_count_max // \"\"" "$PLAN_FILE")
    OPENING_STRATEGY=$(yq "[.topics[] | select(.status == \"pending\")][$idx].opening // \"\"" "$PLAN_FILE")
    CLOSING_STRATEGY=$(yq "[.topics[] | select(.status == \"pending\")][$idx].closing // \"\"" "$PLAN_FILE")
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
    # shellcheck disable=SC2034
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

# Build prompts with site context
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

# Build archetype-specific instructions
ARCHETYPE_INSTRUCTIONS=""
case "${ARCHETYPE:-}" in
  personal-test-report)
    ARCHETYPE_INSTRUCTIONS="Structure: Open with what prompted you to test this. Describe your testing setup (devices, duration, scenarios). Present findings with specific data (tables, scores). Share surprises and disappointments honestly. End with your personal verdict and who this is best for."
    ;;
  head-to-head)
    ARCHETYPE_INSTRUCTIONS="Structure: Brief intro stating what you are comparing and why. Create a detailed comparison table (6+ columns if possible). Go through each contender with pros/cons. Declare a winner for different use cases. Include specific metrics or scores you observed."
    ;;
  step-by-step-tutorial)
    ARCHETYPE_INSTRUCTIONS="Structure: State the end goal clearly. List prerequisites. Walk through numbered steps with expected output at each stage. Include code blocks for commands or queries. Add troubleshooting tips for common mistakes. End with the completed result."
    ;;
  problem-solution)
    ARCHETYPE_INSTRUCTIONS="Structure: Open with a specific frustrating scenario the reader will recognize. Explain why the usual approaches fail. Present the solution step by step. Show before/after comparison. End with the specific improvement achieved."
    ;;
  definitive-resource)
    ARCHETYPE_INSTRUCTIONS="Structure: Position this as the most comprehensive resource on the topic. Include multiple data tables, reference lists, and categorized sections. Make it bookmarkable. Use H2/H3 heavily for navigation. Include a quick-reference summary at the end."
    ;;
  quick-fire-tips)
    ARCHETYPE_INSTRUCTIONS="Structure: Short intro (2-3 sentences max). Numbered tips, each 2-4 sentences. No sub-headings within tips. Mix obvious and non-obvious advice. End abruptly after the last tip (no conclusion section)."
    ;;
  myth-buster)
    ARCHETYPE_INSTRUCTIONS="Structure: Open with a common misconception. For each myth: state it, explain why people believe it, then present the reality with evidence. Use a tabular myth-vs-reality format for at least one section. End with what actually matters."
    ;;
  beginners-roadmap)
    ARCHETYPE_INSTRUCTIONS="Structure: Acknowledge that the topic can feel overwhelming. Present a clear learning path: start here, then this, then that. Each stage should have one specific action and one resource. Include a visual progression (table or numbered steps). End with what competence looks like."
    ;;
esac

# Build word count range
WC_MIN="${WORD_COUNT_MIN:-${WORD_COUNT}}"
WC_MAX="${WORD_COUNT_MAX:-5000}"
# Clean null values from yq
[[ "$WC_MIN" == "null" || -z "$WC_MIN" ]] && WC_MIN="${WORD_COUNT}"
[[ "$WC_MAX" == "null" || -z "$WC_MAX" ]] && WC_MAX="5000"

# Build opening/closing instructions
OPENING_INST=""
case "${OPENING_STRATEGY:-}" in
  statistic) OPENING_INST="Open with a specific, sourced statistic that hooks the reader." ;;
  personal_anecdote) OPENING_INST="Open with a brief personal anecdote (2-3 sentences) that led you to explore this topic." ;;
  direct_question) OPENING_INST="Open by asking the reader a direct, relatable question." ;;
  contrarian_claim) OPENING_INST="Open with a bold or contrarian claim that challenges common assumptions." ;;
  micro_story) OPENING_INST="Open with 'Last week I...' or 'A few months ago I...' — a specific micro-story." ;;
  scenario) OPENING_INST="Open by painting a specific scenario the reader will recognize (e.g., 'You are staring at a PDF...')." ;;
esac

CLOSING_INST=""
case "${CLOSING_STRATEGY:-}" in
  specific_action) CLOSING_INST="End with one specific, actionable next step the reader can take right now (not a generic CTA)." ;;
  reader_challenge) CLOSING_INST="End by challenging the reader to try one thing from the article today." ;;
  reflection) CLOSING_INST="End with a brief, thoughtful reflection. No call-to-action." ;;
  what_id_change) CLOSING_INST="End with 'What I would do differently' or 'What I wish I knew starting out'." ;;
  no_conclusion) CLOSING_INST="Do NOT write a conclusion section. End immediately after the last substantive point." ;;
esac

SYSTEM_PROMPT="You are Arron Zhou, a frontend engineer and productivity enthusiast writing for Search123 (search123.top).${SITE_CONTEXT} Generate a blog article in Markdown format with Hugo-compatible YAML frontmatter (--- delimiters).

## IDENTITY
Write as a real person who tests tools hands-on. Use first person ('I') naturally. Share specific observations from testing — mention dates, version numbers, device used. Your tone is professional but conversational, like explaining something to a smart colleague.

## FRONTMATTER REQUIREMENTS
Include: title, date (use ${DATE}), lastmod (use ${DATE}), description (under 160 chars, compelling), tags (array), categories (array), image (leave as empty string \"\"), draft: false

## ANTI-PATTERNS (CRITICAL — violating these will cause the article to be rejected)
NEVER start the article with any of these patterns:
- 'In today's...' / 'In the vast...' / 'In an era of...' / 'In a world of...'
- 'In the ever-changing...' / 'In this comprehensive...'
- Any sentence beginning with 'In' followed by a prepositional phrase about modernity

NEVER end the article with:
- '**Ready to...**' / 'Start your journey...' / 'Bookmark Search123...'
- Any bold-formatted call-to-action as the final paragraph

NEVER use these structural patterns:
- Repeated 'Key Features / Best For / Why It's Great' sub-headings
- More than 2 consecutive bullet-point lists without prose paragraphs between them
- 'Why [Topic] Matters' as your first H2 heading

## REQUIRED ELEMENTS
1. At least ONE markdown comparison table (| Column | Column |)
2. At least ONE code block showing a command, query, URL, or configuration
3. At least ONE personal observation starting with phrases like 'When I tested...' or 'I noticed that...' or 'In my experience...'
4. At least 2 specific data points with named sources (not 'studies show')
5. At least ONE honest limitation, downside, or caveat about the topic
6. Specific version numbers, dates, or pricing when discussing tools
7. 3-4 internal links to other articles (I will provide the list)

## WORD COUNT
Write between ${WC_MIN} and ${WC_MAX} words. Articles under ${MIN_WORD_COUNT} words will be rejected.

## HEADING HIERARCHY
Use H2 and H3 only (never H1). Vary heading styles — not all H2s should be questions, not all should start with 'How to'.

${ARCHETYPE_INSTRUCTIONS:+## STRUCTURE
${ARCHETYPE_INSTRUCTIONS}}

${OPENING_INST:+## OPENING
${OPENING_INST}}

${CLOSING_INST:+## CLOSING
${CLOSING_INST}}"

USER_PROMPT="Write a blog article about:

Topic: ${TOPIC}
Target keywords: ${KEYWORDS}
Word count target: ${WC_MIN}-${WC_MAX} words"

# Add existing article slugs for internal linking (full titles for context)
if [[ -n "$EXISTING_SLUGS" ]]; then
  # Build a list of article titles with their slugs for better internal linking
  ARTICLE_LIST=""
  if [[ -d "$POST_DIR" ]]; then
    while IFS= read -r article_file; do
      [[ "$(basename "$article_file")" == "_index.md" ]] && continue
      article_slug=$(basename "$article_file" .md)
      article_title=$(grep '^title:' "$article_file" 2>/dev/null | head -1 | sed 's/^title: *"*//;s/"*$//')
      if [[ -n "$article_title" ]]; then
        ARTICLE_LIST="${ARTICLE_LIST}
- [${article_title}](/posts/${article_slug}/)"
      fi
    done < <(find "$POST_DIR" -name "*.md" -not -name "_index.md" 2>/dev/null)
  fi

  if [[ -n "$ARTICLE_LIST" ]]; then
    USER_PROMPT="${USER_PROMPT}

Existing articles on this site (include 3-4 contextual internal links within paragraphs, NOT in a separate 'Related' section):
${ARTICLE_LIST}"
  fi
fi

# Add tool references
if [[ -n "$TOOLS_INFO" ]]; then
  USER_PROMPT="${USER_PROMPT}

Interactive tools on our site (link naturally if relevant): ${TOOLS_INFO}"
fi

USER_PROMPT="${USER_PROMPT}

Output ONLY the markdown content with frontmatter. No explanations."

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

# Validate output: check for banned patterns
BODY=$(echo "$MARKDOWN" | sed -n '/^---$/,/^---$/!p' | sed '1,/^---$/d')
FIRST_LINE=$(echo "$BODY" | head -20 | grep -m1 '[A-Za-z]' || true)
BANNED_FOUND=""
if echo "$FIRST_LINE" | grep -qiE '^In (today|the vast|an era|a world|the ever)'; then
  BANNED_FOUND="Banned opening detected: $FIRST_LINE"
fi
LAST_BOLD=$(echo "$BODY" | tail -10 | grep -oE '\*\*[^*]+\*\*' | tail -1 || true)
if echo "$LAST_BOLD" | grep -qiE '(Ready to|Start your journey|Bookmark Search123)'; then
  BANNED_FOUND="${BANNED_FOUND:+$BANNED_FOUND; }Banned closing detected: $LAST_BOLD"
fi
if [[ -n "$BANNED_FOUND" ]]; then
  log_warn "Anti-pattern detected: $BANNED_FOUND"
  log_warn "Article will be saved but may need manual editing"
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
