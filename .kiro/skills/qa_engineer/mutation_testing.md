---
id: mutation_testing
version: 1.0.0
owners: [qa_engineer, senior_engineer]
tags: [mutation-testing, pitest, stryker, test-quality, coverage]
when_to_use: |
  Test-coverage is high but bugs still leak. Coverage measures
  whether lines ran; it does NOT measure whether your tests would
  catch a bug. Mutation testing measures the latter directly.
  Apply on the critical 10-20% of the codebase, not the whole.
inputs:
  - test_suite, target_module, time_budget
outputs:
  - "mutation_report: surviving mutants + tests to add + suspect-but-OK exclusions"
---

# Mutation Testing — Are Your Tests Actually Testing?

> Line coverage of 95% can pass with assertions of 0%. Mutation
> testing asks the only question that matters: "if the code were
> wrong, would your tests notice?"

## How it works

1. The tool makes a small change ("mutation") to the source code:
   - `>` → `>=`
   - `+` → `-`
   - `return x` → `return null`
   - delete a line
2. Runs your test suite against the mutant.
3. If a test FAILS → the mutant is "killed" (good — your tests caught it).
4. If all tests PASS → the mutant SURVIVED (bad — your tests can't
   tell the difference).

**Mutation score** = killed / total mutants. A high-quality suite
on critical code targets 80%+.

## Why coverage isn't enough

```python
def calculate_discount(amount, tier):
    if tier == "premium":
        return amount * 0.10
    return amount * 0.05

# 100% line coverage, 0 actual assertions:
def test_calculate_discount():
    calculate_discount(100, "premium")
    calculate_discount(100, "standard")
```

The test exercises every line. Coverage tool: green. Mutate the
function: `return amount * 0.10` → `return amount * 0.99`. Tests
still pass. The mutation score for this function is 0%.

## Tools (current)

| Lang | Tool |
|---|---|
| JVM (Java/Kotlin/Scala) | PIT (pitest.org) |
| JS/TS | StrykerJS |
| .NET | Stryker.NET |
| Python | mutmut, cosmic-ray |
| Go | go-mutesting, gremlins |
| Rust | cargo-mutants |
| Ruby | mutant |
| PHP | Infection |

PIT is the gold standard for production use; Stryker is the most
ergonomic for JS. All produce HTML reports of surviving mutants.

## Reading a mutation report

For each surviving mutant, ONE of:

1. **Add a test** — the bug it represents is undetected. Most common.
2. **Tighten an existing test** — assertion was too weak (`.toBeTruthy()`
   instead of `.toBe(42)`).
3. **Mark as equivalent** — the mutant produces semantically identical
   behavior (rare; e.g., `i++` → `++i` in a non-expression context).
   Justify in code, not in the tool config.
4. **Mark as out-of-scope** — performance optimizations, logging
   format changes. Don't test these.

A team's first mutation run typically reveals 30-60% of "covered"
code is actually undertested.

## Where to apply it (cost-benefit)

Mutation testing is SLOW — minutes to hours per run. Don't run on
the full codebase nightly. Instead:

- **Critical modules** — money math, auth checks, permissioning,
  encryption boundaries. Aim for 80%+ mutation score.
- **Newly-added code in PRs** — run only on the diff for fast
  feedback (PIT, Stryker both support this).
- **Manual periodic runs** for older suspect modules.

For background code (UI glue, logging), line coverage is fine.
Mutation testing is for code where bugs hurt.

## Sample run output (Stryker-style)

```
mutant #1   line 14   killed       (changed > to >=)
mutant #2   line 15   killed
mutant #3   line 17   SURVIVED     (deleted email notification)
mutant #4   line 17   SURVIVED     (changed user.id to null)
...
Score: 67% (134 killed / 200 total)
```

Mutants #3 and #4 are the actionable findings. Open the diff, write
the missing tests.

## Test fixes that mutation feedback drives

- **Boundary assertions**: `amount >= 1000` vs `> 1000` mutants force
  tests to use exactly the boundary values.
- **Return-value assertions**: returning `null` mutants force you to
  ACTUALLY check the result.
- **Side-effect assertions**: removing a `db.save()` mutant forces a
  test that observes the save (mock + verify).
- **Negation flips**: `!isAuthorized` → `isAuthorized` mutants force
  tests on BOTH branches.

## Performance — making it tolerable

Mutation testing's cost is N (mutants) × M (tests). Speedups:

- **Mutation in PR diff only**: 100x speedup vs full repo.
- **Incremental mutation cache** (PIT supports): re-test only
  mutants where the source or tests have changed.
- **Test selection per mutant**: a mutant in `pricing.py` only
  needs `test_pricing.py`. Tools do this automatically.
- **Parallelize** across cores or CI runners.

Realistic CI budget: < 10 minutes for diff-mode mutation on a PR.

## Anti-patterns

- **Treating mutation score as a hard gate**. A flaky test will
  randomly kill mutants; locked-down equivalence rules are noisy.
  Use it as a SIGNAL, with human review of surviving mutants.
- **Running on generated code, vendored code, or DTOs.** Wastes
  CPU. Configure exclusions.
- **Chasing 100%.** The last 5-10% are equivalent mutants and
  unproductive arguments with the tool. 80% is excellent.
- **Adding tests that just kill mutants without expressing intent.**
  Test names like `test_kills_mutant_47` are useless. Each test
  should describe a behavior — the mutation is the diagnostic, the
  test name is the documentation.
- **Skipping it entirely on auth/payment code.** This is exactly
  where the test gap costs the most.

## How to introduce it to a team

1. **One critical module first.** Pick the worst recent bug
   site — money math, auth check. Run mutation on JUST that file.
2. **Show the team the surviving mutants.** Most will be
   eye-opening; the testing gaps are usually obvious in hindsight.
3. **Write the missing tests as a team in 30 min.** Score jumps
   visibly. Cultural buy-in earned.
4. **Wire diff-only mutation into PR CI** with a warning (not
   blocking) gate for the targeted modules.
5. **Expand gradually.** Don't try to mutate the entire repo on day 1.

## Validation that mutation testing is paying off

- [ ] At least one targeted module has mutation score ≥ 80%.
- [ ] PR CI shows mutation score delta for changed files.
- [ ] A surviving mutant from last quarter has a corresponding
      new test that now kills it (you actually act on the report).
- [ ] No "equivalent mutant" justification has been added without
      a code comment explaining why.
- [ ] Production bug rate in mutation-covered modules is lower
      than non-covered (measure for 90+ days).
