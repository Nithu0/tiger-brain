---
date: 2026-05-11
type: incident-analysis
strategy: xau-scalp-overlap
reviewer: Karri
status: descriptive (not a proposal)
total_loss_usd: -1058
note: Headline "-$1,200" rounding; exact realized = -$1,058.07
---

# xau-scalp-overlap — 3 consecutive losses 2026-05-11

Three back-to-back SHORT entries by bot `9b2f966c` on `xau-scalp-overlap` between 13:14Z and 13:42Z. All three stopped at the OANDA SL. Net realized PnL: **-$1,058.07** across ~28 minutes wall-clock.

**This is descriptive analysis. Strategy decisions belong to Karri.**

---

## The three trades

| Trade | Open (UTC) | Close (UTC) | Dir | Entry | SL | TP | Close | R | PnL | Conv | Portfolio Regime |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `f64feec4` | 13:14:31 | 13:17:46 | SHORT | 4720.15 | 4727.36 | 4700.04 | 4727.58 | -1.03R | -$292.97 | 0.60 | TRENDING |
| `02d3d403` | 13:19:59 | 13:31:36 | SHORT | 4727.04 | 4736.41 | 4708.74 | 4736.47 | -1.01R | -$363.77 | 0.60 | TRENDING |
| `205dd6ad` | 13:33:04 | 13:42:46 | SHORT | 4734.70 | 4745.43 | 4716.32 | 4745.59 | -1.01R | -$401.33 | 0.80 | TRENDING |

All three `close_reason = OANDA_SL_TP` (stop hit at broker). All three `result_r ≈ -1.0` — clean stop-outs, no slippage anomaly. `session_at_entry = unknown` (separate observability gap, not the cause).

Each subsequent entry was at a **higher** price than the previous SL — the system kept re-shorting into a rising market.

## Realized price action 13:10Z–13:35Z (xauusd.market.raw)

Price was monotonically up through the entire window. Sample ticks:

| Time | Price |
|---|---|
| 13:10:13 | 4715.65 |
| 13:14:31 (entry 1) | 4717.43 → opened at 4720.15 |
| 13:19:58 (entry 2) | 4726.34 → opened at 4727.04 |
| 13:22:19 | 4730.15 |
| 13:26:45 | 4733.28 |
| 13:32:48 | 4733.95 |
| 13:33:01 (entry 3) | 4734.85 → opened at 4734.70 |
| 13:33:36 | 4734.85 |

Net move 13:10 → 13:33: **+19.20 USD (+0.41%)**. Each SL was ~7–10 USD above entry, well within the run-up rate. The market did not reverse for any of the three trades.

## Indicator state at entries (from blackboard `xauusd.market.raw`)

Indicators across the window — uniformly screaming "extended uptrend":

- **ADX**: 32 → 36 (rising, strong trend)
- **RSI**: 73 → 79 (deeply overbought)
- **MACD histogram**: +5.16 → +7.71 (bullish and expanding)
- **Stochastic K**: 95–99 (pinned at top)
- **Price vs BB middle**: trading at or above upper band the entire window
- **EMA20 < EMA50 < price** consistently

This is a textbook trending-up market. The technical-direction snapshots from `analysis_snapshots` show `tech_direction='short'` with `tech_score=-4.0` at `tech_confidence=62%` — i.e. the tech-analyzer was reading the same overbought / over-extended signature as a mean-reversion **short** opportunity, while `macro_direction='long'` disagreed. Scalp-overlap took the tech-side short.

## Regime mismatch

All three: `portfolio_regime_at_entry = TRENDING`. (`regime_at_entry` itself is NULL on all three — separate gap, but the portfolio-level field is populated and unambiguous.)

`xau-scalp-overlap` is, by design, a mean-reversion / overlap scalp — its edge case is range / chop conditions. Firing it counter-trend in an ADX-32+, RSI-78+ environment is exactly the pathological cell:

- Mean-reversion logic flags overbought as a fade
- Trending regime says the overbought reading is the trend, not the exhaustion
- Strategy enters short, price keeps grinding up, SL hits

Three consecutive same-direction stop-outs in a strictly monotonic uptrend is not three independent unlucky draws — it's one regime call repeated three times.

## Conviction distribution

- Trade 1: 0.60
- Trade 2: 0.60
- Trade 3: 0.80 ← highest conviction, largest loss

Conviction did not protect against the loss; the third (highest-conviction) entry produced the worst PnL. The conviction model and the regime-context disagree, and right now the regime-context was correct.

## Postmortems (automated)

All three classified `RIGHT_THESIS_BAD_EXECUTION` with `market_score = 0`, `entry_score = null`, `execution_score = null`. Summary text on all three is identical boilerplate: "Management followed the playbook: no lifecycle events." 

**Reading**: the automated postmortem is treating these as execution problems, but the price evidence above says these are **wrong-thesis** trades — the regime context was unambiguously trending-up and the strategy entered short three times in a row. The `RIGHT_THESIS_BAD_EXECUTION` label is misleading here. Postmortem signal-quality is itself a small observability concern, separate from the strategy question.

## Pattern verdict

**Regime mismatch.** Not drawdown, not setup-quality variance, not slippage. The strategy fired its designed playbook in a regime where that playbook is structurally counter-edge, and the market gave a clean, monotonic counter-example three times.

## Open questions (for Karri)

These are questions, not recommendations:

1. Should `xau-scalp-overlap` carry a regime-gate that blocks entries when `portfolio_regime_at_entry = TRENDING`? Today there's no such gate in the entry path, and the result is repeated entries in the wrong regime.
2. Should consecutive same-direction stop-outs trip a per-strategy cooldown (e.g. after 2 SL in the same direction within N minutes, block entries until regime context refreshes)?
3. Is `tech_direction='short'` at RSI 78 / ADX 32+ the intended tech-analyzer output, or is the tech model itself counter-trend-biased on overbought readings? (Separate concern from scalp-overlap.)
4. Why is `regime_at_entry` NULL on all three trades while `portfolio_regime_at_entry` is populated? Two different fields, only one wired. Observability gap.

## Raw context

- Bot id: `9b2f966c-...`
- Window: `2026-05-11T13:14Z` → `13:43Z`
- Trade ids: `f64feec4-9cab-45b1-86a6-9ab7d5a04f32`, `02d3d403-c1e4-46c4-bd7d-eb7b37f470f1`, `205dd6ad-eafe-4698-8d2d-bbe171293d8d`
- All `close_reason = OANDA_SL_TP`, all `result_r ≈ -1.0`
- Tech analyzer state across window: `direction=short, score=-4.0, confidence=62`, with `macro_direction=long` (disagreeing)
- Realized XAU move 13:10→13:35: +19.20 USD (+0.41%), continuous up-leg, no reversal

---

## Pattern reference

When a multi-trade loss-streak shows this signature (same-direction stop-outs, monotonic counter-move, regime-mismatch), the canonical decision-tree is [[When-Trade-Bleeds-Multi-Day]]. The "pull `portfolio_regime_at_entry` distribution first" guidance there was written specifically using this incident as the worked example.

---

*Authored 2026-05-11 by descriptive-analysis pass. No strategy changes proposed. Routing to Karri for strategy call.*
