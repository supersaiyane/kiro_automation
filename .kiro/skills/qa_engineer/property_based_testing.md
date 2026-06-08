---
id: property_based_testing
version: 1.0.0
owners: [qa_engineer, senior_engineer_be, senior_engineer_fe]
tags: [testing, property-based, hypothesis, quickcheck, fuzzing]
when_to_use: |
  Functions whose specification is a property over all inputs
  (parsers, encoders, serializers, math, state machines). Catches
  bugs example-based tests can't imagine.
inputs:
  - function_under_test + its specification
outputs:
  - property_tests: invariants + minimal shrunk counterexamples
---

# Property-Based Testing (PBT)

## What it is, in one paragraph

Example-based tests assert behavior on specific inputs you thought of.
Property-based tests assert *properties* that should hold for **all**
inputs, then a framework (Hypothesis in Python, fast-check in JS,
QuickCheck in Haskell) generates hundreds of inputs across the domain
and **shrinks** any failing one to a minimal counterexample.

## The properties worth writing

### 1. Round-trip (encode → decode)
```python
@given(st.text())
def test_roundtrip(s):
    assert decode(encode(s)) == s
```
Catches: lossy encoders, edge-case escaping, Unicode normalization
bugs.

### 2. Inverse functions
```python
@given(st.lists(st.integers()))
def test_sort_inverse_sort(xs):
    assert sorted(sorted(xs), reverse=True) == sorted(xs, reverse=True)
```

### 3. Idempotence
```python
@given(st.text())
def test_normalize_idempotent(s):
    assert normalize(normalize(s)) == normalize(s)
```

### 4. Invariants preserved
```python
@given(st.lists(st.integers()))
def test_sort_preserves_count(xs):
    assert len(sorted(xs)) == len(xs)
    assert set(sorted(xs)) == set(xs)
```

### 5. Oracles (compare two implementations)
- Fast vs reference. Optimized vs simple.
- New algorithm vs the trusted slow one.
```python
@given(st.lists(st.integers()))
def test_fast_sort_matches_slow(xs):
    assert fast_sort(xs) == sorted(xs)
```

### 6. Metamorphic relations
"f(x+1) > f(x)" type assertions. Useful for math, ML inference,
ranking functions.

### 7. Stateful / model-based
Use Hypothesis' `RuleBasedStateMachine`. Drive a sequence of
operations against your system, compare against a simple Python
reference model.

## Writing strategies (Hypothesis idioms)

```python
from hypothesis import given, strategies as st, assume, settings

@settings(max_examples=500, deadline=200)
@given(
    user_id=st.integers(min_value=1),
    email=st.emails(),
    age=st.integers(min_value=0, max_value=120),
)
def test_user_save_then_load(user_id, email, age):
    assume(email != "")  # filter rather than narrow the strategy
    save(User(user_id, email, age))
    loaded = load(user_id)
    assert loaded.email == email
    assert loaded.age == age
```

- Use `assume` for sparse pre-conditions; the framework will resample.
- Use bounded strategies for performance; unbounded for thoroughness.
- Set `max_examples` higher in CI nightly, lower for PR checks.
- `@reproduce_failure(...)` decorator pins a previously-found
  counterexample as a permanent regression test.

## Stateful testing — when concurrency / sequences matter

```python
class CounterStateMachine(RuleBasedStateMachine):
    def __init__(self):
        super().__init__()
        self.counter = Counter()
        self.model = 0  # ref impl

    @rule()
    def increment(self):
        self.counter.inc()
        self.model += 1

    @rule()
    def decrement(self):
        self.counter.dec()
        self.model -= 1

    @invariant()
    def values_match(self):
        assert self.counter.value() == self.model
```

Hypothesis explores random sequences of rules; on failure, it shrinks
to a minimal reproducing sequence — sometimes 3 calls instead of 50.

## Shrinking is the secret weapon

Without shrinking, "your function broke on `'a©fñ​‮' + 117
char Unicode mix at index 42`" is unactionable. With shrinking,
Hypothesis reduces to `'©'` (one character) — instantly debuggable.

If a test fails with a 30-character random string, your shrinker
isn't working. Investigate the strategy.

## When PBT pays off

- Parsers + serializers (JSON, CSV, custom wire formats)
- Encoders/decoders (base64, URL encoding, escaping)
- Math + numerical functions
- Data-structure operations (sort, dedupe, merge)
- State machines (cart, order, payment)
- Schemas + migrations (round-trip the schema)
- Concurrent code (stateful, shrunk to small sequences)

## When example-based is enough

- Pure UI rendering (one example per visual state).
- Integration tests across N systems (set up cost dominates).
- Snapshot tests for stable outputs.

PBT complements example-based; it doesn't replace it.

## Anti-patterns

- One PBT and 30 example tests with overlapping coverage. Replace
  example tests with the property they implied.
- Properties that are tautologies (`assert f(x) == f(x)`). Reviews
  miss these; they always pass.
- Filtering strategies down so far that they generate nothing.
  `assume(condition)` should reject < 10% of generated values; if
  more, narrow the strategy.
- No reproducible seed on flakes. Hypothesis prints the seed —
  capture it as a permanent example.
- Stateful tests without a reference model. You're just exercising
  code; you haven't asserted anything.
- Running PBT in PR-blocking CI with max_examples=10000. Move heavy
  runs to nightly; PR gets a smoke run.
