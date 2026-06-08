---
id: load_testing_methodology
version: 1.0.0
owners: [qa_engineer, sre, backend_lead]
tags: [load-testing, k6, vegeta, locust, performance, p99, scenarios]
when_to_use: |
  Before launching anything customer-facing at scale, before
  marketing-driven traffic spikes, after major architecture changes,
  on a periodic regression cadence. Load testing finds bugs that
  unit + integration tests will never find — concurrency races,
  thread-pool exhaustion, cache stampedes.
inputs:
  - slo_targets, expected_traffic_shape, prod_data_volumes
outputs:
  - "load_test_plan: scenarios + ramp + pass/fail criteria + artifacts"
---

# Load Testing Methodology

> A load test that "passes" with no failure criteria is a metaphor.
> A real load test answers "what's the highest load at which we
> meet SLO?" and "what breaks first when we exceed it?"

## Five load test types — different questions, different shapes

| Type | Question | Shape | Duration |
|---|---|---|---|
| Smoke | Does the path work at all? | Low constant load | 5 min |
| Average | Holds under typical traffic? | Constant at p50 | 30 min |
| Stress | When does it break? | Ramp until failure | 1-2 hrs |
| Spike | Survives a sudden surge? | Step from low to 5x in seconds | 30 min |
| Soak | Are there leaks over time? | Constant at p75 for hours | 8-24 hrs |

You need at least Smoke + Average + Soak before a public launch.
Stress is essential for capacity planning.

## Tools (pick one and learn it well)

| Tool | Strength |
|---|---|
| k6 (Grafana) | TypeScript scripting, cloud + open-source, modern. Default recommendation. |
| Vegeta | Simple constant-rate HTTP, Go binary. Best for quick smoke + soak. |
| Locust | Python scripting, distributed via swarm. Good for complex user flows. |
| Gatling | Scala, beautiful reports, JVM-heavy. Strong for enterprise. |
| JMeter | GUI-driven, dated, but still in many enterprises. Avoid for new work. |
| wrk2 (Tene) | Captures coordinated omission accurately. For low-level latency rigor. |

## The Coordinated Omission trap

Most "load tests" lie about p99 by 100x. The bug:

```
loop forever:
    start_request()
    wait_for_response()
    record_latency()
```

If the server stalls for 1 second, the client makes ONE slow
request, not 1000 stalled ones — because the client is also
stalled. The recorded latency distribution misses 999 of the
1000 affected requests.

**Fix**: use an open-loop generator that sends requests at a fixed
RATE regardless of server response. k6 (with `arrival rate`
scenarios), Vegeta, wrk2 do this correctly. Closed-loop tools
(default Locust, JMeter "users") do not.

Always verify your tool generates open-loop traffic when you care
about tail latency.

## Realistic traffic shape

Production traffic is NOT uniform random. Match the shape:

- **Diurnal**: peak / trough ratio is usually 5-10x. Run at peak.
- **Endpoint mix**: real-world weight — 70% read, 25% write, 5%
  expensive query. Not 100% of one path.
- **Payload size distribution**: production has a long tail of
  large requests. Sample real payloads (anonymized) for the test.
- **Cache hit ratio**: a 99% cache hit ratio in prod with COLD
  caches in the load test means your test hits the DB 100x more.
  Warm caches before measuring.
- **Think time**: real users pause between actions. Synthetic
  "fire continuously" generates unrealistic load patterns; add
  jittered sleeps.

A 100k-RPS test with the wrong shape tells you nothing useful.

## Pass / fail criteria (declared BEFORE the run)

A load test report without pass/fail is decoration. Sample:

```
At 5,000 RPS sustained for 30 minutes:
  - p50 latency < 100ms
  - p99 latency < 500ms
  - error rate < 0.1%
  - no host CPU > 80%
  - no host memory > 80%
  - DB connection pool wait < 100ms p99
```

If ANY of these fail at the target RPS, the test fails. Don't move
the goalposts to make the dashboard green.

## Environment — production or it didn't happen

Load test environments have well-known biases:

- Smaller node sizes → ratio-incorrect for thread/connection bottlenecks.
- Smaller data → cache hit rate is artificially high.
- No multi-tenant noise → real prod has ambient load.
- Different network topology → cross-AZ latency missing.

For meaningful results: load test in PROD (off-hours, traffic shadowed
to a canary) OR in an environment that is a 1:1 clone, including data
volumes. Half-measures produce misleading numbers.

## Observability during the test

A pass/fail number is useless if you can't see WHY. Required:

- Every metric the SRE team uses for prod (latency, error rate,
  saturation, throughput per endpoint).
- DB metrics (connections, slow queries, lock waits).
- Downstream service metrics.
- The application's USE method dashboard (Utilization, Saturation,
  Errors per resource — Brendan Gregg).
- Flame graph captured from the bottleneck process.

Tag every metric with `load_test=YES` so it doesn't poison your
production alerting.

## A k6 example you can adapt

```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    average_load: {
      executor: 'constant-arrival-rate',     // open-loop, no coord. omission
      rate: 1000, timeUnit: '1s',
      duration: '30m',
      preAllocatedVUs: 200, maxVUs: 1000,
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<300', 'p(99)<800'],
    http_req_failed:   ['rate<0.001'],
  },
};

export default function () {
  const r = http.get('https://api.example.com/search?q=widgets');
  check(r, { 'status 200': (x) => x.status === 200 });
}
```

The `thresholds` block is the pass/fail criteria. k6 exits non-zero
if any fail → wire to CI for periodic regression.

## Anti-patterns

- **One-shot load tests before launch only.** Performance drifts.
  Run weekly or monthly minimums.
- **No baseline.** "5k RPS p99 = 300ms" tells you nothing alone.
  Compare to last week.
- **Fire-and-forget closed-loop tools.** Coordinated omission lies.
- **All traffic to one endpoint.** Doesn't exercise the real
  contention surface.
- **Empty database.** Tests run faster than prod will ever be.
- **No teardown.** Leaving 10k test users in prod data is a data
  hygiene nightmare. Clean up after every run.
- **Skipping the soak test.** Connection leaks, file descriptor
  leaks, memory leaks only show after hours.
- **Generating load from one host in one AZ.** TCP slow-start,
  ephemeral port exhaustion at the load gen, single-AZ network limits.
  Distribute the generator.

## Interpreting tail latency

p50 going up: capacity problem. Whole system is overloaded.
p99 going up while p50 stable: queueing / contention bottleneck.
ONE slow downstream, slow GC, or lock contention. Not capacity.
p99.9 catastrophic, p99 fine: rare path. Background jobs, one
tenant, a specific request shape.

Profile the affected percentile, not the average.

## Validation that load testing is real

- [ ] Your tool generates open-loop traffic at a fixed RATE.
- [ ] Test environment data volume is within 2x of prod.
- [ ] Cache warm-up is part of the script.
- [ ] Pass/fail criteria are declared in the test definition.
- [ ] CI runs at least one scenario per merge on critical paths.
- [ ] You have a baseline number from last quarter for comparison.
- [ ] Last bug found by load testing has a regression test for it.
