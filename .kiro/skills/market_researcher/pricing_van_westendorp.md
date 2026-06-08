---
id: pricing_van_westendorp
version: 1.0.0
owners: [market_researcher]
tags: [pricing, van-westendorp, willingness-to-pay, packaging, monetization]
when_to_use: |
  Setting a launch price, validating a price change, or testing
  willingness-to-pay across segments. Pair with a Gabor-Granger
  reverse-elasticity test for higher confidence.
inputs:
  - target_segment: from jtbd_interviews
  - sample_size: minimum 100 prospects in the segment
outputs:
  - psm_chart: price sensitivity meter — Cheap / Expensive / Too-Cheap / Too-Expensive
  - acceptable_range: indifference price + optimal price + price stress range
---

# Van Westendorp Price Sensitivity Meter (PSM)

Four questions, asked in this order. **Word for word — order matters.**

1. At what price would you consider this product so **expensive** you would
   not consider buying it? (*Too Expensive*)
2. At what price would you consider this product to be priced so **low**
   that you'd feel the quality couldn't be very good? (*Too Cheap*)
3. At what price would you consider this product starting to get
   **expensive, so that it's not out of the question, but you'd have to
   give some thought** to buying it? (*Expensive*)
4. At what price would you consider this product to be a **bargain — a
   great buy** for the money? (*Cheap / Bargain*)

## Reading the chart

Plot each curve as a cumulative %. Four intersection points:

| Intersection | Meaning |
|---|---|
| Too Cheap × Too Expensive | **Optimal Price Point (OPP)** — equal pain from quality fears and from cost |
| Cheap × Expensive | **Indifference Price Point (IPP)** — most respondents see it as fair |
| Too Cheap × Cheap | **Point of Marginal Cheapness (PMC)** — lower bound of acceptable range |
| Too Expensive × Expensive | **Point of Marginal Expensiveness (PME)** — upper bound |

The **acceptable price range** is between PMC and PME. The strategic
choice within that range depends on positioning:

- Premium / scarcity play → price near PME.
- Land-and-expand / volume play → price between OPP and IPP.
- Trial-driven → start at OPP, plan to step up after retention proves out.

## Three rules

1. **Segment before you average.** SMB and enterprise have different
   curves. Reporting a single OPP across both is malpractice.
2. **Pair with reverse elasticity.** Van Westendorp tells you the
   *acceptable range*. Gabor-Granger ("would you buy at $X? at $Y?")
   tells you the *demand curve inside the range*. You need both.
3. **Re-run after launch.** Stated WTP is consistently inflated 20-40%
   vs. actual behavior. Adjust by your post-launch elasticity.

## When NOT to use Van Westendorp

- Brand-new product categories where respondents have no anchor. They'll
  give you noise.
- Highly-customized B2B sales — list price is fiction; the real price
  comes out in negotiation. Use a deal-desk analysis instead.
- Sub-$10 consumer goods — the cognitive load of the four-question
  battery is bigger than the price they're evaluating.

## Anti-patterns

- Averaging stated WTP across segments — see rule #1.
- Reporting only the OPP — leadership reads it as "the right price"
  rather than "the equilibrium of two fears". Show all four points.
- Sample of 30. PSM needs ≥100/segment for stable curves.
- Survey-only methodology with no in-product price-test follow-up.
  Stated WTP without revealed-preference validation is theater.
- Asking the four questions about a feature, not a packaged product.
  Respondents can't price an unbundled checkbox.
