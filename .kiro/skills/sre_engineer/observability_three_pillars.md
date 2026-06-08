---
id: observability_three_pillars
version: 1.0.0
owners: [sre, devops_engineer, backend_lead]
tags: [observability, opentelemetry, metrics, logs, traces, slo]
when_to_use: |
  Designing or auditing observability for a service. The three
  pillars (metrics, logs, traces) answer different questions; a
  system that has only one is observable in only one dimension.
  Modern stack standardizes on OpenTelemetry across all three.
inputs:
  - service_inventory, current_observability_stack, slo_targets
outputs:
  - "observability_design: metric/log/trace strategy + OTel wiring + signal hygiene"
---

# The Three Pillars of Observability (+ OpenTelemetry)

> Monitoring tells you WHAT broke. Observability tells you WHY.
> The difference is whether you can answer questions you didn't
> pre-define when you instrumented.

## What each pillar is for

| Pillar | Best at | Worst at | Cardinality |
|---|---|---|---|
| Metrics | Trends, alerting, SLOs | Single-request debugging | Low (aggregate) |
| Logs | Detailed context, what happened | Trending, alerting | Medium |
| Traces | Causality across services | Aggregate trends | High |

A service that has only metrics is observable for trends but blind
to "why did THIS user's request fail?" Only logs is blind to
"what's the p99 of this endpoint?" Only traces and you're missing
SLO alerting. You need all three.

## Metrics — RED + USE methods

**RED** (services / requests):
- **Rate** — requests per second.
- **Errors** — error rate (or count).
- **Duration** — latency distribution.

**USE** (resources):
- **Utilization** — % busy.
- **Saturation** — queue depth.
- **Errors** — counts.

Every service has RED metrics. Every resource (CPU, disk, pool)
has USE metrics. Together they cover most of what alerting needs.

```promql
# RED for an HTTP service
sum(rate(http_requests_total[1m])) by (route)              # R
sum(rate(http_requests_total{status=~"5.."}[1m])) by (route) # E
histogram_quantile(0.99, rate(http_duration_seconds[1m]))    # D
```

## Metric cardinality — the silent killer

A label with high cardinality (user_id, request_id) creates
combinatorially many time series. A few rules:

- **NEVER label by user_id or request_id.** That's what traces are for.
- **Limit to ~ 100 values** per label.
- **Bound enum labels**: HTTP status codes, route names, regions.
- **Aggregate first, label second.** "p99 latency per route" yes;
  "p99 latency per (route, user)" no.

The most common bug: an `error_type` label that includes the
error message verbatim. Each unique error string = a new time
series. Datadog / Prometheus bills explode.

## Logs — structured, leveled, sampled

Modern logs are JSON, not strings:

```json
{
  "timestamp": "2026-04-12T18:42:33.124Z",
  "level": "WARN",
  "service": "checkout",
  "request_id": "01HGZ4...",
  "trace_id": "abc123def456...",
  "user_id": "42",
  "msg": "card declined",
  "card_decline_reason": "insufficient_funds",
  "amount_cents": 1299
}
```

Rules:
- One event per line, JSON.
- Always include `service`, `trace_id`, `request_id`, `level`.
- NEVER log PII or secrets. Use a redactor.
- Log at DEBUG sparingly in prod; rate-limit at the source.

**Sampling**: a service doing 10k req/s with 1KB log lines burns
10 MB/s in storage. Sample non-error logs at 1-10%. Always log
ALL errors. Always log the FIRST request in a session at full
fidelity.

## Traces — causality across services

A trace = a tree of spans, one root span per user request.

```
[root: POST /checkout]                                          240ms
  ├─ [auth: verify]                                              22ms
  ├─ [catalog: get product]                                      14ms
  ├─ [inventory: reserve]                                        18ms
  ├─ [payment: charge]                                          175ms  ← SLOW
  │   ├─ [stripe: POST /charge]                                 168ms
  │   └─ [db: UPDATE payments]                                    5ms
  └─ [email: send confirmation]                                   8ms
```

Reading this: the entire checkout took 240ms; 175ms of that was
in `payment.charge`, almost entirely waiting on Stripe. NOT a
bug in our code. Without distributed tracing, you'd be guessing.

**Trace sampling**:
- 100% sampling at <100 req/s service: fine, store everything.
- At high rate, tail-sample: keep ALL error traces + ALL slow
  traces + 1-5% of fast traces. Tail-sampling is non-trivial; use
  the OTel collector's tail-sampler.

## OpenTelemetry — the standard since ~ 2022

OTel is the CNCF-graduated standard for collecting all three
pillars. The pieces:

- **SDKs** (per language) — generate spans, metrics, logs from app
  code.
- **Auto-instrumentation** — frameworks (HTTP servers, DB drivers,
  message brokers) emit OTel data without code changes.
- **OTel Collector** — receives data, transforms (sampling, redaction,
  enrichment), exports to your backend(s).
- **Backends** — Datadog, New Relic, Honeycomb, Tempo, Jaeger,
  Loki, Prometheus, anything that accepts OTLP.

Architecture:

```
[ App + OTel SDK ] ─OTLP─► [ OTel Collector ] ─► [ Tempo (traces) ]
                                              ─► [ Prometheus (metrics) ]
                                              ─► [ Loki (logs) ]
```

Lock-in cost: zero. Switch backends by changing the Collector
config; the app is unchanged. This is the killer feature.

## Context propagation — what ties it all together

`trace_id` is the joiner. The SAME trace_id must appear on:
- Every log line in the trace.
- Every metric exemplar (Prometheus supports `# exemplar` lines).
- The trace itself.

W3C TraceContext is the standard header (`traceparent`,
`tracestate`). OTel auto-instrumentation propagates it across
HTTP and gRPC calls.

If trace_ids aren't on your logs, your logs and traces are
disconnected — you can find a slow trace but can't find the
exception that caused it.

## SLOs and error budgets

An SLO converts metrics into a CONTRACT:

```
SLO: 99.5% of /checkout requests succeed in < 500ms over a rolling
     30-day window.

Error budget: 0.5% × 30 days = ~3.6 hours of "bad" requests.

Burn rate alerts:
  - 14.4x burn rate over 1h  → page (would exhaust 30d budget in 50h)
  - 6x burn rate over 6h     → page
  - 3x burn rate over 24h    → ticket
```

Burn rate (Google SRE Workbook chapter 5) is far better than
threshold alerts. A threshold alert at 99% means you're paged
for a 1-second blip OR for a 12-hour slow leak the same way.
Burn rate distinguishes urgency.

## Anti-patterns

- **Metric with unbounded cardinality.** Hours of debugging the
  bill spike.
- **Logs without trace_id.** Logs and traces live in separate
  silos; you can't pivot.
- **DEBUG logs at full volume in prod.** Pays for itself in
  storage cost.
- **Sampling without keeping errors.** Sampling 1% means error
  traces are also sampled at 1% — exactly the ones you needed.
  Always keep errors at 100%.
- **Three vendors, three SDKs.** Use OpenTelemetry once, switch
  backends later.
- **Alerting on every metric.** Page only on SLO-violating
  conditions; everything else is a ticket or a dashboard.
- **No service-level dashboard.** Each service needs ONE
  dashboard the on-call opens first: RED + USE + top 5 errors.

## Cost control (because observability bills are real)

In 2025-2026, observability spend often rivals compute. Tactics:

- **Metric cardinality budgets.** Bill chargeback per team based
  on their cardinality.
- **Log sampling at the SOURCE**, not the backend. The collector
  can do this.
- **Trace tail-sampling.** Keep what matters; drop the rest.
- **Tiered retention.** 7 days hot, 30 days warm, 90 days cold.
- **Periodic audit.** What's actually queried? Often 80% of
  metrics are never seen by a dashboard or alert. Drop them.

## Validation that observability works

- [ ] Given a customer complaint with a request ID, you can pull
      the full trace + logs + metrics for that request in < 5 min.
- [ ] SLO dashboards exist per service; burn-rate alerts page on
      violations, not on raw thresholds.
- [ ] Every service has the same on-call dashboard shape (RED + USE).
- [ ] OTel is the only SDK in app code; backend swap is config-only.
- [ ] No metric has > 10k active time series unless deliberately
      reviewed.
- [ ] Logs include trace_id 100% of the time.
- [ ] On-call can find "the 5 slowest endpoints" or "the 5 most
      common errors" in < 2 minutes without writing a query.
