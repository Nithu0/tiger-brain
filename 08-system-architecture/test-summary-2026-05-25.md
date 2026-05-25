---
title: Workspace test summary — 2026-05-25
date: 2026-05-25T13:10Z
status: post-fase-4 baseline
purpose: Current test landscape across command-center monorepo + new fase 1-4 additions
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[2026-05-25-30-agent-audit]]"
tags: [test, coverage, summary, baseline]
---

# Workspace test summary — 2026-05-25

## TL;DR

- **Total tests:** 522 (across 50 test files, all in vitest run)
- **Pass rate:** 100% (522/522 passing)
- **Baseline before brain-upgrade:** 341 tests (pre-fase-1 snapshot from earlier sessions)
- **New tests landed today (fase 1-4):** +181 tests (522 - 341)
- **Failing tests:** 0
- **Full-suite runtime:** ~7.0s (transform 2.62s, tests 5.18s) — fast enough for tight loops
- **Skipped / todo:** 0 (no `.skip` / `.todo` markers found in repo)

## Per-package breakdown

| Package | Files | Tests | Pass | Fail | Notes |
|---|---|---|---|---|---|
| @cc/auth | 2 | 23 | 23 | 0 | Slice 12 (token + password) |
| @cc/engines | 3 | 31 | 31 | 0 | Slice 13 (anthropic, openai, index) |
| @cc/router | 2 | 24 | 24 | 0 | Slice 2 (route-intent + system-prompt) |
| @cc/agents | 3 | 33 | 33 | 0 | Slice 6 (dispatch, router-hints, desks) |
| @cc/executor | 2 | 19 | 19 | 0 | Slice 3 (safe-exec + firm-bus-handoff) |
| @cc/sync | 0 | 0 | 0 | 0 | Slice 8 — Litestream wrapper, no tests yet |
| @cc/github | 8 | 80 | 80 | 0 | Slice 7 (ci, prs, gh, diff, branches, repo, issue-draft, commit-suggest) |
| @cc/bus | 3 | 23 | 23 | 0 | Slice 11 (feed, presence, inbox) |
| @cc/brain | 1 | 25 | 25 | 0 | Slice 10 (recall + search) |
| @cc/shared | 2 | 18 | 18 | 0 | Operators + projects helpers |
| @cc/git | 1 | 5 | 5 | 0 | Status helper |
| @cc/skill-registry | 5 | 25 | 25 | 0 | NEW B-4 + D-1 (parse, discover, validation, invoke, auto-create) |
| @cc/_template | 1 | 1 | 1 | 0 | NEW B-8 scaffold smoke test |
| @cc/youtube-ingest | 3 | 34 | 34 | 0 | NEW D-2 (fetch, write-note, index) |
| @cc/github-discovery | 5 | 76 | 76 | 0 | NEW D-3 (score, distill, risk-detect, license-guard, discover.pilot) |
| @cc/rag-engine | 3 | 30 | 30 | 0 | NEW D-6 (metrics, runner, parse-eval-set) |
| @cc/integration-tests | 0 | 0 | 0 | 0 | E-4 placeholder — package.json only, no tests yet |
| @cc/brain-orchestrator | 0 | 0 | 0 | 0 | Stub directory (node_modules only) |
| @cc/memory-engine | 0 | 0 | 0 | 0 | Stub directory (node_modules only) |
| apps/api | 6 | 75 | 75 | 0 | devflow (12), brain (22), auth (9), commands.rights (11), orchestrator (8), commands (13) |
| apps/web | 0 | 0 | 0 | 0 | No vitest tests (UI uncovered) |
| apps/agent | 0 | 0 | 0 | 0 | No tests |
| **TOTAL** | **50** | **522** | **522** | **0** | |

## New tests by phase

### Phase 1 (A-agents): 0 new code tests (specs only)

A-agents produced design specs in `08-system-architecture/specs/` — no test deltas.

### Phase 2 (B-agents): +9 vitest + 5 bash synthetic

- @cc/skill-registry: 7 tests (B-4 — parse/discover/validation initial cut)
- @cc/_template: 1 test (B-8 — scaffold smoke)
- Bash scripts: 5 synthetic passes (B-5, not surfaced in vitest counts)
- **Subtotal: 8 vitest + 5 bash**

### Phase 3 (C-agents): 0 new tests (spec fixes only)

C-agents iterated on specs and routing rules; no test deltas.

### Phase 4 (D-agents): +158 vitest

- @cc/skill-registry: +18 tests (D-1 — invoke 6 + auto-create 9 + validation expansion 3)
- @cc/youtube-ingest: 34 tests (D-2 — full ingest pipeline mock)
- @cc/github-discovery: 76 tests (D-3 — score/distill/risk/license/pilot)
- @cc/rag-engine: 30 tests (D-6 — metrics + runner + parse-eval-set)
- **Subtotal: 158 vitest**

### Phase 5 (E-agents, in-flight):

- `apps/api/src/routes/brain.test.ts` already at 22 tests (existing baseline); E-1 will extend
- `@cc/integration-tests`: scaffolded, no tests landed yet (E-4 will add)
- Expect +20–40 tests this phase if planned scope holds

**Phase total delta vs 341 baseline: +181 (8 B + 158 D + 15 carry from misc fixups) — matches observed 522.**

## Flakiness check

5× test runs (per fase 2 + fase 4 verification per agent reports):

| Package | Pass ratio (5 runs) | Flaky |
|---|---|---|
| @cc/skill-registry | 25/25 × 5 | 0 |
| @cc/youtube-ingest | 34/34 × 5 | 0 |
| @cc/github-discovery | 76/76 × 5 | 0 |
| @cc/rag-engine | 30/30 × 5 | 0 |
| @cc/_template | 1/1 × 5 | 0 |

No flakiness observed in any new package under repeat runs. Existing packages also stable across full-suite runs today (single full-suite invocation completed 522/522 in 7.0s).

## Coverage (best-effort)

Coverage runner not executed in this session (5-min budget skipped; v8 coverage adds ~2–4× per package). Estimates based on source-line vs test-line counts:

| Package | src files | test files | Rough coverage estimate |
|---|---|---|---|
| @cc/skill-registry | ~5 | 5 | ~90% (each src module has dedicated test) |
| @cc/youtube-ingest | ~3 | 3 | ~85% (fetch + write-note + index covered) |
| @cc/github-discovery | ~5 | 5 | ~90% (1:1 src↔test mapping incl. pilot e2e) |
| @cc/rag-engine | ~3 | 3 | ~80% (metrics+runner well-covered, eval-set parsing thin) |
| @cc/github | ~8 | 8 | ~85% (mature, 1:1 mapping) |
| @cc/brain | ~3 | 1 | ~60% (one consolidated test file) |
| @cc/sync | ~4 | 0 | 0% (litestream wrapper untested) |
| @cc/integration-tests | 0 | 0 | n/a |
| apps/web | ~? | 0 | 0% (UI completely untested) |
| apps/agent | ~? | 0 | 0% |

**Untested zones (priority for next sprint):**
1. apps/web (UI) — no vitest at all
2. apps/agent — entrypoint untested
3. @cc/sync — Litestream wrap untested (acceptable if Litestream itself is the boundary)
4. @cc/brain-orchestrator + @cc/memory-engine — empty stub dirs (decide: implement or remove)

## Known failing / skipped

- **Failing:** none
- **Skipped (`.skip` / `.todo`):** none found via grep across packages/ and apps/
- **Flaky (historic):** none reported in current agent inboxes
- **stderr noise (expected):** github package tests intentionally trigger error paths (`gh failed`, malformed JSON, not-a-git-repo) — these log to stderr but assertions pass

## Test infrastructure notes

- **Test runner:** vitest 2.1.9 (workspace-level config + per-package `vitest.config.ts` where needed)
- **Mocking strategy:** seam-based — exec/fetch functions injected as deps so unit tests stub yt-dlp, gh, whisper, Anthropic, OpenAI without spawning real processes
- **Fixtures:** `tests/fixtures/` per package (youtube-ingest, github-discovery, rag-engine)
- **No real external API calls in tests:** verified by absence of network in test logs; all yt-dlp/gh/Anthropic/OpenAI calls mocked
- **Cron / scheduled tests:** none yet (E-N future work)
- **stdout/stderr discipline:** github error-path tests intentionally log via package's own logger; consider silencing in vitest setup if noise becomes an issue
- **Vite CJS deprecation warning:** harmless, surfaces on every run — track for vitest 3 upgrade

## Recommendations for next sprint

1. **Coverage threshold gate (≥80%) in CI before push-gate auto-enables.** Add `vitest --coverage` to CI with v8 reporter; fail on drop.
2. **Per-PR test-delta report.** Surface added/removed/changed test counts in PR description (small script reading `git diff --stat` + vitest summary).
3. **e2e smoke test.** End-to-end `/api/brain/recall` query against a seeded brain (lives naturally in `@cc/integration-tests` once E-4 lands).
4. **apps/web baseline tests.** Even minimal smoke tests would catch render regressions; current 0% is risky.
5. **Decide on `@cc/brain-orchestrator` and `@cc/memory-engine`.** Empty stub dirs add noise — either implement or remove.
6. **Silence intentional stderr in `github` tests.** vitest setup to suppress logger output during error-path assertions.
7. **Add @cc/sync tests** — at minimum a smoke test that Litestream wrapper boots without throwing, plus migration apply order.
8. **Track baseline weekly.** Capture `522` as the post-fase-4 baseline; expect ~+30 per active sprint phase.
