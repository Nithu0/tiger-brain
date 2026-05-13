# Nexus live snapshot — what the worker sees right now

**Right now**: 2026-05-13 09:20:25 UTC (London session, 1x liquidity)
**Headline**: Market RANGING, ADX 13.97 / ATR 6.58 / price $4692.41, **0 open positions**, last rejection 33s ago (`xau-mean-reversion: impulse_too_small 1.33 ATR < 1.5`). Risk level **HIGH** — 30d rolling DD 13.19% > 10% scale-down threshold. Loop healthy: cycle #77, heartbeat 25s, broker OK ($89,245 demo balance).

## Health (api-production-b660 `/health`)

| Field | Value |
|---|---|
| status | ok |
| build | `5c07156d` |
| db | ok (44ms) |
| broker | demo OK (77ms), balance $89,245.47 |
| blackboard | lastMarketRaw 33s, lastDecision **56,135s** (~15.6h — last sim trade closed yesterday 19:57Z) |
| worker | heartbeat 25s, cycle #77, lastCycleDurationMs 9,946 |
| reconciliation | 0 drift, balanceDelta +13.63, last sync 2026-05-12T19:57Z |

## Portfolio context (latest, 09:19:52Z)

- regime: **RANGING**, volatility normal, tradeability fair
- regimeDirection: **null** (reason: `not_trending`)
- preGate: `PASS_TO_BLADE`
- enabled managers: `range_reversion` (score 72), `scalping` (60)
- disabled: `trend_macro`, `momentum_breakout` (score 0)
- experimental 30, bestManager `range_reversion`, fakeoutRisk 0.5, noTradeBias 0

## Technicals (technical-analyst, 09:19:52Z)

ADX **13.97** (well below trend-following 22 / pullback 20 gates) | ATR **6.575** | RSI 40.39 | MACD -2.11 (signal -1.19, hist -0.92) | EMA20 4700.84 / EMA50 4702.59 | BB 4691.86 / 4701.82 / 4711.79 | Stoch %K 1.66 / %D 15.48 | bias **NEUTRAL**.

Cross-asset (market.raw): SPY 738.20, TLT 84.98, USO 144.36, EURUSD 1.16986, Silver 86.25.

## Risk (radar, 09:19:52Z)

- riskLevel: **HIGH**
- dailyPnL: -$1,195.92 (1.34% DD, no daily breach)
- rolling30dDD: **13.19% — exceeds 10% — scale down** (breach=true)
- session: london, blackout false
- warnings: 30d rolling DD breach

## Open positions

**None.** Last 24h closed: 4 losers totaling -$1,195.92 (3x OANDA_SL_TP shorts on `xau-session-breakout` / `xau-volatility-expansion`, plus 1 STALE_TRADE_EXIT import). All closed before 19:57Z yesterday.

## Last 5 signal rejections (xauusd.signal.rejected)

| Time (UTC) | Strategy | Reason |
|---|---|---|
| 09:19:51.930 | xau-mean-reversion | impulse_too_small: 1.33 ATR < 1.5 |
| 09:19:51.609 | xau-pullback-continuation | adx_too_low: 15.1 < 20 |
| 09:19:51.098 | xau-breakout-continuation | no_clean_breakout |
| 09:19:50.873 | xau-trend-following | adx_too_low: 15.1 < 22 |
| 09:19:50.438 | xau-volatility-expansion | ATR ratio 0.65 < 1.3 |

## Last 30m rejection top reasons

- `no_clean_breakout` (breakout-continuation) × 27
- `ATR ratio < 1.3` (vol-expansion) × 27 combined
- `adx_too_low` (trend-following + pullback) × 53 combined
- `impulse_too_small` (mean-reversion) × 16
- `rsi_not_overbought` (mean-reversion) × 5

Every strategy is in NO-FIRE state — ADX/ATR/impulse all below their respective floors. Consistent with RANGING + low-vol regime.

## Agent activity (last 30m, by last-seen)

All 13 core agents heartbeating within 10s of cycle close: narrative, portfolio-brain, radar, macro-analyst, technical-analyst, signal-rejection-log (135 events — high because every strategy rejects every cycle), 6 strategy managers × 27 evals, herald, ingest (54 raw ticks), calendar, macro-regime, sentinel. risk-advisor last 09:15:12Z (5 events / 30m — lower cadence by design). market-research last 09:17:31Z.

## Anomalies / notes

- `/health.lastDecisionSec` = 56,135s. No accepted decision in ~15.6h. Consistent with RANGING + ADX 13.97 + scale-down risk gate — system is correctly *not* trading, but worth flagging vs. tomorrow's expectations.
- Rolling 30d DD breach (13.19%) is the dominant risk signal; would force size reduction even if a setup did fire.
- Yesterday's 4 losers (all shorts, all SL hit) ran on `xau-session-breakout` + `xau-volatility-expansion` during London → NY — those strategies are currently gated off by the ADX/ATR floors.
- No `xauusd.market.regime` topic seen in 15m window — regime info is embedded in `portfolio.context`.

Source: live DB query + `/health` curl at 09:20:25Z.
