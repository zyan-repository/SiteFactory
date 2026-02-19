**English** | [中文](zh/adding-new-site.md)

# Adding a New Site

SiteFactory supports two types of sites. Choose based on your goal:

| Goal | Type | Command | Build? |
|------|------|---------|--------|
| Blog / articles / SEO content | Hugo | `new-site.sh` | Yes |
| Tool / utility / forked project | Static | `fork-site.sh` | No |

## Path A: Hugo Content Site

### Create

```bash
./scripts/new-site.sh <site-name> "<Site Title>" "<Description>" [language]
```

Example:

```bash
./scripts/new-site.sh cooking-tips "Cooking Tips Daily" "Easy recipes and cooking hacks" en
```

What happens:
1. Copies `sites/_template/` to `sites/cooking-tips/`
2. Replaces title, description, domain, AdSense ID, Analytics ID
3. Creates `site.yaml` with `type: hugo`
4. Verifies the site builds successfully

### Preview Locally

```bash
hugo server -s sites/cooking-tips
# Open http://localhost:1313
```

### Add Content

Create new posts:

```bash
hugo new -s sites/cooking-tips posts/my-first-recipe.md
```

Or manually create files in `sites/cooking-tips/content/posts/`:

```markdown
---
title: "10 Easy Pasta Recipes for Beginners"
date: 2026-02-19
description: "Simple pasta recipes anyone can make at home in under 30 minutes."
tags: ["pasta", "beginner", "quick"]
---

Your content here. Aim for 800+ words for SEO.
```

### Content Requirements (for AdSense Approval)

- Minimum 15 unique pages/posts
- Each post at least 300 words (800+ recommended)
- Original content (not copied from other sites)
- Privacy policy page (included in template)
- About page (included in template)
- Contact page (included in template)

### Deploy

```bash
./scripts/deploy.sh cooking-tips
```

## Path B: Fork a GitHub Project

### 1. Find a Project

Search GitHub for useful tools:

```
site:github.com calculator html css
site:github.com converter tool html
site:github.com weather app html css javascript
```

Good categories: calculators, converters, generators, lookup tools, reference pages.

See [Fork Guide](fork-guide.md) for detailed search strategies and recommended projects.

### 2. Check Compatibility

```bash
./scripts/check-repo.sh https://github.com/evgeni/qifi
```

This checks:
- License (must be MIT / Apache / BSD)
- No backend code (no server.js, app.py, etc.)
- No database dependencies
- No server-side frameworks in package.json
- Has index.html

**Understanding the result:**
- Score 70+ with no red flags → **COMPATIBLE** — ready to fork
- Score 40-69 or 1 yellow warning → **NEEDS REVIEW** — see [Fork Guide](fork-guide.md) manual checklist
- Score <40 or red flags → **INCOMPATIBLE** — skip this project

**What are "red flags" (critical issues)?**
- License is GPL, AGPL, or missing — can't use commercially
- Backend files detected (server.js, app.py) — needs a server to run
- Database dependency — needs a database we can't provide

### 3. Fork and Adapt

```bash
./scripts/fork-site.sh https://github.com/evgeni/qifi wifi-qr "WiFi QR Generator" "Generate QR codes to share WiFi"
```

What happens:
1. Runs `check-repo.sh` (aborts if incompatible)
2. Clones the repo to `sites/wifi-qr/`
3. Removes `.git` directory
4. Injects AdSense Auto-Ads into all HTML files
5. Injects Google Analytics
6. Adds SEO meta tags (description, Open Graph)
7. Copies privacy policy and about pages from `_shared/`
8. Creates `ads.txt`
9. Creates `site.yaml` with `type: static`
10. Adds attribution notice to README

### 4. Review and Customize

**Preview the site:**
```bash
open sites/wifi-qr/index.html
```

**Verify ad injection worked:**
```bash
grep "adsbygoogle" sites/wifi-qr/index.html
# If this prints a line containing "adsbygoogle", injection succeeded.
# If no output, re-run fork-site.sh or check the error log.
```

**Update the title** (in `sites/wifi-qr/index.html`):
1. Open the file in any text editor (VS Code, nano, TextEdit, etc.)
2. Find the `<title>` tag (near the top of the file, inside `<head>`)
3. Change the text between `<title>` and `</title>` to your desired title
4. Also find `<meta property="og:title"` and update the `content` value to match

**Update the description** (same file):
1. Find `<meta name="description" content="...">`
2. Change the `content` value to your description (150-160 characters recommended)
3. Also update `<meta property="og:description" content="...">` to match

**Add navigation to privacy policy** (optional but recommended):
- The fork script adds `privacy-policy.html` and `about.html` to the site directory
- Find the navigation section (usually `<nav>` or a `<ul>` with links) in `index.html`
- Add links: `<a href="privacy-policy.html">Privacy Policy</a>` and `<a href="about.html">About</a>`

### 5. Deploy

```bash
./scripts/deploy.sh wifi-qr
```

## After Deployment

### Set Up DNS

```bash
./scripts/dns-setup.sh <site-name>
```

This creates a CNAME record pointing `<site-name>.yourdomain.com` to `cname.vercel-dns.com`.

**How to check if DNS is working:**
1. Visit [https://dnschecker.org/](https://dnschecker.org/)
2. Enter `<site-name>.yourdomain.com`, select record type "CNAME", click search
3. If results show `cname.vercel-dns.com` → DNS is working
4. If no results → wait a few hours and check again (DNS can take up to 48 hours)

### Submit to Google Search Console

1. Go to [Google Search Console](https://search.google.com/search-console)
2. Click **"Add property"** (in the top-left dropdown)
3. Choose **"URL prefix"** (the right-hand option)
4. Enter your site URL: `https://<site-name>.yourdomain.com`
5. Click **"Continue"**
6. For verification, choose **"DNS record"** method:
   - Google shows you a TXT record value (a long string starting with `google-site-verification=`)
   - Go to [NameSilo Domain Manager](https://www.namesilo.com/account/domain-manager) → click your domain → DNS Records
   - Add a TXT record: Host = leave blank (or `@`), Value = paste the Google string, TTL = `3600`
   - Go back to Search Console and click **"Verify"**
   - If verification fails, wait 15-30 minutes for DNS to propagate, then try again
7. Once verified, click **"Sitemaps"** in the left sidebar
8. Enter your sitemap URL: `https://<site-name>.yourdomain.com/sitemap.xml`
9. Click **"Submit"**
10. Google will start crawling your site within a few days. Check indexing progress under **"Pages"** in the left sidebar.

### Add Monitoring

If you have UptimeRobot configured, the monitoring dashboard will pick up the new site automatically next time you run:

```bash
./scripts/generate-dashboard.sh
```

### Check Performance

```bash
./scripts/lighthouse-check.sh <site-name>
```

Target scores: Performance 90+, SEO 95+, Accessibility 85+, Best Practices 90+.

**What these scores mean:**
- **Performance (90+):** How fast your page loads. Below 90 usually means images are too large or there's too much JavaScript. Fix: compress images, remove unused scripts.
- **SEO (95+):** Whether search engines can properly read your site. Below 95 usually means missing meta tags or heading issues. Fix: check that every page has a `<title>`, `<meta description>`, and one `<h1>`.
- **Accessibility (85+):** Whether the site is usable by people with disabilities (screen readers, etc.). Below 85 means missing image alt text or poor color contrast. Fix: add `alt` attributes to all `<img>` tags.
- **Best Practices (90+):** General web development quality. Below 90 means outdated APIs or security issues. Fix: check the specific warnings in the Lighthouse output.

If any score is below target, the Lighthouse output lists specific issues and suggested fixes.

## Managing Sites

### List All Sites

```bash
ls -la sites/ | grep -v _template | grep -v _shared
```

### Remove a Site

```bash
# Remove local files
rm -rf sites/<site-name>

# Also remove from Vercel (if already deployed):
npx vercel rm <site-name> --token YOUR_TOKEN --yes
```

> **Note:** Removing from Vercel stops the site from being accessible online. The DNS record will still exist but point to nothing — you can leave it or clean it up in NameSilo.

### Update a Site

For Hugo sites, edit content and redeploy:

```bash
# Edit content
nano sites/my-blog/content/posts/new-post.md

# Rebuild and deploy
./scripts/deploy.sh my-blog
```

For fork sites, edit files directly:

```bash
# Make changes
nano sites/wifi-qr/index.html

# Deploy
./scripts/deploy.sh wifi-qr
```
