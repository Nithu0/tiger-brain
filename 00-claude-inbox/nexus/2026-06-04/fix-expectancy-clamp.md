# Fix: risk-snapshot expectancy degenerate-R clamp

Date: 2026-06-04
Branch: node-migration-nexus
Scope: observability / data-quality. NO go-live gate behaviour changed — only a displayed aggregate sanitized. No commit/push/Railway.

## Symptom

`/firm/risk-snapshot` reported expectancy **+6.233R at a 31.7% win rate** — mathematically impossible. A positive +6R expectancy with a sub-33% win rate would require average winners of ~+20R, which doesn't exist in the data. This is exactly the inflated number a future live-flip would key on.

## Root cause

Legacy `result_r` rows in `simulated_orders` carry astronomical R-multiples from a **degenerate stop basis**:

- The worker writes `result_r = priceDelta / original_risk_points`.
- Some OANDA-reconcile rows had `stop_loss` overwritten with an `entry ± 0.20` placeholder (or `stop_loss == entry`). That makes `original_risk_points ≈ 0.20` (or 0), so a ~30-point gold move divides to **+106R … +259R**, and exact-equal rows produce **±Inf**.
- The worker already guards this going forward (`apps/worker/src/firm/postmortem-r-multiple.ts`, `MIN_PLAUSIBLE_RISK_POINTS = 1.0`, lands 21.5 — returns `null` for sub-point stops). But rows written **before** that guard remain poisoned in the DB.
- `apps/api/src/routes/risk-snapshot.ts` reads `result_r` straight from the DB and only filtered `Number.isFinite`. That let the +106..+259R rows through (Inf was filtered, but the finite-but-huge ones weren't), dragging avgR/expectancy.

Confirmed against real data in `data/pull/export.json` (reconstructed R from entry/sl/close):

- Degenerate outliers: ids `2ff5ef65…` / `7004bdbd…` / `5115e2dd…` / `29e46e2e…` (entry==sl → Inf), plus `a6214b46…` (R=259, risk=0.20), `98e5f79f…` (R=188.2), `0bd8373b…` (R=156.6), etc.
- The `oanda_backfill` execution_source filter in the route does NOT catch these — they have real UUIDs, not `oanda_backfill_*` ids.

## Guard added

File: `apps/api/src/routes/risk-snapshot.ts`

- New exported constant `MAX_PLAUSIBLE_ABS_R = 25` (with rationale: tightest genuine XAUUSD stop ~6pts, gold rarely travels >60pts intraday → real R almost never exceeds ~10-12R; a +3R winner is already top-bucket; 25R bound is generous so genuine fat-tails survive while ≥106R placeholder rows are caught).
- New exported pure helper `sanitizeRSeries(raw, maxAbsR)` → `{ sane, excludedCount, excludedValues }`. Drops non-finite (NaN/±Inf) and `|R| > maxAbsR`.
- Aggregate now computed on `sane` only — affects `totalTrades`, `avgR`, `expectancy`, `winRate`, and the bucket histogram. **Raw per-trade rows are NOT mutated** (DB untouched); only the aggregate is sanitized.
- Transparency: route logs `app.log.warn` with excluded count + sample values, and the response now carries `rDistribution.degenerateExcluded: number` (added to `RiskSnapshotResponse`).

No gate logic touched. No env var, no DB write, no Railway change.

## Validation against real data (data/pull/export.json, full closed set n=190)

- BEFORE (finite-only, no guard): avgR = **+6.485R** (or NaN once ±Inf included).
- AFTER (`|R| <= 25`): n=178, **excluded=12**, avgR = **+0.101R**, winRate = **0.360**, expectancy = **+0.101R** — now internally consistent.
- Excluded values: `[31.6, 106.1, 138.4, 154.2, 154.3, 156.6, 188.2, 259.0, Inf, Inf, Inf, Inf]`.

## Tests

New file: `apps/api/src/routes/risk-snapshot.test.ts` (5 tests):

1. `sanitizeRSeries` keeps sane values untouched.
2. excludes degenerate placeholder-stop R (>>ceiling) + ±Inf/NaN.
3. boundary: exactly ±25R kept, just beyond excluded.
4. **full route via `app.inject`**: 7 honest trades + 4 poison rows (106.1/259/138.4/Inf) → `totalTrades=7`, `degenerateExcluded=4`, sane negative avgR/expectancy (NOT +6.233), winRate = 2/7.
5. route with no poison → `degenerateExcluded=0`.

## Verify

- `npx tsc --noEmit` (apps/api): touched files (risk-snapshot.ts + .test.ts) clean. Two pre-existing errors in `apps/api/src/backtest/runner.ts` (`loadM1` / backtest meta type) are unrelated uncommitted WIP — not mine.
- `npm test` (apps/api): **18/18 pass** (was 13; +5 added).

## Follow-up (not done — needs operator/Karri)

- A one-time DB cleanup could NULL out the legacy poisoned `result_r` values (DB write → operator-gated). The diagnostic at `apps/api/src/routes/diagnostic-backfill.ts` already classifies `ABS(entry-stop) < 1.0` as `degenerate`; a sibling cleanup could re-derive or NULL those `result_r`. The displayed aggregate is now safe regardless, so this is optional hygiene, not urgent.
- Other read paths that aggregate `result_r` (analytics.ts, strategies-compare.ts, predictions, orb/stats) were NOT audited here — same poison could surface there. Flag for a follow-up sweep if those panels show inflated R.
