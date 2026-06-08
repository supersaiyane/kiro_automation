---
id: outbox_pattern_event_publishing
version: 1.0.0
owners: [backend_lead, architect]
tags: [outbox, eventual-consistency, debezium, cdc, sagas, idempotency]
when_to_use: |
  Any service that must update its DB AND publish an event "atomically"
  to drive downstream systems. Without the outbox, the two diverge —
  state updates without events, or events without state. Direct pairing
  with `saga_pattern_distributed_transactions`.
inputs:
  - service_db, message_broker, event_schema
outputs:
  - "outbox_design: schema + relay process + idempotency strategy + observability"
---

# The Transactional Outbox Pattern

> Two-phase commit across a DB and a message broker is unavailable
> in practice. The outbox approximates it: write the event to the
> SAME database transaction as the state change, then ship it.

## The failure mode it fixes

Naive pattern:

```
BEGIN
  UPDATE orders SET status='paid' WHERE id=X;
  publish(OrderPaid{id:X});  -- network call inside a DB transaction (BAD)
COMMIT
```

Failures:
- `publish` fails → state changed, no event → downstream stale forever.
- `publish` succeeds but `COMMIT` fails → event published, no state →
  downstream acts on phantom data.
- Both succeed but in a long-running tx → DB locks held during a
  network call, throughput tanks.

You can't fix this with retries inside the same transaction. You
need to make publishing a CONSEQUENCE of the commit, not a peer
to it.

## The outbox shape

```sql
CREATE TABLE outbox (
  id            UUID PRIMARY KEY,
  aggregate_id  UUID NOT NULL,             -- entity this event is about
  event_type    TEXT NOT NULL,             -- 'OrderPaid', 'UserCreated'
  payload       JSONB NOT NULL,            -- the event body
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at  TIMESTAMPTZ,               -- NULL = pending
  attempts      INT NOT NULL DEFAULT 0,
  next_attempt  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX outbox_pending_idx
  ON outbox (next_attempt) WHERE published_at IS NULL;
```

The producer:

```sql
BEGIN
  UPDATE orders SET status='paid' WHERE id=X;
  INSERT INTO outbox(id, aggregate_id, event_type, payload)
    VALUES (gen_random_uuid(), X, 'OrderPaid', '{"order_id":"X",...}');
COMMIT
```

Now the state change and the event-to-be are committed atomically.
If anything fails before COMMIT, both roll back together.

## The relay — two strategies

### Strategy A: Polling relay (simplest)

A separate process (or scheduled job, or sidecar) does:

```python
while True:
    rows = SELECT * FROM outbox
      WHERE published_at IS NULL AND next_attempt <= now()
      ORDER BY created_at LIMIT 100 FOR UPDATE SKIP LOCKED;
    for row in rows:
        try:
            broker.publish(row.event_type, row.payload, key=row.aggregate_id)
            UPDATE outbox SET published_at = now() WHERE id = row.id;
        except:
            UPDATE outbox SET attempts = attempts + 1,
              next_attempt = now() + backoff(attempts) WHERE id = row.id;
    if not rows: sleep(1s)
```

- Pros: works on any DB, no extra infra.
- Cons: polling latency (typically 100ms-1s), DB load.
- Use SKIP LOCKED so multiple relay workers don't fight for rows.

### Strategy B: CDC via Debezium (most scalable)

Debezium tails the database's WAL (Postgres) / binlog (MySQL) and
publishes outbox INSERTs as Kafka events directly:

```
[ App ] → [ Postgres ] → [ Debezium ] → [ Kafka ] → [ Consumers ]
                ↑              │
                └── tails WAL ─┘ (no polling, sub-100ms latency)
```

Use the Debezium outbox event router so the Kafka topic, key, and
payload are pulled from your outbox columns, not from the binary
WAL change record.

- Pros: low latency, no polling load on the OLTP DB.
- Cons: Debezium + Kafka Connect is operational work; learning curve.

**Rule of thumb**: start with polling. Move to Debezium when polling
latency or DB load is measurably a problem.

## Idempotency on the consumer side

Outbox guarantees AT-LEAST-ONCE delivery. Consumers WILL see
duplicates (relay retry, broker re-delivery, replay).

Every consumer must:

```sql
CREATE TABLE consumed_messages (
  message_id UUID PRIMARY KEY,
  consumed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- inside the consume transaction:
INSERT INTO consumed_messages(message_id) VALUES (X)
  ON CONFLICT DO NOTHING;
-- if 0 rows inserted, this is a duplicate → skip the side-effect
-- if 1 row inserted, do the side-effect
COMMIT
```

The message_id is the outbox row id, NOT a broker-assigned offset.
Stable, end-to-end.

## Schema evolution

- Event payloads are public contracts. Once shipped, additive only:
  ADD optional fields, never RENAME or REMOVE.
- Stamp every event with `schema_version` so consumers can branch
  if you have to introduce breaking shapes (rare; prefer additive).
- Use Avro or JSON Schema in a schema registry if events cross
  service boundaries. Catch breakage at CI, not at 3am.

## Observability

- **Outbox lag** = max(now - created_at WHERE published_at IS NULL).
  Page on > 60s sustained. Lag is the canary that the relay is dead.
- **Attempt distribution** — most events should be 1 attempt. A long
  tail at 10+ attempts = broker problem.
- **Per-event-type publish rate** — sudden zero = code path
  silently stopped emitting. Alert on the absence.
- **Garbage collection** — published rows older than 30 days can
  be deleted (or moved to cold storage if you replay events).

## Anti-patterns

- **publish() outside the transaction.** That's the bug the outbox
  fixes. Don't recreate it.
- **One outbox table per service is fine; one per cluster is not.**
  Each service owns its own outbox in its own DB.
- **Consumers that "trust the broker" for de-dup.** Brokers
  guarantee at-least-once. De-dup is the consumer's job.
- **Ordering across aggregates.** Outbox preserves per-aggregate
  order (via key=aggregate_id partition). Cross-aggregate order is
  not preserved and usually doesn't matter; if it does, you're
  modeling wrong.
- **Long-lived outbox rows.** Without GC, the table grows forever
  and the pending index loses utility.
- **Mixing the outbox with business tables (joins).** The outbox
  is a tail. Treat it as write-only from business code; only the
  relay reads it.

## Sequencing with sagas

The outbox is the publish leg of a `saga_pattern_distributed_transactions`
step. Without it, a saga can update its local state, crash mid-publish,
and stall the saga forever. Pair them — never deploy sagas without
also deploying the outbox in every participating service.

## Validation that the outbox is real

- [ ] Killing the relay process for 30 seconds causes ZERO data
      loss — events are still in the outbox, published on relay restart.
- [ ] Killing the message broker for 30 seconds causes ZERO event
      loss — same reason.
- [ ] Force-killing the app between state UPDATE and outbox INSERT
      results in NEITHER happening (atomic transaction).
- [ ] Consumer can be deployed with code that processes the same
      event twice and produces the same downstream state.
- [ ] Outbox-lag dashboard exists; alert fires < 60s after relay death.
