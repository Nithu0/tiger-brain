# Autotune unblock map — calibration is inert, here's exactly why

Date: 2026-06-08
Scope: READ/ANALYSIS ONLY. For a Karri decision.
Question in one line: autotune (`CALIBRATION_MODE=SAFE_AUTO_APPLY`) cannot do anything today, for TWO independent reasons that both trace back to `ORB_ONLY_MODE=true`. Fixing one without the other does nothing.

---

## TL;DR

1. **`runCalibration` is skipped entirely under `ORB_ONLY_MODE`.** `orchestrator.ts:741` gates the periodic-calibration call on `!orbOnlyMode`. With `ORB_ONLY_MODE=true` (current per feature-flags.md line 115), it never runs — regardless of `CALIBRATION_MODE`.
2. **Even if un-skipped, there is nothing to calibrate.** `engine_scores` (the table calibration reads) is produced ONLY inside `bladeApproval`, which is ALSO behind the same `!orbOnlyMode` gate. So `engine_scores` has had **0 fresh rows since ORB_ONLY_MODE landed** — last write 2026-04-24, ORB_ONLY_MODE introduced 2026-04-25 (commit `8abb4bb`). The dates line up exactly; this is cause-and-effect, not coincidence.
3. **`ORB_ONLY_MODE` is a misnomer / stale flag.** The live drivers are the TIER-3 strategy modules (trend-following, breakout-continuation, pullback-continuation, mean-reversion, volatility-expansion, session-breakout) running through `runStrategyExecution` — **not** classic ORB. ORB itself is `ORB_ENABLED=false` (feature-flags reconcile 2026-06-05). The flag's real present-day function is "bypass the Prism→Blade firm-decision path (and its learning/attribution machinery)," which has nothing to do with ORB anymore.

---

## Dependency chain — per-link state

```
[A] ORB_ONLY_MODE decision
        │  current: TRUE  → bypasses Prism+Blade path
        ▼
[B] engine_scores flowing       ← produced ONLY by bladeApproval (behind !orbOnlyMode)
        │  current: DEAD (last write 2026-04-24; 0 fresh samples)
        ▼
[C] calibration runs            ← orchestrator.ts:741 `if (!orbOnlyMode && cycle%20==0)`
        │  current: NEVER FIRES (skipped by ORB_ONLY_MODE)
        ▼
[D] SAFE_AUTO_APPLY applies      ← needs ≥30 samples/engine, clamps ±20% from neutral
        │  current: INERT (nothing reaches it; and even reached, 0 samples < 30 min)
        ▼
   autotune effective
```

| Link | What it is | Current state | What unblocks it |
|---|---|---|---|
| **A** ORB_ONLY decision | `ORB_ONLY_MODE` env, default `false`, currently `true` (feature-flags L115) | TRUE → full firm-decision path bypassed | Karri/operator decision (see Karri question) |
| **B** engine_scores flowing | `recordCycleSnapshot()` (`engine-attribution/recorder.ts`) writes 1 row/engine, called from `bladeApproval` (`managers.ts:693`); backfilled on close by `backfillOutcomeForTrade` (postmortem.ts:390) | DEAD since 2026-04-24. `bladeApproval` only runs when `!orbOnlyMode` (orchestrator.ts:674,686). TIER-3 path (`runStrategyExecution`) produces NO engine_scores — verified, zero references | Restart the Prism→Blade path (turn ORB_ONLY off) **OR** add engine_scores production to the TIER-3 path |
| **C** calibration runs | `runCalibration(db, calibrationMode())` every 20 cycles | NEVER — gated `!orbOnlyMode` at orchestrator.ts:741 | Turn ORB_ONLY off, OR move/duplicate the calibration call outside the ORB_ONLY gate |
| **D** SAFE_AUTO_APPLY applies | `calibrateEngineWeights({mode:"APPLY", minSamples:30, maxDeviationFromNeutral:0.20})` inside `runCalibration` (calibration.ts:333). Karri's 2026-06-05 bounds: ≥30 samples/engine, ±20% drift cap | INERT. Needs C to fire AND B to have ≥30 fresh samples/engine | B + C resolved, then `CALIBRATION_MODE=SAFE_AUTO_APPLY` (Karri-gated flip per calibration.ts:37-41) |

Note: `runCalibration` also reads `firm_memory` (postmortems, silent_wins) and `department_scores` for **session-level** threshold recs. Those tables MAY still be writing (postmortems run on trade close regardless of ORB_ONLY). But the **engine-multiplier** half of autotune — the part `SAFE_AUTO_APPLY` actually applies via `calibrateEngineWeights` — is 100% dependent on `engine_scores`, which is dead. So even partial-unblock (C only) gives you session-threshold recs with no engine-weight learning.

---

## Why engine_scores writes stopped 2026-04-24 (answer to Q2)

- **Producer:** `recordCycleSnapshot()` in `engine-attribution/recorder.ts`, called from `bladeApproval()` in `managers.ts:693`. It walks the tiered-conviction result (direction/timing/confirmation engines) and inserts one row per engine. Outcome is backfilled at trade-close by `backfillOutcomeForTrade` (postmortem) / `markCycleAsNoTrade`.
- **The gate:** `bladeApproval` is only called from `orchestrator.ts:686`, which is inside `if (!orbOnlyMode && synthesisId && thesis && ...)` (line 674). `prismSynthesis` (which computes the conviction the snapshot needs) is likewise short-circuited at line 668 under ORB_ONLY. So under ORB_ONLY_MODE, the conviction is never computed and `bladeApproval` is never entered → `recordCycleSnapshot` never fires.
- **Timing:** ORB_ONLY_MODE pivot landed `8abb4bb` 2026-04-25. engine_scores last write 2026-04-24. The flag flip is the cause.
- **Is the producer gated by ORB_ONLY or something else?** ORB_ONLY (transitively, via the bladeApproval call site). There is no separate `ENGINE_ATTRIBUTION_ENABLED`-style flag in the way — it's purely the prism/blade path being bypassed.

---

## Is ORB_ONLY_MODE stale? (answer to Q1) — YES, it's a misnomer

- Live drivers per the 443 channel (feature-flags reconcile 2026-06-05, L70): TIER-3 modules, **no classic ORB**, no ORB attribution in closed-trade stats. `ORB_ENABLED=false`.
- TIER-3 strategies execute via `runStrategyExecution` at **orchestrator.ts:594** — which runs in Step 1f, BEFORE the ORB_ONLY gate (L665) and is NOT wrapped by `!orbOnlyMode`. The code comment is explicit: *"Replaces Prism+Blade for the 4 firm strategies — each runs independently with its own SL/TP/cap."*
- So `ORB_ONLY_MODE`'s actual present-day effect is **not** "only ORB trades." ORB barely runs. Its real effect is: **bypass the Prism→Blade firm-decision path and everything bolted to it — synthesis, blade approval, engine-attribution recording, and periodic calibration.** The name describes a 2026-04-25 reality that no longer holds.
- Better name would be something like `BYPASS_FIRM_DECISION_PATH`. The TIER-3 strategies don't need Prism/Blade and aren't affected by the flag either way; the only casualties of `=true` are the learning/attribution/calibration subsystems.

---

## The crisp Karri question

> **`ORB_ONLY_MODE=true` is silently keeping the entire learning/calibration loop dark.** It bypasses Prism→Blade, which is the only thing that writes `engine_scores`, which is the only data autotune's engine-weight half can learn from. It also directly skips the periodic `runCalibration` call. Net: autotune (`SAFE_AUTO_APPLY`) is doubly inert, and has been since 2026-04-25. Meanwhile the flag's name is stale — the live TIER-3 strategies run independently of Prism/Blade and aren't gated by it at all.
>
> **If we want autotune to function, which unblock do you want?**
>
> 1. **Turn `ORB_ONLY_MODE=false`** — restores Prism→Blade, engine_scores production, AND calibration in one move. Cleanest, but it re-activates the full firm-decision path (a *trade-affecting* change: Prism/Blade can now approve trades alongside TIER-3). Needs your sign-off on running both paths concurrently.
> 2. **Decouple calibration + attribution from the bypass flag** — keep Prism/Blade bypassed for trading, but (a) move the `runCalibration` call outside the `!orbOnlyMode` gate, and (b) add `engine_scores` production to the TIER-3 `runStrategyExecution` path so calibration has live data. More code, but keeps trade behaviour unchanged while turning the learning loop back on. Pure learning-infra (Claude can own the build; the `SAFE_AUTO_APPLY` flip still gates through you).
> 3. **Rename/retire `ORB_ONLY_MODE`** as a follow-up regardless of 1/2, since it no longer means what it says.
>
> My read: **option 2** matches the "learn continuously without changing trade decisions" principle (prinsipp 6 rescind) — it lights up calibration/attribution as observability while keeping the actual `SAFE_AUTO_APPLY`-applies behind your gate. Option 1 is simpler but is itself a trade-affecting change. Which do you want?

---

## Files / line anchors (all absolute)

- `/home/nithu/code/ai-assistent/apps/worker/src/firm/orchestrator.ts` — L594 `runStrategyExecution` (TIER-3, NOT gated); L665 `orbOnlyMode`; L668/674/686 prism+blade gated; L741 calibration gated
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/managers.ts` — L693 `recordCycleSnapshot` inside `bladeApproval`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/engine-attribution/recorder.ts` — engine_scores INSERT
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/engine-attribution/calibrate-weights.ts` — `calibrateEngineWeights`, ±20%/min30 bounds
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/calibration.ts` — L44 `calibrationMode()`, L333 engine calibration call, L37-41 SAFE_AUTO_APPLY gate note
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/strategy-execution.ts` — TIER-3 executor, produces NO engine_scores
- `/home/nithu/code/ai-assistent/docs/ref/feature-flags.md` — L70 reconcile (TIER-3 live, ORB false), L115 `ORB_ONLY_MODE=true`

Caveat: `engine_scores` DB state not verifiable from this session (nexus-pg unreachable — EHOSTUNREACH, needs Railway tunnel). The 2026-04-24 cutoff is per task context; the code-level cause and the date alignment with `8abb4bb` (2026-04-25) corroborate it.
