---
id: ab_testing_experimentation
version: 1.0.0
owners: [website_creator, product_manager]
tags: [ab-testing, experimentation, statistical-power, holdout, multivariate]
when_to_use: |
  Making a conversion or growth decision that costs > a day of
  engineering time, OR rolls out to all users. A/B testing turns
  opinions into evidence — IF run with statistical rigor. Without it,
  it's expensive theater.
inputs:
  - hypothesis, audience_size, conversion_baseline, mde
outputs:
  - "experiment_plan: hypothesis + variants + power + duration + decision rule"
---

# A/B Testing + Experimentation

> "We A/B tested it" only means something if the test was POWERED,
> ASSIGNMENT was clean, and the DECISION RULE was set BEFORE peeking.
> Sloppy tests give false confidence — worse than no test.

## When to A/B test

| Worth it | Skip it |
|---|---|
| > 5% expected lift on a critical metric | < 1% expected lift (noise-limited) |
| > 1000 conversions / variant achievable | Sample size won't hit power in reasonable time |
| Reversible change | Major UX or pricing change requires user research |
| Multiple stakeholders disagree | Strong qualitative signal already |
| New feature with unclear win | Bug fix (just ship it) |

## Hypothesis-driven design

Before opening the test:

```
HYPOTHESIS
  We believe that <CHANGE>
  for <AUDIENCE>
  will result in <METRIC change>
  because <REASONING>.

MEASURE
  Primary metric:   <e.g. signup_completed>
  Secondary:        <e.g. signup_started, time_to_signup>
  Guardrail:        <e.g. session_duration — don't tank UX>

POWER
  Baseline rate:    <p0>
  MDE:              <smallest effect worth detecting, e.g. 10% relative>
  Significance:     0.05 (one-sided usually OK for product wins)
  Power:            0.80
  Required N:       (computed)

DURATION
  Daily traffic:    <N/day>
  Calendar:         (N required) / (daily) → days
  Minimum 1 week to absorb weekly seasonality.
```

If duration > 4 weeks, the test is too small. Either:
- Increase MDE (accept less precision).
- Combine variants.
- Test on a larger surface.
- Skip A/B; ship + observe.

## Statistical basics

### Sample size calculator

```python
# Approximate two-proportion test
def required_sample(p0, mde_rel, alpha=0.05, power=0.80):
    """n per variant"""
    import math
    from scipy.stats import norm
    p1 = p0 * (1 + mde_rel)
    z_alpha = norm.ppf(1 - alpha)
    z_beta  = norm.ppf(power)
    pooled = (p0 + p1) / 2
    sigma2 = pooled * (1 - pooled)
    n = (z_alpha + z_beta)**2 * 2 * sigma2 / (p1 - p0)**2
    return math.ceil(n)

# 5% baseline, 10% relative lift, standard alpha + power:
# required ~ 31,500 per variant
```

Tools: Evan Miller's calculator, Optimizely's, Statsig's, VWO's.

### Frequentist vs Bayesian

| Approach | Pros | Cons |
|---|---|---|
| Frequentist (NHST) | Standard; clear "significant" threshold | Can't peek; fixed-horizon |
| Sequential testing | Can peek; valid early stopping | Statistically stricter |
| Bayesian | Can peek; intuitive ("70% probability B is better") | Easy to abuse priors |

Modern stack (Statsig, Eppo, GrowthBook): sequential testing — you can
look at results any time without inflating false-positive rate.

### Peeking is the sin

```
DAY 1: result LOOKS positive → P(false positive) drops to maybe 60% if
        you stop.
DAY 7: lift faded; would've been not-significant.
DAY 14: actual answer.

If you DECLARE WINNER on day 1 because "it's significant," you've inflated
false-positive rate to 25-40% (way past your nominal 5%).
```

Defenses:
- Fixed-horizon test: declare N + duration BEFORE start; don't peek.
- Sequential test: peek allowed at pre-defined intervals only.
- Bonferroni / FDR correction for multiple tests.

## Multivariate tests (more than 2 variants)

```
A: baseline
B: new headline
C: new CTA color
D: new headline + new CTA color
```

Each comparison eats power. 4-way test = ~3x sample size of A/B.

Avoid unless:
- Sample size is plentiful.
- You're factoring in interactions (does headline + CTA combo matter?).

Most teams should stick to 2 variants per test.

## A/B/N — running multiple unrelated tests

| Approach | When |
|---|---|
| Separate tests per surface | Default; assumes no interaction |
| Mutually-exclusive layers | High-traffic; allocate to one experiment at a time |
| Shared with stratification | Statisticians ONLY |

Risk: 5 simultaneous tests with α=0.05 each = ~22% chance ONE false-
positive. Fix with FDR control (Benjamini-Hochberg).

## Assignment + bucketing

```python
def variant_for(user_id, experiment_id, allocation):
    # Deterministic hash so same user always gets same variant
    h = hash(f"{user_id}:{experiment_id}") % 1_000_000
    cumulative = 0
    for variant, share in allocation.items():
        cumulative += share * 1_000_000
        if h < cumulative:
            return variant
    return next(iter(allocation))  # safety
```

Critical:
- Hash includes EXPERIMENT_ID so different experiments don't correlate.
- DETERMINISTIC by user — they always get the same variant.
- Allocation can shift over time (gradual rollout).

## Holdouts — the long-term truth

Even after a "winner," keep 5% on the OLD variant for 30-90 days.
- Confirms the lift holds in production.
- Catches secondary metric regressions (retention drops 3 months later).
- Calibrates future experiments.

Many teams skip this; mature growth teams don't.

## Tools

| Tool | Use |
|---|---|
| **Statsig** | Modern, sequential testing, feature flags + analytics |
| **Eppo** | Engineering-friendly, warehouse-native |
| **GrowthBook** | Open-source, warehouse-native |
| **Optimizely** | Enterprise; full-stack |
| **VWO** | Marketing-focused |
| **PostHog** | Free tier; analytics + flags + experiments |
| **LaunchDarkly** | Feature flags; experimentation add-on |
| **Convert** | A/B + multivariate; conversion-focused |

Default for startups: PostHog (free + integrated).
Mid-market PLG: Statsig or GrowthBook.
Enterprise: Eppo / Optimizely.

## Common test mistakes

1. **Underpowered**: small lift can't be detected; test concludes "no
   difference" when there IS a real difference.
2. **Peeking + early-stopping** without sequential framework.
3. **Sample contamination**: same user in both variants (different
   browser, logout/login).
4. **Time-of-day / day-of-week** without full week covered.
5. **Seasonality** during a special event (Black Friday).
6. **Outliers** (one whale user dominates conversion metric).
7. **Wrong metric** (vanity instead of revenue / retention).
8. **Multiple comparisons** without correction.
9. **Selection bias** (only "active" users in test).
10. **Non-inferiority confused with equivalence** ("no significant diff"
    ≠ "they're the same").

## Test results template

```
EXPERIMENT: signup_form_v2
DURATION:   2026-04-01 → 2026-04-15 (14 days)
TRAFFIC:    50k visitors total, 25k per variant
HYPOTHESIS: Removing 2 form fields will increase signup completion.

RESULTS:
  Variant A (control, 5-field form):    8.4% conversion
  Variant B (3-field form):             10.2% conversion
  LIFT:                                 +21% relative (+1.8pp absolute)
  P-VALUE:                              < 0.001
  95% CI:                               [+1.0pp, +2.6pp]

SECONDARY:
  Email validation errors:              -34% in B (better)
  Time-to-signup:                       -8 sec in B (better)

GUARDRAIL:
  Trial-to-paid conversion (downstream): -3% in B (worse, p=0.08)
  → CONCERN: are we getting LESS-QUALIFIED signups?

DECISION:
  SHIP B but monitor trial-to-paid for 30 days.
  If trial-to-paid drops > 5% sustained, revert.
```

The senior craft: secondary metrics catch tradeoffs. Don't just stare
at the primary.

## Cultural — experimentation maturity

```
LEVEL 0 — Ad-hoc:
  Occasional test; gut-led decisions.

LEVEL 1 — Reactive:
  Test major changes. No backlog.

LEVEL 2 — Programmatic:
  Experiment backlog; weekly velocity.
  Powered tests. Defined metrics.

LEVEL 3 — Cultural:
  Every product/marketing decision asks "can we test?"
  Holdouts maintained. Retros on wins + losses.
  Statistical literacy across team.
```

Most teams at level 1. Aspire to level 2; level 3 is FANG-tier.

## Anti-patterns

- **No hypothesis** — running tests "to see."
- **Underpowered** — declaring null result on noise.
- **Peeking** — destroys statistical validity.
- **Stopping at significance** without holding for full duration.
- **Same metric in every test** — over-optimizing one thing.
- **No guardrails** — primary wins, secondary tanks, ship anyway.
- **No holdout** — long-term effects untested.
- **Multiple comparisons unprotected.**
- **HiPPO override** — "this looks good" beats data.
- **Tests on unstable surface** (page redesigning during test).

## Validation

- [ ] Hypothesis documented before test.
- [ ] Sample size calculated; duration ≥ 1 week.
- [ ] Primary + secondary + guardrail metrics defined.
- [ ] Tool selected with sequential / Bayesian for early peek
      (or strict no-peek discipline).
- [ ] Deterministic bucketing keyed by user_id + experiment_id.
- [ ] Decision rule documented before launch.
- [ ] Holdout for major changes (30-90 days).
- [ ] Quarterly review of experiment outcomes (wins + losses).
