---
id: accessibility_wcag_2_2_aa
version: 1.0.0
owners: [website_creator, designer, frontend_lead]
tags: [accessibility, a11y, wcag, aria, keyboard, screen-reader, ada-lawsuit]
when_to_use: |
  Every public-facing page. Accessibility isn't a feature, it's the
  floor — 15% of users have a disability, and ADA / EAA lawsuits are
  accelerating. WCAG 2.2 AA is the baseline buyers expect.
inputs:
  - target_compliance, current_audit_results, design_system
outputs:
  - "a11y_baseline: semantic HTML + keyboard + ARIA + contrast + media + tested"
---

# Accessibility — WCAG 2.2 AA

> Accessibility benefits 100% of users 100% of the time. Captions help
> on the noisy train. Keyboard nav helps power users. High contrast
> helps in sunlight. Forget "accessibility = disability"; design for
> every context.

## What WCAG 2.2 AA actually requires

WCAG = Web Content Accessibility Guidelines. Four principles (POUR):

| Principle | Means |
|---|---|
| **Perceivable** | Information available to all senses (or alternatives) |
| **Operable** | Interface usable via keyboard, voice, switch |
| **Understandable** | Clear text, predictable behavior, error handling |
| **Robust** | Compatible with assistive tech (screen readers, etc.) |

Levels: A (minimum), **AA (industry baseline)**, AAA (aspirational, rarely
required for full sites).

**WCAG 2.2** (Oct 2023) adds 9 new success criteria over 2.1. Most-cited
new ones:
- 2.4.11 Focus Not Obscured (minimum)
- 2.5.7 Dragging Movements
- 2.5.8 Target Size (minimum 24×24px)
- 3.3.7 Redundant Entry (don't make users re-type)
- 3.3.8 Accessible Authentication (no cognitive function tests)

## The legal landscape (2026)

- **ADA (US)**: courts treat websites as "places of public accommodation."
  Domino's case (2019) confirmed. Lawsuits up 12% YoY.
- **EAA (EU, June 2025)**: European Accessibility Act mandates WCAG 2.1 AA
  for digital products sold in EU.
- **Section 508 (US gov)**: required for fed contracts.
- **AODA (Ontario, Canada)**: WCAG 2.0 AA mandate.

If you sell to a US company > 50 employees OR any EU company: legal
exposure if you're not WCAG AA.

## Semantic HTML — the foundation

Semantic elements give meaning + free a11y:

```html
<!-- BAD: divs everywhere -->
<div class="header">
  <div class="logo">Acme</div>
  <div class="nav">
    <div onclick="...">Home</div>
  </div>
</div>

<!-- GOOD: semantic + accessible -->
<header>
  <a href="/" aria-label="Acme home">Acme</a>
  <nav aria-label="Main">
    <ul>
      <li><a href="/">Home</a></li>
    </ul>
  </nav>
</header>
```

Use:
- `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>` for landmarks.
- `<button>` for actions (NEVER `<div onClick>`).
- `<a href>` for navigation (NEVER `<div onClick>` for links).
- `<h1>`-`<h6>` in HIERARCHICAL order. One `<h1>` per page.
- `<ul>` / `<ol>` / `<dl>` for lists.
- `<table>` for data, with `<th scope>` for headers.
- `<form>` + `<label>` + `<input>` + `<button>` for forms.

If you find yourself wrapping divs in `role="button"` — you should just
use `<button>`.

## Keyboard navigation

Test: unplug your mouse. Can you USE the entire site?

Requirements:
- **Tab order** follows visual / logical order.
- **Focus visible** (NEVER `outline: none` without replacement).
- **Skip-to-main link** at top: hidden until focused, jumps past nav.
- **Modal dialogs** trap focus inside (and restore on close).
- **Custom widgets** (combobox, accordion, tabs) follow ARIA pattern.

```css
/* Good focus ring */
:focus-visible {
  outline: 2px solid #4f46e5;
  outline-offset: 2px;
  border-radius: 4px;
}

/* Don't kill default unless you replace */
button:focus { outline: 2px solid #4f46e5; outline-offset: 2px; }
```

`:focus-visible` shows ring only on keyboard nav, not mouse click — cleaner
UX for sighted users.

## ARIA — only when HTML isn't enough

The first rule of ARIA: don't use ARIA. Use HTML. ARIA is a fallback.

When you DO need it:

```html
<!-- Disclosure pattern (FAQ expand/collapse) -->
<button aria-expanded="false" aria-controls="faq-1">
  How does pricing work?
</button>
<div id="faq-1" hidden>...answer...</div>

<!-- Live region for status updates -->
<div role="status" aria-live="polite">
  Saved 2 minutes ago
</div>

<!-- Modal -->
<div role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">Confirm delete</h2>
  ...
</div>
```

Reference: WAI-ARIA Authoring Practices (W3C). Don't invent ARIA patterns;
use the documented ones.

## Forms — the most common a11y failure

```html
<!-- BAD: placeholder as label -->
<input type="email" placeholder="Email">

<!-- GOOD: visible label -->
<label for="email">Email address</label>
<input id="email" type="email" autocomplete="email" required
       aria-describedby="email-help">
<small id="email-help">We'll never share your email.</small>

<!-- Error association -->
<input id="email" type="email" aria-invalid="true" aria-describedby="email-error">
<div id="email-error" role="alert">Invalid email format</div>
```

Required attributes:
- `<label for>` ↔ `<input id>` — explicit.
- `autocomplete` (email, name, organization, address-line1, etc.) — works
  with browser autofill + assistive tech.
- `inputmode` (email, tel, numeric, decimal) — mobile keyboard hint.
- `aria-describedby` for help text.
- `aria-invalid="true"` + `role="alert"` for errors.

## Color contrast

WCAG AA: **4.5:1 for body**, **3:1 for large text (≥ 18pt or 14pt bold)**.

Tools:
- WebAIM Contrast Checker.
- Chrome DevTools' color picker (contrast badge).
- Stark (Figma plugin).
- Polypane.

Common failure: gray text. `#999` on `#fff` = 2.85 — FAILS.

For brand colors that fail contrast: use ONLY as decoration, not as
meaningful text. Provide HIGH-CONTRAST alternative for content.

## Images + alt text

```html
<!-- Informative image -->
<img src="chart.png" alt="Revenue grew 40% in Q3 2025">

<!-- Decorative (no info loss if removed) -->
<img src="divider.svg" alt="">

<!-- Functional (in a link/button) -->
<a href="/cart"><img src="cart.svg" alt="Shopping cart"></a>

<!-- Complex (chart, infographic) -->
<figure>
  <img src="complex-chart.png"
       alt="Q3 revenue chart — see description below">
  <figcaption>
    Revenue by quarter: Q1 $1.2M, Q2 $1.5M, Q3 $2.1M, Q4 $2.8M...
  </figcaption>
</figure>
```

Alt text guidelines:
- Convey FUNCTION + CONTEXT, not literal description.
- Don't start with "Image of" — screen readers say that.
- Empty `alt=""` for decorative (not missing alt — empty alt is correct).
- For data viz: provide tabular alternative.

## Video + audio

- **Captions** for video with speech (.vtt file, `<track>` element).
- **Transcript** for audio-only.
- **Audio description** for video where visual carries info.
- **No auto-play with sound** (WCAG 1.4.2).
- **No flashing > 3 times per second** (seizure risk; WCAG 2.3.1).

Tools: rev.com (paid), youtube auto-captions (auto-generate, edit), Trint.

## prefers-reduced-motion

Some users get sick from animations.

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

About 35% of users have this set. Cross-ref `animation_choreography`.

## Touch targets — WCAG 2.5.8 (new in 2.2)

Minimum target size: **24×24 CSS pixels** (Apple HIG suggests 44×44 still).

Apply via padding (not visual size):

```css
button, a.btn {
  min-height: 24px;
  min-width: 24px;
  padding: 12px 20px;
  /* Better: 44×44 to match Apple HIG */
}
```

## Testing tools (use multiple)

| Tool | Catches |
|---|---|
| **axe DevTools** (browser ext) | 50-60% of WCAG issues, automated |
| **WAVE** (browser ext) | Similar coverage, different presentation |
| **Lighthouse a11y** | 30-40% issues, integrates in CI |
| **Pa11y** | CLI-based, CI-friendly |
| **Stark / Polypane** | Designer-friendly |
| **Manual keyboard test** | Catches what tools can't |
| **Screen reader test** | VoiceOver (Mac), NVDA (Windows free), JAWS |
| **User testing with disabled users** | The real gold standard |

Run automated on EVERY PR; manual screen reader test quarterly.

## Common WCAG 2.2 AA failures to audit

- Insufficient color contrast (≥ 30% of sites).
- Missing alt text on images.
- Form inputs without labels.
- Broken or missing focus indicators.
- Inaccessible custom components (carousels, dropdowns, modals).
- Click-only interactions (no keyboard).
- Auto-playing media.
- Wrong heading hierarchy (h1 → h4, skipping h2/h3).
- `<div onclick>` instead of `<button>`.
- Empty links / buttons (icon-only without label).

## Anti-patterns

- **Overlay widget claiming "WCAG compliance"** (accessiBe, UserWay).
  They DON'T fix underlying issues; ADA lawsuits still apply; community
  considers them harmful.
- **`outline: none`** without replacement.
- **Color as the ONLY indicator** (e.g. red text = error). Add icon or
  text.
- **Placeholder as label.** Disappears on focus, screen readers ignore.
- **Auto-advancing carousel.** Keyboard users can't pause.
- **Modal without focus trap.** Tab escapes to background.
- **Click outside to close** (mobile users have nowhere outside).
- **Cookie banner with no keyboard escape.** Users locked out of site.
- **ARIA on top of broken HTML.** Doubles complexity, doesn't help.

## Validation

- [ ] axe DevTools clean on every key page.
- [ ] Lighthouse a11y score ≥ 95.
- [ ] Manual keyboard nav covers full user journeys.
- [ ] Screen reader test (VoiceOver / NVDA) passes for top 5 user flows.
- [ ] All images have appropriate alt text.
- [ ] Forms have visible labels + autocomplete attrs.
- [ ] Color contrast ≥ 4.5:1 for body text.
- [ ] prefers-reduced-motion respected.
- [ ] Captions on all videos with speech.
- [ ] Recent VPAT or accessibility statement published.
