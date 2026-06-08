# Lessons Learned

## 2026-06-06 — mode-selection-before-pipeline
**Mistake:** Jumped into Kiro spec workflow (Mode 4) without asking user which mode they wanted.
**Correction:** User said "give users the option for the mode first, then take that mode for the complete development"
**Rule:** On ANY new development request (build/create/develop + app/tool/system), present all 4 modes to the user FIRST. Never auto-detect. Lock the selected mode for the entire session.
**Triggers:** BUILD, CREATE, MAKE, DEVELOP, IMPLEMENT + APP, TOOL, SYSTEM, PRODUCT, SERVICE, FEATURE, API, DASHBOARD, BOT

## 2026-06-06 — discovery-before-mode-overkill
**Mistake:** Jumped straight to Mode 1 (all 19 agents) for a simple calculator without scoping the request first. Produced Market Research, CTO Strategy, FinOps, Cloud Architecture — all overkill for what could be a CLI tool.
**Correction:** User said: "ask questions first to narrow down, THEN recommend mode, THEN only spin agents that are justified."
**Rule:** ALWAYS ask 3-5 scoping questions (platform, scale, complexity, deployment, revenue) BEFORE mode selection. Use answers to: (1) recommend a mode, (2) select which agents to activate. Never fire all 19 roles without justification from discovery answers.
**Triggers:** BUILD, CREATE, DEVELOP + any app/tool/system — always scope first, never assume full army.
