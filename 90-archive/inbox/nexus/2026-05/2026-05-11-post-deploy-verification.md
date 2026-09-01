---
date: 2026-05-11
type: deploy-verification
commits: 1bb20f8..34d5f3f
status: deployed; awaiting first post-deploy trade
---

# Post-deploy verification — 34d5f3f (metadata-strip fix)

## Build commit shift

- **Before**: 3ab8b61a (HEAD prior to operator push of 8 commits)
- **After**: `34d5f3f1` (confirmed live on Railway)
- **Verification time**: 2026-05-11T11:46:26Z (initial /health) → still 34d5f3f1 at 11:50:48Z
- **Deploy duration**: push happened around 11:43Z window; build commit was already live by 11:46:26Z (first /health call after 180s sleep). So Railway build+deploy ≈ ≤3 min from push to live.
- **deployedAt field**: still `null` in /health JSON. Not load-bearing but worth noting (no regression — also null on previous deploys).

## Worker health

| Metric | Value |
|---|---|
| Build commit | `34d5f3f1` |
| Last cycle # | 8 → 9 → 11 → 12 (advancing normally) |
| Cycle duration | 2.6s–9.8s (healthy band) |
| lastError | `null` |
| Heartbeat | 21–56s old (well under stale threshold) |
| Broker | OK (demo, balance 92643.5338) |
| DB | OK (latency 4ms) |
| Reconciliation | OK, driftCountUnresolved=0, balanceDelta=13.62 |

## Metadata stamping (the load-bearing check)

**No new trades since deploy.** Last `simulated_orders` row opened at **2026-05-11T10:15:31Z** — that's ~1h 28min BEFORE the deploy (11:43Z). Cannot yet verify the fix worked against fresh data.

### Pre-deploy state on existing rows (control)

All 10 most-recent `simulated_orders` rows show:
- `execution_source` = NULL
- `strategy_id` = NULL
- `atr_at_entry` = NULL
- `entry_conviction_score` = NULL
- `portfolio_regime_at_entry` = `TRENDING` / `RANGING` / `NULL` (this one was getting stamped, others were not)

Today's 4 trades (04:16, 06:47, 08:52, 10:15 UTC) all have the same NULL pattern → confirms the metadata-strip bug WAS present pre-deploy.

### Open positions

- 1 open trade (id 7eebe4f7…, opened 10:15Z, strategy pre-deploy = no metadata).

## gate_decisions / blade_decisions cadence

- **gate_decisions**: last write 10:15:31.318Z; 16 rows in last 24h; 0 in last 1h.
- **blade_decisions**: last write 10:15:31.318Z; 4 rows in last 24h (matches 4 trades); 0 in last 15min / 1h.

These tables only get written when a strategy emits a candidate (not every cycle). Sparse cadence is **expected** given strategies are gated and XAUUSD trends rarely align with their setups every cycle. Not a regression signal on its own.

## Market data ingestion

- `lastMarketRawSec` = 55–58s (fresh, ticking each minute)
- Blackboard ingest pipe healthy

## Top concern

**Cannot verify metadata fix until a strategy fires post-deploy.** It is Monday London session (DOW=1, 11:50Z = ~12:50 London time = mid-London-session). Strategies should fire today; whenever the next trade lands, recheck `execution_source`, `strategy_id`, `atr_at_entry`, `entry_conviction_score`. If those are still NULL on a row with `opened_at > 11:43Z`, the fix did NOT take.

Secondary watch:
- `decisionCycleId` is also missing on gate_decisions (`decision_cycle_id` = null on all 3 recent samples). Separate issue, not blocking.
- `deployedAt` in /health is null — minor; build commit is the authoritative shift indicator.

## Recheck checklist (when next trade lands)

```sql
SELECT id, opened_at, execution_source, strategy_id, atr_at_entry,
       entry_conviction_score, portfolio_regime_at_entry
FROM simulated_orders
WHERE opened_at > '2026-05-11T11:43:00Z'
ORDER BY opened_at DESC;
```

All four metadata columns should be non-NULL. If they are, fix landed. If `execution_source` and `strategy_id` are still NULL but `atr_at_entry` and `entry_conviction_score` are populated, partial fix — strip happened elsewhere in the pipeline.
