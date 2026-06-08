---
id: ai_ml_system_design
version: 1.0.0
owners: [ml_engineer, architect, cto]
tags: [ml, system-design, llm, rag, fine-tune, mlops]
when_to_use: |
  Designing the AI/ML layer for a product. The earliest decisions —
  prompt vs RAG vs fine-tune, model size, data layer, eval strategy —
  shape every downstream choice. Get them right before writing a line
  of training or inference code.
inputs:
  - product_requirements, data_inventory, latency_budget, cost_envelope
outputs:
  - "ml_system_design: strategy choice + topology + data layer + eval + serving + cost"
---

# AI / ML System Design

> The fastest path to a working ML feature is the SIMPLEST one that
> hits the metric. Don't fine-tune when prompting works. Don't build
> a vector DB if you have 100 documents. The senior craft is choosing
> the right TIER for the requirement.

## The complexity ladder — pick the simplest viable

```
0. HEURISTICS     - if/else, regex, lookup table.        $0  Days.
1. PROMPT-ONLY    - call LLM with structured prompt.     $$  Days-weeks.
2. PROMPT + RAG   - retrieve relevant docs first.        $$  Weeks.
3. FINE-TUNE      - adapter on base model.               $$$ Weeks-months.
4. CUSTOM MODEL   - train from scratch.                  $$$$ Months-years.
```

**Default: start at tier 0 or 1. Move up ONLY when the lower tier
demonstrably fails the metric.** Most "we need AI" requests stop at
tier 1.

## Decision tree

```
Can heuristics solve it?
  YES → tier 0. Done.
  NO  → Need natural language understanding / generation?
    NO  → Classical ML (XGBoost, scikit-learn) on tabular data.
    YES → Out-of-the-box LLM acceptable?
      YES → tier 1 (prompt-only).
      NO  → Needs proprietary knowledge / domain context?
        YES → tier 2 (RAG).
        NO  → Needs specific format / brand voice consistently?
          YES → tier 3 (fine-tune adapter).
          NO  → Have millions of labeled examples + GPU budget?
            YES → tier 4. (Rare; usually wrong choice.)
            NO  → back to tier 2 or 3.
```

## Tier 1 — Prompt-only

When: classification, summarization, extraction, simple generation
where the LLM already "knows enough."

Architecture:

```
User → API → Prompt template → LLM API → Response parser → User
```

Choices:
- **Model**: Claude Sonnet 4.5 / GPT-4o / Gemini 2.5 Pro for capability;
  Haiku / GPT-4o-mini / Gemini Flash for cost.
- **Output format**: ALWAYS structured (JSON schema, Pydantic). Never
  parse natural-language responses.
- **Tools / function calling** for actions; never run LLM-generated code.
- **Streaming** for UX where partial output is useful.

Cost: $0.01 - $1 per call (varies wildly by model + length).

## Tier 2 — RAG (Retrieval-Augmented Generation)

When: Q&A over your docs, knowledge base bots, code-aware assistants.

Architecture:

```
User query → embed → vector search → top-K docs → re-rank → prompt with
context → LLM → response with citations
```

Components:
- **Embedding model**: OpenAI text-embedding-3-small, Cohere embed-v4,
  Voyage AI for domain-specific, OSS (BGE, Nomic).
- **Vector store**: pgvector (default for ≤ 10M chunks), Pinecone,
  Qdrant, Weaviate, Vespa for scale + hybrid search.
- **Chunking strategy**: 200-1000 token chunks with 10-20% overlap.
  Or "semantic chunking" via sentence boundaries.
- **Re-ranker**: Cohere Rerank, Cross-encoder. Boosts precision @ top-K.
- **Citation tracking**: every response cites source chunk + URL +
  confidence.

See `vector_search_rag_architecture` skill for the deep dive.

## Tier 3 — Fine-tune

When: brand-voice consistency, narrow domain, format adherence the
base model can't reliably produce, smaller/cheaper model for high-volume.

Approaches:
- **LoRA / QLoRA adapters** — train ~0.1% of params; cheap, fast.
- **Full fine-tune** — rare; needs lots of data + GPU.
- **DPO / RLHF / RLAIF** — preference tuning after SFT.

Data requirement:
- LoRA: 500-5000 high-quality examples minimum.
- Full FT: 10k+ examples.

Don't fine-tune to teach NEW KNOWLEDGE (that's RAG's job). Fine-tune
for STYLE, FORMAT, BEHAVIOR.

## Inference topology

```
[ App ]
  │
  ▼
[ Inference gateway ]  ← rate limit, auth, cost cap, fallback
  │
  ├─→ [ Primary model: Claude Sonnet ]
  ├─→ [ Fallback: Claude Haiku ]      ← if primary times out / errors
  ├─→ [ Self-hosted model: vLLM ]      ← if cheaper at volume
  │
  └─→ [ Embedding service ] ←→ [ Vector store ] ←→ [ Re-ranker ]
```

Key decisions:
- **Hosted (Anthropic, OpenAI, Google) vs self-hosted (vLLM, TGI,
  Together, Modal)**.
  - Hosted: faster to ship, lower ops, predictable.
  - Self-hosted: 50-80% cheaper at scale (> $10k/mo), data residency.
- **Failover**: hosted models DO go down (Anthropic, OpenAI both have
  outages monthly). Have a fallback path.
- **Streaming**: SSE / WebSocket; chunk-by-chunk output.

## Data layer

For RAG / classical ML:

| Component | Purpose |
|---|---|
| Source store | Where the docs / training data live (S3, GCS, DBs) |
| Pipeline | Ingest → clean → chunk → embed → write to vector store |
| Vector store | Fast similarity search over embeddings |
| Feature store | For classical ML — precomputed features (Feast, Tecton) |
| Eval data | Golden datasets, held out from training |
| Logs | All prompts / responses / user signal for analysis |

Data freshness:
- Real-time: re-embed on doc change (webhook → pipeline).
- Daily / hourly: scheduled batch.
- One-shot: rare; static knowledge bases.

## Latency budget

| Tier | Realistic p99 latency |
|---|---|
| Embedding (single text) | 50-200ms |
| Vector search (top-10) | 20-100ms |
| Re-ranker | 100-500ms |
| LLM (Sonnet, 500 tok response) | 2-5 seconds |
| LLM (Haiku, 500 tok) | 0.5-2 seconds |
| LLM streaming (time to first token) | 200-800ms |

For interactive UX, target < 3s total. For chat, streaming makes
perceived latency much lower.

## Cost model

Per-request:

```
Cost = (input_tokens × $/M_in) + (output_tokens × $/M_out)
     + (embedding tokens × $/M_embed if RAG)
     + (vector search query — usually included)
     + (re-rank — separate API cost)
```

Typical SaaS B2B costs:
- Tier 1 prompt: $0.001 - $0.05 per request.
- Tier 2 RAG: $0.005 - $0.10 per request.
- High-volume products: budget $1-10 per active user per month.

Compute at LAUNCH + Year 1 + Year 3. Identify break-even point where
self-host beats API ($/req × volume vs. fixed GPU cost).

## Evals — non-negotiable

See `ai_ml_testing_evals` skill. At minimum:

- Golden dataset (100-1000 hand-curated examples).
- Metrics per task:
  - Classification: accuracy, F1, per-class.
  - Generation: faithfulness, helpfulness, harmlessness (LLM-as-judge).
  - RAG: retrieval recall@K, answer faithfulness, citation accuracy.
- CI gate: regression on metric blocks merge.
- Production canary: 1-5% traffic to new model, compare.

## Safety + guardrails

- Input filtering for prompt injection (cross-ref security skill
  `ai_ml_security_prompt_injection`).
- Output filtering: PII redaction, harmful content, schema validation.
- Tool-calling sandbox + per-tool authz.
- Rate limit per user (cost + DoS).
- Audit log of all prompts + responses (with PII redacted).

## Anti-patterns

- **"We need AI"** without a measurable goal. Define the metric first.
- **Building bespoke when a hosted API works.** Premature optimization.
- **Fine-tuning to teach knowledge.** Use RAG instead.
- **No evals → ship and hope.** Models drift; prompts regress; users
  complain after 3 months.
- **Same model for everything.** Pick model per task: capability vs
  cost tradeoff.
- **Hardcoded prompt with no versioning.** Tomorrow's release breaks
  today's behavior; no rollback.
- **Treating LLM output as deterministic.** It's stochastic; even with
  temp=0 the API can change.
- **No human-in-loop for destructive actions** (agent that can email /
  pay / delete).

## Validation

- [ ] Tier chosen + justified vs the next-simpler tier.
- [ ] Model selection explicit + rationale.
- [ ] Latency budget documented per call class.
- [ ] Cost projection at launch / Year 1 / Year 3.
- [ ] Evals + metrics defined; CI gate in place.
- [ ] Fallback model + retry logic.
- [ ] Streaming where UX needs it.
- [ ] Safety guardrails wired (input + output + tool-call).
- [ ] Audit logging operational.
- [ ] ADR-ML-NNN written for major decisions.
