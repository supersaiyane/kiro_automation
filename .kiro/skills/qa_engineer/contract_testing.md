---
id: contract_testing
version: 1.0.0
owners: [qa_engineer, backend_lead, senior_engineer_be]
tags: [testing, contract, pact, consumer-driven, integration]
when_to_use: |
  Services that depend on each other's APIs. Contract testing
  catches breakage in CI BEFORE the downstream service deploys.
  Eliminates the "their API changed and we didn't know" outages.
inputs:
  - consumer + provider APIs
outputs:
  - contract: pact / pb-spec / openapi-test that pins the consumer's actual usage
---

# Contract Testing (Consumer-Driven)

## Why integration tests aren't enough

Classic integration tests spin up the real downstream service.
Problems:
- **Slow.** End-to-end suites take 20-60 minutes.
- **Flaky.** Network, DB state, async events.
- **Late signal.** Failure shows in a nightly run, after merge.
- **Coupled deploys.** "We can't deploy until they deploy."

Contract tests fix these by replacing the integration with a
**contract** the consumer pins and the provider verifies — separately,
in their own CI, before they deploy.

## The flow (consumer-driven model)

```
CONSUMER CI                              PROVIDER CI
┌─────────────────────┐                  ┌─────────────────────┐
│ run consumer tests  │                  │ pull contracts from │
│ against MOCK provider│                  │ the broker         │
│ generate contract   │                  │                     │
│ (request+response   │                  │ replay each contract│
│ pact)               │                  │ against REAL service │
└──────────┬──────────┘                  │                     │
           │ publish to                  │ assert behavior     │
           ▼                              │ matches              │
   ┌───────────────┐                     │                     │
   │ Pact Broker   │  ◄──────────────────┘                     │
   │ (versioned)   │                                            │
   └───────────────┘   block deploy if contracts fail           │
                                          └─────────────────────┘
```

Two key properties:
- **Provider doesn't run consumer tests.** It runs ITS verification
  of the contracts.
- **Consumer doesn't need provider live.** It runs against the mock.

Both can deploy independently. Pact (or equivalent) is the gate.

## What goes in a contract

```json
{
  "consumer": "checkout-service",
  "provider": "pricing-service",
  "interactions": [
    {
      "description": "fetch price for SKU 42",
      "request": {
        "method": "GET",
        "path": "/v1/prices/42",
        "headers": { "Accept": "application/json", "x-tenant": "t-7" }
      },
      "response": {
        "status": 200,
        "headers": { "Content-Type": "application/json" },
        "body": { "sku": 42, "price_cents": 1999, "currency": "USD" }
      }
    },
    {
      "description": "fetch price for missing SKU",
      "request": { "method": "GET", "path": "/v1/prices/missing" },
      "response": { "status": 404, "body": { "error": "not_found" } }
    }
  ]
}
```

Important: the contract captures **only the fields the consumer reads**.
If the provider adds a field, that's not a breaking change. If they
remove a field the consumer uses, contract verification fails.

## Provider states

Some interactions need a precondition ("user 42 exists"). The
contract names a *state*; the provider supplies a setup hook:

```python
@provider_state("user 42 exists")
def state_user_42():
    db.users.insert({"id": 42, "name": "Test"})
```

Keeps the consumer's test deterministic without coupling the consumer
to provider internals.

## What contract tests catch

- Removed field the consumer reads.
- Type change (string → number).
- Required header now missing.
- Status code change (200 → 204).
- Required request field newly missing or renamed.
- Auth header format drift.

What they DON'T catch (don't pretend they do):
- Performance regressions.
- Business-logic correctness on the provider side.
- Data integrity over multiple calls.
- Concurrency / race conditions.

Pair with: targeted integration tests for the few flows that actually
require end-to-end (auth, payment, ordering).

## Deployment gating

The Pact Broker tracks `can-i-deploy?`:
- Consumer C v1.2 must verify against Provider P v2.4 (currently in prod).
- Provider P v2.5 candidate must verify all consumers C, D, E
  that are currently deployed.

Block the deploy on this check. CI integration:
```yaml
- name: can-i-deploy
  run: pact-broker can-i-deploy --pacticipant checkout --version $GIT_SHA
```

## Anti-patterns

- Provider-driven contracts (the *provider* writes the contract). Then
  the consumer's actual usage drifts silently. Always consumer-driven.
- Contracts that assert every field — including ones the consumer
  doesn't read. The contract now blocks legitimate additive changes.
- Using contracts as documentation for humans. They're a test
  artifact; readability is secondary. Keep separate docs.
- Skipping `can-i-deploy` because "we'll fix it forward." That's how
  you discover backward-compat breaks in prod.
- Sharing one Pact between consumer test runs and provider verification
  without versioning. Now every consumer change invalidates every
  provider deploy.
- Not setting up provider states. Tests become flaky on data
  preconditions.
- Treating the broker as optional. The contract lives in the broker
  with versions; without it you just have files.
