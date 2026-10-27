# INV-02 — Obsidian Brain as knowledge substrate + retrieval engine for Veldora

Measured 2026-10-16. Read-only. Everything below is a measurement unless tagged
UNKNOWN or ASSUMPTION. Where the workspace CLAUDE.md disagrees, the measurement wins.

---

## 0. Executive verdict (detail in §6)

**Reuse the engine, do not reuse the corpus, and do not share the database.**

- The retrieval stack (`@cc/memory-engine` + `@cc/rag-engine` + bge-m3/Ollama) is
  real, running, and measurably healthy. Veldora should vendor it against its own
  `memory.db`.
- The corpus is 100% irrelevant to anbud: trading, thesis, and the operator's own
  dev-session history. Zero tender content. Treat as a worked example, not training data.
- The book/PDF pipeline **cannot ingest PDFs at all** and is switched off twice over.
  This is the single biggest gap Veldora has to close itself.

---

## 1. Corpus inventory

Brain root `~/Obsidian/Brain/` — **62 MB total, 2093 markdown files.**

| Folder | Size | Files | Formats | Oldest → Newest | Topic |
|---|---|---|---|---|---|
| `14-books/` | 27 MB | 5 | 1 epub, 1 pdf, 2 md, 1 `.book` | 2026-06-03 → 2026-06-09 | **unprocessed trading books** |
| `_library/` | 4.7 MB | 128 | 103 txt, 19 md, 6 vtt | 2026-05-13 → 2026-07-15 | raw YouTube transcripts + trading concepts |
| `12-youtube/` | 1.8 MB | 254 | 139 md, 106 url, 8 txt | 2026-05-25 → 2026-07-15 | distilled video notes |
| `_runbooks/` | 212 KB | 25 md | md | 2026-05-13 → **2026-10-11** | ops procedures (freshest folder) |
| `05-learning/` | 216 KB | 25 | 24 md | 2026-05-08 → 2026-06-23 | book/paper distillates + per-project research |
| `_decisions/` | 132 KB | 21 md | md | 2026-05-13 → 2026-08-09 | ADRs + "When-X-Happens" decision trees |
| `03-skills/` | 112 KB | 11 md | md | 2026-05-25 → 2026-07-28 | skill registry (§4) |
| `03-business/` | 92 KB | 10 | 9 md | 2026-05-08 → **2026-05-24** | business strategy — **stale, 5 months** |
| `13-github-repos/` | 48 KB | 8 | 7 md, 1 yaml | 2026-05-25 → 2026-07-15 | repo discovery notes |

### 1.1 `14-books/` — the standout finding

Only **two actual books exist**, and **neither has ever been processed**. Both sit in
`_queue/` untouched since June; `_queue/_done/` and `_queue/_failed/` are both **empty**.

| File | Size | Queued | Fate |
|---|---|---|---|
| `Advanced+Futures+Trading+Strategies+30+fully+tested+strategies...epub` (Rob Carver) | 25.6 MB | 2026-06-03 | never processed |
| `Successful Algorithmic Trading.pdf` (Michael Halls-Moore) | 2.3 MB | 2026-06-09 | **would be rejected — PDF unsupported** |

`_library/books/` and `_library/raw/` — the directories the ingester would write
verbatim text into — are **empty (0 files)**. The book pipeline has never run once
end to end.

Note: both books *are* represented in `05-learning/` as hand-written distillates
(`2026-06-09_advanced-futures-trading-strategies-carver.md`,
`2026-06-09_successful-algo-trading-backtest-rigor.md`, plus Carver forecast/vol-targeting
notes). The operator read them manually; the automation never did.

### 1.2 `12-youtube/` — the only corpus with real volume

30 channel folders, 139 distilled notes. Queue has processed **103 done / 3 failed / 1 pending**.
Topic split is overwhelmingly trading + materials science:

```
26 transcripts   12 fiken            12 fabervaale-eng   11 taylor-sparks
11 quantified-strategies  11 flirting-with-models  11 better-system-trader
10 john-george   10 atoms-to-materials   2 josh-whitfield   2 anthropic ...
```

Only `fiken` (12 notes, Norwegian accounting software) is even adjacent to Norwegian
business process. Nothing on procurement, anbud, Doffin, or public-sector sales.

### 1.3 `13-github-repos/` — effectively unused

4 processed notes total, all from a single 2026-06-01 batch (trend-regime detection,
OANDA streaming, position management, XAUUSD backtest engine). 1 item pending since then.

### 1.4 Relevance to Veldora: near zero

I grepped the corpus for tender vocabulary. The **only** anbud-relevant artifact in the
entire Brain is `_runbooks/Runbook-Anbud-Triage.md` (2026-10-11, v1.0) — and that is a
*UI runbook for a dashboard Veldora already has*, not domain knowledge. It documents
`/tenders/triage` on `anbud-veldora.vercel.app`: the queue rules (UNDECIDED + spotted/screening
+ future deadline), the five decision steps, the brass/blue provenance colour code, the
append-only undo log, and hotkeys 1-4. Useful as a spec reference for Veldora's own UI.
It is not training material.

`03-business/` is the closest thematic folder and it is stale since 2026-05-24; its one
substantial file is `2026-05-24-onprem-ai-strategi.md` (56 KB).

---

## 2. The retrieval engine — measured

**Location: `~/.claude/projects/-home-nithu-code/state/memory.db`** (not under the Brain,
not under command-center — worth noting, the workspace CLAUDE.md never says where it is).
296 MB main file + 92 MB WAL. Litestream shadow dir present (`.memory.db-litestream`).
Three stale `.bak` copies from June (137-170 MB each) are sitting next to it — ~550 MB
of recoverable disk, flagged for the operator, not touched.

### 2.1 Schema (verified via `sqlite3 ... .schema`)

Two-tier store, append-only at the bottom:

- **`verbatim_exchanges`** — raw text. `UNIQUE(body_sha256)` dedupe, a
  `verbatim_no_delete` BEFORE DELETE trigger that `RAISE(ABORT)`s, and an
  FTS5 shadow (`verbatim_fts`, `porter unicode61`) maintained by an AFTER INSERT trigger.
- **`memory_objects`** — distilled. Structured JSON columns: `room_assignments_json`,
  `files_touched_json`, `entities_json`, `decisions_json`, `unresolved_questions_json`,
  `next_actions_json`, `source_ref_json`, plus `confidence`, `prompt_version`,
  `fingerprint UNIQUE`, FK back to `verbatim_row_id`. Its own FTS5 shadow
  (`distilled_fts` over `exchange_core` + `specific_context`).
- **`distilled_vec`** — `vec0` virtual table, `FLOAT[1024]`, **partitioned by `project`**
  (migration `001_vec_project_partition`). A `distilled_vec_legacy` unpartitioned table
  still holds 7556 rows.
- **`distilled_embedding_meta`** — `(memory_object_id, model, dim, embedded_at)`.
- **`facets`** — faceted-recall projection: `agent, project, customer, decision_ref,
  date_iso, file_path, doc_type, keywords, archived, provenance` (migration
  `002_facets_notnull_rebuild`, 2026-08-14).
- **`distill_deadletters`** — retry/failure ledger with `attempts` + `resolved_at`.
- `customer_aliases`, `schema_migrations`, `_litestream_seq`/`_lock`.

### 2.2 Row counts (measured 2026-10-16)

| Table | Rows |
|---|---|
| `verbatim_exchanges` | **16,072** |
| `memory_objects` | **16,008** |
| `distilled_embedding_meta` | **16,008** |
| `distilled_vec` (via `distilled_vec_rowids`) | **16,008** |
| `distilled_vec_legacy` | 7,556 |
| `facets` | 15,856 |
| `verbatim_fts_docsize` | 16,072 |
| `distilled_fts_docsize` | 16,008 |
| `distill_deadletters` (open / total) | **0 / 0** |

**Embedding coverage: 16,008 / 16,008 = 100.0%.** The anti-join
`memory_objects LEFT JOIN distilled_embedding_meta WHERE e.memory_object_id IS NULL`
returns **0**. Every distilled object is embedded, FTS-indexed, and in the vector index.
All three indexes agree on 16,008 — no drift.

**Model: `bge-m3`, dim `1024`, single model across all 16,008 rows** (no mixed-model
contamination). Confirmed resident in Ollama: `bge-m3:latest`, 1.16 GB, loopback
`http://127.0.0.1:11434`.

> **CLAUDE.md correction:** the workspace file says "~13 400 verbatim + ~13 350 distillerte".
> Actual is 16,072 / 16,008. The doc is stale-low by ~2,650 objects, not wrong in kind.
> The bge-m3/1024/100%-embedded claim **is** accurate.

### 2.3 Content breakdown

By project:

| Project | Objects |
|---|---|
| command-center | 5,958 |
| nexus | 4,957 |
| thesis | 3,687 |
| as | 725 |
| aslisten-crm | 303 |
| soking-fulltid | 177 |
| personlig | 38 |
| workspace | 20 |
| ~20 `ai-assistent--claude-worktrees-*` keys | 6-18 each |

The worktree-derived project keys are leakage — a worktree path became a project
identifier. Cosmetic, but it fragments project-scoped recall for nexus.

By source type — **this is the important number**:

| source_type | memory_objects | verbatim |
|---|---|---|
| `conversation` | **15,741** | 15,805 |
| `youtube` | 181 | 181 |
| `note` | **86** | 86 |

**98.3% of the index is the operator's own Claude-session history.** The curated Brain
knowledge — 2,093 markdown files — is represented by **86 note rows, 4.1% coverage**,
all written in a single 5-minute window on 2026-06-19 (`06:35:57Z` → `06:40:32Z`).
`@cc/obsidian-ingest` ran **once, four months ago, and has not run since.** It is not
wired into any timer or trigger I could find.

This is the most consequential finding for Veldora after the PDF gap: *the Brain's curated
knowledge is largely not in the retrieval index.* "Train it on everything I already own"
is not currently true even for the Brain's own owner.

Freshness: verbatim `2026-06-13T18:22Z` → `2026-10-16T07:38:43Z` (today, ~2h before
measurement). Distilled through `2026-10-16T06:27:58Z`. Embeddings through
`2026-10-16T06:28:05Z` — **the full capture → distill → embed loop closed this morning.**

Recent distill volume (objects/day): 10-16: 170 · 10-15: 384 · 10-14: 456 · 10-13: 99 ·
10-12: 370 · then a **gap back to 09-23 (5)**. Between 2026-08-31 and 2026-10-12 the
system produced almost nothing. That matches the known catch-up/partial-day gap in
`nightly-distill.ts` noted in the workspace CLAUDE.md — it is real, and the 10-12 spike
is the catch-up firing.

### 2.4 Hybrid BM25 + vector recall — live, verified by execution

`@cc/rag-engine`'s `hybrid()` runs both lanes in parallel and fuses with CombMNZ:

```ts
// packages/rag-engine/src/hybrid.ts:33
export async function hybrid(memoryDb: MemoryDb,
  q: HybridQuery & { query_vec?: Float32Array; embed?: QueryEmbedder }): Promise<HybridHit[]>
const [bm25Hits, vectorHits] = await Promise.all([bm25Search(...), vectorSearch(...)]);
```

I ran the real recall path (`_bin/rag-recall.sh`, read-only) twice and got genuine,
dated, source-attributed hits — e.g. a 2026-06-20 object recalling
`verbatim=11679, distilled=11455, notes=86`, which independently corroborates both the
growth curve and the frozen note count.

**One real defect found by running it.** First invocation printed:

```
[rag-recall] EMBEDDINGS UNAVAILABLE (Ollama?) — degrading to BM25-only:
Ollama embed timed out after 4000ms at http://127.0.0.1:11434/api/embed
```

Cause: `ollama-keepwarm.service` was `inactive (dead)` (its `.timer` is `active (waiting)`,
so the oneshot had not fired recently). A cold bge-m3 takes **1.72 s** to first-token —
but the model *load* exceeds the hard 4 s `RAG_RECALL_TIMEOUT`. After one warm-up curl,
both subsequent hybrid queries returned full results immediately.

So: hybrid recall is live and correct, but **on a cold model the vector lane silently
drops and recall degrades to BM25-only**. The script is honest about it (prints to stderr,
never fabricates), which is good engineering — but a Veldora deployment must either raise
the timeout or guarantee the model stays pinned. This is a reusable-stack caveat, not a blocker.

UNKNOWN: the MRR=0.9556 figure in the workspace CLAUDE.md. I did not re-run the eval
harness (`packages/rag-engine/src/runner.ts` + `recall-eval-2026-05-25.md`) against the
current 16k corpus. The CLAUDE.md itself flags this as the outstanding verification, and
my measurements do not contradict or confirm it.

---

## 3. Ingestion pipelines

### 3.1 Daemons — both running

```
brain-orchestrator.service  active (running)  since 2026-10-16 08:07:21  PID 3044  102.5 MB
brain-worker.service        active (running)  since 2026-10-16 08:07:38  PID 3363  157.7 MB
brain.target                active
ollama-keepwarm.timer       active (waiting)
ollama-keepwarm.service     inactive (dead)   ← see §2.4
```

Both run compiled JS from `dist/`, not `tsx` from `src/`:
`packages/brain-orchestrator/dist/daemon.js` and
`packages/brain-worker/dist/src/worker-main.js`. (Confirms the CLAUDE.md's 2026-10-14
correction on that point.)

Startup log shows both gates ON and work actually flowing:

```json
{"triggersRegistered":2,"triggersActive":2,
 "gates":[{"name":"nightly-distill","gate":"G4","flag":"BRAIN_ENABLE_NIGHTLY_DISTILL","enabled":true},
          {"name":"queue-watcher","gate":"G6","flag":"BRAIN_ENABLE_QUEUE_WATCHER","enabled":true}]}
[brain-orchestrator] trigger nightly-distill: enqueued task baef4f17-...
[brain-worker: task completed] taskId=baef4f17-... role=distill   (06:28:05Z)
```

Env var **names** in the running process (no values printed, except non-secret booleans
and paths): `BRAIN_ENABLE_NIGHTLY_DISTILL=1`, `BRAIN_ENABLE_QUEUE_WATCHER=1`,
`BRAIN_ROOT=/home/nithu/Obsidian/Brain`, `BRAIN_ORCH_DB_PATH=.../data/brain-orchestrator.db`,
`BRAIN_ORCH_LOG_LEVEL=info`, `OLLAMA_BASE_URL=http://127.0.0.1:11434`. Secret-bearing
names present but **not read**: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `OPENROUTER_API_KEY`,
`LIVEAVATAR_API_KEY`.

### 3.2 The queue watcher only watches two directories

```ts
// packages/brain-orchestrator/src/triggers/queue-watcher.ts:82-83
const DEFAULT_QUEUE_DIRS = [
  "12-youtube/_queue",
  "13-github-repos/_queue",
];
```

`14-books/_queue` is **not in the set.** The source comment at line 65 admits it:
*"keeps it a no-op until the operator opens it, so routing `14-books` here is…"*.

Queue state:

| Queue | Pending | Done | Failed |
|---|---|---|---|
| `12-youtube/_queue` | 1 | 103 | 3 |
| `13-github-repos/_queue` | 1 | 4 | 0 |
| `14-books/_queue` | **2** | **0** | **0** |

### 3.3 **Can it ingest arbitrary PDFs/books today? No. Three independent blockers.**

This is the decisive question for Veldora and the answer is unambiguous.

**Blocker 1 — PDF is not a supported format, at all.**

```ts
// packages/book-ingest/src/queue.ts:20
const VALID_EXT_RE = /\.(epub|txt)$/i;
export function extFormat(source: string): "epub" | "txt" | "none" {
  if (/\.epub$/i.test(source)) return "epub";
  if (/\.txt$/i.test(source)) return "txt";
```

`extract.ts` dispatches `epub → extractEpub` (shells to `unzip -Z1` / `unzip -p`, strips
XHTML tags), `txt → extractTxt`, and the module docstring is explicit: *"`.txt` sources
are read directly. **Anything else rejects.**"* There is no PDF branch, no `pdftotext`
seam, no OCR. A queued `.pdf` fails `parseQueueFile` → moved to `_failed/` with
`reason=malformed_source`.

**Blocker 2 — the drainer is env-gated OFF.**

```ts
export const BOOK_INGEST_ENV_FLAG = "BOOK_INGEST_ENABLED";
if (process.env[BOOK_INGEST_ENV_FLAG] !== "1") return result;  // {processed:0}
```

`BOOK_INGEST_ENABLED` is **absent from the running daemon's environment** (verified
against `/proc/3044/environ`). The package's own docstring: *"this lands dark twice over."*

**Blocker 3 — nothing would call it anyway**, per §3.2.

**Blocker 4 (soft) — the distiller is deliberately lossy for copyright.**
Even once enabled, `book-ingest` is architecturally incapable of storing a book faithfully.
It runs a quote-overlap guard that **hard-fails the item** if the output shares >10
consecutive words with the source:

```ts
const run = longestVerbatimRun(probe, extracted.text);
if (run > 10) return { ok: false, reason: `quote_overlap: ${run} consecutive words` };
```

Verbatim text goes to gitignored `_library/books/`; only a paraphrased note is kept.
**For tender documents this is exactly backwards.** Veldora must quote kravspesifikasjoner
verbatim — clause-level fidelity is the product. The copyright guard that makes this
pipeline safe for Rob Carver makes it unusable for a kravspesifikasjon.

**Conclusion: the pipeline handles YouTube URLs and GitHub search specs well
(103 + 4 processed). For books it is unproven and switched off; for PDFs it is
not implemented; and its distillation contract is wrong for tender documents.
Veldora needs its own PDF extraction path regardless.**

### 3.4 Accepted input formats, summarised

| Pipeline | Accepts | Rejects | Status |
|---|---|---|---|
| `youtube-ingest` | one `.url` file per **single video** | `.txt` lists, channel URLs, playlists (→ `_queue/_manual/`) | working, 103 done |
| `github-discovery` | `.md` search-spec files | — | working, 4 done |
| `book-ingest` | `.book` pointer file → `.epub` / `.txt` | **`.pdf`, `.docx`, everything else** | **never run; gated off; not watched** |
| `obsidian-ingest` | Brain `.md`, chunked on headings | — | ran once 2026-06-19, 86 notes, dormant |

---

## 4. Skill registry

`~/Obsidian/Brain/03-skills/` — 11 markdown files, Tier-3 of a three-tier model
(Tier 1 orchestrator built-ins, Tier 2 project agents, Tier 3 reusable skills).
Subfolders `_proposed/` (auto-drafts awaiting review), `_archived/` (superseded),
`_system/` (read-only mirrors of CLI-bundled skills).

Existing skills: `brain-recall`, `brain-distill-daily`, `brain-task-claim`,
`brain-task-complete`, `brain-task-list`, `youtube-ingest`, `github-discover`,
`multi-agent-dispatch`, `worktree-spawn-cleanup`, plus `TOOLBOX-MOC.md` (master index)
and `README.md`.

Caveat: `brain-task-claim` / `brain-task-complete` reference
`firm-task-claim.sh`/`firm-task-complete.sh`, which per the workspace CLAUDE.md **do not
exist on HEAD**. Those two skills are documentation of an unbuilt lifecycle.

### Authoring pattern (copy this for anbud skills)

Filename is kebab-case and **must equal the `name` field** — the filename is the
invocation token. Frontmatter as actually written on disk:

```yaml
---
name: youtube-ingest                  # kebab-case, == filename
description: Run the youtube-ingest pipeline on a URL (or drain the queue) — ...
tier: brain                           # workspace | project | brain
project_scope: workspace
when_to_use: operator drops a URL in `12-youtube/_queue/`, OR runs manually;
             keywords "ingest video", "youtube transcript", "distill talk"
inputs:
  - name: url
    type: url
    required: false
    default: drain-queue
outputs:
  - note_path: string
  - distill_confidence: number
harness_tools: [Bash]                 # Claude-side tools
system_tools: [git, gh]               # CLI binaries required
auto_invocable: false                 # true = orchestrator may fire unprompted
created: 2026-05-25
---
```

Note the README documents a slightly different schema (`version` semver, `triggers` array,
`tier: 3`, `status:`) than the files actually use (`tier: brain`, `when_to_use`,
`harness_tools`/`system_tools`, `auto_invocable`). **Follow the files, not the README** —
`@cc/skill-registry`'s `parseSkillMd` is what consumes them.

Lifecycle: draft → `_proposed/` → operator review → promote to root → invoke by name →
superseded version moves to `_archived/`. Documented anti-patterns: one-off scripts
(those belong in project repos), vague triggers, editing `_system/`, and skills that
bypass operator gates for irreversible actions.

`@cc/skill-registry` (`packages/skill-registry`) exports `discoverSkills`, `parseSkillMd`,
`invokeSkill`, `findSkill`, `extractSection`, `extractCodeBlocks`,
`proposeSkillFromTask`, `renderProposedSkillMd`, `recordValidationPass/Failure`,
`TIER_PRECEDENCE`. REST/CLI, watchers, SQLite cache and trigger-binding are deferred.
`main` points at `./src/index.ts` (not built) — it is consumed in-repo via tsx.

---

## 5. Reusable packages

All under `~/code/command-center/packages/`. (A full mirror exists at
`~/code/cc-leakscan/packages/` — a scan copy, not a second source of truth.)

| Package | Built? | Role |
|---|---|---|
| `@cc/memory-engine` | `dist/` | schema, distill, storage, facets, embedder seam |
| `@cc/rag-engine` | `dist/` | BM25 + vector + CombMNZ, rerank, agentic loop, eval |
| `@cc/brain` | `dist/` | thin read-only vault reader (**not** the RAG layer) |
| `@cc/obsidian-ingest` | src only | vault → `note` rows in memory.db |
| `@cc/book-ingest` | `dist/` | epub/txt → copyright-safe note (§3.3) |
| `@cc/youtube-ingest`, `@cc/github-discovery` | `dist/` | queue drainers |
| `@cc/brain-orchestrator`, `@cc/brain-worker` | `dist/` | the two daemons |
| `@cc/skill-registry` | src only | §4 |

### 5.1 `@cc/memory-engine`

```ts
// storage
getDb(path: string = ":memory:"): MemoryDb    // ← path is a PARAMETER
closeDb(); migrate(db);
insertVerbatim, getVerbatimById, queryVerbatimFts
insertDistilled, getMemoryObjectById, getMemoryObjectsByVerbatim,
queryDistilledFts, queryDistilledVector, upsertEmbedding
recordDeadLetter, openDeadLetters, resolveDeadLetter, deadLetterDates
// distillation
distill, distillReal, distillAndInsert, validateMemoryObject, assertValidEmbedding
buildUserPrompt, SYSTEM_PROMPT, top15IDFTokens, PROMPT_VERSION
makeHaikuDistiller                       // Claude Haiku 4.5; INERT without ANTHROPIC_API_KEY
// embedding seam
bgeM3Embedder, fakeEmbedder, embedTextFor, type Embedder
BGE_M3_DIM (1024), OPENAI_LARGE_DIM
// facets
deriveFacets, upsertFacet, backfillFacets
extractFilesTouched, FILE_PATH_REGEX
```

### 5.2 `@cc/rag-engine`

```ts
hybrid(memoryDb, q)                       // BM25 ∥ vector → CombMNZ
bm25Search, vectorSearch, combMNZ, EMBEDDING_DIM
embedText, embedBatch, resolveEmbeddingConfig, EmbeddingError   // bge-m3 via Ollama
rerank.*                                  // bge-reranker + Cohere providers
agentic.*                                 // Tier-3 plan/evaluate/generate loop
runEval, parseEvalSet, computeMRR, computeNDCGAtK, computePAtK, renderResultsMarkdown
types: HybridQuery, HybridHit, LaneHit, SemanticChunk, SourceRef, RerankResult, RetrievalFn
```

Note the dependency direction: `rag-engine` imports `type { MemoryDb } from "@cc/memory-engine"`
— a **type-only** coupling over a `better-sqlite3` handle. That is a clean seam.

### 5.3 `@cc/brain` — smaller than its name suggests

```ts
export { brainRoot, listProjectNotes, readProjectNote, getProjectCard };
export type { BrainNote };
```

Two source files. A read-only filesystem reader for the vault, powering the dashboard's
`BrainPanel`. **Not** the retrieval engine — do not confuse the two when planning.

### 5.4 How Veldora consumes these without breaching ADR-001

ADR-001 forbids a **shared DB** and **shared in-process imports** between command-center
and any other project. The architecture already accommodates this, almost accidentally:

**`getDb(path)` takes the database path as a parameter.** There is no hardcoded singleton
location — `storage/db.ts:52` names the canonical path only in a *comment*. So:

1. **Vendor, don't link.** Copy `memory-engine` + `rag-engine` into the Veldora repo (or
   publish both to a private registry and depend on a pinned version). Do **not** add a
   path-dependency or npm-workspace link into `~/code/command-center` — that is precisely
   the "shared imports" ADR-001 prohibits, and it would make Veldora unbuildable whenever
   command-center is mid-refactor.
2. **Separate database file.** `getDb("/home/nithu/code/Veldora/data/veldora-memory.db")`
   then `migrate()`. Same schema, same vec0 partitioning, zero rows shared. Veldora's
   `project` partition key becomes `veldora` / per-tender keys. ADR-001's "survives any
   peer being down" test passes: command-center can be deleted and Veldora keeps working.
3. **Share the Ollama daemon, not the data.** `OLLAMA_BASE_URL=http://127.0.0.1:11434`
   with `bge-m3` is a loopback HTTP service — a *loose interface*, explicitly the kind
   ADR-001 permits (file + HTTP only). Both products can embed against one warm model.
   Raise the embed timeout above 4 s or pin the model (§2.4).
4. **If Veldora ever needs the operator's Brain knowledge**, read it over HTTP from
   command-center's `/api/brain/:id`, or re-ingest the vault into Veldora's own DB with
   `obsidian-ingest`. Never open command-center's `memory.db` directly.

Costs to budget: `better-sqlite3` + `sqlite-vec` are native modules (note the CLI
`sqlite3` binary could not load `vec0` — the extension loads only through the Node
package, which is why I counted vectors via `distilled_vec_rowids`). `uuid` and the
Anthropic SDK are the only other notable deps.

---

## 6. Verdict for Veldora

**Reuse the retrieval engine. Build the ingestion. Ignore the corpus.**

**Reuse — the engine is genuinely good and genuinely proven.** 16,008 objects,
100% embedded at bge-m3/1024, BM25 + vector + CombMNZ fusion with rerank and an agentic
tier already written, zero open deadletters, a full capture→distill→embed cycle that
closed 2 hours before I measured it, and append-only guarantees enforced at the trigger
level. Rebuilding this is weeks of work to arrive somewhere worse. `getDb(path)` makes
the ADR-001-clean split trivial: vendor the two packages, point at a Veldora-owned
`.db`, share only the loopback Ollama endpoint.

**Build — ingestion is where Veldora is genuinely on its own.** `book-ingest` rejects
PDFs outright (`/\.(epub|txt)$/i`), is gated off (`BOOK_INGEST_ENABLED` unset), is not
in the watcher's `DEFAULT_QUEUE_DIRS`, and has processed exactly zero items in four
months. Worse, its >10-consecutive-word copyright guard is the opposite of what tender
work needs — Veldora must quote kravspesifikasjoner *exactly*. Veldora needs its own
PDF path (`pdftotext`/`unstructured`/OCR for scanned municipal attachments), its own
Norwegian-aware chunker, and a verbatim-preserving store. The *shape* to copy is
`drainBookQueue`'s injectable-extractor seam and `_queue/_done/_failed` audit trail;
the implementation is new.

**Ignore the corpus.** 62 MB and 2,093 files, but the content is trading strategies,
battery-electrolyte thesis work, and the operator's own dev-session history —
98.3% of the index is `source_type='conversation'`. Zero tender content. The two books
are Rob Carver and Halls-Moore, both unprocessed. The one anbud artifact
(`Runbook-Anbud-Triage.md`) is a UI runbook for Veldora's existing dashboard, useful as
a spec, not as knowledge. "Train Veldora on everything I already own" does not describe
a real asset here — the owned material is trading and thesis knowledge.

**Two caveats to carry into the design:**

1. *The curated-knowledge loop is broken even for its owner.* `obsidian-ingest` ran once
   on 2026-06-19 and indexed 86 of 2,093 files (**4.1%**). If Veldora's value depends on
   recalling curated documents, do not inherit this gap — wire ingestion to a trigger from
   day one, and treat "notes are in the index" as a monitored invariant, not an assumption.
2. *Cold-start silently degrades recall.* A cold bge-m3 blows the 4 s timeout and the
   vector lane drops without the caller noticing (the script prints to stderr, which a
   service would swallow). For a product, make embedding failure loud and fail-closed.

**UNKNOWN / not verified:** the MRR=0.9556 eval figure against the current 16k corpus;
memory-engine corpus-IDF correctness; whether the `ai-assistent--claude-worktrees-*`
project-key fragmentation measurably hurts nexus recall; whether `@cc/book-ingest`'s epub
path works on real input (no item has ever been processed, so its 1,001-test suite has
only ever run against fakes).
