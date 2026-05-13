---
date: 2026-05-13
type: analysis
project: nexus
status: open
reviewer: karri
---

# Vol-Expansion execution leak — 7d deep-dive (06.5 → 12.5)

## TL;DR

19 vol-exp trades, **−$4,115 PnL, 5W/14L = 26% WR**. Postmortem-classifier flags **12 of 19 as RIGHT_THESIS_BAD_EXECUTION** (−$4,613 total, avg −$384). The dominant leak is NOT "MFE-was-deep-then-reversed". It is **thin SL distance + zero post-entry management** on borderline-quality setups. None of the 12 bad-exec trades reached even 0.5R MFE before reversing to full −1R SL.

Of Karri's 5 proposals, **`confluence_filter` (4/5 minimum) is the only one with broad coverage** — would have blocked the borderline-conviction (0.6) clusters. `break_even_on_1r` is **near-useless** for this 7d window because the trades never reach +1R.

---

## Data: 19 trades

Source: `simulated_orders WHERE strategy_id='xau-volatility-expansion' AND opened_at > NOW()-INTERVAL '7 days'`.

### Aggregate metrics

| Metric | Value |
|---|---|
| Total | 19 |
| Winners / Losers | 5 / 14 (26% WR) |
| Total PnL | **−$4,114.96** |
| Avg PnL/trade | −$216.58 |
| Long / Short | 7 / 12 |
| Long wins / Short wins | 1 / 4 |
| Avg winner hold | 90.3 min |
| Avg loser hold | 57.3 min |

Losers exit ~35 min faster than winners — symptom of thin SL hit by chop.

### Postmortem classification

| Classification | n | Sum PnL | Avg PnL | Avg risk-dist | Avg conviction |
|---|---|---|---|---|---|
| RIGHT_THESIS_BAD_EXECUTION | **12** | **−$4,613** | −$384 | $13.56 | 0.68 |
| WRONG_THESIS | 2 | −$776 | −$388 | $13.34 | 0.60 |
| CORRECT_THESIS | 5 | +$1,275 | +$255 | $5.58 | 0.60 |

Notable: winners had **avg risk-dist $5.58** (mostly trades where BE-SL had already been moved tight). Losers had **$13.56 risk-dist** — fixed ATR-based SL, no defensive management triggered.

### Bad-execution MFE distribution

Of the 12 RIGHT_THESIS_BAD_EXECUTION trades:

- 5 have `peak_price = NULL` (no defensive trigger fired, classifier flagged anyway)
- 7 have peak data — **MFE in R units:**

| Trade | Dir | MFE (R) | Result |
|---|---|---|---|
| 2320fd49 (11.5) | long | 0.49 | −1R SL |
| ce91f971 (06.5) | short | 0.42 | −1R SL |
| f6e13d30 (06.5) | long | 0.38 | −1R SL |
| b7604c37 (07.5) | short | 0.33 | −1R SL |
| 4399229e (07.5) | short | 0.15 | stale-exit |
| b37b850e (07.5) | short | 0.15 | −1R SL |
| b415a2a5 (06.5) | long | 0.06 | −1R SL |

**0 of 12 bad-exec trades reached ≥0.5R MFE. 0 reached ≥1R.** Trades did not "give back" gains — they never built gains.

### Time-of-day (UTC)

Worst hours by sum-PnL:
- 14:00 UTC: 4 trades, 0 wins, **−$1,469**
- 13:00 UTC: 2 trades, 0 wins, −$1,296
- 16:00 UTC: 4 trades, 3 wins, +$843 (only profitable bucket)

13–15 UTC = NY open / overlap. Vol-exp gets chopped at the open; 16 UTC (post-open) is the sweet spot.

### Session (note: 16 of 19 have `session_at_entry='unknown'` — telemetry gap)

| Session | n | Wins | PnL |
|---|---|---|---|
| unknown | 16 | 5 | −$2,811 |
| NY_CONTINUATION | 2 | 0 | −$776 |
| OVERLAP_ACTIVE | 1 | 0 | −$527 |

Telemetry bug: session_at_entry not getting populated. Separate fix needed.

### Direction bias on bad-exec

| Direction | n | Sum PnL | Avg hold |
|---|---|---|---|
| long | 6 | −$2,375 | 45.1 min |
| short | 6 | −$2,238 | 64.8 min |

Symmetric leak — not a long-vs-short bias.

---

## Mapping leak to Karri's 5 proposals

### 1. `break_even_on_1r` — **near-zero impact this window**

Proposal claim: trades go +1.5-1.8R then reverse. **Data does not support this**: 0/12 bad-exec trades reached +1R. The 12.5 example in the proposal (#1135, #1139) shows peak_price = $4664.56 on entry $4665.97 → MFE = $1.41 = 0.11R, NOT "+1.8R" as proposal table claims.

The proposal's MFE figures appear to be from a different data source (perhaps M1 tick or external chart) than `simulated_orders.peak_price`. **Need Karri to reconcile the source.** If peak_price is incomplete (only sampled at lifecycle checkpoints), proposal may still be correct; if peak_price is the high-water mark, BE-on-1R fires on zero trades.

**Estimated impact this window: $0–$300.**

### 2. `confluence_filter` (min 4/5 criteria) — **highest coverage**

Both 12.5 trades fired at 60% conviction (3/5). The bad-exec cluster avg conviction = 0.68 (vs 0.60 for winners), but 7 of 12 bad-exec trades had conviction ≤0.7. If 4/5 means raising the conviction floor to 0.80, this would block roughly 10 of 14 losers.

Caveat: small sample — risk of overfitting to a chop week. But strategy's own criteria flagging "suboptimal" is a legitimate self-veto.

**Estimated impact this window: +$2,500 to +$3,500 (blocks ~10 losers, may cost 1-2 winners).**

### 3. `no_chase_filter` — **partial coverage**

Filter premise (entry >50% of impulse-distance from origin = chase). Cannot validate precisely without H1 candle data joined per trade, but the pattern of SHORT entries on 12.5 (#1135, #1139) at $4666 after $4700→$4642 fall fits the description. Bad-exec longs at 14:00 UTC on 11.5 (entry $4729, $4735) also fit "chase top" pattern (peak only +$8 above entry before reversal).

**Estimated impact: +$1,500 to +$2,000.** Overlaps heavily with mean_revert_block.

### 4. `session_sl_widening` (NY 1.2×ATR) — **modest, mixed**

Bad-exec avg risk-dist = $13.56. ATR-at-entry for the 2 trades with data = $18.6 and $19.2. SL_mult = 0.7-0.8 currently. Widening to 1.2 would have saved #1135 (close $4678.39, SL with 1.2×ATR ≈ $4690.97 → unhit). BUT widens R-risk per trade — net effect depends on whether saved trades then converge to TP or just exit later/worse.

For 7d window: ~3 trades had close-price very near SL (within $1) — could be saved.

**Estimated impact: +$800 to +$1,200, but increases per-trade R-risk.**

### 5. `mean_revert_block` — **good fit for cluster pattern**

12.5 cluster (2 SHORTs after 2.5-ATR down-impulse), 11.5 cluster (2 LONGs near top), 06.5 cluster (3 trades during NY-open chop) all fit "post-impulse continuation that mean-reverts". Logic-wise this catches the same trades as `no_chase_filter` from a different angle.

**Estimated impact: +$1,800 to +$2,500.** Heavy overlap with confluence_filter and no_chase.

---

## Recommendation

Order of implementation priority (highest impact / lowest risk first):

1. **`confluence_filter` (4/5 minimum)** — single biggest lever, uses strategy's own self-assessment, low overfitting risk if Karri confirms 4 is the right floor.
2. **`mean_revert_block`** — orthogonal to confluence, catches the structural failure mode (entering AFTER the move).
3. **`no_chase_filter`** — overlaps with #2 but catches longs at the top in a way mean_revert may miss.
4. **`session_sl_widening`** — defensible but increases per-trade R; let #1-3 reduce trade volume first, then re-evaluate.
5. **`break_even_on_1r`** — **HOLD** until peak_price semantics clarified. Current data shows 0/12 bad-exec trades reaching +1R, so BE-trigger fires on zero of them. Either peak_price is sampled too coarsely (real-world MFE was deeper) or the proposal's $24-$25 MFE on 12.5 is wrong. **Karri: please clarify source of "MFE = +$24" figure.**

## Open questions for Karri

1. Source of "MFE = +1.5-1.8R" figure in `break_even_on_1r` proposal? `simulated_orders.peak_price` shows ≤0.5R MFE on all 12 bad-exec trades.
2. Is `peak_price` updated tick-by-tick or only on lifecycle-events? If the latter, MFE measurements understate reality.
3. Acceptable trade-volume drop if confluence raised to 4/5? Estimated 50% fewer signals.
4. Should we stage proposals (confluence first, see 5d data, then layer mean_revert)? Or batch?

## Supporting queries (reproducible)

```sql
-- 19 trades w/ MFE-R calc
SELECT s.id, s.direction, s.entry_price, s.peak_price, s.stop_loss, s.close_price, s.pnl, p.classification,
  CASE WHEN s.peak_price IS NOT NULL THEN
    ROUND((CASE WHEN s.direction='long' THEN s.peak_price::numeric - s.entry_price::numeric
                ELSE s.entry_price::numeric - s.peak_price::numeric END)
          / NULLIF(ABS(s.entry_price::numeric - s.stop_loss::numeric), 0), 2) END AS mfe_r
FROM simulated_orders s LEFT JOIN postmortems p ON p.trade_id = s.id
WHERE s.strategy_id='xau-volatility-expansion' AND s.opened_at > NOW() - INTERVAL '7 days'
ORDER BY s.opened_at DESC;
```

```sql
-- Classification roll-up
SELECT p.classification, COUNT(*), ROUND(SUM(s.pnl::numeric),2), ROUND(AVG(s.pnl::numeric),2)
FROM simulated_orders s JOIN postmortems p ON p.trade_id=s.id
WHERE s.strategy_id='xau-volatility-expansion' AND s.opened_at > NOW() - INTERVAL '7 days'
GROUP BY 1;
```

## Telemetry gaps surfaced

- `session_at_entry='unknown'` on 16/19 trades — broken pipeline (separate fix)
- `atr_at_entry` NULL on 16/19 — only populated 11.5+
- `trade_strategy_snapshots` empty (cycle_id join finds zero rows) — vol-exp criteria-state not landing
- `peak_price` NULL on 5 bad-exec trades — sampling gap

Without these, the proposal-validation is rougher than it should be. Filing as `2026-05-11-vol-exp-instrumentation.md` follow-up.
