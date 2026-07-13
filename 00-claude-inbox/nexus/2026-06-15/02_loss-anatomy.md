# Loss anatomy — worst recent XAUUSD losers (post 2026-05-25)

Generated 2026-06-15. READ-ONLY analysis. Source: `data/pull/export.json` (trade ledger, through 2026-06-09) enriched with `data/pull/journal_trades.json` (postmortems, through 2026-06-05). No fresh pull — no API token in session (401); worked from the existing pull snapshot. Guard logic read from live code on branch `fix/firehose-script-path`.

Caveat: journal snapshot ends 2026-06-05, so the two newest losers (`*_1552`, `*_1560`, 2026-06-09) have no strategy/regime/postmortem tags. Live equity for clamp math = **~$89.8k** (OANDA-source, `risk_snapshot.json`), not the $10k demo constant — `USE_OANDA_BALANCE` is evidently true in prod.

---

## TL;DR

- **Dominant loss mechanism: clean full-stop-out -1R losses from low-conviction directional entries that were simply WRONG on direction.** 11 of 13 enriched losers closed at `OANDA_SL_TP` for almost exactly -1.0R with postmortem `WRONG_THESIS`. The stops *worked*; the *thesis* was wrong. This is a SELECTION problem (entering trades that shouldn't be entered), not a sizing or stop-management problem.
- **Oversizing is the secondary, not primary, mechanism.** Only **3 of the top 15** were "monster" sizes (86/114/158 units vs median 26). Those 3 are exactly what the now-live circuit-breaker was built for and would now be clamped. The other 12 losers were 16–58 units — **under** the current ~59–60-unit cap — and would pass through untouched.
- **Do current guards catch the bleed? PARTIAL → mostly NO.** The circuit-breaker (live, ON) catches the 3 monsters and shaves ~$864 (16%) off the top-15 loss total. It does nothing for the 12 normal-sized -1R thesis losses, which are the bulk of the bleed. The regime-direction and mean-revert gates are **OFF by default** and, even if flipped ON, would not have blocked these (see §3).

---

## 1. The 15 worst losers (post 2026-05-25)

R = resultR from journal. "$risk@SL" = stop-distance-points × size (≈ USD on XAUUSD). All hit stop at ~ -1R unless noted.

| # | ID (tail) | Date (UTC) | Strategy | Dir | Size | Stop pts | %stop | $risk@SL | PnL | R | Close reason | Postmortem |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | _1447 | 06-03 00:45 | xau-fvg | long | **114** | 7.9 | 0.18% | $902 | **-787** | -1.01 | OANDA_SL_TP | WRONG_THESIS |
| 2 | _1441 | 06-02 15:03 | xau-fvg | long | **86** | 8.4 | 0.19% | $725 | **-631** | -1.00 | OANDA_SL_TP | WRONG_THESIS |
| 3 | _1391 | 06-01 00:13 | xau-fvg | short | **158** | 3.1 | 0.07% | $492 | -456 | -1.07 | OANDA_EXTERNAL | EXTERNAL_CLOSE |
| 4 | _1383 | 05-29 11:42 | xau-trend-following | long | 36 | 13.8 | 0.31% | $498 | -451 | -1.04 | OANDA_SL_TP | WRONG_THESIS |
| 5 | _1435 | 06-02 12:57 | xau-fvg | long | 26 | 17.2 | 0.38% | $448 | -433 | -1.11 | OANDA_SL_TP | WRONG_THESIS |
| 6 | _1371 | 05-28 02:09 | xau-mean-reversion | long | 46 | 10.5 | 0.24% | $482 | -425 | -1.01 | OANDA_SL_TP | WRONG_THESIS |
| 7 | _1379 | 05-29 11:12 | xau-trend-following | long | 37 | 12.5 | 0.28% | $463 | -403 | -1.00 | OANDA_SL_TP | WRONG_THESIS |
| 8 | _1504 | 06-05 03:38 | xau-mean-reversion | long | 58 | 6.8 | 0.15% | $395 | -349 | -1.01 | OANDA_SL_TP | WRONG_THESIS |
| 9 | _1365 | 05-27 10:33 | xau-mean-reversion | long | 58 | 6.6 | 0.15% | $385 | -342 | -1.03 | OANDA_SL_TP | WRONG_THESIS |
| 10 | _1453 | 06-03 09:06 | xau-trend-following | short | 40 | 8.9 | 0.20% | $355 | -310 | -1.00 | OANDA_SL_TP | WRONG_THESIS |
| 11 | _1552 | 06-09 03:38 | (no tag) | short | 31 | 6.5 | 0.15% | $201 | -197 | ? | ? | ? |
| 12 | _1560 | 06-09 14:16 | (no tag) | long | 51 | — | — | — | -173 | ? | OANDA backfill (no SL/TP recorded) | ? |
| 13 | _1496 | 06-05 02:31 | xau-mean-reversion | long | 47 | — | — | — | -130 | ? | OANDA_EXTERNAL | EXTERNAL_CLOSE |
| 14 | _1484 | 06-04 08:42 | xau-fvg | short | 22 | 20.6 | 0.46% | $454 | -101 | -0.26 | STALE_TRADE_EXIT | RIGHT_THESIS_BAD_EXECUTION |
| 15 | _1468 | 06-04 01:28 | xau-fvg | short | 16 | 27.6 | 0.62% | $441 | -33 | -0.09 | STALE_TRADE_EXIT | RIGHT_THESIS_BAD_EXECUTION |

Note: `regimeAtEntry` and `sessionAtEntry` came back **null** for every enriched loser — the regime classifier is not labelling at entry (see §3, this is load-bearing). `entryConvictionScore` clustered at **0.5 (fvg) / 0.6 (mean-rev) / 0.7 (trend)** — i.e. all near the minimum bar to fire.

Strategy tally (top 15): **xau-fvg 6, xau-mean-reversion 4, xau-trend-following 3, untagged 2.** FVG is the single biggest contributor and owns both of the two largest losses.

---

## 2. Classification

| Pattern | Count | Trades |
|---|---|---|
| **WRONG_THESIS, clean -1R stop-out** (direction was wrong, stop did its job) | **9** | 1,2,4,5,6,7,8,9,10 |
| Oversized "monster" (>2× median, would now clamp) | 3 | 1,2,3 (overlaps WRONG_THESIS) |
| External/manual close (OANDA_EXTERNAL — not our exit logic) | 2 | 3,13 |
| RIGHT_THESIS_BAD_EXECUTION / stale-exit (idea OK, timing/management off) | 2 | 14,15 |
| Backfill w/o recorded SL/TP (data-quality, not a strategy loss per se) | 1 | 12 |

Notable non-findings:
- **Not stop-too-tight / structural.** Stops ranged 0.07%–0.62% of price; the -1R losers averaged ~0.2–0.3%. Widening would only inflate $-loss (martingale — refused by principle).
- **Not held-through-reversal.** These are mostly fast `OANDA_SL_TP` hits (hold-times short), not winners given back.
- **Not chaos-regime** in any detectable way — regime wasn't even recorded (null).
- **Counter-trend?** Likely yes for several (all those LONGs into a falling gold tape late May / early June), but **unprovable from the data** because regime/direction was null at entry. This is itself the core diagnostic gap.

---

## 3. Would the NOW-LIVE guards have prevented these?

### Circuit-breaker (80u / 300% notional) — LIVE, default-ON (`2e5cdbf`, 2026-06-04, Karri-approved)
`POSITION_SIZE_CIRCUIT_BREAKER_ENABLED=true` default. Clamps (not rejects) to `min(MAX_UNITS_PER_TRADE=80, floor(3.0×equity/entry))`. At ~$89.8k equity, entry ~4493 → **cap ≈ 59 units.**

- **Catches 3/15** (the 86/114/158-unit trades → clamped to ~59). Top loss -787 would have been ~-407.
- **Misses 12/15** — they were already ≤58 units, under the cap. Pass through unchanged.
- Aggregate: clamping the 3 monsters shaves ~**$864 off the -$5,221 top-15 total (~16%)**. Real but partial.
- Verdict: **PARTIAL.** It's a genuine tail-risk brake (the proposal explicitly targeted "100–446-unit monsters" and it works on those), but it does **not** address the dominant -1R thesis bleed.
- Note: it caps **units/notional, not $-risk-at-stop.** Several sub-cap losers still carried $385–$498 risk-at-SL (≈0.5% of balance). A per-trade $-risk cap lives in a *separate* exposure module (`maxRiskPerTradePct=0.75%`) that the strategy-execution sizing path does **not** appear to call — worth confirming as a follow-up; if true, there is no live per-trade dollar-risk ceiling on this path.

### Regime-direction gate — default OFF (`REGIME_DIRECTION_GATE_ENABLED=false`)
- Only ever *blocks* the 4 mean-reversion-family strategies; `xau-fvg` and `xau-trend-following` (9 of our 15) are never in scope.
- `xau-mean-reversion` was only added to the block-list on **2026-06-11** (`f687c70`) — after every trade here.
- **Fails OPEN on null regime**, and regime was null on all these entries (classifier emits null ~98% of TRENDING cycles per in-code note). So even flipped ON, it would have allowed essentially all of them.
- Verdict: **NO.**

### Mean-revert block gate — default OFF (`MEAN_REVERT_GATE_ENABLED=false`)
- Runs on all strategies; blocks an entry that *aligns* with a ≥2.0-ATR recent impulse (buying into a spike). It's the only gate with a realistic shot at the trend-following / FVG "bought the rip then reversed" losers.
- OFF in prod; impulse data not in the journal so can't confirm hit-rate. Best case it catches a subset of the continuation-chasing FVG longs.
- Verdict: **NO (off); PARTIAL at best if enabled.**

### ATR / vol thresholds — `ATR_PCT_THRESHOLDS_ENABLED=false` (still absolute-$ mode)
- Not a per-trade entry block; it's regime/risk classification. Because gold is ~$4.2k, the absolute thresholds misfire (the file's own header notes this gated the firm to 0 trades over 3 days). It contributes to the *null/garbage regime labels* feeding the dead regime-direction gate — i.e. it makes the diagnostic gap worse, it doesn't catch losses.
- Verdict: **NO.**

**Net: the bleed is mostly a pattern no current guard addresses.** Guards catch the size-tail (3 trades, ~16% of $) but not the mechanism (low-conviction wrong-direction entries clearing the entry bar at conviction 0.5–0.7).

---

## 4. The #1 recurring loss mechanism

**Low-conviction directional entries (conviction 0.5–0.7, right at the firing threshold) that are simply wrong on direction, taken with no working regime/trend context, and stopped out cleanly at -1R.** FVG longs into a falling tape are the worst single cluster.

The decisive enabler is the **dead regime pipeline**: `regimeAtEntry` is null on every loser, the classifier emits null ~98% of the time, and the one gate that would block counter-trend entries fails-open on null. So the firm is entering directional trades essentially blind to trend, and the stop is the *only* thing working as designed. The system isn't losing because stops are bad or size is bad (size matters for 3 tail trades); it's losing because it keeps taking marginal entries on the wrong side with no trend filter live.

Highest-leverage fixes (all need Karri sign-off — they alter trade selection):
1. **Fix the regime classifier's null rate** (or make the regime-direction gate fail-CLOSED on null in TRENDING). This is the root: without it, no direction gate can ever work.
2. **Raise the conviction floor** for FVG/trend entries above 0.5–0.7, or require trend-alignment for FVG.
3. Enabling the mean-revert gate would help the "chased the spike" subset — cheap to shadow-test first.
The circuit-breaker is doing its (narrow) job; don't expect it to stop the bleed.

---

## Top-3 worst trades — one-line cause

1. **`_1447` (-787, 06-03, xau-fvg long, 114u):** oversized FVG long on a wrong directional thesis, stopped at -1R; the 114-unit size (now would clamp to ~59) turned a normal -1R into the single biggest loss.
2. **`_1441` (-631, 06-02, xau-fvg long, 86u):** same mechanism — oversized FVG long, WRONG_THESIS, clean stop-out; would now clamp to ~59u.
3. **`_1383` (-451, 05-29, xau-trend-following long, 36u):** *normal-sized* trend-following long, WRONG_THESIS, -1R stop-out — the representative case of the real bleed: no oversizing, no guard catches it, just a wrong-direction entry with the stop doing all the work.
