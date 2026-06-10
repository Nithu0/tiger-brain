# WF lane: brain-memory-integration (DESIGN)

Date: 2026-06-08
Author: Nexus firm worker (wf agent)
Type: design only — no build, no env flips, no strategy change
Status: proposal for operator review

---

## TL;DR

There is **no structured bridge** today between Nexus firm learnings
(`agent_lessons`, `calibration_log`, `postmortems` in Railway Postgres) and the
workspace Obsidian Brain RAG/distillation substrate (`@cc/memory-engine` +
`@cc/rag-engine`, local SQLite). The only links that exist are (a) the
`01-nexus/_repo-docs` symlink into the repo's `docs/` and (b) the
`00-claude-inbox/nexus/` markdown drop convention — both human-curated, neither
queryable by the RAG engine.

The integration is feasible and small. The clean seam already exists:
`insertVerbatim()` → `distillAndInsert()` in `@cc/memory-engine`. The work is a
new **exporter** (Nexus Postgres → verbatim rows tagged with a new
`SourceType`) plus a `nexus_lesson` distill path, plus a queue-watcher dir so
the brain-orchestrator can pick it up. Recommended as a 4-phase plan, all
default-OFF, all behaviour-neutral (read-only on the Nexus side, additive on the
brain side). **No trade-decision impact**, so this is learning-INFRA — Claude's
lane, not Karri's — EXCEPT the one downstream step where a retrieved lesson would
be injected back into a Nexus agent prompt (that crosses into trade-altering and
stays gated to Karri; explicitly OUT of scope here).

---

## 1. The two sides

### 1a. Nexus learning surfaces (source) — Railway Postgres

| Surface | Where | Shape | State |
|---|---|---|---|
| `agent_lessons` | `apps/worker/src/firm/agent-lessons/client.ts` + `@ai-agent/shared` types | structured: `agent_role`, `domain`, `lesson_type`, `status` (proposed/approved/...), `condition_jsonb`, `action_jsonb`, `outcome_score`, `sample_size`, `confidence`, `fingerprint` (UNIQUE, multi-proposer voting via ON CONFLICT), `embedding` (jsonb, optional), `rationale` | Phase B landed, `AGENT_LESSONS_ENABLED` default OFF; deriver writes proposals, trading loop does NOT read them yet |
| `calibration_log` | `apps/api/src/routes/calibration.ts` | per-cycle calibration deltas / autotune candidates | live-ish; gated by CALIBRATION_MODE |
| `postmortems` | `apps/worker/src/firm/postmortem.ts` (`runEnhancedPostmortem`, `EventReview`, `FailureClass`, `PostmortemResult`) | per-trade/event failure classification + R-multiple review | live |

All three are **Postgres tables on Railway**. From this WSL box they are
reachable ONLY over 443 (firewall blocks 5432). The existing
`pull-nexus-data.sh` + the `nexus-pg` read-only MCP are the two sanctioned
read paths. So the exporter must run either (a) inside the Nexus worker/api
(direct DB, then push markdown/JSON to the vault), or (b) locally via the API/MCP
(read over 443, then write to vault). Option (b) is the safer first cut — zero
deploy risk.

### 1b. Brain memory substrate (sink) — local SQLite

- `@cc/memory-engine` — `better-sqlite3` ONLY (no Postgres client). Schema in
  `packages/memory-engine/src/storage/migrate.ts`:
  - `verbatim_exchanges` (id, project, **source_type**, conversation_id, ply_*,
    url, file_path, commit_sha, body, body_sha256 UNIQUE, byte_length,
    created_at) — the raw layer; dedup by body hash.
  - `memory_objects` (the 15-field distilled MemoryObject, FK→verbatim,
    rooms file/concept/workflow, confidence) + FTS5 + `distilled_embedding_meta`.
- Ingest seam (the clean entry point):
  1. `insertVerbatim(memoryDb, row)` → returns `{id, deduped}`.
  2. `distillAndInsert(memoryDb, verbatim_row_id, opts)` → LLM-distills into a
     MemoryObject, writes embedding (bge-m3, 1024-dim) unless NO_EMBED. Idempotent
     via fingerprint + body_sha256.
- `SourceType` enum (`packages/memory-engine/src/types.ts`):
  `conversation | code_change | youtube | github_repo | document | manual_note | terminal_log`.
  **No trading/lesson category** — this is the one schema change needed.
- `@cc/rag-engine` consumes the SAME SQLite (hybrid BM25 + bge-m3 vector, fusion,
  agentic loop). It "MUST consume this schema, never redefine it" (types.ts
  contract). So once a Nexus lesson is a MemoryObject, RAG retrieval is free.
- `@cc/brain-orchestrator` queue-watcher watches `12-youtube/_queue` +
  `13-github-repos/_queue` only (`packages/brain-orchestrator/src/triggers/queue-watcher.ts`).
  G6 gate default OFF. `nightly-distill` trigger exists (G4 default OFF).

---

## 2. The gap (what is missing)

1. **No `SourceType` for trading learnings.** Need e.g. `nexus_lesson`
   (covers agent_lessons), and reuse `document` or add `nexus_postmortem` /
   `nexus_calibration` for the other two. Minimal: one new value `nexus_lesson`,
   route postmortems/calibration through `document` with a project tag, OR add
   all three for clean room-routing. Recommend three.
2. **No exporter.** Nothing reads agent_lessons/calibration_log/postmortems and
   produces verbatim rows. This is the bulk of the work.
3. **No transport decision wired.** Postgres-on-Railway → SQLite-on-laptop. The
   exporter has to bridge networks (443) or run server-side and ship a file.
4. **No queue dir / trigger.** brain-orchestrator does not watch any
   Nexus-sourced queue. Need a `14-nexus-lessons/_queue` (or similar) + a
   queue-watcher entry, OR have the exporter call `distillAndInsert` directly.
5. **No distill prompt for structured lessons.** `distill-real.ts` SYSTEM_PROMPT
   is tuned for conversation/code/doc bodies. agent_lessons are already-structured
   JSON (condition/action). Best to **render them to a canonical markdown body**
   in the exporter (so existing distill works) rather than special-case the LLM.
6. **Embedding-space split.** agent_lessons has its OWN `embedding` column
   (purpose unclear / Karri-WIP-adjacent). Brain uses bge-m3 1024-dim. These are
   separate spaces; the integration uses the brain's, ignores the Nexus column.
7. **No back-channel (retrieval → Nexus).** RAG can serve lessons to a human or
   to a Claude session, but injecting a retrieved lesson INTO a Nexus agent
   prompt to change a trade = trade-altering = **Karri-gated, OUT of scope**.

---

## 3. Integration surface (the contract)

```
Nexus Postgres                          Brain SQLite
──────────────                          ────────────
agent_lessons    ─┐                     verbatim_exchanges
calibration_log  ─┼─[EXPORTER]──render──►  (source_type=nexus_*) ──distillAndInsert──► memory_objects ──► @cc/rag-engine
postmortems      ─┘   (read 443/MCP)        insertVerbatim()                              (+ bge-m3 embed)        (BM25+vector)
                                                                                                                       │
                                                                                                                       ▼
                                                                                              recall in any Claude session / brain query
                                                                                              (NEXT phase, Karri-gated: inject → Nexus agent prompt)
```

Key design choices:
- **One-way, append-only.** Nexus is read-only source. Brain never writes back
  to Nexus Postgres. (Respects operator-prinsipp 2: data never stops; this only
  reads.)
- **Render-to-markdown in the exporter.** Turn each lesson/postmortem/calibration
  row into a deterministic markdown body so the EXISTING distill pipeline handles
  it. Stable body → body_sha256 dedup → re-running the exporter is idempotent.
- **Project tag = `nexus`.** Lets RAG filter Nexus-only and keeps it isolated
  from thesis/AS/etc per cross-repo no-pollution rule.
- **Status filter.** Export only `approved` (and optionally high-`sample_size`
  `proposed`) agent_lessons — avoid polluting the brain with rejected/noise
  proposals. Operator-tunable.

---

## 4. Phased plan (all default-OFF, behaviour-neutral)

### Phase 0 — schema + types (brain side, tiny)
- Add `nexus_lesson`, `nexus_postmortem`, `nexus_calibration` to `SourceType`
  in `@cc/memory-engine/src/types.ts`. Additive enum — no migration needed
  (source_type is a free TEXT column; the enum is a TS guard).
- Optional: add a `nexus`-aware room-key convention (e.g. concept:`strategy_<id>`,
  workflow:`gate_<name>`) so retrieval routing is sane.
- Branch: `feat/wf-brain-nexus-sourcetype` (command-center repo).
- Gate: none needed (type-only, inert until exporter exists). tsc + memory-engine
  tests green.

### Phase 1 — read-only exporter (the core)
- New package or script: `nexus-lessons-export` (lives in command-center
  `packages/` or `scripts/`). Inputs: read over 443 via the Nexus API
  (`/firm-agents/*` / a new read endpoint) or the `nexus-pg` MCP. Output: writes
  JSON/markdown drop files to a vault queue dir `14-nexus-lessons/_queue/`.
- Render each row → canonical markdown (title, domain, condition→action,
  rationale, outcome_score, sample_size, source ref = `nexus:agent_lessons:<id>`).
- Idempotent: same row → same body → dedup at `insertVerbatim`.
- Gate: `NEXUS_LESSONS_EXPORT_ENABLED` default OFF (env, command-center side).
- Branch: `feat/wf-nexus-lessons-exporter`. Behaviour-neutral: when flag OFF the
  exporter no-ops; when ON it only READS Nexus + WRITES vault files.
- NOTE: if the read path is a NEW Nexus API endpoint, that endpoint is added in
  the ai-assistent repo on its own branch, default-OFF route, read-only SELECT —
  flag `NEXUS_LESSONS_EXPORT_API_ENABLED`. Coordinate with ai-1? No — ai-1 owns
  ADX/regime; this touches neither. Safe.

### Phase 2 — distill wiring + queue-watcher
- Extend brain-orchestrator queue-watcher `DEFAULT_QUEUE_DIRS` (or a new opt) to
  include `14-nexus-lessons/_queue`. On drop → `insertVerbatim` →
  `distillAndInsert`.
- OR (simpler first cut) have the Phase-1 exporter call `distillAndInsert`
  directly in-process and skip the queue entirely. Queue is better for the
  always-on daemon story; direct-call is faster to ship + verify.
- Gate: reuses G4 (nightly-distill) / G6 (queue-watcher) — both already
  operator-gated and default OFF. No new gate.
- Branch: `feat/wf-brain-nexus-distill`. Tests: a fixture lesson row →
  verbatim → MemoryObject with project=`nexus`, source_type=`nexus_lesson`.

### Phase 3 — recall surface + eval
- Confirm `@cc/rag-engine` retrieves Nexus lessons (hybrid query e.g. "what did
  we learn about ORB in low-ADX chop?"). Add 3-5 Nexus rows to the eval set;
  re-confirm MRR doesn't regress (current MRR≈0.9556 on the existing set).
- Add a brain runbook entry: "recall Nexus learnings" in
  `_runbooks/Runbook-Brain-Upgrade-Workflow.md`.
- Gate: none — pure retrieval/observability.

### Phase 4 (Karri-GATED, OUT of scope for this lane) — lesson → trade
- Injecting a recalled lesson back into a Nexus agent's system prompt to change
  a gate/sizing/entry decision. This is trade-altering per operator-prinsipp 6 +
  the learning-infra/strategy boundary. **Do NOT build under this lane.** File a
  strategy proposal (`docs/strategy/proposals/`) addressed to Karri when/if
  operator wants it.

---

## 5. Risks / open questions

- **Transport.** Cleanest is exporter-runs-locally (read 443, write vault) — zero
  Nexus deploy. But the brain SQLite lives on this laptop; if the brain is meant
  to run server-side too, the SQLite location must be settled first. (Check
  command-center Dockerfile/apps node-wiring — C1-9 task-persistence is in
  flight and may move the substrate.)
- **agent_lessons is mostly EMPTY today** (`AGENT_LESSONS_ENABLED` OFF in prod,
  deriver may not have run). Verify row counts before building Phase 1, or the
  exporter has nothing to export. postmortems/calibration_log have real data.
- **Volume / cost.** Distillation calls an LLM per verbatim row. agent_lessons
  are low-volume (good). postmortems could be higher — cap + batch. bge-m3 embed
  is local/cheap.
- **FVG_* / Karri-WIP adjacency.** The `embedding` column on agent_lessons is
  Karri-adjacent; do NOT touch or repurpose it. Integration uses brain's own
  embedding space.
- **Dedup vs updates.** A lesson whose `sample_size` increments changes the
  rendered body → new body_sha256 → new verbatim row. Decide: re-distill on
  material change only (e.g. status flip proposed→approved), not on every
  sample_size++. Render only stable fields into the body; put volatile counts in
  a sidecar field excluded from the hash.

---

## 6. Concrete next actions (if operator says go)

1. Verify Nexus data volumes: `bash pull-nexus-data.sh` + a read query for
   `agent_lessons`/`postmortems`/`calibration_log` counts (over MCP/443).
2. Confirm where brain SQLite is canonically hosted post-C1-9 (ask code-1 /
   check command-center apps wiring) — picks transport.
3. Phase 0 PR (sourcetype enum) — trivial, ship first.
4. Phase 1 exporter behind `NEXUS_LESSONS_EXPORT_ENABLED=OFF`.

All Phases 0-3 are learning-INFRA (capture/distill/recall/observability) →
Claude's lane per the learning-infra-vs-strategy boundary. Phase 4 (inject into
trade decisions) → Karri proposal only.

---

## Files referenced

Nexus (ai-assistent):
- `apps/worker/src/firm/agent-lessons/client.ts`
- `apps/worker/src/firm/postmortem.ts`
- `apps/api/src/routes/calibration.ts`, `apps/api/src/routes/firehose.ts`
- `scripts/firehose/grants.sql`
- `docs/ops/firehose-setup.md`
- `pull-nexus-data.sh`

Brain / command-center:
- `packages/memory-engine/src/types.ts` (SourceType + MemoryObject)
- `packages/memory-engine/src/storage/{migrate,verbatim,db}.ts`
- `packages/memory-engine/src/distill-pipeline.ts` (`distillAndInsert`)
- `packages/memory-engine/src/distill-real.ts` (SYSTEM_PROMPT)
- `packages/rag-engine/src/{hybrid,index}.ts`
- `packages/brain-orchestrator/src/triggers/queue-watcher.ts`
- `~/Obsidian/Brain/01-nexus/` (existing human-curated Nexus knowledge folder)
