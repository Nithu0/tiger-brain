---
title: Trade-flow snapshot — observability post-push validation
date: 2026-05-12
project: nexus
status: partial-online
tags: [nexus, observability, postmortem, validation]
---

# Trade-flow snapshot 2026-05-12

Validation of observability fixes (metadata-strip + session_at_entry + postmortems.cycle_id + thesis/conviction) against trades since the big push.

## Today's tape (UTC 2026-05-11, 9 closed trades)

| Metric | Value |
|---|---|
| Total closed | 9 |
| Wins | 1 |
| Losses | 8 |
| Win rate | 11.1% |
| Net PnL | **-2637.99** |

8 of 9 trades closed via `OANDA_SL_TP`. Win rate is terrible — strategy-side issue, not observability scope. Flagging for separate review.

## Last trade (most recent)

- `id`: `2320fd49-1442-45f3-8c57-59d2caaf7ecb`
- `strategy_id`: `xau-volatility-expansion`
- `opened_at`: 2026-05-11 14:12:41Z → closed 16:43:43Z
- `pnl`: -527.40
- `execution_source`: firm_strategy
- `atr_at_entry`: 16.77
- `entry_conviction_score`: 0.80
- `regime_at_entry`: **high** (not null!)
- `portfolio_regime_at_entry`: TRENDING
- `session_at_entry`: **OVERLAP_ACTIVE** (not "unknown"!)

**Metadata fully stamped on the latest trade. The fix is live.**

## Metadata coverage (last 24h, 9 trades)

| Field | Coverage |
|---|---|
| portfolio_regime_at_entry | 9/9 (100%) |
| session_at_entry NOT "unknown" | 2/9 (22%) |
| regime_at_entry not null | 1/9 (11%) |
| entry_conviction_score | 9/9 (100%) |
| atr_at_entry | 9/9 (100%) |

Only the **most recent** trade (16:43Z) has `session_at_entry` and `regime_at_entry` properly populated. The 7 earlier trades from before the deploy still show "unknown" / null. Confirms the fix landed mid-day. Cutover appears around 14:00Z.

## Postmortems (last 24h, 10 records)

| Field | Coverage |
|---|---|
| classification | 10/10 (100%) |
| market_score | 9/10 (90%) |
| entry_score | 0/10 (0%) |
| execution_score | 0/10 (0%) |
| cleanliness | 0/10 (0%) |
| cycle_id | **1/10 (10%)** |

`cycle_id` only populated on the newest postmortem (matching the latest trade). Same cutover pattern — fix is live, backlog not retro-stamped.

**Schema gap**: the requested query referenced `postmortems.evidence` (jsonb), but the actual table has no such column. `counterTrend` / `macroContradicts` evidence fields are not persisted in this table at all. Either they live elsewhere (agent_artifacts? attribution_signals?), or the evidence-fields fix has not landed. Worth confirming with the dev who shipped the postmortem migration.

**Other gap**: `entry_score`, `execution_score`, `cleanliness` are null across the board. The classifier emits a `classification` + `market_score=0` + a one-line summary, nothing deeper. Either the scorer is gated off or the migration added the columns without wiring the writer.

All 10 postmortems classify as `RIGHT_THESIS_BAD_EXECUTION` except one `CORRECT_THESIS` (the single win). Summary text is template-generated, not insight-bearing.

## Gate decisions today

| Gate | would_reject | hard_rejected |
|---|---|---|
| entry_stack_cooldown | 3 | 0 |
| ranging_conviction | 0 | 0 |
| risk_level | 9 | 0 |
| scalp_overlap_asia | 0 | 0 |

**Zero hard rejections today.** `risk_level` flagged 9 trades in shadow mode (would_reject=9 matches the 9 entries — meaning every trade today tripped the risk-level shadow gate). Operator decision pending whether to promote `risk_level` to hard.

## Discord delivery (last 24h)

| kind | status | count |
|---|---|---|
| trigger | sent | 5 |
| review | null | 10 |
| research_note | null | 9 |

Triggers fire to Discord (5/5 sent). Reviews and research_notes have `discord_delivery_status=null` — either delivery is gated off for those kinds, or the column isn't written for non-trigger artifacts. Last-hour window was empty; widening to 24h showed activity.

## Verdict: **PARTIAL ONLINE**

Working:
- `session_at_entry` + `regime_at_entry` + `portfolio_regime_at_entry` stamping on new trades
- `postmortems.cycle_id` on new postmortems
- `entry_conviction_score` + `atr_at_entry` consistently present
- Discord triggers delivering

Gaps:
- `postmortems.evidence` column doesn't exist — `counterTrend`/`macroContradicts` not persisted as designed
- `postmortems.entry_score` / `execution_score` / `cleanliness` all null (writer not wiring these?)
- Discord delivery status not tracked for `review` / `research_note` kinds
- Backlog (pre-14:00Z 2026-05-11) not retro-stamped — acceptable, but be aware analytics queries over 24h will see a mixed population

Not in scope for this validation but flagging:
- 1-in-9 win rate today, -2638 PnL. Strategy review needed (separate from observability).

