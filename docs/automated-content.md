**English** | [中文](zh/automated-content.md)

# Automated Content Pipeline

How SiteFactory automatically generates and publishes SEO-optimized content for Hugo sites.

## Overview

The automated content pipeline consists of three layers:

1. **Content Plan** — AI generates 25 article topics based on the site's niche
2. **Smart Initialization** — New sites launch with 5 seed articles + homepage content
3. **Scheduled Generation** — GitHub Actions cron generates articles on a configurable schedule

Content plans are stored in `content-plans/` (outside `sites/`), keeping site directories clean and separating AI-dependent features from the core site structure.

## Architecture

```
SiteFactory/
├── config.yaml                    # Global defaults (content.default_schedule, etc.)
├── content-plans/                 # AI content plans (separate from sites/)
│   ├── home-coffee-brewing.yaml   # Per-site: topics, schedule, last_generated
│   └── tech-tips.yaml
├── sites/
│   └── home-coffee-brewing/       # Clean site files only
│       ├── site.yaml              # Core metadata (no AI-specific fields)
│       ├── hugo.toml
│       └── content/posts/         # Generated articles land here
└── .github/workflows/
    └── scheduled-content.yml      # Daily cron, reads content-plans/
```

## How It Works

### Site Creation Flow

When you create a new Hugo site:

```bash
./scripts/launch-site.sh hugo home-coffee-brewing \
  "Home Coffee Brewing Guide" \
  "Master the art of brewing perfect coffee at home"
```

The following happens automatically (if AI is configured):

1. Template copied and configured → `sites/home-coffee-brewing/`
2. `generate-content-plan.sh` → creates `content-plans/home-coffee-brewing.yaml` with 25 topics
3. `generate-seed-content.sh` → generates homepage intro, about page, and 5 articles
4. Hugo build verification
5. Deploy to Vercel

Without AI configured, the site still creates normally — just without auto-generated content.

### Content Plan File (`content-plans/{site}.yaml`)

```yaml
site: home-coffee-brewing
niche: "home coffee brewing guide"
publishing_schedule: "weekly"
last_generated: "2026-02-19"
target_keywords:
  - "home coffee brewing"
  - "pour over coffee"
topics:
  - title: "Best Pour-Over Technique for Beginners"
    keywords: "pour over coffee, pour over technique"
    status: published
  - title: "French Press vs AeroPress: Complete Comparison"
    keywords: "french press vs aeropress"
    status: pending
```

Topic statuses: `pending` → `in_progress` → `published`

### Scheduled Generation

The `scheduled-content.yml` GitHub Actions workflow runs daily at 09:00 UTC:

1. Scans `content-plans/*.yaml` for pending topics
2. Checks `publishing_schedule` vs `last_generated` to determine if a site is due
3. Generates one article per eligible site
4. Commits and pushes (triggering auto-deploy via `deploy.yml`)

## Configuration

### Three-Level Priority (highest to lowest)

| Level | Where | Example |
|-------|-------|---------|
| **Per-site** | `content-plans/{site}.yaml` → `publishing_schedule` | `"daily"` |
| **GitHub Secret** | `SF_CONTENT_SCHEDULE` | `"2x-week"` |
| **Global default** | `config.yaml` → `content.default_schedule` | `"weekly"` |

### config.yaml (Global Defaults)

```yaml
content:
  default_schedule: "weekly"       # daily | 2x-week | weekly | biweekly
  default_topic_count: 25          # Topics per content plan
  default_seed_articles: 5         # Seed articles on new site creation
```

### GitHub Secrets (for CI)

| Secret | Required | Description |
|--------|----------|-------------|
| `SF_AI_API_KEY` | Yes | AI provider API key |
| `SF_AI_PROVIDER` | No | Provider name (default: claude) |
| `SF_CONTENT_SCHEDULE` | No | Global schedule override for CI |
| `SF_DOMAIN` | Yes | Base domain |
| `SF_ADSENSE_PUB_ID` | No | AdSense publisher ID |
| `SF_GA_ID` | No | Google Analytics ID |

### AI Provider

```yaml
ai:
  provider: "claude"  # or openai, deepseek, gemini, moonshot, zhipu
  providers:
    claude:
      api_key: "sk-ant-..."
      model: "claude-sonnet-4-20250514"
```

## Scripts

| Script | Purpose |
|--------|---------|
| `generate-content-plan.sh` | Generate/refresh content plan → `content-plans/{site}.yaml` |
| `generate-seed-content.sh` | Generate homepage, about page, and seed articles |
| `generate-content.sh` | Generate a single article (manual or plan mode) |

### generate-content-plan.sh

```bash
./scripts/generate-content-plan.sh <site-name> [topic_count] [schedule]

# Examples:
./scripts/generate-content-plan.sh home-coffee-brewing          # Uses config.yaml defaults
./scripts/generate-content-plan.sh home-coffee-brewing 30 daily  # Override: 30 topics, daily
```

### generate-seed-content.sh

```bash
./scripts/generate-seed-content.sh <site-name> [article_count]

# Examples:
./scripts/generate-seed-content.sh home-coffee-brewing     # Uses config.yaml default (5)
./scripts/generate-seed-content.sh home-coffee-brewing 3   # Override: 3 articles
```

### generate-content.sh (Enhanced)

```bash
# Manual mode (original behavior):
./scripts/generate-content.sh home-coffee-brewing "Best Espresso Machines" "espresso,budget"

# Plan mode (new): picks next pending topic from content-plans/
./scripts/generate-content.sh home-coffee-brewing
```

## Publishing Schedule Options

| Schedule | Frequency | AI Cost (5 sites) |
|----------|-----------|--------------------|
| `daily` | Every day | ~$9/month |
| `2x-week` | Every 3 days | ~$6/month |
| `weekly` | Every 7 days (default) | ~$1.7/month |
| `biweekly` | Every 14 days | ~$0.9/month |

## Manual Workflow Triggers

From GitHub Actions UI:

- **Scheduled Content Generation** → Run workflow
  - `site_name`: Target a specific site (empty = all eligible)
  - `force`: Ignore schedule timing, generate now

## Refreshing the Content Plan

When all topics are published:

```bash
./scripts/generate-content-plan.sh home-coffee-brewing 25
```

This generates 25 new topics. Existing published articles are unaffected.
