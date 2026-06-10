# Brain-Upgrade Merge Train — Executable Plan

_Author: BRAIN-MERGETRAIN (agent #19 of 10-agent parallel run). Generated 2026-06-03 from `origin/*` refs in `/home/nithu/code/command-center`. **Analysis only — no merges performed.**_

## 0. Status snapshot

- **65 open PRs.** Only `@cc/skill-registry` is described as "merged" in workspace memory, but **no brain-upgrade package PR has actually landed on `main`** — every package PR below is still `origin/main`-based and open.
- Two prior planning docs read and superseded by this one:
  - PR #20 `docs/PR_MERGE_ORDER.md` — only covers the **original C1 wave #1–#15**. Predates the C2 lane (#48–72) and the "real impl" PRs (#39/#47/#56/#60/#66/#70/#74). Its conflict matrix is still valid for #1–#15.
  - PR #71 `docs/_MASTER_BRIEF_2026-05-25.md` — 7-wave plan, 3 operator decisions. Good high-level frame; this doc makes the **dedup decisions concrete** and corrects the rag-engine call.
  - PR #49 dep-analysis (`code-2/pr49-dep-analysis`) — root-causes the #49 CI red (missing workspace dirs). Fix folded into Wave 6 below.

**The central problem is not ordering — it is deduplication.** code-2 built parallel copies of packages that code-1 also built, AND code-2 duplicated several of its own packages across two branches each. Resolve dedup first (§2), then the order (§3) is straightforward.

---

## 1. PRs grouped by target package / area

### Foundation (shared types → storage)
- **#1** `brain-orchestrator-skel` — C1-1, `packages/brain-orchestrator` skeleton. No deps.
- **#2** `memory-engine-skel` — C1-2, `packages/memory-engine` schema + distill skel. Stacked on #1.
- **#12** `memory-engine-storage` — C1-3, FTS5 + sqlite-vec storage (2989 lines). Stacked on #2.
- **#47** `memory-engine-distill-real` — C1-2 real distill → Claude Haiku, env-gated (default stub).

### Migrations / sync
- **#3** `distill-migration` — C1-9, adds `003_agent_tasks_*` migration.
- **#24** `distill-backfill` — c1-8 backfill, **based on `code-1/distill-migration`** (stacked on #3).

### rag-engine — **CONTESTED (C1 vs C2)**
- C1 chain (canonical): **#7** hybrid skel → **#9** rerank skel → **#13** agentic skel → **#39** wire-to-memory → **#66** real bge-reranker → **#70** real T3 LLMs → **#74** full T2+T3 chain integration test.
- C2 duplicate: **#56** `rag-engine-eval-runner` (re-implements the same files, lighter) + **#60** `rag-engine-eval-runner-v2` (eval-runner CLI + metrics subset).

### api
- **#14** `api-14b-endpoints` — Phase 14b: `GET /api/commands` filters + `POST /api/agents/report`. Adds `003_target_machine` migration → **collides with #3** on migration id 003.
- **#11** `brain-api-routes` — C1-7, 5 brain endpoints (`apps/api/src/routes/brain.ts`, 415 lines). **Uncontested** (see §2.5).
- **#69** `api-slice-3-4-tests` — C2 api unit tests, additive.

### apps/agent (Phase 14b) — **DUPLICATE (C1 vs C2)**
- **#4** `phase-14b-agent-scaffold` (C1) + **#18** `agent-tests-ci` (C1 tests, stacked on #4).
- **#63** `agent-poller` (C2) — byte-identical apps/agent to #4.
- **#27** `agent-bootstrap-script`, **#43** `discord-agent-failures`, **#46** `agent-heartbeat-discord`, **#32** `machine-id-registry` — C1 agent add-ons.
- **#64** `firm-task-scripts` (C2), **#48** `bin-brain-scripts` (C2), **#72** `firm-tab-init-presence-prompt` (C2, stacked on #48).

### skill-registry — **C2 self-duplicate**
- **#51** `skill-registry-impl` vs **#61** `skill-registry-full` — identical package source.

### youtube-ingest — **C2 self-duplicate**
- **#52** `youtube-ingest-impl` vs **#62** `youtube-ingest` — identical package source.

### github-discovery — **C2 self-duplicate**
- **#53** `github-discovery-impl` vs **#59** `github-discovery` — identical package source.

### integration / template / lockfile (C2 plumbing)
- **#57** `template-package` / **#50** `packages-template-plus-plan` (dup), **#58** `workspace-lockfile-sync`, **#49** `integration-tests` (CI red — needs the 4 packages first), **#25** brain integration tests (C1).

### web (Phase 14c UI)
- **#41** `web-nav-brain-section` (C1 TopNav) → **#55** `web-brain-impl` (C2 full UI, supersedes already-closed #36/#40/#44/#45) → **#67** smoke verify.
- Scaffold-only branches `web-brain-{layout-shell,recall-panel,skills-panel,tasks-panel}` exist locally but have no open PRs — ignore.

### Docs / runbooks / verify (no runtime impact — batch-merge anytime)
#10, #15, #17, #19, #20, #21, #22, #23, #26, #28, #30, #31, #32, #35, #37, #38, #42, #54, #65, #68, #71, #73, #67. Plus bugfix **#6** (health hosted-mode), **#5** (coverage runner), **#33/#34** (typecheck/CI hygiene), **#16** (14c two-svc — operator-gated).

---

## 2. Dedup decisions (DO THIS BEFORE MERGING)

### 2.1 rag-engine — KEEP C1, CLOSE C2 #56 + #60
- **Keep:** C1 chain #7 → #9 → #13 → #39 → #66 → #70 → #74.
- **Close without merge:** **#56** and **#60**.
- **Why:** C1's chain is a strict **superset**. `git diff origin/code-1/rag-engine-chain-integration..origin/code-2/rag-engine-eval-runner -- src/` shows C1 has **+1220 lines / 8 files** that C2 lacks — full `agentic/generator.ts`, `agentic/real-llm.test.ts` (360 lines), and the complete `rerank/bge-reranker.ts` + `evaluator.ts` + `planner.ts` impls. C2 #56 carries the **stub-grade** versions of those same files. C1 is the one wired to the `bge-m3 / sqlite-vec` design (`vector.ts` imports `BGE_M3_DIM`, `queryDistilledVector` from `@cc/memory-engine`; dimension locked at 1024). C1 also has 81/81 agentic tests (#70), 23/23 rerank tests (#66), 15/15 hybrid tests (#39).
- **Cherry-pick before closing:** C2 #56/#60 contain an **eval-runner CLI** (`src/cli.ts`, `src/runner.ts`, `src/metrics.ts`, `src/parse-eval-set.ts`, `tests/{metrics,runner,parse-eval-set}.test.ts`) that C1's chain branch does NOT have. This is genuinely unique, useful (offline eval harness for tuning retrieval). **Action:** before closing #56/#60, cherry-pick just those eval-runner files onto a small follow-up branch `code-1/rag-eval-runner-port` and open it as a post-chain PR. Everything else in #56/#60 is a redundant re-impl — discard.

### 2.2 skill-registry — KEEP #61, CLOSE #51
- Package source is **byte-identical** between the two. #61 `skill-registry-full` = #51 + a lockfile-sync commit. Keep **#61** (has the lockfile fixup), close **#51**. No code lost.
- Note: workspace memory claims skill-registry is "already merged." Verify against `main` first (`git ls-tree origin/main packages/skill-registry`). If it's already on main, close **both** #51 and #61.

### 2.3 youtube-ingest — KEEP #62, CLOSE #52
- Byte-identical source. #62 `youtube-ingest` = #52 + lockfile-sync commit. Keep **#62**, close **#52**. No code lost.

### 2.4 github-discovery — KEEP #59, CLOSE #53
- Byte-identical source. #59 `github-discovery` = #53 + lockfile-sync commit. Keep **#59**, close **#53**. No code lost.

### 2.5 apps/agent — KEEP C1 (#4 + #18), CLOSE C2 #63
- `apps/agent/` is **byte-identical** between #4 and #63 (684 added lines each, empty diff in `apps/agent/`). C1 path is more complete because **#18** stacks real unit tests (`poller.test.ts`, `executor.test.ts`, vitest config + CI job) on top of #4; C2 #63 ships no tests.
- **Keep:** #4 → #18. **Close:** #63. No unique code lost.
- C2's firm-bus scripts (#48, #64, #72) are **separate scope** (`_bin/` shell scripts, not apps/agent) — keep those; they don't conflict with C1 agent.

### 2.6 api brain routes (C1-7) — KEEP #11, no contest
- Workspace memory flagged a possible C1-7 ownership fight with a code-2 `brain-decisions` superset. **That package does not exist** — `git ls-tree -r` across all `code-2/*` branches finds no `brain-decisions` and no `apps/api/src/routes/brain.ts`. The contest never materialized into code. **#11 stands as canon.** Master-brief's "Hold #11" gate (decision #2) can be **resolved: ship #11.**

### 2.7 template package — KEEP #57, CLOSE #50
- #57 `template-package` and #50 `packages-template-plus-plan` both add `packages/_template`. #50 also carries a session COMMIT_PLAN doc (non-code). Keep **#57** (clean boilerplate), salvage the COMMIT_PLAN from #50 into the inbox if wanted, close #50.

**Dedup tally: close 7 PRs (#56, #60, #51, #52, #53, #63, #50). One cherry-pick required (rag eval-runner from #56/#60).**

---

## 3. Numbered merge order (respects shared-types → storage → engine → orchestrator → api → watchers)

Squash-merge everything. `[∥]` = can merge in parallel within the step. Rebase each branch on `main` immediately before its merge; regenerate `package-lock.json` after any step that adds a package.

**STEP 0 — dedup housekeeping (no merges).** Close #56, #60, #51, #52, #53, #63, #50 per §2. Cherry-pick rag eval-runner → `code-1/rag-eval-runner-port` (held for step 7b).

**STEP 1 — zero-risk, parallel.** `[∥]` #6 (health bugfix), #5 (coverage runner), #33, #34 (typecheck/CI hygiene), and ALL docs PRs (#10, #15, #17, #20, #21, #22, #23, #26, #28, #30, #31, #32, #35, #37, #38, #42, #54, #65, #68, #71). Resolve only #10↔#15 ROADMAP rebase. No code-path risk.

**STEP 2 — foundation skeletons (serialize).** #1 (orchestrator) → #2 (memory-engine skel, rebase on main after #1).

**STEP 3 — storage + template (parallel after step 2).** `[∥]` #12 (memory-engine FTS5 + sqlite-vec storage, rebase on #2) ∥ #57 (`_template` boilerplate) ∥ #58 (workspace lockfile/coverage scripts).

**STEP 4 — ⚠ EMBEDDING CLIENT (BRAIN-EMBED's PR) slots HERE.** See §5. Merge immediately after #12 and before the rag-engine chain.

**STEP 5 — migrations (serialize, resolve id collision).** #3 (`003_agent_tasks`) FIRST. Then #14 must **renumber its migration to `004_target_machine`** before merge (both currently claim id 003). Then #24 (distill-backfill, rebase on landed #3). Order: #3 → #14(renumbered) → #24.

**STEP 6 — C2 ingestion packages (parallel, independent trees).** `[∥]` #61 (skill-registry) ∥ #62 (youtube-ingest) ∥ #59 (github-discovery). Each is a self-contained `packages/<x>` dir. After all three land, **#49** (integration-tests) goes green on rebase — merge #49 fourth. Then #69 (api slice tests), #48/#64/#72 (firm `_bin` scripts).

**STEP 7a — rag-engine chain (strict serialize — shared files).** #7 → #9 → #13 → #39 → #66 → #70 → #74. Each rebases on the prior. These all touch the same `packages/rag-engine/src/{index,types,package.json}` so they CANNOT parallelize.
**STEP 7b —** merge `code-1/rag-eval-runner-port` (the cherry-picked C2 eval-runner) on top of the landed chain.
**STEP 7c —** #47 (memory-engine real distill) — independent of rag chain, can go any time after #12; park here to keep waves clean.

**STEP 8 — api brain routes (after #14).** #11 (rebase on #14 to resolve `apps/api/src/index.ts` route registration). #25 (brain integration tests) after #11.

**STEP 9 — agent + watchers (serialize core, parallel add-ons).** #4 → #18. Then `[∥]` #27 (bootstrap), #43 + #46 (Discord alerts), #32 (machine-id registry).

**STEP 10 — orchestrator triggers.** (the G4 nightly-distill trigger PR if/when reopened — currently the `orchestrator-triggers` branch #8 from the old wave; rebase on landed orchestrator+memory+migrations). Operator-gated (G4 cron). Merge last, behind env flag.

**STEP 11 — web UI.** #41 (TopNav) → #55 (full brain UI) → #67 (smoke verify). Independent of api internals; can run in parallel with steps 7–10 if reviewer bandwidth allows.

**STEP 12 — 14c arch (operator-gated).** #16 (two Railway services) — needs explicit "OK kjør". Lands after #4 (see #20 note: alt-arch reverts the diag Dockerfile).

---

## 4. Conflict check — top 5 foundational PRs vs current `main`

All five are clean-additive vs `main` (verified `git diff --stat main...origin/<branch>`); the conflicts are between PRs, not against main:

| PR | vs main | Inter-PR conflict |
|---|---|---|
| #1 orchestrator-skel | clean add (628 lines, new `packages/brain-orchestrator/`) | shadowed by #2/#12 (same SHA stack) — none if ordered |
| #2 memory-engine-skel | clean add (1302 lines, new pkg) | stacked on #1 — rebase after #1 |
| #12 memory-engine-storage | clean add (2989 lines) | stacked on #2 — rebase after #2 |
| #3 distill-migration | clean add (`003_agent_tasks_{pg,sqlite}.sql`) | **⚠ HARD: #14 also adds id 003** (`003_target_machine.sql` + 10 lines in `migrations.ts`). Renumber #14 → 004. |
| #14 api-14b-endpoints | touches `migrations.ts` (+10) + `apps/api/src/index.ts` | conflicts #3 (migration id) AND #11 (`index.ts` route registration). Land #3 first, #11 last. |

**Single sharpest conflict in the whole train:** the migration-id-003 collision (#3 vs #14). Renumber #14 to 004 before its merge — non-negotiable or the migration runner double-applies id 003.

Secondary hotspot: `packages/rag-engine/src/{index,types}.ts` + `package.json` across the entire #7→#74 chain — mitigated only by strict serial rebasing (step 7a).

---

## 5. bge-m3 embedding gap — where BRAIN-EMBED slots in

**Confirmed gap:** there is **no embedding client anywhere** in the tree. `git ls-tree -r origin/code-1/memory-engine-storage | grep -i 'embed\|ollama'` returns nothing. The memory-engine exports the **types and the dimension constant** (`BGE_M3_DIM`, `EmbeddingDim`, `EmbeddingModel`, `MemoryObjectEmbedding`, `assertValidEmbedding`) but no code that actually calls a model to produce a vector.

**The seam is already cut for it.** `packages/rag-engine/src/vector.ts` documents the contract explicitly: it accepts a **pre-embedded `Float32Array` (`q.query_vec`)** and returns `[]` when the vector is missing, with the comment _"The real `bge-m3` query embedding lands in C1-5; until then callers supply the vector directly."_ Dimension is hard-locked at **1024** via a compile-time witness type `EmbeddingVector = Float32Array & { __dim: 1024 }`. Storage side (#12) reads/writes via `queryDistilledVector` against sqlite-vec.

**BRAIN-EMBED's Ollama client must:**
- Export an `embed(text): Promise<Float32Array>` (dim **1024**, bge-m3) that satisfies `assertValidEmbedding`/`BGE_M3_DIM` from `@cc/memory-engine`. Use **sqlite-vec** (not sqlite-vss) on the storage side.
- Live either inside `@cc/memory-engine` (preferred — that's where the embedding types live and where distill writes vectors) or as a thin `@cc/embed` package that memory-engine depends on.

**Merge slot: STEP 4** — after #12 (storage, which defines the vector surface it must match) and **before STEP 7a** (the rag-engine chain, whose `vector.ts` and the real-LLM agentic loop become live-capable only once a real embedder exists). Merging it earlier than #12 means it has no storage surface to target; later than #7a means the chain ships embedder-less and every vector recall silently returns `[]`. **Coordinate with BRAIN-EMBED that their PR bases on (or rebases onto) landed #12, exports the 1024-dim bge-m3 contract, and does NOT re-declare `BGE_M3_DIM`** (import it from memory-engine to keep the single source of truth).

---

## 6. One-screen execution checklist

1. Close #56, #60, #51, #52, #53, #63, #50. Cherry-pick rag eval-runner → `code-1/rag-eval-runner-port`.
2. Verify whether `@cc/skill-registry` is truly on `main`; if so also close #61.
3. Batch-merge docs + #6/#5/#33/#34 (STEP 1).
4. #1 → #2 → (#12 ∥ #57 ∥ #58).
5. **Merge BRAIN-EMBED's bge-m3 Ollama client** (STEP 4).
6. #3 → renumber #14 to migration 004 → #14 → #24.
7. (#61 ∥ #62 ∥ #59) → #49 → #69 → #48/#64/#72.
8. #7→#9→#13→#39→#66→#70→#74 (strict serial) → rag-eval-runner-port → #47.
9. #11 (rebase on #14) → #25.
10. #4 → #18 → (#27 ∥ #43/#46 ∥ #32).
11. #8 orchestrator triggers (operator-gated G4).
12. #41 → #55 → #67 (web, parallelizable).
13. #16 two-svc (operator "OK kjør" gate).

**Operator gates remaining:** #16 (Railway arch), #8 (G4 nightly cron), any tiger-brain push. Per CLAUDE.md, "OK kjør" required before each push to a protected ref.
