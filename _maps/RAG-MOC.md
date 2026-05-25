---
title: RAG-MOC
type: moc
created: 2026-05-25
purpose: Index of the 3-tier RAG engine (naive / advanced / agentic) over MemoryObjects, with evaluation gates
related: [[2026-05-25-brain-upgrade-plan]]
tags: [moc, rag, retrieval, bge-m3, sqlite-vec, hybrid, agentic]
---

# RAG-MOC

Curated index of the workspace-wide retrieval engine per [[RAG_ENGINE_SPEC]] (Module K in [[2026-05-25-brain-upgrade-plan]]). The engine has three tiers that share one MemoryObject store but differ in retrieval sophistication, latency, and cost. **T2 is the default**; T1 is the cheap fallback; T3 only fires for complex multi-hop queries. All tiers are **local-first** (no external API calls in the hot path) per [[RAG_ENGINE_SPEC]] §1.3. This MOC points only — binding truth lives in the spec.

## Spec

- [[RAG_ENGINE_SPEC]] **v1.0.1** (post-fase-3 sweep) — three-tier architecture, hybrid retrieval components, citation-enforcement contract, hard caps.

## T1 — Naive RAG (fallback)

Per [[RAG_ENGINE_SPEC]] §2 — used when T2/T3 are unavailable or for ultra-low-latency lookups (sub-100ms target).

- **Chunking** — fixed paragraph splits (§2.1).
- **Embedding** — **bge-m3**, **1024-dim**, local (§2.2).
- **Storage** — `sqlite-vec` virtual table (§2.3); same MemoryObject store as T2/T3.
- **Retrieval** — top-K cosine over the embedded chunks (§2.4).
- **Generation** — augmented prompt (§2.5).
- **Acceptance** — §2.6 tests.

## T2 — Advanced RAG (primary / default)

Per [[RAG_ENGINE_SPEC]] §3 — the workhorse. All queries default here unless flagged complex.

- **Semantic chunking** — three strategies (§3.1): (a) LLM-as-chunker §3.1.1, (b) sentence-window with embedding similarity §3.1.2, (c) structured distillation per paper [[2603.13017v1]] §3.1.3. Selection table in §3.1.4.
- **Hybrid retrieval** — §3.2 — **BM25 + HNSW + CombMNZ fusion** (§3.2.1 components, §3.2.2 hybrid API, §3.2.3 filter contract).
- **Re-ranking** — §3.3 — **bge-reranker-v2-m3** over the fused candidate set.
- **Citation enforcement** (binding) — §3.4 — every generated claim must cite a MemoryObject `id`; uncited claims are rejected pre-output.
- **Acceptance** — §3.5 tests.

## T3 — Agentic RAG (complex / multi-hop)

Per [[RAG_ENGINE_SPEC]] §4 — escalation tier for complex queries that require iterative retrieval.

- **Orchestrator** — **Claude Opus 4.7** (§4.1).
- **The loop** — retrieve → evaluate → decide (continue / refine / answer) — §4.2.
- **Evaluator** — §4.3 — judges whether the current evidence set is sufficient.
- **Planner** — §4.4 — proposes the next sub-query.
- **Hard caps** (binding) — §4.5 — **max 3 iterations**, max-tokens-per-loop, total-latency budget. Caps prevent runaway agentic spend.

## Evaluation

- [[recall-eval-2026-05-25]] — 10-query gold set (exact-phrase / concept / multi-hop / cross-domain). Acceptance targets: **MRR > 0.6**, **P@1 > 0.5**. Gates Module K landing.

## Related

- [[2026-05-25-brain-upgrade-plan]] §2.K — Module K (RAG) within the broader brain-OS upgrade.
- [[2603.13017v1]] — paper underpinning T2 structured-chunking strategy (§3.1.3) and the eval methodology (stub-allow per NIT 23).
- [[brain-distill-daily]] — feeds the substrate that the RAG engine queries.
- [[Github-Repos-MOC]] — distilled repo notes are retrieval substrate for T2 hybrid queries (e.g. "have we already seen a Rust trading lib?").
- [[MEMORY_DISTILLATION_SPEC]] §6.3 — embedding model decision that propagates to T1/T2 (bge-m3 1024-dim).
- [[Memory-MOC]] — the substrate (MemoryObjects in verbatim + distilled layers) that all three tiers retrieve over.
- [[System-Architecture-MOC]] — parent context.
- `trading-knowledge` — workspace-tier skill whose `_library/trading/lessons/` re-eval trigger (≥30 entries → migrate to pgvector/Chroma) is the most likely first stress test of the T2 hybrid index. (Skill at `~/.claude/skills/trading-knowledge/SKILL.md`; external to brain.)
- [[Youtube-MOC]] — distilled video notes are retrieval substrate for T2 hybrid queries (e.g. "what did Karpathy say about LLM context window?").

## Open questions

- **Stub** — when to migrate from `sqlite-vec` → pgvector/Chroma. Triggered by either: (a) `_library/trading/lessons/` crosses ~30 entries (see `trading-knowledge` re-eval), or (b) p95 T2 latency crosses 500ms.
- **Stub** — T3 budget tuning: Anthropic API spend per agentic query; need observability before defaults are tightened.
- **Stub** — strategy-selection table §3.1.4 needs A/B data once T2 ships; current weights are intuition-based.
- **Stub** — operator-facing CLI for forcing a specific tier (override default T2 → T1 for debugging, T2 → T3 for known-complex queries).

---

*Spec is binding truth. This MOC is a navigation aid for §1–§4; deeper details (DDL, prompt templates, fusion formulas, acceptance harness) live in the spec.*
