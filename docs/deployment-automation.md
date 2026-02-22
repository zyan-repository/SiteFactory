**English** | [中文](zh/deployment-automation.md)

# Deployment Automation

SiteFactory offers two levels of deployment automation. Choose based on your needs:

| Method | Best For | Setup | Infrastructure |
|--------|----------|-------|----------------|
| **One-Click Script** | Quick local deploys | None | Local machine |
| **GitHub Actions** | Auto-deploy on push, scheduled tasks | GitHub Secrets | Free (GitHub) |

## Method 1: One-Click Script (Recommended)

The fastest way to go from idea to live site. One command handles everything:

### Fork a Tool Site

```bash
./scripts/launch-site.sh fork https://github.com/user/repo my-tool "My Tool" "A useful tool"
```

### Create a Hugo Content Site

```bash
./scripts/launch-site.sh hugo my-blog "My Blog" "A blog about things" en
```

### What Happens (6 Phases)

| Phase | Action | Duration |
|-------|--------|----------|
| 1/6 | Create site (fork or Hugo template) | 5-30s |
| 2/6 | Deploy to Vercel (production) | 15-60s |
| 3/6 | Setup DNS via NameSilo API | 2-5s |
| 4/6 | Verify DNS propagation (polling) | 0-120s |
| 5/6 | HTTP health check (verify site is live) | 0-60s |
| 6/6 | Lighthouse audit (optional) | 10-30s |

### Options

| Flag | Effect |
|------|--------|
| `--skip-verify` | Skip phases 4-6 (DNS, HTTP, Lighthouse checks) |

### Environment Variables

| Variable | Effect |
|----------|--------|
| `SF_JSON_OUTPUT=true` | Output machine-readable JSON summary |

### Example Output

```
[INFO]  === SiteFactory Launch: wifi-qr (fork) ===

[STEP]  Phase 1/6: Creating site...
[OK]    Site created: sites/wifi-qr

[STEP]  Phase 2/6: Deploying to production...
[OK]    Deployed: https://wifi-qr-xxx.vercel.app

[STEP]  Phase 3/6: Setting up DNS...
[OK]    CNAME record created

[STEP]  Phase 4/6: Verifying DNS propagation...
[OK]    DNS verified: wifi-qr.search123.top

[STEP]  Phase 5/6: Verifying site is live...
[OK]    Site is live: https://wifi-qr.search123.top

[STEP]  Phase 6/6: Running Lighthouse audit...
[OK]    Lighthouse audit complete

[OK]    === Launch complete! (47s) ===

  +------------------------------------------+
  | Site:    wifi-qr
  | Type:    fork
  | URL:     https://wifi-qr.search123.top
  | DNS:     verified
  | HTTP:    live
  | Time:    47s
  +------------------------------------------+

  Next steps:
    1. Submit sitemap to Google Search Console
       (auto-submitted if google_search_console_key_file is configured)
    2. Wait 1-2 weeks, then apply for AdSense
    3. Monitor: ./scripts/lighthouse-check.sh wifi-qr
```

## Individual Script Enhancements

### deploy.sh

```bash
# Standard deploy
./scripts/deploy.sh my-site

# Preview deploy (non-production)
./scripts/deploy.sh my-site --preview

# Deploy with post-deploy health check
./scripts/deploy.sh my-site --verify

# Flags can be in any order
./scripts/deploy.sh my-site --verify --preview
```

### dns-setup.sh

```bash
# Create CNAME only
./scripts/dns-setup.sh my-site

# Create CNAME and poll until DNS propagates
./scripts/dns-setup.sh my-site --verify
```

## Method 2: GitHub Actions

Automated workflows that run on GitHub's infrastructure (free).

### Setup: Configure GitHub Secrets

Go to your repo's **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret Name | Value | Where to Find |
|-------------|-------|---------------|
| `SF_DOMAIN` | Your domain (e.g., `search123.top`) | `config.yaml` → `domain.name` |
| `SF_VERCEL_TOKEN` | Vercel API token | `config.yaml` → `vercel.token` |
| `SF_NAMESILO_API_KEY` | NameSilo API key | `config.yaml` → `domain.namesilo_api_key` |
| `SF_ADSENSE_PUB_ID` | AdSense publisher ID | `config.yaml` → `adsense.publisher_id` |
| `SF_GA_ID` | Google Analytics ID | `config.yaml` → `analytics.google_analytics_id` |
| `SF_AI_API_KEY` | API key for your chosen AI provider | `config.yaml` → `ai.providers.<provider>.api_key` |

> **Note:** `SF_AI_API_KEY` is shared across all providers. When triggering Content Generation, you select the provider (claude, openai, deepseek, gemini, moonshot, zhipu) — the key must match the provider you choose.

### Available Workflows

#### Auto-Deploy (`deploy.yml`)

**Trigger:** Push to `sites/` directory on main branch, or manual dispatch.

- Automatically detects which site(s) changed
- Deploys only changed sites (parallel if multiple)
- Configures DNS automatically

**Manual trigger:** Go to Actions → "Deploy Sites" → "Run workflow" → enter site name.

#### Health Check (`health-check.yml`)

**Trigger:** Every 6 hours (cron), or manual dispatch.

- Checks HTTP status of all deployed sites
- Generates a health report in the workflow summary
- Warns if any site is down

#### Content Generation (`content-generation.yml`)

**Trigger:** Manual dispatch only.

Go to Actions → "Generate Content" → "Run workflow" and fill in:
- **Site name:** target Hugo site (must exist)
- **Topic:** article topic
- **Keywords:** comma-separated SEO keywords (optional)
- **Word count:** target word count (default 1200)
- **AI provider:** choose from claude, openai, deepseek, gemini, moonshot, zhipu (default: claude)
- **Model name:** leave empty for provider default, or specify a model (e.g., `deepseek-chat`)

The workflow generates the article, commits it, and pushes — which triggers the deploy workflow automatically.

## Choosing the Right Method

| Scenario | Recommended |
|----------|-------------|
| Building your first few sites | One-Click Script |
| Regular content updates via git | GitHub Actions (auto-deploy) |
| Daily AI content generation | GitHub Actions (content workflow) |
| 10+ sites, need monitoring | GitHub Actions (health check) |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Hugo site Vercel project named "public" | `deploy.sh` now auto-links Hugo projects to the correct name. For legacy deployments: `npx vercel link --project <site-name> --yes --cwd sites/<name>/public/ --token $TOKEN` then redeploy |
| Domain assignment fails silently | Check actual project name: `cat sites/<name>/public/.vercel/project.json`. If `projectName` doesn't match, re-link and redeploy |
