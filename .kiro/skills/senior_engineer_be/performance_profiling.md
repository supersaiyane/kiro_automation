---
id: performance_profiling
version: 1.0.0
owners: [senior_engineer, sre]
tags: [performance, profiling, flamegraph, p99, latency, throughput]
when_to_use: |
  Performance has regressed or is below SLO. Apply BEFORE
  optimizing — most performance work is wasted because it targets
  the wrong code. Measurement, then change, then measurement, in
  that order.
inputs:
  - slo_targets, current_metrics, suspected_bottleneck
outputs:
  - "perf_findings: profile evidence + optimization plan + before/after numbers"
---

# Performance Profiling — Knuth in 2026

> "Premature optimization is the root of all evil" — Knuth, 1974.
> The full quote: "We should forget about small efficiencies, say
> about 97% of the time. Yet we should not pass up our opportunities
> in that critical 3%." The skill is identifying the 3%.

## The discipline (in order)

1. **Define the SLO**. "Faster" is not a goal. "p99 under 200ms for
   /search" is.
2. **Measure first**. Real, production-grade workload. NEVER trust
   a microbenchmark in a quiet environment.
3. **Profile**. Find where time/memory/IO is actually spent.
4. **Hypothesize ONE change.**
5. **Apply the change in isolation.**
6. **Measure again.** Compare to step 2.
7. **Repeat or stop.** Stop when SLO is met. NOT when "looks faster."

The most common failure: skip 1-3 and go straight to "I bet it's
the JSON parser." It rarely is.

## The four classical bottlenecks

| Bottleneck | Tell-tale | Profile |
|---|---|---|
| CPU | High CPU%, single core saturated, low IO wait | CPU profiler / flamegraph |
| Memory (allocation rate) | Frequent GC, high allocation rate, p99 sawtooth | Heap profiler / GC log |
| I/O (disk/net) | Low CPU, high IO wait, p99 long tails | iostat, tcpdump, async wait time |
| Lock contention | Threads waiting, throughput plateaus regardless of CPU | Thread dump / off-CPU profile |

Don't guess which one — profile.

## Tools by language

| Lang | CPU | Heap | Off-CPU |
|---|---|---|---|
| Python | py-spy, scalene, austin | tracemalloc, memray | py-spy --idle |
| Java/JVM | async-profiler, JFR | Java Flight Recorder, MAT | async-profiler --off-cpu |
| Go | pprof | pprof heap | pprof block, mutex |
| Node | Clinic.js, 0x, --prof | heapdump + Chrome DevTools | Clinic.js bubbleprof |
| Rust | flamegraph, cargo-flamegraph | dhat, heaptrack | perf record off-cpu |
| Anywhere | perf, eBPF (bcc, bpftrace) | valgrind/massif | perf sched |

**Flamegraphs** (Brendan Gregg) are the universal output format.
Wide bar = lots of time spent. Stack height = call depth. Look at
the WIDE bars near the top — that's where to optimize.

## Production-grade profiling

NEVER infer prod performance from a dev laptop. Profile in
production-similar (ideally production) conditions:

- **Continuous profiling** in prod: Pyroscope, Datadog Continuous
  Profiler, Parca. Low overhead (< 2%), always-on. The diff between
  yesterday and today's flamegraph IS the bug report when something
  slows down.
- **Targeted ad-hoc**: `py-spy dump` on a running pod for 30
  seconds. Not invasive.
- **Load test**: k6 or Vegeta against a staging env that mirrors
  prod data shapes. Synthetic load that hits realistic cache hit
  ratios.

## The latency vs throughput distinction

- **Throughput** ↑ usually means more CPU, more memory, more
  parallelism. "How fast can I serve all my users?"
- **Latency** ↓ usually means less work per request: better
  algorithms, less I/O, smaller payloads. "How fast for this one user?"

You can be high-throughput and high-latency (batched systems). You
can be low-throughput and low-latency (single user, hot cache).
The optimization moves are NOT the same. State which you're tuning.

## p50 vs p99 vs p99.9

A median that drops 5% while p99 doubles is a regression. Latency
distributions are NOT normal — they are long-tailed. Always look at:

- p50 — does the typical user feel different?
- p99 — does the unlucky user feel different? (1 in 100)
- p99.9 — power user (one tenant doing N calls in a row will hit
  this 0.1% almost every session)

**Always graph the distribution as a heatmap or histogram** —
averages mask bimodality.

## The Universal Scalability Law (Gunther)

```
C(N) = N / (1 + α(N-1) + βN(N-1))
```

- N = workers / concurrency.
- α = serial fraction (Amdahl). Caps speedup.
- β = coherency cost (cache invalidation, cross-thread sync). Makes
  speedup go BACKWARDS past a point.

Practically: most systems peak somewhere between 8 and 64 workers
per process. Above that, contention costs > parallelism gains.
Measure the curve, find your peak, don't run beyond it.

## Common optimization moves (in order of payoff)

1. **Algorithm.** O(n²) → O(n log n) beats every micro-optimization.
2. **I/O removal.** A `WHERE` filter pushed to the DB beats reading
   all rows and filtering in app.
3. **Cache.** With careful invalidation. Without invalidation you
   ship a bug.
4. **Batch.** Round trips dominate; one query for 100 rows beats
   100 queries for 1 row.
5. **Concurrency.** Where work is I/O-bound, parallelize.
6. **Allocation reduction.** Reuse buffers, prefer slices over
   copies, avoid boxing.
7. **Inlining / micro.** Hand-tuning a hot loop. Last resort.

## N+1 — the most common database bug

```
posts = Post.all
for p in posts:
    print(p.author.name)   # 1 query per post → N+1 total
```

vs.

```
posts = Post.includes(:author).all   # 2 queries total
```

Detection: turn on slow query log; look for the same query shape
fired N times in a row. ORMs hide this.

## Anti-patterns

- **Optimizing without measuring.** Half the time you make it slower.
- **One-shot profile.** Single-run profiles include startup noise.
  Profile for 30+ seconds under steady-state load.
- **Microbenchmarks that don't match prod.** Hot CPU caches, warm
  JIT, no allocation pressure — none of that matches prod.
- **Eliminating allocations in cold paths.** Time spent here is
  invisible. Profile-driven optimization only.
- **Adding a cache to a correctness bug.** Cached wrong is wrong faster.
- **Concurrency for CPU-bound work in a GIL'd language.** Use
  multiprocessing or a different language; threading won't help.
- **"Just rewrite it in Rust."** The 10x speedup is real only if
  the bottleneck was language overhead. Most of the time it's I/O
  or algorithm and Rust won't help.

## Reporting performance work

The PR description must contain:
- The SLO and current vs target.
- The profile evidence (flamegraph link).
- The hypothesis.
- The change.
- The new measurement (same workload).
- A graph: before vs after, p50 and p99.

"It's faster on my machine" is not evidence.

## Validation that perf work is real

- [ ] You have a flamegraph or equivalent profile BEFORE the change.
- [ ] You have one AFTER.
- [ ] The improvement is visible in the production metrics dashboard
      24 hours after deploy.
- [ ] You did NOT change observable behavior (no functional
      regression).
- [ ] You wrote down what you ruled OUT during the investigation
      so the next perf engineer doesn't repeat it.
