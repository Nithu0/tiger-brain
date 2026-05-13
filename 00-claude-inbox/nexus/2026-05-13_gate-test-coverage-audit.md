---
date: 2026-05-13
type: audit
project: nexus
status: open
---

# Gate test coverage audit

Read-only sweep of `apps/worker/src/firm/gates/` + cross-ref with `package.json` npm test list. Total in test list: **544 tests** (close to 542 baseline; drift since 90c5705).

## 1. Gate files vs tests

| Gate file | LOC | Test file | Tests (test/it) | In npm `test` list? |
|---|---:|---|---:|---|
| `new-gates.ts` (risk_level, scalp_overlap_asia, ranging_conviction, entry_stack_cooldown, session_block) | 281 | `new-gates.test.ts` | 39 | YES |
| `sl-cooldown-gate.ts` | 201 | `sl-cooldown-gate.test.ts` | 26 | YES |
| `daily-trade-cap-gate.ts` | 165 | `daily-trade-cap-gate.test.ts` | 16 | YES |
| `regime-direction-gate.ts` | 113 | `regime-direction-gate.test.ts` | 11 | **NO (orphan)** |
| `mean-revert-gate.ts` | 140 | _(none)_ | 0 | n/a |

Gate-specific tests in `gates/`: **92**. Plus 25 in `strategy-blade.test.ts` and 12 in `regime-direction.test.ts` (orphan) that exercise gate wiring.

## 2. Sub-gates inside `new-gates.ts` (5 sub-gates, all tested)

`risk_level` (5), `scalp_overlap_asia` (5), `ranging_conviction` (8), `entry_stack_cooldown` (7), `session_block` (10) + 3 persistence tests + 1 baseline.

## 3. Gates wired in `strategy-blade.ts`

Invocations found (all paths in `runCycle()` cross-strategy approval):

1. `evaluateSlCooldownGate` (line 96) + `persistSlCooldownDecision`
2. `evaluateRegimeDirectionGate` (line 149) + `persistRegimeDirectionDecision`
3. `evaluateDailyTradeCapGate` (line 191) + `persistDailyCapDecision`
4. `computeEventPolicy` (line 236) — event-policy blackout (lives in `firm/event-policy/`, NOT in gates/)
5. Shield risk-veto (line 260) — inline, no module
6. `evaluateNewGates` (line 310) + `persistGateDecisions`
7. Forge cross-strategy exposure (line 339) — inline
8. `evaluateMeanRevertGate` (line 447 in `strategy-execution.ts`, NOT strategy-blade) + `persistMeanRevertDecision`

## 4. Orphan tests (on disk, NOT in npm `test` script)

**Six orphan test files — their tests NEVER run in CI / `npm test`:**

| Orphan file | Test count |
|---|---:|
| `src/firm/gates/regime-direction-gate.test.ts` | **11** |
| `src/firm/regime-direction.test.ts` | 12 |
| `src/firm/breakout-continuation/breakout-continuation-manager.test.ts` | 21 |
| `src/firm/mean-reversion/mean-reversion-manager.test.ts` | 12 |
| `src/firm/pullback-continuation/pullback-continuation-manager.test.ts` | 17 |
| `src/firm/trend-following/trend-following-manager.test.ts` | 15 |
| **Total orphan tests** | **88** |

Most critical orphan: `gates/regime-direction-gate.test.ts` — a money-impact gate whose direct unit tests are silently skipped. The strategy-blade test file does cover REGIME_DIRECTION wiring (4 tests), so the gate isn't fully unprotected, but unit-level branches are unverified.

## 5. Gates with code but NO unit tests

- **`mean-revert-gate.ts`** (140 LOC). No `mean-revert-gate.test.ts` exists. Only indirect coverage via `mean-reversion-manager.test.ts` (12 tests — but that file is also orphan, see #4).
- **Shield risk-veto** — no standalone gate module; logic inline in strategy-blade. Covered by strategy-blade.test.ts (3 tests).
- **Forge exposure** — inline in strategy-blade. Covered by 3 tests in strategy-blade.test.ts.
- **Event policy** — `firm/event-policy/state-machine.ts`, no `*.test.ts` for the state machine itself. Only blade-level wiring tested.

## 6. Coverage stats (of 544 tests in `npm test`)

| Bucket | Tests | % |
|---|---:|---:|
| Gate-specific (`gates/*.test.ts`) | 81 (16+39+26, regime-gate excluded — orphan) | 14.9% |
| Gate wiring (`strategy-blade.test.ts`) | 25 | 4.6% |
| Strategy-managers (scalp/session-break/vol-exp tested; 4 others ORPHAN) | 28 | 5.1% |
| Notifications + status-report + observability | 73 | 13.4% |
| Position management + lifecycle + orchestrator | 28 | 5.1% |
| Other (agent-bus, predictions, oanda-sync, retention, raw-data, etc.) | ~309 | ~57% |

**Roughly 1 in 5 (~19%) of running tests touch gate behaviour directly or via wiring.**

## 7. Top-3 weakest gates by test coverage

1. **`mean-revert-gate.ts`** — 140 LOC, **zero direct tests**, only indirect (and orphan) coverage via `mean-reversion-manager.test.ts`. Highest absolute risk.
2. **`regime-direction-gate.ts`** — 11 unit tests exist but **orphan** (not in `npm test`). Effective unit coverage = 0 until re-wired. Blade-level wiring is tested (4 tests in strategy-blade.test.ts).
3. **Event-policy state machine** (`firm/event-policy/state-machine.ts`) — no `*.test.ts` for the state machine. Only 3 blade-wiring tests check pass/fail/error paths at the call site. Branches inside `computeEventPolicy` (rule evaluation, blackout windows) are untested.

## 8. Action candidates (operator decides)

- Add `src/firm/gates/regime-direction-gate.test.ts` to `apps/worker/package.json` `"test"` script — restores 11 tests immediately.
- Same for the 4 strategy-manager orphans (65 tests) + `regime-direction.test.ts` (12) — could lift count to ~632 trivially if all still green.
- Write `mean-revert-gate.test.ts` from scratch (no proposal needed — tests = observability, no behaviour change).
- Consider state-machine unit tests for `event-policy/state-machine.ts`.

---

Sources: `apps/worker/package.json`, `apps/worker/src/firm/gates/*`, `apps/worker/src/firm/strategy-blade.ts`, `apps/worker/src/firm/strategy-execution.ts`.
