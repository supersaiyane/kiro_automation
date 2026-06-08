---
id: conversion_optimization
version: 1.0.0
owners: [website_creator]
tags: [cro, conversion, funnel, ab-test, landing-page, growth]
when_to_use: |
  After launch, when the marketing site is live and you have ≥1k
  visitors/week. CRO turns the same traffic into more customers —
  cheaper than buying more traffic.
inputs:
  - funnel_metrics: visitor → signup → activated → paying
outputs:
  - cro_plan: prioritized experiments + expected lift
---

# Conversion Rate Optimization (CRO)

## Where to look (the funnel decomposition)

You can't "improve conversion." You can improve **a specific step**:

```
visitor
  ↓ 100%
landing-page view
  ↓ ~50%  (homepage hits → product page)
product-page view
  ↓ ~10%  (product page → pricing or signup CTA click)
signup form view
  ↓ ~30%  (form view → completed signup)
account created
  ↓ ~40%  (signup → activated user)
activated user
  ↓ ~25%  (activation → paying)
paying customer
```

The weakest *transition* (not the lowest absolute number) is where
to focus. A 30% → 35% lift on a step at 50% of funnel beats a
20% → 40% lift on a step at 5%.

## The five highest-ROI CRO levers (in order)

1. **Above-the-fold headline + value prop.** If a visitor can't
   understand what you sell in 5 seconds, they leave. A/B test
   variations of the hero headline — biggest single-test impact.
2. **CTA copy + position.** "Get started free" beats "Sign up" by
   20-30% typically. Top of page + repeated mid-page + bottom.
3. **Social proof above the fold.** Logos, a one-line testimonial,
   a "trusted by 10,000 teams" stat. 5-15% lift commonly.
4. **Form length.** Each additional field drops conversion ~5-10%.
   Ask for email only; collect the rest after signup.
5. **Page speed.** LCP > 3s → measured 7% conversion drop per
   additional second. Fixing perf is CRO.

Below these, you're in diminishing returns. Spend cycles on the
landing page hero before tweaking the footer.

## The CRO experiment template

```
HYPOTHESIS:
  Changing <element> from <variant A> to <variant B> will increase
  <metric> by ≥<MDE>% because <user-behavior reason>.

PRIMARY METRIC: <signup conversion / paid conversion / activated>

GUARDRAIL: bounce rate, time on page, downstream funnel step

DURATION: <enough samples to detect MDE at 95% / 80% power>
  (use a sample size calculator BEFORE starting)

STOP RULES:
  - Catastrophic guardrail breach
  - Significant lift at full duration → ship treatment
  - No movement at full duration → keep control, write lesson learned
```

Use a CRO platform (Optimizely, VWO, GrowthBook) — not custom code
that breaks bucket-stability and SEO.

## SEO ↔ CRO tension

A landing page optimized for conversion is often a poor SEO landing
page (light on text, focused on a CTA). A page optimized for SEO is
often a poor conversion page (long-form, multiple CTAs).

Resolution: separate page templates per intent.
- `/features/X` — SEO target, long-form, multiple CTAs at intervals.
- `/get-started` — conversion target, lean, one CTA.

Internal links route SEO traffic into the conversion templates after
the user expresses intent.

## Trust signals (cheap, high ROI)

- SOC 2 badge if you have it (~5-10% lift on B2B).
- Customer testimonial with full name + company.
- Specific numbers ("Cut their support time by 47%") beat
  "improved their support."
- Money-back guarantee for paid plans (reduces purchase friction).
- HTTPS lock + privacy-policy link visible in footer.

## Killing the assumption

Most CRO "wisdom" is wrong outside its original context. Test
before believing:
- "Red buttons convert better than green." Maybe at HubSpot in 2012.
  Test on your site.
- "Above the fold is critical." Maybe; depends on scroll behavior.
- "Long copy beats short copy." Or the reverse. Depends on intent.

The only thing that's universally true: **measure your funnel,
hypothesis-test the weakest step.**

## Anti-patterns

- A/B testing without enough traffic. With 100 visitors/day, you need
  3 months for a single test. Plan accordingly.
- Optimizing the wrong page. Tweaking the homepage when 80% of paid
  traffic lands on `/pricing`.
- Running 5 simultaneous tests on the same flow. Interactions are
  uncontrolled; results are noise.
- Calling 5% lift at p=0.3 a win. That's noise dressed up.
- Optimizing for vanity metrics (newsletter signups) instead of
  paying customers downstream. Conversion improvements that don't
  produce revenue are wasted effort.
- Removing a working CTA to "test minimalism." Always have a control;
  always have a fallback.
- A/B testing for 2 days. The day-of-week effect alone biases the
  result. Run ≥ 7 days, ideally 14.
