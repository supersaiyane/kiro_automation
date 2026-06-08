---
id: idempotency_patterns
version: 1.0.0
owners: [backend_lead, senior_engineer_be]
tags: [idempotency, retries, distributed, payments]
when_to_use: |
  Any endpoint that mutates state and may be retried — payments, signups,
  webhooks, async workers consuming from queues.
inputs:
  - mutation_endpoint: HTTP POST/PUT/DELETE description
outputs:
  - idempotency_design: key source, storage, TTL, replay behavior
---

# Idempotency Patterns

**Rule**: the second call must produce the SAME observable outcome as
the first, even if the network or worker retries.

**Client-supplied keys**
- Header `Idempotency-Key: <uuid v4>`.
- Server stores `{key → first_response}` for a TTL (24h typical).
- Replay returns the cached first response, never re-executes the side
  effect.

**Server-derived keys** (when clients can't be trusted)
- Hash of `(user_id, resource_id, intent, business-window)`.
- Window is the granularity that defines "same intent" (e.g. a calendar
  day for a payroll run).

**Storage choices**
- Postgres `idempotency_keys` table with a UNIQUE index — atomic
  insert-or-fail is the lock.
- Redis with `SET key value NX EX <ttl>` works for high-throughput
  endpoints but needs Postgres as durable backup for money flows.

**Anti-patterns**
- Idempotency on read endpoints (no-op; reads are already idempotent).
- TTL too short — a retried payment 25h later double-charges.
- Storing only the key, not the response — replay re-executes.
