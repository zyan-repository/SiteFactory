**English** | [中文](zh/setup-guide.md)

# Setup Guide

Step-by-step guide to set up SiteFactory from scratch. No programming experience required.

## What You'll Need

Before starting, prepare these accounts and credentials:

| Item | Where to get it | Cost |
|------|----------------|------|
| Domain name | [NameSilo](https://www.namesilo.com/) | ~$9/year |
| NameSilo API key | [NameSilo API Manager](https://www.namesilo.com/account/api-manager) | Free |
| Vercel account | [vercel.com](https://vercel.com/) (sign up with GitHub) | Free |
| Vercel token | [vercel.com/account/tokens](https://vercel.com/account/tokens) | Free |
| Google AdSense | [adsense.google.com](https://adsense.google.com/) | Free |
| Google Analytics | [analytics.google.com](https://analytics.google.com/) | Free |
| UptimeRobot (optional) | [uptimerobot.com](https://uptimerobot.com/) | Free |
| Claude API key (optional) | [console.anthropic.com](https://console.anthropic.com/) | Pay-as-you-go |

## Step 1: Install Tools

### macOS

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install hugo yq jq node git
```

### Ubuntu/Debian

```bash
sudo apt-get install hugo yq jq nodejs git
```

### Fedora/RHEL

```bash
sudo dnf install hugo yq jq nodejs git
```

### Windows

Install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) with Ubuntu, then follow the Ubuntu instructions above.

Verify everything installed:

```bash
hugo version    # Should show Hugo version
yq --version    # Should show yq version
jq --version    # Should show jq version
node --version  # Should show Node.js version
```

## Step 2: Clone the Repository

```bash
git clone https://github.com/yourname/SiteFactory.git
cd SiteFactory
```

## Step 3: Run Setup

```bash
./scripts/setup.sh
```

This will:
1. Check all tools are installed
2. Create `config.yaml` from the template
3. Ask you to fill in your credentials

## Step 4: Edit config.yaml

Open `config.yaml` in any text editor:

```bash
nano config.yaml
# or
open config.yaml  # Opens in default editor
```

Fill in your values:

```yaml
domain:
  name: "yourdomain.com"              # Your NameSilo domain
  namesilo_api_key: "abc123def456"     # From NameSilo API Manager

vercel:
  token: "your-vercel-token-here"      # From Vercel Account > Tokens

adsense:
  publisher_id: "ca-pub-1234567890"    # From AdSense dashboard
  enabled: true

analytics:
  google_analytics_id: "G-XXXXXXXXXX"  # From Google Analytics
```

## Step 5: Validate

Run setup again to verify all credentials:

```bash
./scripts/setup.sh
```

You should see green checkmarks for all items. If any fail, double-check the corresponding credential.

## Step 6: Create Your First Site

### Option A: Hugo Content Site

```bash
./scripts/new-site.sh my-blog "My Tech Blog" "Tips and tutorials for developers"
```

Preview locally:

```bash
hugo server -s sites/my-blog
# Open http://localhost:1313
```

### Option B: Fork a GitHub Project

First, check if the project is compatible:

```bash
./scripts/check-repo.sh https://github.com/user/cool-tool
```

If it passes, fork it:

```bash
./scripts/fork-site.sh https://github.com/user/cool-tool cool-tool "Cool Tool"
```

Preview:

```bash
open sites/cool-tool/index.html
```

## Step 7: Deploy

```bash
# Deploy a single site
./scripts/deploy.sh my-blog

# Or deploy all sites at once
./scripts/deploy-all.sh
```

The script will:
1. Build the site (Hugo sites only)
2. Deploy to Vercel
3. Configure your custom subdomain (`my-blog.yourdomain.com`)

## Step 8: Set Up DNS (First Time Only)

For each site, add a DNS record:

```bash
./scripts/dns-setup.sh my-blog
```

This creates a CNAME record: `my-blog.yourdomain.com` → `cname.vercel-dns.com`

DNS changes can take up to 48 hours to propagate. Your site will be live at `https://my-blog.yourdomain.com` once DNS is ready.

## Step 9: Apply for AdSense

> AdSense requires your site to have real content and be at least 1-2 weeks old.

1. Deploy at least 15 pages of original content
2. Make sure privacy policy and about pages exist
3. Wait 1-2 weeks for Google to index your site
4. Apply at [adsense.google.com](https://adsense.google.com/)
5. Once approved, the ads will automatically appear (Auto-Ads is already configured)

See [Content Strategy](content-strategy.md) for detailed AdSense approval tips.

## Step 10: Monitor (Optional)

Generate a monitoring dashboard:

```bash
./scripts/generate-dashboard.sh
open dashboard/index.html
```

Run Lighthouse audits:

```bash
./scripts/lighthouse-check.sh my-blog
# Or all sites:
./scripts/lighthouse-check.sh --all
```

## Troubleshooting

### "command not found: hugo"

Hugo might not be in your PATH. Try:

```bash
# Check where Hugo is installed
which hugo || find /usr -name hugo 2>/dev/null

# macOS (Homebrew): if Hugo is in /opt/homebrew/bin
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Linux: reinstall via package manager
sudo apt-get install hugo  # Ubuntu/Debian
sudo dnf install hugo      # Fedora
```

### "Vercel token invalid"

1. Go to [vercel.com/account/tokens](https://vercel.com/account/tokens)
2. Create a new token with "Full Account" scope
3. Update `config.yaml`

### "NameSilo API key not working"

1. Go to [NameSilo API Manager](https://www.namesilo.com/account/api-manager)
2. Make sure the API key has "DNS Manager" permission
3. Verify the domain is in your NameSilo account

### Build fails with Hugo

```bash
# Check for errors
hugo -s sites/my-blog --verbose

# Common fix: clean cache
rm -rf sites/my-blog/resources
hugo -s sites/my-blog --gc --minify
```

## Next Steps

- Create more sites: see [Adding a New Site](adding-new-site.md)
- Find projects to fork: see [Fork Guide](fork-guide.md)
- Get AdSense approved: see [Content Strategy](content-strategy.md)
- Set up automation: see [n8n/README.md](../n8n/README.md)
