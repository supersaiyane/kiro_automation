---
id: prebuild_documentation_gate
version: 1.0.0
owners: [scrum_master]
tags: [orchestration, phase-gate, daci, blackboard, pre-build, lazy-generation]
when_to_use: |
  Run once at project start, before the implementation phase opens. Defines
  which role produces which pre-build artifact, in what order, with entry/exit
  gates — turning scattered role skills into one coherent doc package.
inputs:
  - idea: the product concept entering the pipeline
outputs:
  - prebuild_package: tiered, role-owned artifacts on the blackboard
  - gate_decision: PASS (open implementation) | BLOCK (named missing artifact)
---

# Pre-Build Documentation Gate

The army does not write nine documents up front. It produces a **tiered**
package: foundation artifacts are written once and kept living; per-feature
artifacts are generated lazily, only when their slice is about to be built.
Generating everything up front is the waterfall trap — refuse it.

**Gate sequence (DACI owner in bold; output lands on the blackboard):**

| # | Artifact                | Owner role            | Skill                       | Tier |
|---|-------------------------|-----------------------|-----------------------------|------|
| 1 | PRD + cut list          | **product_manager**   | prd_authoring, mvp_scope_definition | Found. |
| 2 | Living context file     | **technical_writer**  | living_context_file         | Found. |
| 3 | Tech stack (→ ADR)      | **cto** / architect   | tech_stack_selection, adr_authoring | Blueprint |
| 4 | Project structure       | **architect**         | project_structure_layout    | Blueprint |
| 5 | Data model              | **database_architect**| database_schema_design      | Blueprint |
| 6 | Integration contracts   | **backend_lead**      | integration_contract_spec   | Blueprint |
| — | *Per feature, lazily:*  |                       |                             | JIT |
|   | Access & authz          | security_engineer     | auth_design / iam_rbac_abac | JIT |
|   | Robustness/error paths  | senior_engineer       | error_handling_strategies   | JIT |
|   | Test strategy           | qa_engineer           | (qa skills) + tdd           | JIT |
|   | Design system           | frontend_lead         | design_system_governance    | Ops |
|   | Deploy & CI             | devops_engineer       | ci_cd_pipeline_design       | Ops |
|   | Observability           | sre_engineer          | observability_three_pillars | Ops |
|   | Cost model              | finops_architect      | cost_modeling_unit_economics| Ops |

**Entry criteria**: an idea exists and the PRD slot is empty.
**Exit criteria (PASS)**: Tiers Foundation + Blueprint exist on the blackboard,
the cut list is non-trivial, and the living context file points to all of them.
Ops + JIT artifacts are NOT required to pass the gate — they are pulled per slice.

**Blackboard rule**: every artifact is written to shared state, not held in a
node's local context. Downstream roles read it instead of re-deriving it.

**Anti-patterns**
- Waterfall: generating JIT/Ops artifacts before their feature is scheduled.
- A gate with no BLOCK path — it must be able to name the missing artifact.
- Artifacts kept in node-local context — the next agent re-invents them.
- Passing the gate with an empty or one-line cut list (see mvp_scope_definition).
