---
id: market_sizing_tam_sam_som
version: 1.0.0
owners: [market_researcher]
tags: [market, sizing, tam, sam, som, business-case]
when_to_use: |
  Backing a positioning claim with numbers, or supporting a build-vs-
  buy / invest-vs-not decision. Always include in the discovery
  artifact — vague sizing is worse than honest "I don't know".
inputs:
  - target_segments: from jtbd_interviews
outputs:
  - tam_sam_som: three numbers in USD with the calculation shown
---

# TAM / SAM / SOM

**TAM** (Total Addressable Market) — total spend if everyone with the
job bought from us.
**SAM** (Serviceable Addressable Market) — TAM minus segments we can't
reach (geography, regulation, channel).
**SOM** (Serviceable Obtainable Market) — realistic share of SAM in
3 years given competition and our resources.

**Two methods — show your work**

*Top-down*
1. Find a credible industry total ("$X B global SaaS for HR").
2. Multiply by the share that fits the JTBD ("20% of that spend is on
   onboarding").
3. Multiply by the segment we serve ("companies 100-1000 employees =
   35% of that segment").

*Bottom-up*  (preferred when you have unit economics)
1. Number of target accounts × annual spend per account.
2. Then triangulate against the top-down number. If they disagree by
   more than ~2x, one of them is wrong.

**Anti-patterns**
- A TAM that includes everyone. "Everyone uses email" is not a TAM.
- SOM = TAM × 0.01 with no justification.
- Sizing without naming the time horizon.
