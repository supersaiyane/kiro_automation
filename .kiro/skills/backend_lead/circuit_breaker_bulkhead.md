---
id: circuit_breaker_bulkhead
version: 1.0.0
owners: [backend_lead, sre]
tags: [resilience, circuit-breaker, bulkhead, hystrix, fail-fast, blast-radius]
when_to_use: |
  Any service that calls a downstream that can be slow or fail.
  Without circuit breakers + bulkheads, one slow dependency turns
  into a cascading thread-pool exhaustion and you take down the
  whole service. Apply BEFORE the first incident, not after.
inputs:
  - dependency_graph, failure_modes_per_dep
outputs:
  - "resilience_policy: breaker thresholds + bulkhead pool sizes + fallback strategy"
---

# Circuit Breaker + Bulkhead Patterns

> A slow dependency is worse than a failed dependency. Failure is
> immediate and locally observable; slowness is invisible until it
> has filled every thread in your service.

## The cascade failure that breakers prevent

1. Service A calls service B.
2. B starts taking 30s per request (DB hot lock, GC pause, anything).
3. A's worker threads hold open connections waiting for B.
4. A's thread pool fills.
5. A starts 503ing requests it could have served WITHOUT B.
6. A's callers cascade upstream.

Total outage triggered by one slow dependency — the **resonance
failure**. Breakers + bulkheads break the chain at every hop.

## Circuit breaker — Nygard's three states

```
       failures > threshold
   ┌─────────────────────────┐
   ▼                         │
[CLOSED]                  [OPEN]
   │                         │
   │   success after probe   │  timeout elapsed
   └────► [HALF_OPEN] ◄──────┘
```

- **CLOSED**: calls pass through; failures and successes are
  counted in a rolling window.
- **OPEN**: calls fail fast (no downstream call attempted). Returns
  the fallback (cached value, default, exception, queued action).
- **HALF_OPEN**: after a cool-down, allow a probe request. Success
  → close. Failure → re-open.

### Tuning

- **Failure threshold**: e.g., > 50% of last 20 requests, or
  > 10 consecutive failures.
- **Trip window**: rolling 10-30 seconds. Long enough to be
  meaningful, short enough to react.
- **Cool-down (open → half-open)**: 10-30 seconds typical. Probe
  too soon → flap; too late → unnecessary downtime.
- **What counts as a failure**: 5xx, timeout, connection refused.
  4xx is the client's fault, doesn't count.

Modern implementations: resilience4j (JVM), Polly (.NET),
`circuitbreaker` (Go), `tenacity` (Python — limited).

## Bulkhead — isolate the resources

Even with a breaker, ONE downstream that's misbehaving can saturate
one resource pool. Bulkheads partition:

```
[App] uses one DB connection pool
         ↓
   ┌─────┴─────┐
   │           │
[Path A]   [Path B]   ← share the pool → A's slow query starves B
```

vs.

```
[App] uses TWO pools (bulkheaded)
         ↓
   ┌─────┴─────┐
   │           │
[Path A]   [Path B]
   ↓           ↓
[pool_a]   [pool_b]   ← A can saturate pool_a, B unaffected
```

Patterns:
- **Per-downstream connection pool**: separate HTTP clients (with
  their own connection pools) per downstream. One slow service can
  exhaust its own pool but not the others.
- **Per-tenant concurrency limits**: at most N in-flight calls per
  tenant. One greedy tenant can't drain shared workers.
- **Thread pool isolation**: hystrix-style — one bounded thread
  pool per downstream. Modern equivalent: per-task `Semaphore`.
- **Queue isolation**: separate Kafka consumer groups / SQS queues
  per workload class so a backlog in one doesn't block the other.

## The combo

Always **bulkhead** the resource AND **break** the call. They solve
different failures:
- Bulkhead = limit blast radius when one path is slow.
- Breaker = stop SENDING traffic to a known-broken downstream.

## Fallback strategies (ordered by quality)

When the breaker is open, what do you return?

1. **Cached last-known-good** (best — degraded data > no data).
2. **Default value** ("recommendations service down → return top-N popular").
3. **Empty + soft error** ("we can't show this section right now").
4. **Queue the action for later** (write-side: 202 Accepted, retry async).
5. **Propagate the error** (worst, but sometimes the only correct choice
   — payments, auth).

The choice depends on the call's role in the user flow. NEVER
pick #5 without thinking; it's the default for almost everyone
and almost always wrong.

## Timeouts — the unsung control

A circuit breaker triggered by timeouts requires you to HAVE
timeouts. Most outages start because:

- Default HTTP client timeout is "no timeout."
- Default DB driver timeout is "no timeout."

Set explicit timeouts at every hop, and they MUST shrink as you
go down the stack:

```
[User-facing API: 5s total budget]
       ↓ propagates a deadline header
[Service A: 4.5s remaining → call B with 4s timeout]
       ↓
[Service B: 3.5s remaining → call DB with 3s]
```

This is "deadline propagation." gRPC supports it natively; for
REST, pass a `X-Deadline` header and respect it.

## Anti-patterns

- **Breaker on every internal method call.** Breakers are for
  cross-process / network calls. In-process: just throw.
- **Breaker WITHOUT a fallback.** You just turned a slow failure
  into a fast failure. That's marginal value.
- **Single bulkhead, multiple downstreams.** Defeats the point.
  One pool per downstream.
- **Retries inside the breaker.** Retries during an OPEN breaker
  are pure load amplification. Retry policy goes around the breaker,
  not inside.
- **Infinite retries with no exponential backoff + jitter.** Two
  callers hitting the same broken downstream synchronize at the
  retry interval → thundering herd.
- **Breaker thresholds copied from a blog post.** Tune to YOUR
  traffic. Run a chaos experiment to validate.
- **The fallback path is untested.** You'll exercise it during the
  first real outage and discover it has its own bug.

## Observability for breakers

- **State transitions** — log every CLOSED↔OPEN flip with the
  triggering metric. Page on "open for > 5 min."
- **Error rate before / after the breaker.** If you don't see a
  drop after breaker opens, you have another path leaking.
- **Fallback rate.** Sustained high fallback rate = degraded service;
  decide whether to alarm or accept.

## Reference numbers (start here, then tune)

| Dependency type | Threshold | Cool-down | Timeout |
|---|---|---|---|
| Read-only internal service | 50% over 20 reqs | 15s | 1s |
| Write internal service | 30% over 20 reqs | 30s | 2-3s |
| External 3rd party API | 60% over 20 reqs | 60s | 5s |
| Database | 25% over 50 reqs | 30s | query-dependent |
| Cache | 10% over 100 reqs | 5s | 100ms |

## Validation that the pattern is real

- [ ] Inject 500s on downstream B for 30 seconds. Service A
      should: open the breaker, serve fallbacks, recover when B
      heals, all without spiking error rate on its OWN endpoints
      that don't depend on B.
- [ ] Inject 20s latency on downstream B. Service A's NON-B paths
      should remain p99 < 1s (bulkhead isolation works).
- [ ] No HTTP client in the codebase has "no timeout."
- [ ] Every breaker has a documented fallback. Code review rejects
      breakers without one.
- [ ] Breaker state is visible in dashboards; alerts fire on
      sustained OPEN.
