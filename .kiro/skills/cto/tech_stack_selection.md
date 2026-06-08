---
id: tech_stack_selection
version: 1.0.0
owners: [cto]
tags: [tech-stack, technology-selection, boring-tech, adr-feed]
when_to_use: |
  At project inception, after the PRD, before project_structure_layout.
  Produces a justified stack that feeds an ADR — guarding against the
  agent's habit of emitting the popular default dressed as a decision.
inputs:
  - prd: product intent and scale expectations
outputs:
  - stack: each layer named + one-line justification + simpler-alternative flag
---

# Tech Stack Selection

A one-line idea fed to "recommend a stack" returns the popular choice plus
confident-sounding rationalization — not a considered design. This skill
makes the choice survive scrutiny.

**Procedure**
1. Name each layer: frontend, backend, datastore, auth, hosting, CI.
2. For each, write a **one-line justification** tied to *this* product's
   real constraints (team skill, scale, deadline, cost) — not generic praise.
3. For each, flag whether a **simpler option** would do and what you'd lose
   by taking it. Bias toward boring, proven tech.
4. Hand the result to `adr_authoring` — the stack is an architecturally
   significant decision and gets recorded with options considered.

```
| Layer    | Choice        | Why (this product)     | Simpler option / cost |
|----------|---------------|------------------------|-----------------------|
| Backend  | <x>           | <constraint-tied>      | <option> — loses <y>  |
```

**Anti-patterns**
- Default + rationalization — the trendy stack with reasons invented after.
- Resume-driven selection — choosing tech to learn it, not to ship.
- Premature-scale tech — Kafka/k8s for an app with zero users.
- No "simpler option" column — hides whether a real trade-off was made.
