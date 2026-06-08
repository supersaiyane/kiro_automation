---
id: microservices_decomposition
version: 1.0.0
owners: [architect, cto]
tags: [microservices, newman, decomposition, bounded-context, monolith]
when_to_use: |
  Considering a monolith-to-microservices migration, or designing a
  greenfield system that already feels too large for one team. Apply
  AFTER you've identified bounded contexts (see `domain_driven_design`).
inputs:
  - current_architecture, team_topology, scale_pressure
outputs:
  - decomposition_plan: which services, in what order, with what edges
---

# Microservices Decomposition (Sam Newman)

> Microservices are an organizational pattern as much as an
> architectural one. If your team structure doesn't change, your
> architecture can't either (Conway's Law).

## Default: do NOT decompose

Most teams should not start with microservices. The right starting
point for new products is a **well-modularized monolith** ("modular
monolith" / "moduliths"). Decompose when one of these is true:

1. **Team scale** — > 30 engineers stepping on each other in one repo.
2. **Independent deploy cadence** — module A needs to ship 10x/day,
   module B once a quarter, and they're in the same repo.
3. **Distinct scaling profile** — one capability needs 100x the
   resources of others.
4. **Compliance isolation** — one capability handles regulated data
   that demands separate runtime + access controls.

Decomposing for any other reason (resume-driven, "best practices",
fashion) is technical-debt-by-distribution.

## Service boundaries from bounded contexts

A service per bounded context is the default starting point (see
`domain_driven_design`). Refine with these signals:

- **Single team ownership.** A service owned by 2 teams isn't a
  service; it's a battleground.
- **Data ownership.** Service owns its database. Other services NEVER
  touch the DB directly — only the API. Shared DB across services =
  distributed monolith.
- **Failure isolation.** Failure in service A shouldn't take down B
  unless B's product reason requires it.

## Decomposition strategies

### Strangler Fig (Martin Fowler)

The proven path for monolith → microservices:

```
1. Build a façade in front of the monolith (router / API gateway).
2. New capabilities go in new services BEHIND the façade.
3. Migrate existing capabilities one slice at a time:
   a. Implement the slice in a new service.
   b. Switch the façade to route to the new service.
   c. Decommission the slice in the monolith.
4. When all slices are migrated, the monolith is empty; remove it.
```

Months 1-12 typical. Avoids the "big rewrite that never ships."

### Branch by Abstraction

When the change is INSIDE a single service but moves the implementation
behind an abstraction layer first, switches, then removes the old
implementation. Useful for storage swaps (Postgres → Cassandra) within
one service without long-lived branches.

### Database-First Decomposition

Often the database is the hardest part. Steps:
1. Identify table groups (clusters that interact).
2. Move one cluster behind a service interface; readers go through API.
3. Migrate the cluster to a separate DB; the service owns it.
4. Repeat.

This is harder than the code split; budget more time.

## Inter-service communication

Two main patterns, each with use cases:

### Synchronous (REST / gRPC)

Use when:
- The caller needs the response immediately to proceed.
- The transaction is short and the downstream is reliable.

Implement with:
- Idempotent endpoints.
- Timeouts (always — never unbounded).
- Circuit breakers + bulkheads (see `circuit_breaker_bulkhead`).
- Retries with exponential backoff + jitter.

### Asynchronous (events / messages)

Use when:
- The caller doesn't need the response synchronously.
- Multiple downstreams care about the event.
- You want loose coupling (downstream can be added later without
  touching the producer).

Implement with:
- Kafka / SQS / RabbitMQ as the broker.
- Outbox pattern at the producer (see `outbox_pattern_event_publishing`).
- Idempotent consumers.
- Schema registry for evolution.
- Dead-letter queues with explicit replay procedure.

## Cross-cutting concerns

Once you have N services, you need these uniformly:
- **Observability** — distributed tracing (OTel), correlation IDs.
- **Auth** — central identity service issuing short-lived tokens.
- **Service discovery + load balancing** — built into the platform.
- **Schema management** — for both APIs and events.
- **Deployment** — every service has the SAME pipeline shape.

A team that ships microservices without these will spend more time on
operational pain than they saved on team friction.

## Anti-patterns

- **Distributed monolith** — services that must deploy together.
  Coupling at the data or API level. Cost of microservices, none of
  the benefits.
- **Anemic services** — services that wrap one CRUD endpoint and
  forward to a shared DB. Just an HTTP detour.
- **Shared database** — N services, one DB. Pick the wrong abstraction
  and any service can corrupt others' data.
- **Synchronous chains** — A → B → C → D for one user request.
  Latency = sum; failure rate = product.
- **Premature decomposition** — splitting a 10-person team's monolith
  into 12 services. Spend 6 months on operational plumbing instead of
  features.
- **No API versioning + breaking changes** — every downstream breaks
  on the producer's whim.

## Decomposition success metrics

- **Team independence** — a team can release without coordinating with
  another team ≥ 80% of the time.
- **Lead time for change** — pull request → production < 1 day per
  service.
- **Blast radius** — incident in service X impacts < 30% of users.
- **Service ownership clarity** — one named on-call per service.
