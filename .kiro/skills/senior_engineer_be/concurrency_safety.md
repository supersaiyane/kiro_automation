---
id: concurrency_safety
version: 1.0.0
owners: [senior_engineer_fe, senior_engineer_be]
tags: [concurrency, race-condition, deadlock, async, threads]
when_to_use: |
  Anywhere two execution contexts can touch the same data — threads,
  async tasks, processes, microservices reading each other's stores,
  even a single browser tab with race-prone effects.
inputs:
  - code_under_review: any shared-state access
outputs:
  - concurrency_audit: per-resource access pattern + chosen synchronization
---

# Concurrency Safety

## The four bugs to recognize on sight

1. **Race condition** — two operations interleave such that the final
   state depends on order. Read-modify-write without atomicity is the
   classic.
2. **Deadlock** — A holds lock X waiting for Y; B holds Y waiting for X.
   Nothing makes progress. Detected by lock-order analysis.
3. **Livelock** — both threads notice the conflict and back off, then
   immediately retry into the same conflict. CPU burns; no progress.
4. **Starvation** — one thread always loses the race. Fairness rules.

## The Read-Modify-Write trap

```python
# Two requests, same balance row, no locking:
b = account.balance        # both read 100
b = b - withdrawal         # both compute 70 (after a 30 withdraw)
account.balance = b        # last write wins; one withdrawal lost
```

Wrong solution: "just read again." Doesn't fix the race window.

**Right solutions, in increasing order of cost**:
- **Atomic compare-and-set** (CAS): `UPDATE accounts SET balance =
  balance - 30 WHERE id = 1 AND balance >= 30`. One statement,
  database does the atomicity. Check rows affected.
- **Optimistic locking** with a version column. Retry on conflict.
  Good when conflict rate is low.
- **Pessimistic locking** (`SELECT FOR UPDATE`). Holds a row lock for
  the duration. Use when conflict is common; avoid long-held locks.
- **Single-writer pattern**: only one process writes; others queue
  through it. Sequentializes by design.

## Locks — the etiquette

1. **Always acquire in the same order across all paths.** Lock A
   then B, never B then A. That's how deadlocks form.
2. **Hold for the shortest possible time.** Compute outside the lock;
   commit inside.
3. **Never call out under a lock.** No DB calls, no network calls,
   no callbacks. They might re-enter or wait on something that needs
   your lock.
4. **Timeouts on every blocking acquire.** Indefinite wait =
   indefinite outage when the deadlock happens.
5. **Recursive locks are a smell.** Usually you're trying to paper
   over a re-entry bug.

## Distributed locks — Redis is not magic

Single-Redis lock (SETNX with TTL) is wrong for safety-critical work:
- Process holds lock, GC pause exceeds TTL, lock expires, another
  process takes it, original wakes up and writes — bam, two writers.

For correctness-critical distributed locks:
- Use a fencing token (monotonically increasing). The DB rejects writes
  with stale tokens.
- Use a consensus-backed lock (etcd, ZooKeeper, Consul).
- Better: don't use distributed locks for correctness. Move to a
  single-writer model or use the database's transactional guarantees.

## Async/await pitfalls (Python, JS, etc.)

- **`await` is a yield point.** State can change in between. Don't
  assume invariants hold across `await`.
- **Don't mix sync and async.** Calling sync I/O from an async handler
  blocks the whole event loop.
- **Cancellation safety.** When a task is cancelled mid-write, what
  partial state remains? Use try/finally, idempotent operations.
- **`asyncio.gather` with shared mutable state** is a race kit. Wrap
  with a lock or use per-task state.
- **`asyncio.Lock` is NOT thread-safe.** It coordinates between tasks
  on one event loop. For multi-thread, use `threading.Lock`.

## Common patterns

### Idempotent writes
Build the write to be safe on retry. UPSERT with a deterministic key
(`UNIQUE` on natural ID). Avoid INSERT + later UPDATE patterns.

### Single-flight / request coalescing
Concurrent identical reads → one fetch, others wait on the result.
Prevents the cache-stampede + database thundering-herd.

### Compare-and-swap loops
```
while True:
    cur = read()
    new = compute(cur)
    if cas(cur, new):
        break
    # else: someone else changed it, loop
```
Works if `compute` is pure and conflict rate stays low.

### Producer/consumer with bounded queue
Backpressure. Producer blocks when the queue is full. Consumer pulls
at its own pace. The bound is the safety net for memory.

## Testing concurrency

- **`pytest-asyncio` + `asyncio.gather` of N tasks** to stress.
- **`pytest-flakefinder`** to re-run flaky tests 50× — flakes here
  are races.
- **Race detector tools**: Go's `-race`, Java's TSAN, Python's
  `concurrent-test-pythonic` (or thread-stress via `threading`).
- **Fuzz the interleavings**: deliberate `asyncio.sleep(random)`
  inserted in the unit-under-test reproduces races faster.

## Anti-patterns

- "It works on my machine." Concurrency bugs are scheduling-dependent;
  your local CPU count and OS hide them.
- A lock around every method "to be safe." You've serialized the
  service. Throughput collapses.
- `try: ... except: pass` to silence "weird intermittent errors."
  Almost always hiding a race.
- Sharing mutable state across async tasks without a lock.
- Trusting timestamps for ordering across machines. Clocks skew.
  Use monotonic version numbers or vector clocks.
- "We'll add concurrency safety later." You won't; by then production
  data is wrong.
