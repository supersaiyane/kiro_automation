---
id: integration_contract_spec
version: 1.0.0
owners: [backend_lead]
tags: [integration, third-party, api-contract, failure-modes, idempotency]
when_to_use: |
  Before building any feature that calls a third-party service (payments,
  auth provider, LLM API, email, storage). One contract per external
  dependency, owned here — NOT in the frontend/design spec.
inputs:
  - service_name: the third-party being integrated
outputs:
  - contract: purpose, auth, endpoints, request/response, failure behavior
---

# Integration Contract Spec

Integration contracts are architecture, not styling — they live with the
data model, never next to the color palette. One per service.

```
## Integration: <Service> (e.g., Stripe)
- Purpose:        what it does in our app, in one line.
- Auth:           how we authenticate; where the secret lives (not here).
- Endpoints used: only the ones we call.
- Request:        shape we send.
- Response:       shape we expect on success.
- Failure:        timeout / 4xx / 5xx — exact app behavior for each.
- Idempotency:    key strategy for retries (see idempotency_patterns).
- Rate limits:    provider limits + our backoff.
- Cost note:      unit cost + where the bill spikes at scale.
```

**Why pre-build**: writing the failure and idempotency rows *before* coding
stops the agent from inventing a different (and usually missing) error path
each session.

**Anti-patterns**
- Integration logic re-guessed every session because no contract exists.
- Secret values pasted into the contract — reference the secret, never inline it.
- Happy-path only — no defined behavior when the dependency is down.
- Contract filed under the frontend spec, divorced from the data it touches.
