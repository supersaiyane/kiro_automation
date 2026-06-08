---
id: positioning_april_dunford
version: 1.0.0
owners: [market_researcher, product_manager]
tags: [positioning, market, dunford, obviously-awesome, category]
when_to_use: |
  Re-positioning a product, launching into a new segment, or sharpening
  a sales pitch that "everyone keeps misunderstanding." Run this BEFORE
  redoing the website or sales deck — they're outputs of positioning,
  not inputs.
inputs:
  - target_segments + competitive_landscape from market research
outputs:
  - positioning_canvas: 5 (+1) components with concrete entries
  - chosen_market_category: the frame customers will perceive you in
---

# Positioning — April Dunford's "Obviously Awesome" Framework

> Positioning is **the context you choose to be evaluated in**. It is
> NOT a tagline, NOT branding, NOT a pitch deck. It is upstream of all
> of those. Get this wrong and every downstream message gets weaker;
> get this right and the same product suddenly converts 2-3x.

## The 5 (+1) components — fill these in this exact order

### 1. Competitive Alternatives
What would the customer do if your product didn't exist? Be **specific
and honest**:
  - Named direct competitors
  - Adjacent tools (e.g. spreadsheets, manual processes)
  - The "do nothing" alternative
List ≥ 3. If you can't think of an alternative, the customer doesn't
have the problem you think they do.

### 2. Unique Attributes
Features YOU have that the alternatives don't. Concrete and verifiable
— not "easier" or "more intuitive." Examples:
  - "Multi-tenant by default; competitor X requires separate instance per customer"
  - "Real-time sync with sub-100ms p99 latency"
  - "SOC 2 Type II from launch"

### 3. Value (with proof)
For each attribute, translate it into customer-meaningful value AND
provide proof. "Multi-tenant" → "onboard a new customer in 5 minutes
instead of 5 days" → "customer testimonial / metric / case study".
Without proof, value claims are noise.

### 4. Target Customer Characteristics
The slice of the market that values your unique attributes the MOST.
NOT a demographic; a behavioral / situational segment:
  - "VP of Eng at 100-500 person SaaS companies who got paged 3+ times
    last month for the same incident class"
NOT: "developers at fast-growing companies."

### 5. Market Category
The frame you put the product in so customers know what to compare it
to. Pick deliberately:
  - **Existing category, niche play**: "Project management for marketing teams"
  - **Existing category, win on a wedge**: "Notion, but for engineering docs"
  - **New category creation**: "Customer Data Platform" (Segment, 2015)
Most products win on niche or wedge. New-category creation is high
risk + high cost; reserve for products that genuinely don't fit any
existing frame.

### 6. (Bonus) Relevant Trends
Macro shifts that make NOW the moment for this product. Use sparingly
— if you can't tie the trend to a buying decision, don't include it.
"AI is hot" is not a trend; "regulators just mandated SOC 2 for
processors with revenue > $X" is.

## The positioning STATEMENT format

After filling the canvas, condense to one paragraph for sales /
website / internal alignment:

> For **[target customer]**, who **[has problem / context]**,
> **[product name]** is a **[market category]** that
> **[key benefit/value]**.
> Unlike **[primary competitive alternative]**,
> **[our unique attributes that deliver the value]**.

## Anti-patterns

- "We're the [Uber] for [X]" — lazy borrowed-category positioning.
- Hedging the category ("We're a sales tool, but also kind of a
  marketing tool, and CFOs love us too"). Pick one.
- Mistaking branding for positioning. The Stripe logo doesn't position
  Stripe; "developer-first payments infrastructure" does.
- Positioning written by the founder alone, never sales-tested.
  Validate by watching a salesperson use it in five real conversations.
- Re-positioning every quarter. Positioning compounds; constant
  changes destroy the compound.

## Validation checklist

- [ ] Could a brand-new salesperson explain the positioning in 30s?
- [ ] Does the target customer recognize themselves in the description?
- [ ] Are the unique attributes verifiable (a competitor can't legally
      claim them)?
- [ ] Does the chosen category set expectations the product can meet?
