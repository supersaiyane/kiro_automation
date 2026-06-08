---
id: caching_strategies
version: 1.0.0
owners: [backend_lead, senior_engineer_be]
tags: [cache, redis, memcached, invalidation, stampede, layered]
when_to_use: |
  Read-heavy endpoints where the source of truth is too slow or too
  expensive to hit on every request. Cache makes everything faster
  — until it doesn't. Choose the pattern before writing code.
inputs:
  - hot_endpoint: RPS, payload size, freshness tolerance
outputs:
  - cache_design: tier, TTL, invalidation strategy, stampede protection
---

# Caching Strategies

> "There are only two hard things in Computer Science: cache
> invalidation and naming things." — Phil Karlton

## The cache hierarchy

| Tier | Latency | Capacity | Use for |
|---|---|---|---|
| L1: In-process (LRU dict, `lru_cache`) | < 1 μs | MB | Per-request memoization; small reference data |
| L2: Sidecar (in-pod cache, Caffeine) | ~10 μs | 100s MB | Hot path between in-proc and the network |
| L3: Distributed (Redis, Memcached) | ~0.5 ms | GBs | Shared across instances |
| L4: CDN (Cloudflare, Fastly) | edge → 0 ms | unlimited | Static assets + cacheable HTTP responses |

Most services need L3 + L4. Reach for L1 only when measurement
justifies it (function called 10k+ times per request).

## The four canonical patterns

### Cache-Aside (lazy load) — the default
```
on read:
    v = cache.get(key)
    if v is None:
        v = db.get(key)
        cache.set(key, v, ttl=T)
    return v

on write:
    db.put(key, new_v)
    cache.delete(key)        # or cache.set(key, new_v, ttl=T)
```
- Pros: simple; only what's read is cached.
- Cons: thundering-herd on misses; race between writer's delete and
  concurrent reader's set (stale data wins).

### Write-Through
```
on write: db.put(key, v); cache.set(key, v)
on read:  cache.get(key)  # populated by writer
```
- Pros: no staleness if the writer succeeds.
- Cons: write latency = cache + DB; the cache mirrors the DB and pays
  for cold data nobody reads.

### Write-Behind (write-back)
Cache absorbs writes; flushes to DB asynchronously.
- Pros: very fast writes.
- Cons: durability hazard — cache crash loses unflushed writes. Use
  only for non-critical data (counters, view stats).

### Refresh-Ahead
Cache refreshes hot keys *before* expiry, in the background.
- Pros: avoids stampede; users never wait on the slow path.
- Cons: complex; refreshing dead-cold keys wastes effort. Best for a
  small hot set with predictable demand.

## Invalidation — the actual hard part

Three strategies, pick one explicitly:

1. **TTL only.** Simple. Maximum staleness = TTL. Acceptable for
   public catalogs, counters, summaries.
2. **TTL + explicit invalidation on write.** Writer deletes/updates
   the affected key(s). Watch the race: reader-after-writer
   re-populates with stale DB read in a replica-lag world.
3. **Versioned keys.** Cache key = `user:42:profile:v17`. Writer
   bumps the version. Old keys age out via TTL. No race; cost is the
   version-tracking machinery.

### The replica-lag trap
After write: writer deletes cache → reader misses → reader queries DB
**replica that hasn't replicated yet** → reader re-populates with
stale value. The cache now serves stale until next write.

Fix: route post-write reads to primary (sticky session) for a brief
window. Or: write-through. Or: versioned keys.

## Stampede / dog-pile protection

When a hot key expires, N concurrent readers all miss and hit the DB.
Solutions:

- **Probabilistic early expiration** — refresh slightly before TTL
  for a random share of requests.
- **Singleflight / request coalescing** — N misses for the same key
  collapse to 1 DB call (the others wait on the result).
- **Stale-while-revalidate** — serve stale data for a small window
  while one process re-populates.

Don't skip this — at scale, one expired hot key brings the DB down.

## Sizing & eviction

- **Memory budget** = (avg value size + key size) × hot working set.
- Eviction policy: **LRU** for general; **LFU** for power-law hot sets;
  **TinyLFU** (Caffeine) is the modern best general-purpose policy.
- Monitor **hit rate**, **eviction rate**, **p99 latency of misses**.
  Hit-rate target: ≥ 85% for the pattern to be worth the operational
  burden.

## What NOT to cache

- Authenticated user-specific responses (without per-user keys).
- Anything that's faster from the DB index than the cache round-trip.
- Data with strict consistency requirements (account balance).
- Anything you can't generate a deterministic key for.

## Anti-patterns

- "Cache everything." Negative-hit caches that thrash and never warm.
- TTL of "until we manually clear it." That's not a TTL; that's a bug
  generator.
- Caching authenticated responses under a non-tenant-scoped key.
  Catastrophic data leak.
- "Cache invalidation is hard, so we'll do TTL=24h." If 24h-stale data
  is OK, you don't need a cache — your DB can handle it.
- Storing pickled Python objects (or equivalent) in Redis. Versioning
  becomes impossible across deploys.
- Single Redis as a Single Point of Failure. Use Cluster / Sentinel
  / managed service with replication.
- Treating Redis as a primary store. It's a cache. Persistence flags
  exist but aren't a substitute for a real database.
