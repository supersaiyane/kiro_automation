---
id: analytics_event_tracking_setup
version: 1.0.0
owners: [website_creator, product_manager, designer]
tags: [analytics, ga4, posthog, mixpanel, event-tracking, gdpr, consent]
when_to_use: |
  Setting up analytics on a marketing site, or auditing an existing
  setup. Without solid event tracking, conversion optimization is
  guesswork. Done right, it informs every design decision.
inputs:
  - traffic_sources, conversion_goals, privacy_constraints
outputs:
  - "analytics_plan: tool choice + events + attribution + consent + dashboard"
---

# Analytics + Event Tracking Setup

> "What works?" is the only question that matters. Without analytics,
> every CRO change is a vibe. With proper events, you ship the change
> that moved the number.

## Tool landscape (2026)

| Tool | Use | Cost |
|---|---|---|
| **Google Analytics 4** | Default for marketing sites | Free + paid tier |
| **Plausible** | Privacy-first, EU-friendly, lightweight | $9-$99/mo |
| **Fathom Analytics** | Same niche as Plausible | $14-$74/mo |
| **PostHog** | Product analytics + session replay + feature flags | Free tier + scale |
| **Mixpanel** | Product analytics, funnels, cohorts | Free tier + scale |
| **Amplitude** | Like Mixpanel; product-led growth focused | Free tier + scale |
| **Heap** | Auto-capture (all clicks); retroactive analytics | Paid |
| **Datadog RUM** | Performance + UX in one | Paid |
| **Hotjar / Microsoft Clarity** | Heatmaps + recordings | Free tier (Clarity) |

Default stack for SaaS marketing:
- **Plausible or GA4** for top-of-funnel traffic.
- **PostHog** for product behavior + recordings.
- **Microsoft Clarity** (free) for heatmaps.

## Event taxonomy — name BEFORE you instrument

Define the event dictionary FIRST:

```
Naming convention: object_action (snake_case)

Page-level:
  page_viewed
  page_scrolled_25
  page_scrolled_75
  page_dwell_30s

Marketing engagement:
  cta_clicked       { cta_text, cta_location, page_url }
  signup_started    { source }
  signup_completed  { method }
  pricing_viewed    { tier_compared }
  pricing_toggled   { from, to }       (monthly/annual)
  demo_requested    { company_size, role }
  contact_form_submitted

Content engagement:
  video_played      { video_id, position }
  video_completed   { video_id }
  file_downloaded   { filename }
  newsletter_subscribed

Navigation:
  nav_clicked       { destination }
  search_performed  { query }
  external_link_clicked { url }
```

Document in a spreadsheet / Notion / your analytics tool's catalog.
EVERYONE references the same names.

## Event properties — context matters

A `cta_clicked` event without properties is useless. Always include:

```js
analytics.track('cta_clicked', {
  cta_text: 'Start free trial',
  cta_location: 'hero',                 // hero, features, pricing, footer
  page_url: window.location.pathname,
  page_section: 'above-fold',
  user_segment: 'new_visitor',           // new_visitor | returning | logged_in
  traffic_source: 'google_organic',
  experiment_variant: 'B',
});
```

Properties make events queryable later.

## Identity — anonymous → known

Track anonymous user IDs from FIRST visit:

```js
// First visit: generate a stable anonymous_id (UUID), store in cookie/LS
analytics.identify(anonymous_id);

// When they sign up:
analytics.identify(user_id, { email, name, plan });
// All prior anonymous events get attributed to this user_id.
```

Tools (Segment, RudderStack, PostHog) auto-merge anonymous → known on
identify call.

## Funnels

Define the key conversion funnel:

```
Landing → Pricing → Signup → Activated → Paid

Event chain:
  page_viewed     (homepage)
  cta_clicked     (cta_location: hero)
  page_viewed     (pricing)
  pricing_toggled, pricing_viewed
  cta_clicked     (cta_location: pricing-pro)
  signup_started
  signup_completed
  feature_used    (first_action)        ← "activation"
  subscription_created                  ← "paid"
```

Build funnel report. Each step's drop-off = optimization opportunity.

## UTM tagging

Every paid / email / social campaign URL:

```
https://example.com/landing?
  utm_source=google
  &utm_medium=cpc
  &utm_campaign=q1-launch
  &utm_content=ad-variant-a
  &utm_term=incident-response
```

Standardize a tag dictionary so reports don't fragment.

Tools: GA4 reads UTMs natively; CRM (HubSpot, Salesforce) attributes them
to leads.

## Attribution models

| Model | What it does | When |
|---|---|---|
| Last-touch | Credit goes to last touchpoint | Simple, low-budget |
| First-touch | Credit goes to first touchpoint | Brand-focused |
| Linear | Equal credit across all touchpoints | Multi-channel orgs |
| Time-decay | More credit to recent touches | Long sales cycles |
| Position-based | 40% first + 40% last + 20% middle | Hybrid |
| Data-driven | ML model figures it out | GA4 default for high-traffic |

For most SaaS: position-based or data-driven. Most marketers default to
last-touch which is often wrong.

## Consent + privacy

GDPR + state privacy laws require consent BEFORE tracking analytics
(strict reading) — though "essential" first-party analytics can be argued.

Plausible/Fathom/Microsoft Clarity claim no-consent-needed because they
don't use cookies + anonymize aggressively. Validate with your legal
counsel.

For GA4 + PostHog + Mixpanel: consent banner required. Use a CMP
(Cookiebot, OneTrust, Osano, Didomi). Pattern:

```js
// Before consent
gtag('consent', 'default', {
  analytics_storage: 'denied',
  ad_storage: 'denied'
});

// After user accepts
gtag('consent', 'update', {
  analytics_storage: 'granted'
});
```

EU users: explicit OPT-IN. US users: usually OPT-OUT acceptable (state-
dependent — CA, VA, CO, etc. have nuances).

## Performance — analytics shouldn't slow the page

| Tool | Bundle size | Load impact |
|---|---|---|
| Plausible | ~1KB | Negligible |
| Fathom | ~2KB | Negligible |
| GA4 (gtag.js) | ~50KB | Moderate; defer |
| PostHog | ~60KB | Moderate; defer |
| Mixpanel | ~75KB | Moderate; defer |
| Segment + downstreams | 100KB+ | Significant; defer or proxy |

ALWAYS load with `defer` or `async`. Place in `<head>` for early init but
script attribute prevents render block.

For high-traffic sites: server-side tracking via:
- **Segment server-side**
- **GA4 Measurement Protocol**
- **Posthog Python/Node SDK**

Server-side is privacy-friendly AND ad-blocker-resistant.

## Dashboards — what to show

Marketing dashboard:
- **Traffic** (sessions, users) per source × week.
- **Top landing pages** by conversion rate.
- **Funnel report** (landing → signup).
- **CTA performance** (which CTAs in which locations convert).
- **Page speed** (LCP, CLS) per page.
- **Conversion rate** week-over-week.

Product dashboard (separate):
- **DAU / WAU / MAU**.
- **Activation rate**.
- **Feature adoption**.
- **Retention curves**.
- **Cohort analysis** (signup month vs retention).

## Session replay (use with consent)

Tools: PostHog, Hotjar, Microsoft Clarity, FullStory.

WATCH 5-10 sessions a week. You'll find:
- Confusing UI moments (rage clicks).
- Form abandonment patterns.
- Browser-specific bugs.
- Misclicked elements.

Strip PII automatically (most tools do this for inputs labeled
password/credit-card).

## A/B testing setup

Tools: VWO, Optimizely, PostHog feature flags, GrowthBook (open-source).

```js
const variant = posthog.getFeatureFlag('hero_test');
if (variant === 'B') showVariantB();
else showVariantA();

posthog.capture('hero_test_exposed', { variant });
```

Statistical requirements:
- > 1000 conversions per variant before declaring winner.
- Frequentist or Bayesian framework declared upfront.
- Use sequential testing if you want to peek (Statsig, Eppo).
- Holdouts: 5% population never gets the change — verifies long-term effect.

## Privacy + ad-blocker resistance

Up to 30% of users block analytics (Brave, ad-blockers, Safari ITP).

Mitigations:
- **First-party proxy**: serve analytics from YOUR domain
  (e.g. `/analytics.js`). Routes traffic through a proxy.
- **Server-side tracking**: from your backend, not the client.
- **Conversion API** integrations with Facebook / Google for ads.

## Anti-patterns

- **Auto-capture (Heap-style) without consent**. May breach GDPR.
- **No event taxonomy.** "cta_clicked" + "Button click" + "click cta" =
  three events for one action.
- **Properties as fields, not standardized.** `cta_text` vs `text` vs
  `label` — same property, different names.
- **PII in event properties.** Email in URL fragments captured by
  analytics.
- **No funnel reporting.** Can't see WHERE you lose users.
- **GA4 only.** Missing product analytics (cohorts, retention curves).
- **Analytics blocking page load.** No `defer`.
- **Tracking before consent.** Compliance violation.
- **Last-touch attribution only.** Misses brand + nurture impact.

## Validation

- [ ] Event taxonomy documented and shared.
- [ ] UTMs standardized across all campaigns.
- [ ] Identity tracking (anonymous → known) on user signup.
- [ ] Consent management for EU traffic.
- [ ] Funnel report exists for primary conversion.
- [ ] Dashboard reviewed weekly.
- [ ] Session replays watched (5-10/week).
- [ ] Analytics page load impact < 50ms.
- [ ] Privacy policy mentions every tool in stack.
