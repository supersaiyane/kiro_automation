---
id: responsive_design_mobile_first
version: 1.0.0
owners: [website_creator, frontend_lead, designer]
tags: [responsive, mobile-first, css, container-queries, fluid-typography, breakpoints]
when_to_use: |
  Building any marketing site, landing page, or product surface that
  customers visit on a phone. 60%+ of B2C traffic is mobile in 2026;
  even B2B trends > 40%. Mobile-first stops being a buzzword and
  starts being the only way to ship.
inputs:
  - traffic_breakdown, content_density, design_system
outputs:
  - "responsive_design: breakpoint system + fluid type + container queries + image strategy"
---

# Responsive Design — Mobile-First in 2026

> Design for the 360px viewport first; expand. Most "doesn't work on
> mobile" bugs ship because designers + devs work on 27" monitors and
> only check mobile last. Flip the order.

## The 2026 viewport landscape

| Device class | Width range | What to anticipate |
|---|---|---|
| Phone portrait | 320-430px | Small CTAs, vertical stack, sticky nav |
| Phone landscape | 568-915px | Less common; design as tablet portrait |
| Tablet portrait | 768-834px | Two-column starts to work |
| Tablet landscape / small laptop | 1024-1280px | Multi-column, full nav |
| Laptop / desktop | 1280-1920px | The "design comp" sweet spot |
| Wide / 4K | 1920-3840px | Constrain content width (max-w-7xl) |
| Foldable / split-screen | unpredictable | Container queries to the rescue |

## Breakpoint system

Tailwind's defaults (`sm:640px, md:768px, lg:1024px, xl:1280px, 2xl:1536px`)
work for ~90% of cases. Customize ONLY if you have a specific design need.

```html
<!-- Mobile first: default classes are 360-639px -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  ...
</div>
```

Don't write desktop-first with `max-width` media queries. Mobile-first
with `min-width` is more maintainable.

## Fluid typography

`clamp()` makes type scale smoothly between breakpoints:

```css
/* Headline: 24px at 360px viewport, 72px at 1440px */
h1 {
  font-size: clamp(1.5rem, 5vw, 4.5rem);
  line-height: 1.05;
  text-wrap: balance;        /* CSS Text Module 4 */
}

/* Body: 16px → 20px */
p {
  font-size: clamp(1rem, 1.5vw, 1.25rem);
  line-height: 1.6;
  max-width: 65ch;           /* readable line length */
  text-wrap: pretty;         /* avoid orphans */
}
```

Avoid font-size in `px` for body text. `rem` lets users override.

## Container queries — the 2024+ tool

Media queries respond to VIEWPORT; container queries respond to PARENT
size. Solves "this card needs to look different in the sidebar vs main."

```css
.card-container {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 400px) {
  .card-content {
    display: grid;
    grid-template-columns: auto 1fr;
  }
}
```

Tailwind v3.2+ has `@container` plugin. Safari + Chrome + Firefox shipped
mid-2023; baseline-supported in 2026.

## Grid + flex — when to use which

| Use case | Tool |
|---|---|
| 2D layout (rows AND columns) | CSS Grid |
| 1D layout (just rows OR columns) | Flexbox |
| Marketing card grid | Grid (`auto-fit, minmax(280px, 1fr)`) |
| Header with logo + nav | Flexbox |
| Pricing tiers | Grid |
| Form rows | Grid (`grid-template-columns: 1fr auto`) for label + input |

```css
/* Auto-responsive grid — no media queries needed */
.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: clamp(1rem, 2vw, 2rem);
}
```

## Touch targets

Apple HIG: 44×44pt minimum. Material: 48dp. Real-world: 48px square is
the safe floor.

```css
button, a.btn, .nav-item {
  min-height: 44px;
  min-width: 44px;
  padding: 12px 20px;
}
```

Increase tap-area without making elements VISUALLY bigger via `padding`
or `::before { padding }` tricks.

## Mobile nav patterns

| Pattern | When |
|---|---|
| Bottom tab bar | App-feeling, max 4-5 destinations |
| Hamburger | Sites with 10+ destinations; expected pattern |
| Bottom-sheet menu | Modern alternative to hamburger |
| Sticky top nav with logo | Simple sites with 3-5 destinations |
| Off-canvas drawer | Authenticated app surfaces |

Hamburger anti-pattern: hides nav, kills discovery. Use only when count
demands it.

For marketing site: sticky transparent → solid on scroll, with a focused
CTA visible at all viewports.

## Images — different formats per viewport

```html
<picture>
  <source media="(max-width: 768px)"
    srcset="hero-mobile.avif 1x, hero-mobile@2x.avif 2x"
    type="image/avif">
  <source media="(min-width: 769px)"
    srcset="hero-desktop.avif 1x, hero-desktop@2x.avif 2x"
    type="image/avif">
  <img src="hero-desktop.jpg" alt="..."
    width="1920" height="1080"
    loading="lazy" decoding="async">
</picture>
```

- `srcset` for resolution density.
- `media` for art direction (different crop on mobile vs desktop).
- `loading="lazy"` for non-LCP images.
- `width` + `height` to PREVENT CLS (cumulative layout shift).

See `image_video_optimization` for the deeper pass.

## Viewport meta — get this right or nothing else helps

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

NEVER:
- `user-scalable=no` — breaks accessibility.
- `maximum-scale=1.0` — same.

## Common mobile pitfalls

- **Horizontal scroll** on phone — usually a fixed-width element. Find via
  Chrome DevTools "Responsive" mode.
- **iOS Safari 100vh bug** — vh doesn't account for browser chrome. Use
  `100dvh` (dynamic viewport height) or JS workaround.
- **Sticky positioning + transforms** — `position: sticky` breaks inside a
  parent with `transform`. Restructure.
- **Click delay** — 300ms click delay is gone since 2017 if viewport meta
  is set, but legacy reports still circulate.
- **Tap highlight blue flash** — `-webkit-tap-highlight-color: transparent;`
  to remove; replace with explicit `:active` state.
- **Forms zoom-on-focus** — iOS zooms if input font-size < 16px. Set ≥ 16px.

## Testing

| Tool | Use |
|---|---|
| Chrome DevTools "Responsive" | Quick check, 90% of issues |
| BrowserStack / LambdaTest | Real-device cloud |
| Local devices | Your own phone + tablet, dogfood |
| Lighthouse mobile profile | Performance + a11y |
| Real-User Monitoring (RUM) | Production data on actual devices |

ALWAYS test on a budget Android (e.g. Pixel 6a, Galaxy A14) — not just the
latest iPhone. Performance gap is 5-10×.

## Anti-patterns

- **Designed for desktop only**, then "responsive-ified." Mobile becomes
  worst-of-both-worlds.
- **`px` for everything** including type. Breaks user font preferences.
- **Hover-only interactions**. No hover on touch; provide tap equivalent.
- **Fixed-height containers** for variable content. Overflow + clipping.
- **Hidden mobile content** via `display: none`. Often broken expectations
  (e.g. hidden nav-link); a11y issues.
- **Viewport-locked zoom**.
- **Heavy hero videos that autoplay on mobile.** Eats battery + bandwidth.
- **Carousels as primary nav** — abandoned by 95% on mobile.
- **Inline forms with no input mode hints.** Use `inputmode`, `autocomplete`
  for better keyboards.

## Validation

- [ ] First impression on 360px portrait is usable (test on real budget
      phone).
- [ ] No horizontal scroll on any tested viewport.
- [ ] Touch targets ≥ 44×44.
- [ ] Type readable without zoom (≥ 16px body).
- [ ] LCP image has explicit `width` + `height`.
- [ ] Forms use `inputmode` + `autocomplete` for mobile keyboards.
- [ ] All hover interactions have a tap equivalent.
- [ ] Lighthouse mobile score > 85 (perf + a11y).
