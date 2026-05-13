# B1 — Flip `ENTRY_STACK_COOLDOWN_ENABLED=true` (env-only)

**Status:** plan ready, NOT executed. Operator runs the Railway mutation.
**Reviewer:** Karri (gate already approved at proposal-level).
**Code path:** `apps/worker/src/firm/gates/new-gates.ts:115` + wire-up `apps/worker/src/firm/strategy-blade.ts:273-331`.

## What the flag does

`ENTRY_STACK_COOLDOWN_ENABLED=true` flips the `entry_stack_cooldown` evaluation from **soft-log** to **hard-reject**. When the previous same-direction XAUUSD entry opened <`ENTRY_STACK_COOLDOWN_MINUTES` (default 15) min ago, mini-Blade returns `approved=false` with reason `stack_cooldown_<N>min_lt_15min` and the proposal never reaches execution. No other behaviour changes (soft-log still writes a `gate_decisions` row with `hard_rejected=true`).

## Pre-flip prerequisites (all must be true)

- [x] `STRATEGY_BLADE_ENABLED=true` on Worker — **confirmed live**: `session_block` produced 4 hard_rejects in last 48h (proves master is ON; mini-Blade running).
- [x] `STRATEGY_BLADE_NEW_GATES=true` (default true when master ON) — confirmed: 5 new-gates wrote 15 evals last 48h.
- [x] `NEW_GATES_SOFT_LOG_ENABLED=true` (default) — soft-log audit row continues after flip.
- [x] `ENTRY_STACK_COOLDOWN_MINUTES=15` (default; do not change) — matches Karri approval scope.

No code dependencies. No migration. Single env var.

## Railway command (copy-paste)

```bash
railway variables --set "ENTRY_STACK_COOLDOWN_ENABLED=true" --service Worker
```

(Service name "Worker" per `docs/ref/env-vars.md:5` and precedent in `scripts/firm/preflight.sh:84`. Worker auto-redeploys on env change ~30 sec.)

## Post-flip verification (T+24h)

```sql
-- Run via nexus-pg MCP
SELECT
  DATE(recorded_at) AS day,
  COUNT(*) FILTER (WHERE would_reject) AS would_rejects,
  COUNT(*) FILTER (WHERE hard_rejected) AS hard_rejects,
  array_agg(DISTINCT context->>'strategyId') AS strategies
FROM gate_decisions
WHERE gate_name = 'entry_stack_cooldown'
  AND recorded_at > NOW() - INTERVAL '24 hours'
GROUP BY DATE(recorded_at)
ORDER BY day DESC;
```

**Expected:** `hard_rejects > 0` AND `hard_rejects = would_rejects` (every flagged eval now hard-blocks). Pre-flip baseline: `hard_rejects = 0` always.

**Discord briefing line to watch (morning sweep):**
`[firm.new-gates] cycle=… flagged=entry_stack_cooldown(HARD)` — `(HARD)` not `(soft)` confirms the flip is live.

**Sanity probe:** `curl -s $API/health | jq .blackboard` — must stay green; gate-flip should not affect cycle health.

## 30-second rollback

```bash
railway variables --set "ENTRY_STACK_COOLDOWN_ENABLED=false" --service Worker
```

(Or remove entirely: `railway variables --remove ENTRY_STACK_COOLDOWN_ENABLED --service Worker` — env-var absence = `false` per `boolEnv` default.)

Rollback trigger: would-reject rate spikes >20% of all firm-path proposals AND post-mortems show ≥3 of those would have been winners. Default-OFF behaviour restores within one cycle.

## Expected impact

Based on `gate_decisions` data 2026-04-24 → 2026-05-12 (post `STRATEGY_BLADE_NEW_GATES=true` flip 11.5):

- **Block rate:** 3 would_reject across 15 firm-path evals last 48h = **~20% rejection of same-dir entries within 15-min window**. Across the active trading day 11.5 alone: 3 of ~8 candidates (the 13:14 cluster).
- **Strategies most affected:** `xau-scalp-overlap` (short side — 2 of 3 hits 11.5), then `xau-volatility-expansion` (long side — 1 hit). Both fire intraday → highest stacking-risk surface.
- **Estimated daily block count:** 2-4 entries/day on average trading days (sample n=15 small; revisit at T+7d).
- **Counterfactual on 11.5:** 2 of the 3 13:14-cluster scalp-overlap shorts (-$1058 in 28 min) would have been blocked. Vol-expansion long-leg blocked too. Net: removes the highest-cost stacking-pattern from the loss tape.

**Cost of false positive:** rejected entry is logged but not retried — strategy waits for next cycle (~30s) and re-evaluates with fresh same-dir-mins. Operator can always rollback in 30s.

---

**Status: ready for "OK kjør". Do not execute without operator trigger.**
