# F5 fix audit — backfillClosedTrades idempotency hardening

**Date:** 2026-05-13 (round 6)
**Trigger:** F5 (MEDIUM) from round-5 `duplicate_row_audit.md` — latent re-occurrence vector for `oanda_backfill_<id>` twins. Pre-req before activating lesson-loop.
**Scope:** bug-fix (no proposal needed per CLAUDE.md "bug fixes that restore intended behaviour").
**Author:** Claude (round 6, F5 implementation)

---

## Summary

Hardened `backfillClosedTrades` in `apps/worker/src/firm/oanda-sync.ts` (Section 7) with a second idempotency layer that triangulates closed UUID rows whose `oanda_trade_id` is NULL. The pre-fix code only checked `WHERE oanda_trade_id = $1`, missing rows that closed via stale-exit / MANUAL_GHOST_CLOSE before any sync cycle linked them. Result was the 8 historical twin rows cleaned 2026-05-08 by `60a627d`; without the harden, a single race in production could re-poison the dataset between cleanups.

## Files modified

| File | Change |
|---|---|
| `apps/worker/src/firm/oanda-sync.ts` | +60 −4. Added `_backfillClosedTradesForTests` export (test-only helper, matching the existing `_*ForTests` convention). In `backfillClosedTrades` (Section 7), added layer-2 idempotency check after the existing `oanda_trade_id` SELECT misses: SELECT closed UUID rows with `oanda_trade_id IS NULL` matching `direction = $1 AND ABS(EXTRACT(EPOCH FROM (opened_at - $2))) <= 5 AND ABS(entry_price::numeric - $3::numeric) <= 1.00`, ordered by closest opened_at. On match → UPDATE the row's `oanda_trade_id` to link it (counts as `existing += 1`, no INSERT). UPDATE failure falls through to the original INSERT path (no worse than pre-fix). |
| `apps/worker/src/firm/oanda-sync.test.ts` | +137. Added `_backfillClosedTradesForTests` import + 2 new tests under a Section 7 banner. Uses `withMockedFetch` (existing harness) for `getClosedTrades` and an in-line `mkBackfillDb()` Pool mock that returns scripted rows for each SELECT pattern. |

## Test cases added

1. **Test A — UPDATE-link path.** Seeds the fetch mock with one closed OANDA trade (ticket 548 reconstruction). DB mock returns 0 rows for the `oanda_trade_id` SELECT and 1 row for the triangulation SELECT. Asserts: `inserted = 0`, `existing = 1`, no `INSERT INTO simulated_orders` query was emitted, one `UPDATE simulated_orders SET oanda_trade_id` query was emitted with params `[orphanRowId, "548"]`. Regression-guard for the 8 historical pairs.
2. **Test B — INSERT path (regression-guard).** Same fetch mock, DB mock returns 0 rows for BOTH SELECTs. Asserts: `inserted = 1`, `existing = 0`, exactly one `INSERT INTO simulated_orders` emitted with row id `oanda_backfill_548`, no `UPDATE-link` query emitted. Guards against the harden accidentally suppressing legitimate backfills.

## Verification

- `cd apps/worker && npx tsc --noEmit` — clean (no output).
- `npm test` — 544 / 544 pass (542 baseline + 2 new). Duration ~33s.

## Commit

- `e91731a` — `fix(oanda-sync): harden backfillClosedTrades idempotency against NULL-oanda_trade_id UUID twins`. Husky pre-commit hook ran `tsc apps/worker` — OK. Not pushed (operator OK-kjør gate).

## Coordination note

A sister firm-tab session committed `61afd28` (`fix(worker): firehose COPY + lesson-derivation idempotency ordering`) concurrently around 11:29:04. The two `git commit` calls raced; my staged files briefly landed under the sister's message. Resolved via local `git reset --soft HEAD~1` → re-stage and re-commit each scope separately, preserving the sister's commit message verbatim (saved from `git log -1 --format=%B`). Both commits now sit cleanly on `main` ahead of `origin/main`. No work lost. Future preventive: serialize `git commit` across firm-tabs via a flock on `.git/index.lock` — but that's an ops follow-up, not part of this fix.

## Lesson-loop unblock

With this fix in place, the round-5 recommendation to activate lesson-loop is now safe to proceed with — provided the loop joins on `oanda_trade_id IS NOT NULL` and excludes `execution_source = 'oanda_backfill'` from training (per round-5 §"Lesson-loop activation decision"). Recommend awaiting operator OK-kjør before pushing `e91731a`.
