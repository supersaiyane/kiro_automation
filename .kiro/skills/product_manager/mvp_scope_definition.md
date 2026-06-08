---
id: mvp_scope_definition
version: 1.0.0
owners: [product_manager]
tags: [mvp, scope, prioritization, cut-list, anti-overbuild]
when_to_use: |
  Immediately after core features are listed, before architecture begins.
  Forces an explicit cut list so the army builds the smallest thing that
  reaches market, not the most complete thing imaginable.
inputs:
  - core_features: the must/nice list from the PRD
outputs:
  - cut_list: features deferred to v2+, each with a reason
  - v1_definition: the minimal shippable surface
---

# MVP Scope Definition

The default failure mode of a capable builder is over-building before market
contact. This skill is the forcing function against it.

**The procedure**
1. For every "must-have", ask: *does v1 reach its success metric without this?*
   If yes → demote to the cut list.
2. For every "nice-to-have", default it to the cut list. Promotion needs a
   one-line reason tied to the north-star metric.
3. Write the cut list as a first-class artifact, not a footnote. Each entry:
   `<feature> — deferred because <reason>; revisit at <trigger>`.
4. Read the cut list aloud. If none of it makes you slightly nervous, the
   list is too short — cut more.

**Output shape**
```
## v1 (build this)
- <feature> — reaches metric X
## Deferred (NOT building in v1)
- <feature> — deferred because <reason>; revisit when <trigger>
```

**Anti-patterns**
- "Must-have" inflation — every feature reclassified as essential.
- Cut list with no triggers — deferral with no plan to ever revisit.
- Scoping by feature count instead of by the metric each feature moves.
- Letting architecture start before the cut list exists (it will be built for).
