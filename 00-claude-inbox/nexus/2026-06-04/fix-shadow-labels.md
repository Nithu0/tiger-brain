# Shadow outcome-label fix — verification log (2026-06-04)

Branch: `node-migration-nexus`. Observability-only, no behaviour change. NOT committed/pushed (operator gate).

## What the audit found vs reality

Audit said `/shadow/per-strategy` + `/shadow/comparison` filter `outcome IN ('win','loss')` while the writer stores `tp_hit`/`sl_hit` → aggregates always 0.

**Confirmed root cause, but the SQL fix had already landed** in commit `e1edfac` ("fix(observability+risk-visibility): shadow outcome filter + sizing characterization tests"), part of the same 2026-06-04 10-agent sweep. That commit changed:
- `outcome='win'` → `outcome='tp_hit'`
- `outcome='loss'` → `outcome='sl_hit'`
- `IN ('win','loss')` → `IN ('tp_hit','sl_hit')` (both the per-strategy R-sum and the comparison filter)

So the queries were already correct in HEAD. **What was missing: the regression test** the task asked for (that commit only added sizing characterization tests, none for the shadow query). Also a stale doc comment still claimed `win`/`loss`.

## Actual label values (ground truth)

From `apps/worker/src/firm/shadow-log.ts`:

```ts
export type ShadowOutcome = "pending" | "tp_hit" | "sl_hit" | "expired";
```

- `tp_hit` = win (price hit TP), `pnl_simulated_r = +rMultiple`
- `sl_hit` = loss (price hit SL), `pnl_simulated_r = -1`
- `expired` = 24h no-hit, `pnl_simulated_r = 0`
- `pending` = unresolved

The writer NEVER emits `win`/`loss`. `/shadow/forward-test` (newer endpoint) already used the correct labels and additionally counts `expired` — it was the reference.

## What I changed

1. **`apps/api/src/routes/shadow.ts`** — fixed the stale module-doc comment on line 6 (`win`/`loss`/`pending` → `tp_hit`/`sl_hit`/`expired`/`pending`). No SQL change needed (already correct in `e1edfac`).

2. **`apps/api/src/routes/shadow.test.ts`** (NEW) — 3 tests via Fastify `app.inject` against a stubbed `app.db` (no Postgres, no network):
   - per-strategy SQL asserts the route filters `outcome='tp_hit'` / `outcome='sl_hit'` / `IN ('tp_hit','sl_hit')` and contains NO stale `win`/`loss` literals — locks the contract so a regression to the old filter fails CI.
   - per-strategy surfaces **non-zero** `shadow_wins=6` / `shadow_losses=3`, `shadow_win_rate=6/9`, `missed_r=3` for tp_hit/sl_hit rows.
   - comparison filters the real labels and yields non-zero `shadowR`/cumulative `cumShadowR=3.5`.
   - Pattern copied from existing `risk-snapshot.test.ts` (decorate stub `db`, `register`, `await app.ready()`, `inject`).

3. **`apps/api/package.json`** — `test` script extended to include `shadow.test.ts` (was hardcoded to only `operator-control.test.ts`). A separate owner also appended `backtest/runner.test.ts` to the same script concurrently.

## Verify

- `cd apps/api && npx tsc --noEmit` → **EXIT 0** (clean, working tree intact).
  - Note: transient `runner.ts`/`backtest.ts` tsc errors appear only if you stash `runner.ts` alone — they are a coupled in-progress backtest pair (uncommitted, not mine, from the `37e3da8` ORB-replay repoint). With the tree as-is, tsc is green.
- `cd apps/api && npm test` → **19/19 pass**, including the 3 new shadow tests.

## Notes / out of scope

- `apps/api/src/routes/risk-snapshot.test.ts` has a PRE-EXISTING broken test ("route with no poison reports zero exclusions" → `app.inject is not a function`, reused/closed-app bug). Surfaced only when I briefly globbed the test script; reverted the glob to an explicit file list so I didn't rope in that unrelated failure. Flag for the risk-snapshot owner — not touched.
- Dashboard `ShadowVsActual.tsx` consumes these endpoints; no change needed (it reads the mapped `shadow_wins`/`shadow_losses` fields, which are now non-zero).
- Working tree / stash list left exactly as found (2 stashes preserved, runner.ts dirty preserved).
