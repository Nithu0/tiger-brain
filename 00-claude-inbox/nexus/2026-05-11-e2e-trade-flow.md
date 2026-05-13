# End-to-end trade flow trace — 2026-05-11

**Trade**: `205dd6ad-eafe-4698-8d2d-bbe171293d8d`
**Cycle**: `0866a2bb-7c6d-41d5-abd2-be379a9c960d`
**Strategy**: `xau-scalp-overlap`
**Signal**: `8d8b7b0c-3161-48a5-9bcc-7cd6a44eae88`
**Direction**: SHORT @ 4734.70 (SL 4745.43 / TP 4716.32)
**Outcome**: closed 13:42:46Z, SL hit (OANDA_SL_TP), PnL **-$401.33** (-1.01R)
**Session at entry**: `unknown` (logged); session at close (postmortem): `NY_OPENING_RANGE`
**Portfolio regime at entry**: TRENDING, risk_level high

---

## Step 1 — Signal source (`signals`)

Found. Lookup via `simulated_orders.signal_id` (signals table has no `decision_cycle_id` column — first **schema gap** in the audit query).

- `bot_id=9b2f966c…`, `source=firm-strategy:xau-scalp-overlap`, `confidence=80.00`, `created_at=13:33:04.238Z`.
- `rationale` JSON: `thesis="Scalp SHORT on RSI 79.2 (overbought) in overlap window. Criteria 4/5 (80%) — passed: rsi_strength, atr_floor, core_overlap_window, daily_room"`.
- Intended entry 4734.84848 → actual 4734.70 (slippage ~0.15 in operator's favour for a SHORT, fine).

Direction signal=short matches order direction=short. Confidence 80 matches `entry_conviction_score 0.8000`. **Clean.**

## Step 2 — Blade decision (`blade_decisions`)

Found via `cycle_id` (NOT `decision_cycle_id` — second **schema mismatch in the task spec**).

- `approved=true`, `reject_reason=null`, `captured_at=13:33:04.155Z` (90 ms before order open).
- Checks (3): `event_policy` PASS (state=CLEAR), `risk_veto` PASS (risk=high, but not vetoed), `new_gates` PASS ("4 evaluated, none hard-reject").

**Clean.**

## Step 3 — Gate decisions (`gate_decisions`)

4 gates, exactly as blade summary said.

| gate | would_reject | hard_rejected | reason |
|---|---|---|---|
| risk_level | **true** | false | `risk_level_high` |
| scalp_overlap_asia | false | false | — |
| ranging_conviction | false | false | — (conviction 0.8, regime TRENDING, score 80) |
| entry_stack_cooldown | **true** | false | `stack_cooldown_13min_lt_15min` (13.08 min since last same-dir trade, needs 15) |

**Anomaly #1 (soft)**: 2 of 4 gates flagged `would_reject=true` but `hard_rejected=false`, so order proceeded. This is by-design (shadow gates / advisory tier) but worth noting: a 13-minute stacking trade in TRENDING regime with risk_level=high passed through purely because both flags are still in shadow mode. This is consistent with foundation-gate philosophy (gates report, operator decides) — not a bug.

## Step 4 — Order placement (`simulated_orders`)

Found. `status=closed`, `execution_source=firm_strategy`, `oanda_trade_id=1113`, `provider_used=twelvedata`, `atr_at_entry=10.585`, `original_risk_points=10.734`, `size=43.00`.

Notable NULLs in metadata: `desk`, `regime_at_entry`, `entry_type`, `range_size_usd`, `tp1_price`/`tp2_price`, `thesis_quality_score`, `conviction_total/direction/timing`, `session_high/low_at_entry`, `range_percentile_at_entry`, `orb_metadata`, `entry_snapshot`, `last_activity_at`. Most of these are ORB-specific or partial-TP-specific (legit), but `desk`, `regime_at_entry`, `thesis_quality_score` and `conviction_total` are general fields that should populate from gate context (the gate `ranging_conviction` had `convictionTotal=0.8, thesisQualityScore=80` already in its context jsonb — **never propagated to the order row**).

**Anomaly #2**: `session_at_entry='unknown'` even though the postmortem 9 min later resolved `session_at_close='NY_OPENING_RANGE'`. Session classifier is either not wired into order writes, or fell back to unknown at 13:33Z.

## Step 5 — Blackboard messages

Cycle-tagged messages (4):

| t | topic | agent | type |
|---|---|---|---|
| 13:33:03.825 | xauusd.scalp.signal | scalp-overlap-manager | PROPOSAL |
| 13:33:04.445 | xauusd.manager.decisions | strategy-execution | DECISION ("Execution APPROVED") |
| 13:33:04.452 | xauusd.execution.reports | strategy-execution | EXECUTION_REPORT ("Order placed @ $4734.70") |
| 13:42:51.230 | xauusd.postmortem.reports | postmortem | POSTMORTEM |

Ordering: signal → manager decision (+620 ms) → execution report (+7 ms). Blade `captured_at` is 13:33:04.155 — sits between signal (13:33:03.825) and manager decision (13:33:04.445). Correct.

Surrounding-window query (13:32:30–13:34:00) shows full firm rhythm: sentinel/macro/calendar/ingest/herald → 3 strategy state ticks (scalp/session-break/vol-expansion) → 4 analysts (technical/macro/risk/portfolio). Two complete cycles before and one after the trade-cycle. Cycle cadence ~33s. **Clean.**

**Anomaly #3 (data-model)**: of ~40 blackboard rows in the 90-second window, only the 4 trade-cycle messages carry `decision_cycle_id`. Every FACT/INTERPRETATION posted by fact-agents and analysis-agents is `decision_cycle_id=null`. This is by-design (cycles are per-decision, not per-tick) but it means you cannot reconstruct "which fact rows informed which cycle" from the database alone — only by `timestamp`-window correlation.

## Step 6 — Postmortem

Found. `cycle_id=null` on the row (**Anomaly #4** — postmortem decoupled from the originating cycle even though it's clearly the same trade). `classification=RIGHT_THESIS_BAD_EXECUTION`. `market_score=0`, `entry_score=null`, `execution_score=null`. `pnl=-401.33`. Summary: "Management followed the playbook: no lifecycle events. Final pnl -401.33."

`full_reasoning` is contradictory: classification is `RIGHT_THESIS_BAD_EXECUTION` but the prose says "both market thesis and entry thesis scoring 0/100, indicating complete lack of analytical foundation … taking a trade with zero conviction or analysis backing the directional bias." That doesn't match RIGHT thesis — it matches WRONG thesis. The `market_score=0`/`entry_score=null` suggests the postmortem scoring pipeline didn't get fed the actual analyst snapshots, so the LLM hallucinated "zero conviction" despite the signal being 80% confidence. **Real bug or display issue worth pinging.**

`session_at_close='NY_OPENING_RANGE'` — proves session classifier works post-trade but didn't at entry time.

## Step 7 — Agent artifacts (advisory / trigger)

3 rows in the wider 13:25–13:45 window (none in the narrow 13:30–13:40 query because filtering only `advisory|trigger` excluded the 13:32:42 `review`):

| t | kind | content_len | discord_delivery_status |
|---|---|---|---|
| 13:32:42.372 | review | 678 | null |
| 13:42:54.055 | trigger | 167 | **sent** |
| 13:43:32.064 | review | 282 | null |

Pre-entry: a `review` artifact 22 s before the signal (could be the risk-advisor context for this cycle but `path=null` so unprovable). Post-close: a `trigger` artifact 8 s after close, delivered to Discord (correct). Then another `review` 38 s later.

**Anomaly #5**: no `advisory` rows at all in the entry-window. Either risk-advisor didn't produce a pre-trade advisory, or it produced one as `kind=review` (taxonomy drift). The task spec asked for `kind IN ('advisory','trigger')` — the system isn't writing `advisory` rows.

## Step 8 — Manager decisions (blackboard)

Already covered in step 5: 1 row, `xauusd.manager.decisions` @ 13:33:04.445Z, "Execution APPROVED — xau-scalp-overlap SHORT".

---

## Top 3 audit-trail gaps

1. **Postmortem `cycle_id` not populated** — postmortems decoupled from their cycle; only joinable via `trade_id` → `simulated_orders.decision_cycle_id`. Indirect, easy to miss in joins.
2. **Order metadata fields stay NULL despite gate context having them** — `thesis_quality_score`, `conviction_total`, `regime_at_entry`, `desk` are computed and persisted in `gate_decisions.context` but never copied to `simulated_orders`. Forces a join-by-cycle_id every time you want trade-level analytics.
3. **`session_at_entry='unknown'`** vs `session_at_close='NY_OPENING_RANGE'` 9 min later — session classifier wired into postmortem path but not into entry path.

Minor: **postmortem reasoning contradicts its own classification + scores** (RIGHT_THESIS vs "zero conviction"); **no `advisory` kinds being written** — risk-advisor either silent or using `review` instead.

## Verdict

**Has silent gaps, not broken.**

End-to-end the trade is fully traceable: signal → blade → 4 gates → order → execution-report → close → postmortem are all present, time-ordered, and consistent (direction SHORT throughout, conviction 0.8 throughout, no order without a signal, no execution without a blade approval). No silent failures in the firing path.

The gaps are **observability and data-completeness**, not behaviour:
- Schema mismatches in the audit-spec itself (signals lacks `decision_cycle_id`, blade uses `cycle_id`, gate uses `would_reject` not `action`, postmortem `cycle_id=null`).
- Order rows under-populated relative to what the gates already computed.
- Postmortem LLM prose disagrees with its own structured fields — needs prompt review.
- One `would_reject=true` gate (`entry_stack_cooldown` 13 min < 15) and one elevated risk_level were soft-only — this is by-design but the operator should know that the gate dashboard's "would have rejected" count for this trade is 2/4.

No "gate rejected but order opened anyway" in the hard sense, and no direction mismatch.
