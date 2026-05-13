---
date: 2026-05-11
project: nexus
topic: codex-phase-2a-activation-prep
status: docs-only, dormant on prod, ready locally
---

# Codex Phase 2a — Activation prep (2026-05-11)

## TL;DR

Documentation pass to unblock local Codex testing today. No code change. Production stays dormant (`AGENT_BUS_ENABLED=false` on Railway). Operator can flip locally with a single bash command — low risk because the runner is read-only on the main checkout (operates inside `worktrees/agent-<task-id>`) and refuses tasks touching seven `firm/*` trading-loop prefixes.

## What was verified

1. **Codex CLI** — `codex-cli 0.128.0` resolves to `~/.nvm/versions/node/v24.15.0/bin/codex`. Meets `≥0.128.0` minimum.
2. **Runner invocation** — `AGENT_BUS_ENABLED=true CODEX_BIN=codex node scripts/agent-codex-runner.mjs` runs cleanly, drains queue, exits with `drained=0 failed=0` when no `role=code` tasks queued. (`--help` is not a recognized flag; runner just runs.)
3. **Air-gap (binding)** — Direct source read of both scripts. Identical 7-prefix lists:
   - `scripts/agent-codex-runner.mjs` lines 76–84 → `enforceTradingLoopGuard` throws before dispatch.
   - `scripts/agent-pr-opener.mjs` lines 66–74, 149–155 → defense-in-depth at PR-open time. Records `pr_skipped` audit event with `reason=trading_loop_guard`.
   - Marker pattern: literal substring `TRADING_LOOP_OK` in `task.prompt` lifts the block.
4. **Local-firm-mirror plumbing** — `scripts/firm/ralph.mjs --role=blade` shells to the codex-runner, so the zellij firm pane is already wired (line 19-ish header comment).
5. **No existing tests** under `apps/worker/src/**/*.test.ts` for `agent-codex` — runner is shell-driven, not imported. (Phase 0/1 has SQL/bus-shape tests; runner script tested via live `gemini -p` runs per 03.5 session log.)

## What was written

| File | Purpose |
|---|---|
| `docs/ops/codex-activation-runbook.md` | New — local+prod activation paths, air-gap verification, rollback (30s), advancement gates to Phase 4/5 |
| `.env.example` | Added 7 documented Codex env-vars (`CODEX_BIN`, `CODEX_DEFAULT_MODEL`, `AGENT_CODEX_TIMEOUT_SEC`, `AGENT_CODEX_WORKTREE_ROOT`, `AGENT_AUTO_REVIEW`, `AGENT_PR_OPENER_BASE_BRANCH`, `AGENT_PR_OPENER_TIMEOUT_SEC`) + `AGENT_TASK_MAX_INFLIGHT_PER_ROLE` |
| `docs/ops/phase-status.md` | Sub-decision 6 in 11.5 list + new live-status row `Codex Phase 2a` |
| `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-codex-activation-prep.md` | This pickup note |
| `~/Obsidian/Brain/01-nexus/runtime-state/codex-pipeline-state.md` | Living-state doc (separate from inbox) |

## How to activate locally today

```bash
cd ~/code/ai-assistent
codex --version                                          # expect ≥0.128.0
AGENT_BUS_ENABLED=true CODEX_BIN=codex \
  node scripts/agent-codex-runner.mjs --max=1            # one-shot drain
```

If queue is empty, runner exits clean. To queue a task for actual testing, use the helpers in `scripts/agent-task.mjs` (insert a `role=code` row with `context_refs: [{type:"file",path:"docs/ref/agent-bus.md"}]` so it's air-gap-clean).

## Production activation conditions (binding)

- Foundation gate fully GREEN (currently 🟡 — regel 2 needs 24-48h, regel 4 caveat to 18.5)
- ≥30 days of Phase 3 stable on Railway with zero anomaly
- Operator explicit "OK kjør" in-session referencing the runbook
- Synthetic air-gap-violating task confirms guard fires post-deploy

## Open question

- The phase-status table footnote claims Agent Bus has been dormant since 03.5; the local invocation succeeded today against a Postgres that may not have `agent_tasks` table provisioned. Worker boot creates the tables idempotently — but if the operator is using a fresh local DB without ever booting the worker, the runner will exit with a SQL error on `SELECT ... FROM agent_tasks`. Workaround: run `docker compose up worker` once locally, or run the migration directly. Documented this in the runbook's verification checklist.
