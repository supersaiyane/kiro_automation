---
id: domain_driven_design
version: 1.0.0
owners: [architect, backend_lead]
tags: [ddd, evans, bounded-context, ubiquitous-language, strategic-design]
when_to_use: |
  Designing a system whose business domain is complex (≥ 5 actors,
  ≥ 3 distinct flows). Decomposing a monolith. Naming services for a
  greenfield system. When two teams use the same word to mean different
  things and ship inconsistent behavior.
inputs:
  - business_domain_map, key_user_journeys
outputs:
  - bounded_contexts: named domains + ubiquitous languages
  - context_map: integration patterns between contexts
---

# Domain-Driven Design (Eric Evans)

> The first job of architecture is to **align the software model with
> the business**. DDD's strategic patterns are how you do that at scale.

## Two layers

| Strategic DDD | Tactical DDD |
|---|---|
| Bounded contexts, ubiquitous language, context maps, subdomains | Entities, value objects, aggregates, domain events, repositories |
| Architect's primary tool | Senior dev's primary tool |
| Decides service boundaries | Decides class structure |

We focus on strategic here; tactical is in a separate skill (see
`tactical_ddd` if added).

## Bounded Context

A **bounded context** is the explicit boundary inside which a
particular domain model + language is consistent. Outside the
boundary, the same word may mean a different thing.

Example: in an e-commerce system, "Order" means:
- In Sales context: a quote + checkout state
- In Fulfillment context: a pick-list + shipment
- In Billing context: a charge + invoice

Three different models. Three different services. One name. Trying to
make one "Order" class serve all three contexts is the #1 source of
distributed-monolith pain.

## Subdomain classification

Per domain, classify:
- **Core domain** — what differentiates the business. Build, don't buy.
  Highest engineering investment. Owns most of the senior talent.
- **Supporting** — necessary but not differentiating. Build pragmatically
  or use OSS.
- **Generic** — undifferentiated commodity (auth, billing rails,
  email). BUY.

The CTO's build-vs-buy decision starts here.

## Context Map — relationships between contexts

DDD names the integration patterns between contexts:

| Pattern | Meaning | When to use |
|---|---|---|
| **Shared Kernel** | Two contexts share a small common model | Same team, tight collaboration. Rare. |
| **Customer / Supplier** | Upstream serves downstream; downstream has influence | Mainstream — most internal API relationships |
| **Conformist** | Downstream accepts upstream's model as-is | When upstream is too powerful to influence (3rd-party API) |
| **Anti-Corruption Layer (ACL)** | Downstream translates upstream's model into its own | When upstream's model would pollute yours — VERY common with legacy systems |
| **Open Host Service** | Upstream publishes a standard protocol | Public APIs |
| **Published Language** | A formal, well-documented schema between contexts | gRPC + protobuf, event schemas |
| **Separate Ways** | No integration | When integration cost exceeds value |
| **Partnership** | Two contexts succeed or fail together | Joint products, tight SLA |

## Ubiquitous Language

Inside a bounded context, **everyone uses the same vocabulary** —
domain experts, designers, engineers, code. If business says "policy,"
the class is `Policy`, the table is `policies`, the URL is `/policies`.

Translate at the boundary, never internally.

## How to identify bounded contexts (in practice)

1. **Event storming** workshop with domain experts. Sticky notes for
   domain events. Group events that flow together.
2. **Look for language ambiguity**. "Order" means different things to
   different teams = strong signal these are separate contexts.
3. **Look at team structure** (Conway's Law). Teams that change
   together at the same cadence usually own one context.
4. **Look at the data-store coupling**. Tables that read each other
   across team lines are leakage; tables fully owned by one team are
   in that team's context.

## Anti-patterns

- **One big domain model** — the "canonical Order class" used by 12
  teams. Devolves into a god class everyone is afraid to touch.
- **Premature decomposition** — splitting into 30 microservices before
  understanding the domain. You get distributed-monolith pain without
  the upsides.
- **No anti-corruption layer with legacy systems** — your shiny new
  service starts speaking the legacy's broken language; debt
  propagates.
- **Bounded contexts named by tech layer** ("ApiService",
  "DatabaseService"). Name by domain ("Sales", "Fulfillment").
- **Treating DDD as a doctrine to follow ritualistically.** It's a
  toolkit; the question is always "does this lens reveal a better
  decomposition?"

## Validation that DDD is working

- A new engineer can predict which service owns a given concept
  without checking.
- Cross-team incidents trace to a documented context-map relationship
  (not "we didn't know about each other").
- A product change in context A doesn't require sync with context B
  except at known boundaries.
