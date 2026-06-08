---
id: living_context_file
version: 1.1.0
owners: [scrum_master]
tags: [context, runtime-memory, claude-md, agents-md, conventions, single-source-of-truth, planning]
when_to_use: |
  In the planning phase, before any code is written, and updated at the end
  of every working session. Produces the one file an AI coding agent re-reads
  at the start of every run. Authored early by the planning-phase coordinator
  (scrum_master) so downstream development roles inherit it.
inputs:
  - project_summary: one paragraph
  - conventions: naming, structure, required/forbidden libraries, test/lint commands
outputs:
  - context_file: CLAUDE.md / AGENTS.md / CONTEXT.md, < 200 lines, skimmable
---

# Living Context File

Static specs drift; this file is re-read on every agent run, so keeping it
correct keeps every session correct. It is the highest-leverage document in
the pre-build set and the one you never let go stale. Authored in the planning
phase so every later role reads it instead of re-deriving conventions.

**Mechanism (state this, don't assume it):** the agent loads this file at
session start (Claude Code -> `CLAUDE.md`; other tools -> `AGENTS.md`/`CONTEXT.md`).
It is context, not documentation -- density beats completeness.

```
# <Project> — Agent Context

## Summary        one paragraph: what this is.
## Current State  built / in-progress / broken. Changes most often.
## Conventions    naming · file layout · required libs · FORBIDDEN libs ·
                  test command · lint command.
## Decisions      dated one-liners: "Chose X over Y because Z."
## Don'ts         things the agent keeps trying that you don't want.
## Pointers       links to PRD, architecture, integration contracts.
```

**Maintenance rule**: update at the *end* of any session that changed the
project's shape. A stale context file is a bug, tracked like one.

**Anti-patterns**
- Write-once-and-rot — the file no longer matches the code within days.
- Dumping the full architecture in here — keep depth in pointed docs, link them.
- Listing decisions without the *why* — the agent re-litigates settled choices.
- No "Don'ts" — the agent repeats the same unwanted move every session.