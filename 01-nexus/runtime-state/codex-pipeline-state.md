---
type: living-state
subsystem: codex-code-drainer
last_verified: 2026-05-11T15:30Z
status: 🟢
mode: local-ready, prod-dormant
---

# Codex Pipeline — Living State

Living state doc. Source: `agent_tasks` + `agent_results` joined on `role='code'`; runner header at `scripts/agent-codex-runner.mjs`; runbook `docs/ops/codex-activation-runbook.md`.

## Current state (verified 2026-05-11)

- **Production**: **dormant** — `AGENT_BUS_ENABLED=false` everywhere (Railway worker + local dev default)
- **Phase 2a runbook**: landed at `docs/ops/codex-activation-runbook.md`
- **Air-gap**: verified — trading-loop prefixes blocked in both runner + PR-opener
- **CLI**: `codex-cli 0.128.0` at `~/.nvm/versions/node/v24.15.0/bin/codex` (operator's WSL)
- **Runner**: `scripts/agent-codex-runner.mjs` — drains `role=code` tasks, dispatches via `codex exec --sandbox workspace-write` inside per-task git worktree
- **PR-opener**: `scripts/agent-pr-opener.mjs` — opens PRs only when `agent_results.review_verdict='approved'`, never auto-merges
- **Hard timeout**: `AGENT_CODEX_TIMEOUT_SEC=600` (bounded 30–3600)
- **Concurrency**: `AGENT_TASK_MAX_INFLIGHT_PER_ROLE=3`
- **Local-mirror prod-DB guard**: commit `15089c6` — codex-runner now refuses rlwy.net/railway.app DB URLs unless `RALPH_ALLOW_PROD_DB=true`. See [[local-mirror-safety-state]]

## Trading-loop air-gap

Both runner and PR-opener block these prefixes without literal `TRADING_LOOP_OK` marker in `task.prompt`:

```
apps/worker/src/firm/orb/
apps/worker/src/firm/scalp-overlap/
apps/worker/src/firm/session-breakout/
apps/worker/src/firm/vol-expansion/
apps/worker/src/firm/strategy-execution
apps/worker/src/firm/strategy-blade
apps/worker/src/firm/orchestrator
```

- **Primary guard**: `enforceTradingLoopGuard()` in `agent-codex-runner.mjs:257-271` — throws synchronously before `codex exec`
- **Defense-in-depth**: `openPr()` in `agent-pr-opener.mjs:149-155` — re-parses diff, drops candidate with `pr_skipped` reason=`trading_loop_guard`

## Recent changes

- 2026-05-11: Phase 2a runbook landed at `docs/ops/codex-activation-runbook.md`
- 2026-05-11: `15089c6` — prod-DB guard added to codex-runner + ralph (see [[local-mirror-safety-state]])
- 2026-05-11: air-gap verified by source-read (lists identical between runner + PR-opener)

## Health indicators

- `AGENT_BUS_ENABLED=false` on Railway → zero `role=code` tasks in production
- Air-gap prefix lists identical in both runner + PR-opener
- Auto-review chain: `AGENT_AUTO_REVIEW=true` default → every successful code task emits `role=review` task

## Open issues

- [ ] Production activation blocked on: foundation 🟢 (currently 4/5) + 30d Phase 3 stable + explicit "OK kjør" referencing runbook
- [ ] No automated tests cover the shell-driven runner directly — health asserted via live runs + runbook checklist
- [ ] `gh` CLI auth required for Phase 2c PR-opener — operator's setup, verify before first prod activation
- [ ] Fresh-clone local repo without booting worker fails (agent-bus tables missing) — documented in runbook

## Activation conditions (production)

Requires ALL of:
1. Foundation gate 🟢 (currently 🟡 on rule 2)
2. 30 days of stable Phase 3 firm-agent operation
3. Explicit operator "OK kjør" referencing the runbook
4. Rollback plan rehearsed

## Verification SQL

```sql
-- recent code-drainer activity (should be 0 in prod)
SELECT date_trunc('hour', r.created_at) AS hour, COUNT(*)
FROM agent_results r JOIN agent_tasks t ON r.task_id=t.id
WHERE t.role='code' AND r.created_at > NOW() - INTERVAL '7 days'
GROUP BY 1 ORDER BY 1 DESC;
```

Expected (prod): 0 rows. Local: rows only during operator-run drain sessions.

## Cross-refs

- Runbook: `docs/ops/codex-activation-runbook.md`
- Charter: `docs/ref/agent-bus.md`
- Foundation gate: `docs/ops/new-strategy-gate.md`
- Phase status: `docs/ops/phase-status.md`

Linked to: [[Nexus-MOC]], [[Module-Agent-Bus]], [[gemini-pipeline-state]], [[foundation-gate-state]], [[local-mirror-safety-state]], [[Operator-Principles]] (prinsipp 6: autotune is long-term), [[OK-Kjor-Gate]] (activation gate), [[Foundation-Gate]] (rule 4 prerequisite), [[Truth-Hierarchy]] (runbook in repo `docs/ops/` is canonical)
