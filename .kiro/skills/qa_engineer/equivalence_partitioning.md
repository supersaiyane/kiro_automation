---
id: equivalence_partitioning
version: 1.0.0
owners: [qa_engineer]
tags: [testing, boundary, equivalence, coverage]
when_to_use: |
  Designing test cases for a function or endpoint with structured
  inputs — anywhere a thoughtful set of cases beats "test every value".
inputs:
  - input_domain: parameter types + valid range per parameter
outputs:
  - test_cases: representative cases per equivalence class + boundaries
---

# Equivalence Partitioning + Boundary Value Analysis

**Idea**: inputs fall into classes where every value behaves the same.
Test one representative per class plus the boundaries between classes.

**Procedure**
1. List input parameters + their valid range.
2. Partition each parameter into equivalence classes (valid + invalid).
3. Pick one VALUE from the middle of each class (representative).
4. Add the BOUNDARY values: min, min-1, max, max+1.
5. For multi-parameter functions, combine partitions thoughtfully — not
   every combination, just the ones that exercise interaction.

**Example: a function `discount(age, plan)`**

| age class | plan class | representative | boundary |
|-----------|------------|----------------|----------|
| <18 (invalid) | any | 12 | 17, 18 |
| 18-64 (valid)  | "free" | 30 | — |
| 18-64 (valid)  | "pro"  | 30 | — |
| 65+ (valid, senior) | any | 70 | 64, 65 |

**Anti-patterns**
- 200 test cases that all hit the same equivalence class.
- Boundaries skipped because "the middle case passes".
- Multi-param interaction never tested.
