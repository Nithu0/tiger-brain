---
type: corpus-extraction
domain: nexus-trading-firm
subject: karri-mental-model
batch: 2026-05-13-round2
status: raw
claude_priority: P0
source_glob: docs/strategy/proposals/*.md
proposal_count: 24
distilled_to: _library/trading/concepts/karri_mental_model.md
---

# Karri Mental Model — Full Corpus Extraction

Harvested from every proposal under `docs/strategy/proposals/` (24 files, 2026-05-08 → 2026-05-13) plus the `README.md` template Karri implicitly authored by reviewing the first batch. Karri does not write rebuttals inline — `Review notes` sections are empty across the board because operator captures his feedback verbally (or via Discord) and Claude transcribes via PR status changes, commit SHAs, and the `Decision:` field. The patterns below are inferred from what got approved, what got rejected/parked, what reviewers re-shaped, and the questions Claude pre-emptively asks him in every proposal.

---

## 1. Inventory (24 proposals, dato sortert)

| Date | Slug | Status | Approval signal |
|---|---|---|---|
| 2026-05-08 | break_even_trigger_lower | proposed | parked — superseded by per-strategy BE-on-1R proposals |
| 2026-05-08 | risk_pct_clamp | closed-already-implemented | moot (envFloat already clamps) |
| 2026-05-08 | deprecate_simulated_orders_strategy_id_desk | proposed-revised | half-cancelled (strategy_id now populated; desk-only) |
| 2026-05-11 | conviction_quartile_position_sizing | proposed | deferred 30+ days |
| 2026-05-11 | funnel_drain | proposed (impl off) | implemented behind flag, awaiting flip |
| 2026-05-11 | orb_observe_only | approved-awaiting-operator-flip | env-flip only, code already exists |
| 2026-05-11 | postmortem_size_down_feedback | proposed | parked pending streak-counter infra |
| 2026-05-11 | processed_signals_persistence | proposed | architecture concern, scheduled |
| 2026-05-11 | regime_direction_gate | implemented (env-gated default-off) | TIER 1 batch — approved |
| 2026-05-11 | scalp_overlap_observe_only | approved-awaiting-operator-flip | env-flip only |
| 2026-05-11 | session_block_gate | implemented (env-gated default-off) | TIER 1 batch — approved, sterkeste fix |
| 2026-05-11 | sl_cooldown | implemented (env-gated default-off) | TIER 1 batch — approved |
| 2026-05-11 | vol_expansion_throttle_review | proposed-revised | re-evaluation after baseline expanded; no action yet |
| 2026-05-12 | daily_trade_cap | implemented (env-gated default-off) | approved, awaits Karri activation |
| 2026-05-12 | strategi_1_trend_following_core | proposed → integrated (PR #7+#10) | full Karri spec, Claude implementing |
| 2026-05-12 | strategi_2_breakout_continuation | proposed → integrated (PR #8+#10) | full Karri spec |
| 2026-05-12 | strategi_3_pullback_continuation | proposed → integrated (PR #9+#10) | full Karri spec — "mest stabile alpha" |
| 2026-05-12 | vol_exp_break_even_on_1r | proposed | live observation pending |
| 2026-05-12 | vol_exp_confluence_filter | proposed | live observation pending |
| 2026-05-12 | vol_exp_mean_revert_block | proposed | live observation pending |
| 2026-05-12 | vol_exp_no_chase_filter | proposed | live observation pending |
| 2026-05-12 | vol_exp_session_sl_widening | proposed | live observation pending |
| 2026-05-13 | strategi_4_mean_reversion | implemented (approved-verbally, live) | first counter-trend strategy, sweet-spot-tuned, LIVE |

---

## 2. The proposal template Karri implicitly demands

`README.md` defines the schema, but the pattern hardens with every iteration:

1. **Status + Reviewer + dates** — must be explicit; "Karri" is hard-coded reviewer for money-impact changes
2. **TL;DR** — one paragraph, must include estimated $-impact or R-impact
3. **Current behaviour** — file:line citation mandatory, env-var defaults listed
4. **Proposed change** — diff sketch, new env-var defaults
5. **Risk profile** — best-case / worst-case / edge-cases / backwards-compat **as 4 explicit subsections**
6. **Supporting evidence** — backtest period + N, live observation refs, related docs
7. **Rollback path** — env-flag named explicitly; "30 sec rollback" is the gold standard phrase
8. **Open questions for reviewer** — Claude pre-emptively flags 3-6 design choices and offers alternatives
9. **Review notes** — left blank for Karri's pencil
10. **Decision / Implemented** — footer with commit SHA when landed

---

## 3. Karri's vocabulary (extracted from his usage)

- **TIER 1** — strongest single-fix proposals, batched together. Approval criterion: "$1k+ impact + structural, not statistical"
- **observe-only mode** — env-flag deactivation that preserves data collection. Reactivation gated on other fixes shipping first.
- **funnel drain** — Karri's term for proposal-loss between strategy emit and execution
- **structural vs statistical** — he distinguishes structural problems (R:R math, MFE=$0 retrospect, sample-independent) from statistical (need 30+ days). Structural can be acted on with low-N data.
- **trend-pause** (canonical open hypothesis) — when market chops sideways briefly inside a trend, regime-classifier rapidly flips UP→DOWN→UP, causing 4-5 counter-trend losses. "Strategien har ikke 'vet jeg er i trend / chop / pause?'-state. Når trend pauser, blir den blind."
- **continuation strategies** vs **mean-reversion strategies** — Karri's portfolio taxonomy. S1/S2/S3/Vol-Exp/Session-Breakout = continuation. S4 = explicitly counter-trend, complementary.
- **smart-money pullback acculmulation** — strategy-3 edge mechanic: "institusjoner kjøper ikke topp — de akkumulerer på pullbacks"
- **compression → trigger → expansion** — three-phase model for breakout continuation (S2)
- **impuls / pause / fortsettelse** — three-phase model for pullback continuation (S3): 1.2+ ATR impulse, 0.3–1.2 ATR retrace, signal candle entry
- **counter-trend mean-reversion** — explicit anti-pattern. Strategies in TRENDING_UP must not SHORT, in TRENDING_DOWN must not LONG.
- **sweet-spot tuning** — Karri's process: full 6-month backtest after proposal lands, then tune defaults to the parameter region that maximizes expectancy + drawdown. Lands as separate commit before activation.
- **per-strategi vs global** — recurring axis on gates (cooldown, cap, risk feedback). Karri tends to prefer per-strategi as default unless data shows correlation across strategies.
- **conviction-quartile** — operator-introduced framing for sizing-via-Blade-score (Karri hasn't ruled on it yet — flagged for 30+ days observation).

---

## 4. Evidence bar Karri demands

From the pattern of what was approved vs deferred:

- **Backtest:** preferred ≥6 months OANDA H1 data before live activation. S1/S2/S3/S4 all got 6mo sweet-spot tuning before flip.
- **Sample minimum:** "30+ closed trades" is the soft floor (operator-prinsipp #6). Below that, only structural anomalies (R:R math, MFE=$0) qualify for action.
- **Convergence rule:** Multiple independent analyses pointing to same conclusion (tap1 + tap2 + Claude) can override low-N. Used as justification for TIER 1 batch approval at N=3-4.
- **Live observation:** all behavior-changes ship as `*_ENABLED=false` env-flag for 7-14 days of shadow logging before flip. Karri reads logs, not just summary stats.
- **Specific data the proposal must show:** WR, R-multiple, MFE/MAE per trade, session breakdown, regime breakdown, $/trade
- **Rejection-tagged rejection:** when proposing a threshold change for vol-exp, Claude was told to instrument rejection-reasons first (14d), then decide. Karri rejects pure "tune the number" without observing the funnel.

---

## 5. Karri's rejection / pushback patterns

Inferred from proposals that were parked, revised, or required step-down:

1. **No "tune the threshold" without rejection-instrumentation** — vol_expansion_throttle_review got revised: instrument first 14 days, then decide.
2. **No auto-disable** — every proposal that smelled like behavioral auto-pause (postmortem_size_down, ORB-disable) got rephrased to env-flag + shadow-mode + operator-flip. The operator's principle #1 mirrors Karri here.
3. **No counter-trend mean-reversion in trending regimes** — codified into regime_direction_gate. Hard block, not soft penalty.
4. **No fading momentum / no shorting strong uptrends / no falling knives / no chop trading / no "billige reversals"** — explicitly listed in Strategi-1 spec under "Strategien SKAL IKKE".
5. **No threshold-only proposals** — if a proposal only changes a number without explaining the why-now, it gets parked. Conviction-quartile got "deferred 30+ days".
6. **No auto-activation of new strategies** — S4 was implemented + backtested before "approved-verbally". Even with Karri-OK, default OFF in code; activation is a separate Railway flip.
7. **No global cooldown/cap when per-strategy fits the data** — Karri's defaults lean local unless correlation is shown.
8. **No "while we're here" refactors** — proposals must be focused. The deprecate_simulated_orders proposal got revised when strategy_id got populated mid-flight — Karri/Claude split the proposal in two rather than land both deprecations together.
9. **No two changes in one PR** — strategy modules ship as isolated PRs (S1, S2, S3 each got their own merge; integration was a 4th merge). Karri reviews per-module.
10. **No "stale-exit kills winners" fix without BE-trigger upstream** — the original BE-trigger-lower (0.5R) got parked in favor of per-strategy BE-on-1R proposals that are tighter scoped per module.

---

## 6. Karri's approval patterns (archetypes he likes)

1. **Hard pre-trade gate, env-flag default-off, 30s rollback** — session_block, regime_direction, daily_trade_cap, sl_cooldown all match this archetype. All approved.
2. **Observe-only emergency stop** — env-flag flip when a strategy is actively bleeding; scalp_overlap + ORB both approved-awaiting-flip.
3. **Pullback continuation with structure confirmation** — S3 is described as his "mest stabile alpha". Pattern: trend regime + ADX + vol-expansion + impulse + structured pullback + RSI confirmation + rejection candle. Quote: "Buy weakness in strength, sell strength in weakness."
4. **Compression → expansion breakout, NOT range-gambler** — S2 must have compression phase (ATR < 0.85 × 20-avg), retest, clean candle (wick < 60% body), vol-confirmation. No naïve range breaks.
5. **Per-strategy daily cap + cross-strategy daily cap stacked** — S1/S2/S3 each cap at 3/day; daily_trade_cap_gate adds cross-strategy 6/day on top. Two layers.
6. **Tight SL (1.0–1.5 × ATR) with high R-multiple TP (3R initial + trail)** — every approved strategy: SL ≈ 1.5 ATR, TP ≈ 3R, BE at +0.5R, trailing 1.0 ATR after +1R, time-stop 8h.
7. **Direction-loss-protection** — max 2 losses in same direction per day. Hardcoded into S1/S2/S3.
8. **No-chase** — 1.8 × ATR max from EMA20 / impulse-start. If price has already moved, don't enter late.
9. **High-vol risk reduction** — auto-downscale from 0.5% to 0.35% when ATR > 1.5–1.8 × avg.
10. **Mean-reversion is OK if explicit** — S4 (counter-trend) approved because it's labeled mean-reversion and gated to NY_CONTINUATION + ADX<30 + ≥2.5 ATR impulse + RSI extremes. The blocking gate (regime_direction_gate) excludes S4 from the mean-rev-block list.

---

## 7. Karri's open research questions

1. **Trend-pause detection** (canonical, 2026-05-12) — current regime-direction-gate is a proxy; the real problem is that during chop inside a trend, the classifier flips. Phase 1 instrumentation feasibility analysis written (`2026-05-12-trend-pause-detection.md`), Phase 2 gating pending. Quote: "Når trend pauser, blir den blind."
2. **Conviction-score reliability** — does Blade's composite score actually predict trade quality? Per-strategy or global quartile boundaries? Open until 30+ days post metadata-fix.
3. **Postmortem-tag → risk feedback loop** — 16/16 losers tagged RIGHT_THESIS_BAD_EXECUTION during bleed-period; tag exists but no consumer. Should size-down trigger after 2-consecutive? Scale factor? Tag-strict or tag-loose?
4. **Vol-expansion funnel** — 11% (later 49% on bigger N) signal-to-order. Is it the gate filtering correctly, or strangling a working strategy? Awaits rejection-tagging instrumentation.
5. **Per-strategy vs global cooldown / cap** — every gate proposal asks. Karri leaning per-strategy by default but hasn't ruled definitively.
6. **STALE_TRADE_EXIT with negative PnL** — should it count as SL for cooldown purposes? Currently doesn't. Open.
7. **News-event blackout for S4 mean-reversion** — should impulse-detection skip near FOMC/NFP/CPI? Open.
8. **BE-trigger at 0.5R vs 1.0R vs per-strategy** — original 0.5R proposal parked; S1/S2/S3 use 0.5R; vol-exp BE-on-1R proposal pending.

---

## 8. Vocabulary of refusal

Phrases Karri (or Claude transcribing him) uses to signal a no-go:

- "fundamentally feil"
- "for streng / for løs"
- "missed-profit per false positive: $X" — quantified
- "vi vet ikke uten rejection-tagging"
- "structurally ulønnsom selv ved 60% WR"
- "mean-reversion-feiltagelse i sterk trend"
- "memory loop / loss compounding"
- "den retningen har allerede brent seg ut"

---

## 9. Architecture choices Karri ratified by silence

These are baseline assumptions in every approved proposal:

- All money-impact changes behind env-flag, default OFF
- 30-second rollback via Railway env flip (no code revert needed)
- ATR-multiple-based SL/TP, not pip-based
- H1 timeframe for trend/regime classification, M15 for entry
- Session-aware (London / NY / Asia / overlap / opening_range)
- Postmortem-tagged for every closed trade
- Daily-loss-cap caps unchanged when stacking strategies (aggregate risk constant)
- Per-strategy max-open-positions enforced

---

## 10. Distillation pointer

This corpus is the source. Distilled curriculum at `_library/trading/concepts/karri_mental_model.md`. When new proposals land or new Karri-decisions come in, update both files (raw evidence here, curriculum there).
