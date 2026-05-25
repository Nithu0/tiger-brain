---
title: Coverage gap analysis — 2026-05-25
date: 2026-05-25
status: v1.0
purpose: Identify top 10 uncovered files to address in next sprint to push coverage above 60%
baseline: lines/statements 43.31% (G-9 snapshot) / 43.12% (re-run), branches 77.05% / 76.88%, functions 71.13% / 70.89%, 530 tests passing
related:
  - "[[test-summary-2026-05-25]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [coverage, testing, gap-analysis]
---

# Coverage gap analysis — 2026-05-25

## Current baseline (post G-9)

G-9 reported snapshot (filed in the 2026-05-25 brain upgrade plan):

- Lines: **43.31%** (4315/9961)
- Statements: **43.31%** (same)
- Branches: **77.05%** (1189/1543)
- Functions: **71.13%** (207/291)
- Total tests: 527 / 530 passing

Re-run today (this report, vitest 2.1.9 / v8 coverage):

- Lines: **43.12%** — small downward drift (likely from added uncovered source lines, not new tests)
- Branches: **76.88%**
- Functions: **70.89%**
- Tests: **530 passed + 1 todo** across 54 test files (+1 skipped file)
- Duration: 11.63s

The gap between G-9's 43.31% and today's 43.12% is roughly **20 source-lines added without corresponding tests** — confirms drift is real but small. Treat **43.12%** as the binding number for sprint planning; G-9's 43.31% remains the canonical pre-sprint baseline.

## Why lines/statements low while branches/functions high?

**Hypothesis confirmed by table inspection:** tested packages have very high coverage (95–100%) on the lines that ARE hit — but large swaths of source files have **0% coverage** because they have no test file at all. v8 counts those zero-coverage files into the line/statement denominator, dragging the total down.

Concrete evidence:

- 14 source files at **literally 0% lines** in apps/api (routes/agents.ts, audit.ts, executor.ts, git.ts, github.ts, health.ts, projects.ts, router.ts, terminals.ts; src/index.ts, db-pg.ts, executor-worker.ts, push-store.ts (4.08%), ws.ts (11.28%))
- 3 source files at 0% in apps/agent (executor.ts, index.ts, poller.ts) — entire app uncovered
- ~25 source files at 0% in apps/web (every page.tsx + every component .tsx + every hook .ts)
- 4 files at 0% in packages/sync (litestream.ts, migrations.ts, apply-migrations.ts, index.ts)
- packages/rag-engine/src/cli.ts at 0%

Meanwhile branches/functions stay high because **only executed code contributes to branch/function denominators** under v8's accounting — uncovered files don't get parsed for branches.

## Top 10 uncovered files (priority order)

Ranking criteria: **(uncovered lines) × (business-criticality)** — favors apps/api routes (small files, high leverage per test) over apps/web pages (large files, need vitest+jsdom infra first).

| Rank | File | Lines | Coverage | Why uncovered | Recommended test type |
|---|---|---|---|---|---|
| 1 | `apps/api/src/executor-worker.ts` | 369 | 0% | Worker process; no harness for spawn-based code | Unit test with seam-injected exec; integration smoke under `@cc/integration-tests` |
| 2 | `apps/api/src/ws.ts` | 280 | 11.28% | WebSocket server; only constructor path hit | Fastify-test client + ws-client unit tests for subscribe/publish |
| 3 | `packages/sync/src/litestream.ts` | 169 | 0% | Litestream wrapper — operator boundary; thin shim but uncovered | Smoke test that wrapper boots + parses config; mock litestream binary |
| 4 | `apps/api/src/index.ts` | 139 | 0% | App entrypoint; mostly route mounting + bootstrap | Smoke test importing the buildApp factory and calling `.ready()` |
| 5 | `apps/api/src/db-pg.ts` | 146 | 0% | Postgres adapter (alt to db.ts); only db.ts covered | Mirror db.ts tests under PG mock or mark legacy/deprecated |
| 6 | `apps/api/src/push-store.ts` | 118 | 4.08% | Push-subscription store; constructor-only hit | CRUD unit tests against in-memory + persisted store |
| 7 | `apps/api/src/routes/router.ts` | 91 | 0% | `/api/router/*` endpoints (route-intent surface) | Route smoke tests — POST /classify, GET /agents |
| 8 | `apps/api/src/routes/audit.ts` | 81 | 0% | `/api/audit/*` endpoints (audit-log listing) | Route smoke tests — seed audit row, GET /audit, GET /audit/:id |
| 9 | `apps/api/src/routes/github.ts` | 55 | 0% | `/api/github/*` endpoints; delegates to @cc/github | Route smoke with stubbed @cc/github (gh exec) |
| 10 | `apps/api/src/routes/agents.ts` | 54 | 0% | `/api/agents/*` endpoints (desk listing, dispatch) | Route smoke — GET /agents, POST /agents/dispatch with stubbed dispatcher |

Honorable mentions (just below cutoff, similar shape):

- `apps/api/src/routes/terminals.ts` (40 lines, 0%) — terminal-list endpoints, trivial test
- `apps/api/src/routes/executor.ts` (40 lines, 0%) — safe-exec proxy endpoints
- `apps/api/src/routes/health.ts` (37 lines, 0%) — health endpoints, near-trivial test
- `apps/api/src/routes/projects.ts` (12 lines, 0%) — minor surface
- `apps/api/src/routes/git.ts` (16 lines, 0%) — minor surface
- `packages/rag-engine/src/cli.ts` (146 lines, 0%) — CLI entrypoint, lower priority (binary, not in import paths)

## Categories

### A. Untested route handlers (apps/api/src/routes/)

All 0% unless listed otherwise. Each is a focused Fastify route module; route smoke tests are cheap (Fastify inject API, no real HTTP).

| File | Lines | Effort (hr) | Test pattern |
|---|---|---|---|
| agents.ts | 54 | 0.5 | Inject GET/POST, stub @cc/agents |
| audit.ts | 81 | 0.5 | Seed db row, inject GET; pagination test |
| executor.ts | 40 | 0.3 | Inject POST /exec, stub safe-exec |
| git.ts | 16 | 0.2 | Inject GET /status, stub @cc/git |
| github.ts | 55 | 0.5 | Inject GET /prs etc., stub @cc/github |
| health.ts | 37 | 0.2 | Inject GET /health (trivial) |
| projects.ts | 12 | 0.1 | Inject GET /projects (trivial) |
| router.ts | 91 | 0.5 | Inject POST /classify, stub @cc/router |
| terminals.ts | 40 | 0.3 | Inject GET /terminals (trivial) |
| push.ts (partial 34.10%) | 234 | 1.0 | Expand existing tests to subscribe/notify/unsubscribe |
| **subtotal** | **660** | **~4.1 hr** | Should push apps/api/src/routes from 60.4% to >90% |

### B. Untested utility / core (packages/* + apps/api/src/*)

| File | Lines | Effort (hr) | Test pattern |
|---|---|---|---|
| apps/api/src/executor-worker.ts | 369 | 2.0 | Seam-inject child_process; spawn-mocking unit test |
| apps/api/src/ws.ts | 280 | 1.5 | Fastify+ws-client harness; subscribe/broadcast/disconnect |
| apps/api/src/index.ts | 139 | 0.5 | buildApp factory smoke (ready/close) |
| apps/api/src/db-pg.ts | 146 | 1.0 | Postgres adapter OR mark deprecated and exclude |
| apps/api/src/push-store.ts | 118 | 0.5 | CRUD against in-memory store |
| packages/sync/src/litestream.ts | 169 | 1.0 | Wrapper smoke + config-parse test |
| packages/sync/src/apply-migrations.ts | 97 | 0.5 | Order test + idempotency test |
| packages/sync/src/migrations.ts | 43 | 0.2 | Already 100% branch, just hit lines 25-43 |
| packages/rag-engine/src/cli.ts | 146 | 0.5 | Argv-driven CLI test via tsx subprocess |
| **subtotal** | **1507** | **~7.7 hr** | Single biggest line-coverage lever |

### C. Index/types files (low value to test — accept as 0%)

Most are 1-3 lines and contain re-exports / type declarations only. Acceptable to exclude or leave at 0%.

Examples (each ≤3 lines, 0% coverage):

- packages/agents/src/index.ts (1-15 lines, mostly re-exports — could exclude)
- packages/auth/src/index.ts (1-2)
- packages/brain/src/index.ts (1)
- packages/bus/src/index.ts (1)
- packages/engines/src/types.ts (type-only)
- packages/executor/src/index.ts (1), types.ts (type-only)
- packages/git/src/index.ts (1)
- packages/github-discovery/src/types.ts (type-only)
- packages/github/src/index.ts (1), types.ts (type-only)
- packages/rag-engine/src/types.ts (type-only)
- packages/router/src/index.ts (1)
- packages/shared/src/index.ts (1-3), types.ts (type-only)
- packages/sync/src/index.ts (1-3)
- packages/youtube-ingest/src/types.ts (type-only — actually 100%)

**Recommendation:** add `coverage.exclude` patterns for `**/index.ts` re-export-only files and `**/types.ts` type-only files. That alone will lift global lines coverage by ~2-3pp without writing a single test.

### D. apps/web pages + components + hooks (need vitest+jsdom infra first)

Total ≈ 4,500+ uncovered lines, but **NONE testable until vitest+jsdom+@testing-library/react are set up** for apps/web. Biggest files (deserves attention once infra lands):

| File | Lines | Notes |
|---|---|---|
| apps/web/app/page.tsx | 589 | Main shell; needs render smoke + tab navigation |
| apps/web/components/TerminalConsole.tsx | 331 | Heavy interactive component |
| apps/web/components/OrchestratorPanel.tsx | 302 | Orchestrator UI |
| apps/web/app/brain/memory/page.tsx | 275 | Memory page |
| apps/web/app/brain/skills/page.tsx | 255 | Skills page |
| apps/web/components/ProjectActivity.tsx | 237 | Activity feed |
| apps/web/app/brain/rag/page.tsx | 223 | RAG page |
| apps/web/components/CommandQueue.tsx | 199 | Queue UI |
| apps/web/components/PushControls.tsx | 182 | Push UI |
| apps/web/app/brain/recall/page.tsx | 179 | Recall page |
| (~30 more) | ~2400 | Spread across components/hooks |

**Estimated infra setup:** 2-3 hr (vitest config + jsdom + @testing-library + first render smoke).
**Per-page smoke after that:** ~15 min/page → 5 pages = 1.25 hr for ~+8-10pp line coverage.

### E. apps/agent (no tests yet)

| File | Lines | Test pattern |
|---|---|---|
| apps/agent/src/index.ts | 118 | Entrypoint smoke; assert poller boots |
| apps/agent/src/executor.ts | 232 | Seam-inject exec; assert spawn lifecycle |
| apps/agent/src/poller.ts | 137 | Inject fetch; tick-loop unit test |
| **subtotal** | **487 lines** | ~2 hr total |

## Recommended sprint plan

### Quick wins (next sprint, ≤4 hours total)

| Task | Effort | Expected coverage delta |
|---|---|---|
| Add 9 route smoke tests in apps/api/src/routes/ (everything currently at 0%) | 3.5 hr | +5 to +7pp lines (660 lines now uncovered → ~85% coverage = +560 lines hit) |
| Exclude `**/index.ts` re-exports + `**/types.ts` from coverage report | 0.2 hr | +2 to +3pp lines (cuts denominator by ~250 lines) |
| Expand push.ts route tests from 34% to >80% | 1.0 hr | +1pp lines |
| **Quick-wins subtotal** | **4.7 hr** | **+8 to +11pp → ~52-54% lines** |

### Medium lift (sprint+1, ~8 hours)

| Task | Effort | Expected coverage delta |
|---|---|---|
| Test apps/api/src/executor-worker.ts (seam-injected) | 2.0 hr | +3pp lines (369 lines → ~80% hit) |
| Test apps/api/src/ws.ts (Fastify+ws harness) | 1.5 hr | +2pp lines |
| Test apps/api/src/index.ts (buildApp smoke) | 0.5 hr | +1pp lines |
| Test apps/api/src/push-store.ts | 0.5 hr | +1pp lines |
| Test packages/sync/litestream.ts + apply-migrations.ts | 1.5 hr | +2pp lines |
| Test apps/agent (3 files, seam-inject spawn) | 2.0 hr | +4pp lines |
| **Medium-lift subtotal** | **8.0 hr** | **+13pp → ~65-67% lines (over 60% target)** |

### Bigger lift (sprint+2, ~6 hours — only if 60% target met by above)

- Set up apps/web vitest+jsdom+@testing-library/react (2-3 hr)
- Add 5 page render-smoke tests (1.25 hr)
- Add property-based tests for github-discovery/score (1 hr) — moves branch coverage, not lines
- Property-based tests for license-guard / risk-detect (1 hr) — moves branch coverage

**Expected after all three tiers:** lines ~70-75%, branches ~85%, functions ~85%. Comfortably above the proposed 60% line gate.

## Suggested next-sprint tasks

(Each fits `command-center/10-tasks/_open/` task-file format.)

- **T-2026-05-26-A**: Add 9 route smoke tests in apps/api (agents, audit, executor, git, github, health, projects, router, terminals). Target: apps/api/src/routes from 60.4% → >90% lines; global lines +5-7pp. Effort 3.5 hr.
- **T-2026-05-26-B**: Tune `vitest.config.ts` coverage.exclude to drop `**/index.ts` re-export files + `**/types.ts` from denominator. Target: +2-3pp lines with zero test code. Effort 15 min. Verify no important runtime code is excluded.
- **T-2026-05-26-C**: Expand `apps/api/src/routes/push.test.ts` (currently small) to cover subscribe/notify/unsubscribe (push.ts 34% → >80%). Effort 1 hr.
- **T-2026-05-26-D**: Spawn-mock test for `apps/api/src/executor-worker.ts` (369 lines uncovered). Target: 0% → 80%. Effort 2 hr.
- **T-2026-05-26-E**: Fastify+ws-client harness test for `apps/api/src/ws.ts` (280 lines, 11%). Target: 11% → 80%. Effort 1.5 hr.
- **T-2026-05-26-F**: Smoke test `apps/api/src/index.ts` buildApp factory + `apps/api/src/push-store.ts` CRUD. Effort 1 hr combined.
- **T-2026-05-26-G**: Smoke tests for `packages/sync/litestream.ts` + `apply-migrations.ts` (operator boundary, but worth a wrapper-bootable check). Effort 1.5 hr.
- **T-2026-05-26-H**: Add 3 unit tests for apps/agent (index/executor/poller via seam-injected exec/fetch). Effort 2 hr.
- **T-2026-05-26-I** (stretch): vitest+jsdom+RTL setup for apps/web; 3 page render-smoke tests (page.tsx, brain/memory/page.tsx, brain/skills/page.tsx). Effort 4 hr.

## Excluded from threshold (won't move needle)

- `packages/_template/` — boilerplate scaffold, intentionally trivial
- `packages/integration-tests/` — cross-package suite, gated separately in CI
- `*.config.ts` / `*.config.mjs` / `next.config.mjs` / `postcss.config.mjs` — build configs
- `*.test.ts` — test files themselves
- `apps/web/public/sw.js` — service worker, hard to unit-test, integration-territory
- `apps/web/next-env.d.ts` — Next.js auto-generated type declarations
- All `**/types.ts` (type-only) and `**/index.ts` (re-export-only) — proposed exclusion in T-2026-05-26-B
- `@cc/brain-orchestrator`, `@cc/memory-engine` — empty stub directories; decide to implement or remove (existing recommendation in test-summary)

## Status

- Coverage in **WARNING mode** (not enforced; won't fail CI)
- Proposed enforce threshold: **60% lines** after T-2026-05-26-A through T-2026-05-26-H land
- Stretch target: **75% lines / 85% branches / 85% functions** after T-2026-05-26-I
- **Operator OK kjør required before enforce-flip** — flipping the threshold without operator sign-off is a binding-change

## Appendix: drift note

G-9 baseline (43.31%) was captured at a slightly earlier source-tree state. Re-run today shows 43.12% — ~20 line difference is consistent with the ~3-8 source files that were touched between G-9's snapshot and now. Both numbers describe the same coverage gap shape; the top-10 uncovered files are stable across both runs.
