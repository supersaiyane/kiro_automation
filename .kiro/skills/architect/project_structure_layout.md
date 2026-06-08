---
id: project_structure_layout
version: 1.0.0
owners: [architect]
tags: [repo-structure, file-layout, conventions, monorepo, docs-home]
when_to_use: |
  Before the first feature is built. Fixes where every kind of file lives —
  including where the pre-build docs themselves live — so a growing codebase
  stays consistent across many agent sessions.
inputs:
  - tech_stack: from tech_stack_selection / ADR
outputs:
  - layout: top-level tree + placement rules + docs home
---

# Project Structure Layout

Agents invent inconsistent structure when none is fixed. Decide it once,
record it in the context file, and every session inherits it.

```
<repo>/
  src/            application code
  tests/          mirrors src/ layout
  docs/           the pre-build doc package lives here ↓
    prd.md
    architecture.md          (stack, layout, data model)
    integration-contracts.md
    decisions/               ADR-001.md, ADR-002.md, …
  infra/          IaC, deploy config
  CLAUDE.md       the living context file (repo root, where agents look)
  .env.example    config keys, never real secrets
```

**Placement rules to record**: where new features go, where shared code
lives, the test-file naming convention, and that secrets never land in `src/`.

**Versioning the living docs**: keep them in-repo under `docs/`, versioned by
git. Material changes get a one-line `## Decisions` entry in `CLAUDE.md` plus,
if architectural, an ADR. That is the whole "how do docs stay current" answer.

**Anti-patterns**
- Folder structure re-derived per session — every agent organizes differently.
- Pre-build docs scattered across chat, wiki, and Drive instead of one `docs/`.
- Premature service split — microservice tree before there's a domain to split.
- `docs/` that no one updates — pair every doc with its owner role + a gate.
