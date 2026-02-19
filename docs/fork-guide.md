**English** | [中文](zh/fork-guide.md)

# Fork Guide: Finding and Adapting Open-Source Projects

The core philosophy: **"Copy before Create"** — why build from scratch when thousands of useful tools exist on GitHub?

## The Process

```
Search GitHub → Evaluate (check-repo.sh) → Fork (fork-site.sh) → Deploy → Earn
```

## Step 1: Finding Projects

### Search Strategies

**GitHub Search** — Use these queries:

```
# By tool type
calculator html css language:HTML
converter tool html language:JavaScript
weather app html css
password generator html javascript
color picker tool html

# By "stars" for quality
calculator html stars:>10
qr code generator html stars:>20

# Exclude frameworks
calculator html NOT react NOT vue NOT angular
```

**GitHub Topics** — Browse by topic:

- https://github.com/topics/calculator
- https://github.com/topics/converter
- https://github.com/topics/generator
- https://github.com/topics/tools
- https://github.com/topics/utility

**Google Search** — Find projects with demos:

```
site:github.com "html" "css" calculator open source
site:github.com "MIT license" weather tool html
```

### High-Value Categories

| Category | Examples | Why High Value |
|----------|----------|---------------|
| **Calculators** | BMI, loan, mortgage, tip, age | Users search specific terms → precise ad targeting |
| **Converters** | Unit, currency, timezone, temperature | Repeat visitors, daily use |
| **Generators** | Password, QR code, UUID, color palette | Strong SEO keywords, high intent |
| **Data Lookup** | Weather, IP info, exchange rates | Daily traffic, high engagement |
| **Reference** | Periodic table, keyboard shortcuts, ASCII table | Rich content, long page time |
| **Text Tools** | Word counter, case converter, markdown preview | Writers/devs use regularly |
| **CSS Tools** | Gradient generator, flexbox playground, shadow generator | Dev audience, high CPM |

### Quick Exclusion Signals

Skip a project immediately if you see:

| Signal | Why |
|--------|-----|
| `server.js` / `app.py` / `main.go` | Has a backend |
| `docker-compose.yml` | Multi-service setup |
| `requirements.txt` / `Gemfile` / `go.mod` | Non-frontend dependencies |
| `DATABASE_URL` / `REDIS_URL` in `.env` | Needs database |
| `next` / `nuxt` in package.json | SSR framework (needs server) |
| `express` / `koa` / `fastify` in package.json | Server framework |
| Login/signup pages | Needs auth backend |
| `.env.example` with many API keys | Complex setup |

## Step 2: Evaluate

### Automated Check

```bash
./scripts/check-repo.sh https://github.com/user/project
```

The script checks 7 areas and gives a score out of 100:

| Check | Points | What it looks for |
|-------|--------|-------------------|
| License | 0-20 | MIT/Apache/BSD = 20, Unknown = 5, GPL = 0 |
| Backend files | 0-20 | No server files = 20 |
| Server dependencies | 0-15 | No express/koa/next = 15 |
| Database references | 0-15 | No DB_URL/mongodb = 15 |
| index.html | 0-10 | At root = 10, nested = 5 |
| File count | 0-10 | <20 JS files = 10, >20 = 5 |
| API pattern | 0-10 | External API = 10, Internal /api/ = 0 |

**Scoring:**
- 70+ with no issues → **COMPATIBLE** — ready to fork
- 40-69 or 1 issue → **NEEDS REVIEW** — check manually
- <40 or multiple issues → **INCOMPATIBLE** — skip

### Manual Review Checklist

For "NEEDS REVIEW" projects:

```
☐ Open the GitHub repo page
☐ Check README for setup instructions — simple or complex?
☐ Look at the demo (if available) — does it work?
☐ Check file structure — is there a clear index.html?
☐ Look at package.json scripts — "start" runs a server?
☐ Check for API calls in JS — internal (/api/) or public?
☐ Verify license text allows commercial use + modification
☐ Count HTML/CSS/JS files — manageable size?
```

## Step 3: Fork and Adapt

### One-Command Fork

```bash
./scripts/fork-site.sh <github-url> <site-name> ["Site Title"] ["Description"]
```

Example:

```bash
./scripts/fork-site.sh https://github.com/user/bmi-calculator bmi-calc "BMI Calculator" "Calculate your Body Mass Index"
```

### What Gets Injected

The script automatically adds to all HTML files:

1. **AdSense Auto-Ads** — Google's script tag in `<head>` (auto-places ads)
2. **Google Analytics** — gtag.js for traffic tracking
3. **SEO Meta Tags** — description and Open Graph tags
4. **Privacy Policy** — Standalone page copied from `_shared/`
5. **About Page** — Standalone page copied from `_shared/`
6. **ads.txt** — Required by AdSense for ad verification
7. **Attribution** — Credit to original project in README

### Post-Fork Customization

After forking, you may want to customize:

```bash
# 1. Preview the site
open sites/bmi-calc/index.html

# 2. Check ad injection looks correct
grep "adsbygoogle" sites/bmi-calc/index.html

# 3. Update title/branding if needed
nano sites/bmi-calc/index.html

# 4. Add navigation link to privacy policy
# (inject.sh adds a link before </body>, but you may want it in the nav)

# 5. Deploy
./scripts/deploy.sh bmi-calc
```

## Step 4: SEO Optimization for Fork Sites

Fork sites need extra SEO work since they weren't built for it:

### Must Do

- [ ] Title tag includes primary keyword (e.g., "Free BMI Calculator - Check Your Body Mass Index")
- [ ] Meta description includes keyword + CTA (150-160 chars)
- [ ] H1 heading matches the page purpose
- [ ] Page loads fast (no unnecessary JS libraries)

### Nice to Have

- [ ] Add a "How to Use" section (more content = better for SEO)
- [ ] Add FAQ section with JSON-LD schema
- [ ] Add internal links between your sites
- [ ] Create multiple language versions

## Tips and Best Practices

### Volume Strategy

The key to SiteFactory is volume. Each individual site earns very little, but together they add up:

```
50 sites × $0.10/day average = $5/day = $150/month
```

### Diversify Categories

Don't put all sites in one category. Spread across:
- 30% calculators/converters
- 30% generators/tools
- 20% data lookup
- 20% reference/guides

### Avoid These Mistakes

| Mistake | Why It's Bad |
|---------|-------------|
| Forking the same project twice | Google penalizes duplicate content |
| Not checking the license | Legal risk |
| Leaving broken features | Users bounce, hurts SEO |
| Too many ads | AdSense policy violation |
| No privacy policy | AdSense rejection |
| Not testing on mobile | 60%+ of traffic is mobile |

### When NOT to Fork

Some projects aren't worth the effort:

- Requires a build step you can't replicate
- Depends on a private API that might shut down
- Has hardcoded API keys that you can't get
- Poor UI/UX that would take hours to fix
- Less than 5 GitHub stars (might have bugs)
