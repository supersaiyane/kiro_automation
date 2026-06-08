---
id: seo_foundations
version: 1.0.0
owners: [website_creator]
tags: [seo, search, technical-seo, structured-data, web-performance]
when_to_use: |
  Building the marketing site, choosing a CMS / framework, or
  diagnosing why traffic isn't growing. The technical layer either
  makes or breaks all the content effort.
inputs:
  - site_architecture, content_inventory
outputs:
  - seo_audit: technical health + content gaps + ranking blockers
---

# Technical SEO Foundations

## The hierarchy that matters

Most "SEO" effort is wasted on content tweaks while the technical
foundation is broken. Fix in this order:

1. **Crawlability** — Google can find your pages.
2. **Indexability** — Google decides they're worth indexing.
3. **Renderability** — Google sees the content (JS-heavy sites trip
   here).
4. **Performance** — fast pages rank better; Core Web Vitals matter.
5. **Structured data** — gets you rich results, voice surfaces.
6. **Content quality** — finally; the part most articles obsess over.

## Crawlability — the basics

- **`/sitemap.xml`** listing every important URL with lastmod dates.
  Submit to Google Search Console + Bing Webmaster Tools.
- **`/robots.txt`** that DOESN'T accidentally block what you want
  indexed. Disallow patterns get copy-pasted from the wrong template
  routinely.
- **Internal linking** — every important page reachable in ≤3 clicks
  from the homepage.
- **Canonical URLs** — `<link rel="canonical">` on every page,
  resolving duplicate content (with/without trailing slash, query
  parameters, paginated lists).
- **No infinite spaces** — calendars, faceted filters, session IDs
  in URLs create infinite crawl space. Block in robots.txt or use
  `rel=nofollow`.

## Indexability gotchas

- `noindex` accidentally left on production from a staging template.
  Check on launch and re-check after any CMS change.
- 4xx / 5xx errors on important pages. Pull a crawl report monthly.
- Soft 404s — the page returns 200 with "not found" content. Worse
  than a real 404; Google can't tell.
- Thin pages (<300 words) on a content-heavy site get crowded out.
  Consolidate or expand.
- **Pagination** done wrong — `?page=2` without proper rel=prev/next
  (deprecated by Google but still helpful as a hint) and canonical to
  the first page. Easiest: load more on scroll (single canonical URL)
  for non-critical lists.

## Renderability — the JS trap

Google's crawler renders JavaScript, but with two caveats:
- **Two-pass indexing**: first pass = raw HTML; second pass = post-JS
  render, sometimes days later.
- **Failures**: if JS errors, the page may stay on the first-pass
  HTML (often empty in an SPA).

The fix: **server-side rendering (SSR) or static generation (SSG)**
for content pages. Next.js, Astro, Nuxt — all support this. The
homepage, marketing pages, blog posts must NOT depend on client-side
hydration to be readable.

Test: `curl https://yoursite/ | grep "your hero headline"`. If
nothing comes back, neither does Google's first pass.

## Structured data (schema.org) — the rich-results layer

Add JSON-LD blocks to enable rich results:

- **Organization** — logo, name, social profiles. Knowledge panel
  data.
- **Article** — blog posts; gets you the publication date + author.
- **Product** — price + availability + reviews → rich snippets in
  shopping.
- **FAQ** — gets the expandable FAQ panel; significant CTR lift.
- **BreadcrumbList** — replaces the URL in SERP with breadcrumbs.
- **HowTo** — step-by-step rich result.

Validate with the **Rich Results Test** before deploying.

## Core Web Vitals are a ranking signal

(See skill: `core_web_vitals` in fe_lead/ for the engineering side.)

What the marketing site cares about:
- LCP ≤ 2.5s p75
- INP ≤ 200ms p75
- CLS ≤ 0.1 p75

Below thresholds → Google ranks competitors over you, even with equal
content. Measure in real-user-monitoring (RUM), not just Lighthouse.

## Internationalization

If you have non-English markets:
- `hreflang` tags pointing each version to its peers.
- One URL pattern per locale: `/en/`, `/es/`, `/fr/` (subdirectory) or
  separate ccTLDs. Stick to one strategy; mixing is hard to debug.
- Translated content, not auto-translated. Google detects and
  penalizes machine translation in some categories.

## The keyword research minimum

- Use Google Search Console for your existing-rank keywords. Free,
  accurate.
- Use a tool (Ahrefs, SEMrush, Mangools) for competitive gap analysis.
- Target intent, not just volume. "How to do X" = informational.
  "Best X tool" = commercial intent (closer to conversion).
- One primary keyword per page; don't try to rank one page for ten
  keywords.

## Anti-patterns

- "SEO is a content problem" — it's a technical problem first.
- Building a content site as an SPA with no SSR. Hidden from Google
  on first pass.
- `noindex` in production by accident. Check after every deploy.
- Keyword stuffing. Modern Google penalizes; readers leave.
- Duplicate content across subdomains, locales, www-vs-bare,
  http-vs-https. Pick canonicals.
- 301 redirects in chains (A → B → C → D). Each hop loses link
  equity. One hop max.
- Buying backlinks. Manual penalty risk; recovery is a years-long
  fight.
- "We'll get to SEO after launch." After launch, you're competing
  against pages indexed and ranked for months. Set up the foundation
  before traffic starts.
