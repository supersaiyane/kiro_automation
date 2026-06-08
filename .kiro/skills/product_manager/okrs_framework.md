---
id: okrs_framework
version: 1.0.0
owners: [product_manager, cto, scrum_master]
tags: [okr, objectives, key-results, doerr, grove, planning]
when_to_use: |
  Quarterly or annual planning. When teams are drifting from strategic
  outcomes into feature work. When the answer to "is this the right
  thing to do?" depends on someone's mood instead of an explicit goal.
inputs:
  - strategic_priorities (from CTO / leadership)
outputs:
  - okrs: 2-3 objectives × 3-5 key results, with owners + scoring rubric
---

# OKRs — Objectives + Key Results (Doerr / Grove)

> **Objective** = the qualitative, inspirational goal ("what").
> **Key Results** = quantitative, measurable outcomes ("how we know we got there").
> NOT a task list. NOT a roadmap.

## The shape of a good OKR

```
Objective: <inspirational, qualitative, time-boxed>
  KR1: <metric> from <baseline> to <target> by <date>
  KR2: <metric> from <baseline> to <target> by <date>
  KR3: <metric> from <baseline> to <target> by <date>
```

### Example (good)
**O:** Become the default observability tool for mid-market SaaS.
- KR1: Increase monthly active orgs from 1,200 → 3,000 by end of Q.
- KR2: Reduce time-to-first-trace from signup from 12 min → 2 min.
- KR3: NPS among orgs ≥ 90d on platform from 32 → 50.

### Example (bad)
**O:** Improve the dashboard.  *(not a goal — too vague)*
- KR1: Ship 5 dashboard features.  *(output, not outcome)*
- KR2: Fix all dashboard bugs.  *(unmeasurable; perpetual)*

## Doerr's "FACTS"

- **Focus** — 3 objectives max per team. More = none.
- **Alignment** — team OKRs roll up to org OKRs. Visible to everyone.
- **Commitment** — agreed by the team, not handed down. ~10% can be
  "aspirational" (committed only morally).
- **Tracking** — weekly check-ins on KR progress (0.0-1.0 score).
- **Stretch** — KRs are uncomfortable. 0.7 score on a stretch KR is
  better than 1.0 on a sandbagged one.

## Cascading

```
Company OKR
  Engineering OKR (rolls up)
    Platform Team OKR (rolls up)
      Individual focus areas (informally; NOT individual OKRs)
```

Individual OKRs are an anti-pattern. They become performance reviews
disguised as goals; people sandbag.

## Scoring at end of period

For each KR: 0.0 (no progress) → 1.0 (target hit). Aspirational KRs
target ~0.7. A company hitting all KRs at 1.0 is sandbagging.

Use the conversation, not the score, to decide:
- What did we learn?
- Is the metric still the right one?
- Should the target be more aggressive next period?

## Anti-patterns

- **OKRs as a task list.** "Ship the new auth flow" is not a KR.
  Convert to "Reduce login failures from 3.2% → 1%."
- **KRs that activity-track instead of outcome-track.** "Send 100 sales
  emails" = activity; "Generate 30 qualified meetings" = outcome.
- **Quarterly KRs without weekly check-ins.** You'll discover at end
  of quarter you've been working on the wrong thing.
- **Tying OKRs to comp.** Goodhart's law: people game what they're
  paid on. OKRs become sandbagged. Keep them out of compensation.
- **OKR theater.** Documents written for leadership review, then
  ignored. If nobody references the OKRs week-to-week, they don't exist.
- **Vague rubric** — "we hit it" with no number. Numbers or it didn't
  happen.

## When NOT to use OKRs

- Existential firefighting (sales-to-survival mode — just sell).
- Small teams (< 5 people) where alignment is achieved by being in the
  same room daily.
- Pure maintenance teams with no improvement goals (use SLA tracking).
