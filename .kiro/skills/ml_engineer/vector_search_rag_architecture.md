---
id: vector_search_rag_architecture
version: 1.1.0
owners: [ml_engineer, backend_lead, database_architect]
tags: [rag, vector-search, embeddings, hybrid-search, retrieval, reranking]
when_to_use: |
  Building any system that needs to answer questions or generate
  content grounded in your data (docs, knowledge base, codebase, chat
  history, products). RAG is the standard pattern; getting it right
  separates a hallucination machine from a useful product.
inputs:
  - corpus_size, query_patterns, freshness_needs, latency_budget
outputs:
  - "rag_design: chunking + embedding + storage + retrieval + reranking + citation + evals"
---

# Vector Search + RAG Architecture

> RAG (Retrieval-Augmented Generation) lets you ground an LLM in your
> data without fine-tuning. The hard part isn't the LLM call — it's
> chunking, retrieval quality, reranking, and citations. Most "our
> RAG isn't working" is actually "our retrieval is broken."

## The full RAG pipeline

```
INGEST (one-time / continuous):
  Source docs → Chunker → Embedding model → Vector store + metadata

QUERY (per user request):
  Query → (optional rewriter) → Embedder → Vector search (top-K)
       → (optional hybrid with BM25) → Re-ranker (top-N from K)
       → Build prompt with N chunks → LLM → Response + citations
```

Each stage has its own pitfalls.

## Chunking — the often-overlooked decision

**Bad chunking = bad retrieval = bad RAG**, no matter how good the
LLM is.

Strategies:

| Strategy | When | Pros | Cons |
|---|---|---|---|
| Fixed-size (e.g. 512 tokens) | Default | Simple, predictable | May split mid-sentence |
| Sliding window with overlap | Most cases | Catches boundary info | More chunks → more storage |
| Sentence-based | Short docs | Natural boundaries | Variable size |
| Recursive structural (markdown, code) | Structured docs | Respects hierarchy | More code |
| Semantic (embedding-distance based) | Best quality | Coherent chunks | More expensive ingest |
| Document-level | Tiny docs only | One per doc | Loses precision |

Default starting point: **512 tokens, 50-token overlap, recursive
split by headings → paragraphs → sentences**.

Then iterate based on eval metrics.

## Embedding model choice

| Model | Dim | Use | Notes |
|---|---|---|---|
| OpenAI text-embedding-3-small | 1536 | Default | Cheap, good baseline |
| OpenAI text-embedding-3-large | 3072 | Higher recall | ~10x cost vs small |
| Cohere embed-v4 | 1024 | Multi-lingual | Strong reranker too |
| Voyage AI voyage-3 | 1024 | Domain-tuned (legal, code) | Specialized variants |
| BGE-large-en-v1.5 (OSS) | 1024 | Self-hosted | Strong on MTEB benchmark |
| Nomic-embed-text-v1.5 (OSS) | 768 | Cheap self-host | Good for laptop / edge |
| Jina embeddings v3 | 1024 | Multi-lingual, long context | 8K context |

Default: text-embedding-3-small. Upgrade if eval shows recall problem.

Re-embed on model change — chunks embedded with one model can't be
mixed with another in the same vector store.

## Vector store choice

| Store | Sweet spot | Notes |
|---|---|---|
| **pgvector** (Postgres) | < 10M vectors, transactional | Already have Postgres → free |
| **Pinecone** | Managed, easy, fast | Pricey at scale |
| **Qdrant** | Self-host or cloud, rich filters | Great hybrid search |
| **Weaviate** | OSS + cloud, GraphQL API | Built-in modules (rerank, generate) |
| **Milvus** | Massive scale (billions) | Operational complexity |
| **Vespa** | Production at billions + complex ranking | Yahoo / Verizon scale |
| **Elasticsearch / OpenSearch** | Hybrid (vector + lexical) | Already a search engine |
| **Chroma** | Local dev / prototyping | Limited prod features |

Default for most: **pgvector if you already have Postgres**.
**Qdrant** or **Pinecone** if you need higher throughput.

## Hybrid search — vector + lexical

Vector search misses exact-keyword queries ("product SKU 8472-A").
Lexical search misses semantic queries ("how do I cancel my plan").

Hybrid: run BOTH, fuse scores (Reciprocal Rank Fusion is the standard):

```python
# Conceptual
vector_results = vector_store.search(query_embedding, top_k=50)
lexical_results = bm25.search(query, top_k=50)
final_results = reciprocal_rank_fusion(vector_results, lexical_results, k=60)
return final_results[:10]
```

Most vector stores have hybrid built-in (Qdrant, Weaviate, OpenSearch).

## Re-ranking — the precision boost

After retrieving top-K (e.g. 50), use a re-ranker to pick the top-N
(e.g. 5) most relevant.

Re-rankers are CROSS-ENCODERS: they look at QUERY + CHUNK pair, score
relevance. More expensive per scoring but only run on top-K, so
total cost is OK.

Tools:
- **Cohere Rerank** (managed, multi-lingual, strong)
- **bge-reranker-v2-m3** (OSS, self-host)
- **Mixedbread mxbai-rerank-large-v1** (OSS)
- **Voyage rerank-2** (specialized variants)

Adding a re-ranker typically improves answer quality 20-40% with
minimal latency cost.

## Query rewriting — for ambiguous queries

For chat / multi-turn conversations, the user's query depends on
context:

```
User: "How does the pricing work?"
User: "What about the Pro tier?"  ← ambiguous standalone
```

Use an LLM to REWRITE the query before retrieval:

```
Standalone query: "How does pricing work for the Pro tier?"
```

Costs: 1 extra LLM call per query. Worth it for chat UIs.

Variations:
- **HyDE** (Hypothetical Document Embedding): LLM imagines an answer;
  embed the imagined answer to retrieve real docs.
- **Multi-query**: generate 3-5 query variants, retrieve for each,
  union results.

## Metadata + filtering

Vector store should support metadata filters:

```python
results = vector_store.search(
    query_embedding,
    filter={
        "tenant_id": user.tenant_id,         # tenant isolation
        "doc_type": "policy",
        "date": {"$gte": "2025-01-01"},      # freshness
        "access_level": {"$in": user.allowed_levels}
    },
    top_k=20
)
```

Critical: TENANT FILTER on every query for multi-tenant. Bypass = data
leak. Most stores support this; some don't (chroma is limited).

## Citation tracking

Every response should cite sources:

```
The pricing page shows annual savings of 20% [1].

[1] /docs/pricing.md#annual-savings (confidence: 0.92)
```

Implementation:
- Each chunk carries source metadata (URL, title, section).
- Pass top-N chunks to LLM with explicit "cite by number" instruction.
- Parse LLM output for citations; validate against the chunks used.

LLM-as-judge eval: "is this claim supported by the cited chunk?"

## Freshness — re-indexing

| Pattern | Use |
|---|---|
| One-time | Static knowledge base (rarely changes) |
| Scheduled (nightly) | Slowly changing docs |
| Webhook-driven | Real-time (chat / wiki) |
| CDC from DB | Product catalogs, orders |

Track: time since last update per source, alert if a critical source
is stale.

## RAG evals — the discipline

Without evals, your RAG silently degrades.

Metrics:
- **Retrieval recall@K**: of the human-labeled relevant chunks, how
  many are in top-K?
- **Retrieval precision@K**: of top-K, how many are relevant?
- **Answer faithfulness**: does the answer ONLY use info from cited
  chunks? (LLM-as-judge)
- **Answer helpfulness**: subjective; A/B test with users.
- **Citation accuracy**: every claim in the answer maps to a real
  chunk?

Tools: Ragas, TruLens, LangSmith, Promptfoo, custom golden datasets.

Run on EVERY change (embedding model swap, chunker tweak, prompt update).

## Common failure modes

| Symptom | Likely cause |
|---|---|
| "Answer ignores the docs" | Retrieval missed relevant chunks. Check recall. |
| "Made-up facts" | Retrieved chunks don't support; prompt allows. Add "only use provided context." |
| "Wrong citation" | Re-ranker swapped chunks; check ranker output. |
| "Slow" | Re-ranker on too many chunks; or vector search not indexed. |
| "Doesn't respect tenant" | Missing metadata filter — security issue. |
| "Tomorrow's docs not found" | Re-indexing not running; check pipeline. |

## Late interaction & ColBERT — the bi/cross middle ground

Re-ranking with a cross-encoder is accurate but slow (~500ms per pair).
Bi-encoders are fast (~10ms) but lose token-level precision. **Late
interaction** (ColBERT family) is the third architecture that splits
the difference:

```
SPEED <-----------------------------------------> ACCURACY

Bi-Encoder          Late Interaction         Cross-Encoder
(1 vector/doc)      (N vectors/doc)          (joint encoding)
~10ms               ~30-50ms                 ~500ms+ per pair
Scales to 1B+       Scales to 100M+          Scales to 10K
```

**How ColBERT differs:** encode query and document into per-token
vector matrices (not single vectors). Score with **MaxSim** — for
each query token, find its best-matching document token; sum the maxes.
Token-level matching preserves rare-but-critical terms (product IDs,
domain jargon) that single-vector embeddings dilute.

**ColBERTv2 + PLAID** make it practical at scale:

| | ColBERT v1 | ColBERTv2 (compressed) | Bi-encoder |
|---|---|---|---|
| Per-token storage | 512 bytes | ~16-32 bytes | n/a (1 vector/doc) |
| 10M docs (200 tok each) | ~1 TB | ~64 GB | ~30 GB |
| Accuracy (NDCG@10) | 0.39-0.42 | 0.39-0.44 | 0.35-0.40 |
| Domain transfer | Strong | Strong | Weak |

PLAID's multi-stage pipeline (centroid pruning -> coarse score ->
residual decompress -> exact MaxSim) keeps query latency at 50-100ms
even on 10M+ document corpora.

**When to pick ColBERT over our default hybrid+rerank:**

- Domain-specific search where term-level matching matters (legal, medical, technical manuals, code search).
- 1M-50M document corpus (sweet spot — storage 2-4x bi-encoder, manageable).
- Accuracy demands cross-encoder-level quality but cross-encoder latency is unacceptable.
- Multilingual corpora — Jina ColBERT v2 supports 89 languages.

**When to skip ColBERT:**

- Web-scale (>100M docs) — index storage gets painful. Use bi-encoder for first-stage; ColBERT as reranker.
- Self-contained chunks (FAQ pairs) — single-vector is fine.
- You don't have a GPU in the inference path.

**Production patterns:**

- **ColBERT as primary retriever** — 1M-50M corpora, accuracy paramount.
- **ColBERT as reranker** (most common) — BM25 / bi-encoder first stage -> top 1000 -> ColBERT MaxSim -> top 20.
- **Triple hybrid** — BM25 + bi-encoder + ColBERT -> RRF -> cross-encoder rerank -> top-k. Maximum accuracy, medium scale.

**Library:** `RAGatouille` (Answer.AI) wraps Stanford ColBERT with a
clean Python API — three lines to index, three to search.

## Anti-patterns

- **No chunking strategy** — defaulting to "whole doc per chunk" or
  "1 sentence per chunk." Both extremes hurt.
- **No re-ranking** — top-K vector is too noisy for direct LLM use.
- **No metadata filtering** — multi-tenant breaches.
- **Hard-coded prompts in code** without versioning.
- **No evals** — silent regression.
- **One vector store for every workload** — payments + docs + chat in
  the same index → metadata bloat, security risk.
- **Re-embed on every query** — expensive; cache.
- **Chunk size = 100 tokens** — context too narrow, LLM can't reason.
- **Chunk size = 8000 tokens** — vector search is approximate; tiny
  diff in query vs chunk diluted.
- **Storing PII in vector store metadata** without classification.

## Validation

- [ ] Chunking strategy documented + tuned to corpus.
- [ ] Embedding model chosen + locked (version pinned).
- [ ] Re-ranker in the pipeline (or explicit justification why not).
- [ ] Tenant / authz filter on every query.
- [ ] Citation tracking + validation.
- [ ] Recall@K + precision@K + faithfulness metrics measured.
- [ ] Re-indexing pipeline tested.
- [ ] p99 retrieval latency < 500ms.
- [ ] Cost per query in scope.
