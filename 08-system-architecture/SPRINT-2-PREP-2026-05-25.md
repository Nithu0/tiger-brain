---
title: Sprint 2 Prep — 2026-05-25
date: 2026-05-25
sprint: 2 (planning)
status: ready to start (operator-triggered)
purpose: What sprint 2 implements + dependencies + acceptance criteria
related:
  - "[[SPRINT-1-COMPLETE-2026-05-25]]"
  - "[[OPERATOR-NEXT-ACTIONS]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags:
  - sprint
  - planning
  - sprint-2
---

# Sprint 2 Prep — 2026-05-25

## Sprint 2 goal

Land the MEMORY + RAG implementation that sprint 1 scaffolded specs/stubs for. Code-1 is primary owner; code-2 supports. Net target: turn the 3 DEFERRED acceptance criteria from sprint 1 (rows 5/6/7) into READY by sprint 2 close.

## Pre-conditions (sprint 1 outputs)

- 7 specs at v1.0.2 STABLE (RAG, MEMORY, AGENT_ORCH, SKILL_REG, YOUTUBE, GITHUB, OBSIDIAN_STRUCTURE)
- Brain folders + MOCs + skills + runbooks landed (17 top-level folders, 21 MOCs, 9 skills, 21 runbooks)
- 6 new TS-packages scaffolded under `command-center/packages/`
- 597+ tests green workspace-wide; 47.63% lines coverage baseline (warning-mode)
- brain-G3 worktree-default OPT-IN flag available (`firm --worktree-default`); operator decides flip post 24-48h observation
- PRESENCE.md auto-populate active (L-2 pane-init append, lines 74-78)
- ~57 draft PRs on `origin/main` awaiting operator review/merge (incl. 10 code-2 PRs #48-#57)
- Audit GREEN: wikilinks 97.7% health, frontmatter Issues=0

## Sprint 2 deliverables

### Code-1 lane (primary)

- **C1-1 brain-orchestrator skeleton** — adaptive cycle, trigger registry, state-kv (PR draft exists, needs landing)
- **C1-2 memory-engine schema** — `MemoryObject` TS interface, FTS5 + sqlite-vec storage (PR #47 distill push gates this)
- **C1-3 memory-engine distillation** — Haiku-based distill, surviving-vocabulary pipeline
- **C1-4 rag-engine hybrid retrieval** — BM25 + HNSW + CombMNZ fusion (PRs #7/#9 pushed)
- **C1-5 rag-engine rerank** — bge-reranker-v2-m3 cross-encoder (PR #13 pushed)
- **C1-6 rag-engine agentic loop** — 3-iter cap, evaluator + planner (PR #39 pushed; #56 eval-runner stacks)
- **C1-8 nightly-distill trigger** — brain-orchestrator trigger wired
- **C1-10 test coverage** — 80%+ on all new packages

### Code-2 lane (support)

- **C1-7 brain.ts route wiring** — when MEM/RAG land, wire `/api/brain/memory` + `/api/brain/recall` endpoints (currently 503 stubs)
- **C1-9 sync migrations** — `audit_log` → `agent_tasks(role:distill)` migration path
- **Operator-decision-queue widget enhancement** — real-time updates on `/brain/routines` page
- **Coverage push** — continue per H-3 plan toward 60% line-gate

### Coverage push (parallel)

- Target: 60% lines (currently 47.63%); flip to enforce-mode when reached
- Top files per H-3:
  - ws.ts — J-4 done +24 tests (11% → ~80%)
  - executor-worker.ts — I-4 done +23 tests
  - audit.ts — K-6 done +13 tests
  - Next pass: health.ts / git.ts / agents.ts (~10 tests each, Fastify-inject smoke pattern)

## Sprint 2 acceptance criteria

| # | Criterion | Owner | Measure |
|---|---|---|---|
| 1 | Operator runs `/skill brain-recall query="..."` and gets top-5 hits with source-ref backlinks | code-1 | Manual smoke; hits ≥5, source_ref non-null |
| 2 | `/api/brain/memory` returns real MemoryObjects (not 503) | code-1 + code-2 | curl 200 + last-100 JSON |
| 3 | `/api/brain/recall` returns real RAG hits | code-1 | curl 200 + hits[] populated |
| 4 | brain-G4 nightly-distill cron activatable per checklist | code-1 | Runbook-Brain-Preflight-Checklist § G4 green |
| 5 | Coverage 60%+ lines (warning-mode enforces) | code-2 | `pnpm coverage` line% ≥ 60 |
| 6 | All 8 sprint-1 code-2 PRs merged to main (#48-#55, minus blocked) | operator | gh pr list --state merged |
| 7 | brain-G3 worktree-default flipped to default (post 24-48h opt-in observation) | operator | `firm` default = `--worktree-default`; `--legacy` rollback path |

## Dependencies + risks

### Hard dependencies

- **bge-m3 embedding model** (1024-dim, ~2.3 GB) — download + cache locally before C1-4 lands
- **bge-reranker-v2-m3** (~300 MB) — download + cache before C1-5 lands
- **sqlite-vec native binding** — `npm install sqlite-vec` + compile check on operator's WSL/Linux
- **Anthropic API key** present in `.env` for distillation Haiku calls (C1-3)
- **PR #50 lockfile fix** — `@cc/_template@0.0.0` resolution before any code-2 lane can build clean
- **PR #49 CI-RED** — `@cc/github-discovery` package missing/unpublished resolution before merge

### Risks

- Local embedding model slow/large on operator hardware → fallback to OpenAI embeddings flagged via `EMBED_PROVIDER=openai` env
- sqlite-vec compatibility on WSL2 kernel 6.6.87.2 — needs verify (no test reports yet)
- Coverage push touches code-1's package lanes — coordinate via `inbox/code-1.md` to avoid merge-conflict thrash
- Recall MRR ≥ 0.6 on eval-set is gating for brain-G4 activation; if eval misses, sprint slips
- Operator-merge cadence is the bottleneck — sprint 2 can't start C1-7 wire until C1-2/3 PRs land

## Sprint 2 timeline (estimate)

- **Day 1** — C1-1 brain-orchestrator skeleton + C1-2 memory-engine schema (code-1 parallel); code-2 starts ws.ts/health.ts coverage push
- **Day 2-3** — C1-3 distillation + C1-4 hybrid retrieval; embedding model cache + sqlite-vec verify
- **Day 4** — C1-5 rerank + C1-6 agentic loop + eval-runner smoke on real corpus
- **Day 5** — C1-7 brain.ts wire + C1-9 sync migrations (code-2) + integration test pass
- **Day 6-7** — coverage push to 60% + brain-G4 activation per Runbook-Brain-Preflight-Checklist

Total: ~1 week wall-clock; ~40 sub-agent dispatches estimated (vs sprint 1's 120 — narrower scope, deeper per-task).

## Sprint 1 deferred → Sprint 2 carryovers

- PRESENCE.md fix verification (24-48h observation window, by Wed 2026-05-27)
- 9 broken-edge wikilinks (1 ekte broken; 8 documented stubs per audit-v3) — low priority cleanup
- brain-G4 + brain-G6 activation gating sequence (G4 after MEM lands; G6 after G4 stable 1 week)
- Per-project CLAUDE.md updates — operator-domain, not code-2's lane
- Option C gate-cascade to remaining ~10 files (P3 item #16) — backlog
- Spec v1.1 consolidation — defer to sprint 3 unless operator pulls forward

## Operator-action triggers for sprint 2 start

1. **Operator merges first sprint-1 PR** (suggest PR #57 `_template` → unblocks `@cc/_template` resolution → cascades through stack) → sprint 2 implicitly unblocks
2. **OR operator says "sprint 2 GO" explicitly** → I dispatch sprint 2 prep agents (C1-1 + C1-2 in parallel as Day 1 kickoff)
3. **OR operator triggers `letsgooo`/`OK kjør sprint 2`** → autonomous-execute per global CLAUDE.md, same as #2

Until then, sprint 2 is paused at "ready to start" — code-2 holds in coverage-push lane to avoid drift.

## Related

- [[SPRINT-1-COMPLETE-2026-05-25]]
- [[OPERATOR-NEXT-ACTIONS]]
- [[2026-05-25-brain-upgrade-plan]]
- [[Runbook-Brain-Preflight-Checklist]]
- [[coverage-gap-analysis-2026-05-25]]
- [[INTEGRATION_NOTES_v1.2]]
- [[TOMORROW-2026-05-26]]

---

*Prepped by code-2 at sprint 1 close, 2026-05-25T17:00Z. Sprint 2 unblocks on operator PR-merge cadence + code-1 MEM/RAG implementation landing.*
