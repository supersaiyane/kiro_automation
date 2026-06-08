---
id: cookie_consent_privacy_ux
version: 1.0.0
owners: [website_creator, legal, security_engineer]
tags: [cookie-consent, gdpr, ccpa, cmp, privacy-ux, dark-patterns]
when_to_use: |
  Any site visitable from the EU, UK, California, or 15+ US states with
  privacy laws. The cookie banner is one of the most-seen UI elements
  on your site; get it wrong and you're either violating law or
  alienating users.
inputs:
  - traffic_geo, analytics_stack, tag_inventory
outputs:
  - "consent_ux: CMP choice + banner design + per-category controls + DSR + transparency"
---

# Cookie Consent + Privacy UX

> The cookie banner is the most-clicked design element on the web —
> usually clicked angrily. Done well, it builds trust without
> friction; done poorly, it earns you a regulator fine and a churn
> spike.

## Legal landscape (2026)

| Region | Law | What it requires |
|---|---|---|
| EU | GDPR + ePrivacy | Opt-IN for non-essential cookies; clear choice; easy withdraw |
| UK | UK GDPR + PECR | Same as EU |
| California | CCPA / CPRA | Opt-OUT of "sale" + "sharing"; "Do Not Sell or Share" link |
| Virginia, Colorado, Connecticut, Utah | Various | Opt-out generally |
| Brazil | LGPD | Similar to GDPR |
| Quebec | Law 25 | Strict consent, similar to GDPR |

## Cookie categories (industry standard)

The CMP segments cookies into:

| Category | What | Consent |
|---|---|---|
| **Strictly necessary** | Auth session, cart, CSRF | No consent needed |
| **Functional** | Language preference, theme | Opt-in (EU) / opt-out (US) |
| **Analytics** | GA4, Plausible, Mixpanel | Opt-in (EU) / opt-out (US) |
| **Marketing / advertising** | Facebook Pixel, Google Ads, LinkedIn Insight | Opt-in (EU) / opt-out (US) |
| **Personalization** | Recommendation, content prefs | Opt-in (EU) / opt-out (US) |

For EU: ONLY strictly-necessary loads before consent. Everything else
waits.

For US (most states): everything loads by default, user can opt-OUT.

## CMP tool choice (2026)

| Tool | Pros | Cons | $/mo |
|---|---|---|---|
| **OneTrust** | Enterprise; deep integrations | $$$, complex | $$$ |
| **Cookiebot (Usercentrics)** | Auto cookie scan, multi-jurisdiction | Easy | $$ |
| **Osano** | Modern UX, good defaults | Mid-market | $$ |
| **Didomi** | Strong EU compliance | Marketing-friendly | $$ |
| **Iubenda** | Cheap, smaller sites | Limited customization | $ |
| **Tarteaucitron.js** | Open-source, French-origin | Manual integration | Free |
| **Klaro** | Open-source, modern | Less polish | Free |

Default for B2B SaaS at scale: **Cookiebot** or **Osano**.

## Consent banner UX

### Layout (GDPR-compliant + user-friendly)

```
┌────────────────────────────────────────────────────────────┐
│  We use cookies to improve your experience               × │
│                                                            │
│  We use strictly-necessary cookies + (with your consent)   │
│  analytics, marketing, and personalization cookies.        │
│                                                            │
│  [Manage preferences]  [Reject all]  [Accept all]          │
└────────────────────────────────────────────────────────────┘
```

CRITICAL rules:
- **Reject ALL must be EQUAL prominence to Accept all.** "Manage prefs" +
  pre-selected "essential only" + "Save" is acceptable.
- **No pre-ticked optional categories** (invalid consent under GDPR).
- **Easy withdraw**: footer link "Cookie preferences" reopens the CMP.
- **No "close = consent".** Dismissing the banner ≠ accepting.
- **No dark patterns**: don't hide reject behind multiple clicks.

### Where to place

Options:
- **Bottom banner**: non-modal, scrollable site. Easier to navigate;
  weaker consent capture rate.
- **Modal overlay**: blocks site until choice. Stronger compliance;
  worse UX.
- **Bottom-right toast**: low impact; weak compliance.

For EU traffic: modal-or-bottom-bar with REJECT prominent. For US-only
sites: optional opt-out link in footer + smaller notice.

### Manage Preferences panel

```
┌────────────────────────────────────────────────────────────┐
│  Privacy preferences                                       │
│                                                            │
│  Strictly necessary             [Always on]                │
│  These cookies are required for the site to function.      │
│                                                            │
│  Functional                     [○] off  [●] on            │
│  Remember your settings (language, theme).                 │
│                                                            │
│  Analytics                      [●] off  [○] on            │
│  Help us understand how visitors use the site.             │
│                                                            │
│  Marketing                      [●] off  [○] on            │
│  Personalized ads on other websites.                       │
│                                                            │
│  [Save preferences]   [Accept all]                         │
└────────────────────────────────────────────────────────────┘
```

Default: all optional categories OFF.

## Implementation — defer tag loading

Don't fire pixels before consent:

```html
<!-- Don't do this -->
<script src="https://www.googletagmanager.com/gtag/js?id=GA-..."></script>

<!-- Do this -->
<script>
window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('consent', 'default', {
  ad_storage: 'denied',
  analytics_storage: 'denied',
  ad_user_data: 'denied',
  ad_personalization: 'denied',
  wait_for_update: 500
});
</script>
<!-- gtag.js loads but doesn't track until consent granted -->

<script>
// When user accepts:
gtag('consent', 'update', { analytics_storage: 'granted', ... });
</script>
```

Google Consent Mode v2 is REQUIRED for EU traffic (Mar 2024+); without it,
Google Ads + GA4 data is incomplete.

## CCPA "Do Not Sell or Share"

For California users:

```
Footer: [Do Not Sell or Share My Personal Information]
        →
        Modal: explain what "sale/sharing" means; offer opt-out toggle.
```

Many CMPs auto-detect geo and show this link only to CA visitors. Better:
show to ALL US visitors (state laws expanding).

Implement **Global Privacy Control (GPC)** signal handling — browser
header indicating user wants opt-out everywhere. Treat as opt-out
without confirmation modal.

## Transparency — the trust accelerator

In addition to required disclosures, build trust:

- **Privacy policy** that's actually readable (not 30 pages of legalese).
- **Page-level disclosure**: "This page uses these tools: [GA4, Hotjar,
  Intercom]."
- **First-party messaging** about what you do with data.
- **Vendor list** (in CMP and privacy page).
- **Subprocessor list** (for B2B).
- **Data residency** statement (where servers live).

This stuff is RARE; competitive advantage if you do it.

## Cookie scanner / audit

The CMP needs an accurate inventory. Tools:

- **Cookiebot scanner** (free for non-customers).
- **Osano CookieConsent scan**.
- **Cookiepedia** — database of known cookies + their purpose.
- **Browser DevTools** — Application tab → Cookies + Local Storage.

Audit quarterly. New tools deployed without CMP update = compliance gap.

## Mobile + app privacy

- Same rules apply on mobile web.
- For NATIVE apps: app store requirements (Apple Privacy Manifest 2024+,
  Google Play data safety section).
- Tracking pixel via App Tracking Transparency (iOS) — opt-in only.

## Dark patterns to avoid (and many sites use)

- **Pre-ticked optional categories.** Illegal under GDPR.
- **"Reject" requires 3+ clicks.** Implicit dark pattern; regulators have
  fined for this.
- **"Accept" prominent in color; "Reject" small + gray.** Disparate
  prominence = invalid consent.
- **"Continue without accepting" hidden in fine print.** Same issue.
- **Banner that returns every page load** even after consent. Annoying +
  potentially non-compliant.
- **Modal that prevents reading the page** until you "accept all." Many
  regulators consider this coercion.
- **"Your data is safe with us"** as a value-add. Vague; no trust transfer.

EU regulators have fined for these. €100M+ to Google (2022) on cookie
consent issues.

## Performance impact

Most CMPs load 50-150KB of JS. Mitigate:

- Load CMP early (head) but DEFER decisions to its own thread.
- Use a static, build-time CMP if possible (Cookiebot has this).
- Async loading; show banner immediately, finish loading prefs in background.
- Lighthouse-test the LCP impact.

CMPs blocking LCP is a top-3 perf complaint.

## Anti-patterns

- **No CMP** for an EU-trafficked site. Active risk.
- **CMP installed, tags fire anyway.** Misconfiguration; common.
- **"Reject all" buried.** Will be fined.
- **No "Cookie preferences" link in footer.** Users can't change mind.
- **CMP language only in English.** Localize per visitor locale.
- **Consent banner not visible to keyboard / screen reader users.**
  Accessibility + compliance fail.
- **CMP not tested on mobile.** Often overflows / unclickable.

## Validation

- [ ] CMP installed; auto-scan inventory recent (< 90 days).
- [ ] Strictly-necessary only loads before consent in EU.
- [ ] Reject equally prominent to Accept.
- [ ] Footer link "Cookie preferences" works.
- [ ] CCPA "Do Not Sell" link visible to US visitors.
- [ ] GPC signal honored.
- [ ] Google Consent Mode v2 wired.
- [ ] Banner localized per visitor language.
- [ ] CMP keyboard-accessible.
- [ ] Mobile banner non-blocking + dismissible.
- [ ] LCP impact < 200ms.
