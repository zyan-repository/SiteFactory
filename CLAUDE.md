# SiteFactory Development Guide

Static site mass production system for AdSense monetization.

**Tech stack**: Hugo | Vercel | NameSilo

**Philosophy**: Ship fast, monetize faster. Good enough beats perfect.

## Engineering Philosophy

| Principle | Description |
|-----------|-------------|
| **Speed over Perfection** | A "good enough" site that earns money beats a "perfect" site still in development |
| **Cost is King** | Every decision starts with: is the free tier sufficient? |
| **Scale by Multiplication** | Don't build one big site. Build 100 small sites. Each simple, volume wins |
| **Automate Everything** | Manual operation = can't scale. Everything goes through scripts and GitHub Actions |
| **SEO is the Product** | The site itself doesn't matter. Search engine ranking is what matters |
| **Compliance First** | AdSense ban = zero revenue. Compliance is the bottom line, not optional |
| **Minimum Effort** | Minimize human attention and cognitive load. Automate everything possible. One command should do the job of ten |
| **Copy before Create** | Find existing open-source sites to fork/adapt. Check licenses to avoid legal risk |

### Decision Checklist

| Phase | Question |
|-------|----------|
| **Before building** | Is there an existing site/template to fork? |
| **Designing** | What's the minimum viable version? |
| **Building** | Will this pass Lighthouse 90+? Is AdSense compliant? |
| **Before deploy** | SEO checklist passed? Privacy policy included? |
| **After deploy** | Submitted to Google Search Console? AdSense applied? |

## "Copy Before Create" Methodology

The core philosophy: **don't build what you can fork**. GitHub has thousands of useful tools (calculators, converters, generators) that can be adapted for AdSense monetization in minutes.

### Dual-Track Architecture

| Type | Source | Build | Deploy | Use Case |
|------|--------|-------|--------|----------|
| **Hugo** | `themes/sitefactory/` | `hugo --minify` | `public/` dir | Blogs, articles, SEO content |
| **Static** | GitHub fork | None | Entire dir | Tools, utilities, widgets |

Every site has a `site.yaml` that determines how it's built and deployed:

```yaml
# Hugo content site
type: hugo
name: tech-blog
title: "Tech Blog"
description: "Daily tips for developers"
source: template
language: en
created: "2026-01-15"
# root_domain: true        # Optional: set to serve on root domain

# Forked tool site
type: static
name: bmi-calculator
title: "BMI Calculator"
description: "Calculate your Body Mass Index"
source: https://github.com/user/bmi-calc
license: MIT
language: en
created: "2026-01-15"
```

### GitHub Project Evaluation

Before forking, run `./scripts/check-repo.sh <url>`. A project MUST pass:

```
=== MUST PASS (any failure = skip) ===
☐ License: MIT / Apache 2.0 / BSD (allows commercial use + modification)
  ❌ Reject: GPL / AGPL / SSPL / no license / custom non-commercial
☐ Pure frontend: HTML + CSS + JS only, no server-side code
☐ No database: No MySQL / PostgreSQL / MongoDB / Firebase
☐ No auth: No login / registration
☐ Has index.html: Can be served as static files

=== QUICK EXCLUSION SIGNALS ===
- server.js / app.py / main.go / docker-compose.yml → has backend
- express / koa / fastify / next / nuxt / nest / hapi / restify in package.json → server framework
- requirements.txt / Gemfile / go.mod → non-frontend deps
- DATABASE_URL / REDIS_URL in .env → database dependency
- fetch('/api/...') in code → internal API calls
```

### Fork Adaptation Pipeline

`fork-site.sh` executes: compatibility check → clone → strip .git → inject AdSense + GA + SEO → add privacy/about pages → generate OG image → create ads.txt + site.yaml → add attribution → register in `data/sites.yaml`.

### Hugo Theme System

All Hugo sites share a centralized theme at `themes/sitefactory/`. Template updates automatically propagate to all sites on next build.

| Concept | Mechanism |
|---------|-----------|
| **Theme location** | `themes/sitefactory/` (shared by all Hugo sites) |
| **Site config** | Each site's `hugo.toml` has `theme = "sitefactory"` |
| **Site override** | Place files in `sites/{name}/layouts/` to override theme defaults |
| **CSS strategy** | Theme: `assets/css/main.css` (base) + Site: `assets/css/site.css` (optional override) |
| **Cross-site nav** | Driven by `themes/sitefactory/data/sites.yaml` (auto-rendered in footer) |
| **OG image** | Auto-generated per site via `scripts/lib/og-image.sh` (ImageMagick with fallback) |
| **New site** | `new-site.sh` copies only content/static/hugo.toml (NOT layouts/assets/i18n) |
| **Theme changes** | Push to `themes/` triggers `deploy.yml` to rebuild all Hugo sites |

### High-Value Fork Targets

| Category | Examples | Why |
|----------|----------|-----|
| Calculators | BMI, loan, mortgage, tip | Precise search intent |
| Converters | Unit, currency, timezone | Repeat visitors |
| Generators | Password, QR code, UUID | Strong SEO keywords |
| Data lookup | Weather, IP, exchange rates | Daily traffic |
| Reference | Periodic table, shortcuts | Long session time |

## Project Structure

```
SiteFactory/
├── config.yaml              # Credentials (git-ignored)
├── content-plans/           # AI content schedules & topic lists
├── themes/
│   └── sitefactory/         # Shared Hugo theme (all Hugo sites inherit)
│       ├── layouts/         # Templates (baseof, single, list, partials)
│       ├── assets/css/      # Stylesheets (main.css)
│       ├── i18n/            # UI translations (en, zh, ja)
│       ├── static/          # Shared static files (og-default.png)
│       └── data/sites.yaml  # Cross-site registry (drives footer nav)
├── sites/
│   ├── _template/           # Hugo site scaffold (hugo.toml + content)
│   ├── _shared/             # Shared pages for fork sites
│   │   ├── privacy-policy.{en,zh,ja}.html
│   │   ├── about.{en,zh,ja}.html
│   │   ├── adsense-snippet.html
│   │   ├── analytics-snippet.html
│   │   └── ads.txt
│   └── {site-name}/         # Each site (Hugo or static)
│       ├── site.yaml        # Metadata (type, source, license)
│       └── ...
├── scripts/
│   ├── setup.sh             # One-time setup
│   ├── launch-site.sh       # One-click: create + deploy + DNS + verify
│   ├── new-site.sh          # Create Hugo site from template
│   ├── fork-site.sh         # Fork & adapt GitHub project
│   ├── check-repo.sh        # Evaluate GitHub project compatibility
│   ├── update-sites.sh      # Re-apply injections to all fork sites
│   ├── deploy.sh            # Deploy (auto-detects hugo/static, --verify flag)
│   ├── deploy-all.sh        # Deploy all sites
│   ├── build-all.sh         # Build all Hugo sites
│   ├── dns-setup.sh         # NameSilo API CNAME setup (--verify flag)
│   ├── swap-root.sh         # Swap which site occupies the root domain
│   ├── generate-content.sh  # AI-generate SEO articles (multi-provider)
│   ├── generate-content-plan.sh  # AI-generate content plan for a site
│   ├── generate-seed-content.sh  # AI-generate initial seed articles
│   ├── generate-dashboard.sh # Monitoring dashboard
│   ├── lighthouse-check.sh  # Lighthouse audit
│   ├── pre-commit-hook.sh   # ShellCheck on staged .sh files
│   └── lib/
│       ├── config.sh        # Parse config.yaml → env vars
│       ├── logging.sh       # Colored log helpers
│       ├── inject.sh        # HTML injection (AdSense/GA/SEO)
│       ├── llm.sh           # Unified LLM API wrapper (6+ providers)
│       ├── og-image.sh      # OG image generation (ImageMagick)
│       ├── platform.sh      # Cross-platform utilities
│       ├── verify.sh        # DNS polling + HTTP health check
│       └── vercel.sh        # Vercel project linking helpers
├── dashboard/               # Monitoring dashboard
│   ├── template.html        # Dashboard template
│   └── data/                # Metrics JSON (git-ignored)
├── docs/                    # Documentation
└── .github/workflows/       # CI
```

## Core Rules

1. **Static first** - No server-side logic. Everything pre-rendered at build time. No database
2. **Dual-track sites** - Hugo sites for content, static forks for tools. Both types managed uniformly via `site.yaml`
3. **Config over code** - All credentials in `config.yaml`. Site differences in `hugo.toml` or `site.yaml`
4. **Injection pattern** - Fork sites get AdSense/GA/SEO via `lib/inject.sh`. Hugo sites get them via partials
5. **Naming** - Directories `kebab-case`, templates `snake_case.html`, content `slug-format.md`
6. **Comments in English** - All code comments in English for open-source readability
7. **No secrets in code** - AdSense publisher ID, API keys via `config.yaml` (git-ignored)

## SEO Requirements (Non-Negotiable)

Every page MUST have:

- [ ] Unique `<title>` tag (50-60 chars, primary keyword first)
- [ ] Unique `<meta name="description">` (150-160 chars, includes CTA)
- [ ] Proper heading hierarchy: single H1, logical H2-H4
- [ ] `<html lang="xx">` attribute matching content language
- [ ] Canonical URL: `<link rel="canonical" href="...">`
- [ ] hreflang tags for all language variants
- [ ] Open Graph tags (og:title, og:description, og:image, og:url)
- [ ] Structured data (JSON-LD) for relevant schema (Article, FAQ, Breadcrumb)
- [ ] Image alt text on every `<img>` tag
- [ ] Clean URL structure (no trailing slashes, no query params)

Lighthouse targets:

| Metric | Minimum Score |
|--------|--------------|
| Performance | >= 90 |
| SEO | >= 95 |
| Accessibility | >= 85 |
| Best Practices | >= 90 |

Sitemap & indexing:

- Auto-generated `sitemap.xml` with lastmod dates
- `robots.txt` allowing all crawlers on content, blocking admin paths
- Submit sitemap to Google Search Console on every deploy

## AdSense Compliance

**VIOLATIONS = ACCOUNT BAN = ALL SITES LOSE REVENUE. These rules are absolute.**

| Rule | Detail |
|------|--------|
| **No click encouragement** | Never use "click here", "support us", arrows pointing to ads |
| **No deceptive layout** | Ads must be clearly distinguishable from content |
| **No ad overload** | Content must exceed ad space. With Auto-Ads (default), Google manages placement automatically. If placing ads manually, max 3 units per page |
| **No thin content** | Every page needs 300+ words of original, useful content |
| **No auto-refresh** | Pages must NOT auto-reload to inflate impressions |
| **No pop-up ads** | No interstitials that block content |
| **No traffic manipulation** | No paid traffic, click farms, or traffic exchange |
| **Ad label required** | Use "Advertisement" or "Sponsored" label above ad units |
| **Mobile friendly** | Ads must not break mobile layout or overlap content |
| **Privacy policy** | Every site MUST have a privacy policy page |

Ad placement: SiteFactory uses **Auto-Ads** by default — Google automatically places ads where they perform best. If placing ads manually instead, use max 3 units:
1. Top of article (below H1, above first paragraph)
2. Mid-article (after 3rd or 4th paragraph)
3. End of article (before related posts)

## AdSense Approval: Lessons Learned

Based on 3 rejection cycles for search123.top. These patterns are **confirmed triggers** for AdSense rejection.

### Red Flags That Cause Rejection

| Signal | Why Google Rejects | Prevention |
|--------|-------------------|------------|
| Ads on non-content pages | "Showing ads on screens without publisher content" | Use whitelist: ads only on `.IsHome` + `.IsPage` (not `.Params.noAds`) |
| Language mismatch | Chinese pages on `lang="en"` site = policy violation | All content must match `languageCode` in hugo.toml |
| Rapid content burst | 20 articles in 48h = "content farm" signal | Spread dates across 4-8 weeks minimum |
| No author identity | Missing E-E-A-T signals | Every article needs author byline + site needs About page with author bio |
| Misleading homepage | "Search portal" claims when it's a blog | Homepage must accurately describe the site's actual purpose |
| Thin compliance pages | <100 word privacy/about | Privacy >600 words, About >300 words, specific to site |
| Pure text articles | No images, no visual elements | Include TOC, reading time, styled code blocks, data tables |
| Empty og:image | Signals low-effort site | Every site must have at least a default branded OG image |
| Ads on utility pages | Contact, Terms, Privacy with ads | Set `noAds: true` in frontmatter for all non-content pages |

### Pre-Approval Checklist (Run Before Applying)

- [ ] 15+ articles, each 800+ words with unique topics
- [ ] Publication dates spread across 4+ weeks (not bulk-published)
- [ ] Author name on every article + detailed About page
- [ ] Homepage 300+ words with honest site description
- [ ] Privacy Policy 600+ words (accurate, mentions GA + AdSense)
- [ ] Terms of Service page present
- [ ] Contact page with real email
- [ ] No ads on: 404, taxonomy, terms, privacy, about, contact pages
- [ ] All text in `<html lang>` declared language (no language mixing)
- [ ] og:image set (at least site default)
- [ ] Lighthouse SEO score >= 95
- [ ] Mobile responsive at 375px width
- [ ] No "click here" or arrows pointing at ad areas

## I18n Architecture

Hugo multilingual mode with directory-based content:

```toml
# hugo.toml example
defaultContentLanguage = "en"
[languages]
  [languages.en]
    weight = 1
    languageName = "English"
  [languages.zh]
    weight = 2
    languageName = "中文"
  [languages.ja]
    weight = 3
    languageName = "日本語"
```

Rules:
- Content translations: `content/en/`, `content/zh/`, `content/ja/`
- UI strings: `i18n/en.toml`, `i18n/zh.toml`
- Every page must have hreflang alternates for all available translations
- `x-default` points to English version
- URL structure: `/{lang}/page/` (language prefix always present)
- Do NOT mix languages on a single page

### Documentation Bilingual Requirement

**Every project documentation file (`.md`) must have both English and Chinese versions.** This is non-negotiable.

| Location | English | Chinese |
|----------|---------|---------|
| Root-level files | `FILE.md` | `FILE.zh.md` |
| `docs/` directory | `docs/file.md` | `docs/zh/file.md` |

Format rules:
- English files start with: `**English** \| [中文](path-to-chinese-version)`
- Chinese files start with: `[English](path-to-english-version) \| **中文**`
- When creating or modifying any `.md` file, always create/update both language versions
- README: `README.md` (English) ↔ `README.zh.md` (Chinese)

**Checklist before committing documentation changes:**
- [ ] Both English and Chinese versions exist
- [ ] Language toggle links at the top of each file are correct
- [ ] Both README files' documentation tables include the new entry with links to both versions

## Deployment

### Architecture

- One Vercel project per site (or monorepo with path-based routing)
- Main domain bought via NameSilo (e.g., `sitefactory.dev`)
- Sites accessible at `{site-name}.sitefactory.dev`
- DNS: NameSilo nameservers or Vercel DNS for wildcard SSL

### Root Domain Requirement

**The apex/root domain MUST have a site deployed to it.** Google AdSense verifies by visiting `https://yourdomain.com/`. An empty root domain = failed verification = no ad revenue.

- Exactly ONE site occupies the root domain at a time (tracked in `root-domain.yaml`)
- That site is accessible at both `https://domain.com` and `https://site-name.domain.com`
- Use `./scripts/swap-root.sh <site-name>` to change which site is on the root domain
- Set `root_domain: true` in a site's `site.yaml` for auto-detection by deploy scripts
- Root domain uses DNS A record (`76.76.21.21`), subdomains use CNAME
- See [Root Domain Management](docs/root-domain.md) for full details

### Cost Budget

| Resource | Plan | Limit | Cost |
|----------|------|-------|------|
| Hosting | Vercel Hobby | 100 GB bandwidth/mo | Free |
| Domain | NameSilo | 1 main domain | ~$9/year |
| SSL | Vercel auto-provision | Wildcard | Free |
| CDN | Vercel Edge Network | Included | Free |
| CI/CD | Vercel Git Integration | Auto-deploy on push | Free |
| Monitoring | GA + GSC + UptimeRobot | Free tiers | Free |

> Vercel Hobby plan allows AdSense — ads are explicitly excluded from their "commercial use" definition.

When approaching bandwidth limit: optimize images (WebP, lazy loading), minimize bundles, or split high-traffic sites to separate projects.

## Automation

Automation is handled at two levels:

1. **Bash scripts** — Core execution layer (`launch-site.sh`, `deploy.sh`, etc.)
2. **GitHub Actions** — Auto-deploy on push, scheduled health checks, AI content generation

### GitHub Actions Workflows

| Workflow | File | Trigger | What it does |
|----------|------|---------|-------------|
| Build Check | `build-check.yml` | Push/PR to main | ShellCheck + Hugo build + file verification |
| Auto Deploy | `deploy.yml` | Push to `sites/` or `themes/`, manual dispatch | Deploys changed sites to Vercel + DNS. Theme changes trigger all Hugo site rebuilds |
| Health Check | `health-check.yml` | Every 6 hours, manual | HTTP check all sites, warn if down |
| Content Gen | `content-generation.yml` | Manual dispatch | AI article generation → commit → push → auto-deploy |
| Scheduled Content | `scheduled-content.yml` | Daily 09:00 UTC, manual | Auto-generate content for sites with content plans |

## Monitoring

### Required Metrics Per Site

- **Google Analytics**: pageviews, bounce rate, session duration, traffic sources
- **Google Search Console**: impressions, clicks, CTR, average position
- **AdSense**: RPM, CPC, CTR, estimated earnings
- **Lighthouse**: performance score trend
- **Uptime**: HTTP status check (UptimeRobot free tier)

### Invalid Traffic Prevention

- Monitor AdSense CTR: normal is 1-3%. Above 5% = investigate immediately
- Check traffic sources: sudden spikes from unknown referrers = suspicious
- Never share direct ad unit URLs
- Use Google Analytics to cross-reference traffic patterns
- Alert thresholds: CTR > 5%, revenue drop > 30%, Lighthouse < 80

## Content Quality Requirements

AI-generated content must pass these quality checks:
- **Varied structure**: Mix listicles, how-tos, comparisons, deep dives. Never 5+ articles with same format
- **Internal linking**: Each article should link to 2-3 existing articles on the same site
- **Personal voice**: Use "I" occasionally, include testing observations
- **Publication cadence**: Weekly schedule via GitHub Actions. Never bulk-publish
- **Content plan auto-refresh**: When pending topics < 3, `scheduled-content.yml` auto-regenerates
- **Tool cross-references**: Articles reference relevant tools from `data/sites.yaml` when topically appropriate

### Automation Levels

| Task | Automation | Human Action |
|------|-----------|-------------|
| Content plan generation | Auto (GitHub Actions) | None |
| Article generation | Auto (daily cron) | None |
| Build & deploy | Auto (push triggers) | None |
| Theme updates | Auto (theme changes trigger all Hugo rebuilds) | None |
| Cross-site navigation | Auto (driven by `data/sites.yaml`) | None |
| DNS setup | Auto (`launch-site.sh`) | None |
| OG image generation | Auto (`og-image.sh` on site creation) | None |
| AdSense application | Manual | Submit once, wait 2-4 weeks |
| Google Search Console | Manual | Submit sitemap once per site |
| Finding fork targets | Manual | Browse GitHub for candidates |

## Adding a New Site

### One-Click (Recommended)

```bash
# Fork tool site — one command does everything (create + deploy + DNS + verify)
./scripts/launch-site.sh fork <github-url> <name> "<title>"

# Hugo content site — same one-click flow
./scripts/launch-site.sh hugo <name> "<title>" "<description>" [language]
```

### Step by Step (Manual Control)

```bash
# Hugo site
./scripts/new-site.sh <name> "<title>" "<description>" [language]
./scripts/deploy.sh <name>
./scripts/dns-setup.sh <name>

# Fork site
./scripts/check-repo.sh <github-url>
./scripts/fork-site.sh <github-url> <name> "<title>"
./scripts/deploy.sh <name>
./scripts/dns-setup.sh <name>
```

### Post-Deploy

1. Submit to Google Search Console
2. Apply for AdSense after 1-2 weeks of indexed content

**Target: < 2 minutes from idea to live, verified site.**

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| Duplicate content across sites | Each site must have unique, original content |
| Missing alt text on images | Every `<img>` must have descriptive alt text |
| Hardcoding AdSense publisher ID | Use Hugo params in `hugo.toml`, read via `.Site.Params` |
| Forgetting hreflang on new language | Template must auto-generate hreflang for all translations |
| Huge unoptimized images | Use Hugo image processing: resize, convert to WebP |
| Inline CSS/JS in templates | Use Hugo asset pipeline: bundle, minify, fingerprint |
| Site without privacy policy | AdSense requires it. Use shared partial, never skip |
| Ignoring Core Web Vitals | Run Lighthouse before every deploy |
| Too many ad units per page | Max 3 per page. Content must dominate |
| No robots.txt or sitemap | Hugo auto-generates both. Verify they exist in output |
| Deploying without mobile check | Test responsive layout at 375px width minimum |
| Using client-side rendering | Everything must be pre-rendered. No SPA patterns |
| Forking without checking license | Verify open-source license allows commercial use + modification |
| Using third-party GitHub Actions for tool installation | Prefer direct download scripts — third-party actions go unmaintained and break when upstream changes download URLs (e.g., `peaceiris/actions-hugo` broke when Hugo changed archive naming in v0.103.0+) |
| Using `hugo-version: 'latest'` in CI | Pin Hugo to a specific version (e.g., `0.156.0`) so builds are reproducible and you control when to upgrade |
| Hugo site Vercel project named "public" | Hugo deploys from `public/` dir, so Vercel names the project "public". `deploy.sh` auto-links correct name via `vercel_link_project`. For legacy projects, run `vercel link --project <site-name> --cwd sites/<name>/public/` |

## Code Quality

### Hugo Templates

```bash
# Verify build succeeds with optimization
hugo --gc --minify

# Serve locally for testing
hugo server --bind 0.0.0.0
```

### Scripts (Bash/Node.js)

```bash
# ShellCheck for bash scripts (MUST pass before push — CI runs this)
shellcheck scripts/*.sh scripts/lib/*.sh

# ESLint for any JS (if applicable)
npx eslint .
```

**ShellCheck rules:**
- CI runs ShellCheck with default severity (info + style + warning + error all fail the build)
- A `.shellcheckrc` in the project root ensures local runs match CI behavior
- Pre-commit hook auto-runs ShellCheck on staged `.sh` files (installed via `scripts/setup.sh`)
- To suppress a legitimate false positive, use inline `# shellcheck disable=SCXXXX` with a comment explaining why

### CI: Hugo Setup

CI installs Hugo via direct download (not third-party actions). When upgrading Hugo:

1. Check the new version's release assets at `https://github.com/gohugoio/hugo/releases`
2. Update `HUGO_VERSION` in **both** `.github/workflows/build-check.yml` and `.github/workflows/deploy.yml` — they must stay in sync
3. Verify archive filenames match (Hugo may change naming conventions between major versions)

Current asset naming convention (Hugo v0.103.0+):
- Linux: `hugo_extended_{version}_linux-amd64.tar.gz`
- macOS: `hugo_extended_{version}_darwin-universal.pkg` (only `.pkg` — no `.tar.gz` for extended macOS builds)

**Do NOT use `peaceiris/actions-hugo`** — it is unmaintained and breaks with Hugo v0.103.0+ due to archive naming changes.

### Pre-deploy Check

```bash
shellcheck scripts/*.sh scripts/lib/*.sh && scripts/build-all.sh && scripts/lighthouse-check.sh
```

## Git Conventions

Format: `<type>(<scope>): <subject>`

| Type | Usage |
|------|-------|
| `feat` | New site, new template, new feature |
| `content` | New or updated content pages |
| `fix` | Bug fixes in templates or config |
| `seo` | SEO improvements |
| `perf` | Performance optimizations |
| `deploy` | Deployment config changes |
| `docs` | Documentation |
| `chore` | Tooling, scripts, dependencies |

Scope examples: `template`, `tech-blog`, `ads`, `i18n`, `vercel`, `monitoring`

Examples:
```
feat(template): add FAQ section with JSON-LD schema
content(tech-blog): add 5 articles on cloud computing
seo(recipe-hub): improve meta descriptions for all pages
fix(ads): correct ad unit placement on mobile
```

## Security

| Rule | Detail |
|------|--------|
| **No secrets in code** | AdSense pub ID, API keys via env vars or Vercel env config |
| **Check licenses** | Only fork repos with MIT, Apache 2.0, or similarly permissive licenses |
| **Privacy policy** | Required by AdSense. Must accurately describe data collection (GA, cookies) |
| **No user data collection** | Static sites should not collect PII. If forms needed, use third-party (Formspree) |
| **HTTPS only** | All sites must be served over HTTPS (Vercel handles this) |
