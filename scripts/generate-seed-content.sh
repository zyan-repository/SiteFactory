#!/usr/bin/env bash
# generate-seed-content.sh - Generate initial content for a new Hugo site.
# Creates homepage body, about page body, and N seed articles from the content plan.
#
# Usage: ./scripts/generate-seed-content.sh <site-name> [article_count]
#
# Defaults: article_count from config.yaml (content.default_seed_articles, default 5)
# Prerequisites: generate-content-plan.sh should be run first to create content-plans/{site}.yaml

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/config.sh"
source "$REPO_ROOT/scripts/lib/logging.sh"
source "$REPO_ROOT/scripts/lib/llm.sh"

SITE_NAME="${1:?Usage: generate-seed-content.sh <site-name> [article_count]}"
ARTICLE_COUNT="${2:-${SF_CONTENT_SEED_ARTICLES:-5}}"

SITE_DIR="$REPO_ROOT/sites/$SITE_NAME"
SITE_YAML="$SITE_DIR/site.yaml"
PLAN_FILE="$REPO_ROOT/content-plans/$SITE_NAME.yaml"

if [[ ! -f "$SITE_YAML" ]]; then
  log_error "site.yaml not found: $SITE_YAML"
  exit 1
fi

SITE_TITLE=$(yq '.title // ""' "$SITE_YAML")
SITE_DESC=$(yq '.description // ""' "$SITE_YAML")
SITE_LANG=$(yq '.language // "en"' "$SITE_YAML")

# Read niche from content plan if available, otherwise derive from title
NICHE=""
if [[ -f "$PLAN_FILE" ]]; then
  NICHE=$(yq '.niche // ""' "$PLAN_FILE")
fi
if [[ -z "$NICHE" || "$NICHE" == "null" ]]; then
  NICHE=$(echo "$SITE_TITLE" | tr '[:upper:]' '[:lower:]')
fi

# Determine language instruction for AI
LANG_INSTRUCTION="Write in English."
if [[ "$SITE_LANG" == "zh" || "$SITE_LANG" == "zh-"* ]]; then
  LANG_INSTRUCTION="Write in Chinese (简体中文)."
elif [[ "$SITE_LANG" == "ja" ]]; then
  LANG_INSTRUCTION="Write in Japanese (日本語)."
fi

log_info "Generating seed content for '$SITE_NAME'"
log_info "Provider: $SF_AI_PROVIDER ($SF_AI_MODEL)"

# --- Step 1: Generate homepage body ---
log_step "Step 1/3: Generating homepage content..."

INDEX_FILE="$SITE_DIR/content/_index.md"
if [[ -f "$INDEX_FILE" ]]; then
  HOMEPAGE_PROMPT="Write a 300-400 word introduction for a website called '${SITE_TITLE}'.
Topic/niche: ${NICHE}.
Description: ${SITE_DESC}.

Include:
- An engaging H2 heading (not H1)
- 2-3 paragraphs introducing the topic and why it matters
- A 'What You Will Find Here' section with 4-5 bullet points describing content categories
- Do NOT include any YAML frontmatter

${LANG_INSTRUCTION}
Output ONLY the markdown body content."

  HOMEPAGE_BODY=$(llm_generate "You are a web content writer specializing in ${NICHE}." "$HOMEPAGE_PROMPT") || true

  if [[ -n "$HOMEPAGE_BODY" ]]; then
    # Strip code fences
    HOMEPAGE_BODY=$(echo "$HOMEPAGE_BODY" | sed '/^```.*$/d')
    # Append body after existing frontmatter
    echo "" >> "$INDEX_FILE"
    echo "$HOMEPAGE_BODY" >> "$INDEX_FILE"
    log_ok "Homepage content generated"
  else
    log_warn "Homepage generation failed (non-critical)"
  fi
else
  log_warn "Homepage file not found: $INDEX_FILE"
fi

# Rate limit protection
sleep 3

# --- Step 2: Generate about page body ---
log_step "Step 2/3: Generating about page content..."

ABOUT_FILE="$SITE_DIR/content/about.md"
if [[ -f "$ABOUT_FILE" ]]; then
  ABOUT_PROMPT="Write a 300-word about page for a website called '${SITE_TITLE}'.
Niche: ${NICHE}.
Description: ${SITE_DESC}.

Include:
- Who runs the site and the mission (use the site name, don't invent personal names)
- What readers will find and why it's valuable
- A brief mention of content quality commitment
- Do NOT include any YAML frontmatter

${LANG_INSTRUCTION}
Output ONLY the markdown body content."

  ABOUT_BODY=$(llm_generate "You are a web content writer specializing in ${NICHE}." "$ABOUT_PROMPT") || true

  if [[ -n "$ABOUT_BODY" ]]; then
    # Strip code fences
    ABOUT_BODY=$(echo "$ABOUT_BODY" | sed '/^```.*$/d')

    # Replace everything after the frontmatter closing ---
    FRONTMATTER_END=$(grep -n '^---$' "$ABOUT_FILE" | sed -n '2p' | cut -d: -f1)
    if [[ -n "$FRONTMATTER_END" ]]; then
      head -n "$FRONTMATTER_END" "$ABOUT_FILE" > "${ABOUT_FILE}.tmp"
      echo "" >> "${ABOUT_FILE}.tmp"
      echo "$ABOUT_BODY" >> "${ABOUT_FILE}.tmp"
      mv "${ABOUT_FILE}.tmp" "$ABOUT_FILE"
      log_ok "About page content generated"
    else
      log_warn "Could not find frontmatter boundary in about.md"
    fi
  else
    log_warn "About page generation failed (non-critical)"
  fi
else
  log_warn "About file not found: $ABOUT_FILE"
fi

# Rate limit protection
sleep 3

# --- Step 3: Generate seed articles ---
log_step "Step 3/3: Generating $ARTICLE_COUNT seed articles..."

if [[ ! -f "$PLAN_FILE" ]]; then
  log_warn "No content plan found at $PLAN_FILE. Skipping seed articles."
  log_info "Run first: ./scripts/generate-content-plan.sh $SITE_NAME"
else
  # Check content plan has pending topics
  PENDING_COUNT=$(yq '[.topics[] | select(.status == "pending")] | length' "$PLAN_FILE" 2>/dev/null || echo "0")
  if [[ "$PENDING_COUNT" -lt 1 ]]; then
    log_warn "No pending topics in content plan. Skipping seed articles."
  else
    GENERATED=0
    for i in $(seq 1 "$ARTICLE_COUNT"); do
      # Re-check pending count (generate-content.sh updates the plan file)
      TOPIC=$(yq "[.topics[] | select(.status == \"pending\")][0].title // \"\"" "$PLAN_FILE")

      if [[ -z "$TOPIC" || "$TOPIC" == "null" ]]; then
        log_warn "No more pending topics after $GENERATED articles"
        break
      fi

      log_info "  [$i/$ARTICLE_COUNT] $TOPIC"

      # Call generate-content.sh in plan mode (no topic arg = reads from content plan)
      if "$REPO_ROOT/scripts/generate-content.sh" "$SITE_NAME"; then
        GENERATED=$((GENERATED + 1))
      else
        log_warn "  Failed to generate article $i (continuing...)"
      fi

      # Rate limit protection between articles
      if [[ "$i" -lt "$ARTICLE_COUNT" ]]; then
        sleep 5
      fi
    done

    log_ok "Generated $GENERATED/$ARTICLE_COUNT seed articles"
  fi
fi

log_ok "Seed content generation complete for '$SITE_NAME'"
log_info "Review content: ls sites/$SITE_NAME/content/posts/"
