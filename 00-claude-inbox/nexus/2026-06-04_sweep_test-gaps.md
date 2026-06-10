# LANE 9 — Test coverage gaps on critical + newly-shipped paths

Date: 2026-06-04
Scope: READ-ONLY audit. Worker suite ~1157 tests; husky pre-push = `cd apps/worker && npm test`.
Auditor: Claude (code session)

## TL;DR

The single highest-risk gap is real: **the sizing/risk path that produced the
2026-04-21 ~106-unit amplification has ZERO unit tests.** No test asserts
`executed size == intended units`, and no test reproduces the
`tightSL × %risk × balance` blow-up. The formula is unchanged and **still has
no upper clamp** (`strategy-execution.ts:900-914`): `size = floor(balance ×
risk% × chain × sizingMod × newsBoost / stopLossPoints)` — the only guard is
floor-to-int and a `>0` check. A proposed max-units circuit breaker does not
exist anywhere in `apps/worker/src`.

Secondary gaps: the new API routes (`/learning`, `/calibration/status`,
`/shadow/forward-test`) are entirely untested (apps/api has 56 route files, 1
test file, and it's in `lib/` not `routes/`). `calibrationMode()` env-parsing is
not directly tested. regime-direction flat-band (cc02426) IS well covered (9
tests). orchestrator runCycle ordering is only partially covered (counter /
heartbeat / guard / retention — not phase ordering).

---

## Findings by item

### (a) Sizing/risk path — CONFIRMED no coverage. HIGHEST RISK.

- Real sizing math lives in `apps/worker/src/firm/strategy-execution.ts:900-914`:
  ```
  dollarRisk = virtualBalance * (cfg.riskPercent/100) * chainLotEffective
               * sizingModifierMult * newsBoostMult;
  sizeRaw    = stopLossPoints > 0 ? dollarRisk / stopLossPoints : 0;
  size       = Math.floor(Math.abs(sizeRaw));   // ← only transform, no cap
  ```
- `risk.service.ts` (45 lines) is a daily-loss gate only, NOT sizing, and has NO test.
- `strategy-execution.test.ts` (431 lines) tests: enabled-flag halt, no-bot, no-proposals,
  per-strategy cap, thesis-score stamping, atr stamping, daily-loss block, **invalid
  distances (stopLossPoints=0 only)**, dedup. NONE assert the computed unit count.
- The 2026-04-21 amplification (tight SL × %risk × balance → ~106 units) is NOT reproduced.
- Multipliers `chainLotEffective`, `sizingModifierMult`, `newsBoostMult` stack
  multiplicatively with NO combined ceiling — untested compounding risk.

### (b) Max-units circuit breaker — DOES NOT EXIST.

- grep for `MAX_UNITS|maxUnits|UNIT_CAP|circuit.?breaker|sizeCap` → nothing in source.
- This is unbuilt. Tests must be written WITH the breaker. Spec below. STRATEGY-GATED (Karri).

### (c) Shadow forward-test + new API routes.

- Worker logic IS tested: the 8 forward-test tests live in `shadow-log.test.ts`
  (added in 7ec793c, +86 lines; functions `recordForwardTestSnapshots`,
  `trackForwardTestOutcomes`). Good.
- API routes are NOT tested:
  - `apps/api/src/routes/shadow.ts` → `/shadow/forward-test`, `/shadow/per-strategy`, `/shadow/comparison`
  - `apps/api/src/routes/calibration.ts` → `/calibration`, `/calibration/status`
  - `/learning` is a dashboard page (`apps/dashboard/.../learning/page.tsx`) backed by these API routes.
  - apps/api has exactly ONE test file (`lib/operator-control.test.ts`) — zero route tests.
  - The graceful-empty-state branches ("table absent → empty, never 500",
    shadow.ts:261) are exactly the kind of fail-safe that silently regresses untested.

### (d) calibrationMode() — NOT directly tested.

- `calibration.ts:43` parses `CALIBRATION_MODE` env → 4 modes + RECOMMEND_ONLY fallback.
- `calibration.test.ts` passes mode STRINGS into `runCalibration(db, "OFF")` etc. but
  NEVER calls `calibrationMode()` itself. The env→mode parsing + bogus-value fallback is unverified.
- Note: there is a SECOND, DUPLICATE parse in `apps/api/src/routes/calibration.ts:111-113`
  (inline `validModes.includes(...)` re-impl). Both copies untested; drift risk between them.

### (e) regime-direction flat-band (cc02426) — WELL COVERED. No new test needed.

- cc02426 added 9 tests to `regime-direction.test.ts`: exact-flat null, sub-threshold
  dead-band ($1.50 < $2 → flat), at-threshold ($2 → UP), env-override clamping
  (`resolveCloseMoveMinMove` garbage/out-of-range → default), data-failure-vs-flat
  distinction. Solid. SKIP.

### (f) Critical firm paths with thin/smoke-only coverage.

- `orchestrator.test.ts` covers cycle counter, heartbeat payload, 42P01 heartbeat-disable,
  re-entry guard, retention gate. It does NOT assert PHASE ORDERING inside runCycle.
  runCycle order (orchestrator.ts): Step 0a sync → 0b monitorPositions → 0c postmortem
  → 1 facts → 1e2 strategy-snapshot → 1f runStrategyExecution → 1g shadow trackers.
  Ordering invariants (postmortem before execution; snapshot before execution) are untested.

---

## Highest-value missing tests, ranked by risk

### RANK 1 — Sizing amplification regression (intent-vs-execution). [infra]
File: `apps/worker/src/firm/strategy-execution.test.ts` (new tests)
Assertions:
1. Given balance=10000, riskPercent=1, stopLossPoints=100 → assert computed `size === 1`
   (i.e. floor(10000 × 0.01 / 100) = 1). Locks the baseline formula.
2. REPRODUCE 2026-04-21: balance≈10000, riskPercent=1, **tight** stopLossPoints≈0.94
   → assert `size` lands in the ~100+ range the incident produced (document the exact
   inputs from the postmortem). This test should FAIL the day a cap is added — at which
   point it becomes the breaker's assertion (Rank 2). Until then it DOCUMENTS the hazard.
3. Multiplier stacking: chainLot=2 × sizingMod=1.5 × newsBoost=1.5 → assert dollarRisk
   is exactly 4.5× the base, proving no hidden ceiling today (the risk to flag to Karri).
4. `stopLossPoints=0` → already covered (invalid distances). Keep.

### RANK 2 — Max-units circuit breaker tests (write WITH the breaker). [Karri to design, infra to test]
File: `apps/worker/src/firm/strategy-execution.test.ts`
Assertions (once `MAX_UNITS_PER_TRADE` / equivalent env exists):
1. size computed ABOVE the cap → execution blocked (or clamped) BEFORE any OANDA call
   and BEFORE any `INSERT INTO signals`; assert a `risk_events` / shadow row records the breach.
2. size at exactly the cap → allowed.
3. cap env unset → assert a SAFE DEFAULT applies (not Infinity) — decide default with Karri.
4. clamp-vs-reject behaviour is explicit and asserted (the incident argues for REJECT, not silent clamp).

### RANK 3 — API route tests for the learning surface. [infra]
New file(s): `apps/api/src/routes/shadow.test.ts`, `apps/api/src/routes/calibration.test.ts`
Assertions (inject a stub `app.db`):
1. `/shadow/forward-test` with table-missing error → returns 200 + empty payload, NOT 500
   (guards shadow.ts:261 fail-safe).
2. `/shadow/forward-test?days=30` with rows → aggregates would-fire vs simulated-R correctly.
3. `/calibration/status` → returns `calibrationMode` + `autoApplyActive===(mode==='SAFE_AUTO_APPLY')`.
4. `/calibration/status` with bogus CALIBRATION_MODE env → returns "RECOMMEND_ONLY" (fallback).
   (This also covers the duplicate parse in calibration.ts:111-113.)

### RANK 4 — calibrationMode() env-parse unit test. [infra]
File: `apps/worker/src/firm/calibration.test.ts` (add)
Assertions: set `process.env.CALIBRATION_MODE` to each of OFF / RECOMMEND_ONLY /
SAFE_AUTO_APPLY / SHADOW_COMPARE → returns same string; set to "garbage" / "" / undefined
→ returns "RECOMMEND_ONLY". 6 cases, fail-safe is the load-bearing one (it gates autotune-apply).

### RANK 5 — runCycle phase-ordering invariants. [infra]
File: `apps/worker/src/firm/orchestrator.test.ts` (add)
Assertions: instrument call order (spy/record) and assert:
1. `monitorPositions` and `runPostmortemForNewlyClosedTrades` are invoked BEFORE `runStrategyExecution`.
2. strategy-snapshot (recordForwardTestSnapshots) runs BEFORE runStrategyExecution.
3. shadow outcome trackers run AFTER runStrategyExecution.
Protects against a refactor silently reordering execution ahead of safety/monitoring steps.

---

## NEW TASKS

- **[infra]** Add sizing amplification regression tests (Rank 1) to
  `strategy-execution.test.ts`. Pull exact 2026-04-21 inputs from the
  intent-vs-execution postmortem so test #2 reproduces ~106 units. No behaviour
  change — pure characterization. Run freely (observability/test, not trade-altering).

- **[Karri]** DESIGN the max-units circuit breaker: env name, default value
  (must NOT be Infinity), reject-vs-clamp decision, and where in the pipeline it
  sits (before OANDA call + before signal INSERT). This is a risk/sizing change →
  proposal in `docs/strategy/proposals/`. infra writes the Rank-2 tests once design lands.

- **[infra]** Add API route tests (Rank 3): new `shadow.test.ts` +
  `calibration.test.ts` under `apps/api/src/routes/`. apps/api currently has near-zero
  route coverage — establish the pattern (stub `app.db`, assert empty-state never 500).
  Wire `cd apps/api && npm test` into husky pre-push alongside the worker suite.

- **[infra]** Add `calibrationMode()` env-parse test (Rank 4) — 6 cases, fallback is critical.
  Also flag the DUPLICATE mode-parse in `apps/api/src/routes/calibration.ts:111-113`:
  recommend importing the worker's `CalibrationMode`/parser instead of re-implementing
  (drift risk). [infra fix, behaviour-neutral.]

- **[infra]** Add runCycle phase-ordering test (Rank 5) to `orchestrator.test.ts`.

- **[operator]** Decision needed: the sizing path has no upper bound today and the
  breaker is unbuilt. The Rank-1 reproduction test makes the hazard visible in CI but
  does NOT close it. Karri owns the fix; operator should prioritize the breaker proposal.

## Notes / non-issues
- regime-direction flat-band (cc02426): well covered, no action.
- Shadow forward-test WORKER logic: 8 tests present in shadow-log.test.ts, adequate.
- Husky pre-push runs ONLY the worker suite — any new apps/api tests won't gate pushes
  until `apps/api` is added to the pre-push hook (called out above).
