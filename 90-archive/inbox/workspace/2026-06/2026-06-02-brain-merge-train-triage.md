---
title: Brain Merge-Train Triage Plan — command-center sprint-2 (~70 PR backlog)
date: 2026-06-02
author: claude (code-1 triage pass)
repo: /home/nithu/code/command-center
status: PLAN — operator-gated, NO PR merged or closed by Claude
---

# Brain Merge-Train Triage Plan

**Scope:** `/home/nithu/code/command-center`, default branch `main`. 67 open PRs (gh shows #1–#74 with gaps).
**Goal:** turn "70 PRs, no idea what to merge" into ONE ordered train + a dedupe list, so the operator makes one gated decision instead of 70.

> Provenance convention used throughout:
> **[gh]** = directly observed via `gh pr list` / `gh pr checks` / `git ls-tree`.
> **[infer]** = my reasoning from branch contents / file diffs / lane memory.

---

## 0. Ground truth — current state of `main` (gh)

`git ls-tree origin/main` confirms the sprint-2 brain packages are **NOT merged**:

| Package | On `main`? | Notes |
|---|---|---|
| `packages/brain` | YES (5 files) | **skeleton only** — `brain.ts` + test + index + pkg/tsconfig. Pre-sprint. |
| `apps/api/src/routes/brain.ts` | **YES** | [gh] route + test ARE on main → PR #11 (C1-7, 5 brain endpoints) **already landed**. |
| `packages/memory-engine` | NO (0 files) | empty on main |
| `packages/rag-engine` | NO (0 files) | empty on main |
| `packages/skill-registry` | NO (0 files) | empty on main |
| `packages/youtube-ingest` | NO (0 files) | empty on main |
| `packages/github-discovery` | NO (0 files) | empty on main |
| `packages/brain-orchestrator` | NO (0 files) | empty on main |

So: **4 of 5 (+orchestrator = 5 of 6) new `@cc` packages are absent from main.** The task's premise holds. The one nuance vs the brief: the *brain-api-routes* layer (#11) and the *003 sync migration* (#3) appear already merged (route + you'll want to re-confirm migration landing) — see §3 collision notes.

**Root `package.json` wiring gap (gh):** `build` and `typecheck` scripts on `main` enumerate only the 11 legacy packages (shared, bus, engines, git, router, executor, agents, github, sync, brain, auth) + apps. **None of the 6 new packages are listed.** Meaning: even after they merge, `npm run build` / `npm run typecheck` at root will silently skip them. CI `verify` currently passes on the PRs because it runs per-workspace `vitest` (not the root build), so **green CI today does NOT prove the packages build in the root graph.** [infer, high-confidence]

---

## 1. PR inventory (gh)

Grouped by brain module. `D` = draft, mergeState in parens. All are drafts unless noted.

### A — orchestrator (`packages/brain-orchestrator`)
| PR | Branch | State | Note |
|---|---|---|---|
| #1 | code-1/brain-orchestrator-skel | CLEAN | skeleton, base of C1 stack |
| #8 | code-1/orchestrator-triggers | CLEAN | nightly-distill trigger (G4-gated) |

### B — memory-engine (`packages/memory-engine`)
| PR | Branch | State | Note |
|---|---|---|---|
| #2 | code-1/memory-engine-skel | CLEAN | schema + distill skel (C1-2) |
| #12 | code-1/memory-engine-storage | CLEAN | FTS5 + sqlite-vec storage (C1-3); src: storage/{db,distilled,verbatim,migrate} |
| #47 | code-1/memory-engine-distill-real | CLEAN | real distill→Haiku 4.5, env-gated (default stub); 27 tests |
| #24 | code-1/distill-backfill | CLEAN | audit_log→agent_tasks backfill (003b) |

### C / sync-migration (`packages/sync`)
| PR | Branch | State | Note |
|---|---|---|---|
| #3 | code-1/distill-migration | CLEAN | 003 agent_tasks/results/audit migration (C1-9); 24 tests |

### D — skill-registry (`packages/skill-registry`)
| PR | Branch | State | Note |
|---|---|---|---|
| #51 | code-2/skill-registry-impl | CLEAN | full impl (16 files) |
| #61 | code-2/skill-registry-full | CLEAN | **identical 16 files** to #51 (re-push) |
| #15 | code-1/skill-contract-doc | CLEAN | SKILL_REGISTRY_CONTRACT v1.0 (doc only) |

### E — youtube-ingest (`packages/youtube-ingest`)
| PR | Branch | State | Note |
|---|---|---|---|
| #52 | code-2/youtube-ingest-impl | CLEAN | impl (16 files) |
| #62 | code-2/youtube-ingest | CLEAN | **identical 16 files** to #52 (re-push) |

### F — github-discovery (`packages/github-discovery`)
| PR | Branch | State | Note |
|---|---|---|---|
| #53 | code-2/github-discovery-impl | CLEAN | pilot impl, 76 tests (18 files) |
| #59 | code-2/github-discovery | CLEAN | **identical 18 files** to #53 (re-push) |

### G/K — rag-engine (`packages/rag-engine`)
| PR | Branch | State | Note |
|---|---|---|---|
| #7 | code-1/rag-engine-hybrid | CLEAN | hybrid skeleton (C1-4 scaffold) |
| #9 | code-1/rag-engine-rerank | CLEAN | rerank skeleton (C1-5) |
| #13 | code-1/rag-engine-agentic | CLEAN | agentic skeleton (C1-6) |
| #39 | code-1/rag-engine-hybrid-real | CLEAN, **not draft** | real hybrid vs C1-3 storage; 15 tests |
| #66 | code-1/rag-engine-rerank-real | CLEAN | real bge-reranker-v2-m3, env-gated; 23 tests |
| #70 | code-1/rag-engine-agentic-real | CLEAN | real LLM T3 loop, env-gated; 81 tests |
| #74 | code-1/rag-engine-chain-integration | CLEAN | **cumulative superset** — full T2+T3 chain + integration test (34 rag files incl cli/metrics/parse-eval-set/rerank/agentic) |
| #56 | code-2/rag-engine-eval-runner | CLEAN | eval-runner additive (stacks on #7/#9/#13/#39); 31 rag files |
| #60 | code-2/rag-engine-eval-runner-v2 | CLEAN | eval-runner CLI + metrics + parse-eval-set scaffold (14 rag files) |

### brain-api-routes (`apps/api/src/routes/brain.ts`)
| PR | Branch | State | Note |
|---|---|---|---|
| #11 | code-1/brain-api-routes | CLEAN | 5 endpoints. **route already on main → likely merged-equivalent.** |
| #14 | code-1/api-14b-endpoints | CLEAN | GET /api/commands filters + POST /api/agents/report |

### web /brain pages (`apps/web`)
| PR | Branch | State | Note |
|---|---|---|---|
| #55 | code-2/web-brain-impl | CLEAN | full brain UI — title says "supersedes #36/#40/#44/#45 scaffolds" (those already gone from open list) |
| #41 | code-1/web-nav-brain-section | CLEAN | desktop TopNav Brain dropdown |

### lockfile / build-wiring
| PR | Branch | State | Note |
|---|---|---|---|
| #58 | code-2/workspace-lockfile-sync | CLEAN | register new packages in lockfile + coverage scripts |
| #57 | code-2/template-package | CLEAN | `_template` boilerplate (8 files) |
| #50 | code-2/packages-template-plus-plan | CLEAN | **identical `_template`** to #57 + COMMIT_PLAN |
| #33 | code-1/typecheck-self-contained | CLEAN | make typecheck not require build first |
| #34 | code-1/ci-package-matrix | CLEAN | split verify into per-package matrix |

### coverage-gate
| PR | Branch | State | Note |
|---|---|---|---|
| #5 | code-1/test-coverage-brain | CLEAN | coverage runner + integration test plan |
| #68 | code-1/coverage-gate-plan | CLEAN | doc: coverage gate enforcement (G-9) |

### integration-tests (`packages/integration-tests`)
| PR | Branch | State | Note |
|---|---|---|---|
| #49 | code-2/integration-tests | **UNSTABLE — CI RED** | depends on 4 `@cc/*` not yet on main → `npm i` E404 |
| #25 | code-1/brain-integration-tests | CLEAN | orchestrator+memory-engine E2E test |
| #69 | code-2/api-slice-3-4-tests | CLEAN | Slice 3/4 api unit tests |

### Phase-14b agent / infra (adjacent, not brain-RAG core)
| PR | Branch | State | Note |
|---|---|---|---|
| #4 | code-1/phase-14b-agent-scaffold | CLEAN | agent poller scaffold |
| #18 | code-1/agent-tests-ci | **DIRTY — merge conflict** | poller/executor unit tests |
| #27 | code-1/agent-bootstrap-script | CLEAN | per-machine bootstrap |
| #43 | code-1/discord-agent-failures | CLEAN | Discord webhook on agent failure |
| #46 | code-1/agent-heartbeat-discord | CLEAN | Discord self-heartbeat |
| #63 | code-2/agent-poller | CLEAN | per-machine poller (Phase 14b) — **overlaps #4/#27** [infer] |
| #6 | code-1/health-hosted-mode | CLEAN | /api/health "ok" in hosted mode |
| #16 | code-1/14c-twosvc | CLEAN | two-Railway-service pivot (Slice 14c) |
| #64 | code-2/firm-task-scripts | CLEAN | firm system-prompt + task claim/complete |
| #48 | code-2/bin-brain-scripts | CLEAN | _bin brain-preflight + firm-task CLI |
| #72 | code-2/firm-tab-init-presence-prompt | CLEAN | stacks on #48 |

### Pure-docs / verify drops (no code — batch-merge or close, low priority)
#10, #17, #19, #20, #21, #22, #23, #26, #28, #29, #30, #31, #32, #35, #37, #38, #42 (not draft), #54, #65, #67, #71, #73 — runbooks, decision matrices, CI snapshots, verify logs, security review, merge-order docs, master brief. [gh: all CLEAN]. None block the train; many are now stale (they describe the pre-merge backlog).

---

## 2. CI status snapshot (gh `pr pr checks`)

- **GREEN (verify + smoke pass):** #1,#2,#3,#7,#11,#12,#39,#51,#52,#53,#55,#58,#59,#61,#62,#66,#70 — i.e. essentially all the code PRs I sampled.
- **RED:** **#49** — `verify` FAIL (11s, fails fast). Cause per its own body: declares workspace deps on `@cc/rag-engine`, `@cc/memory-engine`, `@cc/skill-registry`, `@cc/youtube-ingest` that are **not on main**, so `npm install` at repo root throws `E404 @cc/...`. It cannot go green until those packages land. [gh body + infer]
- **DIRTY (merge conflict, needs rebase):** **#18** (`code-1/agent-tests-ci`).
- **UNSTABLE:** #49 (mergeStateStatus UNSTABLE, matches the RED verify).

**Build-wiring caveat (infer):** every new-package PR is green only because CI verify = per-workspace vitest. After merge, root `npm run build` / `typecheck` will not include the new packages until #58 (lockfile/coverage) **plus a root-script edit** lands. #58 as described registers lockfile + coverage scripts; confirm it also patches the root `build`/`typecheck` enumerations — if not, that's a one-line follow-up the train needs.

---

## 3. Dedupe / supersede recommendations (KEEP one, CLOSE rest)

Verified by `git diff --stat` between branch pairs (file-level) and by `git ls-tree` package contents.

### 3.1 skill-registry — KEEP **#61**, CLOSE #51
`git diff origin/code-2/skill-registry-impl..origin/code-2/skill-registry-full` over `packages/skill-registry` = **empty (identical 16 files)**. #61 is the newer re-push with the "full" framing. Keep the newer; close #51 as superseded-identical. (#15 = contract doc, keep separately or fold into merge commit.)

### 3.2 youtube-ingest — KEEP **#62**, CLOSE #52
`diff impl..youtube-ingest` over `packages/youtube-ingest` = **empty (identical 16 files)**. Keep newer #62, close #52.

### 3.3 github-discovery — KEEP **#59**, CLOSE #53
`diff impl..github-discovery` over `packages/github-discovery` = **empty (identical 18 files)**. Keep newer #59, close #53.

### 3.4 `_template` — KEEP **#57**, CLOSE #50
`diff packages-template-plus-plan..template-package` over `packages/_template` = **empty (identical 8 files)**. #50 also carries a COMMIT_PLAN doc — salvage that doc if wanted, otherwise close #50.

### 3.5 rag-engine C1 stack — KEEP **#74**, CLOSE #7, #9, #13, #39, #66, #70
`git ls-tree` proves **#74 (chain-integration) is the cumulative superset**: 34 rag-engine files including bm25/fusion/hybrid (#7/#39), rerank/* (#9/#66), agentic/* (#13/#70), **plus** cli/metrics/parse-eval-set and the full `tests/integration/full-rag-chain.test.ts`. `rev-list` shows rerank-real→agentic-real = 1 commit, agentic-real→chain-integration = 3 commits — a clean linear stack. Merging #74 brings the entire C1 rag lane in one shot.
- One canonical PR: **#74**. Close #7/#9/#13/#39/#66/#70 as "rolled up into #74". (Or keep #39 alone if you prefer smaller reviewable hops — but then you'd merge the same code twice.)

### 3.6 rag-engine eval-runner (C2) — CLOSE BOTH #56 and #60 (rolled into #74)
#74 already contains `cli.ts`, `metrics.ts`, `parse-eval-set.ts`, `runner.ts` — the exact surface #56/#60 add. `diff eval-runner..eval-runner-v2` shows v2 *removes* ~1974 lines vs v1 (it's a slimmer scaffold). Since #74 supersedes both, recommend **CLOSE #56 and #60** rather than dedupe between them. If the operator wants the C2 eval-runner kept independent, KEEP **#60** (v2, the maintained one) and CLOSE #56 — but only if #74 is *not* taken, which contradicts §3.5. Net: with #74 as canon, both C2 eval PRs close.

### 3.7 integration-tests — KEEP **#49** (do NOT close), but it merges LAST
#25 (C1) = orchestrator+memory E2E; #49 (C2) = cross-package E2E over all 4 packages. They test different seams [infer] — not strict duplicates. Keep both; #49 stays RED until its deps land and merges at the end of the train (see §4). #69 (api slice tests) is independent — keep.

### 3.8 brain-api-routes — #11 likely already MERGED
`apps/api/src/routes/brain.ts` + test are on `main` [gh]. The lane memory documented a C1-vs-C2 contest over this file, resolved in C1's favor. **Action: verify #11 is merged/closed; if still "open" it's a no-op diff — close it.** This matches memory note: "code-1 had already shipped PR #11 ... before reading the reply."

### 3.9 agent-poller — KEEP C1 set (#4/#27), reconcile #63
#63 (code-2/agent-poller) overlaps #4 (scaffold) + #27 (bootstrap) [infer from titles; both target `apps/agent` poller]. Recommend operator diff #63 against #4+#27; likely **CLOSE #63** or cherry-pick its delta. Not on the brain-RAG critical path either way.

### 3.10 sync migration #3 — confirm landing
Memory says #3 (003 migration, 24 tests) shipped. Verify whether it's on main; if the `003_*` migration file is already in `packages/sync`, **close #3**; else it's step 3 of the train.

**Dedupe close-list (recommended):** #51, #52, #53, #50, #7, #9, #13, #39, #66, #70, #56, #60 — and (pending verify) #11, #63, #3. That removes ~12–15 PRs without losing any code.

---

## 4. The merge train (ordered, dependency-respecting)

Each step: prerequisite → PR(s) → CI state → blocker. Operator merges top-to-bottom, gated.

| # | Step | PR(s) to merge | CI (gh) | Blocker / note |
|---|---|---|---|---|
| 0 | **Confirm already-landed** | (verify #11 route, #3 migration on main) | — | If present, close those PRs; don't re-merge. |
| 1 | **Build-wiring + lockfile** | **#58** (+ #57 `_template`) | GREEN | **MUST also patch root `package.json` build/typecheck to list the 6 new packages** — confirm #58 does this; if not, add a follow-up commit. This is the gate that makes everything else actually build at root. |
| 2 | (optional) typecheck self-contained | #33, #34 | GREEN | Quality-of-life; lets per-package typecheck run without full build. Merge before or with step 1. |
| 3 | **brain-orchestrator skeleton** | **#1** | GREEN | base of C1 stack; no deps. |
| 4 | **memory-engine: schema → storage → distill** | **#2 → #12 → #47** (then #24 backfill) | GREEN | strict order: skel(#2) before storage(#12) before real-distill(#47). #24 backfill after #47. rag-engine depends on #12's storage surface. |
| 5 | **sync migration 003** | **#3** (if not already on main) | GREEN | provides agent_tasks/results/audit tables the distill backfill (#24) and orchestrator use. |
| 6 | **rag-engine full chain** | **#74** (rolls up hybrid→rerank→agentic + eval-runner) | GREEN | depends on memory-engine storage (#12) being merged — `vector.ts` imports `@cc/memory-engine` (`queryDistilledVector`, `BGE_M3_DIM`). Do NOT merge before step 4. |
| 7 | **EMBEDDING — bge-m3** | *(none — does not exist)* | N/A | **GAP. No PR builds this.** See §6 spec. This is the missing link between "user query string" and the vector lane (which only accepts a pre-embedded `Float32Array`). Build AFTER #74 lands so the new file plugs into the merged rag-engine without collision. |
| 8 | **orchestrator triggers** | **#8** (nightly-distill, G4-gated) | GREEN | depends on memory-engine (#47) + orchestrator (#1). Keep G4 gate OFF until operator opts in (per CLAUDE.md no-auto-cron). |
| 9 | **ingest packages** | **#61** (skill-registry), **#62** (youtube), **#59** (github) | GREEN | independent of rag-engine; can merge anytime after step 1. Order among them is free. |
| 10 | **API routes (14b)** | **#14** (+ confirm #11 done) | GREEN | brain endpoints (#11) appear landed; #14 adds commands/agents/report. |
| 11 | **web /brain pages** | **#55** (UI), **#41** (nav) | GREEN | #55 needs the brain API endpoints (step 10) live to be useful; merge after #14. |
| 12 | **integration-tests** | **#25** (C1 E2E), **#49** (C2 cross-pkg) | #25 GREEN; **#49 RED until steps 4/6/9 land** | #49 only goes green once memory-engine + rag-engine + skill-registry + youtube are on main (its E404 deps). Re-run CI after step 9, then merge. #69 api tests anytime. |
| 13 | **coverage gate** | **#5** (runner), **#68** (enforcement plan) | GREEN | LAST — enabling a coverage gate before the packages are in breaks CI. Turn the gate to "report" first, "enforce" only after operator OK. |
| — | **Docs/verify backlog** | #10,17,19–23,26,28–32,35,37,38,42,54,65,67,71,73 | GREEN | batch-merge the still-relevant ones, close stale snapshots. Not on critical path. |
| — | **Adjacent infra** | #6 health, #16 14c-twosvc, #4/#27 agent, #43/#46 discord, #64/#48/#72 firm | mostly GREEN; **#18 DIRTY** | separate lane; merge on their own gated pass. Rebase **#18** to clear the conflict before merging. Reconcile **#63** vs #4/#27 first (§3.9). |

**One-paragraph summary of the train:** wire the build (#58) → land memory-engine (#2,#12,#47,#24) and the sync migration (#3) → land the rolled-up rag-engine (#74) → **build the missing bge-m3 embedder** → orchestrator trigger (#8) → ingest packages (#61,#62,#59) → API (#14) → web (#55,#41) → integration tests (#25,#49) → coverage gate (#5,#68). Dedupe-closes happen as each canonical PR merges.

---

## 5. CI-RED / won't-build flags

1. **#49 integration-tests — RED (gh: verify fail).** Root cause: depends on `@cc/{rag-engine,memory-engine,skill-registry,youtube-ingest}` not on main → `npm install` E404. **Not a code bug — a merge-order artifact.** Goes green automatically once steps 4/6/9 land. Merge it last; re-run checks first.
2. **#18 agent-tests-ci — DIRTY (merge conflict).** Needs rebase on current main before it can merge. Not brain-RAG core.
3. **Root build/typecheck blindspot [infer].** The 6 new packages are absent from root `package.json` `build` and `typecheck` script lists. Every new-package PR shows green only because CI runs per-workspace `vitest`, which does not exercise the root build graph. **Until #58 (or a follow-up) edits those two script strings to include the new packages, `npm run build` at root will silently skip them and a real type error could land undetected.** Treat step 1 of the train as load-bearing, and add an assertion: after step 1, `npm run typecheck` at root must name all 6 packages.
4. **No embedding generation anywhere [gh+infer].** `packages/rag-engine/src/vector.ts` (even on the most-complete branch #74) explicitly only accepts a pre-embedded `query_vec: Float32Array`; its own header comment says "the real bge-m3 query embedding lands in C1-5" — but C1-5 turned out to be the *reranker* (#66), not the embedder. **The embed step was planned and never built.** This is the single biggest functional hole: the RAG vector lane is non-functional end-to-end for a raw text query until §6 is implemented.

---

## 6. Design spec — `packages/rag-engine/src/embedding/bge-m3.ts`

**DO NOT implement now** — it would collide with the in-flight rag-engine PRs (#74 and the stack). Build it as a fresh commit *after* #74 merges. Spec below is implementation-ready.

### 6.1 Purpose
Turn raw text into 1024-dim embeddings so the rag-engine vector lane can serve real string queries (and so the memory-engine distill path can embed distilled objects at write time). Closes the gap in §5.4.

### 6.2 Module interface
```ts
// packages/rag-engine/src/embedding/bge-m3.ts

/** bge-m3 embedding dimension — LOCKED at 1024. Must equal @cc/memory-engine BGE_M3_DIM. */
export const BGE_M3_DIM = 1024 as const;

export interface EmbedOptions {
  /** max texts per forward pass; default 32. */
  batchSize?: number;
  /** "auto" picks transformers→ollama→error; or force a backend. */
  backend?: "transformers" | "ollama" | "auto";
  /** normalize to unit L2 (recommended; cosine == dot product). default true. */
  normalize?: boolean;
  signal?: AbortSignal;
}

/**
 * Embed N texts → N Float32Array(1024).
 * Order-preserving; output[i] corresponds to texts[i].
 * Throws if no backend is available (never silently returns []).
 */
export function embed(texts: string[], opts?: EmbedOptions): Promise<Float32Array[]>;

/** Convenience single-text wrapper. */
export function embedOne(text: string, opts?: EmbedOptions): Promise<Float32Array>;

/** Probe which backend is live (for health endpoint / startup log). */
export function probeBackend(): Promise<"transformers" | "ollama" | "none">;
```

### 6.3 Backends (privacy-first, local-only)
**Primary: `@huggingface/transformers` (Transformers.js), model `Xenova/bge-m3` (or `BAAI/bge-m3` ONNX).** Runs in-process on the node, on the GPU when available (the operator's node has a GPU — ties directly to the privacy rationale). Lazy-load the pipeline once, cache the module-level singleton; first call pays model-load cost, subsequent calls are warm.

**Fallback: Ollama, model `bge-m3`,** via `POST http://localhost:11434/api/embed` (or `/api/embeddings`). Used when Transformers.js can't init (no ONNX runtime / WASM issue) but a local Ollama daemon is running.

**`backend: "auto"` order:** transformers → ollama → throw. **Never** an external/cloud embedding API.

**Privacy rationale (binding):** brain memory contains sensitive operator data (trading strategy, finances, personal). Embeddings are computed **locally on the node GPU** and never sent to any external API. This is why the spec hard-excludes OpenAI/Cohere/Voyage embedding endpoints — unlike the *reranker* (#66) and agentic LLM (#70) which are env-gated opt-ins, the embedder has **no cloud option at all.** Sensitive text never leaves the machine.

### 6.4 Batching & perf
- Chunk `texts` into `batchSize` (default 32) slices; one forward pass per slice; concat results preserving order.
- Truncate each text to the model max (8192 tokens for bge-m3) — long brain notes are pre-chunked upstream by youtube-ingest/memory-engine, but guard anyway.
- Singleton pipeline (module-level promise) so the model loads once per process.
- Respect `signal` for cancellation; honor a soft timeout pattern like #66's reranker (2s) at the *caller* if used on the request path — but the embed itself shouldn't hard-timeout a batch write.

### 6.5 Where it plugs into the rag-engine vector lane
Today `vectorSearch(memoryDb, q)` requires `q.query_vec?: Float32Array` and returns `[]` when it's missing. After this module exists:
- **Query path:** the hybrid orchestrator calls `embedOne(q.q)` to populate `query_vec` before calling `vectorSearch`. Add a thin `ensureQueryVec(q)` helper in `hybrid.ts` that lazily embeds when `query_vec` is absent.
- **Write/index path:** `@cc/memory-engine` storage (`distilled.ts`) calls `embed([distilledText])` when persisting a distilled object, storing the 1024-dim vector into the sqlite-vec index. (Coordinate the import direction — likely `memory-engine` imports the embedder, or the embedder lives in a tiny shared `@cc/embedding` package to avoid a rag-engine→memory-engine→rag-engine cycle. **Recommend a standalone `packages/embedding` or `rag-engine/src/embedding/` with no `@cc/memory-engine` import** so memory-engine can depend on *it*, not vice-versa.)
- **Dim contract:** `BGE_M3_DIM` here MUST `===` `@cc/memory-engine`'s `BGE_M3_DIM` (vector.ts already re-exports it as `EMBEDDING_DIM` with a compile-time `__dim: 1024` witness). Keep one source of truth; import rather than redeclare if a shared package is used.

### 6.6 Test plan
1. **Dim assertion:** `embed(["hello"])` → `result[0].length === 1024`; `result[0] instanceof Float32Array`. Assert against `BGE_M3_DIM` and against memory-engine's constant (cross-package equality test).
2. **Order preservation:** `embed(["a","b","c"])` returns 3 vectors, and `embedOne("b")` ≈ `embed([...])[1]` (cosine ≥ 0.999).
3. **Determinism:** same text twice → identical (or cosine ≥ 0.9999) vectors within one backend. Mark backend-specific; skip if backend unavailable.
4. **Cosine sanity:** semantically related pair (e.g. "battery electrolyte" vs "solid-state electrolyte") has higher cosine than an unrelated pair ("battery electrolyte" vs "interest rate swap"). Threshold loose (related > unrelated), not absolute.
5. **Normalization:** with `normalize:true`, L2 norm ≈ 1.0 (±1e-3); dot product == cosine.
6. **Backend fallback:** mock transformers-init failure → asserts ollama path is attempted; mock both down → throws (does NOT return `[]`).
7. **Soft-skip in CI:** if neither backend is present in CI, tests `it.skipIf(backend==="none")` so the package still passes verify without a GPU/Ollama in CI (mirrors integration-tests' "soft-skip if vault absent" pattern). The real determinism/cosine tests run locally on the GPU node.

### 6.7 Deps to add (in the package that owns the embedder)
`@huggingface/transformers` (peer-ish, heavy — keep it in *one* package). Ollama needs no dep (plain fetch). Add the package to root `build`/`typecheck` lists (the §5.3 wiring) when it lands.

---

## 7. Operator decisions needed

1. **Adopt #74 as the single rag-engine PR?** (Recommended.) If yes → close #7,#9,#13,#39,#66,#70,#56,#60. If you prefer small reviewable hops, keep the #7→#39→#66→#70 ladder and close only #74 + the C2 eval PRs — but that re-reviews the same code.
2. **Confirm #11 (brain route) and #3 (sync 003) are already on main.** If yes, close them (no-op). I see the route on main [gh]; please eyeball the migration file.
3. **Who owns the bge-m3 embedder, and where does it live?** Recommend a standalone `packages/embedding` (or `rag-engine/src/embedding/`) with no memory-engine import, to avoid an import cycle. Decide before §6 is built.
4. **Root build-script edit:** approve adding the 6 new packages to root `package.json` `build`/`typecheck`. Without it, CI green is misleading (§5.3). Fold into #58 or a tiny follow-up.
5. **Coverage gate: report vs enforce.** Merge #5/#68 as "report" first; flip to "enforce" only after all packages land (per CLAUDE.md: health-checks report, operator decides).
6. **G4 nightly-distill cron (#8) stays OFF** until you explicitly gate it on (no auto-cron per baseline).
7. **Dedupe re-push hygiene:** #61/#52/#62/#59/#50 are exact-duplicate re-pushes of earlier PRs. Confirm you want the *newer* of each pair kept (my default) so PR numbers in changelogs match the latest review.
8. **Docs backlog:** ~22 pure-doc/verify PRs. Approve a batch-merge of the current ones + close of stale CI-snapshots (#42,#65, etc.)? They're noise on the train.

---

*Caveats: branch contents read from `origin/*` refs as of 2026-06-02. "Already merged" claims for #11/#3 inferred from files present on `origin/main` — confirm before closing. CI states are point-in-time from `gh pr checks`; re-run before each merge.*
