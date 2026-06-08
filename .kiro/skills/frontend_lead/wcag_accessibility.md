---
id: wcag_accessibility
version: 1.0.0
owners: [frontend_lead, senior_engineer_fe]
tags: [accessibility, a11y, wcag, aria, keyboard, screen-reader]
when_to_use: |
  Every page, every component, every change. A11y is not a sprint;
  it's a property of the system that gets enforced by code review and
  automated test, not bolted on at the end.
inputs:
  - component_spec, design_token_set
outputs:
  - a11y_audit: per-component WCAG 2.2 AA compliance + fixes
---

# WCAG 2.2 AA — A Working FE Lead's Cheat Sheet

The four principles (POUR):
- **Perceivable**: users must be able to perceive the information.
- **Operable**: they can operate the interface.
- **Understandable**: information & operation are understandable.
- **Robust**: works with current and future assistive tech.

## The 10 rules that catch 80% of failures

1. **Every interactive element is keyboard-reachable.** Tab through
   the page. If your mouse-only "card click" doesn't have a focusable
   target inside, you've broken it.
2. **Focus visible.** Don't `outline: none` unless you've replaced it
   with a custom focus ring of equal-or-better contrast.
3. **Color contrast** ≥ 4.5:1 for normal text, 3:1 for large text and
   UI components. **Don't rely on color alone** — pair red errors
   with an icon + text.
4. **Form fields have labels.** Programmatically — `<label
   for="email">` or `aria-labelledby`. Placeholder is NOT a label.
5. **Images have alt text.** Decorative? `alt=""`. Informative? Write
   what a sighted user would gain.
6. **Heading order is logical.** One H1 per page; don't skip from H2
   to H4 because it "looks right."
7. **Landmarks** — `<header>`, `<main>`, `<nav>`, `<footer>` (or ARIA
   equivalents). Screen-reader users navigate by them.
8. **Live region for async updates.** Toasts, validation errors,
   loading spinners. Use `aria-live="polite"` for non-urgent,
   `aria-live="assertive"` for critical only.
9. **No keyboard traps.** Once a user can tab in, they must be able to
   tab out. Modal dialogs — implement focus trap correctly AND escape
   on ESC.
10. **Reduced motion.** Honor `prefers-reduced-motion` — disable
    auto-play, parallax, big transitions for users who set it.

## Component-level patterns

### Modal / dialog
- `role="dialog"`, `aria-modal="true"`, `aria-labelledby` pointing to
  the title.
- Focus moves to first focusable element on open; back to opener on
  close.
- ESC closes; click-outside is optional and per-design.
- Tab cycles inside; nothing outside the modal is reachable while open.

### Custom dropdown / combobox
- Use the **WAI-ARIA Authoring Practices** combobox pattern. Don't
  invent your own.
- `role="combobox"` on input, `role="listbox"` on options,
  `aria-activedescendant` for the focused option (focus stays in the
  input).
- Arrow keys, Home/End, Esc, Enter — implement all four.

### Toggle / switch
- `role="switch"`, `aria-checked="true|false"`.
- Don't make it look like a checkbox if it's a toggle — they have
  different semantics for a screen reader.

### Toast
- `role="status"` (polite) or `role="alert"` (assertive — only for
  errors). Auto-dismiss is hostile to screen-reader users — they may
  not have heard it yet. Provide a close button.

## Automated + manual testing

**Automated** (catches ~30%):
- axe-core / eslint-plugin-jsx-a11y in CI, blocking on violations.
- Storybook a11y addon for every component.
- Lighthouse a11y audit in CI.

**Manual** (the other 70%):
- Tab the page from the top. Did focus go anywhere unexpected?
- Use a screen reader (VoiceOver on macOS, NVDA on Windows). Listen
  to a critical flow.
- Zoom to 200%. Does anything overflow or become unreadable?
- Disable styles entirely. Does the page still make sense? (If not,
  semantic HTML is missing.)

## Regulatory landscape (don't ignore)

- **US ADA + Section 508**: case law treats web a11y as a covered
  service. Class-action settlements average mid-six figures.
- **EU EAA** (2025): mandatory WCAG 2.1 AA for digital services.
- Internal: most enterprise sales orgs ask for VPAT / ACR. No VPAT,
  no deal in some segments.

## Anti-patterns

- "We'll do an a11y pass before launch." There is no pass. It's a
  property maintained on every PR.
- Hiding focus rings for design reasons. You've broken keyboard users
  to make sighted-mouse users marginally happier.
- `<div onClick>` as a button. Doesn't get keyboard or screen-reader
  semantics for free.
- Tooltips on hover only. Touch and keyboard users can't see them.
- `aria-label` that contradicts the visible label. Screen reader says
  one thing, sighted user reads another.
- Skipping color-contrast for "muted text" — secondary text still has
  to meet the 4.5:1 threshold.
- Disabled inputs missing the `disabled` attribute (using CSS only).
  Screen reader will let users interact with them.
