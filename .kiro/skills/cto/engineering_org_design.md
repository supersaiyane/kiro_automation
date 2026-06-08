---
id: engineering_org_design
version: 1.0.0
owners: [cto]
tags: [org-design, conway, team-topologies, scaling, hiring]
when_to_use: |
  Crossing 10, 30, 80, 200 engineers. Reorgs aren't free — do them
  when the org shape has stopped matching the architecture, not on
  a cadence.
inputs:
  - current_org_chart, current_architecture, 12-month roadmap
outputs:
  - team_topology: stream-aligned / platform / enabling / complicated-subsystem teams
  - hiring_plan: with explicit team sizes + ratios + interfaces
---

# Engineering Org Design (Conway + Team Topologies)

## Conway's Law restated

> Any organization that designs a system will produce a design whose
> structure is a copy of the organization's communication structure.

Corollary: **the inverse** — to get a clean architecture, design the
org around the architecture you want. Reorg first, then ship.

## Four team types (Team Topologies)

| Type | Job | Size | Lifespan |
|---|---|---|---|
| **Stream-aligned** | Own a user-facing slice end-to-end | 5-9 | Indefinite |
| **Platform** | Internal product for stream-aligned teams (CI/CD, observability, data platform) | 6-12 | Indefinite |
| **Enabling** | Time-boxed help: bring a capability to stream-aligned teams (security training, k8s migration), then dissolve | 3-5 | 3-6 months |
| **Complicated-subsystem** | Owns a deeply specialized component (ML model, real-time engine, payment ledger) | 4-8 | Indefinite |

**Rule**: 60-70% of engineers should be on stream-aligned teams. If
you're below 50%, platform is over-built and shipping has slowed.

## Three interaction modes

- **Collaboration**: two teams in the same trenches for a defined period.
  Use for ill-defined boundaries; expensive — minimize.
- **X-as-a-Service**: platform team provides a product, stream teams consume.
  Default mode after the boundaries are clear.
- **Facilitating**: enabling team coaches; doesn't write the consumer's code.

Document the interaction mode per pair. Implicit modes = friction.

## Team size

- **2-pizza rule** (Bezos): 5-9. Below 5 = single point of failure +
  fragile on-call. Above 9 = communication overhead dominates.
- A team with two managers is two teams.
- A team smaller than 4 should *not* own on-call alone.

## Scaling thresholds (rough)

| Headcount | What breaks first |
|---|---|
| ~15 | The "everyone in one room" coordination. Need explicit team charters. |
| ~30 | Hiring outpaces onboarding capacity. Bring up an enabling team. |
| ~50 | Platform team becomes necessary; without one, every stream rebuilds infra. |
| ~80 | Director layer needed; ICs can't span the company anymore. |
| ~150 | Tooling that worked breaks (shared monorepo CI, single Slack channel). |
| ~300 | Conway pays you back hard — the architecture either matches the org or grinds. |

## Hiring ratios (steady state)

- **Senior-to-junior**: 60/40 minimum. Below that, juniors don't get
  mentorship and seniors burn out reviewing.
- **IC-to-manager**: 7±2 reports. Above 9, the manager becomes a
  bottleneck; below 5, the manager is doing IC work and pretending not to.
- **EM to staff/principal IC**: 1:1 at the senior level. Without a
  strong staff+ track, you lose your best ICs to other companies.

## Reorg checklist

Before announcing:
- [ ] The architecture this org shape produces is the architecture you want.
- [ ] Every team has: a charter, an owner, on-call rotation, an SLO,
      a stream of work for ≥6 months.
- [ ] No team is created for one person.
- [ ] Reporting lines moved no more than once per person in 12 months.
- [ ] The interaction modes between new teams are documented.
- [ ] Comms plan: pre-brief skip-levels, then EMs, then all-hands, then
      individual 1:1s for anyone whose manager changed.

## Anti-patterns

- Reorganizing because morale is low. Morale is a symptom; fix the cause.
- "Pizza-team" platforms — splitting platform into many 5-person teams.
  Platforms need depth, not breadth at this size.
- Org-chart fiction: titles that don't match decision authority.
  Engineers learn the real graph in a week.
- One-off "tiger team" that never dissolves. Set a sunset date or
  classify it correctly as a stream-aligned team from day one.
- Reorgs every 9 months. Engineers stop investing in their team
  because they assume the next reorg will scramble it.
