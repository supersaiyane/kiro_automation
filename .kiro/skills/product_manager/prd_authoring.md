---
id: prd_authoring
version: 1.0.0
owners: [product_manager]
tags: [prd, requirements, product-definition, mvp, scope]
when_to_use: |
  At project inception, before any architecture or code. Produces the
  single source of product intent that every downstream role reads.
  One PRD per product, kept living — not regenerated per sprint.
inputs:
  - problem_statement: what hurts, for whom
  - target_user_notes: who this is for
outputs:
  - prd: structured doc (problem, users, vision, features, flow, metrics, scope cuts)
---

# PRD Authoring

The PRD answers *what* and *why* before anyone touches *how*. Keep it
plain-language — a non-technical founder must be able to read it.

```
# PRD: <Product name>

## Problem
The problem, who has it, why it matters. 3–6 lines, no jargon.

## Target Users
The actual person: context, tech comfort, what they want, what frustrates them.

## Vision
One or two lines. The north star.

## Core Features
Each: name · one-line description · [must-have | nice-to-have].

## User Flow
Landing → goal, every screen and decision point in plain language.

## Success Metrics
How we know it works. 2–4 metrics, one is the north-star.

## NOT Building in v1   ← the spine, not a footnote
See skill: mvp_scope_definition. The explicit cut list lives here.
```

**Rule**: the "NOT Building" section is the most load-bearing part. A PRD
without an uncomfortable cut list has not made a decision yet — hand it to
`mvp_scope_definition` before it leaves this role.

**Anti-patterns**
- Feature list with no must/nice tags — everything reads as mandatory.
- "NOT Building" missing or one line long — scope creep is already winning.
- Written once and never updated as the product learns — it rots into fiction.
- Jargon ("RLS", "OAuth", "e2e") in a doc that claims to be founder-readable.
