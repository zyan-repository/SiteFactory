**English** | [中文](zh/content-strategy.md)

# Content Strategy & AdSense Approval

How to get AdSense approved and maximize ad revenue.

## AdSense Approval Requirements

Google reviews your site before allowing ads. Here's what they check:

### Must Have (Non-Negotiable)

| Requirement | Detail |
|-------------|--------|
| **Original content** | Not copied from other sites. AI-generated content is acceptable IF you make meaningful edits (see "How to review AI content" below) |
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
| "Valuable inventory: no content" | Your site has too little useful text. Every page must have substantial, helpful content — not just a tool or widget with no explanations |
| "Valuable inventory: under construction" | Remove placeholder text, "Coming soon" pages, and any empty sections |
| "Navigational issues" | Fix broken links, add clear menu with links to all pages |
| "Site not accessible" | DNS not propagated yet, try again in 1-2 weeks |

### What If AdSense Approval Takes Longer Than Expected?

Normal timeline: 2-14 days. But it can take up to 4-6 weeks in some cases.

**If you haven't heard back after 2 weeks:**
1. Log in to [https://adsense.google.com/](https://adsense.google.com/) and check if there is a status message or banner at the top
2. Make sure your site is actually accessible — visit it in a private/incognito browser window
3. Check [Google Search Console](https://search.google.com/search-console) → "Pages" to see if your pages are indexed (look for "Indexed" count > 0)
4. Keep adding content — more content = higher chance of approval

**If you receive a rejection email:**
1. Read the rejection reason carefully — Google tells you the specific issue
2. Fix the issue (see "Common Rejection Reasons" table above)
3. Wait at least **14 days** before reapplying (applying too soon = automatic rejection)
4. Reapply at [https://adsense.google.com/](https://adsense.google.com/)

> **Common misconception:** You do NOT need separate AdSense accounts for each site. One AdSense account covers all your sites. Once approved for one site, you can add the same `publisher_id` to all your other sites immediately — no need to apply again.

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

> **What is CPC?** Cost Per Click — the amount you earn each time a visitor clicks an ad. These ranges are approximate and depend on the visitor's country, the specific topic, and the advertiser. US/UK/AU traffic earns 5-10x more per click than traffic from developing countries.

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

### How to Review AI Content Before Publishing

Before publishing any AI-generated article, do ALL of the following (budget ~10-15 minutes per article):

1. **Fact-check**: Search key claims on Google. AI can fabricate statistics, tool names, URLs, or dates that don't exist.
2. **Add your voice**: Rewrite the introduction and conclusion in your own words. Add at least 2-3 sentences of personal opinion or experience per section.
3. **Fix robotic patterns**: AI tends to write "In conclusion," "It is important to note that," "In today's digital age." Replace these with natural transitions.
4. **Check for repetition**: AI often says the same thing in slightly different words across paragraphs. Remove redundant sections.
5. **Verify links**: If the AI included any URLs, check that they actually exist and go where expected. Delete any that are broken.

> **Why this matters:** Google can detect low-quality AI-generated content. Simply running "generate" and publishing the raw output will likely get your AdSense application rejected. The edits above make content pass as human-written.

### For Fork Tool Sites

Tool sites don't need blog content, but they need supporting pages to pass AdSense review:

1. **How to Use** (300+ words) — Step-by-step instructions for the tool
2. **About This Tool** (300+ words) — What it does, who it's for, why it's useful
3. **FAQ** (300+ words) — Common questions and answers about the tool
4. **Privacy Policy** — Already included by `fork-site.sh`
5. **Related Tools** — Link to your other sites

> **Where to add these pages:** Create separate HTML files (e.g., `how-to-use.html`, `about.html`) in the site's root directory (`sites/your-tool/`), and add links to them from the main page's navigation.

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

1. **Google Autocomplete** — Type your topic in Google and see what it suggests
2. **People Also Ask** — Check the "People also ask" box that appears in Google search results
3. **Google Trends** ([trends.google.com](https://trends.google.com)) — Compare keyword popularity over time
4. **AnswerThePublic** ([answerthepublic.com](https://answerthepublic.com)) — Find questions people ask about a topic
5. **GitHub search** — What tools do people search for on GitHub?

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

| Metric | What it means | Target | Where to see it |
|--------|--------------|--------|-----------------|
| RPM | Revenue per 1000 pageviews | $1-10 (varies by niche) | AdSense → Reports |
| CPC | Cost per click | $0.10-5.00 | AdSense → Reports |
| CTR | Click-through rate | 1-3% (normal) | AdSense → Reports |
| Pageviews | Total page views | More = more revenue | Google Analytics |

### Warning Signs (Investigate Immediately)

| Signal | What it means | What to do |
|--------|--------------|------------|
| CTR > 5% | Abnormally high click rate — may indicate invalid clicks (bots, click farms, or someone repeatedly clicking your ads) | Check Google Analytics for suspicious traffic sources. Do NOT click your own ads. Wait — Google will investigate automatically. |
| CTR suddenly drops to 0% | Ads stopped showing on your site | Check AdSense dashboard for error messages. Verify your site loads correctly. |
| Revenue drops > 30% overnight | Possible policy violation or ad serving restriction | Log in to AdSense and check for any policy warnings or "Ad serving limited" banners. |
| "Limited ad serving" notice | Google detected unusual click patterns or traffic and temporarily restricted ads on your site | **Where you see this:** A yellow or red banner at the top of the AdSense dashboard. **What to do:** (1) Do NOT click your own ads, ever. (2) Check GA for suspicious referrers. (3) Do nothing else — Google automatically reviews and restores ad serving within 30 days if traffic normalizes. (4) Do NOT contact Google support about this; it resolves itself. |

## Monthly Maintenance

| Task | Frequency | How |
|------|-----------|-----|
| Add new content | Weekly | New posts or pages |
| Check AdSense dashboard | Weekly | Look for warnings or banners at the top |
| Run Lighthouse | Monthly | `./scripts/lighthouse-check.sh --all` |
| Update dashboard | Daily (via n8n) | `./scripts/generate-dashboard.sh` |
| Review traffic sources | Monthly | Google Analytics → Acquisition → Traffic acquisition |
| Check for broken links | Monthly | Browser DevTools console (look for 404 errors) |

## Timeline

| Week | Goal |
|------|------|
| 1 | Set up SiteFactory, create first 3 sites |
| 2 | Add content to sites (15+ pages each) |
| 3 | Submit to Google Search Console, start indexing |
| 4 | Apply for AdSense |
| 5-6 | Wait for AdSense approval, keep adding content |
| 7+ | Scale: fork more tools, generate more content |

> **If AdSense approval takes longer than 6 weeks:** Don't worry — keep adding content and ensure all pages are indexed in Search Console. You can check indexing status at [Search Console](https://search.google.com/search-console) → Pages. Reapply after fixing any issues Google identified.
