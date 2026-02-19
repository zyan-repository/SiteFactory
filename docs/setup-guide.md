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

**Don't have all of these yet?** That's OK — follow the detailed instructions in the next section to get each one. You can also skip optional items (UptimeRobot, Claude API) and add them later.

## How to Get Each Credential

> These instructions were accurate as of February 2026. If a website's UI looks different, the same information is still available — look for Settings or Account sections.

### 1. Domain Name (NameSilo)

A domain name is your website's address (e.g., `mysite.com`). You need to buy one.

**Steps:**
1. Go to [https://www.namesilo.com/domain/search-domains](https://www.namesilo.com/domain/search-domains)
2. Type your desired domain in the search box (e.g., `techtools`)
3. Click **"Search"**
4. Browse the results — look for a `.com` domain that shows as "Available"
5. Click **"Add"** next to your chosen domain
6. Click the **shopping cart icon** (top right) → **"Checkout"**
7. Create a NameSilo account (or log in if you already have one)
8. Complete the payment (PayPal or credit card, ~$8.99/year for `.com`)
9. After purchase, your domain appears at [https://www.namesilo.com/account/domain-manager](https://www.namesilo.com/account/domain-manager)

**What to put in config.yaml:** Just the domain name, without `https://` or `www.`

| Correct | Wrong |
|---------|-------|
| `mysite.com` | `https://mysite.com` |
| `techtools.net` | `www.techtools.net` |

> **Tip:** Choose `.com` for best SEO recognition. Avoid hyphens in domain names. Keep it short and memorable.

### 2. NameSilo API Key

The API key lets SiteFactory's scripts automatically manage DNS records for your domain.

**Steps:**
1. Log in to NameSilo
2. Go to [https://www.namesilo.com/account/api-manager](https://www.namesilo.com/account/api-manager)
3. If you see "You have not generated any API keys", click the **"Generate"** button
4. **Do NOT check** "Generate key for read-only access" (SiteFactory needs write access to create DNS records)
5. A key appears on the page — it looks like a long string of letters and numbers (approximately 20-30 characters)
6. **Copy it immediately** and paste into your config.yaml — you may not be able to see the full key again later

**What it looks like:** A string of ~20-30 alphanumeric characters, e.g., `a1b2c3d4e5f6g7h8i9j0k`

> **Security note:** This key has full access to your domains. Never share it or commit it to git.

### 3. Vercel Account + Token

Vercel is a free hosting service that will serve your websites. You need a GitHub account first.

**Pre-requisite — GitHub account:**
1. If you don't have a GitHub account, go to [https://github.com/signup](https://github.com/signup) and create one (free)

**Create Vercel account:**
1. Go to [https://vercel.com/](https://vercel.com/)
2. Click **"Sign Up"**
3. Choose **"Continue with GitHub"**
4. Authorize Vercel to access your GitHub account
5. You now have a Vercel account on the free Hobby plan

**Create a Vercel token:**
1. Go to [https://vercel.com/account/tokens](https://vercel.com/account/tokens)
2. Click **"Create"**
3. Fill in the form:
   - **Token Name:** anything you want (e.g., "SiteFactory")
   - **Scope:** select **"Full Account"** (this gives the token permission to deploy sites)
   - **Expiration:** choose "No Expiration" (or any duration you prefer)
4. Click **"Create Token"**
5. A long string appears — **copy it immediately!** This token is shown only once. If you close the page without copying, you'll need to create a new one.

**What it looks like:** A string of ~24 or more characters, e.g., `pZGwkE1JaBcDeFgHiJkLmN`

### 4. Google AdSense Publisher ID

AdSense is Google's ad network that pays you when visitors see or click ads on your sites. You need to sign up and get a publisher ID.

**Steps:**
1. Go to [https://adsense.google.com/](https://adsense.google.com/)
2. Sign in with your Google account (Gmail)
3. If this is your first time, click **"Get started"** and follow the signup steps (provide your website URL and country)
4. Google will review your application — this takes a few days to several weeks

**Where to find your publisher ID (once you have an AdSense account):**

**Method A — From the URL bar:**
1. Log in to [https://adsense.google.com/](https://adsense.google.com/)
2. Look at the URL in your browser's address bar
3. It will contain something like: `.../pub-5531531271065052/...`
4. Your publisher ID = prepend `ca-` to that number: **`ca-pub-5531531271065052`**

**Method B — From the settings page:**
1. Log in to AdSense
2. Click the **gear icon** (Settings) in the left sidebar
3. Click **"Account"** → **"Account Information"**
4. Find **"Publisher ID"** — it shows `pub-XXXXXXXXXXXXXXXX`
5. In your config.yaml, add the `ca-` prefix: **`ca-pub-XXXXXXXXXXXXXXXX`**

**What it looks like:** Always `ca-pub-` followed by 16 digits. Example: `ca-pub-5531531271065052`

> **Not approved yet?** No problem. Leave the placeholder value in config.yaml and set `adsense.enabled: false`. You can fill in the real ID later after approval. See [Content Strategy](content-strategy.md) for tips on getting approved.

### 5. Google Analytics Measurement ID

Google Analytics tracks how many visitors your sites get and where they come from.

**Create a Google Analytics property (first time):**
1. Go to [https://analytics.google.com/](https://analytics.google.com/)
2. Sign in with your Google account
3. Click **"Start measuring"** (or "Create Account" if prompted)
4. **Account Name:** enter anything (e.g., "SiteFactory")
5. Click **"Next"**
6. **Property Name:** enter anything (e.g., "My Sites")
7. Select your time zone and currency
8. Click **"Next"** → skip business details → click **"Create"**
9. Accept the terms of service
10. On the "Choose a platform" screen, select **"Web"**
11. Enter your website URL (e.g., `https://mysite.com`) and a stream name (e.g., "Main")
12. Click **"Create stream"**
13. The **Measurement ID** is shown at the top right of the stream details page — it starts with `G-`

**If you already have a Google Analytics account:**
1. Click the **gear icon** (Admin) in the bottom left
2. In the Property column, click **"Data Streams"**
3. Click your web stream
4. The **Measurement ID** is at the top right

**What it looks like:** `G-` followed by 10 uppercase letters or digits. Example: `G-A1B2C3D4E5`

### 6. Google Search Console Verification Code (optional — can add later)

Google Search Console lets you submit your sitemap so Google indexes your pages faster.

**Steps:**
1. Go to [https://search.google.com/search-console](https://search.google.com/search-console)
2. Click **"Add property"** (in the top-left dropdown)
3. Choose **"URL prefix"** (the right-hand option)
4. Enter your website URL: `https://yourdomain.com`
5. Click **"Continue"**
6. Choose the **"HTML tag"** verification method
7. Google shows you a meta tag like: `<meta name="google-site-verification" content="AbCdEf123456789..." />`
8. Copy just the value inside `content="..."` — that's your verification code

**What it looks like:** A string of ~43 alphanumeric characters

> **Note:** You won't be able to fully verify until your site is live and DNS is set up. You can come back to this step later.

### 7. UptimeRobot API Key (optional)

UptimeRobot monitors whether your sites are online and alerts you if they go down.

**Steps:**
1. Go to [https://uptimerobot.com/](https://uptimerobot.com/) and create a free account
2. Log in
3. Click your **profile icon** (top right)
4. Click **"My Settings"**
5. Scroll down to the **"API Settings"** section
6. Find **"Main API Key"** → click **"Show/Create"**
7. Copy the key

**What it looks like:** Starts with `u` followed by ~39 characters. Example: `u1234567-abcdef1234567890abcdef12`

### 8. Claude API Key (optional)

Only needed if you want to use AI to auto-generate blog articles via n8n workflows.

**Steps:**
1. Go to [https://console.anthropic.com/](https://console.anthropic.com/)
2. Create an account or sign in
3. **Add a payment method first** (Settings → Billing) — the API is pay-as-you-go (~$0.01-0.05 per article)
4. Click **"API Keys"** in the left sidebar
5. Click **"Create Key"** → name it anything → copy the key

**What it looks like:** Starts with `sk-ant-` followed by a long string. Example: `sk-ant-api03-abc123...`

---

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

Fill in your values. Every field has a comment explaining where to get it:

```yaml
domain:
  name: "mysite.com"                    # The domain you bought (see section 1 above)
  namesilo_api_key: "abc123def456"      # From NameSilo API Manager (see section 2)

vercel:
  token: "your-vercel-token-here"       # From Vercel Tokens page (see section 3)

adsense:
  publisher_id: "ca-pub-1234567890"     # From AdSense (see section 4)
  enabled: true                         # Set to false if not yet approved

analytics:
  google_analytics_id: "G-XXXXXXXXXX"   # From Google Analytics (see section 5)
```

### Quick Reference: Where to Find Each Value

| config.yaml field | Where to find it | Format | Example |
|-------------------|-----------------|--------|---------|
| `domain.name` | [NameSilo Domain Manager](https://www.namesilo.com/account/domain-manager) | `example.com` (no https://) | `mysite.com` |
| `domain.namesilo_api_key` | [NameSilo API Manager](https://www.namesilo.com/account/api-manager) → Generate | ~20-30 alphanumeric chars | `a1b2c3d4e5f6...` |
| `vercel.token` | [Vercel Tokens](https://vercel.com/account/tokens) → Create | ~24+ chars | `pZGwkE1J...` |
| `adsense.publisher_id` | [AdSense](https://adsense.google.com/) → URL bar or Settings → Account Info | `ca-pub-` + 16 digits | `ca-pub-5531531271065052` |
| `analytics.google_analytics_id` | [GA](https://analytics.google.com/) → New: click "Start measuring" → create; Existing: Admin → Data Streams | `G-` + 10 chars | `G-A1B2C3D4E5` |
| `analytics.google_search_console_verification` | [Search Console](https://search.google.com/search-console) → Add property → HTML tag | ~43 chars | `AbCdEf123...` |

## Step 5: Validate

Run setup again to verify all credentials:

```bash
./scripts/setup.sh
```

You should see green checkmarks (✓) for all items. If any show a red cross (✗):

| Error | How to fix |
|-------|-----------|
| ✗ adsense.publisher_id not set | Follow [section 4](#4-google-adsense-publisher-id) above, or set `enabled: false` to skip |
| ✗ Vercel token invalid | Go to [vercel.com/account/tokens](https://vercel.com/account/tokens), delete the old token, create a new one |
| ✗ NameSilo API key error | Check that the key is correct at [API Manager](https://www.namesilo.com/account/api-manager) and your domain is in your account |
| ✗ Any value still shows "XXXX" | You forgot to replace a placeholder — open config.yaml and fill in the real value |

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

**How to check if DNS is ready:**
- Visit [https://dnschecker.org/](https://dnschecker.org/) → enter `my-blog.yourdomain.com` → select "CNAME" → click "Search"
- If results show `cname.vercel-dns.com`, DNS is working
- If results show nothing or errors, wait a few more hours and check again

## Step 9: Apply for AdSense

> AdSense requires your site to have real content and be at least 1-2 weeks old.

1. Deploy at least 15 pages of original content
2. Make sure privacy policy and about pages exist
3. Wait 1-2 weeks for Google to index your site
4. Apply at [adsense.google.com](https://adsense.google.com/)
5. Once approved, update `adsense.publisher_id` in config.yaml and set `enabled: true`
6. Redeploy your sites — ads will automatically appear

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
2. Delete the old token
3. Create a new token: Name = anything, Scope = **"Full Account"**, Expiration = your choice
4. Copy the new token immediately (it is only shown once)
5. Update `config.yaml` with the new token

### "NameSilo API key not working"

1. Go to [NameSilo API Manager](https://www.namesilo.com/account/api-manager)
2. Check that the API key is still listed and active
3. Verify the domain is in your NameSilo account at [Domain Manager](https://www.namesilo.com/account/domain-manager)
4. If the key does not work, generate a new one and update config.yaml

### Build fails with Hugo

```bash
# Check for errors
hugo -s sites/my-blog --verbose

# Common fix: clean cache
rm -rf sites/my-blog/resources
hugo -s sites/my-blog --gc --minify
```

### "I don't have an AdSense account yet"

You can set up everything else first:
1. In `config.yaml`, keep `publisher_id` as the placeholder value
2. Set `adsense.enabled: false`
3. Deploy your sites, add content, wait 1-2 weeks
4. Apply for AdSense (see [Content Strategy](content-strategy.md))
5. Once approved, update config.yaml with your real publisher ID and set `enabled: true`
6. Redeploy all sites: `./scripts/deploy-all.sh`

### DNS not working after 48 hours

1. Check propagation status at [https://dnschecker.org/](https://dnschecker.org/)
2. Enter `your-site.yourdomain.com`, select record type "CNAME", and search
3. If no results: verify the CNAME record exists in [NameSilo Domain Manager](https://www.namesilo.com/account/domain-manager) → click your domain → DNS Records
4. If the record exists but DNS still fails: the record might be pointing to the wrong value. It should point to `cname.vercel-dns.com`
5. If all looks correct, wait a bit more — some DNS providers take longer than 48 hours in rare cases

### "I lost my Vercel token"

Vercel tokens cannot be retrieved after creation. Simply create a new one:
1. Go to [vercel.com/account/tokens](https://vercel.com/account/tokens)
2. Click **"Create"** to make a new token
3. Update config.yaml with the new token
4. (Optional) Delete the old token from the Vercel page if it is still listed

### config.yaml format errors

YAML format is sensitive to spacing:
- Use spaces for indentation, **never** tabs
- A colon must be followed by a space: `key: value` (not `key:value`)
- Wrap values in quotes if they contain special characters

```yaml
# Correct
domain:
  name: "mysite.com"

# Wrong (no space after colon)
domain:
  name:"mysite.com"

# Wrong (tab indentation — invisible but breaks the file)
domain:
	name: "mysite.com"
```

## Next Steps

- Create more sites: see [Adding a New Site](adding-new-site.md)
- Find projects to fork: see [Fork Guide](fork-guide.md)
- Get AdSense approved: see [Content Strategy](content-strategy.md)
- Set up automation: see [n8n/README.md](../n8n/README.md)
