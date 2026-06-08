---
id: semantic_caching
version: 1.0.0
owners: [ml_engineer, backend_lead, sre_engineer]
tags: [caching, cost-optimization, latency, embeddings, redis, gptcache, semantic-similarity]
when_to_use: |
  You're serving a high-volume LLM product and a meaningful fraction of
  queries are paraphrases / equivalents of prior queries. Typical
  break-even is > 10K queries/day. Especially valuable for
  customer-support FAQ, internal knowledge-base lookups, and any
  domain where users ask the same thing many ways. Distinct from
  prompt-prefix caching (see prompt_engineering_production).
inputs:
  - query_distribution, expected_qps, freshness_requirements, cost_target
outputs:
  - "cache_design: layer stack + similarity threshold + invalidation policy + observability"
---

# Semantic Caching

> Exact-match caches see two queries differing by one letter and miss.
> Semantic caches embed the query and reuse the answer when the
> meaning matches — claimed 30-70% cost reduction and 65× latency
> improvement when tuned right, **and one wrong threshold away from
> serving confidently wrong answers**. The discipline is in the
> threshold and the invalidation policy, not the embedding model.

## Exact cache vs semantic cache

| | **Exact (Redis/Memcached)** | **Semantic (RedisVL / Qdrant / GPTCache)** |
|---|---|---|
| Key | `sha256(query)` | `embedding(query)` |
| Match | Byte-equal | Cosine similarity > threshold |
| Resilience to typos / paraphrase | None | High |
| Latency | < 5ms | 20-80ms (embed + ANN search) |
| Risk of wrong answer | Zero | Non-zero — **the central design problem** |
| When useful | API responses, computed values | LLM completions, RAG responses |

**Both** belong in a production stack. The exact cache catches obvious
repeats; the semantic cache catches paraphrases the exact cache missed.

## Three-layer cache architecture (production default)

```
User query
   │
   ▼
┌──────────────────────────────────┐
│ L1: EXACT CACHE                  │   Hit rate: ~15-25%
│ key = sha256(query)              │   Latency: < 5ms
│ TTL: 1 hour                      │   Cost: $0 to check
└────────────┬─────────────────────┘
             │ miss
             ▼
┌──────────────────────────────────┐
│ L2: SEMANTIC CACHE               │   Hit rate: ~20-35%
│ key = embed(query); cos > 0.95   │   Latency: < 50ms
│ TTL: dynamic per popularity      │   Cost: ~$0.000003 per check
└────────────┬─────────────────────┘
             │ miss
             ▼
┌──────────────────────────────────┐
│ L3: RETRIEVAL / CHUNK CACHE      │   Hit rate: ~10-20%
│ Skip re-embedding retrieved docs │   Latency: < 100ms
│ TTL: until source doc changes    │   Cost: storage only
└────────────┬─────────────────────┘
             │ miss
             ▼
┌──────────────────────────────────┐
│ FULL RAG / LLM PIPELINE          │   Latency: 1-3s
│ (embed + retrieve + generate)    │   Cost: full
└──────────────────────────────────┘

Combined hit rate of L1+L2+L3 typically reaches 45-60% in production.
```

## The semantic-matching pipeline

```python
class SemanticCache:
    def __init__(
        self,
        vector_store: VectorStore,
        embed_model: str = "text-embedding-3-small",
        similarity_threshold: float = 0.95,  # tune empirically
        verifier_model: str | None = "claude-haiku-4-5",  # optional 2nd pass
    ):
        self.store = vector_store
        self.embed_model = embed_model
        self.threshold = similarity_threshold
        self.verifier = verifier_model

    async def get(self, query: str) -> CachedResponse | None:
        # Step 1: embed
        q_vec = await embed(self.embed_model, query)

        # Step 2: ANN search top-1
        nearest = self.store.search(q_vec, top_k=1)
        if not nearest or nearest[0].score < self.threshold:
            return None

        candidate = nearest[0]

        # Step 3: optional verifier pass for high-stakes domains
        if self.verifier and candidate.metadata.get("requires_verify"):
            verdict = await self._verifier_check(query, candidate.cached_response)
            if not verdict.matches:
                return None

        # Step 4: TTL check
        if candidate.is_expired():
            await self.store.delete(candidate.id)
            return None

        return candidate.cached_response

    async def put(self, query: str, response: str, source_ids: list[str], ttl_s: int = 3600):
        q_vec = await embed(self.embed_model, query)
        await self.store.upsert(
            id=str(uuid4()),
            embedding=q_vec,
            metadata={
                "query": query,           # for debugging
                "response": response,
                "source_ids": source_ids, # critical for invalidation
                "created_at": time.time(),
                "ttl_s": ttl_s,
            },
        )

    async def _verifier_check(self, new_query: str, cached_response: str) -> Verdict:
        """Tiny model decides: does the cached response actually answer
        the new query? Cheaper than re-generating."""
        prompt = (
            f"Question: {new_query}\n"
            f"Candidate answer: {cached_response}\n"
            "Does the candidate answer correctly answer the question?\n"
            "Reply with only YES or NO."
        )
        result = await llm(self.verifier, prompt, max_tokens=5)
        return Verdict(matches=result.strip().upper().startswith("YES"))
```

## The central decision: similarity threshold

Too loose → wrong answers (Semantic Drift). Too tight → cache misses,
no savings. Empirically tune via:

1. Collect 100 query pairs that humans label as "same intent" / "different intent".
2. Compute cosine similarity for each pair.
3. Plot ROC; choose threshold at the operating point you want (typically chosen for ≤1% false-positive rate).
4. **Domain-specific tightening**: for medical / legal / financial queries, push the threshold to 0.98 and add a verifier model.

| Domain | Threshold | Verifier? |
|---|---|---|
| Chatbot FAQ | 0.92 | No |
| Customer support | 0.94 | No |
| Documentation lookup | 0.95 | Optional |
| Financial / pricing | 0.97 | Yes |
| Medical / legal | 0.98 | **Mandatory** |
| Compliance / regulated | 0.99 | **Mandatory** + audit log |

## Dynamic TTL

Hot answers should live longer than cold ones:

```
TTL = base_ttl × (1 + log10(hit_count))
```

A query hit once → 1h. Hit 100 times → 3h. Hit 10K times → 5h.
Cold entries evict automatically; popular ones stay warm.

## Invalidation — the hardest part

A semantic cache without proper invalidation serves stale answers
forever. Strategies in order of preference:

| Strategy | Trigger | Pros | Cons |
|---|---|---|---|
| **Source-tagged invalidation** | When source doc updates, evict every cache entry whose `source_ids` contains that doc | Surgical | Requires source tracking |
| **Event-driven** | Webhook from CMS on edit | Real-time | Requires webhook plumbing |
| **TTL** | Time-based | Trivial | Stale answers between updates |
| **Version-tagged** | Cache entry stores doc version; mismatch → miss | Strong consistency | Cache lookup needs version check |
| **Confidence-gated** | If retrieval score < 0.7, never cache | Safety | Lower hit rate |

**Pattern in production:**

```python
# Webhook handler
@app.post("/webhook/document-updated")
async def on_doc_update(doc_id: str):
    affected = await cache.find_by_source(doc_id)
    for entry in affected:
        await cache.invalidate(entry.id)
    logger.info("invalidated %d cache entries for doc %s", len(affected), doc_id)
```

## When semantic caching is NOT worth it

Below ~10K queries/day, the embedding tax + vector-search infrastructure
exceeds the savings:

| Volume | Naive LLM cost/day | Semantic cache adds | Net win |
|---|---|---|---|
| 1K queries | $5 | $1 (embed + ANN) + $50/mo infra | NEGATIVE |
| 10K queries | $50 | $10 + $50/mo infra | ~Break-even |
| 100K queries | $500 | $100 + $100/mo infra | **30-60% savings** |
| 1M queries | $5,000 | $1,000 + $200/mo infra | **60-80% savings** |

## Multimodal semantic caching

Frontier models accept images and audio. Cache them too:

- **Image queries:** embed the image (CLIP / SigLIP); near-duplicate
  images return the cached vision-LLM response. Useful for visual
  product search, OCR pipelines.
- **Audio queries:** transcribe + embed the transcript. Cache key is
  the transcript embedding, not the audio waveform.

Both have **higher** drift risk than text — tighten threshold by
+0.02 and require a verifier for any user-facing surface.

## Observability

Every cache decision should be logged:

```python
@dataclass
class CacheDecision:
    request_id: str
    query: str
    layer: Literal["L1_exact", "L2_semantic", "L3_chunk", "miss"]
    similarity: float | None       # for L2
    cached_response_id: str | None
    latency_ms: float
    verifier_invoked: bool
```

Dashboards to track:

- **Hit rate per layer** — drop in L2 hit rate often signals embedding-model drift.
- **Cost-per-cached-query vs cost-per-miss** — if these converge, your cache is paying its tax for nothing.
- **Drift sampling**: 1% of cache hits are re-evaluated against the original LLM; if their answers diverge significantly, threshold is too loose.
- **Per-domain hit rates** — find domains where threshold should differ.

## Anti-patterns

- **One global threshold across all domains.** Medical queries deserve a tighter threshold than FAQ. Group by domain or call type and tune separately.
- **Caching personalised responses.** If the LLM was told "you are talking to user_42", you cannot cache that response for user_43. Either include user_id in the cache key (kills hit rate) or never cache personalised paths.
- **Caching tool-using responses.** If the LLM called a tool (search, weather, account balance), the answer is not idempotent. Do not cache.
- **No invalidation on source updates.** Users update the doc; you keep serving the old answer for hours. They lose trust.
- **Skipping the verifier on high-stakes domains.** A cosine of 0.97 means "very similar" not "answers the same question". For medical/legal/financial, the verifier pays for itself by preventing one mis-served answer.
- **Embedding inside the request loop.** Use a batched embedder (see RAG production skill); per-request blocking embedding is wasted latency on cache misses.
- **No cache warm-up.** A freshly deployed cache has zero hits for the first few hours. Pre-populate from production logs of the prior week.
- **Caching error responses.** Returning a cached `RateLimitError` to a different user is meaningless. Skip caching on non-2xx.

## Validation

- [ ] L1 exact cache wired before semantic cache.
- [ ] L2 semantic cache threshold tuned with labelled query pairs.
- [ ] Verifier pass enabled for high-stakes domains.
- [ ] Source-ID invalidation hooked into doc-update webhooks.
- [ ] Per-domain thresholds, not one global value.
- [ ] Personalised / tool-using responses excluded from cache.
- [ ] Cache hit-rate dashboard per layer.
- [ ] Drift-sampling job runs daily.
- [ ] Volume justifies infra cost (≥ 10K queries/day).
- [ ] Cache key includes `(tenant_id, user_segment)` where retrieval is tenant-scoped.

## References

- Redis. "RedisVL: Python Client for Redis Vector Library" (2025)
- Bang, F. et al. "GPTCache: A Library for Creating Semantic Cache" (2024/2025)
- Google Cloud. "Generative AI Caching Patterns" (2025)
- See also skills: `prompt_engineering_production` (prefix caching), `production_rag_at_scale` (full caching stack).
