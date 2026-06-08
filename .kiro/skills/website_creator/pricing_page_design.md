---
id: pricing_page_design
version: 1.0.0
owners: [website_creator, product_manager]
tags: [pricing, tiers, anchoring, roi-calculator, enterprise, freemium]
when_to_use: |
  Designing or auditing a pricing page. Pricing presentation drives a
  larger conversion delta than almost any other single page. Anchoring,
  tier layout, and explicit value mapping are the levers.
inputs:
  - pricing_model, target_segments, billing_cycle, competitive_positioning
outputs:
  - "pricing_page_design: tier presentation + anchoring + comparison + CTA + faq"
---

# Pricing Page Design

> The pricing page closes deals OR loses them. Treat it like a
> conversion-critical surface, not a documentation page. Specific
> patterns work; arbitrary ones don't.

## The three-tier classic (and why it works)

```
┌───────────────┐  ┌─────────────────┐  ┌──────────────┐
│   Starter     │  │   Pro           │  │  Enterprise  │
│   $19/mo      │  │   $99/mo        │  │  Custom      │
│               │  │   ⭐ Recommended│  │              │
│   - Feature 1 │  │   - Everything  │  │   - All Pro  │
│   - Feature 2 │  │     in Starter  │  │   - SSO/SAML │
│   - Feature 3 │  │   - Feature 4   │  │   - SOC 2    │
│               │  │   - Feature 5   │  │   - Dedicated│
│               │  │   - Feature 6   │  │     support  │
│  [Start free] │  │  [Try Pro free] │  │ [Talk to us] │
└───────────────┘  └─────────────────┘  └──────────────┘
```

Why three:
- ANCHORING. Even if no one buys Enterprise, it makes Pro look reasonable.
- DECISIVENESS. Two = binary (yes/no). Three = a clear "best" middle.
- SEGMENTATION. Different buyer profiles can self-select.

For freemium add a fourth (FREE) on the left:

```
Free → Starter → Pro → Enterprise
```

## Anchoring — the recommended-tier highlight

Always visually emphasize ONE tier:
- Border color (brand color).
- "Most popular" / "Recommended" badge.
- Slightly larger card.
- The CTA in primary color (others outlined).

This is NOT manipulation — it's a buying signal. Most users want a
recommendation.

## Annual / monthly toggle

```
[Monthly]  [● Annual — save 20%]
```

Toggle defaults to Annual. Brand shows the savings. Per-month equivalent
displayed; annual total in smaller text.

```
Pro tier:
  $99/mo  (billed monthly)
  $79/mo  (billed annually — save $240)
```

For longer commitments (2 / 3 year): show in a separate Enterprise tier.

## What goes in each tier

Per tier, list the KILLER FEATURES — not the full set:

```
Starter           Pro                Enterprise
- 5 users         - 50 users         - Unlimited users
- 10GB storage    - 1TB storage      - Unlimited storage
- Email support   - Slack support    - Dedicated CSM
                  - SSO              - SSO + SAML
                  - API access       - SOC 2 / HIPAA
                                     - Custom contracts
```

Each tier shows MAX 6-7 line items. If you have 30 features per tier, link
to a comparison table.

## Free tier — when to include

| Pro | Con |
|---|---|
| Reduces friction; PLG funnel | Free users cost money |
| Word-of-mouth | Sales focused on free → paid friction |
| Builds developer community | "Free" sometimes attracts wrong audience |

If you ship a free tier:
- Make it GENUINELY useful (not a 7-day trial in disguise).
- Limit the GROWTH AXIS (users, storage, projects) — quality stays full.
- Upgrade path obvious without nagging.
- No credit-card required.

## Enterprise tier — sell the trust, not the price

Don't show a number. Show what's INCLUDED:
- Volume discounts.
- Dedicated CSM.
- SSO / SAML / SCIM.
- SOC 2 / ISO 27001 / HIPAA / GDPR-DPA.
- 99.9% SLA.
- 24/7 support.
- Custom contracts.
- Procurement integration (workday, ariba).

CTA: "Contact sales" + a short form with company size and use case. Or
calendar booking (Calendly, Chili Piper) for fast sales response.

## Comparison table

Below the tier cards:

| Feature | Starter | Pro | Enterprise |
|---|---|---|---|
| Users | 5 | 50 | Unlimited |
| Projects | 3 | Unlimited | Unlimited |
| Storage | 10GB | 1TB | Unlimited |
| API rate limit | 100/min | 1000/min | Custom |
| SSO | — | — | ✓ |
| SOC 2 | — | — | ✓ |
| Dedicated CSM | — | — | ✓ |
| ... |

Sortable, filterable, expandable details. NOT everything — only the
buying-decision attributes.

## ROI calculator (for high-ASP products)

For products that save real money/time:

```
Inputs (sliders):
  - Number of incidents per month: [10]
  - Average response time:         [25 min]
  - Engineer hourly cost:          [$120]

Outputs:
  - You spend ~$50,000/year on incident response.
  - With <product>, expect 40% reduction = $20,000 saved.
  - <product> Pro: $1,188/year. Net: $18,812/year (~16× ROI).
```

Done right, ROI calculators are the most powerful element on the page —
they put the buyer's own numbers in the savings story.

Don't fake-precision: show "~$20,000" not "$19,847.32".

## Add-ons + usage-based components

Modern SaaS often has hybrid pricing:
- Base tier ($99/mo)
- + Usage (e.g. $0.10 per 1000 API calls beyond 100k)
- + Seats (e.g. $20/user/mo above tier limit)

Display CLEARLY:
```
Pro tier:                       $99/mo
+ Up to 100k API calls          included
  Additional: $0.10 / 1000      pay-as-you-go
+ 50 seats                      included
  Additional: $15/seat/mo       monthly billed
```

Hidden usage charges = customer churn after the first big bill.

## Currency + localization

- Detect by IP, default to user's currency.
- Allow override (some users prefer USD billing).
- Show LOCAL tax inclusion (VAT in EU, GST elsewhere) — required by law
  in many jurisdictions.
- Use a payment processor that handles currency conversion (Stripe,
  Paddle).

## FAQ on pricing page

Top objections:
- "Can I change tiers anytime?" (yes; prorated, no contracts)
- "What payment methods?" (credit, ACH, wire)
- "Do you offer discounts for nonprofits / students / startups?"
- "What's your refund policy?"
- "How does the free trial work?" (No credit card; auto-cancel; full
  features)
- "Can I cancel anytime?" (yes; access continues until period end)

## Specific objection handlers

| Objection | Counter |
|---|---|
| "Too expensive" | ROI calculator + comparison to status quo cost |
| "How is this different from <competitor>?" | Compare table specifically vs them |
| "We can build it ourselves" | TCO breakdown (eng hours × $$) |
| "What if I leave?" | Easy export, no contracts, money-back guarantee |
| "What about my security team?" | SOC 2, ISO, GDPR badges + link to trust page |

Anticipate; address inline; don't make them search.

## CTA logic per tier

| Tier | CTA |
|---|---|
| Free | "Start free" — no card |
| Starter | "Start free trial" (or "Sign up") |
| Pro | "Try Pro free" (14-30 day trial) |
| Enterprise | "Talk to sales" → calendar / form |

NEVER:
- "Buy now" on a high-ASP product (push to sales)
- "Contact us" on a self-serve tier (defeats PLG)
- Same CTA on every tier (no differentiation)

## Mobile pricing

Pricing tables fall apart on mobile. Options:
- **Single vertical column** with tier toggle at top.
- **Horizontal scroll** of cards (acceptable, but UX risk).
- **Accordion** style (one tier expanded at a time).

Test on real phones; pricing decisions often happen there.

## A/B testing pricing — carefully

Pricing tests have ETHICAL + LEGAL constraints:
- Don't show different prices to different users randomly. Some jurisdictions
  see this as dynamic pricing fraud.
- Use clear segments (e.g. region, plan choice, but never identity).
- Test layout, copy, anchoring → much safer than testing PRICE itself.

## Anti-patterns

- **"Starting at"** prices that hide variable costs. Trust killer.
- **6+ tiers.** Decision paralysis.
- **No annual savings.** Misses 20-30% commitment lift.
- **CTA on each tier the same.** Tiers don't feel differentiated.
- **Enterprise hidden behind "Contact us"** with no hint of what's
  included. People won't reach out without knowing.
- **No FAQ.** Objections go unanswered → bounce.
- **No comparison table.** Buyers can't compare without one.
- **Hiding the recommended tier.** People want guidance.
- **Free tier indistinguishable** from a trial — bait-and-switch.
- **Coupons everywhere.** Devalues. Better: enterprise discount via sales.
- **Different currency than user's region.** Friction.

## Validation

- [ ] Three tiers (+ optional free + enterprise) with clear differentiation.
- [ ] One tier visibly recommended.
- [ ] Annual / monthly toggle with savings called out.
- [ ] Comparison table for full feature list.
- [ ] FAQ addresses top 5 pricing objections.
- [ ] ROI calculator if high-ASP.
- [ ] Currency detected + tax inclusion clarified.
- [ ] CTA per tier matches its sales motion.
- [ ] Mobile pricing works (real-device test).
