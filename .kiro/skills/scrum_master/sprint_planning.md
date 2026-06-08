---
id: sprint_planning
version: 1.0.0
owners: [scrum_master]
tags: [sprint, planning, capacity, backlog]
when_to_use: |
  Start of every sprint. Convert prioritized stories into a sprint plan
  with goal, capacity, owners, and risks.
inputs:
  - ranked_backlog: stories with RICE or equivalent score
  - team_capacity: person-days available
outputs:
  - sprint_plan: goal, timeline, assignments, risks
---

# Sprint Planning

**Outputs (required)**
1. **Sprint Goal** — one sentence the whole team can recite.
2. **Timeline** — start, end, demo, retro dates.
3. **Assignments** — every story owned by exactly one driver + reviewer.
4. **Risks** — top 3 known unknowns + the trigger to escalate each.

**Capacity rule of thumb**
- 70% of person-days for sprint work
- 20% for support / bugs / interrupts
- 10% slack
Anything ≥90% loaded is a flag, not a stretch goal.

**Anti-patterns**
- Goals like "ship features" — that's not a goal.
- Risks like "API might be slow" with no trigger ("if p95 > 300ms…").
- Loading individuals over capacity to make the plan "fit".
- Skipping the demo or retro because you ran out of time — those are
  load-bearing.
