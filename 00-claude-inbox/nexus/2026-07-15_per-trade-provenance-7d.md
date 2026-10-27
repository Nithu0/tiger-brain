# Per-trade provenance — closed trades, last 7 days (2026-07-08 → 2026-07-15)

Read-only pull from prod Postgres (railway, `simulated_orders` + `engine_scores` + `calibration_log` + `firm_state`). Filters: `status='closed'`, `excluded_from_learning IS NOT TRUE`, firm-originated UUIDs only (no `oanda_backfill_%`/`oanda_import_%`). Window had **10 trades** — no need to extend to 14 days.

## Trades

| # | Closed (UTC) | Dir | Strategy | Vol regime @entry | Portfolio regime @entry | Close reason | R | Net PnL ($) | Size | Conv. score | Engine scores @open |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 07-09 04:36 | long | mean-reversion | — | — | OANDA_SL_TP | +0.16 | +73.64 | 50 | 0.60 | yes (3: intermarket, macro, structure) |
| 2 | 07-10 07:54 | long | mean-reversion | elevated | MIXED_NO_EDGE | OANDA_SL_TP | — | +72.52 | 63 | 0.60 | yes (5 engines) |
| 3 | 07-10 08:49 | long | mean-reversion | normal | MIXED_NO_EDGE | OANDA_SL_TP | — | **−242.09** | 63 | 0.60 | yes (5 engines) |
| 4 | 07-10 12:03 | long | mean-reversion | normal | MIXED_NO_EDGE | OANDA_SL_TP | — | +34.37 | 63 | 0.60 | yes (5 engines) |
| 5 | 07-10 13:39 | short | session-breakout | normal | MIXED_NO_EDGE | CONVICTION_FLIP_EXIT | −0.28 | **−104.11** | 16 | 0.60 | yes (5 engines) |
| 6 | 07-10 14:37 | long | mean-reversion | normal | MIXED_NO_EDGE | OANDA_SL_TP | — | +132.41 | 47 | 0.60 | yes (5 engines) |
| 7 | 07-10 17:28 | short | volatility-expansion | normal | TRENDING | STALE_TRADE_EXIT | +0.33 (*) | −24.05 | 35 | 0.80 | yes (5 engines) |
| 8 | 07-13 14:12 | short | session-breakout | normal | MIXED_NO_EDGE | OANDA_SL_TP | −0.00 | −0.62 | 10 | 0.60 | yes (5 engines) |
| 9 | 07-15 02:12 | long | mean-reversion | — | — | OANDA_SL_TP | — | +231.56 | 64 | 0.60 | yes (3: intermarket, macro, structure) |
| 10 | 07-15 03:41 | long | mean-reversion | — | — | OANDA_SL_TP | — | +51.81 | 63 | 0.60 | yes (3: intermarket, macro, structure) |

Net PnL = `pnl + COALESCE(realized_partial_pnl,0)`. Full trade IDs (order as above): `384167bb`, `59287174`, `b7dc6929`, `e6bd7f49`, `ec66d49e`, `11d972b4`, `1606def7`, `8515d98c`, `67067329`, `f8d7293e`.

**Totals: 10 trades, 6W / 4L by net PnL, net +$225.44.** Losses concentrated on 07-10 (3 of 4). Biggest loser (#3, −$242) and biggest winner (#9, +$232) are both mean-reversion longs at near-identical size (63/64).

5-engine cycles ran intermarket + macro + momentum + structure + technical; the 3-engine cycles (#1, #9, #10 — all Asian-session opens) lacked momentum + technical scores.

## Multiplier / SAFE_AUTO_APPLY check

- `firm_state` key `engine_multipliers:current` (updated 07-15 11:45 UTC): **all 7 multipliers = 1.0**, `mode: RECOMMEND_ONLY`.
- `calibration_log`, last 14 days: **every row `applied = false`, mode `RECOMMEND_ONLY`**. Recommendations exist (technical ≈0.954, structure ≈0.97, momentum ≈0.99, plus marketThesisThreshold 60→58/63 for NY_CONTINUATION) but none were applied.
- Last `applied = true` calibration ever: **2026-06-26** — well before this window (374 applied rows historically, 0 in the last 14 days).
- `entry_snapshot` is **NULL on all 10 trades**, so no per-trade multiplier evidence there either. `original_size` NULL on all rows (no size mutation recorded).
- Size variation (10–64 units) tracks stop distance (inverse sizing), not conviction: `entry_conviction_score` is flat 0.60 on 9/10 trades, 0.80 only on the vol-expansion trade (#7).

## Data-quality notes

- `result_r` populated on only 4/10 trades; missing on all plain OANDA_SL_TP mean-reversion closes except #1.
- (*) Trade #7 has `result_r = +0.33` but net PnL −$24.05 — sign/definition mismatch worth a look (possibly R computed pre-costs or off partial fills).
- `regime_at_entry` and `portfolio_regime_at_entry` NULL on the three Asian-session trades (#1, #9, #10) — same trades that only got 3 engine scores. Looks like a reduced overnight cycle path.
- `entry_snapshot` capture appears dead in this window (0/10 non-null) despite the column existing.

## Answer to thesis-2's question

No. SAFE_AUTO_APPLY / engine multipliers did **not** move sizing on the losers (or on any trade) in this window. The calibration loop is running in RECOMMEND_ONLY: it produced small deflation recommendations (technical 0.954, structure 0.97) but wrote them with `applied=false`, and the live multiplier state is 1.0 across all engines. Nothing has been auto-applied since 2026-06-26. The losers (#3, #5, #7, #8) were sized by the same stop-distance rule as the winners, at the same flat 0.60 conviction — so this week's PnL spread is entry/exit quality, not sizing modulation.
