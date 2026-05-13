---
title: Position-management lifecycle (BE / trailing / stale-exit / metadata)
source: Nexus codebase + docs/ref/position-metadata + Karri's pending BE proposal
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, concept, position-management, lifecycle, break-even, stale-exit]
status: distilled
---

# Position-management lifecycle

Once a trade is open, **position-management owns the exit.** Strategies pick entry, SL and TP at fill; from that point onward `apps/worker/src/firm/position-management/` controls every mutation — break-even, partial-take, trailing, stale-exit, conviction-degradation. Strategies do not re-touch open positions.

## What it does (per cycle, before raw SL/TP scan)

`manageFirmPositions` runs every orchestrator cycle. For each open row in `simulated_orders`:

1. **Update favourable peak** (`peak_price`) — always safe, drives trailing.
2. **Break-even** — when R-multiple ≥ `BREAK_EVEN_RULES.triggerRmult` (=1.0), move SL to `entry ± 0.20 buffer`. Flips `break_even_applied=true`.
3. **Partial TPs** (skipped for "let-run" strategies like `xau-volatility-expansion`) — TP1 = 50% of original size at +1R, TP2 = 25% at +2R. Each books `realized_partial_pnl`.
4. **Trailing** (also skipped for let-run) — only after +1R, distance = `ATR_at_entry × multByRegime` (2.0 trending, 1.5 default, 1.0 ranging). Never loosens the stop (`isBetterStop`).
5. **Stale-exit** — full close if `age > maxAge` AND `|progress| < minProgress × ATR`. Exempt after break-even or TP1.
6. **Conviction degradation** — full exit on opposite-sign flip; one-shot 50% cut when magnitude drops below 60% of entry.

Every broker mutation is **OANDA-first, DB-second**. On OANDA failure the corresponding fields are stripped from the decision so DB never claims a change that didn't land; the evaluator re-proposes next cycle.

## Break-even rule (current vs proposed)

Currently per-strategy via the let-run gate. BE itself is **always on at +1R** (with 0.20-point buffer) — for let-run strategies it's the *only* protection since partials/trailing are skipped. Karri's pending proposal `2026-05-12_vol_exp_break_even_on_1r.md` formalises the same trigger as a vol-exp-specific env flag — backtest evidence: 12.5 trades #1135/#1139 would have closed at $0 instead of −$777 with BE active. Status: pending Karri.

## Regime-aware stale-exit

`resolveStaleConfig` reads `xauusd.portfolio.context.regime`. Trending / breakout regimes get a looser profile (150 min ceiling, 0.15 × ATR progress) vs the default 90 min / 0.30 × ATR. Motivation: 46% of `xau-htf-trend` closes were `STALE_TRADE_EXIT` averaging only +$0.39 — we were cutting trending winners early. Env-tunable via `STALE_EXIT_TRENDING_MINUTES` / `STALE_EXIT_TRENDING_PROGRESS_ATR`.

## Trade metadata stamped at entry

`executionManager` writes runtime observability fields to `simulated_orders` at fill: `decision_cycle_id`, `portfolio_regime_at_entry`, `risk_level_at_entry`, `thesis_quality_score`, `conviction_total/direction/timing`, `execution_source`, `session_high_at_entry`, `session_low_at_entry`, `range_percentile_at_entry`. Critical for lifecycle: `atr_at_entry`, `regime_at_entry`, `session_at_entry`, `entry_conviction_score`, `original_risk_points` — without `original_risk_points` frozen at entry, rMultiple explodes after BE moves SL to entry. **Session-breakout had `atr_at_entry=NULL` until A3 fix (see `2026-05-13_session_breakout_sl_method.md`)** — broke ATR-vs-WR analysis on live data.

## R-multiple tracking

`riskPoints()` uses frozen `originalRiskPoints` (not current `entry − stopLoss`, which collapses to 0 after BE). MFE/MAE are tracked via `peak_price` + the events stream. `management_events` JSONB appends every BE/PARTIAL/TRAIL/STALE/FLIP event for postmortem classifier replay.

## Foundation-gate dependency

`POSITION_MANAGEMENT_ENABLED` (default `true`) must be on for foundation-gate green. When off, manager runs in shadow mode (logs WOULD-decisions, no mutations). The flag is the operator's kill-switch for sustained broker-side failures; verified post-deploy by 3 trades carrying full metadata stamps.

## Anti-patterns

- Closing trades via direct DB writes — kills lifecycle hooks + OANDA stays open (drift).
- Modifying SL/TP after open outside the lifecycle — manager will overwrite with its own `newStop` next cycle.
- Reading `pos.stopLoss` as risk — always use `originalRiskPoints`.
- Trusting `entryConvictionScore=null` rows as low-conviction (they're just missing metadata).

## Cross-references

- **Van Tharp's R-multiple** — every position carries `R = (price − entry) / originalRiskPoints`. Mirrors Tharp's expectancy-as-R framework.
- **Connors's "break-even after impulse"** — the +1R BE trigger is the canonical Connors rule: once trade pays for itself, you can't lose on it.
- **Crabel's "exit before reversal"** — `STALE_TRADE_EXIT` and `CONVICTION_FLIP_EXIT` implement Crabel's intraday-momentum principle: if the thesis ages without progress, get out before the mean-reversion crowd arrives.
