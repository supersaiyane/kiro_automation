# Project Map

## Workspace: anothertest

### .kiro/ Structure
```
.kiro/
├── docs/                   ← (empty, Kiro internal)
├── hooks/
│   ├── elite-team-orchestrator.kiro.hook
│   ├── enforce-orchestrator-pipeline.kiro.hook
│   ├── context-rot-detection.kiro.hook
│   ├── 01-token-discipline.kiro.hook
│   ├── 02-context-discipline.kiro.hook
│   ├── 03-memory-discipline.kiro.hook
│   ├── 04-auto-memory-retrieval.kiro.hook  ← agentmemory query on promptSubmit (v2.0)
│   └── 05-compression-feedback.kiro.hook   ← Learn from compression failures
├── init_docs/
│   ├── checkpoint.md       ← Session resume vectors
│   ├── lessons.md          ← Self-improvement rules (2 entries)
│   ├── decisions.md        ← ADR index (ADR-001 to ADR-015)
│   └── project_map.md     ← THIS FILE
├── skills/                 ← 19 role skill directories (all SKILL.md fixed with frontmatter)
│   ├── market_researcher/
│   ├── cto/
│   ├── product_manager/
│   ├── architect/
│   ├── database_architect/
│   ├── cloud_architect/
│   ├── finops_architect/
│   ├── security_engineer/
│   ├── scrum_master/
│   ├── backend_lead/
│   ├── frontend_lead/
│   ├── senior_engineer_be/
│   ├── senior_engineer_fe/
│   ├── ml_engineer/
│   ├── qa_engineer/
│   ├── devops_engineer/
│   ├── sre_engineer/
│   ├── technical_writer/
│   └── website_creator/
├── settings/
│   └── mcp.json                        ← Mem0 MCP server config (NEW v2.0)
└── steering/
    ├── orchestrator-routing.md         ← Mode detection + discovery-first enforcement (always)
    ├── discovery-engine.md             ← 7-question scoping + scoring + agent activation (always)
    ├── team-orchestrator.md            ← Full army constitution (manual-inclusion)
    ├── skill-selection-matrix.md       ← Targeted skill loading rules (always)
    ├── context-memory-discipline.md    ← Core budget/caveman/headroom (~100 lines, always)
    ├── memory-management.md            ← Retrieval/archival/poisoning (conditional: init_docs/**)
    └── phase-reporting.md              ← Report templates (conditional: docs/phase-*/**)
```

### docs/ (CalcApp artifacts — Mode 1 DESIGN phase, paused at Scrum Master)
```
docs/
├── foundation/
│   ├── market-research.md   ← Market Researcher (THINK, complete)
│   ├── vision-strategy.md   ← CTO Strategy (THINK, complete)
│   ├── system-design.md     ← Architect: C4 diagrams, APIs, ADRs, Gantt (DESIGN, complete)
│   ├── erd.md               ← DB Architect: ER diagram, indexes, retention (DESIGN, complete)
│   ├── schema.sql           ← DB Architect: DDL + RLS + triggers (DESIGN, complete)
│   ├── cloud-design.md      ← Cloud Architect: infra, HA/DR, scaling (DESIGN, complete)
│   ├── finops-design.md     ← FinOps: unit economics, projections (DESIGN, complete)
│   └── security-design.md   ← Security: STRIDE, OWASP, auth, compliance (DESIGN, complete)
└── product/
    └── prd.md               ← Product Manager: 21 stories, 100 pts, 3 phases (DESIGN, complete)
```

### Key State
- **CalcApp:** Mode 1, DESIGN phase. 8/9 docs complete. Scrum Master (roadmap + sprint plan + GATE 2) pending.
- **REST Tester:** Mode 3, COMPLETE. Vue 3 + Vite + Tailwind mini-Postman at rest-tester/.
- **Orchestrator:** Discovery-first routing enforced. 7 questions → score → selective agent activation.
- **All 19 SKILL.md files:** Fixed with proper `name` + `description` frontmatter.
- **Disciplines:** v2.0 — split into 3 files (core always ~100 lines + 2 conditional). GREEN.
- **agentmemory MCP:** Configured in .kiro/settings/mcp.json. Local-only, no API key needed (ADR-015).
- **ADRs:** 15 active decisions (ADR-001 to ADR-015).
- **howtodosetup.txt:** Complete agentmemory installation + configuration guide (root).
- **Lessons:** 2 entries (mode-first, discovery-before-mode-overkill).
