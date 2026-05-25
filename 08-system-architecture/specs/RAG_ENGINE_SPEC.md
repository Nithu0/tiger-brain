---
title: RAG Engine Spec (Advanced + Agentic)
date: 2026-05-25
status: v1.0.2
spec_for: Module K (RAG) — brain-upgrade-plan
operator_directive: "mest avanserte system, naive→advanced→agentic"
author: A-7 (sub-agent)
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[MEMORY_DISTILLATION_SPEC]]"
tags:
  - spec
  - rag
  - retrieval
  - agentic
  - bge-m3
  - reranker
  - hybrid
---

# RAG Engine Spec — Advanced + Agentic

> Canonical RAG reference for the workspace brain. Implements Module K of `[[2026-05-25-brain-upgrade-plan]]` and extends Module B (Memory Engine, `[[MEMORY_DISTILLATION_SPEC]]`). Operator directive: *"jeg vil ha det mest avanserte systemet"* — naive only as fallback, advanced as default, agentic for complex queries.

---

## §1 Overview

### 1.1 Three-tier architecture

The RAG engine ships **three tiers** that share infrastructure (embeddings, vector store, BM25 index, `MemoryObject` schema from Module B) but differ in chunking, retrieval, and generation sophistication:

| Tier | Name | When used | Latency | LLM cost |
|---|---|---|---|---|
| T1 | Naive RAG | Fallback when T2 fails; verbatim quote lookup | < 500ms | very low |
| T2 | Advanced RAG | **Default** for all `/brain recall` queries and background distillation | < 3s | low |
| T3 | Agentic RAG | Complex/multi-hop queries via `/brain ask` | < 30s | medium |

**Binding ordering:** T2 is the default. T1 is fallback-only (resilience). T3 is on-demand for complex queries. Operator sees `tier_used` in every response.

### 1.2 Relationship to other modules

- **Module B (Memory Engine, `[[MEMORY_DISTILLATION_SPEC]]`)** — RAG consumes `MemoryObject` rows as primary chunks (paper-structured chunking, Tier 2 strategy (c)). RAG **extends** Memory Engine — does not replace it.
- **Module A (Brain Orchestrator)** — RAG calls are triggered both by operator commands (synchronous) and by orchestrator routines (background distill, dead-link rebuild). See `[[AGENT_ORCHESTRATION_SPEC]]`.
- **Module I (worktree-as-default)** — Tier 3 reasoning traces are committed as `MemoryObject` rows of `source_type: agentic_recall`; auditable per-branch.
- **`[[2026-05-24-onprem-ai-strategi]]`** — when on-prem Tier-2 hardware deployed, T3 orchestrator-LLM switches from Claude Opus 4.7 to local Qwen 72B; vector store can migrate from sqlite-vec to Qdrant via env flag.
- **`[[2603.13017v1]]`** — paper's cross-layer BM25(verbatim) + HNSW(distilled) + CombMNZ result (MRR 0.759, 102% of verbatim baseline 0.745) is the retrieval baseline for Tier 2.

### 1.3 Local-first invariant

All ingestion, embedding, reranking, and storage runs **locally by default**. External APIs (OpenAI embeddings, Cohere rerank, Anthropic generation) require explicit env flags. Data flagged `source_type: sensitive` (refi-docs, regnskap, helse, anything in `.env*`) is **never** routed to external LLMs regardless of flag state. See §12.

---

## §2 Tier 1 — Naive RAG (fallback)

Minimal, deterministic, dependency-light. Ships first; used when T2 components (LLM chunker, reranker model, hybrid index) are unavailable, or when the query is a verbatim quote lookup where naive recall is sufficient.

### 2.1 Chunking — fixed paragraph

- **Strategy:** split source into ~500-token chunks with 50-token overlap. Token count via `tiktoken` (`cl100k_base`).
- **Boundary preference:** paragraph break > sentence break > hard split. Never split mid-word.
- **Per-chunk metadata:** `{chunk_id, source_id, source_path, offset_start, offset_end, char_count, token_count}`.
- **No LLM call** — pure regex + tokenizer. Fast, reproducible, no API cost.
- **File path:** `packages/rag-engine/src/chunking/fixed.ts`.

### 2.2 Embedding — bge-m3 (local)

- **Model:** `BAAI/bge-m3` via `@huggingface/transformers` (Transformers.js, ONNX runtime).
- **Dimensions:** 1024 (operator-spec said 768; bge-m3 is actually 1024-dim — verified against HF model card. T1 uses 1024).
- **Multilingual:** supports Norwegian Bokmål + English (operator's mixed input).
- **Quantization:** FP16 by default (~2.3GB); INT8 fallback (~1.2GB) if RAM-constrained.
- **Load:** once at process start, cached in module-singleton. Cold-start ~4s on CPU, ~1s on GPU.
- **API:** `embed(text: string): Promise<Float32Array>` and `embedBatch(texts: string[]): Promise<Float32Array[]>` (batch size 32).
- **File path:** `packages/rag-engine/src/embedding/bge-m3.ts`.

### 2.3 Storage — sqlite-vec virtual table

- **Library:** [`sqlite-vec`](https://github.com/asg017/sqlite-vec) (successor to sqlite-vss; preferred for new code). Lazy-loaded via `better-sqlite3` extension.
- **Fallback:** if `sqlite-vec` extension fails to load, fall back to `sqlite-vss` with a logged warning; if both fail, fall back to in-memory brute-force cosine (logged as degraded mode).
- **Schema:**
  ```sql
  CREATE VIRTUAL TABLE chunks_vec USING vec0(
    chunk_id TEXT PRIMARY KEY,
    embedding FLOAT[1024]
  );
  CREATE TABLE chunks_meta(
    chunk_id TEXT PRIMARY KEY,
    source_id TEXT NOT NULL,
    source_path TEXT NOT NULL,
    content TEXT NOT NULL,
    offset_start INTEGER, offset_end INTEGER,
    created_at TEXT NOT NULL
  );
  ```
- **File path:** `packages/rag-engine/src/storage/sqlite-vec.ts`.

### 2.4 Retrieval — top-K cosine

- **Query:** `retrieve(q: string, k=10): Promise<Hit[]>`.
- **Steps:** embed query → `SELECT chunk_id, distance FROM chunks_vec WHERE embedding MATCH ? ORDER BY distance LIMIT ?` → join `chunks_meta`.
- **Distance metric:** cosine (sqlite-vec default). Lower = closer.
- **No reranking.** Returns top-K as-is.

### 2.5 Generation — augmented prompt

- **Prompt template** (system + user):
  ```
  [SYSTEM] You have N retrieved chunks. Cite each claim with [ref:<source_id>].
  [USER] <query>
  [CHUNKS]
  <chunk_1.content> (source: <source_id_1>)
  <chunk_2.content> (source: <source_id_2>)
  ...
  ```
- **Model:** Claude Haiku 4.5 by default for T1 (cheap, fast).
- **Citation enforcement:** lightweight — log warning if no `[ref:...]` present, do not retry (T1 is fast-path).

### 2.6 T1 acceptance tests

- Embed + store + retrieve roundtrip in < 50ms for 1k-chunk corpus on dev laptop.
- Top-1 hit is correct for 10 exact-phrase queries (P@1 = 1.0 on verbatim lookup).
- Cold start < 5s including model load.

---

## §3 Tier 2 — Advanced RAG (primary, default)

Where the operator-directive lives. Three chunking strategies, hybrid retrieval, cross-encoder reranking, hard citation enforcement.

### 3.1 Semantic chunking strategies (three)

Strategy is chosen by `source_type`; mapping table at §3.1.4.

#### 3.1.1 Strategy (a) — LLM-as-chunker

- **Model:** Claude Haiku 4.5 (cheap-and-fast; chunking is a high-volume operation).
- **Prompt:** instruct LLM to read source and emit JSON `[{topic_label: "...", chunk_text: "..."}]` split at topic boundaries.
- **Constraints:** chunks 200–800 tokens (model-enforced via post-processing — re-split if over, merge if under). Topic label ≤ 8 words.
- **Output schema:**
  ```typescript
  type SemanticChunk = {
    chunk_id: string;
    source_id: string;
    topic_label: string;          // LLM-generated, ≤ 8 words
    content: string;
    token_count: number;
    method: "llm-chunker" | "sentence-window" | "structured-distill";
    meta?: MemoryObject;          // populated by strategy (c) structured — full MemoryObject attached for downstream filters
  };
  ```
  The `method` field is widened across strategies (a)/(b)/(c). The optional `meta` field is set by strategy (c) only (see §3.1.3) so the orchestrator can reach back to source_ref / project / sensitive flags without an extra DB roundtrip.
- **Used for:** YouTube transcripts, GitHub READMEs, long-form documents (>5k tokens), retrospectives.
- **Cost cap:** $0.01 per source max (Haiku pricing); abort + fall through to (b) if exceeded.
- **File path:** `packages/rag-engine/src/chunking/semantic.ts`.

#### 3.1.2 Strategy (b) — Sentence-window with embedding similarity

- **Algorithm:** split into sentences (`compromise` or `sentence-splitter` NPM lib); embed each sentence; walk pairwise; split where cosine similarity between adjacent sentence-embeddings drops below threshold τ (default `0.55`, tunable).
- **No LLM call** — uses bge-m3 embeddings only. Cheap, deterministic.
- **Window:** sliding 3-sentence context for embedding (each "sentence" embedding is actually the 3-sentence window centered on it, to capture local semantics).
- **Output:** same `SemanticChunk` schema, `method: "sentence-window"`, `topic_label = first-5-words-of-chunk`.
- **Used for:** code files, terminal logs, structured prose where LLM-chunker is overkill.
- **File path:** `packages/rag-engine/src/chunking/sentence.ts`.

#### 3.1.3 Strategy (c) — Structured distillation (paper 2603.13017v1)

- **Per the paper: each `MemoryObject` IS a chunk.** No further sub-splitting.
- **Chunk-text-for-embedding:** `${exchange_core}\n${specific_context}` (paper §3.2 — averages 38 tokens, the "searchable distilled text").
- **Chunk-text-for-display:** the back-referenced verbatim source (paper §3.2 — "the user always reads the unmodified original"). Distilled text is **never shown** to the operator as the answer body — only the verbatim source is rendered, distilled text routes the retrieval (paper §1).
- **Output:** `SemanticChunk` with `method: "structured-distill"`, `topic_label = exchange_core`, plus full `MemoryObject` JSON attached as `meta`.
- **Used for:** conversations, agent task records, commit-derived events — i.e. anything that already passes through Module B.
- **File path:** `packages/rag-engine/src/chunking/structured.ts`.

#### 3.1.4 Strategy selection table

| `source_type` | Primary strategy | Fallback |
|---|---|---|
| `conversation` | (c) structured | (a) LLM-chunker |
| `agentic_recall` | (c) structured | (a) |
| `code_change` | (c) structured | (b) sentence |
| `youtube` | (a) LLM-chunker | (b) sentence |
| `github_repo` | (a) LLM-chunker | (b) sentence |
| `document` | (a) LLM-chunker | (b) sentence |
| `manual_note` | (c) structured | (a) |
| `terminal_log` | (b) sentence | T1 fixed |
| `sensitive` | (b) sentence (local-only) | T1 fixed (local-only) |

Operator can override via `chunking_strategy` field in `MemoryObject.source_ref`.

### 3.2 Hybrid retrieval

Paper §6 / §7 result: cross-layer BM25(verbatim) + HNSW(distilled `specific_context`) + CombMNZ fusion gives MRR 0.759 vs verbatim-baseline 0.745 (102%, statistically significant). This is the Tier 2 baseline we must meet or exceed.

#### 3.2.1 Components

- **BM25 lane** — SQLite FTS5 virtual table over verbatim source text. Stopwords + porter stem. Top-50 candidates.
  - File: `packages/rag-engine/src/retrieval/bm25.ts`.
- **Vector lane** — sqlite-vec HNSW over distilled `specific_context` embeddings (bge-m3, 1024-dim). Top-50 candidates.
  - File: `packages/rag-engine/src/retrieval/vector.ts`.
- **Fusion** — CombMNZ: `score = (norm_bm25 + norm_vec) * num_lanes_hitting`, then sort desc. Top-50 fused.
  - File: `packages/rag-engine/src/retrieval/fusion.ts`.
- **Hybrid orchestrator** — `hybrid.ts` calls both lanes in parallel, fuses, returns top-50 for reranking.
  - File: `packages/rag-engine/src/retrieval/hybrid.ts`.

#### 3.2.2 Hybrid API

```typescript
interface HybridQuery {
  q: string;
  k_per_lane?: number;        // default 50
  filters?: {
    project?: string[];
    source_type?: string[];
    date_after?: string;
  };
}
interface HybridHit {
  chunk_id: string;
  content: string;            // for display: verbatim source
  distilled_text: string;     // for debug/audit only
  source_ref: SourceRef;
  scores: {
    bm25?: number;
    vector?: number;
    combmnz: number;          // final fused
  };
  lane_hits: ("bm25" | "vector")[];
}
async function hybrid(q: HybridQuery): Promise<HybridHit[]>;
```

**Note on `distilled_text`:** this field is **computed at retrieval time** as `${exchange_core}\n${specific_context}` from the matched `MemoryObject` (matching MEMORY_DISTILLATION_SPEC §6.3 embedding text). It is **not a stored column** on `MemoryObject` — it's the concatenation that fed bge-m3 at index-time, surfaced here for debug/audit/rerank-input.

**Note on `source_ref`:** the `SourceRef` interface is defined in MEMORY_DISTILLATION_SPEC §2 and exposes (among other fields) `verbatim_row_id: number` — the integer primary key of the verbatim row in MEMORY's verbatim layer. Citations and display-path resolution use `source_ref.verbatim_row_id` (no `id` field — that's the parent `MemoryObject.id: UUIDv7`).

#### 3.2.3 Filters

Per-query filters applied at SQL-level (not post-fetch) to keep latency tight: `project IN (...)`, `source_type IN (...)`, `created_at > ?`. Filters apply to **both** lanes before top-K selection.

### 3.3 Re-ranking — bge-reranker-v2-m3

- **Model:** `BAAI/bge-reranker-v2-m3` (cross-encoder, ~300MB, multilingual). Loaded via `@huggingface/transformers`.
- **API:** `rerank(query: string, hits: HybridHit[], top_k=10): Promise<HybridHit[]>` — re-scores each `(query, hit.distilled_text)` pair with the cross-encoder, returns sorted top-K.
- **Why cross-encoder over bi-encoder:** the cross-encoder scores `(q, doc)` jointly with full attention — much more accurate than cosine over bge-m3 embeddings, at the cost of higher latency (~10ms per pair on CPU, ~2ms on GPU). For top-50 → top-10, ~500ms CPU / ~100ms GPU.
- **Score field:** writes `hit.scores.rerank` and overrides sort.
- **Timeout:** 2s hard cap. On timeout, log warning + return raw hybrid top-10 (graceful degradation).
- **File path:** `packages/rag-engine/src/rerank/bge-reranker.ts`.

### 3.4 Citation enforcement (binding)

- **Post-generation regex check:** `\[ref:[\w-]+\]` must appear at least once **per paragraph** in the generated answer.
- **On failure:** prepend system message `"Your previous answer lacked citations. Each paragraph MUST include [ref:<source_id>]. Retry."` and call LLM again. Max 2 retries.
- **On final failure:** return answer with `cited: false` flag + log to firm-bus feed (§11). Never silently ship un-cited output.
- **File path:** `packages/rag-engine/src/generation/cite-validate.ts`.

### 3.5 T2 acceptance tests

- 10-query eval-set (built by A-10, see §10): MRR ≥ 0.6, P@1 ≥ 0.5 (operator's bar from `[[2026-05-25-brain-upgrade-plan]]` §4.1 C1-4).
- Stretch: match paper's MRR 0.759 (102% of verbatim).
- p50 latency < 3s; p95 < 5s.
- 100% of returned answers carry `[ref:...]` after enforcement loop.

---

## §4 Tier 3 — Agentic RAG (complex queries)

For multi-hop, exploratory, or cross-domain queries that cannot be answered from a single retrieval pass.

### 4.1 Orchestrator model

- **Default:** Claude Opus 4.7 (operator's preferred model for high-reasoning tasks).
- **Local fallback:** Qwen 72B (or whichever local model is provisioned per `[[2026-05-24-onprem-ai-strategi]]`) when on-prem AI active. Env flag `RAG_AGENTIC_LOCAL=1` forces local.
- **Sensitive data:** if **any** retrieved chunk has `source_type: sensitive`, orchestrator-model is forced to local regardless of flag state (§12).
- **File path:** `packages/rag-engine/src/agentic/loop.ts`.

### 4.2 The loop

```
state = { query, history: [], iter: 0, max_iter: 3 }
while state.iter < state.max_iter:
  hits = T2.retrieve(state.query)                          # full T2: hybrid + rerank
  evaluations = evaluate(state.query, hits)                # LLM scores each chunk 0..1
  plan = planner(state.query, hits, evaluations, history)  # one of: sufficient | refine | abort
  state.history.append({iter, query, hits, evaluations, plan})
  state.iter += 1

  if plan.action == "sufficient":
    return generate(state.query, hits)
  if plan.action == "abort":
    return { answer: null, reason: plan.reason, truncated: false, trace: state.history }
  if plan.action == "refine":
    state.query = plan.refined_query
    continue

# Hit hard cap — return best-so-far
return generate(state.query, best_hits_across_iterations, truncated=true)
```

### 4.3 Evaluator

- **Input:** query + 10 reranked hits from T2.
- **LLM call:** "Score each chunk 0..1 for how directly it answers the query. Return JSON `[{chunk_id, score, brief_reason}]`."
- **Output:** annotated hits with `evaluator_score` field.
- **File:** `packages/rag-engine/src/agentic/evaluator.ts`.

### 4.4 Planner

- **Input:** query, evaluated hits, full history (prior iterations).
- **LLM call:** structured-output (JSON mode or tool-call) with one of three actions:
  - `{action: "sufficient", confidence: 0..1}` — hits answer the query; proceed to generate.
  - `{action: "refine", refined_query: "...", reasoning: "..."}` — current hits insufficient; rephrase or narrow query.
  - `{action: "abort", reason: "..."}` — no path forward (query out of corpus, contradiction, etc.); return null answer with reasoning.
- **Heuristics for planner prompt:**
  - If average `evaluator_score` > 0.7 → strongly prefer `sufficient`.
  - If all hits scored < 0.3 → prefer `refine` with broader/alternative-vocabulary query.
  - If query has been refined twice with no score improvement → `abort`.
- **File:** `packages/rag-engine/src/agentic/planner.ts`.

### 4.5 Hard caps (binding)

| Cap | Value | Action on hit |
|---|---|---|
| Max iterations | 3 | Return best-so-far with `truncated: true` |
| Max input tokens per query | 10,000 | Abort + operator-alert via firm-bus |
| Max output tokens per query | 2,000 | Truncate + log |
| Max wall-clock | 60s | Abort + return partial trace |
| Max LLM calls per query | 7 (3 eval + 3 plan + 1 gen) | Hard ceiling — should never be reached if iter cap respected |

### 4.6 Reasoning trace as MemoryObject

Every agentic query produces an audit record:

```typescript
{
  id: <uuidv7>,
  source_type: "agentic_recall",
  exchange_core: <original query>,
  specific_context: <final refined query + tier_used + iter_count>,
  // Full trace stored in source_ref.extras:
  source_ref: {
    extras: {
      trace: [
        { iter: 0, query, hits: [...], evaluations: [...], plan: {...} },
        ...
      ],
      truncated: boolean,
      cited: boolean,
      cost: { input_tokens, output_tokens, usd_estimate }
    }
  },
  confidence: <final planner.confidence | 0>,
  ...
}
```

Written to `memory_objects` table on every agentic call. Operator can replay any agentic query via `/brain trace <agentic_recall_id>`.

### 4.7 T3 acceptance tests

- 5 multi-hop eval queries answered with `truncated: false` and `cited: true`.
- All agentic queries persist a complete reasoning trace.
- Hard caps observable in dashboard (`/brain/rag`).

---

## §5 Embedding model strategy

### 5.1 Default — bge-m3 (local)

- **Model ID:** `BAAI/bge-m3` (HF).
- **Dimensions:** 1024.
- **Languages:** 100+ including Norwegian Bokmål.
- **Format:** ONNX FP16 (~2.3GB) for runtime; cached at `~/.cache/huggingface/transformers.js/`.
- **Loaded:** once at process start (module singleton). Process startup adds ~4s on CPU.
- **Throughput target:** 64 chunks/s on CPU (M1/Ryzen 5+), 500 chunks/s on GPU.

### 5.2 Fallback — OpenAI text-embedding-3-large

- **Activated only by:** `RAG_EMBEDDING_FALLBACK_OPENAI=1`.
- **Dimensions:** 3072 (must keep separate `chunks_vec_openai` table — schemas incompatible). Migration script `scripts/embedding-migrate.ts` re-embeds existing corpus when flipping providers.
- **Why available at all:** dev-machine cold-start, model-download failure, comparison benchmarks.
- **Never used for `sensitive` data** — enforced in `embedding/provider.ts` (§5.4).

### 5.3 Provider dispatch

```typescript
// packages/rag-engine/src/embedding/provider.ts
async function embed(text: string, opts?: { sensitive?: boolean }): Promise<Float32Array> {
  if (opts?.sensitive) return embedLocal(text);   // forced local, never external
  if (process.env.RAG_EMBEDDING_FALLBACK_OPENAI === "1" && !localAvailable()) {
    log.warn("embedding-fallback", "Using OpenAI fallback");
    return embedOpenAI(text);
  }
  return embedLocal(text);
}
```

### 5.4 Local-only enforcement

Any caller passing a `MemoryObject` where `source_type === "sensitive"` OR `source_ref.local_only === true` is routed to local embedding only. Provider throws `LocalOnlyViolation` if external is attempted on such data — caller bug, not user error.

---

## §6 Re-ranker model

### 6.1 Default — bge-reranker-v2-m3 (local)

- **Model ID:** `BAAI/bge-reranker-v2-m3` (HF).
- **Type:** cross-encoder.
- **Size:** ~300MB ONNX FP16.
- **Latency:** ~10ms per `(q, doc)` pair on CPU; ~2ms on GPU. Top-50 → top-10 = ~500ms CPU / ~100ms GPU.
- **Languages:** multilingual (same family as bge-m3).

### 6.2 Fallback — Cohere rerank-v3

- **Activated only by:** `RAG_RERANK_FALLBACK_COHERE=1`.
- **Never used for `sensitive` data** — same enforcement as §5.4.
- **Use case:** local model unavailable, comparison benchmarks.

### 6.3 Graceful degradation

If reranker (local or fallback) times out (`>2s`) or errors:
1. Log warning to firm-bus.
2. Return raw hybrid top-10 (no rerank).
3. Flag response with `reranked: false`.

The system **never blocks** on reranker failure — T2 retrieval must always return.

---

## §7 Vector store

### 7.1 Default — sqlite-vec

- **Why:** in-process (zero ops overhead), survives Litestream replication, file-portable, ACID.
- **Limits:** designed for up to ~1M vectors; we expect ~100k–500k after 2 years of brain content. Comfortable headroom.
- **Schema:** see §2.3.
- **Indexing:** HNSW (sqlite-vec default, M=16, ef_construction=200).

### 7.2 Migration path — Qdrant

- **Activated by:** `RAG_VECTOR_STORE=qdrant` (lazy import — `qdrant-js-client` not loaded unless flag set).
- **Trigger conditions:** vector count > 500k, OR on-prem AI Tier-2 hardware deployed, OR operator-explicit migration.
- **Migration tool:** `scripts/vector-migrate-sqlite-to-qdrant.ts` — reads all rows from sqlite-vec, batch-inserts to Qdrant, swaps env flag, runs eval-set to confirm no regression.
- **Provider abstraction:** `packages/rag-engine/src/storage/provider.ts` exposes `VectorStore` interface that sqlite-vec and qdrant adapters both implement. Switching is one-line config change.

### 7.3 Schema migrations

All schema changes go through `packages/rag-engine/migrations/NNN-*.sql` with up + down. Migrations run via existing `@cc/sync` migration framework. Vector dimensions are immutable per table — dimension change requires new table + reindex.

---

## §8 Generation

### 8.1 Augmented prompt construction

```typescript
function buildPrompt(query: string, hits: HybridHit[]): { system: string; user: string } {
  const chunks = hits.map((h, i) =>
    `[chunk_${i+1}] verbatim_row_id=${h.source_ref.verbatim_row_id} path=${h.source_ref.file_path}
${h.content}`
  ).join("\n\n");

  return {
    system: `You answer the operator's question using ONLY the retrieved chunks below.
Cite every claim with [ref:<verbatim_row_id>]. Each paragraph MUST contain at least one citation.
If the chunks do not contain the answer, say so explicitly — do not fabricate.
Respond in the same language as the query (Norwegian Bokmål or English).`,
    user: `Query: ${query}\n\nRetrieved chunks:\n${chunks}`
  };
}
```

- File: `packages/rag-engine/src/generation/augment.ts`.

### 8.2 Generation model

- **Default:** Claude Opus 4.7 (high quality; operator-preferred).
- **Override:** `RAG_GENERATION_MODEL=<model_id>` env or per-call option.
- **For T1 fast-path:** Claude Haiku 4.5 (cheaper, faster, lower accuracy acceptable for fallback tier).
- **For sensitive data:** local model only (per §12).

### 8.3 Citation regex validation + retry

```typescript
const CITATION_RE = /\[ref:[\w-]+\]/;
function validateCitations(answer: string): { ok: boolean; missing_paragraphs: number[] } {
  const paragraphs = answer.split(/\n\s*\n/).filter(p => p.trim().length > 0);
  const missing = paragraphs
    .map((p, i) => CITATION_RE.test(p) ? null : i)
    .filter((i): i is number => i !== null);
  return { ok: missing.length === 0, missing_paragraphs: missing };
}
```

- Retry loop: max 2 retries; if still failing, return answer with `cited: false` warning.
- File: `packages/rag-engine/src/generation/cite-validate.ts` + `retry.ts`.

### 8.4 Streaming

Generation supports streaming via Anthropic SDK's stream interface. Citations validated post-stream-complete (cannot enforce mid-stream). UI shows answer as it arrives; "verified citations" badge appears after stream completes.

---

## §9 Query routing

### 9.1 Routing table

| Query type / command | Tier | Latency target | Cost tier | Default model |
|---|---|---|---|---|
| `/brain recall "..."` | T2 | < 3s | low | Haiku 4.5 (gen) |
| `/brain ask "..."` | T3 | < 30s | medium | Opus 4.7 (gen) |
| `/brain quote "..."` (verbatim phrase lookup) | T1 | < 500ms | very low | Haiku 4.5 |
| `/brain debug "..."` (return raw chunks, no gen) | T2 retrieve only | < 1s | very low | none |
| Background distill (orchestrator) | T2 batch | n/a | low | Haiku 4.5 |
| `MemoryObject` insert → auto-embed | embed only | < 100ms/chunk | very low | none |

### 9.2 Router implementation

```typescript
// packages/rag-engine/src/router/query-router.ts
function route(input: string): { tier: "T1" | "T2" | "T3"; intent: string } {
  if (input.startsWith("/brain quote ")) return { tier: "T1", intent: "verbatim" };
  if (input.startsWith("/brain debug ")) return { tier: "T2", intent: "debug" };
  if (input.startsWith("/brain ask "))   return { tier: "T3", intent: "complex" };
  if (input.startsWith("/brain recall ")) return { tier: "T2", intent: "recall" };
  // Ambiguous: classify with LLM
  return classifyWithLLM(input);
}
```

- LLM classification fallback uses Haiku with a 3-class output (`recall | complex | verbatim`). Cached per-prefix to keep amortized cost ~zero.
- Operator override: `--tier=T3` flag on any command forces tier.

### 9.3 Cost preview

Before T3 dispatch, router returns a cost estimate (`{ estimated_tokens, estimated_usd, estimated_seconds }`) to UI. Operator can cancel before LLM calls fire.

---

## §10 Evaluation framework

Per operator's "verifiser 5×" policy from `[[2026-05-25-brain-upgrade-plan]]` §11.

### 10.1 Eval set construction

- **Built by:** A-10 sub-agent (per `[[2026-05-25-brain-upgrade-plan]]` §4.3).
- **Location:** `08-system-architecture/eval/recall-eval-2026-05-25.md`.
- **Size:** 10 queries minimum, growing to 50 over Q3.
- **Per-query schema:**
  ```yaml
  - id: Q-001
    query: "what did we decide about worktree-as-default"
    gold_hits:                   # operator-curated source_ids
      - 2026-05-25-brain-upgrade-plan#module-i
      - inbox/code-2.md#2026-05-25T10:00Z
    query_type: recall           # recall | complex | verbatim
    notes: "vague recall, two valid hits"
  ```
- **Annotation:** operator marks 1–3 gold hits per query; ties allowed.

### 10.2 Metrics (binding)

Per release / per nightly run:

| Metric | Target | Stretch |
|---|---|---|
| **MRR** (mean reciprocal rank of first gold hit) | ≥ 0.6 | ≥ 0.759 (paper baseline) |
| **nDCG@10** (normalized discounted cumulative gain) | ≥ 0.65 | ≥ 0.80 |
| **P@1** (precision at rank 1) | ≥ 0.5 | ≥ 0.7 |
| **Citation rate** (% answers with valid `[ref:]`) | 100% | 100% |
| **p50 latency T2** | < 3s | < 1.5s |
| **p95 latency T2** | < 5s | < 3s |
| **p95 latency T3** | < 60s | < 30s |

### 10.3 Regression gate (binding)

- Before any merge to `main` of a `packages/rag-engine/**` change, CI runs the eval-set.
- If **any** metric drops > 10% relative to the previous main-branch baseline, **block merge**. Surface diff in PR comment.
- Manual override requires operator OK kjør in PR comment.

### 10.4 Eval CLI

```bash
npx rag-eval --set eval/recall-eval-2026-05-25.md --tier T2 --report eval/runs/$(date +%F).json
```

Output: per-query rank, score, comparison to baseline, summary table.

---

## §11 Failure modes + operator-alerts

All failures route to firm-bus `~/Obsidian/Brain/00-firm-bus/feed.md` (REPORT-only — never auto-fix).

| Failure | Detection | Action | Operator-alert |
|---|---|---|---|
| Embedding model not loaded | `embedLocal()` throws | Fall back to OpenAI if flag set; else fail T2, fall back to T1 | Yes, single warning per process |
| Re-ranker timeout (>2s) | Promise.race | Skip rerank, return raw hybrid top-10, `reranked: false` | Log warning, no immediate alert |
| Agentic loop hits 3-iter cap | counter | Return best-so-far + `truncated: true` | Log to feed, surface in `/brain/rag` dashboard |
| Agentic input-token cap exceeded (10k) | tiktoken | Abort, return null answer | **Immediate firm-bus alert** |
| Citation validation fails 2× | regex | Return answer with `cited: false` | Log warning + dashboard counter |
| Vector store query timeout (>5s) | Promise.race | Fall back to brute-force in-memory cosine on cached embeddings | **Immediate firm-bus alert** + counter |
| sqlite-vec extension load fail | startup probe | Fall back to sqlite-vss → in-memory cosine | **Immediate firm-bus alert** + read-only mode |
| All retrieval lanes empty | post-fusion check | Return `{ answer: null, reason: "no_results", hits: [] }` | Log; no alert (legitimate) |
| Provider 401 (OpenAI/Anthropic) | HTTP status | Surface in dashboard; fall back to local | **Immediate firm-bus alert** |
| Sensitive data routed external | provider guard | Throw `LocalOnlyViolation` (caller bug) | **Immediate firm-bus alert** + log to audit |

Alert format (firm-bus):
```
[2026-05-25T14:32Z] RAG ALERT tier=T3 module=agentic.loop event=token_cap_exceeded
  query="..."
  details={ input_tokens: 12450, cap: 10000 }
  trace_id=<uuid>
```

---

## §12 Privacy + security (binding)

### 12.1 Default invariants

1. **Local-first.** All ingestion, embedding, reranking, storage runs locally. External APIs are opt-in via explicit env flag.
2. **Sensitive flag.** `source_type: sensitive` is a routing tag. Set by:
   - Folder convention: anything under `/home/nithu/Obsidian/Brain/{regnskap,refi,helse}/` auto-tagged.
   - Filename pattern: `.env*`, `*credentials*`, `*secret*`, `*.key`, `*.pem` auto-tagged (and embedding refused entirely for files matching these patterns).
   - Frontmatter: `sensitive: true` in YAML frontmatter.
3. **Sensitive data routing:** sensitive `MemoryObject`s are:
   - Embedded only with local model (bge-m3). Fallback to OpenAI is **refused**.
   - Reranked only with local model. Fallback to Cohere is **refused**.
   - Generated against only with local model (when on-prem AI active). Otherwise **rejected with error** — no external LLM call.
4. **Citation hashing for sensitive sources:** citations include `[ref:sha256:<hex8>]` instead of `[ref:<filepath>]` to avoid leaking path info in transcripts that may be shared. Operator dashboard resolves hash → path locally.

### 12.2 Secrets — never embed

Files matching the sensitive patterns above are **not embedded at all**. The chunker refuses with a logged warning. This is a defense in depth: even if a future bug routes a sensitive chunk to external embeddings, the embedding never existed.

### 12.3 No secret in vector metadata

The vector store metadata table (`chunks_meta`) is constrained by schema to `chunk_id, source_id, source_path, content, offsets, timestamps`. No API keys, no env values, no PII. A pre-commit hook scans new migrations against this whitelist.

### 12.4 Audit log

Every external API call (when fallback flags set) writes a row to `rag_external_calls`:
```sql
CREATE TABLE rag_external_calls(
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL,
  provider TEXT NOT NULL,   -- 'openai' | 'cohere' | 'anthropic'
  endpoint TEXT NOT NULL,
  input_tokens INT,
  output_tokens INT,
  usd_estimate REAL,
  sensitive_check_passed INTEGER NOT NULL DEFAULT 1
);
```
Operator views via `/brain/rag/audit`. Any row with `sensitive_check_passed=0` is a bug — alert immediately.

---

## §13 Anti-patterns (binding)

1. **Never ship T1 alone as default.** Operator directive: most-advanced system. T1 is fallback only.
2. **Never let agentic loop > 3 iterations.** Hard-coded constant, not env-tunable. Anti-infinite-loop, anti-cost-runaway.
3. **Never embed API keys into vector store metadata.** Enforced by schema whitelist + pre-commit scan.
4. **Never delete verbatim source.** Distilled is the index, source is the truth. Verbatim retention is forever (or until operator manually purges).
5. **Never show distilled-only content to operator as answer.** Always cite + render verbatim source path. Distilled text is internal-only routing artifact (per paper §3.2).
6. **Never embed sensitive data with external provider** — local-only enforcement (§12.1).
7. **Never auto-disable a tier** based on anomaly detection. Health-check reports to firm-bus; operator decides handling (per `~/.claude/CLAUDE.md` rule).
8. **Never silently degrade tier.** Every response carries `tier_used`, `reranked`, `cited`, `truncated` flags. Operator always knows what they got.
9. **Never cache LLM responses across users.** This is a single-operator brain; no multi-user cache pollution risk by design — but reaffirmed for any future shared deployment.
10. **Never bypass the citation enforcement loop** (max 2 retries then `cited: false`). Skipping is a code-review block.

---

## §14 Code skeleton — `packages/rag-engine/`

```
packages/rag-engine/
  package.json
  tsconfig.json
  src/
    index.ts                          # public API barrel

    chunking/
      fixed.ts                        # T1 — paragraph 500/50
      semantic.ts                     # T2 strategy (a) — LLM chunker (Haiku)
      sentence.ts                     # T2 strategy (b) — sentence-window
      structured.ts                   # T2 strategy (c) — MemoryObject as chunk
      provider.ts                     # dispatches by source_type → strategy

    embedding/
      bge-m3.ts                       # local via @huggingface/transformers
      openai.ts                       # fallback (flag-gated)
      provider.ts                     # dispatcher + sensitive guard

    storage/
      sqlite-vec.ts                   # default vector store
      qdrant.ts                       # lazy-loaded migration target
      provider.ts                     # VectorStore interface

    retrieval/
      bm25.ts                         # SQLite FTS5 verbatim lane
      vector.ts                       # sqlite-vec HNSW distilled lane
      fusion.ts                       # CombMNZ
      hybrid.ts                       # orchestrates both lanes + fusion

    rerank/
      bge-reranker.ts                 # local cross-encoder
      cohere.ts                       # fallback (flag-gated)
      provider.ts                     # dispatcher + sensitive guard

    agentic/
      loop.ts                         # T3 main loop (max 3 iter)
      evaluator.ts                    # LLM scores chunks 0..1
      planner.ts                      # sufficient | refine | abort
      caps.ts                         # token + time + iter caps

    generation/
      augment.ts                      # builds prompt
      cite-validate.ts                # regex + retry
      retry.ts                        # generation retry wrapper
      provider.ts                     # default Opus 4.7, configurable

    router/
      query-router.ts                 # /brain recall|ask|quote|debug
      classifier.ts                   # LLM fallback for ambiguous

    eval/
      runner.ts                       # eval-set executor
      metrics.ts                      # MRR, nDCG, P@1

    audit/
      firm-bus.ts                     # writes alerts to feed.md
      external-calls.ts               # logs to rag_external_calls

  examples/
    naive.ts                          # T1 demo
    advanced.ts                       # T2 demo
    agentic.ts                        # T3 demo

  tests/
    chunking/                         # 1 test file per strategy
    embedding/
    retrieval/
    rerank/
    agentic/
    generation/
    router/
    integration/                      # end-to-end eval-set run

  migrations/
    001-create-chunks.sql
    002-create-fts.sql
    003-create-vec.sql
    004-rag-external-calls.sql

  scripts/
    embedding-migrate.ts              # re-embed corpus on provider switch
    vector-migrate-sqlite-to-qdrant.ts
    eval.ts                           # CLI eval runner
```

### 14.1 Dependencies

```json
{
  "dependencies": {
    "@anthropic-ai/sdk": "^0.30.0",
    "@huggingface/transformers": "^3.0.0",
    "better-sqlite3": "^11.0.0",
    "sqlite-vec": "^0.1.0",
    "tiktoken": "^1.0.0",
    "compromise": "^14.0.0",
    "uuid": "^10.0.0"
  },
  "optionalDependencies": {
    "openai": "^4.0.0",
    "cohere-ai": "^7.0.0",
    "@qdrant/js-client-rest": "^1.0.0"
  },
  "devDependencies": {
    "vitest": "^2.0.0",
    "@types/better-sqlite3": "^7.0.0"
  }
}
```

Optional deps only loaded when their respective env flags set. Default install footprint stays small (no OpenAI/Cohere/Qdrant unless asked).

---

## §15 Acceptance tests

### 15.1 Per-tier acceptance

**T1 (Naive):**
- [ ] Embed + store + retrieve roundtrip in < 50ms for 1k-chunk corpus.
- [ ] P@1 = 1.0 on 10 exact-phrase verbatim queries.
- [ ] Cold-start including model load < 5s.

**T2 (Advanced) — primary gate:**
- [ ] Eval-set MRR ≥ 0.6 (target 0.759 per paper).
- [ ] Eval-set P@1 ≥ 0.5.
- [ ] Eval-set nDCG@10 ≥ 0.65.
- [ ] 100% citation rate after enforcement loop.
- [ ] p50 latency < 3s, p95 < 5s on 10k-chunk corpus.
- [ ] All three chunking strategies produce valid `SemanticChunk` rows for representative sources.
- [ ] Hybrid retrieval returns results from both BM25 and vector lanes (verify lane_hits coverage).

**T3 (Agentic):**
- [ ] 5 multi-hop eval queries complete with `truncated: false, cited: true`.
- [ ] Hard cap (3 iter, 10k input, 2k output, 60s wall) observable in trace.
- [ ] Every agentic query persists complete reasoning trace as `MemoryObject(source_type: agentic_recall)`.
- [ ] Operator can replay any trace via `/brain trace <id>`.

### 15.2 Cross-cutting acceptance

- [ ] Sensitive data (test fixture in `tests/fixtures/sensitive/`) never reaches external API even with all fallback flags set. Audit log shows zero `sensitive_check_passed=0` rows after full eval run.
- [ ] Citation validation rejects + retries un-cited output; logs final `cited: false` only when both retries fail.
- [ ] Vector store migration script (sqlite-vec → Qdrant) preserves eval-set MRR within 1% delta.
- [ ] Reranker timeout falls through to raw hybrid without erroring the request.
- [ ] All env-flag fallbacks (`RAG_EMBEDDING_FALLBACK_OPENAI`, `RAG_RERANK_FALLBACK_COHERE`, `RAG_VECTOR_STORE=qdrant`, `RAG_AGENTIC_LOCAL=1`) toggle correctly without code change.

### 15.3 Latency benchmark targets

| Tier | p50 | p95 | p99 |
|---|---|---|---|
| T1 retrieve | 50ms | 100ms | 200ms |
| T1 retrieve + generate | 800ms | 1.5s | 3s |
| T2 retrieve | 400ms | 800ms | 1.5s |
| T2 retrieve + rerank | 900ms | 1.8s | 3s |
| T2 retrieve + rerank + generate | 2.5s | 4.5s | 8s |
| T3 full loop (1 iter, sufficient) | 6s | 12s | 20s |
| T3 full loop (3 iter, refine) | 18s | 40s | 60s |

Benchmarks reproducible via `npm -w @cc/rag-engine run bench` on dev laptop (CPU baseline).

---

## §16 Cross-refs

- `[[2026-05-25-brain-upgrade-plan]]` — Module K anchor, §2.K full architecture; §11 verifiser-5x policy this spec respects.
- `[[MEMORY_DISTILLATION_SPEC]]` — Module B (Memory Engine) — RAG consumes `MemoryObject` rows; chunking strategy (c) IS the paper-structured distillation.
- `[[AGENT_ORCHESTRATION_SPEC]]` — Module A (Brain Orchestrator) — schedules background distill calls; routes operator commands.
- `[[OBSIDIAN_BRAIN_STRUCTURE]]` — frontmatter conventions that the chunker reads (e.g. `sensitive: true`, `source_type:`).
- `[[SKILL_REGISTRY_SPEC]]` — `/brain recall` and `/brain ask` are exposed as skills.
- `[[2026-05-24-onprem-ai-strategi]]` — Tier-2 hardware enables local Qwen 72B as T3 orchestrator; Qdrant as production vector store.
- `[[2603.13017v1]]` — *Structured Distillation for Personalized Agent Memory*, Sydney Lewis March 2026 — paper-baseline for cross-layer retrieval (MRR 0.759), four-field MemoryObject schema, two-tier architecture (distilled-as-index, verbatim-as-display).

---

## §17 5× verify (per operator policy)

Per `[[2026-05-25-brain-upgrade-plan]]` §11:

1. **All three tiers fully specified** — chunking (§2.1, §3.1×3, §2.1 fallback), embedding (§5), retrieval (§2.4, §3.2, §4.2), rerank (§6), generation (§8) covered for T1/T2/T3 each. **PASS.**
2. **Privacy policy explicit** — §12 binds sensitive-flag routing, local-only enforcement, no external for sensitive (§12.1.3), citation hashing for sensitive sources (§12.1.4), no secrets in vector metadata (§12.3), audit log (§12.4). **PASS.**
3. **Hard caps numeric** — agentic max 3 iter (§4.5), max 10k input + 2k output tokens (§4.5), max 60s wall (§4.5), max 2 citation retries (§3.4, §8.3), reranker 2s timeout (§3.3, §6.3), vector store 5s timeout (§11), embedding throughput 64 chunks/s CPU (§5.1), latency targets per tier (§15.3). **PASS.**
4. **Eval framework concrete** — MRR + nDCG@10 + P@1 with numeric targets (§10.2), eval-set built by A-10 with documented schema (§10.1), regression gate at 10% drop blocks merge (§10.3), CLI runner (§10.4). **PASS.**
5. **Anti-patterns explicit + enforceable** — §13 lists 10 binding anti-patterns each with enforcement mechanism (schema whitelist, pre-commit scan, hard-coded constant, code-review block). **PASS.**

All 5 checks pass. Spec ready for code-1 lane (per `[[2026-05-25-brain-upgrade-plan]]` §4.1 C1-4 retrieval task).

---

*Sist oppdatert: 2026-05-25 av A-7 (sub-agent), B-2-fixes 2026-05-25. Status: v1.0.1 — CRITICAL alignment fixes applied. Implementeres etter MEMORY_DISTILLATION_SPEC + AGENT_ORCHESTRATION_SPEC er på plass (deler `MemoryObject` schema + `agent_tasks` kø).*

---

## Changelog
- 2026-05-25 v1.0.2 — frontmatter YAML fix (block-list form): converted inline `related: [[X]], [[Y]]` flow-list to block-list with quoted wikilink strings; converted inline `tags: [...]` flow-list to block-list. Body untouched.
- 2026-05-25 v1.0.1 — applied B-2 CRITICAL fixes:
  - `source_ref.id` → `source_ref.verbatim_row_id` (alignment with MEMORY_DISTILLATION_SPEC verbatim layer PK; per Integration Notes A.1.3 / B-2 CRIT #5). Affected: §8.1 `buildPrompt` (chunk header field + system-prompt citation token `[ref:<verbatim_row_id>]`).
  - sqlite-vec confirmed as primary; sqlite-vss appears only as documented fallback at §2.3, §11 (alignment with MEMORY_DISTILLATION_SPEC C-1 fix; per Integration Notes F.3 / B-2 CRIT #6). No edits needed — pre-existing wording already correct.
  - Applied MEDIUMs:
    - D.3: clarified `HybridHit.distilled_text` is computed at retrieval time as `${exchange_core}\n${specific_context}`, not a stored column. Added explicit `source_ref` note pointing at `verbatim_row_id`. (§3.2.2)
    - D.4: added `meta?: MemoryObject` field to `SemanticChunk` type; widened `method` union to all three strategies. (§3.1.1)
  - Did NOT apply (still NIT, deferred):
    - A.1.5 / NIT #22: `chunking_strategy` override on `source_ref` (§3.1.4 trailer) — left as-is pending decision in MEMORY_DISTILLATION_SPEC about request-level options object vs source_ref override.
