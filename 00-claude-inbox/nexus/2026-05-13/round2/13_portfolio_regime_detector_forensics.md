# Portfolio-regime detector — forensic verification

**Date:** 2026-05-13
**Anchor:** 11.5 — 9 trades, 8 SHORT on a +86 USD uptrend day, all 4 strategies fired SHORT into impulse legs
**Scope:** trustworthiness of `portfolio_regime_at_entry` (TRENDING/RANGING) and its companion `regimeDirection`

---

## Verdict

- **Trustworthy as a *base-regime* classifier?** Yes — ADX 32–47 on 11.5 across all entries is consistent with "TRENDING". Base label is mechanically correct.
- **Trustworthy as a *direction signal*?** **NO. Completely broken on 11.5.**
- **Most likely failure mode:** *direction signal silently null on 97.7% of TRENDING messages* — `regime-direction-gate` is short-circuited to "allow" before any directional check, so SHORT-into-uptrend trades pass.
- **Highest-leverage observability addition:** **log+persist `regime_direction_classify_outcome` (one of: ok_up / ok_down / null_flat / candles_empty / candles_too_short / fetch_error)** every call in `portfolio-brain.classifyTrendDirection`. Today the function returns `null` for ≥5 distinct reasons and the cause is invisible.

---

## How the detector works (verified)

`apps/worker/src/firm/portfolio-brain.ts::classifyRegime` (runs **every cycle** — orchestrator.ts:511):

1. Reads `xauusd.analysis.technical` from blackboard (max staleness 300s).
2. Pulls `adx` from `state.indicators` — that ADX is computed on **15-min candles only** (`apps/worker/src/engines/technical-advanced.engine.ts:55` → `fetchADX(symbol, "15min")`).
3. Decision ladder:
   - blackout → EVENT_DRIVEN
   - ATR>12 → NOISY_CHAOTIC
   - **ADX > 30 → TRENDING** ← used 11.5
   - ADX < 18 + low-vol → LOW_VOLATILITY
   - ADX < 22 → RANGING
4. When regime === "TRENDING", calls `classifyTrendDirection()` which:
   - Fetches H4 candles via `fetchCandles("XAUUSD", "4h", 32)` (OANDA primary, Twelve Data fallback).
   - Runs `classifyRegimeDirection` (close_move default — compares latest H4 close to close 4 bars ago).
   - **Catches all errors → returns `null`** with a non-fatal `logWarn`.

Published to `xauusd.portfolio.context` as `state.regime` + `state.regimeDirection` (separate fields).

## DB evidence — 11.5

`xauusd.portfolio.context` messages all of 11.5:
| regime | regimeDirection | count |
|---|---|---|
| TRENDING | null | **592** |
| TRENDING | UP | 14 (only 22:46–23:58) |
| MIXED_NO_EDGE | null | 36 |
| HIGH_VOLATILITY | null | 29 |
| RANGING | null | 19 |
| NOISY_CHAOTIC | null | 18 |

**592 out of 606 TRENDING messages = 97.7% had no direction.** Direction only resolved during the last hour of the day.

Per-trade lookup (`simulated_orders` joined to nearest `xauusd.portfolio.context` ≤10 min before `opened_at`):
- All 9 trades: `bb_regime=TRENDING`, `bb_dir=null`, ADX 32–47.
- Trade #9 (14:12) shows a brief flip to `NOISY_CHAOTIC` (cycle window crossed the 14:00 reversal). Still no direction.

## Market reality 11.5

Computed from `ohlcv_candles` (15min):
- Day open 4682, close 4768, **net +86 USD / +1.8% — uptrend**.
- 06:00–10:00 UTC: drift down 4682 → 4650 (the only counter-leg). Trade #1 (long 04:16) and Trade #2 (short 06:47) sit either side of this.
- **12:00–13:45 UTC: impulse 4668 → 4748 (+80 in 105 min, vertical)**. The 3 scalp-overlap SHORTs at 13:14–13:33 entered *inside* this impulse, ADX 32–36. They were mechanically counter-trend.
- 14:00 onwards: choppy consolidation 4720–4740 → late ramp to 4768.

The base regime call (TRENDING) was correct. The day was genuinely trending. The strategies were not wrong to trade — they were wrong to **short**.

## Why the direction signal collapsed

The `classifyTrendDirection` H4 path is the only producer of `regimeDirection`. Three failure modes explain `null` on 592/606 calls:

1. **fetchCandles("4h") returned `[]`** — OANDA H4 may have intermittent gaps; Twelve Data fallback often returns 404 for `XAU/USD` (documented in the file header).
2. **Candles < CLOSE_MOVE_LOOKBACK (4)** → `null` (regime-direction.ts:79).
3. **Exception swallowed** → `null` with `logWarn` only — no DB row, no metric.

All three currently look identical to downstream: `regimeDirection = null`. The `regime-direction-gate` then returns `{allow, "direction_unknown"}` (regime-direction-gate.ts:91-93) — **the gate is essentially dormant whenever the classifier fails, which is most of the time**.

The 14 messages that DID get `direction=UP` late on 11.5 (22:46–23:58) confirm the path works *sometimes* — so it's not a structural code bug, it's a data-availability / error-handling bug.

## Specific failure mode (high confidence)

**"Direction blindness via silent null"** — not stale cache, not wrong timeframe (the timeframe is correct: H4 for direction is fine, base regime correctly reads M15 ADX which fires every cycle). The base regime is fresh and right; the **direction layer fails open** and the gate is wired to allow on unknown direction.

Secondary contributor: the M15 ADX-only base classifier has no symmetry check — it can't tell you whether the trend is exhausted on M15 even while H4 is still up. But the *primary* break is the direction nullity.

## Concept-level fix-direction (for Karri, not me)

1. Treat `regimeDirection=null` in TRENDING as a **first-class trade-blocker**, not as "allow". Either: (a) flip the gate's default to "reject when unknown" once we trust the classifier, or (b) require a fallback direction source (cheaper: take the *sign of M15 EMA20-EMA50 slope* already on the blackboard — covers 100% of cycles).
2. Move direction out of the TRENDING-conditional fetch — compute it on every cycle from data we already have (no extra API call), so the signal is never null while in-session.
3. Add a hard "do not short during TRENDING_UP / do not long during TRENDING_DOWN" rule for *all* strategies, not just mean-reversion. ORB-short during a vertical M15 impulse leg is just as bad as scalp-short.

(These are concepts. Thresholds + scope are Karri's call.)

## Highest-leverage observability addition

In `portfolio-brain.classifyTrendDirection`, before each `return null`, publish a counter or DB row with the *reason*:
- `candles_empty` (fetchCandles returned [])
- `candles_too_short` (length ≤ 4)
- `fetch_error` (caught exception, include err.name)
- `null_flat` (latest === past)
- `ok_up` / `ok_down`

One line of logging today is hiding ≥5 distinct root causes. Without this we can't tell Karri whether to fix the data source or the classifier logic.

---

**Files referenced**

- `/home/nithu/code/ai-assistent/apps/worker/src/firm/portfolio-brain.ts` (lines 128–233)
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/regime-direction.ts`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/gates/regime-direction-gate.ts`
- `/home/nithu/code/ai-assistent/apps/worker/src/engines/technical-advanced.engine.ts` (line 55 — ADX@M15)
- `/home/nithu/code/ai-assistent/apps/worker/src/services/market-data.service.ts` (fetchCandles 141–230)
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/orchestrator.ts:511` (runs every cycle)
