# Data-integrity verification — post rapid-change week

Date: 2026-06-07 (Sunday, market CLOSED / WEEKEND — see caveat).
Source: live pull over 443 (`bash pull-nexus-data.sh` + extra curls). READ-ONLY.
Build serving API: commit `2b2d2cef`. Broker: demo, balance 90058.74 EUR, openTrades 0.

## VERDICT: CLEAN on core integrity. One open caveat (backfill not finished) + one cosmetic flaw (degenerate stops). No corruption.

---

## 1. Core integrity checks (recent ~20 + full 30d journal, 57 closed trades)

- **size==0 / NULL: NONE.** 199-row `/analytics/export` and 57-row `/journal/trades`: zero size-0, zero empty, zero NULL. The size=0 backfill held on the live insert path — newest firm trade (2026-06-05 12:54, session-breakout) has size=10, not 0.
- **Negative size: NONE.**
- **Duplicate trade ids: NONE** (199 unique ids in export).
- **Impossible prices: NONE.** Entries 4420–4811 range, consistent with XAUUSD.
- **All rows status=closed**, openTrades=0 confirmed by `/health`, `/operator/status`, `/firm/risk-snapshot`. No orphaned open positions.

## 2. risk_level_at_entry + regime_at_entry population (the backfill question)

This is the nuanced part. Two distinct trade populations in the data:

- **Firm-originated (`executionSource=firm_strategy`)** — the live trade-decision path. Only 3 in the visible window: session-breakout x2, vol-expansion x1. These have `regimeAtEntry`, `portfolioRegimeAtEntry`, `riskLevelAtEntry`, `atrAtEntry`, `entryConvictionScore` all **populated** (e.g. regime=normal, portfolioRegime=RANGING, riskLevel=normal). The live path writes the risk/regime metadata correctly.
- **OANDA-mirror (`executionSource=oanda_import:* / oanda_backfill:*`, "blade_match")** — externally-filled OANDA trades attributed post-hoc to a strategy. These have `regimeAtEntry=NULL` by design (no firm decision-cycle behind them). 43/57 journal rows are NULL-regime; all of them are mirror rows. **This is clean/expected, not corruption.**

**`original_risk_points` backfill (PR#69-adjacent) is NOT complete.** `/diagnostic/backfill-original-risk-points/status` → `remainingNull: 24, stillBackfillable: 24, unfixableSkippable: 0, done: false`. 31/57 journal rows still have `originalRiskPoints=null`. The backfill ran but has 24 rows left and is reported `done:false`. **Action: re-run / let the backfill finish — it has not converged.** (All 24 are stillBackfillable, none degenerate-unfixable, so it should complete cleanly.)

## 3. Strategy attribution — FVG + trend-following STOPPED on firm path (confirmed)

- **Zero FVG / trend-following trades originate from `firm_strategy`.** Cross-checked every FVG/trend row in `/positions` and 72h `executionSources`: all are `oanda_import:xau-fvg:blade_match_*` / `oanda_import:xau-trend-following:*` / one `oanda_backfill`. They appear only as OANDA-side fills the mirror attributes to those strategy labels — NOT new firm entries.
- The only `firm_strategy` entries are session-breakout (x2) and vol-expansion (x1) — all enabled strategies. Disable took.
- No orphaned open positions (openTrades=0).

## 4. Breaker / risk-gate effect — effectively PRE-ACTIVATION on firm path

- `RISK_LEVEL_HARD_GATE_ENABLED` is `<unset>` (expected false) per runtime manifest — risk_level gate is soft-log only. 7d funnel: risk_level evaluated 21, hardRejected 0, wouldReject 2. `gateImpact`: if activated it would have blocked 2 winners (netPnl −2430.61) — so leaving it soft is currently correct.
- Big sizes (158, 114, 86) are all **xau-fvg OANDA-mirror** trades = externally-placed, NOT firm-sized → breaker/size-clamp cannot apply to them. No firm trade was clamped to ~80.
- Only **1 firm-originated entry since 2026-06-04** (session-breakout, size=10). Not enough firm-path volume to demonstrate the breaker clamping. No NEW hard losses or breaker-clamped firm trades since 06-04. All the hard-loss rows (pnl < −300) since 06-04 are OANDA-mirror (fvg/mean-reversion/trend), each R≈−1.0 (clean SL hits, not corruption).

## 5. Minor flaw (cosmetic, not corruption): degenerate stops on session-breakout

5 session-breakout rows have `entryPrice == stopLoss` (e.g. 2026-06-05 4420.57=4420.57), giving R≈0 and pnl≈0. This is a degenerate zero-risk stop (firm trade `originalRiskPoints=null`, stop placed at entry). Not data corruption — the row is internally consistent — but the session-breakout stop placement is producing zero-distance stops on some entries. Worth a Karri/strategy look (NOT a data-integrity issue; flagging for attribution accuracy since R/expectancy math divides by stop distance).

---

## Weekend / staleness caveat

Market CLOSED (session=WEEKEND, tradeAllowed=false). `/health` status=fail only because `worker.cyclesPerHour=1` / lastHeartbeat 1714s (cold-start + weekend low cadence) — db/broker/blackboard/reconciliation all ok, drift unresolved=0. Newest trade is Fri 2026-06-05 12:54. So the firm path has produced almost no new trades to stress-test the backfills/breaker live; verdict on the firm insert path rests on the 3 firm_strategy rows present, which are all clean. Re-verify mid-week once London/NY sessions add firm entries.

## TODO surfaced for operator
1. `original_risk_points` backfill incomplete (24 rows, done:false) — re-run / finish it.
2. session-breakout degenerate stops (entry==SL) — strategy review (Karri), not data.
