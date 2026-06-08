---
id: velocity_capacity_modeling
version: 1.0.0
owners: [scrum_master]
tags: [velocity, capacity, story-points, forecasting, planning]
when_to_use: |
  Sprint planning, quarterly OKR setting, or any conversation that
  starts with "can we ship X by Y?" Velocity is for forecasting
  ranges; it is not a performance metric.
inputs:
  - last_6_sprints: story points completed (not committed)
  - upcoming_capacity: PTO, on-call, hiring ramp
outputs:
  - forecast: 50% / 80% / 95% confidence ranges
  - capacity_for_sprint_N: realistic story-point envelope
---

# Velocity & Capacity Modeling

## Velocity is a *forecasting input*, not a *target*

**The moment you make velocity a goal, you destroy its value as a
predictor.** Engineers will inflate estimates, split stories
artificially, and the number becomes Goodhart's-law fiction.

Use velocity to *predict* what you can ship. Don't use it to evaluate
individuals or teams.

## The numbers worth tracking

1. **Completed story points per sprint** (not committed). Track 6
   sprints rolling.
2. **Completion ratio** = completed / committed. Healthy: 0.85-1.10.
   - <0.7 sustained: over-committing. Stop.
   - >1.15 sustained: under-committing. Stretch.
3. **Cycle time** per story (start → done). The distribution shape
   matters more than the average — a fat tail predicts surprise.
4. **Throughput** (stories closed / week), independent of point sizes.
   When points drift, throughput stays comparable.

## Capacity arithmetic for the next sprint

Team headcount × working days × focus factor = available person-days.

- **Working days** = sprint length − PTO − holidays − all-hands days.
- **Focus factor** = 0.6-0.7 (NOT 1.0). On-call, support, code review,
  meetings, recruiting take 30-40% of time.
- **Subtract on-call**: a person on primary on-call delivers ~30% of
  normal. Secondary on-call: ~70%.

Translate person-days → story points via your last 6-sprint average:
`points/person-day`. Multiply. That's the sprint envelope.

## Three-point forecasting

For any commitment ≥1 sprint out, give a range, not a date:

- **50% confidence**: median completion date.
- **80% confidence**: more conservative — multiply remaining points by
  your 80th-percentile per-sprint velocity (typically ~0.85× of mean).
- **95% confidence**: planning floor — typically ~0.6-0.7× of mean.

Communicate as: "We'll likely finish in 4 sprints (50% confident), but
plan for 5 (80%), and don't promise anything externally before 6 (95%)."

If you give a single date, you're lying. Even if you don't know it.

## Re-baselining triggers

Re-compute the rolling velocity *immediately* when:
- Team size changes (gain or loss, even one person on a 5-person team).
- Stack changes (new framework, new infra).
- On-call rotation changes.
- Quarter-boundary process changes (new review gate, new tool).

Don't carry stale velocity into a new context.

## What story points are (and aren't)

- **Are**: relative-effort ladder. A 5 is roughly 5× a 1.
- **Are not**: hours. Stop the "1 point = N hours" conversion. It
  destroys the relativity.
- **Are not**: a productivity ranking. Sprint A: 30 points. Sprint B:
  35 points. Doesn't mean sprint B was 17% better — could be a
  scoping difference.

If your team can't agree on a 1-point reference story, your scale
is broken. Re-anchor with a planning poker session before the next
sprint.

## Anti-patterns

- "Velocity is up 20% this quarter!" — usually point inflation, not
  productivity.
- Comparing velocity across teams. Different scales; meaningless.
- Forecasting from a single recent sprint. One sprint is a sample of
  one.
- Committing to 100% of capacity. No slack means no time for
  unexpected bugs, fix-loops, or learning.
- Hiding a vacation or two from the capacity calculation because "they
  can make it up." They can't.
- A green sprint with a chronically empty "completed" column on one
  person — the team is masking. Investigate, don't ignore.
- "We don't track velocity, we go by gut." Your gut is also subject
  to confirmation bias and recency effects. Numbers + judgment, not
  numbers vs. judgment.
