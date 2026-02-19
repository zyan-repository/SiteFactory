**English** | [中文](zh/fork-guide.md)

# Fork Guide: Finding and Adapting Open-Source Projects

The core philosophy: **"Copy before Create"** — why build from scratch when thousands of useful tools exist on GitHub?

## Key Terms

If you're new to web development, here are terms used in this guide:

| Term | What it means |
|------|--------------|
| **Frontend** | The part of a website that runs in your browser (HTML, CSS, JavaScript files). This is what we need. |
| **Backend** | Server-side code that runs on a remote computer (Node.js, Python, etc.). We can't use these — free hosting doesn't support servers. |
| **API** | A way for code to request data from a server. "Public API" = anyone can use it (OK for us). "Internal API" = the project's own server (not OK). |
| **SSR** | Server-Side Rendering — pages are generated on a server before being sent to the browser. Requires a running server, which we can't host for free. |
| **Static site** | A website made of plain files (HTML, CSS, JS) that don't need a server to generate pages. This is what we need. |
| **package.json** | A file listing a JavaScript project's dependencies. We check this file for server-related entries. |
| **License** | Legal terms for using someone's code. MIT/Apache/BSD = OK for commercial use. GPL = has restrictions, avoid. No license = not allowed to use, skip. |

## The Process

```
Search GitHub → Evaluate (check-repo.sh) → Fork (fork-site.sh) → Deploy → Earn
```

## Step 1: Finding Projects

### Search Strategies

**GitHub Search** — Use these queries in the [GitHub search bar](https://github.com/search):

```
# By tool type
calculator html css language:HTML
converter tool html language:JavaScript
weather app html css
password generator html javascript
color picker tool html

# By "stars" for quality (more stars = more people found it useful)
calculator html stars:>10
qr code generator html stars:>20

# Exclude frameworks (we need plain HTML, not complex frameworks)
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

Skip a project immediately if you see any of these:

| Signal | What it means (plain English) | Why we skip it |
|--------|------------------------------|----------------|
| `server.js` / `app.py` / `main.go` | The project has code that runs on a server | We only host static files; we can't run servers |
| `docker-compose.yml` | The project runs multiple services together | Way too complex for our setup |
| `requirements.txt` / `Gemfile` / `go.mod` | The project needs Python/Ruby/Go installed | We need pure HTML/CSS/JS only |
| `DATABASE_URL` / `REDIS_URL` in `.env` | The project stores data in a database | Static sites can't have databases |
| `next` / `nuxt` in package.json | Uses a framework that generates pages on a server (SSR) | Requires a Node.js server to run |
| `express` / `koa` / `fastify` in package.json | Uses a web server framework | We need browser-only code |
| Login/signup pages | The project requires user accounts | User accounts need a backend server |
| `.env.example` with many API keys | Complex setup with many external dependencies | Too many things that can break |

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
- 40-69 or 1 issue → **NEEDS REVIEW** — check manually (see below)
- <40 or multiple issues → **INCOMPATIBLE** — skip this project

**What counts as a "critical issue" (red flag)?**
- License is GPL, AGPL, or "no license found" — means you can't use it commercially
- Backend files detected (server.js, app.py, etc.) — project needs a server to run
- Database dependency found — project needs a database we can't provide

If the score is 70+ but has a **warning** (yellow text, not red), you can usually proceed. Read the warning to understand what it's about — common warnings are "many JS files" or "unknown license format" which are usually fine.

### Manual Review Checklist

For "NEEDS REVIEW" projects, open the GitHub page and check:

```
☐ Does the README show simple setup? (just "open index.html" = good)
☐ Is there a live demo link? Does it work in the browser?
☐ Can you find index.html in the file list?
☐ In package.json, does the "start" script run a server? (bad: "node server.js", ok: no start script)
☐ Do JS files call internal APIs (look for "/api/" in the code)? (bad) Or public APIs (look for "https://api.xxx.com")? (ok)
☐ Does the license text say "MIT" or "Apache" or "BSD"? (good)
☐ Are there fewer than 30 HTML/CSS/JS files total? (manageable = good)
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

After forking, review and customize:

**1. Preview the site:**
```bash
open sites/bmi-calc/index.html
```

**2. Verify ad injection worked:**
```bash
grep "adsbygoogle" sites/bmi-calc/index.html
# If this prints a line, injection succeeded.
# If no output, re-run fork-site.sh or check for errors in the log.
```

**3. Update the title** (in `sites/bmi-calc/index.html`):
1. Open the file in any text editor
2. Find the `<title>` tag (near the top, inside `<head>`)
3. Change the text between `<title>` and `</title>` to your desired title
4. Also find `<meta property="og:title"` and update the `content` value to match

**4. Update the description** (same file):
1. Find `<meta name="description" content="...">`
2. Change the `content` value to your description (150-160 characters recommended)
3. Also update `<meta property="og:description" content="...">` to match

**5. Deploy:**
```bash
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
Optimistic: 50 sites x $0.10/day average = $5/day = $150/month
Realistic:  50 sites x $0.03/day average = $1.50/day = $45/month
Minimum:    50 sites x $0.01/day average = $0.50/day = $15/month
```

**Reality check:**
- Most new sites earn $0 for the first 1-3 months (no traffic yet)
- Revenue depends heavily on niche, traffic volume, and visitor geography
- US/UK/AU traffic earns 5-10x more per click than traffic from developing countries
- The $0.10/day average is achievable but requires consistent content and SEO work
- Treat SiteFactory as a long-term project, not a get-rich-quick scheme

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
| Not checking the license | Legal risk — you could be forced to take the site down |
| Leaving broken features | Users bounce immediately, hurts SEO rankings |
| Too many ads | AdSense policy violation — can get your account banned |
| No privacy policy | AdSense will reject your application |
| Not testing on mobile | 60%+ of traffic is mobile — broken mobile = lost visitors |

### When NOT to Fork

Some projects aren't worth the effort:

- Requires a build step you can't replicate (e.g., needs `npm run build` with complex webpack config)
- Depends on a private API that might shut down or require payment
- Has hardcoded API keys that you can't get your own version of
- Poor UI/UX that would take more than 30 minutes to fix
- Less than 5 GitHub stars (likely has bugs or is abandoned)
