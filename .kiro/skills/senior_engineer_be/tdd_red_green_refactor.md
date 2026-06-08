---
id: tdd_red_green_refactor
version: 1.0.0
owners: [senior_engineer_fe, senior_engineer_be]
tags: [tdd, testing, red-green-refactor, methodology]
when_to_use: |
  Implementing a new function, bugfix with a reproducible failure, or any
  logic where the behavior is clear before the implementation.
inputs:
  - acceptance_criteria: Given/When/Then list from the story
outputs:
  - tested_code: implementation with passing tests
---

# Red / Green / Refactor

**Cycle, repeated every ~10 minutes**

1. **Red** — write the smallest failing test that names the next
   behavior. It MUST fail for the right reason (NameError ≠ valid red).
2. **Green** — write the minimum code that makes the red test pass.
   Permission to be ugly. Don't generalize prematurely.
3. **Refactor** — with every test green, clean up: rename, extract,
   remove duplication. No new behavior in this step.

**Don'ts**
- Don't write more than one failing test at a time.
- Don't skip refactor — that's where the design improvement happens.
- Don't refactor with a red test on the board.

**Test naming**

`test_<what>_<given>_<expected>`:
- `test_login_with_wrong_password_returns_401`
- `test_search_with_empty_query_returns_empty_list`

**Anti-patterns**
- Tests that mirror the implementation (mock the function under test).
- Tests that pass before the change is even made — they tested nothing.
