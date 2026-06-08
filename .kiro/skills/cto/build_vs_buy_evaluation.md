---
id: build_vs_buy_evaluation
version: 1.0.0
owners: [cto]
tags: [strategy, build-vs-buy, vendor, tco]
when_to_use: |
  Any significant capability that could be built in-house OR purchased
  from a vendor: auth, payments, observability, messaging, search.
  Required output of the STRATEGY phase for every such component.
inputs:
  - component: name + the capability it provides
  - candidate_vendors: 2-3 options the architect has surfaced
outputs:
  - decision: build | buy | partial — with explicit rationale
  - approved_vendor: if buy, which one
---

# Build vs Buy Evaluation

**Default**: buy commodity, build differentiating. The system's
competitive moat is what you should build; everything else, rent.

**Decision matrix (score each on 1–5)**

| Factor                           | Weight | Build | Buy |
|----------------------------------|--------|-------|-----|
| Differentiation for our product  | 0.30   |       |     |
| Time-to-market                   | 0.20   |       |     |
| 3-year TCO                       | 0.15   |       |     |
| Operational burden (on-call)     | 0.15   |       |     |
| Vendor lock-in risk              | 0.10   |       |     |
| Compliance / data sensitivity    | 0.10   |       |     |

Higher weighted total wins. The matrix is a SANITY CHECK, not the
verdict — the CTO writes the decision and rationale, the matrix
explains the math.

**Anti-patterns**
- "Build" because NIH (not invented here). You're not Google.
- "Buy" without modeling exit cost (data export, contract escape).
- Choosing on year-one cost only. SaaS bills compound.
- Skipping the "partial" option (host open source, integrate via
  managed service for non-critical paths).
