---
id: component_decomposition
version: 1.0.0
owners: [frontend_lead]
tags: [react, components, ui, decomposition, design-system]
when_to_use: |
  Translating a UI spec or wireframe into a component tree with clear
  prop/state boundaries before the SR_ENG_FE writes code.
inputs:
  - ui_spec: wireframes or layout description
outputs:
  - component_tree: parent/child structure with props + local state
---

# Frontend Component Decomposition

**Heuristics**

1. **Single Responsibility** — one component does one thing. A "page"
   coordinates; a "card" displays; a "form" submits. If you can't write
   the component's purpose in one sentence, split it.
2. **Container / Presentational** — containers hold state and call
   APIs; presentational components are pure functions of props. Easier
   to test, easier to swap, easier to reuse.
3. **Lift state only as far as needed** — global state for cross-cutting
   concerns (auth, theme, feature flags). Component-local state for
   anything that doesn't escape that subtree.
4. **Props ≤ 6** rule — once a component accepts more than ~6 props,
   it's either doing too much or its consumers should pass a typed
   object.
5. **Accessibility by construction** — semantic HTML first; ARIA only
   to fill gaps. Every interactive element keyboard-reachable.

**Anti-patterns**
- "God" pages that own all state.
- Re-implementing what the design system already has.
- Inline styles overriding tokens.
