# Metadata-strip fix — 2026-05-11

## Symptom

Last 47 closed trades on `simulated_orders` show NULL for `strategy_id`, `execution_source`, `atr_at_entry`, `entry_conviction_score` — most also NULL for `portfolio_regime_at_entry` (a few have it set, see below). Spanning 2026-04-28 → 2026-05-11.

Breakdown of all `simulated_orders` by `execution_source`:

| execution_source | count | has_strategy_id | has_atr | has_regime | has_conviction | first | last |
|---|---|---|---|---|---|---|---|
| NULL | 138 | 0 | 0 | 5 | 0 | 2026-04-16 | 2026-05-11 |
| firm_blade | 6 | 0 | 6 | 6 | 6 | 2026-04-23 | 2026-04-24 |
| oanda_backfill | 3 | 3 | 0 | 0 | 0 | 2026-04-28 | 2026-04-28 |

Note that even `firm_blade` rows (the legacy Prism+Blade managers.ts path) have NULL `strategy_id` — they only set `execution_source = 'firm_blade'`, no separate `strategy_id`. `oanda_backfill` rows pack both into one sentinel string.

## Root cause

`apps/worker/src/firm/strategy-execution.ts` is the bridge that turns the 4 TIER 3 strategy PROPOSAL messages (ORB, scalp-overlap, session-breakout, vol-expansion) into OANDA trades + `simulated_orders` rows. After calling `tryOpenPosition` (line 551), it issues two follow-up UPDATEs (line 572-601) to:

- mirror broker fill price (entry/SL/TP)
- stamp `decision_cycle_id`, `original_risk_points`, `portfolio_regime_at_entry`, `risk_level_at_entry`

That was the entire metadata block. The columns `strategy_id`, `execution_source`, `atr_at_entry`, `entry_conviction_score` — written by the legacy path at `managers.ts:1046-1090` — were never added to the TIER 3 follow-up UPDATE. So all 138 trades opened via `firm-strategy:*` signals since commit `e15b67a` (initial TIER 3 bridge) have NULLs across those four columns.

This is a regression in the sense that the legacy path always populated them; the new path never did. Not a fresh break, but a long-standing strip that becomes visible now that TIER 3 is the dominant path (all 47 most-recent trades).

`portfolio_regime_at_entry` was added by commit `fbdf1b3` and now reaches the latest 3 rows (the ones with `TRENDING`/`RANGING`) — the rest came before that commit landed.

## Impact

- `agent-bus/firm-agents/risk-advisor.ts`, `operator-brief.ts`, `daily-journal.ts`, `strategy-tuner.ts`, `agent-trigger.ts` — all SELECT/JOIN/GROUP BY `strategy_id`. With NULL they fall to `"?"` placeholders or drop the row entirely (`AND strategy_id IS NOT NULL` filters in agent-trigger.ts:88 and strategy-tuner.ts:60). Result: per-strategy retrospectives are blind.
- `postmortem.ts:208-210` reads `atr_at_entry` + `entry_conviction_score` to compute R-multiple and conviction calibration. NULL → those columns skip from analytics.
- `firm/status-report.ts:150` groups PnL by `execution_source` → most trades show up under `"unknown"` instead of attributed to `firm_strategy`.
- Position-management lifecycle: the let-run gate (`rules.ts:99-103`) reads `strategyId` from `signals.source` JOIN, not from `simulated_orders.strategy_id`, so it still works. The TRENDING stale-exit override (`rules.ts:201-202`) reads `portfolio_regime_at_entry`, which fbdf1b3 added — also works. **However**, the ATR-based stale-progress math in `position-management/lifecycle.ts` reads `atrAtEntry` from `rowToPos()` (manager.ts:104). When NULL the progress check can't fire, so stale-exit falls back to time-only — losers stay open longer than intended. This is plausibly part of the bleed signature operator described, though not the whole story (let-run was correctly active for vol-exp).

## Fix scope decision (Phase 2)

This is "wire the field through to INSERT" — all data is already known at the call site, none of gate logic, sizing, BE-trigger, SL/TP, regime classifier, or signal routing is touched. CLAUDE.md "bug fixes that restore intended behaviour" exemption applies; no strategy/risk proposal needed.

## Patch

Commit `0ad348f` — `apps/worker/src/firm/strategy-execution.ts` only.

Added to both UPDATE branches (OANDA-filled and paper-only):
- `strategy_id = cfg.strategyId` (one of the 4: `xau-orb`, `xau-scalp-overlap`, `xau-session-breakout`, `xau-volatility-expansion`)
- `execution_source = 'firm_strategy'` (new sentinel, distinct from `firm_blade` and `oanda_backfill`)
- `atr_at_entry = proposal.state.atr ?? proposal.state.atr14` (scalp-overlap and session-breakout publish `atr` via `...signal` spread; vol-expansion publishes `atr14`; ORB carries none so it stays NULL there)
- `entry_conviction_score = proposal.confidence` (0-1 scaled, same convention managers.ts:944 uses for `total_conviction_score`)

Type-check `apps/worker` clean. Existing strategy-execution tests all pass (5/5).

## Verification SQL (run after deploy)

Operator should run this 60 minutes after Railway picks up the deploy (assuming at least one TIER 3 trade fires in that window):

```sql
SELECT execution_source, COUNT(*),
       COUNT(*) FILTER (WHERE strategy_id IS NOT NULL) AS has_strategy_id,
       COUNT(*) FILTER (WHERE atr_at_entry IS NOT NULL) AS has_atr,
       COUNT(*) FILTER (WHERE entry_conviction_score IS NOT NULL) AS has_conviction,
       MIN(opened_at), MAX(opened_at)
FROM simulated_orders
WHERE opened_at > NOW() - INTERVAL '2 hours'
GROUP BY execution_source ORDER BY 2 DESC;
```

Expect: a new `firm_strategy` row in the breakdown, with `has_strategy_id` and `has_conviction` equal to count, `has_atr` = count for non-ORB strategies.

Sanity check per-strategy:

```sql
SELECT strategy_id, COUNT(*),
       AVG(atr_at_entry) AS avg_atr,
       AVG(entry_conviction_score) AS avg_conv
FROM simulated_orders
WHERE execution_source = 'firm_strategy'
GROUP BY strategy_id;
```

## Not in this fix (out-of-scope)

- Back-filling the 138 historical NULL rows. That requires a SQL migration + a heuristic to derive strategy from `signals.source` (already possible via the existing JOIN pattern in `position-management/manager.ts:122`). Worth a separate small migration commit before agent-bus retros become reliable.
- `entry_snapshot` JSONB enrichment (managers.ts writes a rich blob; strategy-execution doesn't). Lower priority — only postmortem reads it and it's defensive against missing fields.
- ORB has no ATR in its proposal state. To get `atr_at_entry` for ORB the manager would need to publish it. Tangential — flag for operator if per-ORB ATR analytics are desired.

## Next step

Operator: review + push (harness denies direct push from this thread).
