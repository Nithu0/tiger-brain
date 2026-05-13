---
date: 2026-05-13
type: audit
project: nexus
status: open
reviewer: karri
---

# Position-management BE-trigger audit — Scenario B (sampling, not behavior)

## TL;DR

`peak_price` is sampled **once per orchestrator cycle** (30s – 10min depending on session). For fast intra-cycle moves it materially under-reports true MFE. The 12 vol-exp RIGHT_THESIS_BAD_EXECUTION conclusion ("never reached +1R MFE") is partly a measurement artifact: peak_price is a lagging discrete poll of price, not a high-water mark from a tick stream.

## Code paths

- `apps/worker/src/firm/position-management/lifecycle.ts:344-348` — peak update logic. `pos.peakPrice ?? pos.entryPrice`, then `Math.max(peak, price)` for long / `Math.min` for short. Persists if changed.
- `apps/worker/src/firm/position-management/manager.ts:289-292` — DB write of `peak_price` on every cycle decision.
- `apps/worker/src/firm/orchestrator.ts:742-770` — `monitorPositions()` calls `manageFirmPositions()` exactly **once per cycle**, with `currentPrice` being a single OANDA spot fetch (or blackboard fallback).
- `apps/worker/src/firm/session-window.ts:185-205` — cycle cadence: 30s (London/NY open), 60s (pre-open), 120-180s (NY-AM, NY-PM, NY-late), 300s (Asia), 600s (overnight).
- BE trigger: `rules.ts:21 triggerRmult: 1.0`. Lifecycle fires `BREAK_EVEN` on the **same cycle** rMult ≥ 1R is observed — so a poll showing peak=0.95R then close at 1.1R won't trigger BE if next poll is past TP.
- Vol-exp specifically: `isLetRunStrategy` skips PARTIAL_TP1/TP2 and TRAILING, so **BE is the sole protection lever** for this strategy.

## Evidence from `simulated_orders` (last 30d, closed_at IS NOT NULL, n=156)

```
total trades                                                          156
peak_price IS NULL (any reason)                                       100
  └─ OANDA_BACKFILL (expected — no firm tracking)                      79
  └─ non-backfill (worker should have polled at least once)            21
peak_price IS NULL AND duration > 10 min                               83
  └─ implies cycle ran but never wrote peak_price for that row,
     OR backfill rows dominate; 4/21 non-backfill nulls had dur > 60min
```

Non-backfill nulls (sample): id `a5dc8687` 141 min (session-breakout), `85ec5794` 54 min (vol-exp), `4d9f4960` 95 min (vol-exp), `eafbd640` 137 min (vol-exp). These trades lived through 10+ cycles yet `peak_price` was never written. **Either the row was never reloaded (e.g. signal_id JOIN failure) or the favorable side never advanced past `entry_price` on any single poll** (less likely over 137 min).

### Smoking gun — peak < close on winners

For `close_reason='OANDA_SL_TP'` with peak non-null and signed_realized_r > 0 (broker TP hit, true winner):

| id (short) | dir | peak MFE-R | signed realized R | dur min |
|---|---|---|---|---|
| `eee56af6` | long | 1.59 | 1.57 | 6.4 |
| `7db8fe10` | long | 1.85 | 1.69 | 23.5 |
| `6c3cd86d` | long | 1.16 | **1.56** | 65.1 |
| `270be3eb` | long | 1.12 | 0.53 | 105.1 |

`6c3cd86d` is the killer: realized > peak. Impossible unless `peak_price` missed the actual TP touch. Confirms peak_price is a discrete poll, not a true high-water mark.

### Average MFE-R distribution (peak-based)

```
strategy_id                  n   null_peak   avg_mfe_r   max_mfe_r   reached_1r   be_applied
xau-volatility-expansion    41          9        0.53        1.63            3           13
xau-session-breakout        14          3        0.23        0.37            0            1
xau-scalp-overlap            7          3        0.04        0.04            0            2
xau-orb                      5          2        0.04        0.04            0            0
```

Note: `be_applied=13` for vol-exp vs `reached_1r=3` via peak — the 10-trade gap is BE firing during a cycle where realtime price was at 1R but the persisted peak_price wasn't (BE uses live `currentPrice`, not peak_price). So BE-trigger fires correctly on the cycle it sees ≥1R; peak_price simply lags as a recorded artifact.

By close_reason:

```
close_reason       n     avg_mfe_r   reached_1r   reached_0.8r   be_applied
OANDA_BACKFILL    79     null            0             0             0
OANDA_SL_TP       54     0.72            7             7            18
STALE_TRADE_EXIT  14     0.26            0             0             0
```

## Diagnosis: A or B?

**B — peak_price column is sampled too coarsely.** Two failure modes stacked:

1. **Sampling bias**: cycle interval (30s – 10min) misses intra-cycle wicks. For a vol-exp trade entering near London open and resolving inside 5 minutes, peak_price may only be written once or never.
2. **Null-peak rows**: 21 non-backfill closed rows have `peak_price IS NULL` despite > 0 cycle of life. Two possible roots: row missed the `WHERE status='open'` window (closed within the same cycle it opened), or peakPrice only writes when `newPeak !== peak` (lifecycle.ts:348) and on the very first cycle `peak = entryPrice`, then current price was at or worse than entry. Net effect identical: MFE evidence missing.

The 12 RIGHT_THESIS_BAD_EXECUTION conclusion is **partially valid** (some vol-exp trades genuinely never reached 1R — see `891cfa41` short with MFE=0.11R over 89 min) but **statistically biased low** because the peak_price column under-counts.

## Proposed fix (Karri review)

Replace cycle-polled `peak_price` with **broker-side MFE** from OANDA per-trade `unrealizedPL` or candle high/low scan over the open interval:

- **Cheap fix**: at trade close (`closed_at` set), backfill `peak_price` by scanning the OANDA 1-minute candle high/low between `opened_at` and `closed_at` for the favorable side. One bulk query. Add as a `peak_price_resolved_at` column to distinguish live-poll from backfilled.
- **Better fix**: subscribe to OANDA stream for open positions and update peak in a sub-cycle (5s) loop. More complex, real-time, no broker-API-cost increase if same connection.
- **Decision lever this unlocks**: vol-exp RIGHT_THESIS_BAD_EXECUTION reclassification — true count is likely lower than 12. May validate Karri's earlier claim that BE-trigger "works in principle but never activated in practice" was a measurement artifact.

## Open questions

- Should `peak_price` be renamed `peak_price_polled` and a new `peak_price_true` column added (resolved from broker candles at close)?
- Does any downstream agent (vol-exp execution-leak, postmortem.ts) treat peak_price as authoritative? `postmortem.ts:250` reads it directly — its conclusions inherit this bias.
- BE-trigger uses `currentPrice` (live, not peak_price) — so the live BE behavior is correct; only the MFE *audit/postmortem* path is biased.

## Files touched (read-only investigation)

- `apps/worker/src/firm/position-management/{manager,lifecycle,rules,types,classifier}.ts`
- `apps/worker/src/firm/orchestrator.ts:740-770`
- `apps/worker/src/firm/session-window.ts:180-210`
- `apps/worker/src/firm/postmortem.ts:240-290`
