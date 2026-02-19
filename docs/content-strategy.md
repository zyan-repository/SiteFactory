**English** | [中文](zh/content-strategy.md)

# Content Strategy & AdSense Approval

How to get AdSense approved and maximize ad revenue.

## AdSense Approval Requirements

Google reviews your site before allowing ads. Here's what they check:

### Must Have (Non-Negotiable)

| Requirement | Detail |
|-------------|--------|
| **Original content** | Not copied from other sites. AI-generated is OK if edited |
| **Sufficient content** | Minimum 15 pages/posts with 300+ words each |
| **Privacy policy** | Describes cookie usage, analytics, ad tracking |
| **About page** | Who runs the site, what it's about |
| **Contact info** | Email or contact form |
| **Navigation** | Clear menu, users can find all pages |
| **Site age** | Usually 1-2 weeks minimum (varies by region) |
| **Custom domain** | Not a free subdomain from Vercel/Netlify |
| **HTTPS** | SSL certificate (Vercel handles this) |
| **ads.txt** | File at root declaring your publisher ID |

### Common Rejection Reasons

| Reason | Fix |
|--------|-----|
| "Insufficient content" | Add more posts (aim for 20+, 800+ words each) |
| "Valuable inventory: no content" | Your site has too little useful text |
| "Valuable inventory: under construction" | Remove placeholder text, "Coming soon" pages |
| "Navigational issues" | Fix broken links, add clear menu |
| "Site not accessible" | DNS not propagated yet, try again later |

## Content Creation Strategy

### For Hugo Content Sites

Create content that ranks on Google and attracts clicks:

**High-Value Niches** (higher CPC = more revenue per click):

| Niche | Example Topics | Estimated CPC |
|-------|---------------|---------------|
| Technology | "How to", tutorials, tool reviews | $0.50-2.00 |
| Finance | Savings tips, investing basics, budgeting | $1.00-5.00 |
| Health | Fitness tips, nutrition, wellness | $0.50-3.00 |
| Education | Study tips, online courses, language learning | $0.50-2.00 |
| Home/DIY | Organization, simple repairs, decoration | $0.30-1.50 |

**Content Formula:**

```
Title: [Number] + [Keyword] + [Benefit]
Example: "10 Free Tools to Convert PDF to Word Online"

Structure:
- Introduction (50-100 words) — state the problem
- H2 sections (each 100-200 words) — cover each point
- Conclusion (50-100 words) — summarize and CTA
- Total: 800-1500 words
```

### Using AI for Content Generation

SiteFactory includes an n8n workflow for AI content generation via Claude API:

1. Import `n8n/workflows/content-generation.json` into n8n
2. Configure the Claude API key
3. Set the cron schedule (e.g., daily)
4. The workflow generates SEO-optimized markdown articles

**Important:** Always review AI-generated content before publishing:
- Check for factual accuracy
- Add personal touches / unique insights
- Ensure natural reading flow
- Verify keyword usage isn't excessive

### For Fork Tool Sites

Tool sites don't need blog content, but they need supporting pages:

1. **How to Use** (300+ words) — Step-by-step instructions
2. **About This Tool** (300+ words) — What it does, who it's for
3. **FAQ** (300+ words) — Common questions and answers
4. **Privacy Policy** — Already included by `fork-site.sh`
5. **Related Tools** — Link to your other sites

## SEO Fundamentals

### On-Page SEO Checklist

Every page should have:

```
☐ Unique title tag (50-60 chars, keyword first)
☐ Meta description (150-160 chars, includes CTA)
☐ Single H1 heading
☐ Logical H2-H4 hierarchy
☐ Image alt text
☐ Internal links to other pages
☐ External links to authoritative sources
☐ Clean URL structure (no query params)
```

### Technical SEO

SiteFactory's Hugo template handles these automatically:

- Sitemap.xml generation
- robots.txt
- Canonical URLs
- Open Graph tags
- JSON-LD structured data
- hreflang tags (for multilingual sites)

### Keyword Research (Free Methods)

1. **Google Autocomplete** — Type your topic and see suggestions
2. **People Also Ask** — Check the PAA box in Google results
3. **Google Trends** — Compare keyword popularity
4. **AnswerThePublic** — Find questions people ask
5. **GitHub search** — What tools do people search for?

## AdSense Optimization

### Ad Placement Rules

SiteFactory uses **Auto-Ads** — Google automatically places ads where they perform best. But keep these rules:

| Rule | Detail |
|------|--------|
| Max 3 ad units per page | More ads ≠ more revenue |
| Content > ads | Ad space must be less than content space |
| No misleading placement | Ads must look like ads, not content |
| Mobile-friendly | Ads must not break mobile layout |
| No pop-ups | No interstitials blocking content |

### Revenue Metrics to Track

| Metric | What it means | Target |
|--------|--------------|--------|
| RPM | Revenue per 1000 pageviews | $1-10 (varies by niche) |
| CPC | Cost per click | $0.10-5.00 |
| CTR | Click-through rate | 1-3% (normal) |
| Pageviews | Total page views | More = more revenue |

### Warning Signs (Investigate Immediately)

| Signal | Possible Issue |
|--------|---------------|
| CTR > 5% | Invalid clicks (click farms, bots) |
| CTR suddenly drops to 0% | Ad serving issue |
| Revenue drops > 30% overnight | Policy violation or ad limit |
| "Limited ad serving" notice | Google is reviewing your traffic |

## Monthly Maintenance

| Task | Frequency | How |
|------|-----------|-----|
| Add new content | Weekly | New posts or pages |
| Check AdSense dashboard | Weekly | Look for warnings |
| Run Lighthouse | Monthly | `./scripts/lighthouse-check.sh --all` |
| Update dashboard | Daily (via n8n) | `./scripts/generate-dashboard.sh` |
| Review traffic sources | Monthly | Google Analytics |
| Check for broken links | Monthly | Browser DevTools console |

## Timeline

| Week | Goal |
|------|------|
| 1 | Set up SiteFactory, create first 3 sites |
| 2 | Add content to sites (15+ pages each) |
| 3 | Submit to Google Search Console, start indexing |
| 4 | Apply for AdSense |
| 5-6 | Wait for AdSense approval, keep adding content |
| 7+ | Scale: fork more tools, generate more content |
