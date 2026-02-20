**English** | [中文](zh/deployment-automation.md)

# Deployment Automation

SiteFactory offers three levels of deployment automation. Choose based on your needs:

| Method | Best For | Setup | Infrastructure |
|--------|----------|-------|----------------|
| **One-Click Script** | Quick local deploys | None | Local machine |
| **GitHub Actions** | Auto-deploy on push, scheduled tasks | GitHub Secrets | Free (GitHub) |
| **n8n Workflows** | Visual automation, complex pipelines | Docker | Self-hosted |

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
| `SF_AI_API_KEY` | Claude/OpenAI API key | `config.yaml` → `ai.providers.claude.api_key` |

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

The workflow generates the article, commits it, and pushes — which triggers the deploy workflow automatically.

## Method 3: n8n Workflows (Optional)

For visual workflow automation. Requires a running n8n instance.

### Quick Setup

```bash
# Start n8n with Docker
docker run -d --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  -v /path/to/SiteFactory:/data/SiteFactory \
  -e SF_PROJECT_ROOT=/data/SiteFactory \
  -e SF_DOMAIN=search123.top \
  n8nio/n8n
```

### Import Workflows

1. Open http://localhost:5678
2. Go to Workflows → Import from file
3. Import each JSON from `n8n/workflows/`:
   - `new-site-pipeline.json` — Webhook: create + deploy sites
   - `content-generation.json` — Webhook: AI content generation
   - `monitoring-report.json` — Cron: daily monitoring dashboard
   - `site-health-check.json` — Cron: health checks every 6h
4. Activate each workflow

See [n8n/README.md](../n8n/README.md) for detailed setup instructions.

## Choosing the Right Method

| Scenario | Recommended |
|----------|-------------|
| Building your first few sites | One-Click Script |
| Regular content updates via git | GitHub Actions (auto-deploy) |
| Daily AI content generation | GitHub Actions (content workflow) |
| 10+ sites, need monitoring | GitHub Actions (health check) |
| Complex multi-step automation | n8n |
| Visual workflow editing | n8n |
