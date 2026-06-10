# Health + anomaly watch — post-flip safety check (2026-06-07)

**Author:** Claude (read/verify-only watch) · **Data:** 443 pull @ 2026-06-07 12:31 UTC + nexus-pg (read-only) · **Live commit:** 2b2d2ce

## Verdict

**System healthy since flip: YES** (with two cosmetic weekend-artifact health flags, no real damage, no rollback warranted).

The key de-risking fact: **the two trade-altering switches cannot actually move trade decisions yet**, regardless of whether the Railway flags are on:
- **Lesson injection:** 3 lessons in `agent_lessons`, all `status='proposed'`, **0 approved**. The injection consumer reads only `status='approved'`, and auto-promotion (`LESSON_AUTO_PROMOTE_ENABLED`) is built but default-OFF. → injection is inert; nothing reaches agent prompts.
- **Autotune (`CALIBRATION_MODE=SAFE_AUTO_APPLY`):** `calibration_log` has **zero rows since 2026-04-25**, all historical rows `applied=false / mode=RECOMMEND_ONLY`. No engine-multiplier firm_state keys exist. → no autotune has applied anything. Karri's ±20% / ≥30-sample bounds (PR #68) have never been exercised.

So the "autotune + injection together producing weird conviction" failure mode is **structurally not live** right now. Good place to be for a fail-and-learn watch.

## 1. Worker / health

- `/health` = **fail**, but driven entirely by `worker.ok=false` → `cyclesPerHour:1`, `lastCycleNo:4`. This is the **weekend cadence** (market closed → worker throttles) plus a cycle-counter reset consistent with a redeploy of 2b2d2ce. Heartbeat is **fresh** (`worker:heartbeat` updated 12:02 UTC, ~30 min before pull) and `lastError:null`.
- broker: **connected**, demo, OANDA practice, balance 90,058.74 EUR, latency 70-72ms.
- reconciliation: **clean** — driftCountUnresolved 0, balanceDelta 38.37.
- blackboard: market.raw fresh (~29 min), decisions stale 171k s = last Friday close (expected, weekend).
- Foundation: 24h report shows **RED** (ohlcv_candles + gate_decisions "0 writes last 24h"); the **72h report shows YELLOW** with both tables green. The RED is a weekend false-positive — those tables wrote within 72h, just paused over the closed market. Only genuine standing item: `reddit_posts` last write 2026-05-27 (10 days, pre-existing yellow, unrelated to flip).

## 2. Trade behaviour since activation

- Last trade opened **2026-06-05 12:54 UTC (Fri)**; none since → market closed all weekend. No new trades to evaluate for the flip yet — the real test is Monday's London/NY session.
- **No blowup / runaway / stuck state.** Sizing sane: last-window sizes 10-58 units (one 158-unit FVG short on 2026-06-01 pre-window). No martingale escalation. Circuit-breaker (PR #67 clamp) has no clamp events logged.
- `risk_events`: **none since 2026-06-04**. The NEWS_BLACKOUT in the snapshot is 2026-06-02; DAILY_LOSS criticals are all 2026-04-10 (historical).
- dailyLoss: 0 / 500 limit, status ok. drawdown currentDD 0; max 30d DD 5.49%.

## 3. Pre/post-flip pattern (per-strategy, since 2026-06-01)

| strategy | n | pnl | wr |
|---|---|---|---|
| xau-fvg | 11 | **-1202.90** | 0.45 |
| xau-trend-following | 1 | -310.09 | 0.00 |
| xau-session-breakout | 2 | +58.95 | 0.50 |
| xau-mean-reversion | 3 | +369.90 | 0.33 |
| xau-volatility-expansion | 1 | +2112.54 | 1.00 |

- 25-trade R-distribution: avgR **-0.443**, winRate **0.16**, expectancy -0.443 — poor, but this is the **pre-existing edge problem, not a flip-induced regression** (199-trade lifetime: PF 0.71, WR 37.7%, expectancy -50.15). Pattern is continuous with the baseline; no step-change at the flip date.
- **xau-fvg is the dominant live driver and is bleeding (-$1.2k/11 trades)** — note FVG wiring is Karri's WIP and is NOT part of the approved flip batch. Flag for Karri, not a rollback target.
- directionMix 7d balanced (8L/10S), no bias warning.

## 4. Flag-interaction bugs

None surfacing, because (per Verdict) the two trade-altering switches are inert (0 approved lessons, 0 calibration applies). risk_level gate: `gateImpact` says activating it would have cost -$2430 (blocked 2 winners, 0 losers) over 7d — correctly **not** hard-active (`RISK_LEVEL_HARD_GATE_ENABLED` expected false, soft-log only). No gate over-blocking: 7d funnel shows only mean_revert (4 rejects) + 1 sl_cooldown reject firing.

## Top 3 anomalies

1. **Health=fail + Foundation 24h=RED are weekend false-positives.** Worker throttled + counter reset over closed market; 72h view is YELLOW/green. Cosmetic — but worth confirming Monday that ohlcv_candles + gate_decisions resume writing once London opens. If they stay dead Monday, escalate (candle source / new-gates deploy).
2. **xau-fvg bleeding -$1.2k over 11 trades (WR 0.45, dominant driver).** Not in the approved flip batch (Karri WIP, unwired config). Route to Karri. Negative expectancy is a pre-flip standing problem, not flip-caused.
3. **No evidence the trade-altering flips are doing anything yet.** 0 approved lessons + 0 calibration applies. If the *intent* was continuous learning, it is currently a no-op until a lesson is approved (manual `!lesson approve` or `LESSON_AUTO_PROMOTE_ENABLED`) and calibration runs under SAFE_AUTO_APPLY. Report, operator/Karri decide.

## Rollback recommendation

**None.** No flag warrants rollback — system is stable, sizing sane, reconciliation clean, and the trade-altering switches are structurally inert (can't misbehave with 0 approved lessons / 0 calibration applies). REPORT-only per operator-prinsipp 1.

**Watch item, not a rollback:** re-run this check Monday after London open. The real post-flip behaviour test only begins when the market reopens and a lesson/calibration actually applies. If `xau-fvg` keeps bleeding once live trading resumes, that is a Karri strategy question, not an infra rollback.
