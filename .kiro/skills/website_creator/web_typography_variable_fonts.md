---
id: web_typography_variable_fonts
version: 1.0.0
owners: [website_creator, designer]
tags: [typography, web-fonts, variable-fonts, fout, foit, font-display]
when_to_use: |
  Every site that uses custom fonts. Typography choices land in 90% of
  marketing-site decisions; getting font loading right separates a fast
  brand from a CLS-broken one.
inputs:
  - brand_typeface, glyph_set_needed, performance_budget
outputs:
  - "typography_system: scale + weights + variable-font config + loading strategy + fallbacks"
---

# Web Typography + Variable Fonts

> Type is brand. But web fonts are the second-biggest performance
> cost after images. Variable fonts + smart loading let you ship the
> brand without paying the perf tax.

## Type system fundamentals

Per project, define:

```
Scale:         12 / 14 / 16 / 18 / 20 / 24 / 32 / 48 / 72 (modular)
Body:          16-18px, line-height 1.5-1.7, max-w 65ch
Headings:      24/32/48/72, line-height 1.05-1.25, tight tracking
Weights:       regular 400, medium 500, semibold 600, bold 700
Style scale:   x-large display / large h1 / h2 / h3 / body / caption / micro
```

Tokenize in CSS variables or Tailwind config; reference everywhere.

## Variable fonts — pay once, get every weight

Static fonts: one file per weight + style. A site using regular, italic,
medium, semibold, bold = 5+ files = 200-500 KB.

Variable fonts: ONE file with axes (weight, width, slant). 60-80 KB total
for the same range.

```css
@font-face {
  font-family: 'Inter';
  src: url('/fonts/Inter.var.woff2') format('woff2-variations');
  font-weight: 100 900;       /* range */
  font-display: swap;
}

/* Use any weight in range */
h1 { font-weight: 750; }
.balanced { font-weight: 425; }
```

Default variable fonts to consider (2026):
- **Inter** — UI workhorse, free, 100-900 + italics.
- **Geist** — Vercel's, free, opinionated geometric.
- **Geist Mono** — code companion.
- **JetBrains Mono** — code.
- **Manrope** — modern geometric.
- **Public Sans** — US gov-derived, neutral.
- **Crimson Pro** — serif.
- **Inter Display / Tight** — Inter optimized for headings.

For brand work: **commission a variable font** from a foundry (Klim,
Pangram Pangram, Grilli Type, OHno).

## font-display — the FOIT/FOUT decision

| Value | Behavior | Use |
|---|---|---|
| `auto` | Browser default (usually block) | Don't |
| `block` | Hide text up to 3s, then fallback | Block-feeling brands |
| `swap` | Show fallback immediately, swap when ready | **Default** for most |
| `fallback` | Brief block, then fallback if not ready quickly | Mid-priority |
| `optional` | Use only if cached on first paint | Performance-critical |

For marketing sites: `swap`. Users see content fast; brand font swaps in.

```css
@font-face {
  font-family: 'BrandFont';
  src: url('/fonts/brand.woff2') format('woff2-variations');
  font-display: swap;
}
```

To minimize FOUT JANK: choose fallback that closely matches the brand font's
metrics (x-height, advance width).

## size-adjust + ascent-override — kill FOUT shift

```css
@font-face {
  font-family: 'BrandFont';
  src: url('/fonts/brand.woff2') format('woff2-variations');
  font-display: swap;
  size-adjust: 102%;          /* tune to match fallback metrics */
  ascent-override: 90%;
  descent-override: 20%;
  line-gap-override: 0%;
}

@font-face {
  font-family: 'BrandFont fallback';
  src: local('Arial');
  size-adjust: 99%;
  ascent-override: 91%;
}

body {
  font-family: 'BrandFont', 'BrandFont fallback', Arial, sans-serif;
}
```

Tool: Malte Ubl's font fallback tool (vercel/fontslogic), Iconfont.

Result: ZERO layout shift on swap. Industry-leading.

## Preload critical fonts

In `<head>`:

```html
<link rel="preload"
      href="/fonts/Inter.var.woff2"
      as="font"
      type="font/woff2"
      crossorigin>
```

Loads the font in parallel with HTML parse → ready when CSS needs it →
no FOUT delay.

ONLY preload the FONTS USED ABOVE THE FOLD. Don't preload the italic if
hero text isn't italic.

## Subsetting

Default fonts ship ALL glyphs (sometimes 1000+). For a Latin-only site,
that's wasted bytes.

```bash
# Subset to Latin Basic + Latin Supplement
glyphhanger https://yoursite.com --formats=woff2 --subset='*'
```

Or use Google Fonts API which subsets per-page.

A 200 KB font becomes 60 KB after subsetting to Latin only.

## Hosting fonts

| Option | Pros | Cons |
|---|---|---|
| **Self-host on CDN** | Fast, GDPR-clean (no third-party requests), preload-able | Manage versions yourself |
| **Google Fonts** | Free, easy | Third-party request; some EU concerns post-Schrems II |
| **Bunny Fonts** | EU-hosted Google Fonts proxy, GDPR-friendly | Vendor risk |
| **Adobe Fonts** | Excellent libraries, paid | Subscription, JS loader by default |
| **Foundry direct** | Commercial license, latest variants | $$$ |

For most pro sites: **self-host on the same CDN as your site**. Fastest +
no privacy concerns + preload works perfectly.

## Performance budget

| Asset | Budget |
|---|---|
| Total font weight | < 100 KB |
| Above-fold fonts | < 50 KB |
| Font files preloaded | ≤ 2 |
| Variable font axes used | ≤ 3 (weight, italic, optional optical-size) |

Track via Lighthouse + WebPageTest.

## Readability — line length + leading

- **Line length**: 45-75 characters / 65ch baseline. Wider = harder
  to track lines.
- **Leading**: 1.4-1.7 for body. Tighter for headings (1.05-1.25).
- **Justify**: avoid on web (rivers + uneven spacing). Use `text-wrap: pretty`
  (Chrome 117+, Safari 17.4+) for balanced ragged-right.
- **Tracking** (letter-spacing): slight negative on large display type
  (`-0.02em`); slight positive on small all-caps (`0.05em`).
- **Hyphens**: `hyphens: auto;` for justified or narrow columns.

## Color contrast — accessibility floor

WCAG 2.2 AA: 4.5:1 for body, 3:1 for large text (18pt+ or 14pt+ bold).

Check: WebAIM contrast checker, Stark, Polypane.

Common failure: gray on white. `#999` on `#fff` is 2.85:1 — FAILS.

## Pairings — when to mix typefaces

- **Sans + sans** (Inter + Manrope): subtle hierarchy, modern.
- **Serif + sans** (Crimson + Inter): classical, editorial feel.
- **Sans + mono** (Inter + JetBrains Mono): tech / SaaS.
- **Display + sans** (specialty heading + Inter body): brand emphasis.

Don't mix three. Two typefaces with multiple weights covers everything.

## Numeral handling

- **Tabular numerals**: `font-variant-numeric: tabular-nums;` for tables,
  prices, monospace alignment.
- **Old-style figures**: for editorial; sit on the baseline naturally.
- **Lining figures**: caps-height, default in most UI fonts.

```css
.pricing-amount { font-variant-numeric: tabular-nums lining-nums; }
```

## Internationalization

If you'll ship non-Latin: plan early.

- **Chinese / Japanese / Korean (CJK)**: ~3 MB per weight. Use a different
  font OR subset by language.
- **Arabic / Hebrew**: RTL flow; verify your fonts include glyph set.
- **Devanagari, Cyrillic, Greek**: ensure your typeface SUPPORTS them; not
  all do.

Use `lang` attribute on `<html>` and per-block; CSS `:lang()` to swap fonts.

## Anti-patterns

- **5 different font weights, all loaded.** Pick 2-3.
- **Pulling fonts from foundry CDN** with render-blocking CSS.
- **No `font-display`**, defaulting to `block` → invisible text 3 seconds.
- **No preload** → FOUT on every page.
- **Mixing 3+ typefaces** for "variety." Looks confused.
- **Font-size in `px`** for body text (overrides user preferences).
- **No tabular nums for pricing tables.** Misalignment.
- **Loading italics + bold of a font you only use regular of.**
- **Centered body text.** Hard to read.

## Validation

- [ ] Font weight total < 100 KB.
- [ ] Variable fonts used where possible.
- [ ] `font-display: swap` set; no FOIT.
- [ ] Above-the-fold font preloaded with `crossorigin`.
- [ ] Fallback metrics overridden to prevent CLS on swap.
- [ ] Body line length 45-75 characters.
- [ ] Contrast ≥ WCAG AA on all text.
- [ ] Tabular nums on prices + data tables.
- [ ] Lighthouse perf > 90 on mobile.
