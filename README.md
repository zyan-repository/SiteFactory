**English** | [中文](README.zh.md)

# SiteFactory

**Mass production, massive returns.**

Static website mass production system — build 100 sites for the cost of one domain. Fork existing open-source projects or generate Hugo content sites, auto-deploy to Vercel, monetize with AdSense.

```
Idea → Fork/Generate → Deploy → Earn
        (2 min)       (auto)   (passive)
```

## Why SiteFactory?

| | Traditional | SiteFactory |
|---|---|---|
| Sites per month | 1-2 | 50+ |
| Cost per site | $5-50/mo | **$0** |
| Setup time | Hours | **< 2 minutes** |
| Technical skill | Required | **Not required** |
| Total monthly cost | $50-500 | **< $2** |

## How It Works

### Two Paths to a New Site

**Path A: Fork an existing project** — Find a useful open-source tool (calculator, converter, weather app), run one command to adapt it with ads and deploy.

```bash
# Check if a GitHub project is compatible
./scripts/check-repo.sh https://github.com/evgeni/qifi

# Fork it: clone → inject AdSense/Analytics → deploy
./scripts/fork-site.sh https://github.com/evgeni/qifi wifi-qr "WiFi QR Generator"
./scripts/deploy.sh wifi-qr
```

**Path B: Generate a Hugo content site** — Create an SEO-optimized blog with AI-generated content.

```bash
# Create from template
./scripts/new-site.sh tech-tips "Tech Tips Blog" "Daily tips for developers"
./scripts/deploy.sh tech-tips
```

Both paths produce sites that:
- Score 90+ on Lighthouse
- Are AdSense-compliant (privacy policy, ads.txt, proper ad placement)
- Have full SEO (meta tags, Open Graph, JSON-LD, sitemap, robots.txt)
- Support i18n (multilingual content)
- Auto-deploy to Vercel with custom subdomains

## Quick Start

### Prerequisites

**macOS:**
```bash
brew install hugo yq jq node
```

**Ubuntu/Debian:**
```bash
sudo apt-get install hugo yq jq nodejs
```

**Windows:** Use [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) with Ubuntu, then follow the Linux instructions above.

### Setup (One Time)

```bash
# 1. Clone the repo
git clone https://github.com/yourname/SiteFactory.git
cd SiteFactory

# 2. Run setup — creates config.yaml, checks tools, validates credentials
./scripts/setup.sh

# 3. Edit config.yaml with your credentials
#    Each field has comments explaining WHERE to find the value.
#    For full step-by-step instructions: docs/setup-guide.md
nano config.yaml

# 4. Re-run setup to verify
./scripts/setup.sh
```

### Where to Find Your Credentials

| Credential | Where to get it | Format |
|------------|----------------|--------|
| Domain | [NameSilo](https://www.namesilo.com/) → buy a `.com` domain | `mysite.com` (no https://) |
| NameSilo API Key | [API Manager](https://www.namesilo.com/account/api-manager) → click "Generate" | ~20-30 alphanumeric chars |
| Vercel Token | [Tokens page](https://vercel.com/account/tokens) → click "Create", scope "Full Account" | ~24+ chars (shown once!) |
| AdSense Publisher ID | [AdSense](https://adsense.google.com/) → look at URL bar for `pub-XXXXX` → prepend `ca-` | `ca-pub-` + 16 digits |
| GA Measurement ID | [Analytics](https://analytics.google.com/) → **New account:** click "Start measuring" → create account & property → create stream → copy ID; **Existing:** Admin → Data Streams → your stream | `G-XXXXXXXXXX` |

Full step-by-step with click paths: see [Setup Guide](docs/setup-guide.md).

### Create Your First Site

```bash
# One-click: fork, deploy, DNS, and verify — all in one command
./scripts/launch-site.sh fork https://github.com/evgeni/qifi wifi-qr "WiFi QR Generator"

# Or for a Hugo content site
./scripts/launch-site.sh hugo my-blog "My Blog" "A blog about things"
```

Or step by step:

```bash
./scripts/fork-site.sh https://github.com/evgeni/qifi wifi-qr "WiFi QR Generator"
./scripts/deploy.sh wifi-qr
./scripts/dns-setup.sh wifi-qr
```

## Architecture

```
SiteFactory/
├── config.yaml              # Your credentials (git-ignored)
├── SITES.md                 # Registry of all integrated sites
├── sites/
│   ├── _template/           # Hugo site template (SEO-optimized)
│   ├── _shared/             # Shared pages for fork sites (privacy policy, about)
│   ├── my-blog/             # Hugo content site (type: hugo)
│   └── my-tool/             # Forked tool site (type: static)
├── scripts/
│   ├── setup.sh             # One-time setup
│   ├── new-site.sh          # Create Hugo site from template
│   ├── fork-site.sh         # Fork & adapt GitHub project
│   ├── check-repo.sh        # Evaluate GitHub project compatibility
│   ├── deploy.sh            # Deploy single site to Vercel
│   ├── deploy-all.sh        # Deploy all sites
│   ├── build-all.sh         # Build all Hugo sites
│   ├── dns-setup.sh         # Add DNS record via NameSilo API
│   ├── generate-dashboard.sh # Generate monitoring dashboard
│   ├── launch-site.sh       # One-click: create + deploy + DNS + verify
│   ├── generate-content.sh  # AI-generate SEO articles
│   ├── lighthouse-check.sh  # Run Lighthouse audit
│   └── lib/                 # Shared functions (config, logging, injection, verify)
├── n8n/                     # Automation workflows (import into n8n)
├── dashboard/               # Monitoring dashboard (auto-generated HTML)
└── docs/                    # Documentation
```

### Site Types

Every site has a `site.yaml` that tells the system how to handle it:

```yaml
# Hugo content site (needs build step)
type: hugo
name: tech-blog
source: template

# Forked static site (deploy as-is)
type: static
name: wifi-qr
source: https://github.com/evgeni/qifi
license: MIT
```

The deploy script reads `type` and acts accordingly:
- `hugo` → build with Hugo, deploy `public/` directory
- `static` → deploy entire directory as-is

## The "Copy Before Create" Philosophy

Why build from scratch when thousands of useful tools already exist on GitHub?

### What to Fork

| Category | Examples | AdSense Value |
|----------|----------|---------------|
| Calculators | BMI, loan, mortgage, tip | High (practical queries) |
| Converters | Unit, currency, timezone, color | High (repeat visitors) |
| Generators | Password, QR code, Lorem Ipsum, gradient | High (precise SEO keywords) |
| Data lookup | Weather, IP info, exchange rates | High (daily traffic) |
| Reference | Periodic table, keyboard shortcuts, emoji list | Medium (rich content) |

### Compatibility Requirements

Before forking, a project must pass `check-repo.sh`:

- **License**: MIT / Apache 2.0 / BSD (allows commercial use)
- **No backend**: Pure HTML + CSS + JS only
- **No database**: No MySQL / PostgreSQL / MongoDB / Firebase
- **No auth**: No login / registration flow
- **Has index.html**: Can be served as static files

See [Fork Guide](docs/fork-guide.md) for the complete evaluation checklist.

## Cost Analysis

| Resource | Plan | Cost |
|----------|------|------|
| Hosting (Vercel) | Hobby (100GB/mo) | Free |
| Domain (NameSilo) | 1 domain + unlimited subdomains | ~$9/year |
| SSL | Vercel auto-provision | Free |
| CDN | Vercel Edge Network | Free |
| Monitoring (UptimeRobot) | 50 monitors | Free |
| Analytics (Google) | Unlimited | Free |
| CI/CD (Vercel) | Auto-deploy on push | Free |

**Total: ~$0.75/month** ($9/year for the domain, everything else free)

Revenue potential: Even modest AdSense earnings of $0.50/day across all sites = $15/month = 20x ROI.

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `launch-site.sh <fork\|hugo> ...` | **One-click: create + deploy + DNS + verify** |
| `setup.sh` | One-time setup, validates all credentials |
| `new-site.sh <name> <title> <desc>` | Create Hugo content site |
| `fork-site.sh <url> <name> [title]` | Fork & adapt GitHub project |
| `check-repo.sh <url>` | Evaluate GitHub project compatibility |
| `deploy.sh <name> [--preview] [--verify]` | Deploy single site to Vercel |
| `deploy-all.sh` | Deploy all sites |
| `build-all.sh` | Build all Hugo sites |
| `dns-setup.sh <name> [--verify]` | Add CNAME via NameSilo API |
| `generate-content.sh <name> <topic>` | AI-generate SEO articles |
| `generate-dashboard.sh` | Generate monitoring dashboard |
| `lighthouse-check.sh <name\|--all>` | Run Lighthouse audit |

## n8n Workflows

Import the JSON files from `n8n/workflows/` into your n8n instance:

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| `new-site-pipeline` | Webhook | Creates and deploys a new site |
| `content-generation` | Cron (daily) | AI-generates SEO articles via Claude API |
| `monitoring-report` | Cron (6h) | Updates monitoring dashboard |
| `site-health-check` | Cron (daily) | Checks DNS, SSL, uptime for all sites |

See [n8n/README.md](n8n/README.md) for setup instructions.

## Monitoring Dashboard

Auto-generated single HTML file showing all sites' status, uptime, and Lighthouse scores.

```bash
# Generate/update dashboard
./scripts/generate-dashboard.sh

# Open it
open dashboard/index.html
```

## Documentation

| Doc | 中文版 |
|-----|--------|
| [Setup Guide](docs/setup-guide.md) | [配置指南](docs/zh/setup-guide.md) |
| [Adding a New Site](docs/adding-new-site.md) | [添加新站点](docs/zh/adding-new-site.md) |
| [Fork Guide](docs/fork-guide.md) | [Fork 指南](docs/zh/fork-guide.md) |
| [Content Strategy](docs/content-strategy.md) | [内容策略](docs/zh/content-strategy.md) |
| [Contributing Sites](docs/contributing-sites.md) | [贡献站点](docs/zh/contributing-sites.md) |
| [Deployment Automation](docs/deployment-automation.md) | [部署自动化](docs/zh/deployment-automation.md) |
| [Site Registry](SITES.md) | [站点清单](SITES.zh.md) |

## Tech Stack

| Component | Technology | Why |
|-----------|-----------|-----|
| Content sites | Hugo | Fastest SSG (<1ms/page), single binary |
| Tool sites | Pure HTML/CSS/JS | Zero build, fork from GitHub |
| Hosting | Vercel Hobby | Free, 100GB bandwidth, auto SSL |
| Domain | NameSilo | ~$9/year, REST API for DNS |
| Automation | n8n (self-hosted) | Visual workflows, 400+ integrations |
| Content AI | Claude API (via n8n) | SEO-optimized article generation |
| Monitoring | UptimeRobot | Free 50 monitors, 5-min intervals |
| Ads | Google AdSense Auto-Ads | Single tag, auto-optimized placement |

## License

MIT
