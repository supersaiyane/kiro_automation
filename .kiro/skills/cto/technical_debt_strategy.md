---
id: technical_debt_strategy
version: 1.0.0
owners: [cto, architect]
tags: [tech-debt, fowler, refactoring, prioritization, strategy]
when_to_use: |
  Engineering velocity has dropped or every new feature seems to break
  something old. Or you're approaching a major architectural inflection
  (10x scale, new platform). You need a SHARED LANGUAGE about debt to
  prioritize it against features.
inputs:
  - velocity_trend, incident_trend, eng_satisfaction_signal
outputs:
  - debt_register: typed + prioritized + scheduled
  - debt_policy: how much new debt is allowed per quarter
---

# Technical Debt Strategy

## Fowler's Tech-Debt Quadrant

The first thing to clarify: not all debt is the same.

|  | **Reckless** | **Prudent** |
|---|---|---|
| **Deliberate** | "We don't have time for design." (shipping panic — usually wrong) | "We must ship now and deal with consequences." (deliberate, owned, documented) |
| **Inadvertent** | "What's layering?" (lack of skill / awareness) | "Now we know how we should have done it." (learning surfaces older choices) |

Different quadrants get different responses:
- **Reckless-deliberate**: stop. Talk to the team about engineering culture.
- **Prudent-deliberate**: pay back on a scheduled cadence; the cost is the price of speed.
- **Inadvertent reckless**: training + code review + standards.
- **Inadvertent prudent**: re-architect when the cost of carrying exceeds the cost of fixing.

## The debt register

Treat tech debt like financial debt — explicit, named, with a payback plan.

| ID | Class | Description | Interest (cost / sprint) | Principal (cost to fix) | Owner | Due |
|---|---|---|---|---|---|---|
| TD-001 | Reckless-deliberate | Auth uses session ID in URL | 4 hours / sprint (security review overhead) | 3 days | @sec | 2026-Q3 |
| TD-002 | Prudent-inadvertent | No idempotency on payment endpoints | 1 incident / quarter | 5 days | @be-lead | 2026-Q2 |

**Interest** is the cost you pay every sprint for not having paid it
down yet. If the interest > 1 person-day/sprint, prioritize.
**Principal** is the cost to pay it back. Compare interest × expected
remaining-time to principal for the ROI.

## Debt budget per quarter

A team that ships only features will be unable to ship in 18 months.
A team that only pays debt will be replaced in 6 months. Balance:

| Mode | Feature work | Debt + reliability |
|---|---|---|
| Growth (most teams, most of the time) | 70% | 30% |
| Stability (post-incident or pre-scaling event) | 40% | 60% |
| Maintenance (mature product) | 30% | 70% |

The CTO sets the mix per team per quarter. The team can't unilaterally
shift it without explicit conversation.

## Identifying high-priority debt

The four signals:
1. **Repeated outages from the same area** — that area has interest.
2. **Velocity decline** — story points done / sprint dropping over 3+
   sprints. Look at where the time goes.
3. **High inter-team coordination cost** — N teams need to align for one
   change = coupling that should be debt-reduced.
4. **Onboarding pain** — new engineers say "this took me 3 weeks to
   understand" = comprehension debt.

## Strategic patterns for paying down debt

1. **Strangler Fig** (Martin Fowler) — wrap the legacy with a façade;
   route new functionality through new code; gradually retire the
   legacy. Avoids the "big rewrite that never ships."
2. **Branch by Abstraction** — introduce an abstraction layer first,
   then route through it, then swap the implementation. Avoids long-
   lived feature branches.
3. **Test before refactor** — characterization tests pin existing
   behavior so refactors don't silently break.
4. **Documentation refresh** — sometimes the debt is comprehension,
   not code. Fix the docs first; saves the rewrite.

## Anti-patterns

- **Big rewrites** ("We'll rewrite the whole thing in Rust over the
  next 6 months"). Almost always fail. Incremental over rewrite.
- **Tech-debt sprints** with no follow-up — pay 1 sprint, accumulate 6
  worth of new debt over the next quarter.
- **Debt that's "in someone's head"** but not in the register. Out of
  sight = unprioritized = compounding.
- **Refactoring without tests.** You can't tell if you broke anything;
  inevitably you did.
- **Justifying speed by promising future cleanup.** Almost never
  happens. Write the debt item AT THE TIME, with a due date.

## Communication outside engineering

When PM or sales push back on debt work, translate to their language:
- "Without this, we'll lose 2 days/sprint to maintenance — that's one
  feature per quarter we can't ship."
- "Without this, our SOC 2 audit fails."
- "Without this, every change to module X requires manual QA across
  3 teams."
