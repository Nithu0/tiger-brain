---
type: living-state
subsystem: metadata-stamping
last_verified: 2026-05-11T15:30Z
status: 🟡
---

# Metadata Stamping — Living State

Every simulated order must be stamped with attribution metadata at entry time. NULL columns mean we can't attribute PnL — Foundation Rule 2 (metadata coverage) reads this.

## Current state (verified 2026-05-11)

- **Fix deployed**: commit `0ad348f` — worker INSERT now writes all required attribution columns
- **Historic backfill**: 59 trades backfilled via `scripts/backfill/2026-05-11_strategy-id-backfill.ts` per runbook
- **Foundation Rule 2**: 🟡 yellow — awaiting first POST-deploy trade to flip to 🟢
- **Likely state**: 0 post-deploy stamped trades until next London/NY session-open

## Required columns at entry (canonical)

- `signal_id` — UUID of the originating signal
- `strategy_id` — UUID of the strategy module that produced the signal
- `execution_source` — text enum (e.g. `firm-orb`, `firm-scalp`, `legacy`)
- `regime_at_entry` — text enum (`trend`, `mean-revert`, `chop`, `news`, etc.)
- `entry_conviction_score` — float (0..1)
- `atr_at_entry` — float (ATR value at entry, basis for stop sizing)

See `docs/ref/position-metadata.md` for full column list + regime-aware stale-exit columns.

## Recent changes

- 2026-05-11: `0ad348f` — metadata-strip fix on firm-strategy INSERT path deployed
- 2026-05-11: 59 historical trades backfilled (`strategy_id` derived from `signal_id` lookup)

## Health indicators

- Post-deploy: all NEW `simulated_orders` rows have all 6 required columns NOT NULL
- Historical (pre-2026-05-11): 59 backfilled rows present with derived attribution
- Foundation Rule 2 flips 🟢 when verification SQL returns ≥ 1 row

## Open issues

- [ ] **Awaiting first post-deploy trade** — typically next session-open. When ≥1 row appears, flip foundation gate rule 2 to 🟢 in `docs/ops/phase-status.md`, [[foundation-gate-state]] and this doc
- [ ] T+24h confirm: zero NULL `strategy_id` rows on new trades

## Incident history

- **2026-05-04 → 2026-05-10 bleed**: all 28 trades from this period had `strategy_id`, `execution_source`, `regime_at_entry`, `entry_conviction_score`, `atr_at_entry` all NULL. Root cause: strategies silently skipping ~50% of cycles; firing path didn't stamp metadata. Fix: f551c17 (path-not-skipping) + 0ad348f (INSERT-writes-attribution).
- **Backfill 2026-05-11**: 59 historical rows recovered via signal_id → strategy lookup.

## Verification SQL

```sql
-- post-deploy null check
SELECT count(*) FROM simulated_orders
WHERE strategy_id IS NULL
  AND created_at > now() - interval '24 hours';
```

Expected: 0.

```sql
-- foundation rule 2 confirmation
SELECT count(*) AS stamped_trades,
       max(created_at) AS latest_trade
FROM simulated_orders
WHERE created_at > '2026-05-11T<deploy-time>'::timestamptz
  AND strategy_id IS NOT NULL
  AND execution_source IS NOT NULL
  AND atr_at_entry IS NOT NULL
  AND entry_conviction_score IS NOT NULL;
```

Expected: stamped_trades ≥ 1 once a session-open trade lands.

## What never auto-fires

- Backfilling without dry-run per [[Runbook-Backfill-Script-Pattern]]
- Dropping NULL rows to clean the metric ([[Operator-Principles]] rule 2 — data never stops)
- Auto-disabling strategies not stamping properly. Fix the stamping, not the strategy

## Sibling state to watch

- `signals` table — same metadata requirements at signal time
- `analysis_snapshots` — fact-agents stamp similar attribution

Linked to: [[Nexus-MOC]], [[Foundation-Gate]], [[foundation-gate-state]], [[production-loop-state]], [[Module-Position-Management]], [[Runbook-Backfill-Script-Pattern]], [[Operator-Principles]] (rule 2: data never stops), [[Truth-Hierarchy]] (`simulated_orders` SQL above this snapshot), [[When-Trade-Bleeds-Multi-Day]]
