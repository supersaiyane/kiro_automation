---
id: north_star_metric
version: 1.0.0
owners: [product_manager]
tags: [metrics, north-star, okr, leading-indicators, product-strategy]
when_to_use: |
  Defining what success looks like for the product over the next 12-24
  months. The North Star is the metric that the company optimizes; the
  rest are inputs or guardrails.
inputs:
  - business_model + jtbd from market_research
outputs:
  - north_star: single metric + the leading inputs that drive it
  - guardrails: metrics that must NOT regress
---

# North Star Metric (NSM)

**One metric. One.** It captures the value the customer gets from the
product. Revenue is not it (revenue is a *consequence*); engagement
isn't it either unless your model is ads-based.

## Three properties of a real NSM

1. **Customer-value-aligned.** When this metric goes up, customers got
   more of what they hired the product for.
2. **Leading, not lagging.** Predicts revenue 1-2 quarters out.
3. **Movable by the team.** If nobody on the team can affect it within
   a quarter, it's a vision statement, not a metric.

## Examples (clean ones)

| Company / domain | NSM | Why it works |
|---|---|---|
| Marketplace (Airbnb-like) | Nights booked | Captures both sides of the marketplace + actual transaction |
| Messaging (Slack-like) | Weekly messages sent in teams of ≥3 | Excludes bots and abandoned workspaces |
| Storage (Dropbox-like) | GB synced across ≥2 devices | "≥2 devices" = product is doing the job |
| Email (Superhuman-like) | Emails triaged per active day | Triage > inbox visits |

Notice none of them is "MAU" or "revenue". MAU is reach without value;
revenue is the lagging confirmation.

## The L1 → L2 → L3 input tree

The NSM at L1. **L2 = the 3-5 inputs you can directly affect.** Each L2
decomposes into L3 actions.

Example for "Weekly messages in teams of ≥3":
- L2: New active teams created
  - L3: Signup-to-activation rate
  - L3: Day-7 retention
- L2: Messages per active user
  - L3: Channels with notifications on
  - L3: Integrations connected
- L2: Active users per team
  - L3: Invites sent per existing user
  - L3: Invite acceptance rate

Every project the team picks should be defensible against this tree.
"What L3 does this move?" — if nothing, don't ship it.

## Guardrails (anti-regression)

The NSM goes up — but at what cost? Pick 2-4 guardrails that **must not
regress** even if the NSM rises:

- Latency p95
- Support ticket volume per 1k MAU
- Refund rate
- Negative review rate
- Churn at month-3

Every experiment ships with NSM impact **and** guardrail deltas.

## Quarterly review ritual

Once a quarter, ask:
1. Did the NSM move? By how much? Which L2 input drove it?
2. Are any guardrails red?
3. Did our L3 actions explain the L2 movement, or are we hand-waving?
4. Is the NSM still the right one? (Don't change it unless the
   business model changed; otherwise drift in the metric definition
   makes the trend uncomparable.)

## Anti-patterns

- Two North Stars. There's a reason it's called "north" — pick one.
- NSM = revenue. Revenue is the *result*. Optimizing it directly leads
  to short-term tactics that erode the product.
- A team-level NSM that doesn't roll up to company NSM. If team-X's
  metric can rise while company NSM falls, the metric is misaligned.
- Defining the NSM in the slide and never instrumenting it. If a query
  doesn't return it on demand, it isn't your NSM.
- Changing the NSM each quarter. Trends become uninterpretable.
- "Engagement" or "satisfaction" without a unit. Not a metric, a vibe.
