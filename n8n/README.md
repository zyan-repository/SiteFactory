# SiteFactory n8n Workflows

Automation workflows for SiteFactory, designed to be imported into an [n8n](https://n8n.io/) instance.

## Workflows

| Workflow | File | Trigger | Description |
|----------|------|---------|-------------|
| New Site Pipeline | `workflows/new-site-pipeline.json` | Webhook (POST) | Create new Hugo or forked sites via API |
| Content Generation | `workflows/content-generation.json` | Webhook (POST) | Generate SEO-optimized articles using Claude AI |
| Monitoring Report | `workflows/monitoring-report.json` | Cron (daily 8AM UTC) | Generate dashboard and alert on site downtime |
| Site Health Check | `workflows/site-health-check.json` | Cron (every 6 hours) | Check all sites and alert on failures |

## Prerequisites

- **n8n instance** running (self-hosted or n8n Cloud)
- **SiteFactory repository** cloned on the same machine as n8n (for Execute Command nodes)
- **Node.js / Hugo** installed on the n8n host for site building
- **Git** configured with push access to the SiteFactory repository

## How to Import Workflows

1. Open your n8n instance in a browser (default: `http://localhost:5678`)
2. Go to **Workflows** in the left sidebar
3. Click the **"..."** menu (top right) and select **"Import from file"**
4. Select the `.json` file from the `workflows/` directory
5. Click **Save** to save the imported workflow
6. **Activate** the workflow using the toggle in the top right

Alternatively, use the n8n CLI:

```bash
# Import a single workflow
n8n import:workflow --input=workflows/new-site-pipeline.json

# Import all workflows
for f in workflows/*.json; do
  n8n import:workflow --input="$f"
done
```

## Required Credentials

### Claude API Key (for Content Generation)

1. Go to **Settings > Credentials** in n8n
2. Click **Add Credential** and select **Header Auth**
3. Configure:
   - **Name**: `Claude API Key`
   - **Header Name**: `x-api-key`
   - **Header Value**: Your Anthropic API key from https://console.anthropic.com/
4. Save the credential
5. In the "Content Generation" workflow, the "Call Claude API" node will use this credential

### Environment Variables

Set these in your n8n environment (`.env` file or system environment):

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `SF_DOMAIN` | Yes | Your base domain for all sites | `example.com` |
| `SF_ALERT_WEBHOOK_URL` | No | Webhook URL for alerts (Slack, Discord, etc.) | `https://hooks.slack.com/services/...` |

If running n8n via Docker, add to your `docker-compose.yml`:

```yaml
services:
  n8n:
    environment:
      - SF_DOMAIN=yourdomain.com
      - SF_ALERT_WEBHOOK_URL=https://hooks.slack.com/services/xxx
```

### SiteFactory Config

The workflows use scripts from the SiteFactory repository, which read credentials from `config.yaml`. Make sure these are configured:

| Config Key | Used By | Purpose |
|------------|---------|---------|
| `vercel.token` | deploy.sh | Vercel deployment |
| `domain.name` | All scripts | Base domain |
| `claude.api_key` | Content Generation | Claude API (workflow uses its own credential, but scripts may also use this) |
| `monitoring.uptimerobot_api_key` | Monitoring Report | UptimeRobot integration |

## Workflow Details

### 1. New Site Pipeline

**Endpoint**: `POST <n8n-base-url>/webhook/new-site`

**Request body**:
```json
{
  "type": "hugo",
  "name": "tech-blog",
  "title": "Tech Blog",
  "description": "A blog about technology",
  "source": "https://github.com/user/repo"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"hugo"` or `"fork"` | Yes | Hugo creates from template; fork clones a GitHub repo |
| `name` | string | Yes | Site name (lowercase, alphanumeric, hyphens only) |
| `title` | string | Yes | Display title for the site |
| `description` | string | No | Site description |
| `source` | string | Only for `fork` | GitHub repository URL to fork |

**Response** (success):
```json
{
  "success": true,
  "site_name": "tech-blog",
  "site_type": "hugo",
  "site_directory": "sites/tech-blog",
  "message": "Site 'tech-blog' created successfully"
}
```

**Test**:
```bash
curl -X POST http://localhost:5678/webhook/new-site \
  -H "Content-Type: application/json" \
  -d '{
    "type": "hugo",
    "name": "test-site",
    "title": "Test Site",
    "description": "A test site"
  }'
```

### 2. Content Generation

**Endpoint**: `POST <n8n-base-url>/webhook/generate-content`

**Request body**:
```json
{
  "site_name": "tech-blog",
  "topic": "10 Best Practices for Web Performance",
  "keywords": ["web performance", "page speed", "core web vitals"],
  "word_count": 1200
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `site_name` | string | Yes | Target site (must exist in `sites/`) |
| `topic` | string | Yes | Article topic / title |
| `keywords` | string[] | No | SEO keywords to include |
| `word_count` | number | No | Target word count (300-5000, default 1200) |

**What it does**:
1. Validates input and generates a URL-friendly slug from the topic
2. Calls Claude API with an SEO-optimized prompt to generate a markdown article with Hugo frontmatter
3. Writes the article to `sites/<name>/content/posts/<slug>.md`
4. Commits and pushes to git (which triggers Vercel auto-deploy if configured)

**Test**:
```bash
curl -X POST http://localhost:5678/webhook/generate-content \
  -H "Content-Type: application/json" \
  -d '{
    "site_name": "tech-blog",
    "topic": "Getting Started with Hugo Static Sites",
    "keywords": ["hugo", "static site generator", "jamstack"],
    "word_count": 800
  }'
```

### 3. Monitoring Report

**Trigger**: Runs automatically every day at 8:00 AM UTC.

**What it does**:
1. Executes `scripts/generate-dashboard.sh` to collect site metrics and UptimeRobot data
2. Reads the generated `dashboard/data/metrics.json` to check for downtime
3. If any monitored sites are down, sends an alert to the configured webhook URL
4. If all sites are healthy, logs the status silently

**Manual trigger**: Open the workflow in n8n and click "Execute Workflow" to run immediately.

### 4. Site Health Check

**Trigger**: Runs automatically every 6 hours (00:00, 06:00, 12:00, 18:00 UTC).

**What it does**:
1. Reads all site directories from `sites/` (skipping `_template` and `_shared`)
2. For each site, makes an HTTP GET request to `https://<name>.<domain>/`
3. Records response status and categorizes as healthy/unhealthy/down
4. If any sites fail, sends an alert to the configured webhook
5. Writes health check results to `dashboard/data/health.json`

**Manual trigger**: Open the workflow in n8n and click "Execute Workflow" to run immediately.

## Configuring Webhook URLs

When you import a webhook-triggered workflow, n8n assigns URLs based on your instance configuration:

- **Development**: `http://localhost:5678/webhook/<path>`
- **Production**: `https://your-n8n-domain.com/webhook/<path>`
- **Test mode**: `http://localhost:5678/webhook-test/<path>` (only active while the workflow editor is open)

To get the exact webhook URL:
1. Open the workflow
2. Click the Webhook trigger node
3. The URLs are shown in the node parameters panel

## Configuring Alert Destinations

The monitoring and health check workflows send alerts to a webhook URL. This is compatible with:

- **Slack**: Use an [Incoming Webhook URL](https://api.slack.com/messaging/webhooks)
- **Discord**: Use a [Discord Webhook URL](https://support.discord.com/hc/en-us/articles/228383668)
- **Custom endpoint**: Any HTTP endpoint that accepts POST with JSON body

Set the `SF_ALERT_WEBHOOK_URL` environment variable, or edit the "Send Alert" node URL directly in each workflow.

## Path Configuration

The workflows use the `SF_PROJECT_ROOT` environment variable to locate the SiteFactory repository.

Set this variable in your n8n environment:
- **n8n Docker**: Add `-e SF_PROJECT_ROOT=/path/to/SiteFactory` to your `docker run` command
- **n8n Desktop**: Set the environment variable in your shell before starting n8n
- **n8n Cloud**: Configure in n8n Settings > Environment Variables

If `SF_PROJECT_ROOT` is not set, workflow Execute Command nodes will fail with a path error.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Webhook returns 404 | Make sure the workflow is **activated** (toggle on) |
| Execute Command fails | Verify the SiteFactory repo path is correct and scripts are executable (`chmod +x scripts/*.sh`) |
| Claude API returns 401 | Check your API key in the "Claude API Key" credential |
| Health check times out | Increase the timeout in the HTTP Health Check node (default: 15s) |
| No alert received | Verify `SF_ALERT_WEBHOOK_URL` is set and the URL is reachable from the n8n host |
| Git push fails | Ensure git remote is configured and SSH keys / credentials are available to the n8n process |
