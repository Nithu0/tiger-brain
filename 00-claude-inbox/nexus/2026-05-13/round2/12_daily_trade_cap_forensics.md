# 12 — Daily trade-cap forensics

**Root cause**: Gate landed AFTER the runaway day. Not a logic bug — a deploy-timing artifact. The 8 logged decisions / 0 blocks pattern is explained by the gate having had no opportunity to fire.

**Fix (file:line)**: No fix to gate logic required. Two narrower issues worth addressing — see "Real issues" below.

**How to verify after fix**:
```sql
-- After any high-volume day (≥7 firm_strategy trades), expect a block row:
SELECT recorded_at, context->>'count', context->>'cap', hard_rejected
FROM gate_decisions WHERE gate_name='daily_trade_cap' AND hard_rejected=true
ORDER BY recorded_at DESC LIMIT 5;
```

---

## Timeline reconciliation

| Day (UTC) | firm_strategy trades | PnL | Gate active? |
|---|---|---|---|
| 2026-05-11 | **9** | **−$2 638** | NO (gate landed 12.5) |
| 2026-05-12 | 3 | −$1 163 | yes — but only 3/6, no block warranted |

Commit `b8195b9 feat(gates): daily_trade_cap per Karri proposal 12.5` was the first time the gate code existed. 11.5's losses predate it by 24h.

## The 8 logged rows on 12.5

All from 2026-05-12 14:00–17:35 UTC. Counts observed: `[0,0,0,0,0,1,1,2]`. Cap=6. Highest count never reached 6, so `count >= cap` never fired. The gate WAS executing and counting correctly — it just never saw enough trades to block.

## Logic walk-through (verified clean)

`apps/worker/src/firm/gates/daily-trade-cap-gate.ts:110-143`:
- Counts `simulated_orders` where `opened_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC')` AND `execution_source='firm_strategy'`.
- Postgres server TZ = `Etc/UTC` (verified `SHOW timezone`). `opened_at` is `timestamptz`. Bound resolves to today-00:00 UTC. Reset at UTC midnight is correct.
- Threshold: env-driven `DAILY_TRADE_CAP` (default 6, range 1-20). `dailyTradeCap()` returns DEFAULT_CAP on missing/invalid → cannot silently become Infinity.
- Block branch (`count >= cap`) returns `allowed: false`, persisted via `persistDailyCapDecision`, propagated through `strategy-blade.ts:191` → `finalize()` → `approved: false` → `strategy-execution.ts:528-529` returns `{ executed: false }`. Wiring is intact.
- Counter counts OPEN+CLOSED (no `status` filter) — correct for cap intent (you want to limit entries, not closes).

No off-by-one, no wrong-day-boundary, no short-circuit. The gate would work.

## Real issues worth flagging (NOT the cause of 11.5 losses)

### Issue 1 — Gate counts only `execution_source='firm_strategy'`
Production data shows 4 distinct `execution_source` values in last 30d:
- `firm_strategy`: 67 (counted by gate)
- `NULL`: 79 (NOT counted)
- `firm_blade`: 6 (NOT counted — legacy `managers.ts:1018`)
- `oanda_backfill`: 3 (NOT counted — correct)
- `oanda_import`: 1 (NOT counted — correct)

If both `managers.ts` (firm_blade) and TIER 3 path (firm_strategy) fire on the same day, the cap under-counts. Karri's backtest used total-trades-per-day, not firm_strategy-only. In practice ORB_ONLY_MODE keeps managers.ts dormant — but if it ever flips back on, the cap leaks.

**Fix proposal** (apps/worker/src/firm/gates/daily-trade-cap-gate.ts:115):
```sql
AND execution_source IN ('firm_strategy','firm_blade')
```

### Issue 2 — `execution_source` is set via UPDATE AFTER tryOpenPosition INSERT
`strategy-execution.ts:741+764` stamps `execution_source='firm_strategy'` via UPDATE after the row is INSERTed (which uses default NULL). If the UPDATE fails (network blip, log shows "Failed to mirror OANDA fill into simulated_orders"), the trade exists but is invisible to the gate. Race window: trade N+1's gate query during trade N's UPDATE-in-flight will undercount by 1.

Not catastrophic at cap=6 (you'd need 6 races to occur back-to-back), but at lower caps it matters.

**Fix proposal**: have `tryOpenPosition` accept and INSERT `execution_source` inline instead of post-UPDATE patch. Cleaner; eliminates race + 79 historical NULL rows pattern.

## Decision

Operator does not need to change daily-trade-cap-gate.ts for the 11.5 issue. The cap WILL block on the next high-volume day provided `DAILY_TRADE_CAP_ENABLED=true` is set in Railway.

Verify env flag is live in Railway. If not set, the gate is silently bypassed at line 100.

Issue 1 (execution_source filter) → file as separate proposal if managers.ts ever re-enables.
Issue 2 (UPDATE race) → low-priority hardening; queue behind higher-impact work.

---

Generated 2026-05-13 by Claude Code forensic sweep round 2.
