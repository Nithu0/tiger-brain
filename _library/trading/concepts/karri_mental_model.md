---
tags: [library, reviewer, karri]
type: source
status: distilled
claude_priority: P0
domain: nexus-trading-firm
distilled_from: 00-claude-inbox/nexus/2026-05-13/round2/16_karri_proposal_corpus.md
last_refreshed: 2026-05-13
update_when: new proposal lands OR Karri verbal decision OR strategy goes live
---

# Karri Mental Model — Curriculum for Future Claude Sessions

Karri is Nexus's strategy/risk reviewer. Operator owns ops/infra; Karri owns money-impact decisions. He does not write inline rebuttals — his model is reconstructed from what gets approved, what gets parked, and the specs he hands Claude to implement. Read this before reasoning about any strategy/risk change.

---

## Karri's vocabulary (use these terms with him)

- **TIER 1 fix**: structural single-fix with ≥$1k/30d impact and rollback-by-flag.
- **observe-only mode**: env-flag deactivation that preserves data collection.
- **structural vs statistical**: structural problems (R:R math, MFE=$0, sample-independent) can act on N<30; statistical needs 30+ days.
- **trend-pause**: chop inside a trend that fools the regime-direction classifier into rapid UP↔DOWN flips, triggering counter-trend losses. Canonical open hypothesis. "Når trend pauser, blir den blind."
- **continuation vs mean-reversion**: portfolio taxonomy. S1/S2/S3/Vol-Exp/Session-Breakout = continuation. S4 = explicit counter-trend, complementary.
- **compression → trigger → expansion**: S2 three-phase model.
- **impuls / pause / fortsettelse**: S3 three-phase model (1.2+ ATR impulse, 0.3–1.2 ATR retrace, signal-candle entry).
- **smart-money pullback accumulation**: S3 edge mechanic. "Buy weakness in strength, sell strength in weakness."
- **counter-trend mean-reversion in TRENDING**: explicit anti-pattern — must be hard-blocked.
- **no-chase**: if price has moved >1.8 ATR from impulse-start / EMA20, do not enter late.
- **sweet-spot tuning**: 6-month backtest after proposal lands, tune defaults to maxima, separate commit before live flip.

---

## What Karri demands of every proposal

1. **Template compliance**: TL;DR with $-impact, file:line citations, current behaviour, proposed change (diff sketch + new env defaults), risk profile (4 subsections: best-case / worst-case / edge-cases / backwards-compat), supporting evidence (period + N), rollback path (named env-flag, "30 sec rollback" is gold), 3-6 open questions with alternatives offered.
2. **Env-flag default OFF**. Always. Activation is a separate Railway flip after his review.
3. **≥6 months OANDA H1 backtest** before live activation. Sweet-spot tuning lands as a separate commit.
4. **≥30 closed trades** sample minimum unless invoking the structural-problem override (R:R math, MFE pattern, convergence of independent analyses).
5. **Rejection-tagging before threshold-tuning**: instrument the funnel for 14 days before proposing a number change.
6. **Per-trade + daily metrics**: WR, R-multiple, MFE/MAE, session breakdown, regime breakdown, $/trade.
7. **One change per PR** for strategy modules (S1, S2, S3 each got their own merge).

---

## Karri's rejection patterns (anti-patterns to avoid)

1. **Auto-disable on anomaly** — never. Health-check REPORTS, operator/Karri decide.
2. **Counter-trend mean-reversion in TRENDING regimes** — hard-blocked by regime_direction_gate.
3. **Fading momentum / shorting strong uptrends / falling knives / chop-trading / "cheap reversals"** — listed in Strategi-1 spec as "Strategien SKAL IKKE".
4. **Threshold-only proposals** without instrumentation showing why-now. Conviction-quartile parked 30+ days for this reason.
5. **Two changes in one PR** — split strategy modules into isolated merges.
6. **Global cooldown/cap** when per-strategy fits the data. Karri defaults local unless cross-strategy correlation shown.
7. **"While we're here" refactors** — focused diffs only.
8. **Late entries / chasing impulse** — anti-chase filter is mandatory in every approved strategy.
9. **Naïve range breakouts** — S2 requires compression phase + retest + wick<60% + vol-confirmation. No range-gambler.
10. **Behavior change without rollback flag** — every approved gate has a `*_ENABLED=false` knob.

---

## Karri's approval archetypes (he likes these)

1. **Hard pre-trade gate, env-flag default-off**: session_block, regime_direction, daily_trade_cap, sl_cooldown.
2. **Observe-only emergency stop**: env-flip for actively-bleeding strategies (scalp_overlap, ORB).
3. **Pullback continuation with structure**: trend + ADX + vol-exp + impulse + 0.3–1.2 ATR retrace + RSI + rejection candle.
4. **Compression → expansion breakout**: ATR contraction <0.85× 20-avg, retest within 0.1 ATR, clean candle.
5. **Stacked caps**: per-strategy daily cap (3/day) + cross-strategy cap (6/day).
6. **Tight SL + high R-multiple TP**: SL ≈ 1.5 ATR, TP ≈ 3R initial + trail 1.0 ATR after +1R, BE +0.5R, time-stop 8h.
7. **Direction-loss protection**: max 2 losses per direction per day.
8. **High-vol risk auto-reduction**: 0.5% → 0.35% when ATR > 1.5–1.8× avg.
9. **Mean-reversion gated explicitly** (S4): ADX<30, ≥2.5 ATR impulse, RSI extreme, NY_CONTINUATION only, confirmation candle.
10. **Postmortem-tagged closes** with `RIGHT_THESIS_BAD_EXECUTION` vs `WRONG_THESIS` vs `STOP_TOO_TIGHT` taxonomy.

---

## Karri's open research questions

1. **Trend-pause detection** (canonical). Current regime_direction_gate is a proxy. Phase 1 instrumentation pending: count regime-direction flips in 30-min window + ATR-contraction signal. Phase 2 gating (raise SL_COOLDOWN to 120m on pause-detect?) awaits log review. **Do not propose own implementation — Karri reviewing.**
2. **Conviction-score reliability**: does Blade's composite score predict edge? Per-strategy or global quartile boundaries? 30+ days post metadata-fix needed.
3. **Postmortem-tag → risk feedback**: should 2-consecutive `RIGHT_THESIS_BAD_EXECUTION` trigger 0.5× size-down? Tag-strict vs tag-loose? 24h timeout calendar or trading-hours?
4. **Vol-expansion funnel health**: 11% / 49% conversion — gate-too-strict or working-as-intended? Awaits rejection-tagging.
5. **STALE_TRADE_EXIT with negative PnL** — should it count as SL for cooldown? Currently doesn't.
6. **News-event blackout for S4 mean-reversion** — block before FOMC/NFP/CPI?
7. **Per-strategy vs global**: cooldown, cap, risk-feedback all hit this axis. Default local; await data showing correlation.

---

## When in doubt

- Karri's gate stack (in approval order): sl_cooldown → regime_direction → session_block → daily_trade_cap → mini-Blade.
- His preferred timeframes: H1 for regime/trend, M15 for entry, ATR(14) for sizing.
- His preferred sessions: LONDON_ACTIVE, NY_CONTINUATION, ASIA_OBSERVE (for S1 only). Block OVERLAP_ACTIVE + NY_OPENING_RANGE.
- His size cap default: 0.5% risk per trade, 0.35% in high-vol.
- His R-target: 3R initial TP, trail 1.0 ATR after +1R, BE at +0.5R.
- His rollback gold standard: "30 sec via Railway env flip, no code revert needed."

Full evidence: `00-claude-inbox/nexus/2026-05-13/round2/16_karri_proposal_corpus.md`.
