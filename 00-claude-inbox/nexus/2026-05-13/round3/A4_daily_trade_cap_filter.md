# A4 — Daily trade-cap filter widening

**Date**: 2026-05-13
**Agent**: round3 / A4
**File touched**: `apps/worker/src/firm/gates/daily-trade-cap-gate.ts` + test
**Status**: implemented locally, NOT committed (per instructions)

## Why

Round 2 found the cross-strategy daily cap counted only
`execution_source = 'firm_strategy'`. Over the last 60 days production
holds:

| execution_source | rows |
|---|---|
| NULL (legacy / pre-tagging) | 79 |
| firm_strategy | 67 |
| firm_blade | 6 |
| oanda_backfill | 3 |
| oanda_import | 1 |

`firm_blade` and the legacy NULL rows silently bypassed the cap. Dormant
today (ORB_ONLY_MODE=true), but a leak the moment `managers.ts` re-enables
legacy paths or strategy-blade ramps back up.

## Decision: allow-list, not deny-list

Allow-list (`IN ('firm_strategy','firm_blade') OR IS NULL`) chosen over
deny-list. Rationale: a deny-list (`NOT IN ('oanda_backfill','oanda_import')`)
fails open the moment a new sync tag is added (e.g. `oanda_resync`). New
strategy paths are added deliberately and reviewed; new sync paths slip in.
Allow-list forces explicit opt-in for anything that should count.

## Diff — SQL predicate

Before:
```sql
WHERE opened_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC')
  AND execution_source = 'firm_strategy'
```

After:
```sql
WHERE opened_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC')
  AND (execution_source IN ('firm_strategy', 'firm_blade')
       OR execution_source IS NULL)
```

Also updated:
- Header docstring — explains widening + allow-list rationale + A4
  changelog stamp.
- Block-detail string: `"firm-strategy trades"` → `"strategy trades"`
  (no test asserted on this substring).

## Test changes

`daily-trade-cap-gate.test.ts` invariant 7 (SQL shape pin):
- Replaced single-predicate regex with two assertions (IN-clause + IS
  NULL) plus a `doesNotMatch` against the old narrow `= 'firm_strategy'`
  predicate so a future revert is caught.
- All other tests untouched — they use mocked counts and don't care which
  rows the SQL selects.

## Verification

- `cd apps/worker && npm test` → **539 / 539 pass** (21.2s).
  (Higher than 478 baseline because parallel A-agents added tests this
  round; daily-trade-cap suite specifically all green.)
- `tsc --noEmit` worker-wide currently shows 1 unrelated error in
  `session-breakout/session-break-manager.ts:367` (parallel A2 mid-edit
  on ATR field — not my file). Reproduced with my changes stashed,
  confirming pre-existing.

## Rollout

No env-flag change needed — `DAILY_TRADE_CAP_ENABLED=false` in prod, so
this is dormant. When operator flips it on, cap now correctly covers all
real strategy executions.
