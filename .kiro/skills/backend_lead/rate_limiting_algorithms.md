---
id: rate_limiting_algorithms
version: 1.0.0
owners: [backend_lead, sre]
tags: [rate-limiting, token-bucket, leaky-bucket, fairness, ddos, multi-tenancy]
when_to_use: |
  Any public API, multi-tenant service, or downstream-dependent
  workflow. Pick BEFORE traffic asymmetry hurts you — one customer
  shouldn't be able to consume all your quota with a runaway loop.
inputs:
  - traffic_profile, fairness_requirements, sla_per_tier
outputs:
  - "rate_limit_design: algorithm + storage + tier policy + client UX"
---

# Rate Limiting Algorithms — pick the right one

> Rate limiting is not "1000 requests per minute." It's the contract
> between your service and every caller about how to behave when
> resources are scarce.

## The four canonical algorithms

| Algorithm | Burst behavior | Smoothness | Memory per key | When to use |
|---|---|---|---|---|
| Fixed window | Sharp boundary burst (2x at edges) | Low | 1 int | Counting only; not for production limits |
| Sliding window log | Exact | Perfect | O(N requests) | Low-volume / billing limits |
| Sliding window counter | Approximate (interp.) | Good | 2 ints | General-purpose web API |
| Token bucket | Configurable burst | Good | 2 floats | Best general default |
| Leaky bucket (queue) | No burst (smooths) | Perfect | 1 int + queue | Upstream-protection, smoothing |

### Token bucket (recommended default)

```
state per key: (tokens: float, last_refill: timestamp)
on request:
  now = current_time()
  elapsed = now - last_refill
  tokens = min(capacity, tokens + elapsed * refill_rate)
  last_refill = now
  if tokens >= 1:
    tokens -= 1
    ALLOW
  else:
    DENY
```

- `capacity` = max burst size (e.g., 100).
- `refill_rate` = sustained rate (e.g., 10/s).
- Allows brief bursts up to `capacity`, then settles at `refill_rate`.

Real APIs (Stripe, GitHub, AWS) all use some variant of this.

### Sliding window counter (close second)

```
window = 60s
count_curr = redis INCR rate:user:42:1738015800   # this minute
count_prev = redis GET  rate:user:42:1738015740   # last minute
weight = (60 - seconds_into_curr_window) / 60
approx = count_curr + count_prev * weight
if approx > limit: DENY
```

- Approximates a true sliding window with O(1) memory.
- Avoids the "2x burst at window boundary" of fixed window.

## Distributed: where do you count?

**Local** (per-instance):
- Each app instance maintains its own bucket.
- Simple, fast, no network call.
- Inaccurate by exactly the cluster size (N instances → up to Nx limit).
- Fine for coarse "DDoS shield" use; bad for "10 req/min billing quota."

**Centralized via Redis**:
- Single source of truth. Use Lua scripts for atomic INCR+TTL or
  use a token-bucket library (e.g., `redis-cell`).
- Sub-ms p99 if Redis is co-located; round trip per request.
- Failure mode: Redis down → fail-open (let traffic through) or
  fail-closed (deny everything). **Document and test the choice.**

**Hierarchical**:
- Coarse cluster-wide check in Redis + fine per-instance for speed.
- Most large APIs do this.

## Fairness in multi-tenant systems

Per-key (e.g., per API key) limiting is not enough. A single
customer can starve all others if they hit cluster CPU/IO limits:

- **Weighted fair queueing**: give each tenant a share of capacity
  proportional to their tier weight.
- **Concurrency limits per tenant** (in addition to rate) — caps the
  blast radius of a slow query.
- **Per-tenant cost accounting**: not every request costs the same
  (a search costs 100x a key lookup). Charge buckets by computed
  cost, not by request count.

## The client UX of rate limiting

A 429 with no info is hostile. Standardize headers (IETF
`draft-ietf-httpapi-ratelimit-headers`):

```
HTTP/1.1 429 Too Many Requests
RateLimit-Limit: 100
RateLimit-Remaining: 0
RateLimit-Reset: 17
Retry-After: 17
```

- `RateLimit-Limit`: the quota.
- `RateLimit-Remaining`: how many calls you have left in the window.
- `RateLimit-Reset`: seconds until the quota resets.
- `Retry-After`: how long the client should wait before retrying.

Provide a **headroom signal** even on successful responses (200s),
so well-behaved clients can self-throttle BEFORE hitting 429.

## What to limit

In order of impact:
1. **Authentication endpoints** — brute-force protection. Limit by
   IP + by username separately. Lock-out is stronger than rate-limit
   for `/login`.
2. **Write endpoints** — limit per (tenant, endpoint).
3. **Expensive reads** — search, exports, reports. Often a
   concurrency limit beats a rate limit ("max 3 exports in flight per tenant").
4. **Webhook outbound** — when YOU call customer URLs, rate-limit
   yourself per-customer to be a good citizen.

## Anti-patterns

- **One global rate limit** ("10k req/s total"). Single customer
  fills it; the rest of the world gets 429s. Always per-key.
- **Fixed-window-only.** The burst at window boundaries is a
  well-known DoS vector. Sliding window or token bucket.
- **Local-only in a cluster of 50.** Real limit = 50 × configured.
- **Fail-closed without testing.** Redis hiccups should not 100%
  outage the API. Make fail-open explicit and TIME-BOX it (after
  N seconds of Redis down, page someone).
- **No headers**. Clients can't implement backoff intelligently.
- **Same limit for free and enterprise tiers.** Tier-based limits
  are a product feature, not just a knob.
- **Retry-After: 0.** Hostile. Always honest, conservative number.
- **Counting after rate limit, in app code.** Rate limit should be
  cheap and BEFORE expensive auth/business logic. CDN edge or
  ingress layer is best.

## Redis Lua script — atomic token bucket

```lua
-- KEYS[1]: bucket key
-- ARGV: capacity, refill_rate, requested_tokens, now_ms
local key, cap, rate, want, now = KEYS[1],
  tonumber(ARGV[1]), tonumber(ARGV[2]),
  tonumber(ARGV[3]), tonumber(ARGV[4])

local data = redis.call("HMGET", key, "tokens", "last")
local tokens = tonumber(data[1]) or cap
local last   = tonumber(data[2]) or now
local elapsed = math.max(0, now - last) / 1000.0
tokens = math.min(cap, tokens + elapsed * rate)

local allowed = 0
if tokens >= want then
  tokens = tokens - want
  allowed = 1
end

redis.call("HMSET", key, "tokens", tokens, "last", now)
redis.call("EXPIRE", key, math.ceil(cap / rate) * 2)
return {allowed, tokens}
```

One round trip; atomic; no race conditions across replicas.

## Validation that rate limiting works

- [ ] A single customer running an infinite loop CANNOT degrade
      response time for other customers (verify with a load test).
- [ ] 429 responses include all three RateLimit-* headers.
- [ ] Redis flap (30 seconds) does NOT cause 100% 5xx — fail-open
      is in effect with a logged warning.
- [ ] Per-tenant burn-rate is observable in your dashboards.
- [ ] An attacker spraying /login from 1 IP locks the account
      faster than 100 IPs all probing 1 account (per-IP + per-user
      limits are both in effect).
