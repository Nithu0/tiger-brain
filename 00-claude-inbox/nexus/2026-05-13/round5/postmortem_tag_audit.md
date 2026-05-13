# Postmortem-tag distribution audit (round 5 / C4 quantification)

Window: full postmortem table (first row 2026-05-01, last 2026-05-12). 60d query returns same rows — postmortem-agent only started writing from 30.4.

## TL;DR

- **Top-3 tags (all 49 PMs, 11 days)**: `RIGHT_THESIS_BAD_EXECUTION` 28 (57%), `CORRECT_THESIS` 18 (37%, winners only), `WRONG_THESIS` 3 (6%).
- **Among labeled losers only (n=31)**: RTBE 90.3%, WRONG_THESIS 9.7%. So yes — RTBE genuinely dominates the loser bucket.
- **Round-2 "16/16" claim is REAL but understated**. Between 04.5 morning and 12.5 17:00, every single labeled loser (27/27) was RTBE before the first WRONG_THESIS finally appeared. The "16/16" was a snapshot mid-streak. Not a small-sample fluke — it's an 8-day monoculture.
- **Caveat #1 — coverage gap**: ~63 losers from 15.4–29.4 are unlabeled (postmortem-agent wasn't writing yet). Pre-30.4 distribution is unknown.
- **Caveat #2 — classifier may be biased**: only 3 of 31 labeled losers are WRONG_THESIS. Plausible the rule in `postmortem.ts:217-221` over-routes to RTBE when direction matched briefly. Worth a classifier audit before building consumers.

## Histogram — by classification

| classification | n | losers | winners | avg_pnl |
|---|---|---|---|---|
| RIGHT_THESIS_BAD_EXECUTION | 28 | 28 | 0 | -302.08 |
| CORRECT_THESIS | 18 | 0 | 18 | +349.09 |
| WRONG_THESIS | 3 | 3 | 0 | -387.79 |

`cleanliness`, `entry_score`, `execution_score` columns are 100% NULL — agent writes only `classification` + `summary`. Granular features dormant.

## By tag × strategy_id

| classification | strategy | n | avg_pnl |
|---|---|---|---|
| RTBE | xau-volatility-expansion | 16 | -345.62 |
| RTBE | xau-session-breakout | 5 | -214.80 |
| RTBE | xau-orb | 3 | -254.56 |
| RTBE | xau-scalp-overlap | 3 | -352.69 |
| RTBE | (null) | 1 | -32.54 |
| WRONG_THESIS | xau-volatility-expansion | 2 | -388.21 |
| WRONG_THESIS | xau-session-breakout | 1 | -386.97 |
| CORRECT | xau-volatility-expansion | 13 | +450.62 |
| CORRECT | xau-session-breakout | 4 | +210.52 |
| CORRECT | xau-scalp-overlap | 1 | +19.29 |

S2 (volatility-expansion) is the heaviest RTBE contributor in absolute count. S3 (scalp-overlap) loses largest avg per RTBE. S1 has zero CORRECT_THESIS in the window — it only contributes to the RTBE bucket.

## By tag × portfolio_regime_at_entry

Mostly NULL (47% of all PMs). Where set: RTBE-TRENDING 8, RTBE-RANGING 1, WRONG-TRENDING 2, WRONG-NOISY 1, CORRECT-TRENDING 1. Regime signal is too sparse for action.

## Missing tags

The classifier defines six classes (`postmortem.ts:37-44`): CORRECT_THESIS, WRONG_THESIS, RIGHT_THESIS_BAD_TIMING, RIGHT_THESIS_BAD_EXECUTION, RIGHT_THESIS_BAD_INVALIDATION, NO_TRADE_SHOULD_HAVE_WON. Three of six are never emitted in 49 rows:
- `RIGHT_THESIS_BAD_TIMING` — never used
- `RIGHT_THESIS_BAD_INVALIDATION` — never used
- `NO_TRADE_SHOULD_HAVE_WON` — never used (would need a "didn't trade" emitter; current hook only fires on close)

No `MISTIMED_ENTRY` / `NEWS_SHOCK` exist as enum values. If Karri wants those, the schema needs to expand first.

## Consumer audit (re: C4 "dormant" claim)

- `postmortem_streaks` table updates on each PM (postmortem-hook.ts:217) — but **no SELECT consumer exists in the entire repo**. Confirmed via grep.
- `classification` IS read by 3 advisory paths: `trade-critic.ts`, `strategy-tuner.ts`, `daily-journal.ts` — these feed text into LLM prompts. So the loop is partially live (LLM advisory), but no programmatic gate / risk-engine / size-adjuster reads the tag.
- Dashboard (`apps/api/src/routes/strategies.ts:492`) reads PMs for display only.

## Implications for C4

1. **RTBE is genuinely the dominant pattern in the loser bucket (90.3% of labeled losers, n=31).** Investment in a feedback consumer is justified by signal volume — IF the classifier isn't over-routing.
2. **Caveat — validate the classifier first**. The 90% rate is suspicious. Operator/Karri should hand-label ~10 RTBE PMs to confirm vs. WRONG_THESIS. If 30%+ are mislabeled, the feedback loop will tune for the wrong failure mode.
3. **The "dormant" framing in C4 is partially incorrect** — LLM agents already consume the tag. The real gap is *programmatic action*. C4 should be reframed as "promote RTBE signal from advisory-LLM to a gate input (e.g., shrink S2 size when consecutive_count >= 3)" — not "build the first consumer".
4. **Bigger leverage**: 3 of 6 enum classes are never emitted. Wiring `RIGHT_THESIS_BAD_TIMING` (entered too early vs. valid breakout) would split the RTBE bucket and produce actionable cohorts. Bigger ROI than another RTBE consumer.
5. **Tail risk**: pre-30.4 losers (63 trades) are unlabeled and may have a different distribution. If Karri proposes ML on PM features, fix the backfill first.

## Data freshness

- Postmortem coverage 30.4 → 12.5: 31/32 losers labeled (96.9%). One loser (32.54 USD on 12.5) has null strategy_id and shorter summary — likely a corner case.
- 13.5 not yet in window (today, query at session-start time).
