---
id: rice_prioritization
version: 1.0.0
owners: [product_manager]
tags: [prioritization, planning, backlog, rice]
when_to_use: |
  The backlog has > 5 candidate items and stakeholders need a defensible,
  numerical ranking. Use before the sprint plan is drafted.
inputs:
  - backlog: list of items with reach, impact, confidence, effort
outputs:
  - ranked_backlog: items sorted by RICE score, with explanation per item
---

# RICE Prioritization

**Score = (Reach × Impact × Confidence) / Effort**

- **Reach**: how many users affected per quarter.
- **Impact**: 3 = massive, 2 = high, 1 = medium, 0.5 = low, 0.25 = minimal.
- **Confidence**: 100% high, 80% medium, 50% low. Lower confidence ⇒ lower score.
- **Effort**: person-months (or person-weeks).

**Anti-patterns**
- Don't trust the number blindly — RICE is a sanity check, not a verdict.
  Override with strategic context when needed and document the override.
- Don't tweak confidence to justify the answer you already wanted.
- Effort < 0.5 distorts the ratio; round up.

**Example**

| Item | R | I | C | E | RICE |
|------|---|---|---|---|------|
| SSO  | 5000 | 2 | 0.8 | 2 | 4000 |
| Dark mode | 1000 | 0.5 | 0.5 | 1 | 250 |

Rank by RICE; document which strategic overrides changed the final order.
