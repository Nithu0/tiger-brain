# Nexus — Monday post-open flip verification (2026-06-08)

**Pulled:** 2026-06-08 ~10:31Z (≈3.5h after London open 07:00Z). Channel: API/443 (`pull-nexus-data.sh`). DB MCP dead/firewalled — not used. Build live: `5fd39f9b`.

**Headline:** The "first real test" did NOT happen. Worker is cycling normally, but **zero trades have opened today** and — critically — **the risk/learning flags the premise says were flipped Friday read `<unset>` in the live runtime manifest**. Nothing risk-side could bite because (a) no trades to act on, and (b) the gates are not actually enabled in prod. Treat the "all flags flipped" premise as UNCONFIRMED / likely false against live state.

---

## 1. Worker cycling — LIVE-CONFIRMED healthy, NOT weekend-idle

- `/health`: status ok; db ok (4ms); broker ok demo, balance 90058.74; worker ok.
- `lastCycleNo: 323`, `cyclesPerHour: 55`, `lastCycleDurationMs: 3689`, `lastHeartbeatSec: 58`, `lastError: null`.
- Market data fresh: `xauusd.market.raw` age 59s, analysis/sentiment/ohlcv all green (last write ~10:30Z).
- Session: `LONDON_ACTIVE`, isPrimary true. Regime `HIGH_VOLATILITY`, enabled managers momentum_breakout/trend_macro/scalping.
- Decision-emitting topics (`manager.decisions`, `portfolio.exposure_check`, `event.policy`) last fired **09:50:12Z** → age ~41 min, flagged "bad" in freshness. That is NOT idle — it's because the firm keeps returning `WAIT_FOR_MORE_DATA` (no decision = no decision-topic write). Cycles themselves are running every ~65s.

**Verdict: cycling normally post-open. Not a weekend false-positive.**

---

## 2. RISK_LEVEL_HARD_GATE — STILL INERT (not enabled in prod)

- `runtimeManifest.RISK_LEVEL_HARD_GATE_ENABLED` = **`<unset>`** (expected `false`, anomaly false). The hard gate is **not turned on** in the live worker/API.
- Funnel gate is reported as `risk_level` (canonical name). Today (24h window): `evaluated:1, wouldReject:0, hardRejected:0`.
- 7-day window: `risk_level evaluated:19/21, hardRejected:0, wouldReject:1` → the gate is running in **shadow/would-reject (soft-log)** mode only. One historical would-reject; zero hard rejects ever.
- `gateImpact` (7d): `risk_level wouldHaveBlocked:1, winnersBlocked:1, losersBlocked:0, netPnlIfActivated:-2112.54` → had it been live it would have blocked a **winner**, costing PnL. (Same caution as before — don't activate on this evidence.)

**Verdict: NOT-YET-TRIGGERED and STILL-INERT. It is in shadow mode, not biting, and the enable flag is `<unset>` in prod. hard_rejected TODAY = 0.**

---

## 3. Circuit-breaker (300% notional / 80 units) — NOT-YET-TRIGGERED

- Code: `positionSizeCircuitBreaker` in `apps/worker/src/firm/strategy-execution.ts:986`. Default **ON** (`POSITION_SIZE_CIRCUIT_BREAKER_ENABLED=true`), `MAX_UNITS_PER_TRADE=80`, `MAX_NOTIONAL_PCT=300`. It **clamps** (not rejects) and fires only on the path of an actually-executing trade.
- **Zero trades executed today** → the clamp code path was never reached. No CLAMPED events possible.
- Largest notional today: N/A — no trades. Open positions: 0. Exposure: total 0.90%/4% cap (that 0.90% is the *prospective* sizing on the waited setup, not an open position).

**Verdict: NOT-YET-TRIGGERED. Cannot confirm live until a trade actually fires.**

---

## 4. New trades since open — NONE

- `openTrades:0`, `closedLast24h:0`, `pnlLast24h:0`, `dailyPnl:0`.
- Most recent trade in the system: **2026-06-05** (Friday) — `xau-session-breakout` short, pnl -0.17 (firm_strategy); plus Friday OANDA-import fills (xau-fvg +558.42, xau-mean-reversion -348.51 / -129.97, etc.). **Nothing on 2026-06-08.**
- Why no entries: every strategy state returns shouldTrade=false today —
  - breakout-continuation: `no_valid_range`
  - pullback-continuation: `pullback_too_deep 17.09 ATR > 2`
  - mean-reversion: `adx_too_high 45.5 > 25`
  - volatility-expansion: `ATR ratio 1.03 < 1.3`
  - session-breakout: `Range too wide ($84.97)`
  - trend-following: stale (`session_not_allowed: WEEKEND`, last eval Sat 06.6 — **this one looks stuck**, see anomalies)
  - Firm decision layer: `WAIT_FOR_MORE_DATA — entry score 33 < 37`.

**No sizing anomaly / blowup pattern to assess — nothing traded.** Baseline unchanged: avgR -0.443, winRate 0.16, 25 trades (rDistribution). maxDD30d 5.49%.

**Verdict: no new trades. PnL delta vs baseline = 0 (no activity).**

---

## 5. Autotune — STILL INERT (as expected, no-op)

- `calibrationMode: RECOMMEND_ONLY`, `autoApplyActive: false`, `multipliersNeutral: true`, all engineMultipliers = 1.0.
- Lessons: 3 proposed, 0 approved; `lessonsFlagEnabled:false`, `derivationFlagEnabled:false`, `injectionFlagEnabled:false`. Firehose: `lessons_last_7d: 0`.
- Recent calibration-log entries all `applied:false, mode:RECOMMEND_ONLY` (dated April).

**Verdict: STILL-INERT — recommend-only, neutral multipliers, injection OFF. Expected no-op, confirmed.**

---

## ANOMALIES / operator attention

1. **PREMISE MISMATCH — flags not actually enabled in prod (HIGH priority to confirm).**
   The premise is "operator flipped all learning/risk activation flags Friday." The live `runtimeManifest` says otherwise — all of these read `<unset>` (expected false, no anomaly):
   `RISK_LEVEL_HARD_GATE_ENABLED`, `SCALP_OVERLAP_ASIA_BLOCK`, `RANGING_CONVICTION_GATE_ENABLED`, `ENTRY_STACK_COOLDOWN_ENABLED`, `LEGACY_XAUUSD_EXECUTION_ENABLED`, `NEXUS_CIO_ENABLED`.
   `risk_snapshot.config` corroborates: `slCooldownEnabled:false`, `dailyTradeCapEnabled:false`.
   → Either the Friday flip targeted a different service (e.g. set on Worker but manifest is read where they're unset), didn't persist, or never happened. **Operator should confirm where the flips were applied.** As of now, on the API/worker the system is reading defaults, and only `NEW_GATES_SOFT_LOG_ENABLED=true` (shadow logging) is active — which is why gates show `wouldReject` but `hardRejected:0`.

2. **`trend-following` strategy state is stale** — last evaluated 2026-06-06 17:16Z with `session_not_allowed: WEEKEND`, age ~41h, while all other strategies evaluated ~59s ago. It looks frozen on a weekend reject and is not re-evaluating in LONDON_ACTIVE. Worth a worker-log check ([firm.trend-following]); not data-stopping but it means one strategy is effectively dark.

3. **Foundation YELLOW** — `reddit_posts` last write 2026-05-27 (11d stale). Recommended action OBSERVE. Blocks new-gate/new-strategy activation per foundation gate. (Known/expected — flagged for completeness.)

4. **`/firm-activity-feed` 404** and `/firehose/derive-status` 404, `/learning` 404 — these endpoints in the pull script no longer exist on build 5fd39f9b. Cosmetic for this audit (covered by other endpoints) but the pull script should drop/rename them.

---

## Per-mechanism summary

| Mechanism | Status | Today's evidence |
|---|---|---|
| Worker cycling | LIVE-CONFIRMED healthy | cycle 323, 55/hr, heartbeat 58s, market data 59s |
| RISK_LEVEL_HARD_GATE | STILL-INERT (shadow only; flag `<unset>`) | hardRejected today 0; 7d hardRejected 0, wouldReject 1 |
| Circuit-breaker (300%/80u) | NOT-YET-TRIGGERED | 0 trades → clamp path never reached |
| New trades / sizing | NONE | openTrades 0, closedLast24h 0, last trade 06-05 |
| Autotune | STILL-INERT (RECOMMEND_ONLY) | autoApply false, multipliers neutral, injection off |

**Bottom line:** Monday open produced no entries (all strategies + firm gate waiting on thresholds in a HIGH_VOLATILITY/wide-range tape). The risk/learning mechanisms could not be exercised — and more importantly the activation flags appear to NOT be set in the live runtime. The "first real test" is still pending. Re-pull on next genuine entry to capture the first live clamp/hard-gate evaluation.
