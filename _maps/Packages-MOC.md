---
title: Packages MOC — command-center monorepo
type: moc
created: 2026-05-25
purpose: Inventory of all @cc/* TypeScript packages in command-center, with status + dependencies + maintainer
related:
  - "[[System-Architecture-MOC]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[command-center]]"
tags: [moc, packages, command-center, monorepo]
---

# Packages MOC — command-center monorepo

> All `@cc/*` packages in `/home/nithu/code/command-center/packages/`. Updated 2026-05-25 after fase 4-5 (brain-upgrade).

## Pre-brain-upgrade packages (Slices 1-13)

These shipped as part of Slices 1-13 (see `[[command-center]]`). All build to `dist/` and ship `main: ./dist/index.js`. Tests are colocated `*.test.ts` under `src/` (or run through `apps/api`).

| Package | Version | Purpose | Slice |
|---|---|---|---|
| `@cc/shared` | 0.1.0 | Shared types + project registry | 1 |
| `@cc/git` | 0.1.0 | Cross-repo git status reader | 1 |
| `@cc/router` | 0.1.0 | Intent → ProposedCommand routing via `@cc/engines` | 2 |
| `@cc/executor` | 0.1.0 | Approval-gate + safe-exec + firm-bus handoff | 3 |
| `@cc/bus` | 0.1.0 | WebSocket broadcast (commands/git/presence) | 4 |
| `@cc/agents` | 0.1.0 | 6 desk-agents (Atlas/Cipher/Shield/Prism/Forge/Blade) via `@cc/engines` | 6 |
| `@cc/github` | 0.1.0 | gh CLI wrapper + PR/branch/CI/issue/commit drafting (uses `@anthropic-ai/sdk`) | 7 |
| `@cc/sync` | 0.1.0 | Litestream + multi-operator audit + migrations (peerDep `better-sqlite3`) | 8 |
| `@cc/brain` | 0.1.0 | Read-only Obsidian project-scoped notes | 10 |
| `@cc/auth` | 0.1.0 | HMAC-signed session tokens + constant-time password verify | 12 |
| `@cc/engines` | 0.1.0 | Multi-engine abstraction: `AnthropicEngine` (Claude) + `OpenAIEngine` ("Codex") | 13 |

Note: no `@cc/db` package exists yet (was planned for Slice 14a). Db dispatch currently lives in `apps/api/src/db.ts` per `[[ADR-002-sqlite-then-postgres]]`.

## New brain-upgrade packages (fase 4-5, 2026-05-25)

New packages added during fase 4-5 of the brain-upgrade. These use the `_template` pattern: `main: ./src/index.ts` (no build step), `tests/` directory, vitest, `js-yaml` for frontmatter parsing.

| Package | Version | Purpose | Source |
|---|---|---|---|
| `@cc/_template` | 0.0.0 | Standard TS package boilerplate (copy-source) | B-8 |
| `@cc/skill-registry` | 0.0.1 | 3-tier skill discovery + invocation + auto-create | B-4 + D-1 |
| `@cc/youtube-ingest` | 0.1.0 | yt-dlp + whisper + distill pipeline | D-2 |
| `@cc/github-discovery` | 0.1.0 | gh search + license-guard + distill | D-3 |
| `@cc/rag-engine` | 0.1.0 | RAG (T1/T2/T3) + `rag-eval` CLI (T1-3 stubbed, code-1 implements) | D-6 |
| `@cc/integration-tests` | 0.1.0 | E2E happy-path across new packages | E-4 |

## Planned (code-1 lane, in progress)

Scaffold directories exist (with `node_modules/` only — no `package.json` / `src/` yet). code-1 owns implementation per `[[2026-05-25-brain-upgrade-plan]]`.

| Package | Purpose | Owner | Status |
|---|---|---|---|
| `@cc/brain-orchestrator` | Adaptive cycle + triggers (lift from FirmOrchestrator) per `[[AGENT_ORCHESTRATION_SPEC]]` | code-1 C1-1 | scaffold pending |
| `@cc/memory-engine` | MemoryObject schema + FTS5 + sqlite-vec storage + distill per `[[MEMORY_DISTILLATION_SPEC]]` | code-1 C1-2/3 | scaffold pending |

code-1 also implements rag-engine retrieval impl for T1/T2/T3 — currently stubbed in D-6's package; replaces `stubs.ts` once memory-engine lands.

## Package dependency graph (high level)

```
@cc/shared
  ↑
  ├─ @cc/router → @cc/engines → @anthropic-ai/sdk + openai
  ├─ @cc/agents → @cc/engines
  ├─ @cc/executor → @cc/bus
  ├─ @cc/sync → better-sqlite3 (peer)
  ├─ @cc/git
  ├─ @cc/brain
  ├─ @cc/github → @anthropic-ai/sdk
  ├─ @cc/auth (no internal deps; node:crypto only)
  ├─ @cc/skill-registry (independent; js-yaml only)
  ├─ @cc/youtube-ingest → @cc/memory-engine (planned), @cc/rag-engine
  ├─ @cc/github-discovery (independent; js-yaml only)
  ├─ @cc/rag-engine → @cc/memory-engine (planned)
  ├─ @cc/brain-orchestrator (planned) → @cc/memory-engine (planned)
  └─ @cc/integration-tests → @cc/skill-registry, @cc/youtube-ingest,
                              @cc/github-discovery, @cc/rag-engine
apps/api → all
apps/web → apps/api via HTTP
```

## Test counts (per fase-5 test summary 2026-05-25)

- Total: 522/522 passing across 50 files
- New from brain-upgrade: +181 tests
  - `@cc/skill-registry` — 25
  - `@cc/_template` — 1
  - `@cc/youtube-ingest` — 34
  - `@cc/github-discovery` — 76
  - `@cc/rag-engine` — 30
  - `@cc/integration-tests` — 4 (+ todo placeholders)
  - `apps/api` (`brain.ts` route) — 22

## Test-summary doc

`[[test-summary-2026-05-25]]`

## Coverage baseline (2026-05-25)

Per `[[coverage-gap-analysis-2026-05-25]]` (H-3) + G-9 setup:

| Metric | Baseline | Target | Mode |
|---|---|---|---|
| Lines | 43.31% | 60% | warning |
| Statements | 43.31% | 60% | warning |
| Branches | 77.05% | 50% | ✓ above |
| Functions | 71.13% | 60% | ✓ above |

**527/530 tests passing.** Coverage in WARNING mode — doesn't fail CI.

### Per-package coverage (if available)
| Package | Lines | Statements | Branches | Functions | Notes |
|---|---|---|---|---|---|
| @cc/skill-registry | N/A* | | | | |
| @cc/youtube-ingest | | | | | |
| @cc/github-discovery | | | | | |
| @cc/rag-engine | | | | | |
| @cc/_template | excl | | | | by design |
| @cc/integration-tests | excl | | | | by design |

*Per-package breakdown requires `--reporter=json-summary` or HTML; see `coverage/index.html`.

### Coverage commands
```bash
npm run test:coverage           # full HTML report
npm run test:coverage:summary   # text summary only
open coverage/index.html        # browse HTML report
```

### Gap analysis
See `[[coverage-gap-analysis-2026-05-25]]` for top 10 uncovered files + recommended sprint plan.

## How to create a new package

1. `cp -r packages/_template packages/<your-pkg>`
2. Update `package.json` (name `@cc/<your-pkg>`, version `0.1.0`, add real deps)
3. Update `README.md` + write code in `src/`
4. From repo root: `npm install` (registers new workspace)
5. From repo root: `npm -w @cc/<your-pkg> test`
6. See `[[2026-05-25-brain-upgrade-plan]]` §2 for which module a new pkg should align with

## Related

- `[[System-Architecture-MOC]]`
- `[[2026-05-25-brain-upgrade-plan]]`
- `[[test-summary-2026-05-25]]`
- `[[COMMIT_PLAN_2026-05-25]]` (where today's uncommitted pkgs are planned for PR)
- `[[command-center]]`
- `[[ADR-001-architecture]]` · `[[ADR-002-sqlite-then-postgres]]`

---

*Last updated 2026-05-25 — post-fase-5. 17 packages enumerated from `packages/` (11 pre-upgrade + 6 brain-upgrade); 2 planned scaffolds (brain-orchestrator, memory-engine) await code-1.*
