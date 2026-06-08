---
title: "I Scrubbed My Name from 57 Search Results in One Weekend: Here's Every Step That Worked"
date: 2026-06-08
lastmod: 2026-06-08
description: "Proven, step-by-step methods to remove personal info from Google, Bing, and people-search sites. I tested every technique myself."
tags: ["online privacy", "data removal", "personal information", "digital footprint", "search engines", "privacy tools"]
categories: ["Privacy", "Security"]
image: ""
draft: false
---

It started with a random vanity search of my own name on a Tuesday evening in May 2026. I was killing time before a meeting, sipping cold brew, and typed "Arron Zhou" into Google. What came back was a dossier I didn't know existed.

My current home address. My phone number from three apartments ago. A blurry photo from a 2022 conference badge. And — most unsettling — an estimated income bracket that was within $5,000 of my actual salary.

I felt my stomach drop. Not because I have anything to hide, but because I never consented to any of this being public. I spent that weekend obsessively testing every opt-out form, every data removal request, and every privacy trick I could find. By Sunday night, I had removed my information from 57 distinct search results across Google, Bing, DuckDuckGo, and 14 people-search sites.

This article is the exact playbook I used. No fluff, no "just use a VPN and relax" advice. Just specific, tested steps that actually removed my data from search results.

## Why Your Personal Info Ends Up in Search Results

Before we get into removal tactics, let's understand the ecosystem feeding search engines your private data. I've been writing about privacy tools for years, and my piece on [how to clear your digital footprint](/posts/how-to-clear-digital-footprint-protect-privacy/) covers the broader picture, but here's the condensed version for search results specifically.

There are three primary sources:

**Data brokers** scrape public records (property deeds, voter registrations, professional licenses) and cross-reference them with social media profiles, shopping histories, and forum posts. Companies like Spokeo, BeenVerified, and Whitepages aggregate this into neat little profiles, then sell access to employers, landlords, and anyone with $3.99 and an email address.

**People-search sites** are the consumer-facing version of data brokers. Sites like Radaris, MyLife, and PeopleFinders let anyone search your name and get your address, relatives, and sometimes criminal records. They make money from ads and premium subscriptions.

**Search engine caches** preserve old versions of web pages even after the original content is removed. Google's cache, the Wayback Machine, and Bing's snapshot feature mean deleted information often lives on for months.

When I tested my own removal requests in May 2026, I used Chrome 125 on a Windows 11 machine, with uBlock Origin and Privacy Badger running. Your mileage may vary depending on browser and location, but the core workflows are identical.

## The First 30 Minutes: Secure Your Accounts and Stop the Bleeding

Most people start by hitting people-search sites directly. That's a mistake. If your personal info is still accessible through other channels, you're just playing whack-a-mole. You need to close the data spigots first.

### Step 1: Run a Complete Account Audit

I logged into every online account I could remember — 47 in total, according to my password manager (I use Bitwarden, and my [password manager testing framework](/complete-guide-to-password-managers/) details why). For each account, I checked:

- **Profile visibility settings**: Is my profile public? Can search engines index it?
- **Email and phone display**: Are these hidden from other users?
- **Location data**: Is my city or address visible?

The biggest offender? A LinkedIn profile I hadn't touched in three years. My full address was listed because I'd once added it for a "networking event" mailing list. I changed visibility to "Only me" for all contact details.

### Step 2: Lock Down Social Media Searchability

Facebook, Twitter (X), Instagram, and Reddit all allow search engine indexing of your profiles. Here's what I changed in May 2026:

- **Facebook**: Settings → Privacy → "Do you want search engines outside Facebook to link to your Profile?" → Toggle OFF. This stopped Google from showing my Facebook page in search results.
- **Twitter/X**: Settings → Privacy and safety → "Discoverability" → Uncheck "Let people who have your email or phone number find you"
- **Reddit**: In old Reddit (new Reddit buries this), go to preferences → privacy options → uncheck "Show up in search results"
- **Instagram**: Switch to private account. If you need public for business, at minimum hide your email and phone in bio.

### Step 3: Remove Yourself from Google's Public Data

Google has a specific tool for this: the "Results about you" feature. When I tested it in May 2026, it was available under my Google account settings (not search settings). Here's the exact URL path:

myaccount.google.com → Privacy & personalization → Results about you

I submitted removal requests for three items that showed my personal contact info. Google processed two within 24 hours and rejected one (a news article quoting my LinkedIn profile — they argued it was "newsworthy"). I appealed and lost.

## The Heavy Lifting: Removing Data from People-Search Sites

This is where the real work begins. I identified 14 people-search sites that had indexed my information, using Google searches like:

site:spokeo.com "Arron Zhou"
site:beenverified.com "Arron Zhou"
"Arron Zhou" "address" OR "phone" OR "email"

I also used Google's advanced search operators — which I wrote about in [my guide to advanced search](/how-to-use-google-advanced-search-operators-effectively/) — to find buried pages. The `site:` and `inurl:` operators were my best friends.

### The Data Removal Process (Site by Site)

Below is the table I made during my weekend marathon. I've tested each link and process within the past 30 days.

| Site | Opt-Out Method | Processing Time | Success Rate |
|------|----------------|-----------------|--------------|
| Spokeo | Submit ID + email verification | 3-5 days | 4/4 listings removed |
| BeenVerified | Automated phone verification | 24-48 hours | 3/3 listings removed |
| Whitepages | Opt-out form + email confirmation | 2-7 days | 2/2 listings removed |
| Radaris | Email opt-out with link | 48 hours | 1/1 listing removed |
| MyLife | Requires email + CAPTCHA | 5-10 days | 2/3 listings removed (one reappeared) |
| PeopleFinders | Automated phone call verification | 24 hours | 2/2 listings removed |
| Intellius | Opt-out form + email | 3-5 days | 1/1 listing removed |
| PeekYou | Opt-out form | 24-48 hours | 1/1 listing removed |
| ZabaSearch | Email opt-out | 48-72 hours | 1/1 listing removed |
| CheckPeople | Automated phone verification | 24 hours | 1/1 listing removed |
| TruthFinder | Requires ID upload | 2-4 weeks | Still pending |
| Instant Checkmate | Requires phone verification | 3-5 days | 1/1 listing removed |
| US Search | Opt-out form | 5-7 days | 0/1 (denied, need to reapply) |
| Clustrmaps | Email opt-out | 24 hours | 1/1 listing removed |

**Critical observation**: When I tested Spokeo's opt-out, I noticed the confirmation email landed in my spam folder. Check your spam. I almost missed it, and the removal request would have expired after 72 hours.

### What Information Do They Require to Remove You?

Every site asks for some form of identification to prove you are who you say you are. The common pattern is:

- Full name
- Email address
- Phone number (some sites call you with an automated code)
- Street address (to match their records)
- Date of birth (sometimes)

I was uncomfortable giving my phone number to data brokers I was trying to escape. For phone verification sites, I used a Google Voice number I created specifically for this purpose. If you don't have one, Burner or Hushed work too.

One site — TruthFinder — required me to upload a photo of my driver's license. I declined. The risk of a data broker storing my government ID outweighed the benefit of removing one listing. According to the 2025 Data Broker Transparency Report from Consumer Reports, 14% of data brokers admitted to data breaches in the previous 18 months. I wasn't willing to take that chance.

## The Advanced Stuff: Removing Cached Pages and Old Content

People-search sites are the low-hanging fruit. The harder work is removing content you or others published years ago.

### Google Cache Removal

Even if you delete a blog comment, forum post, or old social media update, Google's cached version persists. I found three cached pages with my old phone number.

The removal process:
1. Log into Google Search Console
2. Use the "Remove outdated content" tool
3. Submit the exact URL of the cached page
4. Google reviews within 24-48 hours

For pages I couldn't access via Search Console (like third-party forums), I used Google's public removal request form at `www.google.com/webmasters/tools/removals`. You'll need the exact URL.

### Wayback Machine Removal

The Internet Archive's Wayback Machine stores snapshots of pages even after they're deleted. I found a 2023 snapshot of an old personal website that listed my full address.

Removal process for Wayback Machine:
1. Go to `archive.org/about/exclude.php` (yes, this is the obscure URL — it hasn't changed in years)
2. Include the exact URL you want removed
3. Add a note explaining why (I said "doxxing risk — contains personal address")
4. Wait. It took 6 days for my URL to be removed.

The Wayback Machine processes these manually, and they seem backlogged. My request was submitted on May 15, 2026, and the URL was excluded on May 21.

### Old Forum Posts and Comments

I had posts on Stack Overflow (dated 2019) and a fantasy football forum (2018) that included my real email address. Stack Overflow allows you to edit your profile to hide your email, but forum posts are permanent unless you contact the site admin directly.

For the fantasy football site, I emailed their support with a subject line "Privacy removal request — [username] — [URL]" and included a short explanation. They removed the posts within a week.

Stack Overflow was more difficult. Their policy is that post content belongs to the community, not the author. I couldn't delete my questions without upvoted answers losing context. However, I could edit my profile to remove the display email, and I requested a username change through their support form.

## The Tools That Actually Help

Not every privacy tool is worth installing. I tested five during my weekend, and here's what I actually kept.

### DeleteMe (Paid — $129/year for one person)

DeleteMe is a subscription service that handles removal requests across 25+ data broker sites on your behalf. I signed up for the free trial to compare against my manual efforts.

When I tested DeleteMe in May 2026:
- They identified 19 of the 14 sites I'd already found plus 5 I missed
- Their removal progress was visible in a dashboard with checkmarks
- After 2 weeks, 12 of the 19 listings were removed

The catch: DeleteMe's processing time for new requests was listed as "4-6 weeks." Manual removal was faster for me, but DeleteMe handled sites I didn't know existed.

### OneRep (Paid — $13.96/month)

OneRep claims to cover 190+ sites. I tested it on a separate profile (a burner name I created for testing). After 10 days, only 6 of the 15 known listings were removed. Their dashboard was less transparent than DeleteMe's, and I couldn't see which requests were pending.

### Google's "Results about you" (Free)

This is Google's built-in tool, and it's surprisingly effective for Google-specific removals. I used it to remove:
- 2 Spokeo listings appearing in Google results
- 1 BeeVolved listing
- 1 old forum post

Limitation: This only removes URLs from Google's search index. The source pages still exist on the original sites. And it doesn't touch Bing or DuckDuckGo.

### Privacy Bee (Free tier available)

Privacy Bee offers a free scan that shows risk scores. Their premium ($149/year) includes automated removal. I only used the free scan, which found 8 data points I missed — mostly from little-known sites like VoterRecords.com.

### Manual Checklist (Free — what I built)

After the weekend, I created a spreadsheet tracking:
- Site name
- URL of the specific listing
- Opt-out link
- Date submitted
- Date removed
- Follow-up needed

I used Google Sheets (and yes, I wrote about [Google Sheets for project management](/how-to-use-google-sheets-project-management/) because it genuinely works). Having a centralized tracker prevented me from submitting the same request twice or forgetting which sites needed follow-ups.

## The Honest Limitations Nobody Talks About

I want to be straightforward: you cannot make yourself completely invisible. Here are the hard limits I hit.

### Public Records Are Public

Property records, court filings, and voter registration are legally public in the United States. You can't remove your name from a county assessor database. You can, however, make those records harder to find by:

- Requesting address redaction (some states allow this for safety concerns, e.g., California SB-250)
- Registering to vote with a PO box instead of your street address (check your state's rules)
- Using a trust or LLC for property ownership (expensive and requires a lawyer)

I tried to remove my voter registration record from the public-facing database in my county. The clerk informed me that per state law, voter rolls must be available for inspection. My name stayed.

### Google Won't Remove Everything

Google's policies allow them to keep "newsworthy" or "public interest" content. A 2024 article in my local paper mentioned my name in connection with a community event. Google refused my removal request, citing the "public figure" exception — even though I'm not a public figure. Their reasoning: the article was from a legitimate news publication and served "informational purposes."

### Data Brokers Re-Add You

This is the most frustrating part. Between May 2026 and June 2026, three sites I'd already removed myself from re-added my information. Spokeo re-appeared in search results on June 2 with a newer version of my profile (likely scraped from a new property record). I had to re-submit the removal request.

The cycle is: you remove your data → the broker rescrapes public records → your data reappears → you remove it again.

According to a 2025 study by the Privacy Rights Clearinghouse, 67% of people who opted out of data broker sites found their information re-listed within 12 months. The median time before re-appearance was 8 months.

### Phone Verification Is a Privacy Trap

Several people-search sites require phone verification — meaning they call or text you a code. This ties your confirmed phone number to their existing profile. You're literally giving them your active phone number to complete the removal.

For the sites that required this, I used a Google Voice number that I planned to abandon afterward. If you use your real number, expect marketing calls. Within 48 hours of verifying my Google Voice number with PeopleFinders, I received three spam calls on that number.

## How to Use Search Engines to Monitor Recurrence

Once you've done the initial cleanup, you need to monitor for reappearance. Here's my monitoring setup — which I built using the same alert strategies from my [Google Alerts guide](/how-to-set-up-google-alerts-news-trends/).

### Set Up Google Alerts for Your Name + Data Points

Create three separate alerts:

1. `"Your Full Name"` — catches new mentions
2. `"Your Email Address"` — catches data broker scrapes (use quotes around the full email)
3. `"Your Phone Number"` — format with dashes and without

I also added an alert for my old address, since that's common in white pages sites.

### Use Bing's Alerts Too

Google misses things that Bing catches. I set up Bing Alerts (at `bing.com/alerts`) for the same terms. When I tested both in May 2026, Bing alerted me to a ProfileFinder listing that Google hadn't indexed yet.

### Monthly Manual Searches

Once a month, I run these searches:

site:*people* OR site:*finder* OR site:*publicrecords* "Arron Zhou"

I also search for my email and phone number directly on Google and Bing. This takes 15 minutes but catches new listings that alerts might miss.

## What About Search Engines That Don't Support Removal?

Google and Bing offer removal tools, but other search engines handle this differently.

### DuckDuckGo

DuckDuckGo gets its results from Bing's index. If you remove yourself from Bing, you're largely removed from DuckDuckGo too. However, DuckDuckGo doesn't have a direct removal tool. Their position, according to their privacy policy (last updated March 2025), is that they show "what's already public." I had to remove data at the source.

### Brave Search

Brave has its own index (as of 2024) and doesn't offer removal forms. I tested this by searching for a listing I'd removed from Google — Brave still showed it two weeks later. The only option is to email their support at `support@search.brave.com`, which I did for one persistent URL. They responded in 4 business days but declined removal, saying the content was "publicly available from a government source."

### Startpage

Startpage uses Google's index with privacy filters. Removing from Google generally removes from Startpage. No separate removal process needed.

## The One-Box Method: When You Need Speed

I'd been working systemically, but during the weekend I developed a faster method for known sites. Here's the command I used to find all pages on a specific people-search site that contained my info:

site:spokeo.com "Arron Zhou" AND (address OR phone OR email OR age)

Using this in Google's search bar returned 11 specific pages — 8 of which I hadn't found manually. The trick is to combine `site:` with personal identifiers. I covered more operator combinations in [my boolean search guide](/create-boolean-search-strings-for-research/).

I then opened each URL, copied the exact opt-out link path, and submitted removal requests in batches. By batching, I finished 14 sites in about 4 hours on Saturday.

## What I Didn't Do (But You Might Consider)

There are extreme measures I chose not to take. You might feel differently depending on your threat model.

### Legal Name Change

Some people legally change their name to break the data trail. This is overkill for most people. The cost in the US ranges from $150-$400 plus court fees, and it requires publishing your new name in a local newspaper (which defeats the purpose). I skipped this.

### Sealed Records

If you have court records you want hidden, you can petition to have them sealed. This requires a lawyer and costs $500-$2000. I didn't have any court records to deal with.

### Delete Your Social Media Entirely

This was tempting. But as a professional writer and engineer, having some social media presence helps with credibility. Instead, I locked everything down to the strictest privacy settings.

## The Real Cost of This Project

Let's be transparent about what this cost me in time and money.

**Time spent (manual)**: Approximately 14 hours over one weekend, plus 2 hours of follow-ups.

**Tools I paid for**: I didn't. I used free trials and manual methods. If I were maintaining this long-term, I'd consider DeleteMe ($129/year) for the ongoing monitoring.

**Tools that cost me privacy**: Phone verification on 3 sites. I gave them a Google Voice number, but they still associated that number with my name.

**Ongoing maintenance**: 15 minutes per month for monitoring.

## The Bottom Line

After that weekend, my name returned to a reasonably private state. Googling "Arron Zhou" now shows my professional portfolio, my GitHub profile, and one LinkedIn page with limited info. The people-search results that once filled the first two pages are gone.

The system works, but it requires periodic maintenance. Data brokers are persistent, and they'll re-list your information as new public records appear. Treat privacy like brushing your teeth — it's not a one-time fix, it's a regular habit.

If you're serious about this, start with the account audit (30 minutes), then tackle the top 10 people-search sites using the links above. Set your Google Alerts. Check back in 2 months.

And if you find a new data broker site I missed, drop me a note. I'm still hunting down a few.
