---
id: event_sourcing_cqrs
version: 1.0.0
owners: [architect, backend_lead]
tags: [event-sourcing, cqrs, audit, eventual-consistency, read-write-split]
when_to_use: |
  Domains where the AUDIT TRAIL is the product (finance, healthcare,
  regulated industries). Heavy-read systems where the read shape
  differs sharply from the write shape (analytics, search). When you
  need to replay history into new projections.
inputs:
  - domain_model, projected_query_load, audit_requirements
outputs:
  - event_schema, command_handlers, projection_handlers, snapshot_policy
---

# Event Sourcing + CQRS

## Two patterns, often paired

- **Event Sourcing**: the source of truth is an APPEND-ONLY log of
  domain events. Current state is derived by replaying the log.
- **CQRS** (Command-Query Responsibility Segregation): the model
  optimized for writes is DIFFERENT from the model optimized for
  reads. Updates go through commands; queries hit projections.

They are independent but synergize: event sourcing produces the log,
CQRS uses it to build many read shapes.

## When event sourcing is RIGHT

- The audit trail is itself a product feature (financial ledger,
  medical records).
- You need to answer "what was the state at time T" — replay.
- You need new query shapes over old data (build a new projection +
  replay history).
- Domain events carry intent that pure state changes lose ("user
  cancelled subscription due to billing error" vs. just
  `subscription.active = false`).

## When event sourcing is WRONG

- Simple CRUD with no audit need.
- Domain has heavy mutation of complex graphs (you'll fight aggregate
  consistency).
- Team is new to distributed systems — operational complexity is real.
- The team thinks "eventually consistent" means "eventually correct
  enough." It doesn't; it requires explicit user-experience design.

## The basic shapes

### Write side

```
[Command: PlaceOrder]
       ↓
  Aggregate.handle(cmd):
    validate invariants
    emit: [Event: OrderPlaced(order_id, items, total, ...)]
       ↓
  Event Store (append-only): events ordered by aggregate_id
```

### Read side

```
Event Store
   ↓ subscribe
[Projection Handler]
   ↓ build
[Read Model: OrderSummaryView, by customer_id]
   ↑
[Query: GET /customers/{id}/orders]
```

## Aggregates

The unit of consistency. One aggregate = one transactional boundary =
one event-store stream. Per-aggregate invariants are enforced
synchronously; cross-aggregate consistency is eventual (via sagas —
see `saga_pattern_distributed_transactions`).

Rule of thumb: keep aggregates small. A "Customer" aggregate that owns
all orders, addresses, payment methods, and preferences is a hot row
and a write-contention nightmare. Split.

## Snapshots

Replaying 100K events to load an aggregate is slow. Snapshot the
aggregate state every N events; load = latest_snapshot + events_after.
Per-aggregate replay budget should be <100ms p99.

## CQRS without event sourcing

You can do CQRS on a traditional DB:
- Writes via commands hit the main DB.
- Reads come from denormalized views (materialized in another DB or in
  the same DB).
- View sync happens via CDC (Debezium) or app-side writes.

This is often the right starting point — CQRS without event sourcing.
Add event sourcing later if you genuinely need replay.

## Schema evolution

The hardest operational problem. Events live forever; you can't
"migrate" them.

- **Versioned events**: `OrderPlacedV1`, `OrderPlacedV2`. New handlers
  understand both.
- **Upcasters**: on read, transform old events into the new shape.
- **NEVER** rewrite history. The whole point of event sourcing is the
  immutable record.

## Anti-patterns

- **CRUD with events** — emitting `OrderUpdated` for everything,
  effectively storing state changes instead of intent. Half the cost,
  none of the benefit.
- **Reading the event store directly** for queries. Always project to
  a read model. Reading raw event streams = O(history) per query.
- **Aggregates that span 6 entities.** Either redesign (smaller
  aggregates) or accept saga-coordinated consistency.
- **No projection lag SLO.** Users will see stale reads; design + alert
  for it. "Read after own write" requires special handling (sticky
  reads, optimistic UI).
- **GDPR right-to-be-forgotten without crypto-shredding.** Immutable
  events × PII = regulatory problem. Use envelope encryption per
  subject + key deletion.

## Operational checklist

- [ ] Event schema versioning + upcaster pipeline
- [ ] Snapshot policy + frequency
- [ ] Projection lag SLO + alerting
- [ ] Idempotent projection handlers (replay-safe)
- [ ] PII encryption with key-per-subject (for forgettability)
- [ ] Replay procedure documented and TESTED in staging
