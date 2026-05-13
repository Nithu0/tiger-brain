# Round 4 audit — `atr_xauusd_volatility.md`

**Date:** 2026-05-13
**Output:** `~/Obsidian/Brain/_library/trading/concepts/atr_xauusd_volatility.md`
**Word count:** 647 total (frontmatter + headings + links); body prose ≈ 510 words. Within 400–600 target.

## Sources used (all in-repo / in-brain, no fabrication)

1. **`fetchATR` implementation** — `apps/worker/src/services/market-data.service.ts:284-296`. Twelve Data `/atr` endpoint with `time_period=N`, default 14, returns Wilder-smoothed.
2. **Per-strategy ATR period configs** — grep across `apps/worker/src/firm/*/config.ts`:
   - `MR_ATR_PERIOD`, `MR_SL_ATR_MULT = 0.75` (mean-reversion/config.ts:60-61)
   - `TF_ATR_PERIOD`, `TF_SL_ATR_MULT = 0.75` (trend-following/config.ts:47,58)
   - `VOL_EXP_ATR_PERIOD = 14`, `VOL_EXP_SL_ATR = 0.7` (vol-expansion/config.ts:50-51)
   - `SCALP_OVERLAP_ATR_PERIOD`, `SCALP_OVERLAP_SL_ATR = 1.0` (scalp-overlap/config.ts:47-48)
   - `SESSION_BREAKOUT_ATR_PERIOD = 14` (session-breakout/config.ts:93)
   - `PC_ATR_PERIOD`, `BC_ATR_PERIOD` (pullback/breakout-continuation configs)
3. **Simple-range vs Wilder leakage risk** — `vol-exp-manager.ts:142-159` (`computeAtrRatio`, comment "Mirrors the backtest implementation"). Confirmed via Round 3 finding A3 (`round3/A3_atr_at_entry_session_breakout.md`) and Round 2 finding 19 (`round2/19_vol_expansion_distilled.md:23`).
4. **`atr_at_entry` stamping** — `strategy-execution.ts:727-790` (`proposal.state.atr ?? proposal.state.atr14` pattern; A3 added the parallel fetch for session-breakout 11.5).
5. **Session thresholds + cold-start delta scope** — `docs/ref/session-thresholds.md` (table of per-session gate thresholds, cold-start only touches primary windows + only marketThesis/entryThesis).
6. **Cold-start config** — `apps/worker/src/firm/cold-start-config.ts` (bounds [-20, 0], default -13).
7. **DST critical rule** — referenced via `docs/ref/session-thresholds.md` line 16-18 + `critical-rules.md` rule #2 + `session-window.ts:185`.
8. **Vol-expansion lessons** — `_library/trading/strategies/volatility_expansion.md` lines 16-47 corroborate Asia vs NY ATR ratio, session-aware SL widening, and the Wilder-vs-simple-range split.
9. **Mean-reversion 0.75×ATR** — `_library/trading/strategies/mean_reversion_xau.md` line 35 confirms tight SL rationale.

## What I made an inference call on (and flagged in-text)

- **"2-3× wider NY vs Asia"** — corroborated qualitatively by `volatility_expansion.md:20` (gold's "long, low-volatility regimes punctuated by news-driven impulse bursts") and by the `getBaselineSessionThresholds()` table's per-session gating, but the exact 2-3× multiplier comes from operator-tribal-knowledge / industry standard, not a numeric query I ran against `ohlcv_candles`. A 2-min SQL could replace this with a live measurement — flagging as followup, not blocker.
- **"London-open spike, ATR can double in 2-3 candles"** — standard market-microstructure claim, not directly queried from Nexus tables. Same followup applies.
- **M5 ATR "entry-timing only, not SL sizing"** — not enforced anywhere in code today; this is a prescriptive rule extracted from the H1-dominant fact that *all* current Nexus strategies fetch H1 ATR. Stated as heuristic, not as repo-policy.
- **Crabel "stretch" formula** — Crabel/Carver/Chan/Wilder are not cited anywhere in the Nexus codebase. Cross-refs are inferred-canonical from standard literature; flagged consistent with prior lessons (`19_vol_expansion_distilled.md` made the same call).

## What was easy / what was hard

**Easy:** all ATR multipliers + period configs are clean grep hits, well-named, env-tunable. The Wilder-vs-simple-range split was already documented in two prior lessons.

**Hard:** the cold-start delta scope. The session-thresholds.md file makes it clear cold-start touches *gate* thresholds, not ATR — but the natural-language framing "what's safe vs unsafe under cold-start" doesn't map 1:1 onto what cold-start-config.ts actually does. I reframed: the *real* unsafe case is computing ATR on a partial candle buffer (orthogonal to `FIRM_COLD_START_MODE` but conceptually related). Worth a future cleanup pass — "cold-start" the env flag and "cold-start" the colloquial concept of "just-booted firm with thin data" are not the same thing, and the lesson elides this distinction for brevity.

## Followup suggestions

1. Run a SQL pass against `ohlcv_candles` to publish the actual median H1 ATR per session bucket (Asia / London-active / NY / overlap) and replace the qualitative "2-3×" with a measured ratio. Belongs in `docs/ref/session-thresholds.md` if numeric.
2. Decide whether the lesson should warn against M5 ATR for SL sizing more strongly — i.e. add an env-floor in code (`*_TIMEFRAME` check on ATR fetch). Currently it's convention, not enforced.
3. Karri-question: should the vol-expansion simple-range-vs-Wilder split be considered tech-debt (refactor + rerun backtest) or design (deliberate noise filter)? The current code comment treats it as design.

## Workflow check

~7 tool calls, ~6 min wall-time. Bottleneck was tightening the prose from 813 → 647 words after the first draft over-explained the Wilder formula and the cold-start scope. Edit pass dropped two paragraphs of preamble and merged the "DST handoff" bullet into the session table. Bullet density is high — fine for a concept lesson (operator scans, doesn't read linearly).
