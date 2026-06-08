---
id: debugging_methodology
version: 1.0.0
owners: [senior_engineer_fe, senior_engineer_be]
tags: [debugging, root-cause, methodology, incident]
when_to_use: |
  An unexpected behavior, a flaky test, a production incident, or a
  customer-reported bug. Use BEFORE writing the fix, not while.
inputs:
  - symptom: observable bad behavior + reproduction steps if known
outputs:
  - root_cause: the actual mechanism, not just the trigger
  - fix_strategy: what changes and what stays
---

# Debugging Methodology

**Four phases. Do not skip ahead.**

1. **Reproduce reliably** — without a repro, every fix is a guess. Add
   logs, lower the noise, narrow the inputs. If you cannot repro on
   demand, your first task is the repro.
2. **Isolate** — bisect the change set, the inputs, or the dependency
   versions. Halve the search space each step. `git bisect` exists for
   a reason.
3. **Diagnose** — explain the failure mechanism, not just "it works
   now". If you can't write a one-paragraph story of how the bug
   happens, you haven't found it.
4. **Fix + regression test** — write a test that fails BEFORE the fix
   and passes AFTER. Without that test the bug returns.

**Heuristics**
- The bug is usually in the last code you changed. Look there first.
- If it works in dev and not prod, the difference is data, config, or
  concurrency. In that order.
- "It's flaky" = "we haven't found the race yet."

**Anti-patterns**
- Adding `try/except: pass` to hide the symptom.
- "It's an intermittent issue" with no follow-up investigation.
- Fixing the trigger and not the mechanism (the bug comes back through
  a different trigger).
