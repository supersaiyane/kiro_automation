---
inclusion: always
---

# Discovery Engine — Scope Before Build

**MANDATORY:** On ANY new build request (BUILD/CREATE/MAKE/DEVELOP/IMPLEMENT + APP/TOOL/SYSTEM/etc.),
this discovery phase runs FIRST — before mode selection, before any agents fire.

---

## RULE: DISCOVERY BEFORE EVERYTHING

```
User Request → Discovery (7 questions) → Score → Recommend Mode + Agent Subset → User Confirms → Execute
```

**NEVER skip discovery unless user explicitly says "just build it" or "skip questions".**
Skip → defaults to Mode 3 (Direct Execution).

---

## STEP 1: Present All 7 Questions (Single Prompt)

Present using the `user_input` tool. All 7 questions in ONE message. User answers all at once.

### The 7 Discovery Questions

```
1. PLATFORM — What type of application?
   [ ] Web app
   [ ] Mobile app (iOS/Android)
   [ ] Desktop app
   [ ] CLI / Terminal tool
   [ ] Library / Package
   [ ] Multiple platforms

2. SCALE — Who is this for?
   [ ] Just me (personal tool)
   [ ] Small team (< 10 users)
   [ ] Public product (100s–1000s users)
   [ ] SaaS business (10K+ users)

3. COMPLEXITY — How complex?
   [ ] Simple (1-2 features, single screen/command)
   [ ] Medium (3-5 features, multiple views)
   [ ] Complex (10+ features, integrations, real-time)
   [ ] Enterprise (microservices, multi-tenant, compliance)

4. DEPLOYMENT — Where does it run?
   [ ] Local only (my machine)
   [ ] Single server / VPS
   [ ] Cloud managed (Vercel, Supabase, AWS, etc.)
   [ ] App stores (Apple/Google Play)
   [ ] Multi-region / High availability

5. REVENUE — Monetization model?
   [ ] None (free/open-source)
   [ ] Ads
   [ ] One-time purchase
   [ ] Subscription (SaaS)
   [ ] Enterprise licensing

6. DESIGN & UX — UI polish level?
   [ ] None (CLI, API, or script)
   [ ] Basic functional (works, not pretty)
   [ ] Polished (production-ready, responsive)
   [ ] Branded (custom design system, animations)

7. SECURITY & COMPLIANCE — Requirements?
   [ ] Minimal (no auth, no user data)
   [ ] Basic auth (login/logout, simple roles)
   [ ] User data + privacy (GDPR, data encryption)
   [ ] Regulated (HIPAA, PCI-DSS, SOC2, FedRAMP)
```

---

## STEP 2: Score Responses → Determine Complexity Tier

Each answer maps to a weight (0–3). Sum all weights to get a **Complexity Score**.

### Scoring Matrix

| Question | Option A (0 pts) | Option B (1 pt) | Option C (2 pts) | Option D (3 pts) |
|----------|-----------------|-----------------|------------------|------------------|
| 1. Platform | CLI / Library | Web OR Desktop | Mobile | Multiple platforms |
| 2. Scale | Just me | Small team | Public product | SaaS business |
| 3. Complexity | Simple | Medium | Complex | Enterprise |
| 4. Deployment | Local only | Single server | Cloud managed / App stores | Multi-region / HA |
| 5. Revenue | None | Ads | One-time / Subscription | Enterprise licensing |
| 6. Design/UX | None (CLI) | Basic functional | Polished | Branded |
| 7. Security | Minimal | Basic auth | User data + privacy | Regulated |

**Maximum possible score: 21 (all D's)**
**Minimum possible score: 0 (all A's)**

### Complexity Tiers

| Score Range | Tier | Recommended Mode | Rationale |
|-------------|------|-----------------|-----------|
| 0–4 | **Minimal** | Mode 3 (Direct Execution) | Just build it. No planning overhead justified. |
| 5–9 | **Light** | Mode 4 Lite (Spec + 3-5 agents) | Some structure needed but not full army. |
| 10–14 | **Standard** | Mode 4 (Hybrid) or Mode 1 Lite (8-12 agents) | Production-grade, needs architecture + security. |
| 15–21 | **Full** | Mode 1 (Full Army, all 19 agents) | Enterprise/SaaS with compliance — full pipeline justified. |

---

## STEP 3: Map Score → Agent Activation

### Agent Activation Table

| Agent/Role | Minimal (0-4) | Light (5-9) | Standard (10-14) | Full (15-21) |
|------------|:---:|:---:|:---:|:---:|
| Market Researcher | ❌ | ❌ | ❌ | ✅ |
| CTO (Tech Strategy) | ❌ | ✅ (lite: stack only) | ✅ | ✅ |
| Product Manager | ❌ | ✅ (lite: 5 stories) | ✅ | ✅ |
| Architect | ❌ | ✅ (lite: 1 diagram) | ✅ | ✅ |
| Database Architect | ❌ | ❌ | ✅ (if DB needed) | ✅ |
| Cloud Architect | ❌ | ❌ | ✅ (if cloud deploy) | ✅ |
| FinOps Architect | ❌ | ❌ | ❌ | ✅ |
| Security Engineer | ❌ | ❌ | ✅ (if auth/privacy) | ✅ |
| Scrum Master | ❌ | ❌ | ✅ | ✅ |
| Backend Lead | ❌ | ✅ | ✅ | ✅ |
| Frontend Lead | ❌ | ✅ (if UI) | ✅ | ✅ |
| Senior Engineer (BE) | ❌ | ✅ | ✅ | ✅ |
| Senior Engineer (FE) | ❌ | ✅ (if UI) | ✅ | ✅ |
| ML Engineer | ❌ | ❌ | ❌ | ✅ (if ML) |
| QA Engineer | ❌ | ✅ (lite: unit tests) | ✅ | ✅ |
| DevOps Engineer | ❌ | ❌ | ✅ (if cloud) | ✅ |
| SRE Engineer | ❌ | ❌ | ❌ | ✅ |
| Technical Writer | ❌ | ❌ | ✅ | ✅ |
| Website Creator | ❌ | ❌ | ❌ | ✅ (if marketing site) |

### Conditional Activation Rules

Beyond the score-based table, these conditions override:

| Condition (from answers) | Force-Activate | Force-Skip |
|--------------------------|----------------|------------|
| Platform = "Mobile" or "App stores" | DevOps, Security | — |
| Revenue = "Subscription" or "Enterprise" | FinOps, PM (full) | — |
| Security = "Regulated" | Security (full), Cloud | — |
| Scale = "Just me" | — | Market Research, FinOps, SRE |
| Deployment = "Local only" | — | Cloud, DevOps, SRE |
| Design = "None (CLI)" | — | Frontend Lead, Senior FE |
| Complexity = "Simple" | — | DB Architect (unless persist needed) |

---

## STEP 4: Present Recommendation to User

After scoring, present:

```
Based on your answers:
- Complexity Score: X/21
- Recommended Tier: [Minimal/Light/Standard/Full]
- Recommended Mode: [Mode 3 / Mode 4 Lite / Mode 4 / Mode 1]
- Agents to activate: [list]
- Agents skipped (with reason): [list]

[Proceed with this plan] / [I want full army anyway] / [I want fewer agents] / [Just build it (Mode 3)]
```

**User can override:**
- "Full army" → activate all 19 regardless of score
- "Fewer agents" → user removes specific agents
- "Just build it" → Mode 3, no agents, direct code

**Once confirmed → LOCKED for session.** No re-asking.

---

## STEP 5: Execute with Selected Agents Only

- Mode 3 (Minimal): No planning docs. Code directly.
- Mode 4 Lite (Light): PRD (lite) → Architecture (lite) → Sprint plan → Code. Skip think phase.
- Mode 4 (Standard): Requirements → Design → Tasks → Sprints. Selected agents only.
- Mode 1 Full: Full Think → Design → Develop with all gates. All agents.

### "Lite" Artifact Rules

When agents fire in "lite" mode:

| Agent | Full Output | Lite Output |
|-------|------------|-------------|
| CTO | Full strategy doc (10 sections) | Tech stack table only (1 page) |
| PM | 21+ stories with full AC | 5-8 stories with basic AC |
| Architect | C4 diagrams + ADRs + APIs | 1 component diagram + key ADRs only |
| QA | Full test plan + coverage targets | Unit test strategy only |
| Security | STRIDE + OWASP + compliance | Auth flow + basic checklist |

---

## EXAMPLES

### Example 1: "Build me a calculator"
**Likely answers:** CLI or Web, Just me, Simple, Local, None, Basic, Minimal
**Score:** 0 + 0 + 0 + 0 + 0 + 1 + 0 = **1 → Minimal → Mode 3**
**Result:** No agents. Just code the calculator directly.

### Example 2: "Build a task management app"
**Likely answers:** Web, Small team, Medium, Cloud managed, None, Polished, Basic auth
**Score:** 1 + 1 + 1 + 2 + 0 + 2 + 1 = **8 → Light → Mode 4 Lite**
**Agents:** CTO (lite), PM (lite), Architect (lite), Backend Lead, Frontend Lead, QA (lite)

### Example 3: "Build a fintech payment platform"
**Likely answers:** Multiple, SaaS, Enterprise, Multi-region, Subscription, Branded, Regulated
**Score:** 3 + 3 + 3 + 3 + 2 + 3 + 3 = **20 → Full → Mode 1**
**Agents:** ALL 19 activated. Full pipeline justified.

### Example 4: "Build a mobile fitness tracker"
**Likely answers:** Mobile, Public product, Complex, App stores, Subscription, Polished, User data + privacy
**Score:** 2 + 2 + 2 + 2 + 2 + 2 + 2 = **14 → Standard → Mode 4**
**Agents:** CTO, PM, Architect, DB, Cloud, Security, Backend Lead, Frontend Lead, QA, DevOps, Scrum Master

---

## ENFORCEMENT

- This discovery MUST run before orchestrator-routing.md mode detection
- If user says "mode N" explicitly in their prompt → skip discovery, use that mode with full agent set
- If orchestrator-routing.md fires WITHOUT discovery having run first → VIOLATION
- The only bypass is: user says "just build it" / "skip questions" / "mode N"

---

## CALCULATOR TEST (the overkill prevention check)

Before presenting the recommendation, ask yourself:
> "If the user said 'build me a calculator' and I'm about to activate 19 agents — is that justified by the score?"

If score < 5 and you're about to activate more than 5 agents → STOP. Something is wrong. Re-check.

