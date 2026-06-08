---
id: graph_rag
version: 1.0.0
owners: [ml_engineer, architect, database_architect]
tags: [rag, knowledge-graph, graphrag, multi-hop, hipporag, microsoft-graphrag, neo4j]
when_to_use: |
  Vector RAG is plateauing on multi-hop queries — answers that require
  connecting entities across documents that share no surface text. Or
  the corpus is inherently graph-shaped (citations, org charts, code
  intelligence, biomedical pathways). NOT a default upgrade — most RAG
  systems should fix retrieval and reranking first.
inputs:
  - corpus_topology, failed_query_distribution, refresh_cadence, budget
outputs:
  - "graph_rag_design: extraction pipeline + storage + query strategy + maintenance plan"
---

# GraphRAG

> GraphRAG is the combination of Knowledge Graphs and RAG. Vector RAG
> finds *similar text*; GraphRAG follows *connected entities*. It's a
> specialized tool for graph-shaped questions, **not** a default
> upgrade over vector RAG. For ~80% of production workloads, a hybrid
> BM25-plus-dense retriever followed by a cross-encoder reranker is
> cheaper to build, cheaper to operate, and competitive on answer
> quality.

## Don't build a graph until you've earned it

The decision should be data-driven. Pull 100 failed retrievals from
your existing RAG system and tag each into one of three buckets:

| Bucket | What it looks like | Fix |
|---|---|---|
| **Lexical / chunking failures** | The answer was in the corpus, retriever didn't surface it | Better embeddings, hybrid scoring, larger top-k, reranker, contextual_retrieval skill |
| **Synthesis failures** | Right chunks retrieved, generator combined them poorly | Better prompt, reranker, larger generator |
| **Graph-shaped failures** | Answer required a chain of relationships across documents that share no surface text | Build the graph |

**Rule:** if bucket 3 is **< 30%** of failures, do not build a graph.
The construction + maintenance cost will not pay back. If it's ≥ 30%,
GraphRAG (or graph-as-reranker — see below) is the right next investment.

## Workloads where GraphRAG is the right tool

The pattern across all of these: the question requires connecting
entities that do not co-occur in any single chunk, and the relationships
themselves carry semantic weight surface embeddings do not capture.

- **Drug discovery / biomedical** — gene → protein → compound → disease pathways. UMLS-grounded variants (GraLC-RAG) tuned for this.
- **Financial fraud rings** — accounts → devices → locations → transactions across documents that never name each other.
- **Legal precedent chains** — case citations through jurisdictional layers; each case references only its immediate parents.
- **Enterprise policy ownership** — "who approves an exception to policy X in region Y" requires traversing reporting + ownership edges.
- **Code intelligence at repo scale** — call graphs, type hierarchies, dependency edges are inherently graph-shaped; vector similarity over source-code chunks loses the structure.

## The dominant 2026 pattern: graph-as-reranker

Full GraphRAG indexes the entire corpus as a graph. Expensive,
brittle, and overkill for most use cases. The pattern most production
teams converge on instead:

```
┌───────────────────────────────────────────────────────────────┐
│  GRAPH-AS-RERANKER FLOW                                       │
│                                                               │
│  query                                                        │
│    │                                                          │
│    ▼                                                          │
│  Hybrid vector + BM25 ──► top-50 chunks                       │
│                              │                                │
│                              ▼                                │
│              [Entity extractor — small fine-tuned model OR    │
│               structured-output LLM call]                     │
│                              │                                │
│                              ▼                                │
│              [Graph traversal — 1-2 hops from named entities] │
│                              │                                │
│                              ▼                                │
│              expanded candidate set                           │
│              (original 50 + graph-expanded chunks)            │
│                              │                                │
│                              ▼                                │
│              cross-encoder reranker                           │
│                              │                                │
│                              ▼                                │
│              top-k → generator                                │
└───────────────────────────────────────────────────────────────┘
```

**You build only the slice of graph that the query touches, lazily**,
rather than a global graph index. Empirically: ~70-80% of full
GraphRAG's quality lift at ~20% of the upfront cost. Maintenance tail
shrinks because untouched regions are never re-indexed.

## When you actually need full GraphRAG (Microsoft pattern)

For genuine **global summarization** questions — "what are the primary
themes across all 500 employee reviews?" or "summarize the sentiment
of these 10,000 documents" — graph-as-reranker doesn't help.
Microsoft's full GraphRAG architecture earns its keep here:

```
┌─────────────────────────────────────────────────────────────┐
│  PHASE 1 — EXTRACTION (one-time, expensive)                 │
│  Document corpus ──► LLM extracts entities + relations      │
│                       (Person, Project, Date, etc.)         │
│  ──► nodes + edges stored in Neo4j / Memgraph / Cosmos      │
│                                                             │
│  PHASE 2 — COMMUNITY DETECTION                              │
│  Run Leiden algorithm to cluster densely-connected nodes    │
│  into "communities" at multiple resolution levels.          │
│                                                             │
│  PHASE 3 — COMMUNITY SUMMARIES                              │
│  For each community, LLM writes a natural-language summary  │
│  ("This community is about Q3 product launches in EMEA").   │
│  Hierarchical — coarse and fine summaries both stored.      │
│                                                             │
│  QUERY TIME — GLOBAL                                        │
│  Search community summaries instead of raw chunks.          │
│  Compose an answer from relevant community summaries.       │
│                                                             │
│  QUERY TIME — LOCAL                                         │
│  Find a node + traverse its neighborhood.                   │
└─────────────────────────────────────────────────────────────┘
```

This is what allows answering "summarize the sentiment of 1,000 docs"
without putting all 1,000 in context — pre-summarization at index time
compresses the dataset into a queryable hierarchy.

## Variants worth knowing (2024-2026)

| Variant | Best for | Trade-off |
|---|---|---|
| **Microsoft GraphRAG v2 (2025)** | Genuine global summarization workloads | Most expensive; cheapest extraction in v2 |
| **HippoRAG / HippoRAG 2** (Princeton 2024/2025) | Multi-hop benchmarks at lower index cost | Personalized PageRank over memory graph |
| **LightRAG** (HKU 2024) | Faster construction + updates | Trades some recall on global questions |
| **GraLC-RAG** (March 2026) | Biomedical multi-hop QA | UMLS-grounded; very domain-specific |
| **LazyGraphRAG** (Microsoft 2025) | Defer community-summary cost until query time | Lower upfront index cost |

The general direction across all variants: less monolithic indexing,
more incremental / lazy graph construction, clearer separation between
"global summary" workloads (Microsoft-style communities win) and
"local multi-hop" workloads (HippoRAG-style traversal is cheaper).

## Storage choices

| Store | Best for | Notes |
|---|---|---|
| **Neo4j** | General-purpose, mature Cypher | The default; managed (AuraDB) or self-host |
| **Memgraph** | High-throughput, in-memory queries | C++; fast; Bolt protocol |
| **AWS Neptune** | AWS-native, IAM integration | Higher latency than Neo4j; chooses Gremlin or SPARQL |
| **Azure Cosmos DB Gremlin** | Microsoft-stack-native | Pairs naturally with Microsoft GraphRAG pipeline |
| **TigerGraph** | Massive-scale (billions of edges) | Higher operational cost |
| **kuzudb** | Embedded analytics on a graph | Single-binary; good for local + CI tests |

For hybrid systems, also need a vector DB (pgvector / Qdrant / Pinecone)
to bridge "find a starting node" via vector → "expand neighborhood"
via graph.

## Extraction — the bottleneck

Knowledge-graph extraction is token-intensive. Naive cost for a 10K-page
corpus with a frontier model: ~$5K-$15K depending on entity density.

**Mitigations:**

1. **SLM tiered extraction** — small fine-tuned model (Llama-3-8B or similar) does the first pass; frontier model handles conflict resolution between overlapping entities.
2. **Structured output** — extract via JSON schema (see `prompt_engineering_production`) so the parser doesn't choke.
3. **Incremental** — re-extract only changed documents; reconcile entity identity on the diff.
4. **Prompt caching** — the extraction prompt is identical across all chunks; cache the system portion (see `semantic_caching` and prompt caching in `prompt_engineering_production`).

## The maintenance tail

GraphRAG's hidden cost is **not** the initial extraction — it's
maintenance. The corpus drifts: new documents arrive, entities change
names, relationships get rewritten. **A graph built in January is
meaningfully wrong by April.**

Plan for a quarterly refresh that:

1. Re-runs extraction on changed documents.
2. Reconciles entity identity across the diff (merging "Acme Corp" and "Acme Inc." → one node).
3. Re-runs community detection on the changed regions.
4. Re-summarises affected communities.

Budget LLM cost AND engineering time for this refresh upfront, or
don't build the graph. Teams that skip this end up with a graph that
retrieves confidently and wrongly — **worse than no graph at all**.

## Decision flow

```
Need multi-hop reasoning across docs sharing no surface text?
│
├── No ──► Stop. Use hybrid RAG + reranker (see vector_search_rag).
│
└── Yes
        │
        Is the question pattern mostly local (1-2 hops from named entities)?
        │
        ├── Yes ──► Graph-as-reranker (2026 standard). Lazy slicing.
        │
        └── No (global summarization workload)
                │
                Microsoft GraphRAG v2 + community summarization.
                │
                Budget for quarterly maintenance refresh.
                │
                Eval set MUST include global + local questions.
```

## Performance / cost reference

| Approach | Build cost (10M tokens) | Query latency | Quality lift vs vector RAG |
|---|---|---|---|
| Vector RAG (baseline) | $0 (already built) | ~100ms | — |
| Vector + reranker | + $0 | ~200ms | +20-30% |
| Contextual Retrieval (Anthropic) | ~$10-50 | ~200ms | +35-49% |
| Graph-as-reranker (lazy) | ~$100-500 | ~250-350ms | +50-70% |
| Full Microsoft GraphRAG v2 | $500-5,000 | ~300-500ms | +60-80% (global queries only) |
| HippoRAG 2 | $200-1,000 | ~300ms | +50-65% (multi-hop) |

## Anti-patterns

- **Building a graph because RAG "feels wrong"** — without the failed-retrieval-bucket analysis, you'll burn $5K+ and discover the real problem was chunking.
- **Single-pass extraction with a frontier model on every doc.** $$$$. Use SLM tiered extraction.
- **No entity reconciliation.** "Acme Corp", "Acme Inc.", "Acme" become three separate nodes; queries miss connections.
- **No maintenance plan.** Graph rots; serves confidently wrong answers.
- **Treating GraphRAG and vector RAG as either/or.** They're complementary. Vector finds the starting node; graph traverses outward.
- **Storing the entire knowledge graph in one tenant-shared instance** without `tenant_id` per node + edge. Cross-tenant leak via Cypher.
- **Skipping the eval set.** GraphRAG performance is workload-shaped; without a benchmark on YOUR data, you don't know if you're winning.
- **Choosing Microsoft GraphRAG for local multi-hop questions.** Use HippoRAG / LightRAG / graph-as-reranker. Reserve Microsoft for genuine global summarization.

## Validation

- [ ] Failed-retrieval-bucket analysis done; graph-shaped failures ≥ 30%.
- [ ] Pattern chosen: graph-as-reranker (lazy) vs full GraphRAG (global summary) — with rationale.
- [ ] Extraction tier strategy: SLM first-pass + frontier reconciler.
- [ ] Entity reconciliation deduplicates name variants.
- [ ] `tenant_id` on every node + edge for multi-tenant systems.
- [ ] Quarterly maintenance refresh scheduled + budgeted.
- [ ] Eval set covers both local (multi-hop) and global (summarization) queries.
- [ ] Cost monitoring: extraction $$, query latency, refresh $$.
- [ ] Graph DB choice documented + bench-marked for query patterns.
- [ ] Fallback: vector RAG runs in parallel and serves answer if graph traversal returns nothing.

## References

- Edge et al. "From Local to Global: A GraphRAG Approach" (Microsoft Research, 2024)
- Gutiérrez et al. "HippoRAG: Neurobiologically Inspired Long-Term Memory for LLMs" (NeurIPS 2024)
- HippoRAG 2 (Princeton, 2025)
- LightRAG (HKU, 2024)
- GraLC-RAG (arXiv 2603.22633, 2026)
- Neo4j. "Generative AI and Graph Databases" (2025)
- See also skills: `vector_search_rag_architecture`, `contextual_retrieval`, `production_rag_at_scale`, `long_term_memory_systems`.
