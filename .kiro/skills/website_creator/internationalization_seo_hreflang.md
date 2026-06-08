---
id: internationalization_seo_hreflang
version: 1.0.0
owners: [website_creator, frontend_lead]
tags: [i18n, l10n, hreflang, rtl, localization, multi-region]
when_to_use: |
  Targeting more than one language or region. Done correctly: search
  engines route users to the right locale; users land on content in
  their language. Done poorly: SEO penalties, lost users, broken layout.
inputs:
  - target_locales, content_volume, translation_workflow
outputs:
  - "i18n_plan: URL strategy + hreflang + translation + rtl + region detection"
---

# Internationalization, Localization, hreflang

> Translation is the smallest part. The HARD parts are URLs that
> search engines understand, layouts that work in RTL, currency /
> date / number formats that feel native, and translation workflows
> that don't grind to a halt.

## i18n vs l10n vs g11n

- **i18n** (internationalization): engineering — code ready to handle any
  locale.
- **l10n** (localization): translation + adaptation per locale.
- **g11n** (globalization): the business strategy.

Engineering does i18n once. Localization is ongoing per locale.

## URL strategy — pick one

| Strategy | Example | SEO impact | When |
|---|---|---|---|
| **Subdirectory** | `/fr/`, `/de/`, `/en/` | Strongest (single domain authority) | Default for SaaS |
| **Subdomain** | `fr.example.com`, `de.example.com` | OK; treated as separate sites | Multi-region orgs |
| **ccTLD** | `example.fr`, `example.de` | Strong local signal but separate domains | E-com with logistics per country |
| **Query param** | `?lang=fr` | Weakest; avoid | Don't use |

For most SaaS: SUBDIRECTORIES. SEO juice consolidated; one cert, one CDN
config.

## hreflang — tell Google which language for which user

```html
<head>
  <link rel="alternate" hreflang="en"      href="https://example.com/en/page">
  <link rel="alternate" hreflang="en-us"   href="https://example.com/en-us/page">
  <link rel="alternate" hreflang="en-gb"   href="https://example.com/en-gb/page">
  <link rel="alternate" hreflang="fr"      href="https://example.com/fr/page">
  <link rel="alternate" hreflang="de"      href="https://example.com/de/page">
  <link rel="alternate" hreflang="x-default" href="https://example.com/en/page">
</head>
```

Rules:
- Self-referencing entry MANDATORY (each page lists itself).
- `x-default` for users with no match (usually English).
- Use ISO 639-1 (`fr`) or 639-1 + 3166-1 alpha 2 (`fr-FR`).
- Bidirectional: pages must link TO EACH OTHER.
- Sitemap can declare hreflang instead of in-page link (cleaner at scale).

Common bugs (most sites get this wrong):
- One-way links (en page links to fr, but fr doesn't link back).
- Invalid codes (`hreflang="fr-FR"` is OK, but `hreflang="france"` is not).
- Missing self-reference.
- Pointing all alternates to /en/ (defeats purpose).

Validate: SEMrush, Ahrefs, Screaming Frog all check hreflang.

## Language detection — server vs client

Server-side (recommended):
- Read `Accept-Language` header.
- Match to supported locales (fallback chain: `fr-CA` → `fr` → `en`).
- 302 redirect to `/fr/` from `/` (with cookie to remember preference).
- Honor explicit user choice via cookie / URL.

Client-side:
- JavaScript checks `navigator.language` + falls back.
- Less SEO-friendly; render-blocking; bots see original URL.

Hybrid: server-side detection + visible language switcher.

## Language switcher

```html
<details>
  <summary>🌐 English</summary>
  <ul>
    <li><a href="/en/pricing" hreflang="en">English</a></li>
    <li><a href="/fr/pricing" hreflang="fr">Français</a></li>
    <li><a href="/de/pricing" hreflang="de">Deutsch</a></li>
    <li><a href="/ja/pricing" hreflang="ja">日本語</a></li>
  </ul>
</details>
```

Best practices:
- Show language name in the language ITSELF ("Deutsch" not "German").
- Place in footer (mostly) or top-right (some sites).
- Persistent across pages (cookie).
- Allow ALL locales, not just current page's translations.

## Translation workflow

```
Source (English content) → Translation Memory (TM) tool → Translators → Reviewed → CMS
```

Tools:
- **Lokalise / Phrase / Crowdin** — TM, glossary, machine-translation
  pre-fill, reviewer workflow.
- **GitHub + JSON files** — for small / dev-heavy teams.
- **CMS native** (Storyblok, Contentful) — works for site copy; less for
  product strings.

Use TM: same phrase translated once, reused everywhere → consistency +
cost savings.

Workflow:
1. Source-language change committed.
2. Translation task auto-created for each locale.
3. Pre-fill from TM + machine translation.
4. Human translator refines.
5. Reviewer approves.
6. Publish triggers site rebuild.

## RTL (Arabic, Hebrew, Persian, Urdu)

```html
<html lang="ar" dir="rtl">
```

CSS Logical Properties make RTL automatic:

```css
/* Old way (broken in RTL) */
.card { margin-left: 16px; padding-right: 24px; }

/* New way (flips automatically) */
.card { margin-inline-start: 16px; padding-inline-end: 24px; }
```

| Old | Logical equivalent |
|---|---|
| margin-left | margin-inline-start |
| margin-right | margin-inline-end |
| padding-left | padding-inline-start |
| left: 0 | inset-inline-start: 0 |
| text-align: left | text-align: start |

Things to flip manually:
- Icons with direction (→, arrows). Use mirror-image or RTL-aware icons.
- Image carousels (swipe direction).
- Number formatting (mostly handled by `Intl.NumberFormat`).

## Number, date, currency formatting

NEVER hardcode. Use `Intl`:

```js
const price = new Intl.NumberFormat('de-DE', {
  style: 'currency', currency: 'EUR'
}).format(99);
// → "99,00 €"

const date = new Intl.DateTimeFormat('ja-JP', {
  dateStyle: 'long'
}).format(new Date());
// → "2026年5月27日"

const relative = new Intl.RelativeTimeFormat('fr', {numeric: 'auto'});
relative.format(-1, 'day');  // → "hier"
```

Server-side: same APIs in Node.js. Python: babel.

## Pluralization

English has 2 plural forms (1, > 1). Arabic has 6. Polish has 3.

```js
// Don't:
text = `${count} ${count === 1 ? 'item' : 'items'}`;

// Do (uses Unicode CLDR rules):
const fmt = new Intl.PluralRules('pl');
const form = fmt.select(count); // 'one' / 'few' / 'many' / 'other'
// translation file has all forms:
//   one:   "{count} przedmiot"
//   few:   "{count} przedmioty"
//   many:  "{count} przedmiotów"
text = T[form].replace('{count}', count);
```

i18n libs (i18next, react-intl, FormatJS) handle this for you.

## Content adaptation beyond translation

Some content needs MORE than translation:
- **Currency**: prices in local currency.
- **Phone numbers**: format per country.
- **Addresses**: field order, postcode position.
- **Date formats**: MM/DD vs DD/MM vs YYYY-MM-DD.
- **Examples / case studies**: regional customers.
- **Legal**: GDPR notice for EU; CCPA for CA; LGPD for BR.
- **Imagery**: cultural sensitivity (gestures, attire, gestures).
- **Idioms**: "knocked it out of the park" → meaningless in non-baseball
  countries.

## SEO per locale

- **Translate URLs** (not always — depends on locale-specific search).
  `/fr/produit` vs `/fr/product`.
- **Translate meta tags** (`title`, `description`, `og:title`).
- **Local backlinks** for local SEO.
- **Submit per-locale sitemaps** to Google.
- **Schema.org localized** (`inLanguage`, `availableLanguage`).

## Geo-restrictions + region-specific features

Beyond language, REGIONS may differ in:
- Features available (e.g. crypto features banned in some regions).
- Compliance content (cookie banner verbiage).
- Currency / payment methods.
- Customer support hours.

Use `Accept-Language` + IP geolocation (CloudFlare, MaxMind) for routing.

## Anti-patterns

- **Auto-redirect by IP without user choice.** Frustrating for travelers,
  expats, VPN users. Detect + suggest, don't force.
- **Mixing locales on same page** (translated nav, English body).
- **No hreflang.** Google may pick wrong locale.
- **Hardcoded English strings** in code. Hard to extract for translation.
- **Translation as afterthought.** Better to design with i18n from day 1.
- **`Intl` API not used** — locale-specific formatting broken.
- **RTL via `direction: rtl` on `<html>` only** — no logical-property CSS,
  layouts break.
- **Same images in every locale.** Cultural mismatches.
- **Pricing in USD only.** Friction.
- **`navigator.language` blindly trusted.** Often default OS lang, not user
  preference.

## Validation

- [ ] Subdirectory URLs for each locale.
- [ ] hreflang implemented + validated (bidirectional, self-ref).
- [ ] Language switcher accessible in footer + top.
- [ ] All formatting via `Intl` API.
- [ ] Logical CSS properties used (margin-inline-start, etc.).
- [ ] Translation workflow live (TM + machine pre-fill + human review).
- [ ] RTL tested on Arabic / Hebrew.
- [ ] Date / number / currency tested in 3+ locales.
- [ ] Per-locale sitemaps submitted to Google.
- [ ] Cookie banner localized per region.
