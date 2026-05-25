---
title: Memory-MOC
type: moc
created: 2026-05-25
purpose: Index of the two-stage memory-distillation system — verbatim FTS5 layer + distilled sqlite-vec layer + MemoryObject schema + trigger sources
related: [[2026-05-25-brain-upgrade-plan]]
tags: [moc, memory, distillation, memory-objects, brain-upgrade]
---

# Memory-MOC

Curated index of the workspace-wide memory system per [[MEMORY_DISTILLATION_SPEC]] (Module B in [[2026-05-25-brain-upgrade-plan]]). The system has two layers: a **verbatim** layer (raw conversations + actions, FTS5-indexed, never deleted) and a **distilled** layer (semantic MemoryObjects, embedded with bge-m3, queried by the RAG engine). Distillation runs on multiple triggers (per-action, per-conversation, nightly, per-ingest, manual). This MOC points only — binding truth always lives in the spec.

## Spec

- [[MEMORY_DISTILLATION_SPEC]] **v1.0.2** (post-fase-3, C-1 update) — single source of truth for layer schemas, distillation prompt template, surviving-vocabulary enforcement, migration pipeline, and acceptance tests.

## Schema (MemoryObject)

The binding TypeScript interface for distilled entries lives in [[MEMORY_DISTILLATION_SPEC]] §2 (`MemoryObject` interface). Fields cover `id`, `kind` (action/conversation/note/youtube/github/etc.), `project`, `created_at`, `surviving_vocabulary`, `summary`, `back_refs`, `embedding_model`, `fingerprint`. Frontmatter template for human-readable mirrors lives in [[00-templates/memory-object]].

## Verbatim layer (raw)

Per [[MEMORY_DISTILLATION_SPEC]] §5 — append-only SQLite table, FTS5 virtual index for exact-phrase search, never-delete invariant. Sources:

- command-center `audit_log` rows (per-action records — tool calls, file writes, bus messages)
- Claude conversation transcripts (per-conversation finalisation)
- raw transcripts from `12-youtube/_library/...` (per-ingest)
- raw repo metadata + README snapshots from GitHub discovery (per-ingest)

API surface in §5.2 — `verbatim.put(...)` / `verbatim.search(query, k)` / `verbatim.get(id)`. Used as fall-back when the distilled layer misses (e.g. exact-quote lookup).

## Distilled layer (semantic)

Per [[MEMORY_DISTILLATION_SPEC]] §6 — `MemoryObject` rows in SQLite + `sqlite-vec` virtual table holding **bge-m3** embeddings (**1024-dim**, local-first per [[RAG_ENGINE_SPEC]] §1.3). Each MemoryObject has a fingerprint for dedup (per §9.2 acceptance test) and a `surviving_vocabulary` field that the distillation prompt is required to preserve verbatim (per §3.3, enforced post-hoc).

API in §6.2 — `distilled.put(obj)` / `distilled.search(query, k, filters)` / `distilled.delete(id)`. Embedding details in §6.3.

## Trigger sources

When distillation runs (per [[MEMORY_DISTILLATION_SPEC]] §4 + [[AGENT_ORCHESTRATION_SPEC]] §8.1):

| Trigger | Cadence | Source | Output |
|---|---|---|---|
| Per-action | event-driven | `audit_log` insert | one verbatim row; distilled row only if heuristic-passes |
| Per-conversation | end-of-conversation Stop hook | Claude transcript | one verbatim row + one distilled row |
| Nightly | cron 03:00 local via [[brain-distill-daily]] | yesterday's audit_log + transcripts | batched distill; dedup against existing MemoryObjects |
| Per-ingest | event-driven | YouTube + GitHub queues drain | one verbatim row + one distilled row per item |
| Manual | operator-invoked | `brain-distill-daily YYYY-MM-DD` | replay distill for a past date |

## Quality + migration

- **Quality checks** — §7 (vocab survival, fingerprint dedup, back-ref integrity).
- **Migration pipeline** — §8 — existing hand-authored brain notes lifted into MemoryObjects without mutating originals (verified §8.3).
- **Acceptance tests** — §9 — vague-recall MRR, dedup, verbatim survival, surviving-vocabulary, back-ref. Gates landing of Module B.

## Related

- [[2026-05-25-brain-upgrade-plan]] §2.B — Module B (memory) within the broader brain-OS upgrade.
- [[2603.13017v1]] — paper on structured distillation; informs §3 prompt template + §9.1 vague-recall MRR test (stub-allow per NIT 23).
- [[00-templates/memory-object]] — frontmatter template for human-readable mirrors.
- [[brain-distill-daily]] — the brain-tier skill that wraps the nightly trigger.
- [[Distillation-Hook]] · [[Distillation-Stop-Hook]] — pre-spec hook scaffolding that the new orchestrator-driven flow replaces.
- [[Github-Repos-MOC]] — discovery emits one verbatim row + one distilled MemoryObject per repo note (per-ingest trigger).
- [[Memory-Lifecycle]] — legacy RAW → DISTILLED → PROMOTED → DEPRECATED → ARCHIVED model; superseded by the spec but retained for promotion semantics.
- [[RAG-MOC]] — the retrieval engine that consumes the distilled layer (and falls back to the verbatim layer for exact-phrase).
- [[Retrospectives-MOC]] — weekly roll-up pulls distilled `kind: decision` MemoryObjects into the Decisions section.
- [[Skills-MOC]] — brain-tier skills emit distillation triggers (`brain-distill-daily`, `youtube-ingest`, `github-discover`) that write into both layers.
- [[System-Architecture-MOC]] — parent context (Module B is one node in the upgrade graph).
- [[Truth-Hierarchy]] — where distilled memory sits in the read-order (below operator-decisions, above raw scratchpads).
- [[Youtube-MOC]] — ingest emits one verbatim row + one distilled MemoryObject per video (per-ingest trigger).

## Legacy hierarchy (pre-distillation)

The earlier per-project memory hierarchy — `~/.claude/CLAUDE.md` (global) → `<workspace>/CLAUDE.md` → `<repo>/CLAUDE.md` → `~/.claude/projects/<slug>/memory/` — remains the **session-loading** mechanism. It is orthogonal to the distillation system: CLAUDE.md files are operator-curated context; MemoryObjects are machine-distilled retrieval substrate. See [[Global-CLAUDE-md]] · [[Session-Start-Hook]] for the loading path.

## Open questions

- **Stub** — when does the distilled layer cross the size threshold that forces a move from `sqlite-vec` to a real vector DB (pgvector / Chroma)? Tracked in [[System-Architecture-MOC]] open questions.
- **Stub** — auto-promotion of distilled MemoryObjects into hand-authored brain notes (reverse migration) — out of scope for v1.0.2; revisit after Module K (RAG) lands.
- **Stub** — distillation scope: Nexus postmortems only vs. all workspace audit-log events? Cost-driver for Module B implementation.

---

*Replaces the pre-distillation Memory-MOC (2026-05-08); the legacy per-project memory hierarchy is preserved in the "Legacy hierarchy" section above. Spec is binding truth.*
