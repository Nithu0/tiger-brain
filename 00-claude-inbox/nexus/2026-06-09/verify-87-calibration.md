# Verify PR #87 — calibration decouple from ORB_ONLY_MODE

Date: 2026-06-09
Scope: READ/ANALYSIS ONLY. Code = `origin/main` (live = `362eafa`, Merge PR #87; fix commit `6d8813b`). Data = live `/calibration/status` + `/calibration` pulled today 2026-06-09 ~11:30 (post-#87 merge).

## TL;DR verdict

- **Does calibration RUN now?** YES — and proven on live data, not just code.
- **Does engine_scores FLOW now?** YES — empirically confirmed (engine-weight multipliers are non-neutral and recomputed today).
- **What autotune is actually live vs inert?**
  - **Session-level calibration**: LIVE, producing fresh recommendations.
  - **Engine-weight calibration**: LIVE, producing fresh non-neutral multipliers from real `engine_scores`.
  - **Both still RECOMMEND_ONLY** (`applied=false`). Nothing feeds back into trade decisions yet — that requires `CALIBRATION_MODE=SAFE_AUTO_APPLY`, which is Karri-gated. So autotune *computes* correctly now but does not *act*. That's by design.

The prior audit's assumption ("engine_scores can't flow because recordCycleSnapshot is behind ORB_ONLY_MODE") was correct about the *mechanism* but is moot in practice **because ORB_ONLY_MODE is false on prod**, so the Blade path runs and DOES insert engine_scores.

## 1. runCalibration now unconditional — CONFIRMED

`apps/worker/src/firm/orchestrator.ts` (~line 748). The gate changed from:

```ts
if (!orbOnlyMode && this.cycleCount % 20 === 0) {   // OLD
if (this.cycleCount % 20 === 0) {                   // NEW (6d8813b)
  runCalibration(this.db, calibrationMode()).catch(...)
```

`runCalibration` now fires every 20 cycles regardless of `ORB_ONLY_MODE`. Diff is +10/-4, single file. Mode stays `CALIBRATION_MODE`-driven (default `RECOMMEND_ONLY`), so behaviour-neutral unless the env flag is flipped.

## 2. engine_scores trace — the key question

Two writers of `engine_scores`:

1. **`recordCycleSnapshot`** (`engine-attribution/recorder.ts:33`) — the ONLY INSERT. Called only inside **`bladeApproval`** (`managers.ts:~700`).
2. **`backfillOutcomeForTrade`** (`recorder.ts:79`) — only `UPDATE ... WHERE trade_id=$1`. Updates rows that already exist; inserts nothing.

`bladeApproval` is invoked in the orchestrator at `if (!orbOnlyMode && synthesisId && thesis && isTradeAllowed && portfolioGate)` (~line 674-686). So:

- The engine_scores INSERT is gated on **`!orbOnlyMode`** (Prism/Blade path).
- TIER-3 strategies (Step 1b-1j, before the gate) get a `trade_id` but never call `recordCycleSnapshot` → no rows → the postmortem backfill UPDATE matches 0 rows for TIER-3 trades.

**Therefore the answer depends entirely on the live value of `ORB_ONLY_MODE`:**
- If `ORB_ONLY_MODE=true` → Blade path skipped → no engine_scores → engine-weight calibration self-gates to no-op (calibration RUNS but engine multipliers stay neutral). Session-level still works (it reads `firm_memory` postmortems, not engine_scores).
- If `ORB_ONLY_MODE=false` (CURRENT PROD per commit msg) → Blade path runs → engine_scores DO flow → engine-weight calibration has real data.

The commit message correctly characterises this as "engine-weight calibration self-gates (only acts on fresh engine_scores, which exist only when the Prism/Blade path runs)." The decouple is robust either way: it just stops the flag from silently killing the *session-level* half too.

## 3. Live data — calibration IS producing rows post-#87

`/calibration/status` pulled today (2026-06-09 ~11:30 UTC):

```
calibrationMode:    RECOMMEND_ONLY
autoApplyActive:    false
multipliersNeutral: false          <-- was TRUE (all 1.0) in 2026-06-07 pull
multipliersSource:  { mode: "APPLY", computedAtIso: "2026-06-09T09:16:24.779Z" }   <-- was null
engineMultipliers:  macro 1.0386 · technical 1.0386 · structure 1.0386 ·
                    intermarket 1.0386 · momentum 0.9415 · sentiment 1.0 · session 1.0
```

`recentCalibrationLog` (20 rows) span **2026-06-09T07:40 → 09:16 UTC** (today, fresh, ~20-cycle cadence). Contains BOTH:

- **Engine-weight rows**: `engine_multiplier.{macro,technical,structure,intermarket,momentum}`, non-neutral values → proves `engine_scores` has fresh rows feeding `calibrateEngineWeights`.
- **Session-level rows**: `marketThesisThreshold` ASIA_OBSERVE 70→73 (multiple timestamps today) → proves postmortem-driven session calibration runs.

**Contrast with the pre-#87 snapshot** (`live_calibration_status.json`, pulled 2026-06-07): every `recentCalibrationLog` row was frozen at **2026-04-24/04-25**, `multipliersSource: null`, `multipliersNeutral: true`. That is exactly the "calibration dead since 2026-04-25" the commit describes. Post-merge it is alive.

All current rows show `applied: false` (mode `RECOMMEND_ONLY`).

## 4. What actually works vs still inert

| Capability | State after #87 | Why |
|---|---|---|
| `runCalibration` fires every 20 cycles | LIVE | gate decoupled (6d8813b), confirmed by fresh log rows |
| Session-level calibration (marketThesisThreshold etc.) | LIVE, computing | reads `firm_memory` postmortems (TIER-3 trades feed this); fresh ASIA_OBSERVE rows today |
| Engine-weight calibration (per-engine multipliers) | LIVE, computing | `engine_scores` IS flowing because `ORB_ONLY_MODE=false` → Blade path runs → `recordCycleSnapshot` inserts. Non-neutral multipliers today prove it |
| Multipliers actually *applied* to trade decisions | INERT (by design) | `CALIBRATION_MODE=RECOMMEND_ONLY` → `engineMode=RECOMMEND_ONLY` (calibration.ts:334-335) → `applied=false`. Needs `SAFE_AUTO_APPLY` to act |
| SAFE_AUTO_APPLY autotune (session + engine self-adjust) | BLOCKED (Karri-gated) | requires operator/Karri env flip; guardrails ≥30 samples/engine + ±20% deviation already coded |

### Caveat / fragility worth flagging
Engine-weight calibration only has data **while `ORB_ONLY_MODE` stays false**. If anyone flips `ORB_ONLY_MODE=true` again, the Blade path stops, `recordCycleSnapshot` stops inserting, and within ~7 days (the calibration lookback window) engine_scores goes stale → engine-weight calibration silently reverts to neutral. #87 does NOT fix that coupling (the INSERT is still inside `bladeApproval` behind `!orbOnlyMode`); it only ensures the *session-level* half survives the flag and that `runCalibration` itself always fires. A full fix would move engine_scores capture to cover the TIER-3 path, or wire TIER-3 trades through `recordCycleSnapshot`. Route to Karri — it's a learning-infra/strategy boundary call, not a clear bug.

## Sources
- `git show 6d8813b` (PR #87 fix)
- `origin/main:apps/worker/src/firm/orchestrator.ts` (calibration gate + bladeApproval call site)
- `origin/main:apps/worker/src/firm/managers.ts` (`bladeApproval` → `recordCycleSnapshot`)
- `origin/main:apps/worker/src/firm/engine-attribution/recorder.ts` (INSERT vs UPDATE)
- `origin/main:apps/worker/src/firm/calibration.ts` (session + engine-weight, mode mapping L334-335)
- Live: `/calibration/status`, `/calibration` pulled 2026-06-09; contrast `live_calibration_status.json` (2026-06-07)
