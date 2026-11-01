---
date: 2026-05-11
project: nexus
type: test-coverage
area: strategy-blade
audit-closes: audit-2026-05-11 "0 unit tests on critical safety path"
---

# Strategy-blade gate tests — coverage uplift

## What landed

Extended `apps/worker/src/firm/strategy-blade.test.ts` with 15 new tests covering the 4 gates already wired in `strategy-blade.ts`. No production logic changed.

- **File**: `/home/nithu/code/ai-assistent/apps/worker/src/firm/strategy-blade.test.ts`
- **Lines**: 600 (was ~196)
- **Tests in file**: 22 total (7 pre-existing + 15 new)

## New tests (15)

**Env-var defaults (smoke / 3)**
1. `_internal.isEnabled: defaults to false when STRATEGY_BLADE_ENABLED unset`
2. `_internal.isEnabled: parses 'true'/'1'/'yes' as enabled`
3. `_internal.isEnabled: unrecognised values fall back to false`

**EVENT_POLICY gate (3)**
4. when flag false, gate is skipped (no event_policy in checks)
5. when flag on + no events in DB, gate passes with state=CLEAR
6. DB error is non-fatal — gate stays open

**NEW_GATES gate (4)**
7. when flag false, gate is skipped
8. soft-log mode — wouldReject hit does NOT block trade
9. hard gate on + matching reject criteria → blade rejects (via `RISK_LEVEL_HARD_GATE_ENABLED=true`)
10. `persistGateDecisions` is invoked (mock DB records `INSERT INTO gate_decisions`)

**FORGE_CHECK gate (3)**
11. when flag false, gate is skipped
12. pass-through when no open positions + healthy regime
13. DB error is non-fatal — gate stays open

**Cross-gate (2)**
14. per-gate independence: only enabled gates appear in `checks[]`
15. `eventSizeMultiplier` defaults to 1.0 when EVENT_POLICY off

## Verify results

- `cd apps/worker && npx tsc --noEmit` — **clean (0 errors)**
- `cd apps/worker && npm test` — **427 pass / 1 fail / 428 total**
  - 1 fail is pre-existing in `research-drainer.test.ts` (regex `/FOR UPDATE SKIP LOCKED/` not matching the UPDATE-recover query). Same failure was present in baseline before my changes — unrelated to this work.
  - All 22 strategy-blade tests pass.
- Baseline was 412 pass / 1 fail / 413 total → delta +15 passing tests / 0 new failures.

## Test approach

- Uses project standard `node:test` + `node:assert/strict` (task brief said Vitest but project does not use Vitest — `apps/worker/package.json` runs `node --test --import tsx`). Matched existing pattern in `postmortem-r-multiple.test.ts`.
- Mock `Pool` via `{ query: async () => ({ rows: [], rowCount: 0 }) } as unknown as Pool`.
- Mock `Blackboard` via plain object with `publish`/`latest`/`read` stubs.
- Per-gate isolation by toggling sibling `STRATEGY_BLADE_*` flags off so failures are attributable.
- `clearAllEnv()` before + after every test to avoid env leak between cases.
- Added `setImmediate` flush before asserting on the detached `persistGateDecisions().catch()` call.

## Places that would have required refactor (follow-up flags)

These were skipped per scope guard ("write the simplest test you CAN"):

1. **EVENT_POLICY BLACKOUT branch** — would need a DB-fixture row in `economic_events` with `event_at` inside `blackoutLeadMinutes`. Currently only CLEAR is exercised. Not a refactor blocker — just needs a richer mock-DB that responds to the specific SELECT used by `findNearestHighImpact`. Add to follow-up backlog.
2. **FORGE_CHECK reject paths** — `performPortfolioCheck` has rich rejection codes (`reject_open_cap`, `reject_floor_breached`, `resized_*`, etc.). Each needs simulated_orders fixture rows. Same story: not coupled, just verbose. Coverage today is the pass path + error path. Follow-up: pattern a `makeFixtureDb({ openPositions: [...] })` helper and add reject-path tests.
3. **NEW_GATES other hard flags** — only `RISK_LEVEL_HARD_GATE_ENABLED=true` is exercised in the reject case. `SCALP_OVERLAP_ASIA_BLOCK`, `RANGING_CONVICTION_GATE_ENABLED`, `ENTRY_STACK_COOLDOWN_ENABLED` are exercised indirectly through soft-log paths but not asserted in hard-reject mode. Straightforward to add — but those gates have their own dedicated unit-test file (`src/firm/gates/new-gates.test.ts`), which already covers them. Not duplicated here.

None of these require `strategy-blade.ts` itself to change — they're test-fixture work only.

## Commit

`0137e0b` — committed locally, **not pushed** (per "NO push" constraint).

```
test(strategy-blade): smoke + per-gate unit tests
```
