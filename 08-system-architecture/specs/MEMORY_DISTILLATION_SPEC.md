---
title: Memory Distillation Spec
date: 2026-05-25
status: v1.0.2 draft
spec_for: Module B (Memory Engine) + Module K (RAG) — brain-upgrade-plan
paper_reference: 2603.13017v1
author: A-1 (sub-agent)
related: ["[[2026-05-25-brain-upgrade-plan]]", "[[RAG_ENGINE_SPEC]]"]
tags: [spec, memory, distillation, rag, schema]
---

# Memory Distillation Spec

> Implements Module B (Memory Engine) from [[2026-05-25-brain-upgrade-plan]] §2.B and provides the storage substrate that Module K (RAG) §2.K consumes. Schema and distillation prompt are paper-true to `2603.13017v1` (Lewis 2026, "Structured Distillation for Personalized Agent Memory").

---

## 1. Overview

This spec defines the two-tier memory substrate of the workspace brain:

- **Verbatim layer** (never deleted, never paraphrased) — full SQLite + FTS5 store of every exchange, code-change diff, YouTube transcript, GitHub README, terminal session log, manual brain note.
- **Distilled layer** (paper-true) — per-exchange `MemoryObject` rows with the four canonical fields (`exchange_core`, `specific_context`, `room_assignments`, `files_touched`) plus operator-extensions (`entities`, `decisions`, `unresolved_questions`, `next_actions`, `confidence`, `expires_at`) and a 1024-dim `bge-m3` embedding column for vector recall.

**Relation to `[[RAG_ENGINE_SPEC]]` (sibling):** This spec owns the *storage* and *write-path* (distillation pipeline + verbatim insert). The RAG engine owns the *read-path* (chunking, hybrid retrieval, reranking, agentic loop, generation+citation). Both specs share the `MemoryObject` schema defined here as the canonical interchange format — RAG must not redefine the schema, only consume it.

**Layering (binding):** MEMORY exposes *low-level* storage primitives (`queryVerbatimFts`, `queryDistilledFts`, `queryDistilledVector`, `getMemoryObjectById`) — single-index lookups, no fusion, no reranking, no agentic looping. RAG composes these primitives into *high-level* operations (hybrid retrieval = BM25 + vector + fusion, reranking, multi-hop agentic loop, prompt assembly, citation enforcement). The boundary: anything that touches a single SQLite index lives here; anything that combines multiple indices or calls an LLM lives in RAG. Per finding G.1 in `INTEGRATION_NOTES_v1.1`.

**Hard invariants (binding, enforced by code):**

1. Verbatim source rows are append-only. The `verbatim_exchanges` table has no `UPDATE` or `DELETE` path in the public API.
2. Distilled rows are *never* shown to the operator as a final answer — they are retrieval-routing artifacts only. Every operator-facing recall surface MUST render the verbatim row that the matched distilled row back-references.
3. Embedding model defaults to local `bge-m3` (1024-dim, multilingual, supports Norwegian). OpenAI fallback (`text-embedding-3-large`, 3072-dim) only when `MEMORY_EMBED_PROVIDER=openai` env-flag is explicitly set — code refuses cloud calls otherwise.
4. All code is TypeScript. No Python in this module.

---

## 2. MemoryObject TS interface

The 15-field schema (operator-spec said "14", but the enumerated list contains 15 — verified field-by-field below). Norwegian comments are operator-facing; field names are English for portability.

```typescript
// packages/memory-engine/src/schema.ts
//
// MemoryObject — paper-tro per 2603.13017v1 Table 1 + operator-extensions.
// 14 felter totalt: 4 paper-canonical, 10 operator/back-ref/quality.

export type SourceType =
  | "conversation"      // Claude Code exchange (ply-based)
  | "code_change"       // git commit / diff
  | "youtube"           // 12-youtube/ ingest
  | "github_repo"       // 13-github-repos/ ingest
  | "document"          // PDF / Obsidian markdown / academic paper
  | "manual_note"       // operator-skrevet brain-notat
  | "terminal_log"      // firm-bus / pane stdout-fragment
  | "agentic_recall"    // Tier 3 reasoning trace from RAG_ENGINE agentic loop (per RAG_ENGINE_SPEC §1.2/§4.6/§15.1); stored back into memory for future recall
  | "sensitive";        // operator/secret-tagged content; local-only routing enforced by RAG_ENGINE_SPEC §5.4/§6.3/§12 — never embedded with external provider, never sent to cloud LLM

export interface RoomAssignment {
  type: "file" | "concept" | "workflow"; // paper-canonical 3-typer
  key: string;                            // identifier ("retry_timeout", ikke "errors")
  label: string;                          // kort menneske-lesbar
  relevance?: number;                     // 0..1 (LLM-confidence per rom; valgfri)
}

export interface SourceRef {
  // Back-referanse til verbatim-rad. Minst ett felt MÅ være satt.
  conversation_id?: string;   // for source_type "conversation"
  ply_start?: number;         // paper-tro (inclusive)
  ply_end?: number;           // paper-tro (inclusive)
  file_path?: string;         // for code_change / document
  commit_sha?: string;        // for code_change
  url?: string;               // for youtube / github_repo / document
  verbatim_row_id: number;    // BINDING — FK til verbatim_exchanges.id (alltid satt)
  extras?: Record<string, unknown>; // forward-compat escape-hatch; consumers (e.g. RAG_ENGINE_SPEC §4.6 agentic trace: { trace, truncated, cited, cost }) may attach payload-specific metadata here without schema-bump. Treat as opaque from MEMORY's perspective — never indexed, never queried, only round-tripped.
}

export interface MemoryObject {
  // --- identitet ---
  id: string;                       // UUIDv7 (tids-sorterbar)
  created_at: string;               // ISO-8601 UTC
  project: string;                  // "nexus" | "thesis" | "command-center" | "as" | "personlig" | "soking" | "research-os" | "brain"
  source_type: SourceType;

  // --- paper-canonical 4 ---
  exchange_core: string;            // LLM: 1-2 setninger, hva skjedde (commit-message-analogi)
  specific_context: string;         // LLM: ÉN konkret detalj (diff-analogi) — number/error/param/path, kopiert eksakt
  room_assignments: RoomAssignment[]; // LLM: 1-3 rom (binding: validate length ∈ [1,3])
  files_touched: string[];          // REGEX-ekstrahert fra raw exchange, IKKE LLM-generert

  // --- operator-extensions (for vår workspace) ---
  entities: string[];               // navn, funksjoner, env-vars, error-strings
  decisions: string[];              // "vi valgte X over Y fordi Z"
  unresolved_questions: string[];   // åpne tråder (matet inn i 10-tasks/_open/ av BrainOrchestrator)
  next_actions: string[];           // strukturelle TODOs (kandidat for 10-tasks/)

  // --- traceability + kvalitet ---
  source_ref: SourceRef;            // back-ref til verbatim (BINDING — aldri null)
  confidence: number;               // 0..1, fra distill-LLM self-report. < 0.5 → re-distill
  expires_at?: string;              // ISO; for runtime-state med kjent staleness (f.eks. "active branch" gjelder kun til neste merge)
}

// Embedding lever på egen tabell (distilled_embeddings), 1024-dim bge-m3 default.
export interface MemoryObjectEmbedding {
  memory_object_id: string;         // FK
  model: "bge-m3" | "text-embedding-3-large";
  dim: 1024 | 3072;
  vector: Float32Array;
  embedded_at: string;
}
```

**Schema-validatorer (kjøres på hver `insertDistilled()`):**

| Felt | Regel | Failure-action |
|---|---|---|
| `exchange_core` | 10 ≤ chars ≤ 400 | reject, re-prompt |
| `specific_context` | 5 ≤ chars ≤ 300 | reject, re-prompt |
| `room_assignments` | 1 ≤ length ≤ 3 | reject, re-prompt |
| `room_assignments[].type` | ∈ {file, concept, workflow} | reject, re-prompt |
| `files_touched` | regex-ekstrahert post-hoc fra verbatim (ikke LLM) | overwrite hvis LLM forsøker å sette |
| `source_ref.verbatim_row_id` | FK exists in verbatim_exchanges | hard error, abort insert |
| `confidence` | 0 ≤ x ≤ 1; if < 0.5 → push to `_redistill_queue` | warning, log |

---

## 3. Distillation prompt template

Used for batch distillation (`distill.ts → callHaiku()`). Paper-tro per Appendix B, utvidet med våre operator-felter. Modell: **Claude Haiku 4.5** (per paper §3.2).

### 3.1 System prompt (kort, anti-drift)

```text
You are a structured distillation extractor. Your job: read one exchange
and emit a single JSON object matching the MemoryObject schema below.

BINDING RULES:
1. Surviving vocabulary: reuse the exact terms from the source. Do NOT
   paraphrase, do NOT invent synonyms. If participants said "connection
   pool timeout", that exact phrase must survive into your output.
2. specific_context must be ONE concrete detail copied EXACTLY from the
   text — a number, error message, parameter name, file path, env-var.
   Do NOT use the project path itself.
3. 1-3 rooms only. Each room key must be specific enough to group
   related exchanges (e.g. "retry_timeout" not "errors").
4. Do NOT populate files_touched — leave it as empty array []. The
   pipeline regex-extracts it post-hoc.
5. Respond with ONLY valid JSON. No prose, no markdown code fences,
   no commentary. Parse failure means the exchange is re-queued.
6. If exchange is mostly empty or trivial, set confidence < 0.3 and
   say so briefly in exchange_core.
```

### 3.2 User prompt (template, with interpolations)

```text
Distill this {source_type} exchange into JSON matching this schema:

{
  "exchange_core": string,            // 1-2 sentences. What was accomplished or decided. Use SOURCE TERMS verbatim.
  "specific_context": string,         // ONE concrete detail copied exactly: number/error/param/path/env-var.
  "room_assignments": [               // 1-3 rooms.
    {
      "type": "file" | "concept" | "workflow",
      "key": "snake_case_specific_identifier",
      "label": "short human label",
      "relevance": 0.0-1.0
    }
  ],
  "entities": [string],               // names, functions, env-vars, error strings mentioned
  "decisions": [string],              // explicit decisions ("we chose X over Y because Z")
  "unresolved_questions": [string],   // open threads
  "next_actions": [string],           // structural TODOs
  "confidence": 0.0-1.0               // your self-assessed extraction quality
}

Project: {project_id}
Source type: {source_type}
Exchange ({ply_start}-{ply_end}):
---
{messages_text}
---

Respond with ONLY valid JSON. No code fences, no prose.
```

### 3.3 Surviving-vocabulary enforcement (post-hoc)

After Haiku returns JSON, `distill.ts` runs a *vocabulary preservation check*:

1. Extract top-15 IDF tokens from the verbatim source (corpus-wide IDF table refreshed nightly).
2. Compute overlap with tokens present in `exchange_core ∪ specific_context`.
3. Paper baseline: 27.0% of top-15 IDF tokens survive into distilled text. **Our threshold: ≥25%.**
4. If overlap < 25%, set `confidence -= 0.2` and push to `_redistill_queue` with a "low-vocab-preservation" tag (max 1 retry per object — second failure is logged and the object is kept anyway, since paper notes that exchange-specific vocab loss is *expected* in some cases).

### 3.4 Truncation policy

- Messages truncated to **4,000 characters** before being sent to Haiku (paper §3.2, Appendix B).
- Exchanges > 20 plies split at fixed intervals (paper §3.1).
- Exchanges < 100 characters filtered as trivial — not distilled, but still inserted into the verbatim layer.

---

## 4. When to distill

Distillation is triggered from five surfaces. All five route through the same `distill.ts → insertDistilled()` path; only the upstream trigger differs.

| # | Trigger | Cadence | Source | Owner | Handoff |
|---|---|---|---|---|---|
| **a** | Per command-center action | Real-time (post-`audit_log` insert) | `audit_log` row | command-center executor | emits `agent_tasks(role: "distill", payload: { audit_log_id })` |
| **b** | Per conversation-end | On Claude Code stop-hook | full ply-range of just-closed conversation | `~/.claude/settings.json` stop hook | shells `cc memory distill --conversation <id>` |
| **c** | Nightly batch on `audit_log` | cron 03:00 lokal | yesterday's untouched audit rows + brain-notes edited yesterday | BrainOrchestrator `nightly-memory-distill` trigger | enqueues N×`agent_tasks` (one per orphan row) |
| **d** | Per YouTube / GitHub ingest | On ingest-pipeline complete | freshly-ingested transcript / README | `youtube-ingest` / `github-discovery` workers | direct call to `distill.ts` after writing verbatim |
| **e** | Manual skill | Operator-on-demand | arbitrary date range or project | `/skill brain-distill-daily` invocation | calls same nightly path with explicit `--since` / `--project` filters |

**Idempotency:** Every distill-job is keyed by a SHA-256 fingerprint of `(source_ref.verbatim_row_id, source_type, prompt_version)`. Re-running a distill produces an `UPSERT` keyed on this fingerprint — the same input never produces duplicate `MemoryObject` rows. `prompt_version` bumps when the prompt in §3 changes, so a prompt-revision triggers re-distillation on next run without manual cleanup.

**Backpressure:** `nightly-memory-distill` caps at 500 distill-calls per night. Operator-alert (firm-bus feed line) if backlog > 2000 unprocessed verbatim rows. Operator decides whether to lift the cap or skip a day.

---

## 5. Verbatim layer

**Storage:** `better-sqlite3` (synchronous, single-file, zero ops cost). Lives at `~/.claude/projects/-home-nithu-code/state/memory.db`. WAL mode enabled for concurrent readers + single writer.

### 5.1 Schema (DDL)

```sql
-- packages/memory-engine/src/storage/verbatim.sql

CREATE TABLE IF NOT EXISTS verbatim_exchanges (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  project       TEXT    NOT NULL,
  source_type   TEXT    NOT NULL,    -- matches SourceType union
  conversation_id TEXT,
  ply_start     INTEGER,
  ply_end       INTEGER,
  url           TEXT,
  file_path     TEXT,
  commit_sha    TEXT,
  body          TEXT    NOT NULL,    -- full raw text, append-only
  body_sha256   TEXT    NOT NULL,    -- dedup-fingerprint
  byte_length   INTEGER NOT NULL,
  created_at    TEXT    NOT NULL,    -- ISO-8601 UTC
  UNIQUE(body_sha256)                -- hard dedup at insert-time
);

CREATE INDEX idx_verbatim_project    ON verbatim_exchanges(project);
CREATE INDEX idx_verbatim_source     ON verbatim_exchanges(source_type);
CREATE INDEX idx_verbatim_created    ON verbatim_exchanges(created_at);
CREATE INDEX idx_verbatim_conv       ON verbatim_exchanges(conversation_id, ply_start);

-- FTS5 virtual table for keyword recall (BM25 default ranker)
CREATE VIRTUAL TABLE IF NOT EXISTS verbatim_fts USING fts5(
  body,
  content='verbatim_exchanges',
  content_rowid='id',
  tokenize='porter unicode61'
);

-- Triggers to keep FTS in sync (insert-only; no update/delete on verbatim)
CREATE TRIGGER IF NOT EXISTS verbatim_ai AFTER INSERT ON verbatim_exchanges BEGIN
  INSERT INTO verbatim_fts(rowid, body) VALUES (new.id, new.body);
END;
```

### 5.2 Public API

```typescript
// packages/memory-engine/src/storage/verbatim.ts

export interface InsertVerbatim {
  project: string;
  source_type: SourceType;
  body: string;
  conversation_id?: string;
  ply_start?: number;
  ply_end?: number;
  url?: string;
  file_path?: string;
  commit_sha?: string;
}

export function insertVerbatim(row: InsertVerbatim): { id: number; deduped: boolean };

export function queryVerbatimFts(
  q: string,
  opts?: { project?: string; source_type?: SourceType; limit?: number }
): Array<{ id: number; body: string; bm25_score: number; project: string; source_type: SourceType }>;

export function getVerbatimById(id: number): VerbatimRow | null;

// NO updateVerbatim. NO deleteVerbatim. Append-only invariant enforced
// by the absence of these functions in the public API.
```

### 5.3 Never-delete invariant

- No `DELETE` statement against `verbatim_exchanges` exists anywhere in the codebase. CI grep-check (`rg "DELETE FROM verbatim" packages/memory-engine/`) must return zero matches.
- DB-level: the SQLite user that the app connects as has table-level deletion blocked via a `BEFORE DELETE` trigger that raises `RAISE(ABORT, 'verbatim is append-only')`.
- Backup: nightly `sqlite3 .backup` to `~/Obsidian/Brain/_library/memory-backups/memory-YYYY-MM-DD.db` (Litestream-friendly).

---

## 6. Distilled layer

**Storage:** same `memory.db` file, separate tables. Vector index via [`sqlite-vec`](https://github.com/asg017/sqlite-vec) loadable extension (in-process, no separate vector DB). `sqlite-vec` is the actively-maintained successor to `sqlite-vss` (by the same author asg017) and aligns with `[[RAG_ENGINE_SPEC]]` §2.3 fallback chain (`sqlite-vec → sqlite-vss → in-memory`). `sqlite-vss` is retained only as a runtime fallback if `sqlite-vec` fails to load.

### 6.1 Schema (DDL)

```sql
-- packages/memory-engine/src/storage/distilled.sql

CREATE TABLE IF NOT EXISTS memory_objects (
  id                    TEXT PRIMARY KEY,        -- UUIDv7
  created_at            TEXT NOT NULL,
  project               TEXT NOT NULL,
  source_type           TEXT NOT NULL,
  exchange_core         TEXT NOT NULL,
  specific_context      TEXT NOT NULL,
  room_assignments_json TEXT NOT NULL,           -- serialized RoomAssignment[]
  files_touched_json    TEXT NOT NULL,           -- serialized string[]
  entities_json         TEXT NOT NULL,
  decisions_json        TEXT NOT NULL,
  unresolved_questions_json TEXT NOT NULL,
  next_actions_json     TEXT NOT NULL,
  source_ref_json       TEXT NOT NULL,           -- serialized SourceRef
  verbatim_row_id       INTEGER NOT NULL REFERENCES verbatim_exchanges(id),
  confidence            REAL NOT NULL,
  expires_at            TEXT,
  prompt_version        INTEGER NOT NULL,
  fingerprint           TEXT NOT NULL UNIQUE     -- SHA-256(verbatim_row_id || source_type || prompt_version)
);

CREATE INDEX idx_mo_project       ON memory_objects(project);
CREATE INDEX idx_mo_source        ON memory_objects(source_type);
CREATE INDEX idx_mo_created       ON memory_objects(created_at);
CREATE INDEX idx_mo_verbatim_fk   ON memory_objects(verbatim_row_id);
CREATE INDEX idx_mo_confidence    ON memory_objects(confidence);

-- FTS5 over distilled.specific_context for hybrid retrieval
CREATE VIRTUAL TABLE IF NOT EXISTS distilled_fts USING fts5(
  exchange_core,
  specific_context,
  content='memory_objects',
  content_rowid='rowid',
  tokenize='porter unicode61'
);

-- sqlite-vec virtual table — 1024-dim bge-m3 vectors
-- (separate table because sqlite-vec requires its own virtual-table syntax;
--  aligned with RAG_ENGINE_SPEC §2.3. sqlite-vss is runtime fallback only.)
CREATE VIRTUAL TABLE IF NOT EXISTS distilled_vec USING vec0(
  chunk_id TEXT PRIMARY KEY,
  embedding FLOAT[1024]
);

CREATE TABLE IF NOT EXISTS distilled_embedding_meta (
  rowid             INTEGER PRIMARY KEY,         -- matches distilled_vec.rowid
  memory_object_id  TEXT NOT NULL UNIQUE REFERENCES memory_objects(id),
  model             TEXT NOT NULL,
  dim               INTEGER NOT NULL,
  embedded_at       TEXT NOT NULL
);
```

### 6.2 Public API

```typescript
// packages/memory-engine/src/storage/distilled.ts

export function insertDistilled(obj: MemoryObject): { id: string; reused: boolean };
// reused=true means fingerprint matched — existing row returned, no LLM call

export function upsertEmbedding(
  memory_object_id: string,
  vector: Float32Array,
  model: "bge-m3" | "text-embedding-3-large"
): void;

export function queryDistilledFts(
  q: string,
  opts?: { project?: string; limit?: number }
): Array<{ memory_object_id: string; bm25_score: number }>;

export function queryDistilledVector(
  query_vec: Float32Array,
  k: number,
  opts?: { project?: string }
): Array<{ memory_object_id: string; distance: number }>;

export function getMemoryObjectById(id: string): MemoryObject | null;

export function getMemoryObjectsByVerbatim(verbatim_row_id: number): MemoryObject[];
```

### 6.3 Embedding

- Default model: `bge-m3` (1024-dim, multilingual, supports Norwegian) via `@huggingface/transformers` (Node-native, no Python).
- Embedding text: `${exchange_core}\n${specific_context}` (per paper §3.2 `distill_text` formula).
- Fallback (only with `MEMORY_EMBED_PROVIDER=openai`): `text-embedding-3-large` (3072-dim). Code refuses to load the OpenAI client unless the env var is set.
- Embeddings are re-computable from `(exchange_core, specific_context)` — never embed sensitive raw secrets; the distillation step already strips most by virtue of operating on `exchange_core` (1-2 sentences) and `specific_context` (single detail).

---

## 7. Quality checks

Run after every `insertDistilled()` and as part of the weekly `repo-health-audit` BrainOrchestrator routine.

| # | Check | Trigger | Pass criterion | Fail action |
|---|---|---|---|---|
| 7.1 | `files_touched` regex re-extract | per insert | Pipeline-regex output equals `obj.files_touched` (modulo set-order) | Overwrite with regex output; log discrepancy if LLM had tried to set it |
| 7.2 | 1-3 rooms validate | per insert | `1 ≤ obj.room_assignments.length ≤ 3` AND each `.type ∈ {file, concept, workflow}` | Reject, re-prompt (max 1 retry), then log + skip |
| 7.3 | Surviving-vocabulary check | per insert | ≥25% of top-15 IDF tokens from verbatim appear in `exchange_core ∪ specific_context` (paper baseline: 27.0%) | `confidence -= 0.2`; enqueue for `_redistill_queue` once |
| 7.4 | Confidence floor | per insert | `confidence ≥ 0.5` | Enqueue for re-distill on next nightly batch with `prompt_version++` if structural, otherwise retry same prompt once |
| 7.5 | Fingerprint dedup | per insert | `fingerprint` not already in `memory_objects` | Return existing row, set `reused: true`, skip LLM call |
| 7.6 | Embedding null-check | per nightly | Every `memory_objects` row has a matching `distilled_embedding_meta` row | Backfill embedding via batch-embed worker |
| 7.7 | Back-ref integrity | per nightly | Every `memory_objects.verbatim_row_id` resolves in `verbatim_exchanges` | Hard alert — indicates corruption (should be impossible per FK constraint) |

**Regex for `files_touched` (Module B canonical):**

```typescript
// packages/memory-engine/src/distill/extract-files.ts
const FILE_PATH_REGEX =
  /(?:^|\s|[`'"(])((?:\.{0,2}\/)?(?:[\w.-]+\/)*[\w.-]+\.[a-zA-Z]{1,6})(?=[\s`'")\].,;:]|$)/g;
// Matches: ./foo/bar.ts, packages/x/y.test.ts, ~/Obsidian/Brain/notes.md, README.md
// Rejects: bare words without extension, URLs (handled separately)
```

---

## 8. Migration: existing brain notes → MemoryObjects

**Principle (binding):** Original Obsidian markdown is **never** modified. Each existing note becomes both a verbatim row (full content as `body`) and one or more distilled `MemoryObject` rows. The `.md` file on disk stays exactly where it is — Obsidian wikilinks, frontmatter, MOC structure all preserved.

### 8.1 Migration pipeline

```
1. Walk /home/nithu/Obsidian/Brain recursively, respecting these rules:
   INCLUDE:
     _decisions/**/*.md          (15 immutable decisions)
     _maps/**/*.md               (20+ MOCs)
     _runbooks/**/*.md           (17 procedures)
     01-nexus/**/*.md, 02-thesis/**/*.md, ..., 07-personlig/**/*.md
     08-system-architecture/**/*.md
     handoffs/**/*.md, _decisions/**/*.md
   EXCLUDE:
     00-firm-bus/feed.md         (low-signal high-churn)
     00-firm-bus/PRESENCE.md     (ephemeral)
     _library/raw/**             (already verbatim by design)
     90-archive/**               (intentionally cold)
     **/.obsidian/**             (vault config)

2. For each included .md file:
   a. Read full content + parse YAML frontmatter
   b. insertVerbatim({
        project: inferProjectFromPath(path),
        source_type: "manual_note",
        body: full_content,
        file_path: relative_path_from_brain_root
      })
   c. If file is large (> 8000 chars), split on H2/H3 boundaries
      → one verbatim row per section, one distill-job per section
   d. Enqueue distill-job: agent_tasks(role: "distill", payload: { verbatim_row_id })

3. Migration runs ONCE, gated by --migrate flag. Subsequent re-runs
   are idempotent via fingerprint dedup (§7.5).

4. Operator-approval gate: dry-run mode prints counts per folder
   (verbatim rows to insert, distill-jobs to enqueue, projected
   Haiku token spend). Operator OK kjør before --execute.
```

### 8.2 Project inference (from path)

```typescript
function inferProjectFromPath(p: string): string {
  if (p.startsWith("01-nexus/")) return "nexus";
  if (p.startsWith("02-thesis/")) return "thesis";
  if (p.startsWith("03-skills/")) return "skills";
  if (p.startsWith("04-career/")) return "soking";
  if (p.startsWith("05-learning/")) return "learning";
  if (p.startsWith("12-youtube/")) return "youtube";
  if (p.startsWith("13-github-repos/")) return "github";
  if (p.startsWith("08-system-architecture/")) return "command-center";
  if (p.startsWith("_decisions/")) return "brain";  // cross-cutting
  if (p.startsWith("_runbooks/")) return "brain";
  if (p.startsWith("_maps/")) return "brain";
  return "brain"; // fallback
}
```

### 8.3 Originals untouched — verification

After migration completes, CI check:

```bash
# Must report zero modified .md files in the brain
cd /home/nithu/Obsidian/Brain && git diff --name-only HEAD | grep '\.md$' && exit 1 || exit 0
```

Migration writes only to `memory.db`, never to `.md` files. The brain remains the single source of truth for human-readable knowledge; `memory.db` is a *projection*, not a *replacement*.

---

## 9. Acceptance tests

All tests live in `packages/memory-engine/tests/`. CI gate: must pass before any `npm publish` of the package or any merge to `main`.

### 9.1 Vague-recall MRR test (paper-style)

Curate 5 vague queries against existing brain content. Compute Mean Reciprocal Rank against a hand-labeled gold-set of correct verbatim rows. **Target: MRR ≥ 0.60** (paper Tier 2 achievable; relax from paper's 0.759 since our corpus is smaller and noisier).

Test data lives in `08-system-architecture/eval/recall-eval-2026-05-25.md` (built by A-7 sub-agent). Query examples:

| # | Query (Norwegian, vague) | Gold verbatim row (project / file) |
|---|---|---|
| 1 | "den greia om worktrees og isolation som vi snakka om" | `command-center` / `2026-05-14-16-pane-codex-parallell.md` |
| 2 | "regelen om at vi aldri auto-disabler en gate" | `brain` / `_decisions/foundation-gate-policy.md` |
| 3 | "hva besluttet vi om on-prem AI hardware" | `command-center` / `2026-05-24-onprem-ai-strategi.md` |
| 4 | "den postmortem-pattern som Nexus bruker for å lære" | `nexus` / `_runbooks/When-Postmortem-Lands.md` |
| 5 | "battery electrolyte ML pipeline arkitektur" | `thesis` / `_maps/Thesis-MOC.md` |

Test code:

```typescript
test("vague-recall MRR ≥ 0.60 on 5-query eval-set", async () => {
  const evalSet = loadEvalSet("recall-eval-2026-05-25.md");
  const reciprocalRanks: number[] = [];
  for (const { query, gold_verbatim_id } of evalSet) {
    const hits = await hybridRecall(query, { k: 10 });
    const rank = hits.findIndex(h => h.source_ref.verbatim_row_id === gold_verbatim_id);
    reciprocalRanks.push(rank === -1 ? 0 : 1 / (rank + 1));
  }
  const mrr = reciprocalRanks.reduce((a, b) => a + b, 0) / reciprocalRanks.length;
  expect(mrr).toBeGreaterThanOrEqual(0.60);
});
```

### 9.2 Fingerprint-dedup test

```typescript
test("re-distilling identical exchange returns reused=true and same id", async () => {
  const v = insertVerbatim({ project: "test", source_type: "conversation", body: "foo" });
  const obj1 = await distillAndInsert(v.id);
  const obj2 = await distillAndInsert(v.id);
  expect(obj2.id).toBe(obj1.id);
  expect(obj2.reused).toBe(true);
  expect(callsToHaiku()).toBe(1); // second distill skipped the LLM
});
```

### 9.3 Verbatim-survival test

```typescript
test("no public API can delete a verbatim row", () => {
  const api = await import("../src/storage/verbatim");
  expect(api).not.toHaveProperty("deleteVerbatim");
  expect(api).not.toHaveProperty("updateVerbatim");
  // DB-level: trigger blocks DELETE
  const v = insertVerbatim({ project: "test", source_type: "conversation", body: "x" });
  expect(() =>
    db.prepare("DELETE FROM verbatim_exchanges WHERE id = ?").run(v.id)
  ).toThrow(/append-only/);
});
```

### 9.4 Surviving-vocabulary test

```typescript
test("≥25% of top-15 IDF tokens survive distillation on sample of 50 exchanges", async () => {
  const sample = sampleVerbatim(50);
  const survivalRates = await Promise.all(sample.map(async v => {
    const obj = await distillAndInsert(v.id);
    const top15 = top15IDFTokens(v.body);
    const distilledText = `${obj.exchange_core} ${obj.specific_context}`.toLowerCase();
    const survived = top15.filter(t => distilledText.includes(t.toLowerCase())).length;
    return survived / top15.length;
  }));
  const mean = survivalRates.reduce((a, b) => a + b, 0) / survivalRates.length;
  expect(mean).toBeGreaterThanOrEqual(0.25);
});
```

### 9.5 Back-ref integrity test

```typescript
test("every MemoryObject resolves to an existing verbatim row", () => {
  const orphans = db.prepare(`
    SELECT m.id FROM memory_objects m
    LEFT JOIN verbatim_exchanges v ON m.verbatim_row_id = v.id
    WHERE v.id IS NULL
  `).all();
  expect(orphans.length).toBe(0);
});
```

---

## 10. Failure modes + operator-alert

All operator-alerts emit a single-line entry to `~/Obsidian/Brain/00-firm-bus/feed.md` prefixed with `[memory-engine][ALERT]`. No auto-remediation — operator decides per `[[2026-05-25-brain-upgrade-plan]]` §11 (REPORT-only invariant).

| # | Failure | Detection | Operator-alert line | Recovery |
|---|---|---|---|---|
| 10.1 | Distillation timeout (Haiku > 60s) | `distill.ts` wraps Haiku call in `AbortSignal.timeout(60_000)`. Counter `memory.distill.timeouts` incremented. | `[memory-engine][ALERT] distill timeout >60s on verbatim_row_id={id} (project={p}); retry queued (attempt {n}/3)` | Auto-retry up to 3 times with exponential backoff (5s, 25s, 125s). After 3rd failure, mark `confidence=0.0`, log + skip, alert operator. |
| 10.2 | Embedding model down (`bge-m3` load fails) | `embedding.ts` health-check on module init + per-call try/catch. Counter `memory.embed.failures`. | `[memory-engine][ALERT] bge-m3 load failed: {err}; switching to NO_EMBED mode (FTS-only retrieval until resolved)` | Memory continues writing distilled rows WITHOUT embeddings; retrieval degrades to FTS-only (Tier 1 fallback). Operator triggers `/skill rebuild-embeddings` once model is back. |
| 10.3 | FTS5 lock contention | `better-sqlite3` throws `SQLITE_BUSY` during FTS rebuild. Detected via `err.code === "SQLITE_BUSY"`. | `[memory-engine][ALERT] FTS5 lock contention; {n} writes queued for >30s` | Single-writer queue serializes inserts. If queue > 100, operator-alert; operator may schedule downtime to vacuum + reindex. |
| 10.4 | sqlite-vec index corruption | Boot-time integrity check: `SELECT vec_version();` + sample-query test. If sample-query returns NULL distances or throws, flag corruption. (If primary `sqlite-vec` extension itself fails to load, runtime falls back to `sqlite-vss` per RAG_ENGINE_SPEC §2.3 — same corruption check applies via `SELECT vss_version();`.) | `[memory-engine][ALERT] sqlite-vec corruption detected; vector recall DISABLED until rebuild (fallback to sqlite-vss attempted={bool})` | Auto-rebuild from `distilled_embedding_meta` on next nightly cycle (re-INSERT all embeddings into a fresh `distilled_vec` table). Operator may trigger immediately via `/skill rebuild-vector-index`. |
| 10.5 | Verbatim dedup-collision (rare hash birthday) | `body_sha256` UNIQUE constraint throws on insert with different body but same SHA. | `[memory-engine][ALERT] SHA-256 collision on verbatim insert (project={p}); manual review required` | Block insert, log both bodies to `~/Obsidian/Brain/00-claude-inbox/memory-engine/sha-collision-{ts}.md`, operator chooses resolution. |
| 10.6 | Backup write failure | Nightly `.backup` to `_library/memory-backups/` fails. | `[memory-engine][ALERT] backup write failed: {err}; last successful backup {iso}` | Skip the night, alert. Operator inspects disk space / permissions. After 3 consecutive nights, escalate alert priority. |
| 10.7 | Haiku rate-limit hit | API returns 429. Counter `memory.distill.rate_limited`. | `[memory-engine][ALERT] Haiku rate-limit hit; backing off {n} minutes (cap {cap}/day reached)` | Token-bucket already in place; this alert only fires if the operator-configured `MEMORY_DISTILL_DAILY_CAP` is exceeded. Operator may raise cap. |

**Alert delivery (binding):** firm-bus `feed.md` write is the *only* automated channel. No Discord, no email, no PWA push — those require operator explicit opt-in per `[[CLAUDE.md]]` § "No auto-disable".

---

## 11. Code skeleton

File tree under `packages/memory-engine/`. One-line description per file.

```
packages/memory-engine/
├── package.json                        # name: @cc/memory-engine, deps: better-sqlite3, sqlite-vec (primary) + sqlite-vss (runtime fallback), @huggingface/transformers, @anthropic-ai/sdk
├── tsconfig.json                       # extends repo root, declaration: true, strict: true
├── README.md                           # quickstart + API surface summary
├── src/
│   ├── index.ts                        # public exports: schema, insertVerbatim, insertDistilled, hybridRecall, distillAndInsert
│   ├── schema.ts                       # MemoryObject + SourceRef + RoomAssignment + SourceType types (see §2)
│   ├── distill/
│   │   ├── distill.ts                  # main entry: verbatim_row_id → Haiku call → MemoryObject → insertDistilled
│   │   ├── prompts.ts                  # SYSTEM_PROMPT + USER_PROMPT_TEMPLATE constants from §3
│   │   ├── haiku-client.ts             # @anthropic-ai/sdk wrapper with 60s timeout + retry-with-backoff
│   │   ├── extract-files.ts            # FILE_PATH_REGEX + extractFilesTouched(body) (§7)
│   │   ├── idf-table.ts                # corpus-wide IDF table builder + top15IDFTokens(body) (§3.3, §9.4)
│   │   ├── validate.ts                 # schema validators from §2 table (10-3 chars, 1-3 rooms, etc.)
│   │   └── fingerprint.ts              # SHA-256(verbatim_row_id || source_type || prompt_version)
│   ├── storage/
│   │   ├── db.ts                       # better-sqlite3 connection singleton; WAL mode; loads sqlite-vec extension (falls back to sqlite-vss if vec unavailable, per RAG_ENGINE_SPEC §2.3)
│   │   ├── migrate.ts                  # runs DDL from verbatim.sql + distilled.sql on first boot
│   │   ├── verbatim.ts                 # insertVerbatim, queryVerbatimFts, getVerbatimById (NO update/delete) (§5)
│   │   ├── verbatim.sql                # DDL from §5.1
│   │   ├── distilled.ts                # insertDistilled, upsertEmbedding, queryDistilledFts, queryDistilledVector (§6)
│   │   ├── distilled.sql               # DDL from §6.1
│   │   └── backup.ts                   # nightly .backup() to _library/memory-backups/
│   ├── embedding/
│   │   ├── embed.ts                    # embedDistillText(obj) → Float32Array; routes to bge-m3 or openai per env
│   │   ├── bge-m3.ts                   # @huggingface/transformers local pipeline (1024-dim)
│   │   └── openai.ts                   # OpenAI text-embedding-3-large fallback (only if MEMORY_EMBED_PROVIDER=openai)
│   ├── retrieval/
│   │   ├── hybrid.ts                   # BM25(verbatim) + HNSW(distilled) + CombMNZ fusion (paper §3.4 cross-layer)
│   │   └── score-fusion.ts             # CombMNZ, RRF, weighted fusion strategies
│   ├── migration/
│   │   ├── brain-walk.ts               # walk Obsidian vault, respect include/exclude rules from §8.1
│   │   ├── project-infer.ts            # inferProjectFromPath (§8.2)
│   │   └── run-migration.ts            # CLI entry: --dry-run / --execute (§8.1)
│   ├── triggers/
│   │   ├── on-conversation-end.ts      # stop-hook entry (§4.b)
│   │   ├── on-audit-log.ts             # command-center action trigger (§4.a)
│   │   ├── nightly-batch.ts            # cron 03:00 batch (§4.c)
│   │   └── on-ingest.ts                # YouTube/GitHub post-ingest hook (§4.d)
│   ├── alerts/
│   │   └── firm-bus.ts                 # appendAlertLine() → ~/Obsidian/Brain/00-firm-bus/feed.md (§10)
│   └── cli/
│       ├── distill-cli.ts              # `cc memory distill --conversation <id>` + `--since YYYY-MM-DD`
│       ├── migrate-cli.ts              # `cc memory migrate --dry-run|--execute`
│       └── recall-cli.ts               # `cc memory recall "query"` (debug surface; primary recall lives in @cc/rag-engine)
└── tests/
    ├── schema.test.ts                  # MemoryObject validators
    ├── distill.test.ts                 # mocked Haiku, JSON-parse, surviving-vocab
    ├── verbatim.test.ts                # insert, FTS query, dedup, NO-delete invariant (§9.3)
    ├── distilled.test.ts               # insert, fingerprint dedup, embedding upsert
    ├── retrieval.test.ts               # vague-recall MRR ≥ 0.60 (§9.1), fingerprint dedup (§9.2)
    ├── migration.test.ts               # dry-run counts, idempotency, originals-untouched (§8.3)
    ├── failure-modes.test.ts           # timeout, embed-down, FTS-lock, vss-corruption (§10)
    └── fixtures/
        ├── sample-verbatim.json        # 20 hand-curated exchanges for unit tests
        └── eval-set-2026-05-25.json    # 5-query MRR eval-set (imported from 08-system-architecture/eval/)
```

**Build:** `npm -w @cc/memory-engine build && npm -w @cc/memory-engine test`. Test coverage target: 80%+ (per `[[2026-05-25-brain-upgrade-plan]]` C1-10).

---

## 12. Cross-refs

- [[2026-05-25-brain-upgrade-plan]] — governing plan (§2.B Memory Engine, §2.K RAG, §11 verify policy). **Verified present** at `08-system-architecture/2026-05-25-brain-upgrade-plan.md`.
- [[RAG_ENGINE_SPEC]] — sibling spec (read-path: chunking, hybrid retrieval, reranking, agentic loop, citation enforcement). **Stub — not yet written** (no file at `08-system-architecture/specs/RAG_ENGINE_SPEC.md` as of 2026-05-25). Will consume `MemoryObject` schema defined here.
- [[AGENT_ORCHESTRATION_SPEC]] — sibling spec (task lifecycle, leasing, merge protocol). **Verified present** at `08-system-architecture/specs/AGENT_ORCHESTRATION_SPEC.md`. Owns the `agent_tasks(role: "distill", ...)` queue that this module produces and consumes.
- [[OBSIDIAN_BRAIN_STRUCTURE]] — sibling spec (folder conventions, frontmatter rules). **Verified present** at `08-system-architecture/specs/OBSIDIAN_BRAIN_STRUCTURE.md`. Defines the source structure that §8 migrates from.
- [[YOUTUBE_INGESTION_SPEC]] — sibling spec; one of the §4.d distillation triggers. **Verified present.**
- [[GITHUB_DISCOVERY_SPEC]] — sibling spec; the other §4.d distillation trigger. **Verified present.**
- [[SKILL_REGISTRY_SPEC]] — sibling spec; consumer of `next_actions` field (auto-skill-extraction). **Verified present.**
- [[2603.13017v1]] — paper "Structured Distillation for Personalized Agent Memory" (Lewis 2026). §3.2 Table 1 (schema), §3.3 (embedding+indexing), §3.4 (search configs), §5.1 (MRR=0.759 cross-layer headline), §7 (10 limitations), Appendix B (distillation prompt). PDF at `/home/nithu/code/2603.13017v1.pdf`. **Verified present.**
- [[2026-05-24-onprem-ai-strategi]] — on-prem AI strategy (informs §6 fallback path; lokal `bge-m3` default aligned with privacy invariant). **Verified present** at `03-business/2026-05-24-onprem-ai-strategi.md`.
- [[CLAUDE.md]] — operator baseline (binding rules on auto-disable, REPORT-only, OK kjør gates, secret handling). **Verified present** at `~/.claude/CLAUDE.md`.

---

*Sist oppdatert: 2026-05-25 av A-1 sub-agent. v1.0 draft. Awaiting operator OK kjør for C1-2 / C1-3 / C1-4 implementation lanes.*

---

## Changelog
- 2026-05-25 v1.0.1 — embedding dim 768 → 1024 (bge-m3 actual = 1024; A-7 RAG_ENGINE_SPEC catch)
- 2026-05-25 v1.0.2 — applied B-2 CRITICAL fixes:
  - SourceType union: added `agentic_recall` + `sensitive` (RAG_ENGINE_SPEC alignment per INTEGRATION_NOTES_v1.1 A.1.1, A.1.2)
  - SourceRef: added `extras?: Record<string, unknown>` forward-compat field (A.1.4 — supports RAG_ENGINE_SPEC §4.6 agentic trace)
  - Storage: sqlite-vss → sqlite-vec (newer maintained successor; vss retained as runtime fallback per RAG_ENGINE_SPEC §2.3 chain; DDL `vss0(embedding(1024))` → `vec0(chunk_id TEXT PRIMARY KEY, embedding FLOAT[1024])`; §10.4 failure-mode wording updated; F.3)
  - §1 layering note: documented MEMORY-low-level vs RAG-high-level boundary (G.1 NIT applied)
