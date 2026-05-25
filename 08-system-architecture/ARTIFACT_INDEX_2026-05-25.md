---
title: Brain Upgrade Artifact Index — 2026-05-25
date: 2026-05-25
status: complete (sprint 1)
purpose: Complete inventory of every artifact created during the 80+ agent brain-upgrade sprint
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[2026-05-25-BRAIN-UPGRADE-FINAL-SUMMARY]]"
tags:
  - meta
  - inventory
  - sprint
  - artifact-index
---

# Brain Upgrade Artifact Index — 2026-05-25

Operator-facing single-source inventory. Every artifact created during the 80+ agent brain-upgrade sprint is enumerated below, categorized by type, with wikilinks for navigation.

## Brain content

### Plan + status
- [[2026-05-25-brain-upgrade-plan]] (v1.2 draft, 10 modules, §14 STATUS)
- [[2026-05-25-BRAIN-UPGRADE-FINAL-SUMMARY]] (single-page final)

### Specs (`08-system-architecture/specs/`)
- [[MEMORY_DISTILLATION_SPEC]] v1.0.2
- [[AGENT_ORCHESTRATION_SPEC]] v1.0.2
- [[RAG_ENGINE_SPEC]] v1.0.2
- [[SKILL_REGISTRY_SPEC]] v1.0.2
- [[OBSIDIAN_BRAIN_STRUCTURE]] v1.0.2
- [[YOUTUBE_INGESTION_SPEC]] v1.0.2
- [[GITHUB_DISCOVERY_SPEC]] v1.0.2
- Stubs: [[LICENSE_GUARD_SPEC]], [[MEMORY_OBJECT_SPEC]], [[RETROSPECTIVE_SPEC]]

### Audit + reports (`08-system-architecture/`)
- [[INTEGRATION_NOTES_v1.1]], [[INTEGRATION_NOTES_v1.2]]
- [[wikilink-audit-2026-05-25]], [[wikilink-audit-v2-2026-05-25]]
- [[audit-report-2026-05-25]], [[audit-report-v2-2026-05-25]] (audit-report-v3 deferred — not created)
- [[preflight-report-2026-05-25]]
- [[cleanup-report-2026-05-25]]
- [[coverage-gap-analysis-2026-05-25]]
- [[link-graph-insights-2026-05-25]], [[link-graph-v2-2026-05-25]]
- [[wikilink-reconciliation-2026-05-25]]
- [[presence-investigation-2026-05-25]]
- [[test-summary-2026-05-25]]
- [[pre-distill-manifest-2026-05-25]]
- [[recall-eval-2026-05-25]] (in `eval/` subfolder)
- [[ARTIFACT_INDEX_2026-05-25]] (this file)

### Samples
- `08-system-architecture/samples/sample-memory-object.json`
- `12-youtube/_samples/sample-distilled-youtube-note.md`
- `13-github-repos/_samples/sample-distilled-github-note.md`

### MOCs (`_maps/`)
- [[System-Architecture-MOC]]
- [[Memory-MOC]]
- [[RAG-MOC]]
- [[Skills-MOC]]
- [[Tasks-MOC]]
- [[Youtube-MOC]]
- [[Github-Repos-MOC]]
- [[Retrospectives-MOC]]
- [[Packages-MOC]]

### Skills (`03-skills/`)
- [[brain-distill-daily]]
- [[youtube-ingest]]
- [[github-discover]]
- [[multi-agent-dispatch]]
- [[worktree-spawn-cleanup]]
- [[brain-recall]]
- [[brain-task-list]]
- [[brain-task-claim]]
- [[brain-task-complete]]
- (`03-skills/README.md` index)

### Runbooks (`_runbooks/`)
- [[Runbook-Brain-Upgrade-Workflow]]
- [[Runbook-Sample-Task-Walkthrough]]
- [[Runbook-Brain-Preflight-Checklist]]
- [[Runbook-Brain-Demo]]

### Templates (`00-templates/`)
- `atomic.md`, `moc.md`, `skill.md`, `retrospective.md`, `task.md`, `memory-object.md`, `youtube-note.md`, `github-repo-note.md` + `README.md`

### Decisions (`_decisions/`)
- [[2026-05-25-operator-gate-naming]] (I-1)

### Operator-facing (brain root)
- [[00-CHEAT-SHEET]] (G-4)
- [[OPERATOR-NEXT-ACTIONS]] (G-5, J-7 updated)
- `00-claude-inbox/command-center/2026-05-25-30-agent-audit.md` (D-9, I-7 updated to 80-agent)
- `00-claude-inbox/command-center/2026-05-25-brain-upgrade-fase2.md` (B-10 tracking)
- `00-claude-inbox/command-center/2026-05-25-brain-upgrade-fanout-status.md`
- `00-claude-inbox/command-center/2026-05-25-karri-handoff-prs.md`
- `00-claude-inbox/command-center/2026-05-25-36-prs-final-snapshot.md`

### Retrospectives (`09-retrospectives/`)
- [[2026-W22]] (B-7, first weekly retrospective)
- `09-retrospectives/README.md`

### Queue templates (drop-zones)
- `12-youtube/_queue/HOW-TO-DROP-URL.md` (D-10)
- `13-github-repos/_queue/HOW-TO-DROP-SEARCH.md` (D-10)
- `10-tasks/_open/HOW-TO-CREATE-TASK.md` (D-10)
- `10-tasks/README.md`
- `12-youtube/README.md`, `13-github-repos/README.md`

### Pilot tasks (`10-tasks/_open/`)
- [[T-2026-05-25-001-rag-semantic-chunker]]
- [[T-2026-05-25-002-skill-registry-discovery]]
- [[T-2026-05-25-003-youtube-ytdlp-wrapper]]

### Allowlists
- `12-youtube/_channels.yaml` (stub)
- `13-github-repos/_topics.yaml` (stub)

### Brain scripts (`scripts/`)
- `brain-content-audit.sh` (F-9, H-1 patched, I-5 exempted)
- `brain-link-graph.sh` (G-7, J-2 enhanced)

### Sanity + workspace meta
- `/home/nithu/code/README.md` (H-8)
- `/home/nithu/code/CLAUDE.md` (updated by F-2)
- `~/Obsidian/Brain/README.md` (updated by F-3)
- `~/Obsidian/Brain/00-DASHBOARD.md` (updated by D-7)
- `~/Obsidian/Brain/00-CONTROL-PANEL.md` (updated by D-7)

## Command-center artifacts

### New TS packages (`packages/`)
- `@cc/skill-registry` (B-4 scaffold + D-1 full impl + tests) — `src/{auto-create,discover,invoke,parse,validation,types,index}.ts`
- `@cc/_template` (B-8 boilerplate) — `src/{index,types}.ts` + `tests/smoke.test.ts`
- `@cc/youtube-ingest` (D-2) — `src/{chunking,distill,fetch,hype-filter,transcript,write-note,types,index}.ts`
- `@cc/github-discovery` (D-3) — `src/{distill,extract,license-guard,risk-detect,score,search,types,index}.ts` + 5 tests
- `@cc/rag-engine` (D-6 eval-runner scaffold) — `src/{cli,metrics,parse-eval-set,runner,stubs,types,index}.ts` + 3 tests
- `@cc/integration-tests` (E-4 e2e harness)

### Coverage gate (root)
- `vitest.config.ts` (G-9 warning-mode)
- `package.json` updates (G-9 + I-4 + J-4 + J-5 deps)

### Bash scripts (`_bin/`)
- `firm-task-claim.sh` (B-5)
- `firm-task-complete.sh` (B-5)
- `brain-preflight.sh` (E-3)

### API routes (`apps/api/src/routes/`)
- `brain.ts` extended with 7 endpoints (E-1 scaffold + G-8 decisions)
- `brain.test.ts`
- `brain-decisions.spec.md` (H-10 endpoint contract)

### Web pages (`apps/web/app/brain/`)
- `page.tsx` (index), `recall/`, `memory/`, `skills/`, `tasks/`, `routines/`, `rag/` (E-5 = 7 pages)
- `components/brain/BrainShell.tsx` (E-5 shared)
- `components/brain/OperatorDecisionQueue.tsx` (G-8)
- `apps/web/hooks/useLiveStream.ts`

### Tests (`apps/api/test/`, `packages/*/tests/`)
- `apps/api/src/executor-worker.test.ts` (I-4, +23 tests)
- `apps/api/src/routes/brain.test.ts` (I-4, J-5)
- ws.test.ts (J-4, in flight)
- Per-package tests in 6 new packages

### Commit-ready (root)
- `COMMIT_PLAN_2026-05-25.md` (E-2 — 8 PRs planned)
- `docs/_VERIFICATION/2026-05-25-final-ci-survey.md`

## Summary stats

- Brain files: ~50+ new artifacts
- Command-center files: 100+ new files across 6 packages + apps
- Tests: 341 → 565+ (+220+)
- Specs: 7 (all v1.0.2) + 3 stubs
- MOCs: 9 (System-Architecture-MOC was extended)
- Runbooks: 4 new + 1 extended
- Skills: 9 (was 1)
- Total agents that produced all this: ~90 sub-agents over 10 phases

## How to navigate this index

- For overview: read [[2026-05-25-BRAIN-UPGRADE-FINAL-SUMMARY]]
- For deep dive: read [[2026-05-25-brain-upgrade-plan]]
- For next actions: read [[OPERATOR-NEXT-ACTIONS]]
- For specific feature: navigate to its MOC then its spec
- For drop-zones (URLs/repos/tasks): see `12-youtube/_queue/`, `13-github-repos/_queue/`, `10-tasks/_open/`

## Status

Sprint 1 COMPLETE. Next sprint = operator OK kjør on commits + code-1 lane implementation.

## Verification

- [x] All artifact categories enumerated (plan, specs, audits, MOCs, skills, runbooks, templates, decisions, retros, queues, tasks, allowlists, scripts, sanity, packages, scripts, API, web, tests, commit-plan)
- [x] Wikilinks valid against filesystem (audit-report-v3 noted as not created; ws.test.ts noted in flight)
- [x] Counts cross-checked vs feed.md + brain-plan §14
- [x] Frontmatter YAML valid (title/date/status/purpose/related/tags)
- [x] Operator-usable as single navigation source
