# Postmortem streak-table Phase 1 landed (2026-05-11)

**Commit:** `a53598b`
**Proposal:** `docs/strategy/proposals/2026-05-11_postmortem_size_down_feedback.md`
**Reviewer:** Karri
**Phase status:** Phase 1 of 3 implemented. Phase 2 (shadow-log) + Phase 3 (live 0.5x scale-down on streak>=2) deferred per proposal staging.

## What landed

1. **Schema migration** added to `DB_MIGRATIONS` array in `packages/shared/src/db/schema.ts`:
   ```sql
   CREATE TABLE IF NOT EXISTS postmortem_streaks (
     strategy_id            TEXT PRIMARY KEY,
     last_postmortem_class  TEXT,
     consecutive_count      INTEGER DEFAULT 0,
     last_updated           TIMESTAMPTZ DEFAULT NOW()
   )
   ```
   Auto-applies on next worker boot.

2. **Postmortem-hook wired** (`apps/worker/src/firm/postmortem-hook.ts`):
   - Added `strategy_id` to SELECT + ClosedTradeRow interface.
   - After postmortems-table mirror, performs UPSERT into `postmortem_streaks`:
     - Same class as previous → `consecutive_count + 1`
     - Different class → reset to 1
     - Always updates `last_updated = NOW()`
   - Non-fatal: any error logged via `logWarn`, postmortem flow continues.

3. **NO env-flag.** Observation-only schema. Zero behavioral impact on sizing.

## Behavior

- Triggers once per closed trade that goes through `runPostmortemForNewlyClosedTrades`.
- Strategy without `strategy_id` (null) is skipped silently — no row created.
- Same orchestrator-cycle atomicity is fine: UPSERTs are independent per strategy_id.

## Verify after 7d (operator query)

```sql
-- Strategies currently on a streak (Phase 1 review trigger)
SELECT strategy_id, consecutive_count, last_postmortem_class, last_updated
FROM postmortem_streaks
WHERE consecutive_count >= 2
ORDER BY consecutive_count DESC, last_updated DESC;

-- Full distribution for Karri to calibrate Phase 2 thresholds
SELECT last_postmortem_class, consecutive_count, COUNT(*) AS strategies
FROM postmortem_streaks
GROUP BY last_postmortem_class, consecutive_count
ORDER BY last_postmortem_class, consecutive_count;

-- Sanity: row count + freshness
SELECT COUNT(*) AS rows, MIN(last_updated) AS oldest, MAX(last_updated) AS newest
FROM postmortem_streaks;
```

## Verification

- `cd packages/shared && npx tsc --noEmit` → clean
- `cd apps/worker && npx tsc --noEmit` → clean
- `cd apps/worker && npm test` → 488/488 pass (488 not 478 — main has gained tests since proposal was written)

## Notes for Karri after 7d data

- Phase 2 trigger from proposal: `streak >= 2 AND last_tag == RIGHT_THESIS_BAD_EXECUTION`.
- Phase 2 is shadow-mode (log "would-scale" decisions, no live sizing) gated by `POSTMORTEM_RISK_FEEDBACK_ENABLED=false`.
- Phase 3 (live 0.5x scale-down) requires Karri-OK on 14d shadow-data per proposal.

## Rollback

- Truncate table — no behavioral impact, additive only.
- Code-revert: single commit (`a53598b`) reverts cleanly.

## Caveat noted during commit

`docs/ops/phase-status.md` got swept into this commit by a parallel session that had pre-staged it before my `git add`. Content of that diff is Karri's review-runde summary (5 new TIER 1 proposals including this one), so it's contextually adjacent — not a regression — but flagging it so it's not a surprise on inspection.
