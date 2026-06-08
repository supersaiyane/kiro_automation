---
id: adr_authoring
version: 1.0.0
owners: [architect]
tags: [adr, architecture, decision, documentation]
when_to_use: |
  Any architecturally significant choice — technology selection, data
  model, integration pattern, auth strategy, security boundary. Capture
  before implementation, not after.
inputs:
  - decision_topic: short description of the choice
  - options_considered: at least 2 alternatives
outputs:
  - adr: structured record with Context, Decision, Consequences, Status
---

# ADR Authoring

```
# ADR-NNN: <Short, decision-focused title>

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXX

## Context
What problem are we solving? What forces are in play (performance, team
skill, cost, deadline)? Use 4–8 lines, not 4 pages.

## Decision
The specific choice. One sentence. Bold it. The body explains why this
option won.

## Options Considered
- Option A: pros / cons
- Option B: pros / cons
- (selected) Option C: pros / cons

## Consequences
What becomes easier? What becomes harder? What did we owe a future
maintainer?
```

**Anti-patterns**
- ADRs written after the fact to justify what already shipped.
- Multiple decisions per ADR — split them.
- No "Options Considered" — looks like there was no real choice.
- Status never updated; old ADRs read as current when they're not.
