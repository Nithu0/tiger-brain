---
date: 2026-05-11
project: nexus
phase: codex-phase-2a
verdict: live-idle
operator-action: AGENT_BUS_ENABLED=true + AGENT_CODEX_DAILY_BUDGET_USD flipped on Railway
---

# Codex Phase 2a — production activation verification

## Operator action

Flipped on Railway:

- `AGENT_BUS_ENABLED=true`
- `AGENT_CODEX_DAILY_BUDGET_USD` (value not read; default 50 if unset)

## Probe results (UTC 2026-05-11 ~13:58–13:59)

### `/health` build (post 90s wait for restart)

```
commit:           b6b4934c    (= git HEAD b6b4934, "test(orchestrator): smoke + step-flow coverage")
lastCycleNo:      6           (was 3 at first probe — cycles advancing)
lastHeartbeatSec: 5
worker.ok:        true
db.ok:            true
broker.ok:        true (demo, balance 91187.0604)
reconciliation:   ok, drift=0
```

Worker survived env-var restart and is back to nominal cadence.

### `agent_tasks` for `role=code`

```sql
SELECT id, status, role, model, created_at, claimed_at, finished_at, claimed_by
FROM agent_tasks WHERE role='code'
ORDER BY created_at DESC LIMIT 10;
```

→ **0 rows.** No code-tasks have ever been queued in production. Existing roles: `research` (23 done / 25 failed), `review` (34 done / 1 failed).

Schema note: column is `finished_at`, not `completed_at` (runbook query had a typo — corrected here for future probes).

### `agent_results` for role=code last 24h

```sql
SELECT id, task_id, status, cost_usd, tokens_in, tokens_out, created_at
FROM agent_results
WHERE created_at > NOW() - INTERVAL '24 hours'
  AND task_id IN (SELECT id FROM agent_tasks WHERE role='code')
ORDER BY created_at DESC LIMIT 10;
```

→ **0 rows.** `SUM(cost_usd)` over the same set returns `null`. Today's spend = $0.00, well under any budget cap. Budget-check code has nothing to exercise — but also nothing to error on.

### Blackboard codex topics last 1h

```sql
SELECT topic, COUNT(*), MAX(timestamp) FROM blackboard
WHERE topic LIKE '%codex%' AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY topic;
```

→ **0 rows.** Also checked `LIKE 'xauusd.codex%'` over all time: 0 rows. No `xauusd.codex.budget_exhausted` or autoclean events. Active topics last 30 min are the normal firm topics (market.raw, analysis.*, manager.decisions, etc.).

## Architecture note (why no autoclean / no drainer activity is expected)

`scripts/agent-codex-runner.mjs` is a **local** script. It refuses to claim prod code-tasks unless `AGENT_RUNNER_PROD_CLAIM=true` (line 107–119). The Railway env-flip opens the *bus side* — queue is reachable, idempotency hashing works, budget-check code is loaded — but the actual code-task drainer runs on operator's local machine, not in the Railway worker.

Autoclean (`AGENT_CODEX_AUTOCLEAN_ENABLED`, default true) fires at the start of each local drainer loop. It will appear in the blackboard only when the local runner runs — not from Railway.

## Verdict

**Phase 2a is LIVE (idle).** All preconditions satisfied:

- Bus is reachable (worker came back clean post-restart)
- Queue table exists, schema intact, `role='code'` is a valid filter
- Budget-check code is on the deployed commit (`b6b4934c` matches HEAD)
- No code-tasks queued → no errors → no work
- No autoclean noise → expected (drainer is local, not running on Railway)

## What to expect next

Code tasks will appear from one of:

1. **Manual operator queueing** — operator runs a one-shot INSERT or calls the agent-bus client with `role: "code"` to test end-to-end.
2. **Phase 5 trigger-publish** — not yet shipped. Firm agents will emit code-tasks autonomously when Phase 5 lands. Until then, the queue stays empty by design.

Local runner activation (separate from Phase 2a):

- Operator starts `node scripts/agent-codex-runner.mjs` on their machine with `AGENT_BUS_ENABLED=true` + `AGENT_RUNNER_PROD_CLAIM=true`.
- Drainer polls `claimNextTask("code", ...)` and processes anything Phase 5 (or manual queueing) deposits.

No action required from Claude. Operator owns the next step (manual queue test OR wait for Phase 5).

## Followup queries (for next checkpoint)

```sql
-- Same set, anytime:
SELECT id, status, claimed_by, created_at, claimed_at, finished_at
FROM agent_tasks WHERE role='code' ORDER BY created_at DESC LIMIT 10;

-- Today's codex spend (if any):
SELECT COUNT(*) AS n, SUM(cost_usd) AS usd, SUM(tokens_in) AS tin, SUM(tokens_out) AS tout
FROM agent_results
WHERE created_at > NOW() - INTERVAL '24 hours'
  AND task_id IN (SELECT id FROM agent_tasks WHERE role='code');

-- Budget-exhausted events (would prove budget-cap fired):
SELECT id, timestamp, state FROM blackboard
WHERE topic='xauusd.codex.budget_exhausted' ORDER BY timestamp DESC LIMIT 5;
```
