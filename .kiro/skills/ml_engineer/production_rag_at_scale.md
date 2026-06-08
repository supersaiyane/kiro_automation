---
id: production_rag_at_scale
version: 1.0.0
owners: [ml_engineer, backend_lead, sre_engineer, architect]
tags: [rag, production, scaling, multi-tenant, query-routing, monitoring, cost-optimization, failure-modes]
when_to_use: |
  Moving RAG from prototype to production. Specifically: serving >100K
  queries/day, multi-tenant SaaS, latency SLAs under 3s, multiple
  knowledge domains, regulated isolation requirements, or cost lines
  someone in finance is now asking about. This is the capstone for the
  retrieval skill family.
inputs:
  - qps_target, tenant_topology, latency_sla, cost_budget, corpus_size
outputs:
  - "production_rag_design: routing + caching + isolation + monitoring + cost guardrails"
---

# Production RAG at Scale

> Production RAG is no longer a weekend project. It's a distributed
> system with retrieval pipelines, caching layers, routing logic,
> self-correction loops, multi-tenant isolation, and cost controls,
> all operating under strict latency SLAs. When RAG fails in
> production, the failure is in **retrieval roughly 73% of the time**,
> not generation — so successful enterprise deployments treat the
> knowledge source (not the model) as the primary investment.

## RAG vs Long Context — when each wins

Every frontier family now ships 1M+ token context (Claude Opus 4.7,
Sonnet 4.6, GPT-5.5, Gemini 3.1 Pro, Qwen 3.6 Plus, Llama 4 Maverick).
The question is no longer "RAG or long-context?" but "when does each
win?"

|  | **Small corpus (< 100K tokens)** | **Large corpus (> 1M tokens)** |
|---|---|---|
| **Static data** | Long context wins — stuff it all in, no index needed | RAG required — can't fit in window |
| **Dynamic data** | Hybrid — cache context, invalidate on change | RAG required — incremental indexing |
| **Multi-user** | RAG preferred — personalised retrieval | RAG required — tenant isolation |

| Dimension | RAG | Long context (1M) |
|---|---|---|
| Avg query cost | ~$0.0001 | ~$0.10 |
| Avg latency (p50) | ~1s | ~30-45s |
| Precision on specific facts | High | Degrades in middle |
| Cross-doc synthesis | Weak | Strong |
| Cost at 1000 QPS | ~$100/day | **~$100,000/day** |
| Data freshness | Minutes | Requires full reload |

**Hybrid wins for most production systems:** RAG retrieves top
candidates from a large corpus; long context synthesizes across them.

## The four-path query router

Not every query needs retrieval. Production systems classify and route:

```
                    User query
                        │
                        ▼
                 Query Classifier
                        │
        ┌────────┬──────┴──────┬────────┐
        ▼        ▼             ▼        ▼
   ┌────────┐ ┌──────┐ ┌────────────┐ ┌────────┐
   │ Direct │ │Simple│ │ Complex    │ │Agentic │
   │  LLM   │ │  RAG │ │   RAG      │ │  RAG   │
   └────────┘ └──────┘ └────────────┘ └────────┘
   "What's   "What's   "Compare Q3   "Analyze
    2+2?"    our PTO   vs Q4         all legal
             policy?"  revenue"      risks in
                                     these 50
                                     contracts"
```

| Signal | Direct LLM | Simple RAG | Complex RAG | Agentic RAG |
|---|---|---|---|---|
| Requires private data | No | Yes | Yes | Yes |
| Single-hop answer | Yes | Yes | No | No |
| Needs multiple sources | No | No | Yes | Yes |
| Requires reasoning chain | No | No | Maybe | Yes |
| Time-sensitive data | No | Maybe | Maybe | Yes |

```python
class QueryRouter:
    def __init__(self, classifier_model: str = "gpt-5.2-mini"):
        self.classifier = classifier_model

    async def classify(self, query: str, user_context: dict) -> str:
        # Fast path: regex/keyword for trivial queries
        if self._is_trivial(query):
            return "direct_llm"

        # Skip retrieval if no org-specific terms
        if not self._needs_retrieval(query, user_context):
            return "direct_llm"

        # LLM-based complexity classification
        complexity = await self._assess_complexity(query)
        return {
            "simple": "simple_rag",
            "multi_hop": "complex_rag",
            "agentic": "agentic_rag",
        }[complexity]
```

For multi-domain systems, layer a **domain router** on top:

```python
DOMAIN_RULES = {
    r"revenue|sales|quota|ARR": "financial_index",
    r"policy|handbook|PTO|benefits": "hr_index",
    r"API|endpoint|SDK|integration": "engineering_index",
    r"compliance|GDPR|SOC2|audit": "legal_index",
}
```

## Three-layer caching stack

Heavy reuse of skill `semantic_caching` — production RAG runs all three:

```
Query
  │
  ▼
L1 EXACT (Redis)          ~15-25% hit rate, < 5ms
  │ miss
  ▼
L2 SEMANTIC (Vector DB)   ~20-35% hit rate, < 50ms
  │ miss
  ▼
L3 DOCUMENT CACHE         ~10-20% hit rate, < 100ms
  │ miss               (skip re-embedding cached chunks)
  ▼
Full RAG pipeline
```

Combined hit rate: 45-60% in production. **Up to 68% cost reduction and
65× latency improvement** with well-tuned semantic caches.

## Multi-tenant isolation — the three models

| Pattern | Isolation | Cost | When |
|---|---|---|---|
| **Silo** — one index per tenant | Strongest | $$$$ | Enterprise, regulated, large customers |
| **Pool** — shared index, mandatory `tenant_id` filter | Weakest | $ | SMB SaaS, cost-sensitive |
| **Bridge** — top N tenants get silos, rest share pool | Configurable | $$ | Mixed customer base |

**Defense in depth (mandatory regardless of model):**

```python
async def retrieve_isolated(query: str, tenant_id: str, user_id: str):
    # Layer 1: tenant_id is mandatory
    if not tenant_id:
        raise SecurityError("tenant_id required")

    # Layer 2: validate user belongs to tenant
    if not await authz.user_in_tenant(user_id, tenant_id):
        raise AuthorizationError()

    # Layer 3: DB-level filter (ALWAYS, no exceptions)
    chunks = await vector_db.search(
        query_embedding=await embed(query),
        filter={"tenant_id": {"$eq": tenant_id}},
        top_k=10,
    )

    # Layer 4: post-retrieval verification (defense-in-depth)
    for chunk in chunks:
        assert chunk.metadata["tenant_id"] == tenant_id, "Cross-tenant leak"

    # Layer 5: audit log
    await audit.record(action="retrieve", tenant_id=tenant_id,
                       user_id=user_id, chunk_ids=[c.id for c in chunks])

    return chunks
```

**Noisy-neighbor prevention** (pool model):

```python
TENANT_LIMITS = {
    "free":       {"qps": 5,   "daily_queries": 500},
    "pro":        {"qps": 50,  "daily_queries": 10_000},
    "enterprise": {"qps": 200, "daily_queries": 100_000},
}
```

## Pipeline optimization — parallel + cached

```
SEQUENTIAL (naive, ~1450ms):
  Query → Embed(200) → Search(150) → Rerank(300) → Generate(800)

OPTIMIZED (~1050ms cold, ~5ms warm):
  Query ─┬─► Embed(200) ─► Vector Search(150) ─┐
         │                                      ├─► RRF → Rerank(300) → Generate(800)
         ├─► BM25 Search(100) ──────────────────┘
         │
         └─► Cache Check(5) ── HIT → Return cached
```

```python
async def parallel_retrieve(query: str, query_emb: list[float]) -> list[Chunk]:
    tasks = [
        vector_search(query_emb, top_k=20),
        bm25_search(query, top_k=20),
        graph_search(query, max_hops=2, top_k=10),  # optional
    ]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    valid = [r for r in results if not isinstance(r, Exception)]
    return reciprocal_rank_fusion(valid, k=60)[:20]
```

**Batched embedding** for throughput — group small embedding requests
into batches of 64 with a 50ms ceiling on collection wait time.
Maximizes GPU utilization at scale.

**Streaming generation with early retrieval** — fire retrieval on
pause detection while the user is still typing; first token streams
~500ms sooner than naive.

## Corrective RAG (CRAG) — self-checking retrieval

```
User query
  │
  ▼
Retrieve top-K
  │
  ▼
┌─────────────────┐
│ Relevance Grader│ "Do these docs answer the query?"
└────────┬────────┘
         │
   ┌─────┼─────┐
   ▼     ▼     ▼
 CORRECT AMBIGUOUS WRONG
   │     │     │
   │     │     ▼
   │     ▼   Reformulate query, retry
   │   Supplement with web search
   ▼
 Generate
```

```python
class CorrectiveRAG:
    async def answer(self, query: str) -> RAGResponse:
        for attempt in range(self.max_corrections + 1):
            chunks = await retrieve(query, top_k=10)
            grade = await self._grade_relevance(query, chunks)

            if grade.verdict == "correct":
                return await self._generate(query, chunks)
            elif grade.verdict == "ambiguous":
                web = await web_search(query)
                merged = self._merge_and_dedupe(chunks, web)
                return await self._generate(query, merged)
            else:  # "wrong"
                query = await self._reformulate(query, reason=grade.reason)

        # Exhausted retries — best-effort with disclaimer
        return await self._generate_with_caveat(query, chunks)
```

## Cost optimization — tiered + progressive

**Cost breakdown of a naive RAG query:**

| Component | Cost | % of total |
|---|---|---|
| Embedding | $0.000005 | ~1% |
| Vector search | $0.00001 | ~2% |
| Reranking | $0.0001 | ~15% |
| **LLM generation** | $0.0005-0.005 | **~80%** |

Generation dominates — that's where tiering wins.

**Tiered model strategy:**

|  | Low complexity | Medium | High |
|---|---|---|---|
| Generation | Small (gpt-5.2-mini) ~$0.0002 | Mid (Sonnet 4.6) ~$0.002 | Large (Opus 4.7) ~$0.02 |
| Reranking | Skip | Lightweight | Cross-encoder |

**Progressive detail pattern** — start cheap, escalate only when needed:

```python
class ProgressiveRAG:
    async def answer(self, query: str) -> str:
        # Level 1: semantic cache
        if cached := await self.cache.get(query):
            return cached.response                          # ~$0

        # Level 2: fast retrieval + small model
        chunks = await retrieve(query, top_k=3)
        resp = await generate(query, chunks, model="gpt-5.2-mini")
        if resp.confidence > 0.85:
            await self.cache.put(query, resp)
            return resp.text                                # ~$0.0003

        # Level 3: deep retrieval + reranking + larger model
        chunks = await retrieve(query, top_k=15)
        reranked = await rerank(query, chunks, top_k=5)
        resp = await generate(query, reranked, model="claude-sonnet-4-6")
        if resp.confidence > 0.7:
            await self.cache.put(query, resp)
            return resp.text                                # ~$0.003

        # Level 4: full agentic pipeline
        return await self.agentic_pipeline.run(query)       # ~$0.05
```

**Cost guardrails** are non-negotiable in production:

```python
class CostGuard:
    daily_budget = 500.0      # $/day
    per_query_limit = 0.10    # $/query
    per_user_hourly = 1.0     # $/user/hour
```

## Failure modes — the RAG taxonomy

```
RETRIEVAL FAILURES                  GENERATION FAILURES
  ├─ Missing documents                ├─ Hallucination despite good context
  ├─ Wrong chunks (low precision)     ├─ Ignoring retrieved context
  ├─ Missed chunks (low recall)       ├─ Over-reliance on one source
  └─ Stale embeddings                 └─ Citation fabrication

SYSTEM FAILURES                     QUALITY FAILURES
  ├─ Index unavailable                ├─ Chunking artifacts
  ├─ Embedding service timeout        ├─ Context window overflow
  └─ Reranker OOM                     └─ Over-hedging answers
```

**The 80% rule of chunking:** ~80% of RAG quality issues trace back to
chunking decisions, not retrieval or generation. Common failures:

- Chunk too small — loses context.
- Chunk too large — dilutes relevance.
- Boundary splits — table or list split across chunks.
- Missing metadata — chunks lack headers, titles, section context.

(See skill `contextual_retrieval` for the fix.)

**Debugging checklist** (investigate in order):

1. **Retrieval quality** — log queries vs retrieved chunks; compute precision@K on 20 failing queries; check if relevant docs exist; compare BM25 vs vector (BM25 wins → embeddings stale).
2. **Chunking quality** — sample 50 chunks, do they make sense in isolation? Check table / list / code-block boundaries. Verify metadata present.
3. **Reranking quality** — compare pre/post-rerank orderings. Is reranker pushing relevant docs down?
4. **Generation quality** — test with perfect (manually curated) context; does LLM still fail? Check context window overflow. Check system prompt isn't conflicting with retrieved content.

**Agentic-RAG-specific failures:**

- **Retrieval thrash** — agent re-retrieves without converging. Fix: limit to 3-5 iterations + track query uniqueness.
- **Tool storms** — excessive tool calls in one turn. Fix: per-query tool-call limit + cost ceiling.
- **Context bloat** — chunks accumulate, overflow window. Fix: sliding window, drop oldest.

## Monitoring — four observability layers

```
L1: INFRASTRUCTURE          L2: PIPELINE
  - p50/p95/p99 latency       - Retrieval precision@K
  - Error rates                - Retrieval recall@K
  - QPS                        - Reranker effectiveness
  - Cache hit rate             - Chunk utilization rate
  - Index size + growth        - Context window fill rate

L3: QUALITY                 L4: BUSINESS
  - Faithfulness score         - User satisfaction (thumbs)
  - Answer relevancy           - Task completion rate
  - Hallucination rate         - Escalation to human rate
  - Citation accuracy          - Cost per successful query
```

| Metric | Target | Alert | Action |
|---|---|---|---|
| p95 latency | < 2s | > 5s | Scale retrieval infra |
| Cache hit rate | > 40% | < 20% | Tune similarity threshold |
| Retrieval precision@5 | > 0.7 | < 0.5 | Re-evaluate chunking |
| Faithfulness | > 0.9 | < 0.8 | Audit generation prompts |
| Hallucination rate | < 5% | > 10% | Tighten grounding prompt |
| Empty retrieval rate | < 2% | > 5% | Check index coverage |
| Cost per query | < $0.005 | > $0.02 | Review model tiering |

**End-to-end trace** per query:

```python
@dataclass
class RAGTrace:
    request_id: str
    query: str
    route: str
    cache_hit: bool
    retrieval_latency_ms: float
    chunks_retrieved: int
    chunks_after_rerank: int
    rerank_latency_ms: float
    generation_model: str
    generation_latency_ms: float
    total_latency_ms: float
    input_tokens: int
    output_tokens: int
    estimated_cost: float
    faithfulness_score: float          # computed async
    user_feedback: str | None
```

**Nightly quality job** — sample 200 production queries, re-evaluate
with RAGAS-style metrics, alert if faithfulness or relevancy degrades.

## Scaling to millions of documents

```
Docs:    1K    →  100K  →  1M    →  100M
Chunks:  10K   →  1M    →  10M   →  1B
Index:   50MB  →  5GB   →  50GB  →  5TB

Strategy: Single → Single+Replica → Sharded → Distributed Cluster
```

**Sharding strategies:**

| Strategy | How | Pros | Cons |
|---|---|---|---|
| Hash-based | `shard = hash(doc_id) % N` | Even distribution | Cross-shard queries |
| Range-based | By date range | Time-queries fast | Uneven shards |
| Domain-based | By doc type | No cross-shard queries | Unbalanced |
| Tenant-based | By `tenant_id` | Perfect isolation | Many small shards |

**Read replicas** — separate read/write paths so ingestion never
degrades query latency.

**Index maintenance** — quarterly:

```python
async def daily_maintenance():
    # 1. Re-embed stale documents (older than 90 days OR old model version)
    await reembed(filter=stale_filter)

    # 2. Remove orphaned vectors (doc deleted, vector lingered)
    await delete_orphans()

    # 3. Compact + optimize shards (fragmentation > 20%)
    await compact_shards()

    # 4. Health-check every shard
    await verify_shard_health()
```

## Reference architectures

**Customer Support RAG** — 50K articles, 2M interactions/month, p95 < 3s,
cache hit rate ~45%, auto-resolution ~60%.

```
Customer query → Semantic cache → Intent classifier → KB RAG + Order DB
                                                        │
                                                        ▼
                                          Response with citations + confidence
                                              │
                                         confidence > 0.8 → auto-respond
                                         confidence < 0.8 → human handoff
```

**Enterprise multi-tenant knowledge platform** — 200 tenants, 10M docs,
500K queries/day, bridge isolation (5 enterprise silos + shared pool).

**Legal document analysis** — agentic RAG planner decomposes
"summarize indemnification clauses across all vendor contracts" into
metadata search → section retrieval → long-context synthesis.

## System design interview angle

**Q: Design a RAG system for 10K QPS across 500 tenants, p99 < 2s.**

Four-layer answer:

1. **Routing + caching** — three-layer cache (exact / semantic / document) handles 45-50% of traffic. Only 5-6K QPS hit retrieval.
2. **Retrieval** — bridge isolation (top 20 tenants silo, rest pool with mandatory `tenant_id` filter). Parallel vector + BM25 retrieval with RRF fusion. Sharded vector DB cluster, read replicas.
3. **Generation** — tiered model strategy. Per-tenant rate limiting prevents noisy neighbors.
4. **Observability** — per-query traces; nightly RAGAS sampling; alert if faithfulness < 0.85 or p95 > 3s.

Daily cost ~$2-5K generation + $500-1K infra.

**Q: Retrieval surfaces irrelevant docs but LLM generates plausible answer.**

Three layers of defence:

- Retrieval: relevance grader rejects sub-threshold chunks; CRAG-style fallback to web search or "insufficient info".
- Generation: constrained prompting requires the model to flag insufficient evidence; route low-confidence answers to human review.
- Monitoring: correlate retrieval scores against thumbs-down feedback to find reranker / chunking root causes.

**Q: Costs tripled over a month with no query volume increase.**

Investigate in this order: cache hit rate drop → classifier routing
shifted to expensive model → retrieval thrash in agentic loops →
re-embedding redundant docs from missed deduplication.

## Anti-patterns

- **One global semantic-cache threshold** — domains have different tolerances. Tune per domain.
- **No query router** — running agentic RAG on "what's 2+2?" burns money.
- **`tenant_id` not enforced at the DB level** — relying on the LLM to filter. Inevitable cross-tenant leak.
- **No relevance grader** — generating from garbage retrievals produces confident hallucinations grounded in real-but-irrelevant docs.
- **No cost guardrails** — one buggy agent loops 100 times and bills $50.
- **Single model tier** — using Opus for everything kills the cost model.
- **No nightly quality sampling** — quality degrades silently; users notice before you do.
- **Ingestion on the same nodes as query serving** — heavy re-indexing tanks p95 latency. Separate ingestion + read replicas.
- **No webhook-based cache invalidation** — docs update, cache serves stale answers for the TTL window.
- **Atomic-update violations** — vector DB updated but BM25 index lags; queries return inconsistent results.

## Validation

- [ ] Query router classifies routes; trivial queries skip retrieval.
- [ ] Three-layer cache stack (exact / semantic / document); per-domain thresholds.
- [ ] Multi-tenant isolation model chosen + documented (silo / pool / bridge).
- [ ] `tenant_id` is a mandatory filter at the DB level; post-retrieval assertion.
- [ ] Audit log per retrieval (tenant_id, user_id, chunk_ids).
- [ ] Per-tenant rate limits + cost guardrails.
- [ ] Parallel vector + BM25 retrieval with RRF.
- [ ] Cross-encoder reranker (Cohere / BGE / similar) on top of fusion.
- [ ] Tiered model strategy + progressive escalation.
- [ ] Corrective RAG fallback (relevance grader + web supplement).
- [ ] Per-query trace (request_id, latency breakdown, cost, confidence).
- [ ] Four-layer monitoring (infra / pipeline / quality / business).
- [ ] Nightly RAGAS-style quality sampling.
- [ ] Sharding strategy chosen by data shape.
- [ ] Read replicas separate from ingestion path.
- [ ] Quarterly maintenance job (re-embed stale, prune orphans, compact, health-check).
- [ ] Atomic vector + BM25 updates per document.
- [ ] Webhook-based cache invalidation on doc change.

## References

- Asai et al. "Self-RAG: Learning to Retrieve, Generate, and Critique" (2024).
- Yan et al. "Corrective Retrieval Augmented Generation (CRAG)" (2024).
- Anthropic. "1M Token Context Window General Availability" (March 2026).
- RAGAS Framework. "Context Precision, Recall, Faithfulness, Relevancy" (2025).
- AWS. "Multi-Tenant RAG with Amazon Bedrock Knowledge Bases" (2025).
- Microsoft. "Design a Secure Multitenant RAG Inferencing Solution" (2025).
- See also skills: `vector_search_rag_architecture`, `contextual_retrieval`, `graph_rag`, `semantic_caching`, `agent_design_tool_use`, `ai_ml_testing_evals`.
