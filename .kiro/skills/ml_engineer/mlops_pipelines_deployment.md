---
id: mlops_pipelines_deployment
version: 1.1.0
owners: [ml_engineer, devops_engineer, sre]
tags: [mlops, model-registry, ab-serving, drift, monitoring, retraining]
when_to_use: |
  Operating ML/LLM models in production beyond a single notebook. The
  difference between a research project and a product is MLOps: model
  registry, reproducible training, A/B serving, drift detection,
  retraining cadence, cost monitoring.
inputs:
  - model_strategy, request_volume, slo_targets, team_maturity
outputs:
  - "mlops_plan: registry + pipeline + serving + monitoring + retrain + rollback"
---

# MLOps — Pipelines + Deployment + Operations

> The model that ships is not the model in production six months
> later. Data drifts. Users push edges. Vendors change defaults.
> MLOps is the discipline of keeping the SHIPPED model honest over
> time.

## Maturity tiers (Google's "MLOps Maturity Model")

```
LEVEL 0 — Manual:
  Notebooks, manual deploy, no monitoring. OK for prototypes.

LEVEL 1 — Reproducible:
  Pipelines automated. Model artifact registry. Versioned data.
  Can re-train + redeploy in hours, not days.

LEVEL 2 — Continuous:
  Auto-retrain on drift. Auto-deploy through staging → prod.
  A/B serving + traffic shifting. Online learning if applicable.
```

Pick the tier that matches your product stage. Don't over-engineer
for a CRUD app that uses GPT-4.

For LLM-based products: Level 0-1 often sufficient (no training).
For classical ML or fine-tuned LLMs: Level 1-2.

## Model lifecycle

```
EXPLORE → DEVELOP → TRAIN → EVALUATE → REGISTER → DEPLOY → MONITOR → RETRAIN
   ↑                                                            │
   └────────────────────────────────────────────────────────────┘
```

Each step has tooling + artifacts.

## Training pipeline (for fine-tunes / classical ML)

```
1. INGEST: data from feature store / S3 / DB
2. CLEAN: deduplication, PII removal, train/val/test split
3. FEATURE ENGINEER: transforms, encoders
4. TRAIN: hyperparameter sweep, distributed if needed
5. EVALUATE: on held-out test set + golden set
6. REGISTER: model + metadata to artifact store
7. ARTIFACT: model file, tokenizer, preprocessor — all versioned
```

Orchestration: Airflow, Kubeflow, Metaflow, Prefect, Dagster, Vertex
AI Pipelines, SageMaker Pipelines.

Reproducibility checklist:
- Pinned data version (snapshot ID).
- Pinned code version (git SHA).
- Pinned environment (Docker image tag).
- Pinned random seed.
- Recorded hyperparameters.
- Recorded eval metrics.

## Model registry

Required artifacts per model:

```
model_id:             customer-intent-v3.2
trained_at:           2026-04-15T10:00:00Z
data_snapshot:        s3://datalake/snapshots/2026-04-14/...
code_sha:             abc1234
image_tag:            ghcr.io/org/trainer:v1.5
hyperparameters:      { lr: 1e-4, batch: 32, epochs: 5 }
eval_metrics:
  accuracy:           0.876
  f1:                 0.824
  latency_p99_ms:     85
training_cost_usd:    420
status:               canary | production | retired
parent_model:         customer-intent-v3.1
diff_notes:           "Added 1,200 examples from Q1 feedback loop"
```

Tools: MLflow (de facto OSS), Weights & Biases, Comet, SageMaker
Model Registry, Vertex AI Model Registry.

## Deployment strategies

| Strategy | Use | Risk |
|---|---|---|
| **Blue/green** | Atomic cutover | All-or-nothing rollback |
| **Canary** (5% → 50% → 100%) | Default | Gradual risk; auto-rollback on metric drop |
| **Shadow** (mirror traffic, don't serve) | Pre-launch validation | Logged perf without user impact |
| **Multi-armed bandit** | Continuously optimizing | Auto-shifts traffic to best variant |
| **A/B split** | Compare two variants | Strict statistical analysis |

Default: canary with auto-rollback on metric regression.

## Serving topology

```
[ API gateway ] → [ Inference router ]
                      │
                      ├─→ [ Model A : 95% traffic ] (production)
                      ├─→ [ Model B : 5% traffic  ] (canary)
                      └─→ [ Shadow : 100% mirror ]  (logged, not served)
```

Inference platforms:
- **Self-hosted**: vLLM, TGI (Text Generation Inference), SGLang,
  TensorRT-LLM, TorchServe, TensorFlow Serving, BentoML, Triton,
  Ray Serve.
- **Managed**: Modal, Replicate, Anyscale, AWS SageMaker, GCP Vertex.
- **Hosted API only**: Anthropic, OpenAI, Google — no serving infra
  needed.

For LLM-heavy products: hosted API is usually right unless cost or
data-residency forces self-host.

### Self-hosting LLM inference — choosing the engine

If you're past the hosted-API threshold (typically: regulated data,
on-prem requirements, or > $50K/mo in inference spend on stable
workloads), engine choice matters:

| Engine | Strengths | Weaknesses | When |
|---|---|---|---|
| **vLLM** | PagedAttention + continuous batching, best throughput per GPU $; large community | Optimised for newer Llama/Qwen/Mistral; slower to add brand-new architectures | Default pick for most LLM workloads in 2026 |
| **TGI** (HuggingFace) | First-class HF Hub integration; good for Llama family; supports speculative decoding | Slightly behind vLLM on throughput | When you live in the HF ecosystem |
| **SGLang** | Excellent for structured generation (JSON schema, constrained decoding); fast prefix cache (RadixAttention) | Newer; smaller community | Agent / tool-use workloads heavy on JSON output |
| **TensorRT-LLM** | Best raw latency on NVIDIA hardware; highly tuned | NVIDIA-only; harder to deploy; longer compile cycles | Latency-critical, GPU-rich workloads |
| **TorchServe / Triton** | Multi-framework, multi-model | Less LLM-specific optimisation | Mixed workloads (LLMs + classical ML on same fleet) |

Operational essentials regardless of engine:

- **Continuous batching** (vLLM/TGI/SGLang default) — dynamically packs
  requests with different sequence lengths into a single forward pass;
  3-10× throughput vs naive static batching.
- **PagedAttention** (vLLM-style) — manages KV-cache in pages like an
  OS manages virtual memory; eliminates internal fragmentation; lets
  you fit ~2-4× more concurrent sequences in the same GPU memory.
- **Prefix / KV-cache** — when many requests share a system prompt,
  the engine reuses the cached KV state. Sibling to the prompt-prefix
  caching covered in `prompt_engineering_production` and the
  semantic-caching covered in `semantic_caching`.

### Speculative decoding — 2-3× wall-clock speedup at zero quality cost

LLM decoding is memory-bandwidth-bound: loading 140GB of weights to
produce one 2-byte token is wasteful. Speculative decoding uses a
cheap method to **guess** the next K tokens and the big model
**verifies** them all in one parallel pass.

| Variant | What it adds | Speedup |
|---|---|---|
| **Draft model** (classic) | A small 1B-7B "draft" model generates K candidates; target model verifies | 2-3× |
| **Medusa heads** (Cai et al, 2024) | Extra prediction heads on the target model itself — no separate draft model, no extra VRAM | 2.5× |
| **Lookahead decoding** (Fu et al, 2024) | Uses the model's own past hidden states to find recurring n-grams | Excellent on structured / repetitive output (code, JSON) |
| **Hardware-aware dynamic K** (vLLM, TensorRT-LLM) | K grows when GPU underutilised, shrinks when saturated | Adaptive — throughput-aware |

**Where it wins:** code, JSON output, structured generation,
classification — anything where the next token is predictable.

**Where it doesn't:** high-temperature creative writing — flat
probability distributions mean low acceptance rate, wasted draft
compute. Disable speculation (or set K=1) for creative paths.

**Operational reality:** vLLM, TGI, and TensorRT-LLM all support
speculation as a config flag. The choice is K (number of speculated
tokens) and which method (draft model vs Medusa). Start with vLLM's
default and benchmark on YOUR workload — acceptance rates are
domain-specific.

## Monitoring

What to monitor:

| Layer | Metric |
|---|---|
| **Infrastructure** | GPU/CPU util, memory, queue depth, throughput |
| **Latency** | p50 / p99 inference time |
| **Quality** | accuracy / faithfulness / harmfulness (sampled, LLM-judge) |
| **Drift** | input feature distribution vs training |
| **Output drift** | label distribution shift |
| **Cost** | $/request, total spend per day |
| **User signal** | thumbs-up/down, conversion, retention |

Tool stack:
- **Prometheus + Grafana** for infra + latency.
- **Arize / WhyLabs / Aporia / Fiddler** for ML observability.
- **PostHog / Mixpanel** for user signal.

Alert on drift > 2σ from baseline.

## Drift detection

Two kinds:

| Type | What | Detection |
|---|---|---|
| **Data drift** | Input distribution changes (e.g. new product launched, user demographics shift) | KS test, PSI (population stability index), embedding distance |
| **Concept drift** | Input→output relationship changes (e.g. user behavior shifts) | Predictive metric on labeled samples |
| **Performance drift** | Model output gets worse | Track key metric over time |

When detected: trigger retraining pipeline OR rollback to last stable.

## Online learning vs batch retraining

| Approach | Use |
|---|---|
| Batch retraining (weekly/monthly) | Default; most stable |
| Online learning (continuous updates) | Rare; high-frequency, fast-shifting data (ads, recsys) |
| Active learning | When labeling is expensive; ask users to label uncertain cases |
| Reinforcement learning from human feedback (RLHF / RLAIF) | LLM fine-tunes |

Don't ship online learning for v1. Batch is plenty.

## Rollback

Auto-rollback triggers:
- Eval metric drops > N% on canary.
- Error rate spike.
- User signal (thumbs-down rate up).
- Cost per request spike.

Process:
1. Detect (within 5 min).
2. Shift traffic back to previous model (within 1 min after detection).
3. Page on-call.
4. Investigate.
5. Decide: re-deploy with fix, or sustain previous.

## Cost monitoring

For hosted APIs:
- Per-request cost logged.
- Daily / weekly spend dashboard.
- Anomaly alert (spike > 20% WoW).
- Budget cap per workload + per tenant.

For self-hosted:
- GPU utilization (low = wasted; high = capacity risk).
- Right-size: GPU type + count.
- Spot for batch; on-demand for serving.

See cloud architect / FinOps skills for budget framework.

## Specific concerns by model type

### LLM (via API)
- Track tokens per request.
- Cache deterministic prompts.
- Fallback model on primary outage.
- Eval metric: faithfulness, helpfulness, harmlessness.

### Embedding model
- Pin version; re-embed on swap.
- Lower risk of drift than generative.

### Classical ML (XGBoost, etc.)
- Feature freshness monitored.
- Retrain on drift signal (often weekly).

### Custom DL model
- Distributed training infra needed for scale.
- Versioned model files (often GBs).
- Inference optimization (ONNX, TensorRT, vLLM, Triton).

## Agent-specific MLOps

For agentic systems (multi-step LLM with tool use):
- Track per-step token + cost.
- Trace entire conversation for debugging (LangSmith, Helicone, Phoenix).
- Replay tools for regression testing.
- Sandbox tools; cap concurrent agent count.

## Anti-patterns

- **Notebook → prod.** Move to a real pipeline.
- **One-off training, no registry.** Can't reproduce; can't roll back.
- **No drift detection.** Silent decay over months.
- **Manual deployment.** Mistakes; downtime.
- **No A/B / canary.** All-traffic flip is a hostage situation.
- **Online learning before basics.** Batch first.
- **Compute optimized only for training.** Inference is where money goes.
- **No fallback model.** Vendor outage = product down.
- **Same model image across regions** with no deployment isolation.

## Validation

- [ ] Model artifact + metadata registered for every prod model.
- [ ] Training pipeline reproducible from a git SHA.
- [ ] Canary deploy + auto-rollback wired.
- [ ] Drift detection on input + output distributions.
- [ ] User signal (CSAT / conversion) tied to model version.
- [ ] Cost per request tracked + dashboarded.
- [ ] Fallback model for API outages.
- [ ] On-call runbook for ML-specific incidents.
- [ ] Retraining cadence documented + automated.
