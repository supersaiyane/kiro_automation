---
id: tech_strategy_framework
version: 1.0.0
owners: [cto]
tags: [strategy, principles, constraints, vendor-approval]
when_to_use: |
  Required artifact of the STRATEGY phase. Sets the rules the
  Architect (and every downstream role) cannot override without
  re-escalating to the CTO.
inputs:
  - market_research: target segments + sizing
  - prd: product goals
outputs:
  - strategic_principles: 3-5
  - constraints: explicit yes/no
  - approved_vendors: with rationale
---

# Technical Strategy Framework

**1. Strategic Principles (3-5 max)**
Each principle is short, opinionated, falsifiable.
Examples:
- "API-first — every internal capability is also an external one."
- "Buy commodity, build the differentiator (search ranking)."
- "Compliance-by-construction — every PII path has an audit log."

If a principle could apply to any company, it's not a principle.

**2. Constraints (explicit yes/no)**
Examples:
- ✅ Postgres for OLTP. ❌ No new MongoDB.
- ✅ Python 3.12 + TypeScript. ❌ No Java in new services.
- ✅ AWS primary, GCP for ML only. ❌ No new Azure footprint.

The Architect references the constraint by id when designing.

**3. Approved Vendors**
Listed with: capability, contract status, exit cost estimate.
Anything not on the list requires a build-vs-buy evaluation
(see skill: `build_vs_buy_evaluation`) before adoption.

**4. Decisions log**
Every approve/reject decision recorded with date + rationale.
Future architects look here to understand "why didn't we do X?"

**Anti-patterns**
- Principles that are platitudes ("we value quality").
- Constraints that are "guidelines" — they're either binding or absent.
- Approved-vendor lists with no exit cost: lock-in by neglect.
- Strategy that doesn't reference the market research it derives from.
