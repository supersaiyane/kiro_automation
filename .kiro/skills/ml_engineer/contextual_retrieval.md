---
id: contextual_retrieval
version: 1.0.0
owners: [ml_engineer, backend_lead]
tags: [rag, retrieval, anthropic, chunking, bm25, contextual-embeddings, ingestion]
when_to_use: |
  Your RAG retrieval-failure rate exceeds ~3-5% on top-20 chunks, your
  documents are dense or fragmented (legal contracts, financial
  reports, technical manuals), or your chunks regularly lose meaning
  in isolation. This is an ingestion-time technique — pay once at
  index time, save forever at query time.
inputs:
  - corpus_characteristics, retrieval_failure_rate, ingestion_budget, model_choice
outputs:
  - "contextual_retrieval_design: contextualization model + caching strategy + pipeline + cost"
---

# Contextual Retrieval (Anthropic, Sep 2024)

> Chunking is the silent killer of RAG. A chunk that reads
> "It costs $200/month" is useless without knowing **what** costs
> $200 and which company sells it. Contextual Retrieval prepends a
> short LLM-written context string to each chunk **before** embedding
> and BM25 indexing. Anthropic's measurements: 49% reduction in
> retrieval failures with hybrid; 67% with reranking on top.
> This is the highest-leverage single change you can make to a RAG
> pipeline.

## The problem: context dilution

```
Original document — "Acme Corp Q3 2025 Financial Report"

  Section 4: Product Pricing

    "The Standard plan costs $200/month. The Enterprise
     plan includes SSO and audit logs for $800/month."

──── After naive chunking ────

Chunk 17: "It costs $200/month."
Chunk 18: "The Enterprise plan includes SSO and audit
           logs for $800/month."
```

A user searching "How much does Acme Standard plan cost?" misses
chunk 17 entirely. No "Acme", no "Standard", no "plan" — embedding
is semantically distant from the query.

**Anthropic's measurement:** traditional chunking has 5.7% retrieval
failure rate on top-20. Roughly 1 in 18 queries fails to surface
information that exists in the knowledge base.

## How it works — two sub-techniques

### Contextual Embeddings

Before embedding a chunk, ask an LLM (cheap one — Haiku, GPT-5.2-mini)
to write a 50-100 token context string explaining what the chunk is
about within the full document. Prepend that string to the chunk.
Embed the combined string.

```
<document>
{{WHOLE_DOCUMENT}}
</document>

Here is the chunk we want to situate within the whole document:
<chunk>
{{CHUNK_CONTENT}}
</chunk>

Please give a short succinct context to situate this chunk within
the overall document for the purposes of improving search retrieval
of the chunk. Answer only with the succinct context and nothing else.
```

**Result for chunk 17:**

> **Before:** "It costs $200/month."
>
> **After:** "This chunk is from the Acme Corp Q3 2025 Financial Report,
> Section 4 on Product Pricing. It describes the cost of the Standard
> plan. It costs $200/month."

The embedding now contains "Acme", "Standard plan", "Product Pricing"
— all the terms a user would naturally search for.

### Contextual BM25

Same trick, applied to a BM25 keyword index built over the
contextualized chunks. BM25 is critical for:

- **Exact terms** — product IDs, version numbers, SKUs.
- **Rare tokens** — domain-specific jargon under-represented by embeddings.
- **Proper nouns** — company names, people, places.

A query "Widget-X pricing" gets zero BM25 hits on raw chunk "It costs
$200" but matches the contextualized version because "Widget-X" appears
in the prepended context.

## Cumulative performance gains (Anthropic data)

| Configuration | Failure rate (top-20) | Reduction vs baseline |
|---|---|---|
| Traditional embeddings (baseline) | 5.7% | — |
| Contextual Embeddings only | 3.7% | **35%** |
| + Contextual BM25 (hybrid) | 2.9% | **49%** |
| + Reranking | 1.9% | **67%** |

The headline: the combination of contextual embeddings + contextual
BM25 + reranking is the highest-leverage single change available to
a RAG pipeline as of 2026.

## Cost — the part everyone gets wrong

Naive cost: for a 10K-chunk corpus, you make 10K LLM calls. With
Sonnet at ~$0.002/chunk: $20. With Opus: $100. Sounds fine — until
you realize each call sends the **whole document** along with the
chunk, multiplying input tokens by ~document-size / chunk-size.

**The fix: prompt caching.** The document portion is identical across
all chunks from that document. Cache it.

```python
def contextualize_with_caching(
    full_document: str,
    chunks: list[str],
    model: str = "claude-haiku-4-5",
) -> list[str]:
    """Document body cached across all chunk calls — ~90% cost reduction."""
    results = []
    for chunk in chunks:
        response = client.messages.create(
            model=model,
            max_tokens=200,
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": f"<document>\n{full_document}\n</document>",
                        "cache_control": {"type": "ephemeral"},  # 5-min TTL
                    },
                    {
                        "type": "text",
                        "text": (
                            f"<chunk>\n{chunk}\n</chunk>\n\n"
                            "Please give a short succinct context to situate "
                            "this chunk within the overall document for the "
                            "purposes of improving search retrieval. Answer "
                            "only with the succinct context and nothing else."
                        ),
                    },
                ],
            }],
        )
        context = response.content[0].text
        results.append(f"{context}\n\n{chunk}")
    return results
```

**Cost reference** (10K chunks, avg 400 tokens):

| Model | Cost per chunk | Total (no cache) | Total (cached) |
|---|---|---|---|
| Claude Haiku 4.5 | ~$0.0003 | ~$3 | ~$0.30 |
| Claude Sonnet 4.6 | ~$0.002 | ~$20 | ~$2 |
| Claude Opus 4.7 | ~$0.01 | ~$100 | ~$10 |

Prompt caching reduces cost ~90% for the document body that gets
repeated. **Use Haiku-class** unless you're in a regulated domain
where audit demands the frontier model — context strings are short
and factual, no creative writing.

## The lightweight fallback: Contextual Chunk Headers (CCH)

If LLM contextualization is too expensive (free SaaS tier, edge
deployment, real-time ingestion), use **deterministic** structural
headers — no LLM call required:

```python
def add_chunk_headers(
    document_title: str,
    section_hierarchy: list[str],
    chunk: str,
) -> str:
    header_parts = [f"Document: {document_title}"]
    for i, section in enumerate(section_hierarchy):
        header_parts.append(f"{'  ' * i}Section: {section}")
    header = "\n".join(header_parts)
    return f"{header}\n\n{chunk}"

# Example output:
#   Document: Acme Corp Q3 2025 Financial Report
#   Section: Finance
#     Section: Product Pricing
#       Section: Standard Plan
#
#   It costs $200/month.
```

| Factor | CCH | LLM Contextualization |
|---|---|---|
| Cost | Free | $0.30-$10 per 10K chunks (with caching) |
| Quality | Good for structured docs (Markdown, HTML) | Excellent on all docs incl. unstructured |
| Speed | Instant | 50-200ms per chunk |
| Best for | Tech docs, Markdown, HTML with clear headers | Legal, medical, unstructured prose |

**Hybrid approach:** use CCH for structured documents, LLM
contextualization for unstructured/ambiguous ones — saves cost on the
80% of corpora that have clean structure.

## The full pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│  INGESTION                                                       │
│  1. Chunk documents (recursive splitter, 300-500 tokens)         │
│  2. For each chunk:                                              │
│     a. Send (full_doc + chunk) to small LLM (Haiku-class)        │
│     b. Get context string (50-100 tokens)                        │
│     c. Prepend context to chunk                                  │
│  3. Embed contextualized chunks ──► Vector DB                    │
│  4. Index contextualized chunks ──► BM25 (Elasticsearch / Tantivy)│
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  QUERY                                                           │
│  query                                                           │
│   ├──► Vector search (top 50)  ───┐                              │
│   │                               ├──► RRF fusion (top 25)       │
│   └──► BM25 search (top 50)  ─────┘         │                    │
│                                              ▼                   │
│                                       Cross-encoder reranker     │
│                                              │                   │
│                                              ▼                   │
│                                       Top-5 ──► LLM generation   │
└──────────────────────────────────────────────────────────────────┘
```

RRF (Reciprocal Rank Fusion) for combining vector + BM25:

```python
def reciprocal_rank_fusion(ranked_lists: list[list[str]], k: int = 60) -> dict:
    scores: dict[str, float] = {}
    for ranked in ranked_lists:
        for rank, doc_id in enumerate(ranked, start=1):
            scores[doc_id] = scores.get(doc_id, 0) + 1 / (k + rank)
    return dict(sorted(scores.items(), key=lambda x: x[1], reverse=True))
```

## When to use Contextual Retrieval

**Use it when:**

- Your corpus has fragmented documents where chunks lose meaning in isolation (legal, financial, medical, technical manuals).
- You have domain-specific jargon embeddings struggle with.
- Your retrieval failure rate exceeds 3-5%.
- You can afford the one-time ingestion cost (~$0.30-$10 per 10K chunks with caching).

**Skip it when:**

- Chunks are already self-contained (FAQ pairs, product cards, structured records).
- Corpus is tiny (< 100 chunks) — just use long-context.
- You need real-time ingestion (< 1s per doc) and can't batch.
- You're using long-context (1M tokens) for the whole corpus — no chunking needed.

## Vs. other RAG enhancements

| Approach | How it works | Improvement | Cost | When |
|---|---|---|---|---|
| Naive chunking | Fixed-size splits | Baseline | Free | Default |
| **Chunk Headers (CCH)** | Prepend doc/section titles | 10-20% | Free | Structured docs |
| **Contextual Retrieval** | LLM-generated context per chunk | **35-49%** | $0.30-$10 per 10K | Most production systems |
| Contextual + Reranking | Above + cross-encoder | **67%** | $0.30-$30 per 10K | High-stakes retrieval |
| HyDE | Hypothetical doc at query time | 20-40% | Per-query LLM cost | Complex queries |
| Parent-Child chunking | Embed children, retrieve parents | 15-30% | Free | Long structured docs |
| Late Chunking (Jina) | Long-context embed then chunk | 25-40% | Embed-only | Dense retrieval only (no BM25 help) |

**Key distinction:** Contextual Retrieval is **ingestion-time** (pay
once). HyDE is **query-time** (pay per query). For high-volume systems,
Contextual Retrieval amortizes much better.

## Production architecture at scale

```
┌─────────────────────────────────────────────────────────────────┐
│ INGESTION SERVICE                                               │
│                                                                 │
│ Document Store ──► Chunker ──► Contextualization Queue          │
│                                       │                         │
│                                ┌──────┴──────┐                  │
│                                │  Workers    │ N parallel       │
│                                │  + Cache    │ LLM calls        │
│                                └──────┬──────┘                  │
│                                       │                         │
│                                       ▼                         │
│                                Contextualized Chunks            │
│                                       │                         │
│                                ┌──────┴──────┐                  │
│                                │  Embed +    │                  │
│                                │  BM25 index │                  │
│                                └──────┬──────┘                  │
│                                       │                         │
│                                       ▼                         │
│                          Vector DB + BM25 Index                 │
└─────────────────────────────────────────────────────────────────┘
```

**Scaling concerns:**

- **Throughput:** parallelize LLM calls (50-100 concurrent workers); rate-limit per Anthropic/OpenAI quota.
- **Updates:** re-contextualize only changed chunks; store raw + context separately so re-embedding is cheap.
- **Quality monitoring:** sample 1% of chunks for human eval of context quality.
- **Atomic index updates:** vector DB + BM25 index must update atomically per document.

## Anti-patterns

- **Sending each chunk's contextualization request without prompt caching.** Burns 10× the necessary cost.
- **Using a frontier model when Haiku-class would do.** No quality gain on factual context generation; cost goes up 30×.
- **Contextualizing already-self-contained chunks (FAQs).** Net negative; the LLM adds noise to chunks that already had everything they needed.
- **Re-contextualizing every chunk on doc update.** Track which chunks changed; only redo those.
- **No BM25 alongside contextual embeddings.** You leave the second 14% on the table by skipping hybrid retrieval.
- **No reranker.** Drops you from 67% improvement back to 49%.
- **Treating CCH as "good enough" for unstructured docs.** CCH works on Markdown headers. On a wall of legal text, you need the LLM.
- **No quality sampling.** Without 1% human eval, you don't notice when the contextualizer starts producing degraded context (model version drift, prompt regression).

## Validation

- [ ] Retrieval failure rate measured before + after — confirmed improvement.
- [ ] Haiku-class model used unless audit demands otherwise.
- [ ] Prompt caching enabled on the document portion.
- [ ] Both Contextual Embeddings AND Contextual BM25 indexes built.
- [ ] RRF fusion of vector + BM25 results before reranking.
- [ ] Cross-encoder reranker on top (Cohere Rerank, BGE reranker, or similar).
- [ ] Re-contextualization triggered only on doc change.
- [ ] 1% quality sampling job on context strings.
- [ ] Atomic vector + BM25 index updates per document.
- [ ] Cost per 10K chunks tracked and monitored.

## References

- Anthropic. "Contextual Retrieval" (September 2024) — the source paper.
- Jina AI. "Late Chunking: Contextual Chunk Embeddings Using Long-Context Embedding Models" (2024).
- Voyage AI. "voyage-context-3: Contextualized Chunk Embeddings" (2025).
- NirDiamant. "RAG Techniques: Contextual Chunk Headers" (GitHub, 2024).
- See also skills: `vector_search_rag_architecture`, `graph_rag`, `production_rag_at_scale`, `prompt_engineering_production` (for caching).
