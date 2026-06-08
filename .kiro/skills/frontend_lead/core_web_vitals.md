---
id: core_web_vitals
version: 1.0.0
owners: [frontend_lead, senior_engineer_fe]
tags: [performance, lcp, inp, cls, lighthouse, web-vitals]
when_to_use: |
  Any page that users see. Performance is a feature; below-threshold
  vitals hurt SEO ranking, conversion, and retention measurably.
  Track in CI; budget like you'd budget money.
inputs:
  - page_under_test: production or staging URL
outputs:
  - vitals_report: LCP / INP / CLS per-page; budgets; remediation list
---

# Core Web Vitals (CWV)

Three metrics, **measured at the 75th percentile of real users** (not
synthetic Lighthouse):

| Metric | "Good" threshold | What it measures |
|---|---|---|
| **LCP** (Largest Contentful Paint) | ≤ 2.5 s | Time until the biggest above-the-fold element renders |
| **INP** (Interaction to Next Paint) | ≤ 200 ms | Slowest interaction-response over the visit (replaced FID in 2024) |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | Visual stability — sum of unexpected layout shifts |

## LCP — what actually moves it

1. **Server response time** (TTFB) > 0.6s ruins LCP before the browser
   draws a pixel. Fix on the server or with a CDN.
2. **Render-blocking resources** — synchronous CSS and JS in `<head>`.
   Inline critical CSS, defer the rest.
3. **The LCP element itself.** Hero image, hero text, big card.
   - Image? Serve `<img loading="eager" fetchpriority="high"` + WebP
     + responsive `srcset` + correct width/height attributes.
   - Above-the-fold images NEVER `loading="lazy"`.
4. **JavaScript that delays the paint.** Hydration heavy? Stream
   server-rendered HTML; hydrate progressively.

Diagnostic: in Chrome DevTools → Performance → identify the LCP frame
→ trace what's blocking it.

## INP — interactions feel slow because the main thread is busy

INP = the slowest interaction's response time. To improve:

- **Break up long tasks.** Any task >50ms on the main thread is a
  block. Use `scheduler.yield()`, `setTimeout`, or `requestIdleCallback`.
- **Defer hydration** of non-critical components (modals, footers).
- **Memoize render-heavy components.** `React.memo`, `useMemo`,
  `useCallback` — but only when measurement shows the cost.
- **Web workers for heavy compute.** Don't parse 5MB JSON on the main
  thread.
- **Watch out for third-party scripts.** A single misbehaving analytics
  tag can blow INP for the whole page.

## CLS — layout shift sources, in order of frequency

1. **Images without dimensions.** Always set `width` and `height`
   (or CSS aspect-ratio).
2. **Web fonts FOUT/FOIT.** Use `font-display: optional` or pre-load
   the font with `<link rel="preload">`.
3. **Ads and embeds** without reserved space. Reserve the container.
4. **Dynamically injected content above existing content** (e.g.
   cookie banner pushing content down). Either insert below or use
   a sticky overlay.

## Performance budget

Set a budget per page-type. Block PRs that exceed it.

```yaml
# performance-budget.yml
homepage:
  lcp_ms: 2500
  inp_ms: 200
  cls: 0.1
  total_js_kb: 170      # gzipped
  total_css_kb: 60
  total_img_kb: 500
  third_party_requests: 5
product_listing:
  lcp_ms: 2800
  total_js_kb: 220
  ...
```

Enforce via Lighthouse CI in PR checks. If the budget breaks, a
discussion happens before merge — not a quarterly cleanup.

## Real-user monitoring (RUM) vs. lab

- **Lab** (Lighthouse, WebPageTest): controlled, repeatable, great for
  *catching* regressions in CI.
- **RUM** (web-vitals lib, Google's CrUX dataset): the only thing that
  reflects actual users. Their device, their network, their region.

**Optimize for RUM p75, not Lighthouse score.** A 95 Lighthouse score
on a $2,000 dev laptop says nothing about the user on a 3-year-old
Android in a subway.

## Image performance — the cheat sheet

- WebP or AVIF — 30-50% smaller than equivalent JPEG.
- Responsive: `<img srcset="...300w, ...600w, ...1200w" sizes="...">`.
- `loading="lazy"` for below-fold; `"eager"` for above-fold.
- Set explicit `width` and `height` attributes — prevents CLS.
- Self-host critical hero images; CDN the rest.

## Anti-patterns

- "We rely on Lighthouse." Run it once a sprint and forget. The
  median user has worse hardware than your dev box.
- Bundling everything into one JS chunk. Code-split by route.
- Web fonts loaded synchronously, FOIT for 500ms. Use
  `font-display: swap` (with size-adjust to prevent CLS).
- Lazy-loading the hero image because lazy-loading "is good". The
  hero is *exactly* the wrong place for it.
- Polyfills shipped to modern browsers. Use `module/nomodule` to
  serve modern bundles to modern browsers.
- "Performance is the platform team's job." It's the FE Lead's. The
  platform sets up the rails; the FE is the one driving the train.
