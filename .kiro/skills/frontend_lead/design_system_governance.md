---
id: design_system_governance
version: 1.0.0
owners: [frontend_lead, designer]
tags: [design-system, tokens, governance, contribution, versioning]
when_to_use: |
  Design system exists or is being built. Without governance, a
  design system fragments into N forks within 6 months — teams add
  components locally, drift versions, and the "system" becomes a
  museum of stale primitives. Governance is what turns it into a product.
inputs:
  - component_inventory, consumer_teams, current_version_skew
outputs:
  - "ds_governance: contribution rules + versioning + deprecation + token policy"
---

# Design System Governance — Beyond "We Built A Library"

> The hard problem is not building components. It's making one
> shared system that 8 product teams will actually use, contribute
> back to, and keep up-to-date with. That requires governance — the
> politics and process around the code.

## Why design systems decay without governance

The failure pattern:

```
Month 1: DS team ships Button, Input, Modal.
Month 3: Team A needs a "fancy button with icon." Forks Button.
Month 5: Team B needs a tooltip. Builds locally.
Month 7: DS team ships Tooltip. Team B still uses theirs.
Month 9: Three button styles in prod. Inconsistent UX.
Month 12: "The design system isn't working." Rewrite proposed.
```

What was missing wasn't components — it was the **mechanism** for
teams to influence and contribute to the central system.

## The governance model — pick one

### Centralized
A dedicated DS team owns everything. Consumers file requests.
- Pros: consistency, quality control.
- Cons: bottleneck, forks proliferate when consumers can't wait.
- When: small org (< 50 FE), high-design-fidelity product.

### Federated
DS team owns the core; product teams own "satellite" components
that haven't graduated yet. Promotion path is documented.
- Pros: faster iteration, distributed ownership.
- Cons: requires governance discipline to prevent fragmentation.
- When: 50-300 FE, mature product.

### Open-source-internal (recommended at scale)
DS team is the maintainer. Any product team can PR. Standard
contribution rules + reviewer approval gate.
- Pros: scales to large orgs.
- Cons: requires real PM-ing of the system.
- When: 300+ FE, multiple parallel product lines.

State your model explicitly. "We're federated" tells contributors
their lane.

## Tokens — the foundation layer

Tokens are the design DNA. Versioned separately from components:

```json
{
  "color": {
    "background": {
      "primary": { "value": "#FFFFFF" },
      "elevated": { "value": "#F7F9FC" }
    },
    "text": {
      "primary": { "value": "#101828" },
      "secondary": { "value": "#475467" }
    }
  },
  "spacing": {
    "xs": { "value": "4px" },
    "sm": { "value": "8px" },
    "md": { "value": "16px" }
  }
}
```

Pipeline: design tool (Figma variables) → JSON tokens → Style
Dictionary / W3C tokens → CSS variables / iOS / Android. One
source of truth across platforms.

Token rules:
- **Never hardcode** a hex in components. Use a token.
- **Tokens are versioned** (semver). Breaking changes need a
  migration period.
- **Tokens are SEMANTIC, not raw**: prefer `background.primary`
  over `gray-50`. Themes (dark mode) need semantic to remap.

## Contribution rules

A `CONTRIBUTING.md` that says "follow our process" is useless.
Specific rules that work:

1. **New component proposal**: file an issue with use case,
   wireframes, and 3+ teams who would use it. DS team triages
   weekly.
2. **Variants of an existing component**: PRs welcome. Reviewer
   from DS team is required.
3. **Tokens**: only DS team merges token changes (they cascade).
4. **Breaking changes**: a `BREAKING:` commit message requires
   semver-major, migration codemod, deprecation notice 1+ minor
   version before removal.
5. **PRs MUST include**: story, tests (unit + visual regression),
   docs update, a11y check.

## Versioning + adoption

Semver, strictly:

- **Patch**: bug fix, no API change.
- **Minor**: additive (new component, new prop). Safe.
- **Major**: breaking. Migration required.

For consumers:
- Pin to a minor (`^2.4.0`). Get patches free.
- Major upgrades are a project with a tracking ticket. DS team
  provides a codemod (jscodeshift) where possible.

## Deprecation lifecycle

```
1. ANNOUNCE deprecation in release notes (with reason + replacement).
2. ADD deprecation warning in console at runtime + linter rule.
3. STAY supported for N minor versions or M months (e.g., 6 months).
4. REMOVE in a major version.
```

Rushing deprecation without the warning period burns trust;
consumers will fork rather than upgrade.

## Adoption tracking

You cannot govern what you can't see. Build a usage dashboard:

- % of pages using DS components (vs. raw HTML / forks).
- Per-team adoption rate.
- Top 10 "wanted but missing" components (from issue tracker).
- Components with > 50% deprecation warnings firing in prod.

Tools: AST scan of consumer repos (component-usage-stats), runtime
telemetry from production, periodic audit reports.

Show the dashboard at quarterly DS reviews. Adoption that's stagnant
or dropping = the system isn't delivering value.

## Accessibility as a non-negotiable

Every DS component ships with:
- WCAG 2.2 AA compliance verified (axe-core in CI).
- Keyboard navigation tested.
- Screen reader labels documented.
- Color contrast verified across themes.

Components without these are not "advanced enough" — they're
broken. Production teams who use them inherit accessibility for
free; that's a strong adoption driver.

## Documentation — the product page

Each component has:

- **Anatomy diagram** (the parts named).
- **Live examples** (Storybook / Ladle / web components).
- **Props table** (auto-generated from TypeScript).
- **Variants and states** (all visible at once).
- **Do / Don't** (visual examples).
- **A11y notes** (keyboard, ARIA).
- **Code snippet** copy-paste-able.

If a designer or engineer can't be productive in 5 minutes of
reading, the doc is broken.

## Anti-patterns

- **One-shot DS launch**, then no team to maintain. Decays in 6
  months.
- **No design tokens**, just component primitives. Theming is
  impossible.
- **No deprecation process.** Teams fork instead of upgrading.
- **DS as code-only**, no Figma counterpart. Designers and engineers
  drift apart.
- **Components named after products** ("BillingButton"). Generic
  names (`Button`, `IconButton`) survive product pivots.
- **Behavior in tokens.** Tokens are visual only. Don't put logic
  there.
- **Storybook is the only doc.** Engineers won't browse 50 stories
  without a curated guide.
- **Locked PR access.** "Only DS team can merge" without an SLA
  means teams give up and fork.

## The DS team's product KPIs

- **Adoption rate** — % of new pages using DS.
- **Customer satisfaction** — quarterly survey of product teams.
- **Time to ship a new pattern** — proposal → in production.
- **Bug rate** — open issues / total components.
- **Contribution rate** — PRs from product teams (high = healthy).

If the DS team can't show movement on these, the DS is decoration.

## Sequencing for a new design system

Month 0-3: Tokens + 5 foundational components (Button, Input,
Modal, Layout primitives, Typography). Use them in ONE product
area as the design partner. Get real feedback.

Month 3-6: Expand to 10-15 components based on what the design
partner needs next. Set up Storybook, automated visual regression.

Month 6-9: Open contribution rules. Onboard the next 2 product
teams. Adoption dashboard.

Month 9-12: Theming / dark mode (now that tokens are in place).
First deprecation. Quarterly DS review with all consumer team leads.

A design system is a 2-3 year journey. Plan accordingly.

## Validation that the DS is governed

- [ ] Token source of truth is documented; no hex codes in
      component code.
- [ ] Adoption dashboard exists and trends up.
- [ ] At least one breaking change has been deprecated and removed
      gracefully.
- [ ] Product team contributions account for > 20% of PRs.
- [ ] No component has a known a11y bug in the last 90 days.
- [ ] A new engineer can ship a screen using ONLY DS components
      in their first week.
