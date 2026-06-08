---
id: saga_pattern_distributed_transactions
version: 1.0.0
owners: [backend_lead, architect]
tags: [saga, distributed-transactions, microservices, choreography, orchestration]
when_to_use: |
  A business operation spans multiple services + databases and must be
  "all or nothing" — but you've correctly given each service its own DB
  and can't use a 2PC distributed transaction. Classic cases: order
  flow (inventory + payment + shipping), user signup (auth + billing +
  notification), refund flow.
inputs:
  - business_flow: ordered steps across multiple services
outputs:
  - saga_design: "choreography vs orchestration choice, per-step compensating actions, idempotency strategy, observability"
---

# The Saga Pattern (Chris Richardson)

> Once each microservice owns its own DB, two-phase commit becomes a
> liability. Sagas coordinate **eventual consistency** across services
> via a sequence of local transactions, each with a compensating
> action for rollback.

## The two flavors

### Choreography

Services communicate via events. No central coordinator.

```
[Order Service] --order.placed--> (event bus)
                                     ↓
[Inventory Service] reserves stock, emits inventory.reserved
                                     ↓
[Payment Service] charges, emits payment.captured
                                     ↓
[Shipping Service] schedules, emits shipping.scheduled
```

- **Pros**: loose coupling, easy to add new participants.
- **Cons**: hard to see the full flow in one place; debugging is
  spelunking across logs; ordering bugs are subtle.

Use for **simple, short sagas** (≤ 3 steps).

### Orchestration

A central orchestrator (saga coordinator) drives the flow.

```
[Saga Coordinator]
  step 1: Inventory.reserve(...) → success
  step 2: Payment.charge(...) → success
  step 3: Shipping.schedule(...) → FAIL
  → compensate: Payment.refund(...)
  → compensate: Inventory.release(...)
```

- **Pros**: flow is explicit in one place; testable; failure handling
  is centralized.
- **Cons**: orchestrator becomes a coupling point; service-locator-y.

Use for **complex sagas** (≥ 4 steps) or **regulated flows** (payments,
medical, legal — auditors need a clear flow record).

**Rule of thumb**: start with choreography. Refactor to orchestration
when debugging cost or audit needs exceed the coupling cost.

## Compensating actions — the hardest part

For every forward step, design the compensating action UP FRONT.

| Forward | Compensation |
|---|---|
| Reserve inventory (decrement stock) | Release inventory (increment stock) |
| Charge payment | Refund payment |
| Send confirmation email | Send cancellation email (NOT "unsend") |
| Provision user account | Mark account suspended (NOT "delete") |

Critical rules:
- **Compensations must be idempotent** (you may retry them).
- **Compensations must SEMANTICALLY undo** — not literally undo.
  You can't unsend an email; you send a correction.
- **Some steps are not compensatable** (sent SMS, dispatched
  physical goods). Order steps so non-compensatable actions come
  LAST and only after the saga has otherwise committed.
- **Pivot steps**: the step after which compensation becomes
  impossible. Document it explicitly per saga.

## The OUTBOX pattern — without which sagas leak

Critical pairing: the saga needs to publish events atomically with
state changes. WITHOUT the outbox, you can:

1. Update DB (succeed).
2. Crash before publishing event.
3. State + event diverge — saga stalls forever.

The outbox:
1. Inside the same DB transaction, write the event to an `outbox`
   table.
2. A separate process (Debezium / pg_notify / poller) reads `outbox`
   and publishes to the message broker.
3. Publisher marks the row published.

See `outbox_pattern_event_publishing` for the full pattern.

## Idempotency

Every saga step + every consumer must be idempotent:
- **Saga steps**: use deterministic idempotency keys (e.g.
  `saga_id + step_id`). Repeat invocations no-op.
- **Consumers**: track processed message IDs in a `consumed_messages`
  table. Reject duplicates.

Without idempotency, retries (which WILL happen) cause double charges
and triple-decremented inventory.

## Observability

A saga that fails silently is the worst possible system. Required:

- **Correlation ID** on every step + every event + every log line.
- **Saga state machine** observable in a dashboard (which step, last
  transition, last error).
- **Lag SLO**: a saga that's been in a non-terminal state for > N
  minutes pages someone.
- **Dead-letter queue** for events that fail compensation; explicit
  manual replay procedure documented.

## Anti-patterns

- **Implicit sagas** — the flow exists only in the heads of the
  developers who wrote it. Document it; draw the state machine.
- **Compensations that aren't tested.** They WILL fire eventually.
  Test them in CI: deliberately fail step N, verify all preceding
  steps' compensations ran.
- **Non-idempotent compensation.** Compensation retries cause
  triple-refunds.
- **Saga coordinator that calls services synchronously**. Now you've
  rebuilt distributed transactions on top of HTTP — all the latency,
  none of the reliability.
- **Sharing the saga state across services**. The coordinator owns
  the state. Participants are stateless from the saga's perspective.

## Migration from "we already have distributed transactions"

If you've inherited a system with two-phase commit across services:
1. Identify each business flow that spans services.
2. Decide: choreography or orchestration per flow.
3. Add idempotency keys to every relevant endpoint.
4. Implement compensations as code, not as ad-hoc cleanup scripts.
5. Switch one flow at a time. Keep the old 2PC path as a fallback
   until the new saga has been in prod for 30+ days.
