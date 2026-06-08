---
inclusion: always
---

# Orchestrator Routing Rule (Lightweight Router)

This file ONLY handles intent detection and routing. The full team constitution,
role definitions, artifact chain, gates, and git rules live in `team-orchestrator.md`.

---

## MANDATORY: DISCOVERY-FIRST (before mode selection, before ANY work)

**CRITICAL RULE:** On the FIRST request of any new development task (BUILD/CREATE/MAKE/DEVELOP/IMPLEMENT + APP/TOOL/SYSTEM/etc.), the **Discovery Engine** (`discovery-engine.md`) runs FIRST.

**Execution order:**
1. Discovery Engine asks 7 scoping questions
2. Score answers → determine complexity tier
3. Recommend mode + agent subset
4. User confirms (or overrides)
5. THEN orchestrator-routing activates the confirmed mode

**Discovery Engine takes priority over this file's mode detection logic.** This file only fires AFTER discovery completes and mode is confirmed.

**Bypasses (skip discovery, go direct to mode):**
- User says "mode N" explicitly → skip discovery, use that mode with full agent set
- User says "just build it" / "skip questions" → Mode 3 (Direct Execution)
- Request is NOT a build (bug fix, refactor, question) → Mode 3 directly

---

## MANDATORY: MODE SELECTION FIRST (before ANY work begins)

**CRITICAL RULE:** On the FIRST request of any new development task (BUILD/CREATE/MAKE/DEVELOP/IMPLEMENT + APP/TOOL/SYSTEM/etc.), you MUST present mode options to the user BEFORE doing anything else. No auto-detection. No assumptions. The user picks their mode explicitly.

**Present these options using user_input tool:**

| Mode | Name | Description |
|------|------|-------------|
| Mode 1 | Full Army Pipeline | All roles, multi-phase, full docs + reports. Best for production-grade apps. |
| Mode 2 | Single Agent | One role only (research, architecture, sprint plan, etc.). Best for isolated deliverables. |
| Mode 3 | Direct Execution | Just code it. No orchestrator, no docs overhead. Best for quick scripts/prototypes. |
| Mode 4 | Hybrid (Spec + Army) | Spec planning first (requirements → design → tasks), then army execution. Best for structured development with planning phase. |

**Once the user selects a mode, that mode is LOCKED for the entire development session.** Do not re-ask. Do not switch modes unless the user explicitly requests it.

**If user says "mode N" in their initial prompt** → skip the selection prompt, use that mode directly.

---

## ROUTING: 4 Modes (reference for execution after selection)

### EXPLICIT MODE OVERRIDE
**Trigger:** Prompt contains "mode 1", "mode 2", "mode 3", or "mode 4" (case-insensitive).
**Action:** Skip mode selection prompt. Activate the specified mode directly.
**Priority:** Explicit override > mode selection prompt.
Examples: "mode 1: build a chess app" → Full Army. "mode 4: create a dashboard" → Hybrid.

### MODE 1: Full Army Pipeline
**Trigger:** Prompt contains BUILD/CREATE/MAKE/DEVELOP/IMPLEMENT combined with
APP/TOOL/SYSTEM/PRODUCT/SERVICE/FEATURE/UI/API/DASHBOARD/BOT/AGENT/WEBSITE/PIPELINE

**Action:** Invoke `team-orchestrator.md` constitution. 
**IMPORTANT:** Load `#team-orchestrator` steering file into context FIRST (it is manual-inclusion, not always-loaded).
Run full Think → Design → Develop chain.
- ALL roles fire (per team-orchestrator.md role registry)
- Multi-phase: ≥2 phases, ≥2 sprints/phase, ≥3 tasks/sprint
- 8 docs per phase in docs/phase-N/
- Security/QA/DevOps tasks mandatory in sprint plan
- Git discipline per team-orchestrator.md rules
- Mapping + Discipline reports at phase end

**NEVER:**
- Write code before docs
- Skip any gate
- Collapse to single phase

---

### MODE 2: Single Agent Invocation
**Trigger:** Prompt targets ONE specific role without full pipeline intent.

| User Intent Pattern | Role Invoked | Output |
|-------------------|-------------|--------|
| "research / market analysis / competitor / opportunity" | Market Researcher | market-researcher doc |
| "tech strategy / tech stack / build vs buy / scalability" | CTO | cto-strategy doc |
| "user stories / PRD / requirements / feature spec / acceptance criteria" | Product Manager | PRD doc |
| "architecture / system design / data model / API design / sequence diagram" | Architect | architecture doc |
| "sprint plan / tasks / backlog / estimate / velocity" | Scrum Master | sprint-plan doc |
| "security review / threat model / vulnerability / audit / OWASP" | Security Engineer | security doc |
| "test plan / test cases / QA / testing / coverage" | QA Engineer | test-plan doc |
| "CI/CD / deployment / infrastructure / monitoring / DevOps / IaC" | DevOps Engineer | devops-plan doc |
| "database design / schema / ER diagram / migration" | Database Architect | schema doc |
| "cloud architecture / VPC / landing zone / multi-region" | Cloud Architect | cloud doc |
| "cost analysis / FinOps / budget / unit economics" | FinOps Architect | finops doc |
| "SLI / SLO / observability / incident / runbook" | SRE Engineer | sre doc |
| "documentation / API docs / runbooks / ADR index" | Technical Writer | docs |

**Action:** Invoke ONLY that role. Produce its document (≥300 words, full depth, same template as pipeline). No other roles, no phases/sprints, no git unless asked.

---

### MODE 3: Direct Execution
**Trigger:** Neither Mode 1, Mode 2, nor Mode 4 matches.
- Bug fix, refactor, style change, conversational question, debugging

**Action:** Proceed directly. No orchestrator invoked.

---

### MODE 4: Hybrid (Spec + Army)
**Trigger:** Prompt contains BUILD/CREATE/MAKE/DEVELOP/IMPLEMENT + APP/TOOL/SYSTEM/... AND user explicitly requests "mode 4" OR "hybrid".
Also activates when Kiro spec workflow is running AND Mode 1 would normally trigger.

**Action:** Two-phase hybrid approach:
1. **Planning phase** — Use Kiro spec workflow (.kiro/specs/) for requirements.md → design.md → tasks.md
2. **Execution phase** — Once tasks.md is generated, switch to Mode 1 army pipeline for implementation:
   - Load `#team-orchestrator` steering file
   - Use spec's requirements.md as PRD input (skip Market Researcher + CTO Think phase)
   - Use spec's design.md as architecture input (skip Architect design from scratch)
   - Run Develop chain: sprints, all engineering roles, gates, reports
   - Multi-phase: ≥2 phases, ≥2 sprints/phase, ≥3 tasks/sprint
   - All 6 reports per phase (QA, Security, Mapping, Discipline, Jira, Git)

**Key difference from Mode 1:** Think + Design phases are replaced by Kiro spec system. Develop phase uses full army pipeline.

**Artifacts produced:**
- `.kiro/specs/{name}/` — requirements.md, design.md, tasks.md (planning)
- `docs/phase-N/` — sprint plans, code, tests, reports (execution)

**NEVER:**
- Write code during planning phase
- Skip army roles during execution phase
- Collapse execution to single phase

---

## PRIORITY: Mode Override > Mode 1 > Mode 4 > Mode 2 > Mode 3

If user specifies "mode N" explicitly → that mode wins, no detection needed.
If both Mode 1 and Mode 4 could match (e.g., "build an app" with spec workflow active) → Mode 4 wins.
If both could match without spec context (e.g., "build an app and do security review"), Mode 1 wins.
Mode 2 is for ISOLATED role requests only.

---

## EXCEPTIONS (bypass to Mode 3):
- "skip orchestrator" / "just code it" — explicit user override
- "Add X to existing Y" where Y is already built this session
- Bug fix on existing code
- Refactor / rename / style change

---

## MANDATORY: TESTING + REPORTS IN ALL MODES

**CRITICAL RULE:** Testing is NON-NEGOTIABLE in every mode. No code ships without tests.
Discipline report is NON-NEGOTIABLE in every mode. User must always see burn rate.

### Testing Requirements by Mode

| Mode | Testing Requirement | Test Framework | Gate |
|------|-------------------|----------------|------|
| Mode 3 (Direct) | Write + run relevant tests after every build | vitest/jest/pytest (match project) | Build fails if tests fail |
| Mode 4 Lite | QA (lite) — unit tests for all new functions | Project's test framework | Must pass before "done" |
| Mode 4 Standard | QA (full) — unit + integration tests | Full test suite | Gate before each sprint end |
| Mode 1 (Full) | QA (full) — unit + integration + contract + load | Full suite + regression | Gate 3 + Gate 5 (phase-end) |

### Testing Protocol (Mode 3 — Direct Execution)

After EVERY code build in Mode 3:
1. **Set up test framework** if not present (vitest for Vue/JS, pytest for Python, etc.)
2. **Write tests** for the code just built (minimum: happy path + 1 edge case per component)
3. **Run tests** — `npm test` / `vitest --run` / equivalent
4. **Report results** inline:

```
## Test Report
- Framework: [vitest/jest/pytest]
- Tests run: X
- Passed: X
- Failed: X
- Coverage: X% (if available)
- Duration: Xs
```

**If tests fail:** Fix before declaring task complete. Never ship broken code.

### Discipline Report Requirements by Mode

| Mode | Report Trigger | Report Format |
|------|---------------|---------------|
| Mode 3 (Direct) | End of every build task | Inline mini-report (see below) |
| Mode 4 Lite | End of build | Lite discipline report |
| Mode 4 Standard | Phase/sprint end | Full discipline report |
| Mode 1 (Full) | Phase end | Full 6-report set (QA, Security, Mapping, Discipline, Jira, Git) |

### Mode 3 Build Report (MANDATORY after every Mode 3 build)

```
## Build Report (Mode 3)
| Metric | Value |
|--------|-------|
| Tests | X pass / Y fail |
| Coverage | X% |
| Reads | X |
| Tool calls | X |
| Tier | PEAK/GOOD/DEGRADING |
| Tokens saved (est.) | X% |
| Build verified | YES/NO |
```

### Mode 4 Lite Build Report

```
## Build Report (Mode 4 Lite)
| Metric | Value |
|--------|-------|
| Tests written | X |
| Tests passed | X / Y |
| Coverage | X% |
| Agents used | [list] |
| Reads | X |
| Tool calls | X |
| Tier | PEAK/GOOD |
| Tokens saved (est.) | X% |
| Planning docs produced | X |
```

**ENFORCEMENT:** If a build completes WITHOUT a test report → the build is INCOMPLETE.
The task is not done until tests pass and report is shown.

---

## SELF-CHECK (Mode 1 only, before proceeding):
- [ ] ≥2 phases decomposed?
- [ ] Each phase has ≥2 sprints?
- [ ] Each sprint has ≥3 tasks?
- [ ] 8+ docs per phase?
- [ ] All gates defined (Think→Design, Design→Develop)?
- [ ] Security/QA/DevOps tasks in sprint plan?
- [ ] Git: feature branches, task IDs, no secrets?
- [ ] Mapping + Discipline reports planned?
- [ ] **QA report after EVERY phase** (covers all sprints — tests run, coverage, pass/fail per sprint)?
- [ ] **Security report after EVERY phase** (covers all sprints — audit, scan results, findings per sprint)?
- [ ] **Mapping report after EVERY phase** (covers all sprints — task status per sprint)?
- [ ] **Discipline report after EVERY phase** (covers all sprints — token metrics, tier, grade per sprint)?
- [ ] **Jira Task Tracking report after EVERY phase** (covers all sprints — epic/story/task status per sprint)?
- [ ] **Git Commit/Branch Tracking report after EVERY phase** (covers all sprints — commits, branches, merges per sprint)?

---

## PER-PHASE REPORTS: Jira Task Tracking + Git Tracking (produced once per phase, covering ALL sprints)

All 6 reports (QA, Security, Mapping, Discipline, Jira, Git) are produced ONCE at the end of each phase.
Each report contains per-sprint breakdowns so no data is lost.
File naming: `docs/phase-N/REPORT-NAME.md` (single file per phase, sections per sprint inside).

### E. Jira Task Tracking Report (after EVERY phase, per-sprint sections inside)
File: `docs/phase-N/JIRA-TASK-REPORT.md`
```markdown
## Jira Task Report — Sprint N.M

### Epic Summary
| Epic ID | Title | Status | Stories Done / Total |
|---------|-------|--------|---------------------|

### Story Breakdown
| Story ID | Epic | Title | Status | Tasks Done / Total | Carry-Over? |
|----------|------|-------|--------|-------------------|-------------|

### Task Detail
| Task ID | Story | Title | Assignee (Role) | Status | Blocker? | Notes |
|---------|-------|-------|-----------------|--------|----------|-------|

### Sprint Metrics
| Metric | Value |
|--------|-------|
| Tasks planned | X |
| Tasks completed | X |
| Tasks carried over | X |
| Velocity (story points) | X |
| Blockers encountered | X |
| Blockers resolved | X |
```

### F. Git Commit/Branch Tracking Report (after EVERY phase, per-sprint sections inside)
File: `docs/phase-N/GIT-TRACKING-REPORT.md`
```markdown
## Git Tracking Report — Sprint N.M

### Branch Summary
| Branch Name | Base | Status | Merged To | Merge Commit |
|-------------|------|--------|-----------|--------------|

### Commit Log
| SHA (short) | Branch | Task ID | Message | Files Changed |
|-------------|--------|---------|---------|---------------|

### Git Discipline
| Check | Result |
|-------|--------|
| All commits reference task IDs? | YES/NO (list violations) |
| Feature branches used? | YES/NO |
| No direct commits to main? | YES/NO |
| No secrets committed? | YES/NO (scan result) |
| Merge strategy (no-ff)? | YES/NO |
| Branch cleanup after merge? | YES/NO |

### Summary
- Total commits this sprint: X
- Branches created: X
- Branches merged: X
- Branches pending: X
- Git violations: X
```
