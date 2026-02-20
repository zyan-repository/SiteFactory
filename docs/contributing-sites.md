**English** | [中文](zh/contributing-sites.md)

# Contributing a Site to SiteFactory

Want to add a useful tool site to SiteFactory? This guide explains how.

## Quick Overview

```
Find project → check-repo.sh → fork-site.sh → verify → PR
```

**Target**: < 10 minutes from finding a project to submitting a PR.

## Requirements

Before your site can be accepted:

| Requirement | Detail |
|------------|--------|
| License | MIT, Apache 2.0, or BSD only |
| Type | Pure frontend (HTML + CSS + JS) |
| No backend | No server.js, no database, no auth |
| Works offline | Open `index.html` in browser and it works |
| check-repo.sh score | 70+ (COMPATIBLE) |

## Step-by-Step

### 1. Find a Project

See the [Fork Guide](fork-guide.md) for search strategies and high-value categories.

**Best categories for contribution:**

| Category | Examples | SEO Value |
|----------|----------|-----------|
| Calculators | BMI, loan, mortgage, tip | High — precise search intent |
| Converters | Unit, currency, timezone | High — repeat visitors |
| Generators | Password, QR code, UUID | High — strong keywords |
| Text Tools | Word counter, markdown preview | Medium — dev audience |
| Reference | Periodic table, ASCII table | Medium — long sessions |

### 2. Evaluate

```bash
./scripts/check-repo.sh <github-url>
```

Only proceed if the verdict is **COMPATIBLE** (score 70+).

### 3. Fork and Adapt

```bash
./scripts/fork-site.sh <github-url> <site-name> "<Title>" "<Description>"
```

**Naming rules:**
- `site-name` must be lowercase with hyphens: `bmi-calculator`, `color-picker`
- `Title` should be SEO-friendly: include the primary keyword
- `Description` should be 150-160 characters with a call-to-action

### 4. Verify Locally

Open the site in your browser:

```bash
open sites/<site-name>/index.html
```

**Checklist:**

- [ ] Page loads and functions correctly
- [ ] No broken styles or missing assets (check browser console for 404s)
- [ ] AdSense script present in `<head>` (view source, search for "adsbygoogle")
- [ ] Analytics script present in `<head>` (search for "googletagmanager")
- [ ] Privacy policy link visible at bottom of page
- [ ] `site.yaml` exists with correct metadata
- [ ] `ads.txt` exists
- [ ] `privacy-policy.html` and `about.html` exist
- [ ] Mobile layout works (resize browser to 375px width)

### 5. Post-Fork Customization

Some things the script can't do automatically:

- **Update `<title>`** — Make it SEO-friendly with primary keyword
- **Remove original project links** — CNAME files, original domain references
- **Fix canonical URL** — Should point to your deployed domain
- **Test all features** — Make sure buttons, inputs, and outputs all work

If the script injection didn't work perfectly (e.g., non-standard HTML structure), you can manually edit the HTML or use a code assistant to fix it.

### 6. Update the Site Registry

Add your site to [SITES.md](../SITES.md) (in the project root):

```markdown
| my-tool | static | [user/repo](https://github.com/user/repo) | MIT | Brief description |
```

This is **required** — PRs without a SITES.md update will be rejected.

### 7. Submit a PR

**One site per PR.** Include the entire `sites/<site-name>/` directory and the SITES.md update.

PR title format:
```
feat(sites): add <site-name> - <brief description>
```

Example:
```
feat(sites): add bmi-calculator - BMI calculator forked from user/repo
```

PR body should include:
- Source GitHub URL
- License type
- check-repo.sh score
- Screenshot of the working site (optional but helpful)

## What NOT to Submit

| Type | Reason |
|------|--------|
| GPL/AGPL projects | License incompatible with commercial use |
| Projects requiring API keys | High maintenance, can break anytime |
| SPA frameworks (React, Vue, Angular) | Need build step, injection doesn't work |
| Projects with login/auth | Require backend server |
| Duplicate categories | Don't submit a 3rd BMI calculator if 2 exist |
| Abandoned projects | Last commit > 2 years ago, likely has issues |

## site.yaml Reference

Every fork site has a `site.yaml` created automatically:

```yaml
type: static          # Always "static" for fork sites
name: bmi-calculator  # Directory name, kebab-case
title: "BMI Calculator"
description: "Calculate your BMI instantly"
source: https://github.com/user/repo   # Original repo URL
license: MIT          # MIT, Apache-2.0, or BSD
language: en          # Primary language
created: 2026-02-19   # Fork date
```

## Troubleshooting

### Script injection failed

If `fork-site.sh` errors or the injected code doesn't appear:

1. Check if the HTML files have standard `</head>` and `</body>` tags
2. Single-page apps with JS-rendered content won't work with injection
3. You can manually add the AdSense/Analytics snippets from `sites/_shared/`

### Submodule dependencies missing

If the forked project uses git submodules and assets are missing:

The fork script uses `--recurse-submodules` to clone submodule dependencies. If files are still missing, check if the project uses a build step to compile assets (e.g., SCSS to CSS). These projects may need manual setup.

### Site looks broken

Check the browser console (F12) for errors:
- 404 errors = missing files, check file paths
- CORS errors = the site calls external APIs that block cross-origin requests
- JS errors = may indicate missing dependencies or build step required
