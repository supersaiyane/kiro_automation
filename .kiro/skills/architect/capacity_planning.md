---
id: capacity_planning
version: 1.0.0
owners: [architect, sre_engineer]
tags: [capacity, scaling, headroom, cost, sizing]
when_to_use: |
  Designing a new service, before any traffic-doubling event (launch,
  marketing campaign, regulatory deadline), or quarterly for any
  service whose load is growing >20% YoY.
inputs:
  - current_load: RPS, query rate, payload size, fan-out factor
  - growth_assumptions: explicit, with sources
outputs:
  - capacity_plan: instance type × count, headroom %, cost, breakpoints
---

# Capacity Planning From First Principles

The numbers everyone in the room should know:

| Operation | Order of magnitude |
|---|---|
| L1 cache read | ~0.5 ns |
| L2 cache read | ~7 ns |
| Main memory read | ~100 ns |
| SSD random read | ~16 μs (16,000 ns) |
| Network within DC | ~0.5 ms |
| Network cross-region | 50-150 ms |
| Disk seek (HDD) | 10 ms |
| TCP packet ack | ~250 μs round-trip in DC |

This is the "latency numbers every programmer should know" cheat sheet.
You should be able to estimate any architecture's lower-bound latency
from it without measuring.

## The Little's Law backbone

> **L = λ × W**
> Average number in system = arrival rate × average time in system.

Concretely: if your service handles 1000 RPS at p50 latency 100ms, you
have **100 in-flight requests on average**. You need at least that
many concurrent execution slots (threads, goroutines, async tasks).
For p99, multiply by the p99/p50 ratio and add headroom.

## The four-step plan

### 1. Measure the baseline
- RPS per endpoint at p50/p95/p99.
- Payload size (bytes in/out).
- Database queries per request.
- Cache hit rate.
- Fan-out factor per request (1 incoming = N downstream calls).

### 2. Project the growth
- Organic: extrapolate the last 12 months. Be honest about the curve
  (linear vs. exponential decays differently).
- Inorganic: list the launch / campaign / regulatory event. Each one
  has a multiplier and a window.
- Worst case: 99th percentile day, not average day. Black Friday for
  e-commerce. Tax deadline for tax software. Be specific.

### 3. Convert to resources
- **Threads/connections** = peak RPS × p95 latency (Little's Law)
- **CPU** = sum of per-request CPU time × peak RPS
- **Memory** = base + (per-request memory × concurrent requests)
- **DB connections** = max(peak RPS × queries/req × query latency, pool_floor)
- **Disk IOPS** = writes/req × peak RPS × replication factor
- **Network egress** = avg response size × peak RPS × geographic fan-out

### 4. Add headroom
- **3× peak** for CPU/memory if scaling is slow (>5 min)
- **2× peak** if scaling is fast (<1 min)
- **1.5× peak** for DB connections (pool exhaustion = downtime)
- **5× peak** for queue depth (backpressure absorption)

Headroom is **non-negotiable**. The day you exceed it, your scaling
plan kicks in — not your incident response.

## Breakpoints

Identify the *next* bottleneck at each scale. Examples:

| Scale | First thing that breaks |
|---|---|
| 1 RPS | nothing |
| 100 RPS | thread/connection pool exhaustion |
| 1,000 RPS | DB connections, single-process GIL/event-loop |
| 10,000 RPS | single-DB writes, single-cache cluster, NIC saturation |
| 100,000 RPS | cross-AZ network, single-region DNS, garbage collection pauses |
| 1,000,000 RPS | cross-region routing, single CDN provider, bot defense |

For your current scale, name the next two breakpoints. If you can't,
you're not ready to plan capacity — you're guessing.

## Cost model

Capacity is a cost decision. Run two numbers:

- **Current annualized cost** at today's instance × count.
- **Projected annualized cost** at the planning horizon, with headroom.

If the projection is >2× current spend, you have an architecture
problem, not a capacity problem. The next breakpoint is the redesign.

## Anti-patterns

- "We'll just auto-scale" — auto-scaling has a warmup time. Spikes
  faster than the warmup get dropped.
- Sizing from the average, not the p99 day.
- Forgetting fan-out. Service A is 1k RPS; if it calls service B three
  times, B is 3k RPS. Plan B's capacity for that.
- Ignoring the DB. App tier scales horizontally cheaply; DB doesn't.
  The DB is your first breakpoint 90% of the time.
- Plans expressed only as "more instances". Bigger instances + same
  count is often cheaper per unit of capacity, but more blast-radius.
- No re-measurement. Capacity plans go stale in one quarter; re-baseline.
