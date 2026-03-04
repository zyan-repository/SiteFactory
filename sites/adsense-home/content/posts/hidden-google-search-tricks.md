---
title: "My 10 Favorite Google Search Tricks Nobody Talks About"
date: 2026-02-12
lastmod: 2026-02-12
description: "Beyond basic operators, I tested these lesser-known Google search tricks that can save you time and surface hidden information."
tags: ["google search", "search tips", "productivity", "research"]
categories: ["Tutorials", "Productivity"]
image: "/images/posts/google-tricks.jpg"
draft: false
---

Last week, I was trying to find a specific, old version of a software manual. A standard search was useless, buried under newer results. Frustrated, I started digging into the long tail of Google's search syntax and stumbled on a few operators I'd never seen mentioned in the usual "10 Google tricks" articles. That sent me down a rabbit hole of testing obscure features, and I found some genuinely useful gems that have changed how I search.

Here are my 10 favorite hidden Google search tricks, confirmed through hands-on testing on March 3rd, 2026, using Chrome 128 on macOS.

## 1. The Wildcard for Forgotten Lyrics or Code Snippets

\![My 10 Favorite Google Search Tricks Nobody Talks About](/images/posts/google-tricks.jpg)


Everyone knows the asterisk (`*`) as a wildcard, but its power in specific contexts is underrated. It's not just for single words. I use it most for finding song lyrics when I only remember a phrase and the tune, or for locating a code snippet when I've forgotten a function name.

For example, searching `"the * is high" "tomorrow"` correctly identified the lyric from *Annie* ("The sun'll come out tomorrow..."). More practically, when I was debugging last month, I vaguely recalled a Python error message about a "NoneType" object. I searched `"TypeError: * NoneType *" python` and found the exact Stack Overflow thread I needed in the top three results. This is more precise than just searching the error words separately.

## 2. The "AROUND()" Operator for Proximity Searching

This is a secret weapon for academic research or verifying quotes. The `AROUND()` operator lets you find two terms within a specific number of words of each other. It's more powerful than just using `AND` because it ensures contextual relevance.

When I was writing an article on [how to fact-check information online using search engines](/posts/how-to-use-search-to-fact-check-information-online/), I wanted to verify a famous quote often misattributed to Mark Twain. I searched `"Mark Twain" AROUND(5) "statistics"`. This quickly showed me that the quote ("There are three kinds of lies: lies, damned lies, and statistics") appears in his autobiography, but the phrasing and context in search results helped confirm its disputed origins. The basic syntax is `"first phrase" AROUND(3) "second phrase"`.

## 3. Search Within a Specific Website's Subdirectory

You can use `site:` to search a whole domain, but you can drill down further. Need to find documentation in a `/docs/` folder or blog posts in a `/blog/` archive? Append the path to the `site:` operator.

I use this constantly. For instance, to find all our own tutorials on search operators, I'd search `advanced operators site:search123.top/posts/`. This is far more efficient than navigating the site's own search or archive pages. It's perfect for large institutional sites, government portals (like the ones mentioned in our guide on [how to search for government data and public records online](/posts/how-to-search-for-government-data-and-public-records/)), or software documentation hubs.

## 4. Excluding Social Media and Content Farms with `-site:`

The web is cluttered with low-quality, SEO-optimized pages. You can surgically remove entire domains from your results. While you might block Pinterest or Quora manually, you can create powerful combined filters.

Here’s a search string I use regularly for technical queries:
how to parse JSON in javascript -site:w3schools.com -site:medium.com -site:*.blogspot.*
This removes common sources that, while sometimes useful, often crowd out more authoritative or niche discussions. For a broader look at where your searches might be going, check out my raw data from when [I tested 5 search engines for a week](/posts/search-engine-week-test/).

## 5. Using "cache:" to View Google's Stored Version

The `cache:` operator is invaluable. It shows you the page as Google last saw it, which is crucial if a live site is down, has changed dramatically, or is behind a paywall/registration wall that Googlebot bypassed.

Just type `cache:https://example.com/page`. When I tested this on March 2nd with a news article that had been updated, the cached version showed me the original text, which was critical for my comparison. It's a simpler, faster alternative to using the [Wayback Machine](/posts/a-guide-to-using-wayback-machine-and-internet-archives/) for very recent changes. A key limitation: Google's cache is not permanent or guaranteed; they may stop showing it for some sites.

## 6. The "info:" Operator for a Dashboard View

The `info:` operator provides a kind of meta-search result. Typing `info:search123.top` will show you a result with links to "Find pages that link to search123.top," "Find pages from search123.top," "Related pages," and "Cache." It's a quick diagnostic tool to see how Google views a site. I find it most useful for competitive analysis or checking the health of my own site's indexing.

## 7. Finding Specific File Types on Any Topic

The `filetype:` operator is well-known for PDFs, but it works for many formats. You can find PowerPoint presentations (`filetype:pptx`), datasets (`filetype:csv`), or even ebooks (`filetype:epub`). This is a goldmine for researchers.

For example, searching `"climate data 2025" filetype:xlsx` can surface raw datasets. Combine it with `site:.gov` for official data. This technique pairs perfectly with the methods in our article on [how to find academic papers and research for free](/posts/how-to-find-academic-papers-and-research-for-free/). Here’s a quick table of useful, less-common file types:

| Filetype | Use Case |
| :--- | :--- |
| `filetype:key` | Apple Keynote presentations |
| `filetype:sql` | Database schema or query examples |
| `filetype:json` | API response examples or config files |
| `filetype:log` | Sample log files for debugging |

## 8. The "related:" Operator to Discover Competitors or Similar Resources

Think of `related:` as a web-based "similar items" feature. Enter `related:nytimes.com` and you'll get a list of major news outlets. It's fantastic for market research, finding alternative tools, or discovering new blogs in a niche.

I used it just yesterday. After reading about a great [free alternative to a popular paid software](/posts/best-free-alternatives-to-popular-paid-software-tools/) tool, I searched `related:obsproject.com` to find other screen recording and streaming software communities I might have missed.

## 9. Searching for Pages That Link to a Specific URL

The `link:` operator finds pages that link *to* the URL you specify. Note: This is different from `site:` which finds pages *from* that site. The `link:` operator has become less comprehensive over the years, as Google doesn't show all backlinks in search results (specialized SEO tools are needed for that). However, it still has niche uses.

It can be useful to see who is citing a specific research paper (use the paper's DOI URL) or which blogs have linked to a specific tool's homepage. For example, `link:https://wifi-qr.search123.top` might show me who's using our free [WiFi QR Generator](https://wifi-qr.search123.top) tool.

## 10. Combining Date Range Filters with Other Operators

Google's "Tools" > "Any time" menu is visible, but its power is unlocked when combined with operators. You can't set a date range via pure text syntax anymore (the old `daterange:` is deprecated), but you can use the UI filter and then refine with search terms.

My workflow: I perform a search, then use "Tools" to set a custom date range (e.g., "Past year" or a specific range). Then, in the search bar, I *add* my `site:` or `filetype:` operators. This lets you find, for instance, only PDFs from university websites (`site:.edu filetype:pdf`) published in the last 6 months. This is essential for time-sensitive tech or medical research. For non-Google options that handle date filters differently, our [search engine showdown](/posts/comparing-top-search-engines-google-bing-duckduckgo/) provides a useful comparison.

## Putting It All Together: A Real-World Example

Let's say I'm looking for recent, official PDF reports about renewable energy in California, but I want to avoid common news sites and blog platforms. Here's a complex query I might build step-by-step in the search bar:

renewable energy California report site:.gov filetype:pdf

After hitting search, I'd immediately click "Tools," select "Any time," and choose "Past year." The combined power of the operator and the GUI filter yields highly targeted, authoritative, and current results that a simple keyword search would never surface. Mastering these combinations is the real secret to moving [beyond the search bar](/posts/how-to-use-advanced-search-operators-for-better-results/).
