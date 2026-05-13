---
date: 2026-05-11
project: nexus
type: test-coverage
area: firm/orchestrator
---

# Orchestrator unit tests — critical-path coverage gap closed

## Context

CI audit flagged `apps/worker/src/firm/orchestrator.ts` (665 lines, session-cycle manager) as **0% covered**. This is the heart of the firm — coordinates fact collection, analysis, synthesis, decision pipeline, strategy execution, retention, foundation-monitor, heartbeat, the lot. Zero tests was the largest coverage gap on the critical path.

## What landed

`apps/worker/src/firm/orchestrator.test.ts` — 11 smoke + step-flow tests covering:

1. `constructor produces sane defaults (cycle 0, board attached)`
2. `stop() before start() is a safe no-op`
3. `runCycle: increments cycle counter on every successful run`
4. `runCycle: heartbeat payload has cycleDurationMs + lastError fields`
5. `runCycle: heartbeat disabled permanently when firm_state table missing (42P01)`
6. `runCycle: skips when previous cycle still running (this.running guard)`
7. `runCycle: retention SKIPS when RETENTION_ENABLED is unset (default)`
8. `runCycle: retention FIRES once when RETENTION_ENABLED=true (then cached by date)`
9. `runCycle: foundation-monitor SKIPS when FOUNDATION_MONITOR_ENABLED unset`
10. `runCycle: foundation-monitor FIRES when FOUNDATION_MONITOR_ENABLED=true`
11. `runCycle: heartbeat is written in finally block (runs even when body throws)`

## Mock approach

Followed the `retention.test.ts` recording-db pattern:

- Stub `Pool` with a `query()` that captures `{ sql, params }` and returns
  `{ rows: [], rowCount: 0 }` by default
- Light `defaultRowsFor()` helper returns `[{ daily_pnl: "0" }]` for the
  getDemoMode SUM(pnl) probe so the cycle progresses past the early choke-point
- Real `Blackboard` instance used (just wraps the recording-db)
- `drainMicrotasks()` helper yields setImmediate 10x to let fire-and-forget
  `.catch()`-wrapped paths (heartbeat, retention, foundation-monitor) settle
- Env vars (`RETENTION_ENABLED`, `FOUNDATION_MONITOR_ENABLED`, ...) snapshotted
  in `beforeEach` and restored in `afterEach`

## Key fingerprints used for assertions

- **Heartbeat**: `sql.includes("firm_state")` AND `params.includes("worker:heartbeat")`
- **Retention fired**: `DELETE FROM sentiment_snapshots` (clean, not touched elsewhere)
- **Foundation-monitor fired**: `params.includes("foundation_monitor:last_state")`
- **`this.running` guard**: gated first `db.query` with a blocking promise so
  cycle #1 stayed in-flight; called `runCycle()` a second time and asserted
  zero new queries fired

## Results

| Metric | Before | After |
|---|---|---|
| Worker tests pass | 467 | **478** |
| Worker tests fail | 0 | 0 |
| `tsc --noEmit` (worker) | clean | clean |
| Orchestrator coverage | 0 tests | 11 tests |

Full suite: `npm test` in `apps/worker` → `tests 478, pass 478, fail 0, duration_ms ~11800`.

## Commit

`test(orchestrator): smoke + step-flow coverage (5-10 tests)` — pure test additions, no behaviour change to `orchestrator.ts`. **No push** (operator-gated per CLAUDE.md "OK kjør" rule).

## Caveats / what we explicitly did NOT cover

- Full Step 1/2/3 ordering (fact agents → analysis → prism → blade): out of scope
  per task prompt ("no entire firm mock"). Each module has its own tests.
- ORB / scalp / session-breakout / vol-expansion entry-evaluation paths: those
  modules have their own tests under `firm/orb/`, `firm/scalp-overlap/`, etc.
- `monitorPositions()` — short-circuits at line 688 when no price; not tested
  end-to-end (would need oanda-service or board.latest stubs).
- Strategy execution + notification dispatch: tested in their own files.

## What this UNLOCKS

The recording-db harness now exists in `orchestrator.test.ts`. Future test work
can:

- Add tests for the ORB_ONLY_MODE branch (line 458) — currently un-exercised
- Add tests for cycle-window transition (line 212) — Discord notify path
- Add tests for `runBlackboardTtlCleanup` (line 647) at the `cycleCount % 100`
  trigger
- Add tests for the demoMode shadow-publish path (line 489)

These were intentionally left out to keep the diff focused per scope.
