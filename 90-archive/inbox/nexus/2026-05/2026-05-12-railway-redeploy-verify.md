# Railway redeploy verify — 21-commit push (Karri+Round 15)

**Date**: 2026-05-11 20:30 UTC (12.5 norsk tidlig morgen)
**HEAD local**: `63b00ce` (fix(session_block_gate): final iteration after concurrent-commit churn)
**Push contents**: 21 commits = 8 Karri PR-merger + 13 Round-15 commits rebased

---

## /health snapshot (T+~5 min after push)

```json
{
  "status": "ok",
  "build": { "commit": "378e7316" },
  "checks": {
    "db":            { "ok": true, "latencyMs": 39 },
    "broker":        { "ok": true, "mode": "demo", "balance": 90441.3911 },
    "blackboard":    { "ok": true, "lastDecisionSec": 22618 },
    "worker":        { "ok": true, "lastHeartbeatSec": 189, "lastCycleNo": 1, "lastError": null },
    "reconciliation":{ "ok": true, "driftCountUnresolved": 0, "balanceDelta": 13.63 }
  }
}
```

**Deployed commit**: `378e7316` (Merge PR#5 scalp-orb observe-only) — **13 commits behind HEAD**

Local-vs-deployed delta (commits NOT yet live):
```
63b00ce fix(session_block_gate): final iteration after concurrent-commit churn
dd0b1ba docs(proposals): record commit SHA for regime_direction_gate
1661bc6 chore(env): document SL_COOLDOWN_* flags
07f5d00 feat(gates): sl_cooldown per Karri proposal 11.5
502bae1 feat(vol-expansion): Phase 1 rejection-stage instrumentation
e609157 feat(dashboard): Phase 1 conviction-quartile histogram
1003091 feat(postmortem): Phase 1 streak-table for size-down feedback
497c6fd docs(proposals): scalp_overlap + orb observe-only approved-await-flip
f5bee29 docs(scripts): postmortem-backfill runbook
138dfd3 docs(ops+strategy): 5 architecture-level concerns from 11.5 audit
e207f6a docs(claude-md): refresh test count (478/478)
1790a75 fix(postmortem): wire regime + analyst-direction into classifier
a265d99 feat(observability): wire macro-event Discord audit-trail
```

Worker is healthy on the pre-push commit. `lastCycleNo: 1` reflects fresh container after Karri's 8 PR-merger landing earlier (378e7316 deployed cleanly).

---

## DB schema checks (run against shared Postgres — independent of which worker commit is live)

### postmortem_streaks table — PRESENT (Phase 1 streak-table)

```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name='postmortem_streaks' ORDER BY ordinal_position;
```

| column_name | data_type |
|---|---|
| strategy_id | text |
| last_postmortem_class | text |
| consecutive_count | integer |
| last_updated | timestamp with time zone |

Row count: 0 (no postmortems written since migration applied — expected, Phase 1 is observe-only and no new trades have closed).

**Schema verdict**: matches `packages/shared/src/db/schema.ts:1467-1472` from commit `1003091`. **Migration applied** — `idempotent CREATE TABLE IF NOT EXISTS` runs at worker boot.

### gate_decisions — column shape intact

`gate_name`, `would_reject`, `hard_rejected`, `reason`, `context` all present. No new gate-name values yet (`session_block`, `sl_cooldown`, `regime_direction_gate` absent from last 24h):

```
gate_name              | hits | last_seen
-----------------------+------+----------------------
entry_stack_cooldown   | 9    | 2026-05-11T14:12:41Z
ranging_conviction     | 9    | 2026-05-11T14:12:41Z
risk_level             | 9    | 2026-05-11T14:12:41Z
scalp_overlap_asia     | 9    | 2026-05-11T14:12:41Z
```

Expected — new gates ship default-OFF (env-gated). And: worker hasn't ticked on `63b00ce` yet, so their code path is not even in memory.

---

## Recent simulated_orders (post-deploy window — 20 min)

Empty. Market quiet (Sunday evening — pre-Sydney open). Latest order was 14:12 UTC:

```
strategy_id            | thesis_quality | conviction | regime_at_entry | session_at_entry      | opened_at
-----------------------+----------------+------------+-----------------+-----------------------+--------------
xau-volatility-expansion| NULL          | NULL       | high            | OVERLAP_ACTIVE        | 14:12 UTC
xau-volatility-expansion| NULL          | NULL       | NULL            | unknown               | 14:00 UTC
xau-scalp-overlap       | NULL          | NULL       | NULL            | unknown               | 13:33 UTC
```

`regime_at_entry` + `session_at_entry` already wired (from `a2f1cbc` / `3a1f2e1` — earlier in today's push and **live** in 378e7316). `thesis_quality_score` + `conviction_total` still NULL — the wiring fix is in those same commits but evaluator may not be emitting them yet for vol-expansion; will confirm next time a trade fires after `63b00ce` is live.

---

## Outstanding

- **Railway is 13 commits behind HEAD.** Possible causes:
  - Auto-deploy debounce / queueing of rapid pushes — likely picking up next batch shortly.
  - Build skipped due to no source-tree change for `apps/worker` (lots of docs commits). Unlikely — `07f5d00`, `1003091`, `502bae1`, `1790a75`, `a265d99` all touch worker code.
  - Railway watching wrong branch. Should be `main`.
  - Monitor was still polling for `63b00ced` when this report was written.

- **Action for operator**: Open Railway dashboard → confirm deploy of `63b00ce` is queued or building. If stuck, manually trigger redeploy from `main`. Then re-curl /health.

---

## Verdict

**PARTIAL.** Deployed commit `378e7316` reflects Karri's 8 PRs + earlier work today (metadata-wiring) — that half is live and worker is green. The 13 Round-15 commits (gate features, streak table code path, dashboard quartile, vol-expansion rejection-stage instrumentation) are NOT yet on the live worker. Schema migrations that gate on `IF NOT EXISTS` (e.g., `postmortem_streaks`) DID apply because the table was created by some pre-378e7316 boot — verified present.

No new gate firing observed (expected: env-gated OFF + worker pre-push commit + Sunday market quiet).

Next checkpoint: when /health returns `63b00ced`, recurl /health, recheck `gate_decisions` for 30-min window, and look for `thesis_quality_score` non-NULL on next post-Sydney-open trade.
