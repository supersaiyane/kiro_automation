---
id: refactoring_safely
version: 1.0.0
owners: [senior_engineer_fe, senior_engineer_be, backend_lead]
tags: [refactoring, fowler, mikado, characterization-tests, safe-change]
when_to_use: |
  About to restructure code that is in production. Refactoring is
  ONLY safe with tests around the area being changed, small steps,
  and a rollback plan. If those preconditions don't exist, the work
  ahead is "creating safety nets" not "refactoring."
inputs:
  - target_module, test_coverage_baseline, business_pressure
outputs:
  - "refactor_plan: ordered small steps, each green between commits"
---

# Refactoring Safely — Fowler's Catalog + the Mikado Method

> Refactoring = changing the structure of code WITHOUT changing
> observable behavior. The "without changing behavior" part is what
> makes it safe; abandon that and you're rewriting.

## Preconditions (non-negotiable)

Before touching code:

1. **Tests exist that pin current behavior.** If they don't, write
   characterization tests FIRST. These are not "good tests" — they
   freeze the current behavior including its bugs, so you can detect
   accidental change.
2. **You can run those tests in < 5 minutes.** Slow tests = no
   refactoring discipline. The whole technique relies on running tests
   between every small step.
3. **You can revert** in < 2 minutes (small commits, no DB migrations
   tangled in).

If any of these is false, the FIRST refactor is "build the safety net."

## The two-hat rule

You are EITHER:
- **Wearing the refactoring hat** — restructuring, no behavior change,
  tests stay green. Commit message: "refactor: ..."
- **Wearing the feature hat** — adding/changing behavior, tests
  evolve. Commit message: "feat: ..."

NEVER wear both at once. A single commit that refactors AND adds
behavior is impossible to review or revert safely. Switch hats
between commits.

## Fowler's small-step catalog (the moves)

Each move is < 5 minutes of work, tests green afterward:

- **Extract Function** — pull a block of code into a named function.
- **Inline Function** — collapse a one-line wrapper.
- **Rename Variable / Function** — clarity for free.
- **Extract Variable** — name a sub-expression.
- **Replace Magic Number** — give the literal a name.
- **Split Loop** — one loop doing two things → two loops.
- **Replace Conditional with Polymorphism** — `if type == X` → method call.
- **Extract Class** — when one class holds two responsibilities.
- **Replace Constructor with Factory Function** — when construction
  has logic.
- **Replace Primitive with Object** — when a string represents
  more than text (Money, EmailAddress).
- **Parameterize Function** — when two functions differ only by a value.
- **Replace Loop with Pipeline** — `for` → `filter/map/reduce`.

Pick one, do it, run tests, commit. Repeat. This is the entire game.

## The Mikado Method (for big restructurings)

When the target change is large (extract a module, swap a library,
change a data model), don't push through linearly — you'll hit a
yak shave and have an uncommittable mess.

```
GOAL: "Replace internal Auth library with Auth0 SDK"
  → Attempted naively: breaks 47 places.
  → Mikado:
     1. Try the goal.
     2. It breaks. Write down what would need to be true first.
     3. REVERT.
     4. Pick one prerequisite. Apply it as a SAFE refactor.
        Commit. Run tests.
     5. Try the goal again. Note new prerequisites. Revert.
     6. Repeat until the goal applies cleanly with tests still green.
```

You end up with a tree of refactors, each leaf shippable, the root
goal done in a tiny final commit. The tree IS the documentation
of the work.

## When to use which approach

| Scope | Approach |
|---|---|
| Local cleanup (a function) | Fowler small steps, no plan needed |
| Module-scale (a class hierarchy) | Fowler steps, sequenced in a checklist |
| Cross-cutting (auth, persistence) | Mikado method tree |
| Architectural (split a service) | Strangler Fig (see `microservices_decomposition`) |

## Characterization testing — when you have no tests

Approved technique (Michael Feathers, *Working Effectively with Legacy
Code*):

1. Find a seam: a place where you can intercept input/output.
2. Call the code with a battery of inputs.
3. Record the outputs (don't judge if they're "correct" — they're
   what the code DOES).
4. Lock those outputs in as the expected values in tests.
5. NOW you can refactor. If a test breaks, you changed behavior;
   that's a signal to revert and try again.

Characterization tests are throwaway scaffolding. Replace with
intent-revealing tests AFTER the refactor.

## Boy-Scout Rule, with limits

"Leave the code cleaner than you found it" — yes, but:
- **Drive-by refactors in a feature PR are banned by 4E.** Open
  a separate PR (the refactor hat).
- **Drive-by renames** that cascade to 200 files are not "small."
  Plan them.
- **Drive-by formatting changes** make diffs unreviewable. Run
  the formatter as a separate, isolated PR; never mix.

## Anti-patterns

- **"Refactoring" sprints** with no test coverage. That's
  rewriting under a friendlier name. Owners will discover regressions
  in production.
- **Branching for weeks.** Long branches diverge from main and
  produce un-reviewable mega-PRs. Refactor on main behind a flag if
  the change is risky; ship small commits trunk-based.
- **Big-bang renames.** A 1,200-file rename PR cannot be reviewed.
  Stage it across multiple PRs, with the renaming script committed
  alongside.
- **Refactoring that "improves" code by adding 3 layers of
  abstraction nobody asked for.** Cleverness ≠ improvement.
  Code should be simpler after, not just rearranged.
- **No revert plan.** "It compiles!" is not a revert plan. Small
  commits + flag-gated risky parts = real revert plan.

## Tools that pay back the time

- IDE refactor menu (Rename/Extract Method). Not Cmd-F replace.
- AST-aware tools: `ast-grep`, `comby`, `jscodeshift`, `bowler`.
  Safer than sed for structural changes.
- Coverage diff in CI: "this PR drops coverage from 87% → 84%" is
  a refactor smell to investigate.

## Reviewing a refactor PR

A reviewer looks for ONE thing: does the diff change behavior?

- New conditionals → suspicious.
- New error handling → suspicious.
- Tests changed → suspicious (unless the test was clearly
  poorly-named or coupled to internals).
- Lots of files renamed → no behavior change, just verify the
  tool's output.

If a refactor PR is hard to review, it's too big. Ask for it to
be split.

## Validation that a refactor was safe

- [ ] Test count is the same or higher.
- [ ] Test pass rate is identical.
- [ ] Coverage is the same or higher.
- [ ] No production behavior changed (verified via post-deploy
      monitoring of the affected paths).
- [ ] The team can find the new structure faster than the old
      (the actual goal of refactoring).
