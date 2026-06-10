# Flip-confirmation matrix — "alt er flippa" (Karri-approved batch)

**Date:** 2026-06-07 (Sat, market WEEKEND — no live trade evaluations since 2026-06-05 12:54 UTC)
**Build:** `2b2d2ce` (= HEAD = live worker commit, confirmed via `/health` build.commit `2b2d2cef`)
**Method:** READ/VERIFY ONLY. Env values are NOT readable. Effect inferred from DB side-effects (gate_decisions, calibration_log, agent_lessons, firm_state) + the proving code path. nexus-pg read-only + data/pull/ (fresh 14:31).

> **Top-line:** of the 7 flags, **2 took real effect, 5 are inert.** The single most important inert item is `LESSON_AUTO_PROMOTE_ENABLED` — the code does not exist in this build (PR #73 open). The lesson-learning chain is broken end-to-end: derivation crashes nightly, nothing gets approved, nothing gets injected, auto-promote isn't deployed.

---

## Matrix

| Flag | Flipped (worker)? | Actually effective? | Evidence | Blocker if inert |
|---|---|---|---|---|
| **AGENT_LESSONS_ENABLED** | Yes (inferred) | **Partial / scaffold-live** | Firm agents writing today (`firm_agent:trade-critic/risk-advisor:last_run_iso` = 2026-06-07T12:02Z); derive cron passes its `AGENT_LESSONS_ENABLED!=="true"` early-return (writes `:failed` markers → flag must be true). Client/injection gates open. | Master is ON, but everything downstream of it is broken/empty (see below). On its own it changes no trade behaviour. |
| **LESSON_DERIVATION_ENABLED** | Yes (inferred) | **NO — flipped but CRASHING** | `firm_state` has `firehose:derive_lessons:<date>:failed exitCode 1` for **every day 2026-05-29 → 2026-06-07** (today incl). The `:failed` marker is only written *after* both flag gates pass and the subprocess spawns → flag is on, but `scripts/firehose/derive-lessons.mjs` exits 1 every night. Last successful proposals were 2026-05-21 (the only 3 rows in `agent_lessons`). | Subprocess runtime crash (not env-gate, not missing file — fetch query verified working, returns valid clusters incl. a qualifying TRENDING/OANDA_SL_TP anti-pattern at 14% WR). Suspect: embeddings step / INSERT path after fetch. **Needs a manual run with logs to pin the throw.** |
| **LESSON_INJECTION_ENABLED** | Yes (inferred) | **NO — inert, nothing to inject** | `agent_lessons`: 3 proposed, **0 approved**. `buildLessonContext()` (`agent-lessons/injection.ts:51,58`) filters `status='approved'` AND `confidence >= 0.5`. The 3 proposed rows are conf 0.22 / 0.36 / 0.36 — they'd fail the conf gate even if approved. risk-advisor + trade-critic DO call `buildLessonContext` (running today) → it returns `""` every time. | Zero approved lessons. Injection is a live no-op until lessons get approved AND have conf ≥ 0.5. **This is a trade-altering switch per CLAUDE.md — but it's currently injecting nothing, so no behaviour change has occurred.** |
| **LESSON_AUTO_PROMOTE_ENABLED** | Yes (operator flipped) | **NO — CODE NOT IN BUILD (PR #73 open)** | `grep` across `apps/` + `packages/` + `scripts/`: **ZERO call-sites** for `LESSON_AUTO_PROMOTE_ENABLED`. No `auto-promote-lessons.*` file anywhere in repo. No `AUTO_PROMOTE` / `autoPromote` reference in any source. Flag is read by nothing. | **PR #73 not merged → not in `2b2d2ce`.** Flipping the env on Railway does literally nothing; no process reads it. INERT until #73 merges + deploys. This is the loudest item — flag is a placebo right now. |
| **CALIBRATION_MODE (=SAFE_AUTO_APPLY?)** | Unknown on worker | **NO effect observed — no apply, ever** | `/calibration/status` → `calibrationMode: RECOMMEND_ONLY, autoApplyActive: false` (BUT this echoes the **API** process env, not the worker — not authoritative for worker flip). Authoritative side-effects: `multipliersSource: null` (worker never persisted a multiplier snapshot to `firm_state` — no `ENGINE_MULTIPLIERS_STATE_KEY` row exists), `multipliersNeutral: true`, all 7 engine multipliers = 1.0. `calibration_log` last row = **2026-04-25**, all `applied=false`, all `mode=RECOMMEND_ONLY`; no row ever written with `applied=true`. | Two independent blockers even if worker = SAFE_AUTO_APPLY: (1) **engine_scores has 0 rows in 14d** → `calibrateEngineWeights` scorecards empty → `minSamples≥30` never met → nothing applies/logs (Karri guardrail working as designed). (2) **Session-threshold half is a stub:** `getActiveProfile()` (`calibration.ts:362-366`) always returns baseline and has **zero consumers** — `calibration_profiles` is never read back into the loop. So even a populated calibration_log wouldn't change trade decisions. SAFE_AUTO_APPLY is effectively inert in this build. |
| **RISK_LEVEL_HARD_GATE_ENABLED** | Yes (inferred, unconfirmable yet) | **Cannot confirm post-flip — but real call-site exists** | Real gate: `gates/new-gates.ts:107,125` → `hardRejected = wouldReject && RISK_LEVEL_HARD_GATE_ENABLED`. `gate_decisions` shows 5 `risk_level` rows with `would_reject=true, hard_rejected=false`, **all dated ≤ 2026-06-03** (pre-flip). Since the flip, market has been closed (WEEKEND) → **no `risk_level` evaluation has fired post-flip**, so DB can't yet show `hard_rejected=true`. | Not inert in code — it has teeth. But **unverifiable until Monday London open** when an elevated/high/extreme risk_level + a signal coincide. First post-flip `risk_level would_reject=true` should now carry `hard_rejected=true`. **VERIFY-BY: Mon 2026-06-08 after first elevated-risk cycle.** |
| **POSITION_SIZE_CIRCUIT_BREAKER_ENABLED** | Flip is a no-op (already default ON) | **Effective — but flip changed nothing** | Call-site `strategy-execution.ts:987` defaults to `true`. It CLAMPS oversized trades to cap (`MAX_UNITS_PER_TRADE` / `MAX_NOTIONAL_PCT`), doesn't reject. Already on by default pre-flip. | Not inert — it's active. But flipping it explicitly to true is redundant (default was already true). No state change from the flip. Verify clamps via `firm` log `circuit-breaker CLAMPED` lines when a large trade is sized. |

---

## Inert-despite-flipped — ranked

1. **`LESSON_AUTO_PROMOTE_ENABLED` — code absent (PR #73 open).** Zero call-sites in build `2b2d2ce`. Flag reads by nothing. Placebo until #73 merges + deploys. **Loudest.**
2. **`LESSON_DERIVATION_ENABLED` — flipped but crashing nightly (exit 1) for 9+ days.** No new lessons since 2026-05-21. The supply side of the learning loop is dead.
3. **`CALIBRATION_MODE=SAFE_AUTO_APPLY` — double-blocked.** engine_scores empty (minSamples≥30 unmet) AND session-threshold apply is an unconsumed stub (`getActiveProfile` returns baseline). No `applied=true` row has ever been written.
4. **`LESSON_INJECTION_ENABLED` — live but injecting nothing.** 0 approved lessons; the 3 proposed are below the conf-0.5 floor. `buildLessonContext` returns `""` on every agent call.
5. **`POSITION_SIZE_CIRCUIT_BREAKER_ENABLED` — was already default-on.** Flip is a redundant no-op (still effective, just no state change).

## Genuinely effective from the flip
- **RISK_LEVEL_HARD_GATE_ENABLED** — has a real call-site with teeth; post-flip behaviour **not yet observable** (weekend). VERIFY Monday.
- (POSITION_SIZE_CIRCUIT_BREAKER is effective but was already on, so not "from the flip".)

## The learning loop, end-to-end (why "continuous learning" is NOT actually running)
```
derive (CRASHING nightly) → propose → approve (0 approved; auto-promote NOT DEPLOYED / #73) → inject (returns "" ) → trade
```
Every stage is broken or empty. Flipping the env flags did not light up the loop. To make it real: (a) merge+deploy #73, (b) fix the derive-lessons.mjs nightly crash, (c) get lessons approved with conf ≥ 0.5. Until then the lesson half of "alt er flippa" is cosmetic.

## Caveats
- Worker env values are not readable from this session. "Flipped (inferred)" = behaviour/side-effect implies the flag is on; it is not a direct read.
- `/calibration/status` and `runtimeManifest.flags` env-echoes reflect the **API** service env, NOT the worker — do not read them as worker-flip proof. The DB-backed fields on those endpoints (multipliersSource, calibration_log dates, lesson counts) ARE authoritative.
- RISK_LEVEL gate effect is unverifiable until market reopens.

## Follow-ups (for operator / Karri)
- **#73:** merge + deploy, then re-confirm auto-promote writes approvals.
- **derive-lessons crash:** run `AGENT_LESSONS_ENABLED=true LESSON_DERIVATION_ENABLED=true LESSON_DERIVATION_DRY_RUN=true DATABASE_URL=… node scripts/firehose/derive-lessons.mjs` with logs to pin the exit-1 line (fetch verified OK → suspect embeddings/INSERT).
- **VERIFY-BY Mon 2026-06-08:** first post-flip `risk_level would_reject=true` row should carry `hard_rejected=true`.
- **SAFE_AUTO_APPLY:** still inert even if flipped — needs engine_scores volume (≥30/engine) AND the `getActiveProfile`/`calibration_profiles` read-back to be wired before it can change decisions.
