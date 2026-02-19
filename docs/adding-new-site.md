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
./scripts/check-repo.sh https://github.com/user/cool-tool
```

This checks:
- License (must be MIT / Apache / BSD)
- No backend code (no server.js, app.py, etc.)
- No database dependencies
- No server-side frameworks in package.json
- Has index.html

Score 70+ with no critical issues = ready to fork.

### 3. Fork and Adapt

```bash
./scripts/fork-site.sh https://github.com/user/cool-tool cool-tool "Cool Tool" "A useful tool"
```

What happens:
1. Runs `check-repo.sh` (aborts if incompatible)
2. Clones the repo to `sites/cool-tool/`
3. Removes `.git` directory
4. Injects AdSense Auto-Ads into all HTML files
5. Injects Google Analytics
6. Adds SEO meta tags (description, Open Graph)
7. Copies privacy policy and about pages from `_shared/`
8. Creates `ads.txt`
9. Creates `site.yaml` with `type: static`
10. Adds attribution notice to README

### 4. Review and Customize

```bash
# Preview
open sites/cool-tool/index.html

# Check the injected code looks right
grep "adsbygoogle" sites/cool-tool/index.html
```

You may want to:
- Update the title and description
- Add a link to privacy policy in the navigation
- Customize colors or branding
- Add more SEO meta tags

### 5. Deploy

```bash
./scripts/deploy.sh cool-tool
```

## After Deployment

### Set Up DNS

```bash
./scripts/dns-setup.sh <site-name>
```

### Add Monitoring

If you have UptimeRobot configured, the monitoring dashboard will pick up the new site automatically next time you run:

```bash
./scripts/generate-dashboard.sh
```

### Submit to Google

1. Go to [Google Search Console](https://search.google.com/search-console)
2. Add property: `https://<site-name>.yourdomain.com`
3. Verify via DNS (TXT record) or HTML file
4. Submit the sitemap: `https://<site-name>.yourdomain.com/sitemap.xml`

### Check Performance

```bash
./scripts/lighthouse-check.sh <site-name>
```

Target scores: Performance 90+, SEO 95+, Accessibility 85+, Best Practices 90+.

## Managing Sites

### List All Sites

```bash
ls -la sites/ | grep -v _template | grep -v _shared
```

### Remove a Site

```bash
rm -rf sites/<site-name>
# Also remove from Vercel:
npx vercel rm <site-name> --token YOUR_TOKEN --yes
```

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
nano sites/cool-tool/index.html

# Deploy
./scripts/deploy.sh cool-tool
```
