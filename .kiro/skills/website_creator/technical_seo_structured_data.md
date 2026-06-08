---
id: technical_seo_structured_data
version: 1.0.0
owners: [website_creator, frontend_lead]
tags: [seo, technical-seo, schema-org, sitemap, robots, canonical, og]
when_to_use: |
  Beyond `seo_foundations`. Technical SEO is what gets you on page one
  of Google when on-page content is already strong. Schema.org markup,
  sitemap discipline, canonical URLs, robots directives — invisible
  to users, decisive for crawlers.
inputs:
  - site_topology, target_keywords, indexed_inventory
outputs:
  - "technical_seo_audit: structured data + sitemap + robots + canonical + indexability"
---

# Technical SEO + Structured Data

> Content SEO answers "what does the user want to read?" Technical SEO
> answers "can Google FIND, CRAWL, RENDER, and UNDERSTAND it?" Most
> sites lose 30-60% of their organic ceiling to fixable technical bugs.

## The pillars of technical SEO

```
1. CRAWLABILITY     — Googlebot can REACH every page (robots, internal links)
2. INDEXABILITY     — Google decides which pages to keep in the index
3. RENDERABILITY    — JS-rendered content actually visible to crawler
4. STRUCTURED DATA  — Schema.org markup → rich results / SERP features
5. CANONICALIZATION — One URL per piece of content; no duplicate fighting
6. PERFORMANCE      — Core Web Vitals (cross-ref existing skill)
7. INTERNATIONAL    — hreflang (cross-ref i18n skill)
```

This skill covers 1-5.

## Schema.org structured data

Tag your pages with machine-readable data. Google uses it for rich
SERP results (stars, prices, FAQ accordions, breadcrumbs, etc.).

Use **JSON-LD** (preferred), not microdata or RDFa:

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "How to ship fast",
  "image": "https://example.com/hero.jpg",
  "author": { "@type": "Person", "name": "Jane Doe" },
  "datePublished": "2026-05-27",
  "publisher": {
    "@type": "Organization",
    "name": "Acme",
    "logo": { "@type": "ImageObject", "url": "https://example.com/logo.png" }
  }
}
</script>
```

Common types to ship:

| Type | Where | SERP benefit |
|---|---|---|
| `Organization` | Home, About | Knowledge panel, logo in SERP |
| `WebSite` + `SearchAction` | Home | Sitelinks search box |
| `BreadcrumbList` | Every page | Breadcrumb display |
| `Article` / `BlogPosting` | Posts | Top stories carousel |
| `Product` + `Offer` | E-commerce | Price, rating, availability |
| `Review` / `AggregateRating` | Product, service pages | Stars in SERP |
| `FAQPage` | FAQ pages | Accordion in SERP |
| `HowTo` | Tutorial pages | Step-by-step in SERP |
| `Recipe` | Recipe sites | Rich recipe cards |
| `Event` | Event pages | Event panel |
| `LocalBusiness` | Local sites | Local pack |
| `JobPosting` | Career pages | Google for Jobs |
| `SoftwareApplication` | Product pages | App detail panel |
| `VideoObject` | Video pages | Video thumbnail |
| `Person` | Author pages | Knowledge panel |

Test with Google's **Rich Results Test** before deploy. Validate with
**Schema.org Validator** for spec compliance.

## Sitemap.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2026-05-27</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://example.com/pricing</loc>
    <lastmod>2026-05-20</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
```

Rules:
- ONE URL per canonical version.
- ≤ 50k URLs per sitemap; ≤ 50MB.
- For larger sites: sitemap INDEX file referencing multiple sitemaps.
- `lastmod` is the strongest signal — keep it accurate.
- Submit to Google Search Console + Bing Webmaster.
- Auto-generate from CMS / SSG; don't hand-curate.
- Per-locale sitemaps with `<xhtml:link rel="alternate" hreflang="...">`
  for international.

Image sitemap, video sitemap, news sitemap as separate files for those
content types.

## robots.txt

```
# /robots.txt
User-agent: *
Disallow: /admin/
Disallow: /api/
Disallow: /search?
Allow: /

Sitemap: https://example.com/sitemap.xml
```

Common patterns:
- DISALLOW: admin areas, dynamic search URLs, faceted-nav infinite
  combinations, staging subdomains.
- ALLOW the rest by default.
- Specific user-agents for special handling (AI scrapers — see "AI
  bot blocking" below).
- Always include sitemap location.

**Beware**: robots.txt blocks CRAWL not INDEX. A page disallowed in
robots may still be indexed if linked from elsewhere (without content
preview). Use `noindex` meta tag for real "don't index."

## Robots meta + X-Robots-Tag

```html
<meta name="robots" content="index, follow">      <!-- default -->
<meta name="robots" content="noindex, nofollow">  <!-- block both -->
<meta name="robots" content="noindex, follow">    <!-- block index, allow link juice -->
<meta name="googlebot" content="noimageindex">    <!-- specific bot -->
```

Or HTTP header (for non-HTML resources):

```
X-Robots-Tag: noindex
```

Common applications:
- `noindex` on: search results, internal duplicates, thin content,
  legacy URLs.
- `nofollow` on: user-generated links (comments), paid links.

## Canonical URLs

```html
<link rel="canonical" href="https://example.com/pricing">
```

When multiple URLs serve the same content (UTMs, sort params, paginated
listings, http vs https, www vs non-www), specify the canonical:

```
https://example.com/products?utm_source=email
https://example.com/products?utm_source=twitter
https://example.com/products?sort=price
                                    ↓ all canonical to:
                          https://example.com/products
```

Without canonicals, Google picks one. Often the wrong one. Your link
juice splits across variants.

For paginated archives:
- Don't use `rel="prev/next"` (deprecated 2019).
- Each page canonical to itself.
- Alternative: paginate via "load more" (single URL).

## URL structure best practices

```
GOOD: https://example.com/blog/how-to-ship-fast
GOOD: https://example.com/pricing
BAD:  https://example.com/p?id=12345
BAD:  https://example.com/blog/2026/05/27/how-to-ship-fast (date locks the URL)
```

- Lowercase only.
- Hyphens, not underscores.
- Short + descriptive.
- HTTPS only — HSTS preload list submission.
- 301 redirect www↔non-www to one canonical host.
- One trailing-slash convention.

## JS rendering for SEO

Modern Google renders JS, but with delay (the "second wave"). For
SEO-critical pages:

- **SSR** (Next.js, Astro SSR) — server renders, instant content.
- **SSG** (Next.js, Astro, 11ty, Hugo) — pre-rendered at build time.
- **ISR** (Next.js) — hybrid, regenerate on demand.

AVOID for landing pages / marketing content:
- **Pure CSR** (React-only SPA) — Google renders but slower, riskier.
- **Hash-routed SPAs** (`/#/page`) — Google ignores everything after #.

Validate with Google Search Console's **URL Inspection Tool** ("Test
live URL") — shows what Googlebot SEES, not what you see.

## Open Graph + Twitter Cards

Social-share preview metadata (also affects search snippets):

```html
<meta property="og:title" content="Page title">
<meta property="og:description" content="Page description">
<meta property="og:image" content="https://example.com/og.png">
<meta property="og:url" content="https://example.com/page">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Acme">

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Page title">
<meta name="twitter:description" content="Page description">
<meta name="twitter:image" content="https://example.com/og.png">
```

OG image: 1200×630px, < 5MB, must be reachable (test in
debugger.facebook.com).

## Core Web Vitals (cross-ref)

LCP < 2.5s, INP < 200ms, CLS < 0.1. Page Experience signal in Google
ranking. See `core_web_vitals` skill.

## Internal linking

Internal links pass authority + help Googlebot discover:

- **Breadcrumbs** on every page.
- **Related-articles** on blog posts.
- **Pillar pages** linking to topic clusters.
- **Footer** has 5-20 high-value links.
- **Anchor text** descriptive, not "click here."

Tools to audit: Screaming Frog, Sitebulb, Ahrefs Site Audit.

## Indexing diagnostics

Google Search Console essentials:
- **Coverage report** — pages indexed / excluded / errors.
- **Performance report** — clicks, impressions, queries.
- **URL Inspection** — per-URL crawl status.
- **Sitemaps** — submitted + processed.
- **Manual actions** — penalties (rare but catastrophic).

Run weekly review.

## AI bot blocking (2025+)

```
User-agent: GPTBot
Disallow: /

User-agent: ClaudeBot
Disallow: /

User-agent: CCBot
Disallow: /

User-agent: anthropic-ai
Disallow: /

User-agent: Google-Extended
Disallow: /
```

Block AI scrapers (OpenAI, Anthropic, Common Crawl, Google AI training)
if you don't want your content in training data. Doesn't block Google
SEARCH indexing — only AI training crawls.

Decision: opt-out IF you have proprietary content; opt-in IF you want
visibility in AI-generated answers (Perplexity, ChatGPT browse).

## Common SEO killers (the audit checklist)

1. `noindex` on important pages (CMS default got copied to prod).
2. Canonical points to a redirect chain.
3. JS-rendered nav links Google never sees.
4. Sitemap has 404s (CMS unpublished but kept in sitemap).
5. Duplicate content via faceted search URLs.
6. No HTTPS / mixed content / cert issues.
7. Pagination misconfigured.
8. Slow Core Web Vitals.
9. Mobile usability fails.
10. Geo-blocking Googlebot (treats Google IP as bot, returns 403).

## Anti-patterns

- **Schema.org spam** — adding markup for content not visible to user.
  Manual penalty risk.
- **Sitemap with 100% pages** including thin / low-value. Dilutes
  signal. Be selective.
- **Canonical that 404s.** Tells Google nothing.
- **Robots blocking CSS / JS.** Google can't render properly.
- **Skipping technical audit pre-launch.** New site index issues take
  months to recover.
- **HSTS without testing**. Can lock out customers in pre-HTTPS browsers.
- **One URL for products in multiple languages**. Use hreflang +
  separate URLs.
- **Generic "About Us" meta description.** Wasted SERP space.

## Validation

- [ ] Sitemap submitted + indexed in GSC.
- [ ] robots.txt allows Google access to all important paths.
- [ ] Canonical on every page.
- [ ] Schema.org for Article, Product, FAQ, BreadcrumbList where
      applicable.
- [ ] Core Web Vitals green on real-user data (CrUX).
- [ ] OG + Twitter cards on every page.
- [ ] No noindex on important pages.
- [ ] HTTPS-only with HSTS.
- [ ] Mobile-friendly per GSC.
- [ ] AI-bot policy explicit (allow or block).
