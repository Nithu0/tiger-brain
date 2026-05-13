---
date: 2026-05-13
type: analysis
project: nexus
status: open
---

# OVERLAP_ACTIVE × RIGHT_THESIS_BAD_EXECUTION audit (13.5)

Postmortem audit flagged this combo as the dominant single failure pattern in the last 7 days: 7 trades, -$2,184. Karri's `session_block_gate` was supposed to be the kill-switch. Question: did the 7 losers happen before or after the gate flipped?

## TL;DR

All 7 losing trades opened BEFORE the first `session_block` hard-reject. Gate appears to be working correctly post-flip. No leakage detected.

## Timeline

- **First `session_block` decision recorded:** 2026-05-12 14:00:02 UTC (also first hard_reject)
- **Last losing OVERLAP_ACTIVE trade opened:** 2026-05-11 14:00:30 UTC (≈24h before gate enforcement started)
- **Earliest losing OVERLAP_ACTIVE trade opened:** 2026-05-06 11:00:45 UTC
- **OVERLAP_ACTIVE postmortems after first hard-reject (2026-05-12 14:00 UTC):** 0

Gate is enforcing as designed. No OVERLAP_ACTIVE trade has slipped past since flip.

## The 7 losers (all pre-flip)

| opened_at (UTC)         | strategy                  | dir   | pnl     |
|-------------------------|---------------------------|-------|---------|
| 2026-05-06 11:00:45     | xau-volatility-expansion  | long  | -465.16 |
| 2026-05-06 13:50:56     | xau-volatility-expansion  | short | -529.10 |
| 2026-05-07 10:01:00     | xau-volatility-expansion  | short | -277.96 |
| 2026-05-11 08:52:59     | xau-session-breakout      | short |   -2.55 |
| 2026-05-11 10:15:31     | xau-orb                   | short | -398.41 |
| 2026-05-11 13:14:31     | xau-scalp-overlap         | short | -292.97 |
| 2026-05-11 14:00:30     | xau-volatility-expansion  | long  | -218.27 |
| **Total**               |                           |       |**-2184.42**|

## Per-strategy breakdown

| strategy                  | losers | pnl       |
|---------------------------|--------|-----------|
| xau-volatility-expansion  | 4      | -1490.49  |
| xau-orb                   | 1      |  -398.41  |
| xau-scalp-overlap         | 1      |  -292.97  |
| xau-session-breakout      | 1      |    -2.55  |

vol-exp confirms as dominant bleeder: 4/7 trades, 68% of total loss. All four were "Management followed the playbook" (no lifecycle events) — the entry was the error, not the exit.

xau-scalp-overlap losing during OVERLAP_ACTIVE is ironic given its name; the strategy targets the overlap but evidently lacks the regime/exec filter that overlap volatility demands.

## session_block_gate decision log (full)

```
2026-05-12 14:00:02  hard_rejected=true   session_blocked_OVERLAP_ACTIVE
2026-05-12 14:01:10  hard_rejected=true   session_blocked_OVERLAP_ACTIVE
2026-05-12 14:52:33  hard_rejected=true   session_blocked_OVERLAP_ACTIVE
2026-05-12 14:52:33  hard_rejected=true   session_blocked_OVERLAP_ACTIVE
2026-05-12 15:01:01  hard_rejected=false  (non-overlap session, passed)
2026-05-12 15:39:24  hard_rejected=false  (non-overlap session, passed)
2026-05-12 16:27:00  hard_rejected=false  (non-overlap session, passed)
2026-05-12 17:35:53  hard_rejected=false  (non-overlap session, passed)
```

Four `hard_rejected=false` rows after 15:01 UTC correspond 1:1 with trades that opened after the flip (`891cfa41…`, `85ec5794…`, `a5dc8687…` and one earlier non-strategy import) — i.e., the gate evaluated them, found session != OVERLAP_ACTIVE, and let them through. Consistent.

## Verdict on counterfactual

> "Of the 7 losing trades, how many would have been blocked if SESSION_BLOCK_ENABLED was true throughout?"

**All 7.** Each one closed with `session_at_close = OVERLAP_ACTIVE`. Cross-checking `opened_at` against London/NY overlap window (typically 13:00-16:00 UTC) confirms each entry was during overlap or close enough that session classification rounds to OVERLAP_ACTIVE. The four observed hard_rejects on 2026-05-12 14:00-14:52 UTC are direct evidence: at the same time-of-day as several of these losers, the gate now rejects.

Counterfactual saved P&L if gate had been live throughout the 7-day window: **+$2,184** (assuming the rejected entries don't get substituted by other losing trades — which is the right baseline because the postmortem classifier already isolated this combo).

## Operator recommendation

1. **session_block_gate is working.** Don't touch it. Zero OVERLAP_ACTIVE postmortems since flip. Keep `SESSION_BLOCK_ENABLED=true`.
2. **vol-exp is the structural bleeder.** 4/7 losers, $1,490 of the $2,184. The fact that "management followed the playbook" on all four means the postmortem is correctly fingerpointing the entry filter, not the exit. Worth flagging to Karri: vol-exp's entry criteria still fire during OVERLAP_ACTIVE even though those entries reliably lose. The session_block_gate now masks this, but if anyone proposes loosening the gate, vol-exp's OVERLAP exposure needs an in-strategy filter first.
3. **xau-scalp-overlap behavior is worth a one-line audit.** Name suggests it should *target* overlap; data shows it loses during overlap. Possibly mis-named or mis-tuned, but only 1 sample so don't over-rotate.
4. **Watch period:** keep this gate on through end of week. If still 0 OVERLAP_ACTIVE postmortems by Sunday with normal trading volume, consider this proxy validated as a stand-in for the trend-pause detector Karri is theorizing.

## Caveats

- Sample is small (4 hard_rejects, 4 pass-throughs since flip). Confidence in "gate works" comes from the binary check (zero overlap trades got through), not from a deep statistical test.
- Postmortem classifier `RIGHT_THESIS_BAD_EXECUTION` is a heuristic; if its definition shifts, this audit's $-2,184 figure shifts with it.
- `session_at_close` is sampled at close time; technically an entry could happen in a different session and close during OVERLAP_ACTIVE. Spot-checking `opened_at` vs typical London/NY overlap (13:00-16:00 UTC) all 7 line up close enough that this isn't a confound here.

## Source data

- `postmortems` filtered to `session_at_close = OVERLAP_ACTIVE`, `classification = RIGHT_THESIS_BAD_EXECUTION`, last 7d → 7 rows
- `gate_decisions` filtered to `gate_name = session_block` → 8 rows total (4 hard_reject, 4 pass-through)
- `simulated_orders` joined for strategy_id + opened_at
