---
title: ATR + XAUUSD-specific volatility behavior
source: Nexus codebase + session-thresholds + Wilder/Crabel/Chan
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, concept, atr, volatility, xauusd, session, sl-sizing]
status: distilled
---

# ATR + XAUUSD-specific volatility behavior

## ATR(14) basics

ATR (Wilder 1978) is the rolling mean of **True Range** over N bars.

`TR_i = max(high_i - low_i, |high_i - close_{i-1}|, |low_i - close_{i-1}|)`

The gap-adjusted terms only matter across discontinuities. Default N = 14, Wilder's commodity-tuned value. ATR is unit-of-price (USD on XAUUSD): ATR 4.5 means the H1 bar swings ~$4.50 of gold on average.

## XAUUSD-specific behavior

Gold's intraday range is **not stationary across sessions**. Empirically on XAUUSD H1:

- **Asia (~22:00–07:00 UTC)** — thin liquidity, H1 ATR(14) ~$2–4, range-contraction regime, mean-reversion friendly.
- **London open (~07:00–09:00 UTC)** — first impulsive expansion; ATR can double in 2–3 candles. The most reliable daily volatility event.
- **NY / overlap (~12:00–17:00 UTC)** — sustained widest ATR, **typically 2–3× the Asia value**. Most news prints (FOMC, NFP, CPI) land here.
- **DST handoff** (London → BST in March, EU → CET in October) — boundaries drift ±1h for 1–3 weeks. Hardcoded UTC misaligns sessions; use `getLondonLocalTime()` (critical-rules.md #2).

Consequence: any threshold expressed in **absolute dollars** starves Asia and over-trades NY. Always express thresholds as **N × ATR** of the active session bucket.

## Cold-start delta — what's safe

`FIRM_COLD_START_THRESHOLD_DELTA` (default -13, [-20, 0]) loosens *gate* thresholds (marketThesis/entryThesis on LONDON_ACTIVE/OVERLAP_ACTIVE only). It does **not** touch executionWindow, invalidationQuality, or ATR computation itself.

- **Safe**: ATR(14) via Twelve Data once warmup is in (≥14 H1 bars).
- **Unsafe**: local ATR from a fresh buffer < 14 bars. Mirror `computeAtrRatio` in `vol-exp-manager.ts:147` — return `null` rather than emit a half-warmed value. Never size SL on a partial-window ATR.

## Period choice (H1 dominant, M5 entry-timing only)

All Nexus strategies fetch H1 ATR(14): vol-expansion, mean-reversion, session-breakout (added 11.5 for observability), trend-following, scalp-overlap, breakout- and pullback-continuation. Env-tunable via `*_ATR_PERIOD`, bounds 5–50. H1 smooths Asia thinness while still resolving the London-open spike. **M5 ATR is for entry-timing only** (wait for an M5 expansion bar to confirm an H1 setup); never size SL from M5 ATR on a position held > 1 hour — M5 noise puts the stop inside normal pullback distance.

## Wilder vs simple range (flagged leakage risk)

Twelve Data's `fetchATR` returns Wilder-smoothed values. `vol-expansion` deliberately computes a **simple per-candle range average** locally (`vol-exp-manager.ts:144-146`, "Mirrors the backtest implementation") for the *signal*; its *SL/TP sizing* uses Wilder. Round 3 finding A3 flagged this: refactoring the signal to Wilder smoothing in code without re-running the 90d backtest silently breaks the +$528/90d sweet-spot guarantee.

## SL-sizing rule of thumb

Live H1 ATR(14) SL multipliers:

- `MR_SL_ATR_MULT = 0.75` (mean-reversion, tight)
- `TF_SL_ATR_MULT = 0.75` (trend-following sweet-spot 12.5)
- `VOL_EXP_SL_ATR = 0.7` (flagged sub-NY-noise; session widening pending)
- `SCALP_OVERLAP_SL_ATR = 1.0`
- Env floor: ~0.5 on most configs — below that = noise territory

**Heuristic**: minimum **0.75 × ATR** for tight strategies, **1 × ATR** baseline. NY-session widening to 1.2 × ATR is a documented but unflipped mitigation (`vol_exp_session_sl_widening`).

## Cross-references

- **Wilder, J. Welles (1978)** — *New Concepts in Technical Trading Systems*. Original ATR + RSI definitions.
- **Crabel, Toby (1990)** — *Day Trading with Short Term Price Patterns*. The "stretch" formula = ATR-derived volatility multiplier for opening-range breakouts; conceptual ancestor of Nexus ORB sizing.
- **Chan, Ernest (2008)** — *Quantitative Trading*. Z-score normalization of volatility for cross-instrument comparability — Nexus does not currently z-score ATR, but should for any future multi-symbol move.
- **Carver, Robert** — *Systematic Trading* / *Leveraged Trading*. ATR as volatility-target input for position sizing; Nexus is half-Carver (fixed risk %, ATR-derived SL).

## Nexus-internal links

- Session ATR profile: `docs/ref/session-thresholds.md`
- Cold-start config: `apps/worker/src/firm/cold-start-config.ts`
- ATR fetch (Twelve Data, Wilder): `apps/worker/src/services/market-data.service.ts:284`
- Local simple-range computation: `apps/worker/src/firm/vol-expansion/vol-exp-manager.ts:147`
- `atr_at_entry` stamping: `apps/worker/src/firm/strategy-execution.ts:765`
- Round 3 A3 finding (session-breakout `atr_at_entry` backfill): `00-claude-inbox/nexus/2026-05-13/round3/A3_atr_at_entry_session_breakout.md`
