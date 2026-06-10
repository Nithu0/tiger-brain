# Active-learning reactivation plan — Nexus XAUUSD

Author: ai-2 (systems auditor) · 2026-06-03 · Repo: /home/nithu/code/ai-assistent

Scope: map the learning machinery, confirm why nothing is learned at runtime,
and produce a reactivation plan that respects the infra-vs-strategy boundary
(prinsipp 6: no autotune before 30+ days data + explicit operator approval;
money-near changes go through Karri).

---

## (a) Why "nothing is learned at runtime" today — precise map

There are TWO independent learning subsystems. Both are fully built and both
are inert. Plus one observation that revises the V1/V9 finding.

### Subsystem 1 — Calibration engine (session thresholds + engine weights)

- `runCalibration()` is invoked at `apps/worker/src/firm/orchestrator.ts:696`
  every 20 cycles, but with a **hardcoded string literal** `"RECOMMEND_ONLY"` —
  not an env flag:
  ```ts
  runCalibration(this.db, "RECOMMEND_ONLY").catch(...)
  ```
  There is no `CALIBRATION_MODE` env read anywhere in the worker (grep of
  `apps/worker/src` returns only this call site + the function def). So the mode
  can never be anything but RECOMMEND_ONLY without a code change.

- In RECOMMEND_ONLY mode, `runCalibration` writes rows to `calibration_log`
  with `applied = (mode === "SAFE_AUTO_APPLY")` → always `false`
  (`calibration.ts:285-296`). Recommendations are computed, logged, discarded.

- **`getActiveProfile` is effectively dead.** `calibration.ts:328-332` always
  returns `getBaselineProfile(...)` (static), with an inline comment that the
  profile-table lookup "would" happen when SAFE_AUTO_APPLY is active. And the
  only caller of `getActiveProfile` in the worker is... none — grep of
  `apps/worker/src` (excluding tests) shows the sole hit is its own definition
  at `calibration.ts:328`. The orchestrator uses static `thresholds` +
  `applyDemoBoost` (orchestrator.ts:633-640), not the calibration profile. So
  even the static baseline path from calibration is unused by the live loop.

- **Engine performance multipliers — wired consumer, dead producer.** This is
  the most important nuance and partially revises the V1/V9 "computed and
  discarded" claim:
  - The CONSUMER is live: `conviction/scoring.ts:53-54` calls
    `getEnginePerformanceMultiplier(e.engine_name)` and multiplies base weight
    by it on every cycle. `config.ts:120` returns
    `perfMultipliers[engine] ?? PERF_MULT_BOUNDS.neutral`.
  - The PRODUCER is dead: `setEnginePerformanceMultipliers()` (config.ts:107)
    is only ever called from `engine-attribution/calibrate-weights.ts:116`,
    inside an `if (mode === "APPLY")` block. And the only caller of
    `calibrateEngineWeights` is `calibration.ts:310`, which maps
    `engineMode = mode === "SAFE_AUTO_APPLY" ? "APPLY" : "RECOMMEND_ONLY"`
    (calibration.ts:308-309). Since `mode` is hardcoded RECOMMEND_ONLY upstream,
    `engineMode` is always RECOMMEND_ONLY, so the APPLY branch never runs and
    `setEnginePerformanceMultipliers` is never called at runtime.
  - Net effect: `perfMultipliers` stays at the in-memory neutral default
    (1.0) for the worker's whole lifetime. The multiply at scoring.ts:54 is a
    no-op. The feedback loop the file header advertises
    ("engines → synthesis → trades → postmortem → engine_scores → here →
    multipliers → engines", calibrate-weights.ts:8-9) is open at exactly one
    weld point: the APPLY gate. Everything else is plumbed.

### Subsystem 2 — agent_lessons loop (derive → propose → approve → inject)

Four stages, gated independently. Revises the V1/V9 "3 dead points" — the
injection wiring into agents IS present (so it's a flag-state problem, not a
missing-call problem):

- PRODUCER: `scripts/firehose/derive-lessons.mjs`. Guarded by
  `isEnabled()` (lines 48-54): requires BOTH `AGENT_LESSONS_ENABLED=true` AND
  `LESSON_DERIVATION_ENABLED=true` (or `FIREHOSE_FORCE=true`). Default OFF →
  process exits 2 before touching the DB (line 246-249). No proposals are ever
  written. **Dead point 1.**

- INJECTION GATE: `agent-lessons/injection.ts:33-38` `isInjectionEnabled()`
  requires BOTH `AGENT_LESSONS_ENABLED=true` AND `LESSON_INJECTION_ENABLED=true`.
  `buildLessonContext` returns `""` early when off (line 50). Both flags default
  off. **Dead point 2.**

- INJECTION IS WIRED (correction to V1/V9): `buildLessonContext` is actually
  imported and called by two live firm-agents —
  `agent-bus/firm-agents/risk-advisor.ts:113` and
  `agent-bus/firm-agents/trade-critic.ts:68`. So the consumer side is NOT
  missing; it's a flag gate, not a missing call. (Whether those firm-agents
  themselves run depends on the agent-bus flags, a separate gate.)

- PROMOTION proposed→approved: `client.approve()` (client.ts:110-124) exists and
  honors `AGENT_LESSONS_ENABLED`. `listApprovedFor` (client.ts:141) only returns
  `status='approved'` rows, so injection shows nothing until something is
  approved. The approval trigger DOES exist — `scripts/firm/discord-listener.mjs`
  handles `!lesson approve <id>` (lines 135-200, runs the UPDATE directly).
  BUT: (i) the listener only runs if operator starts it and the lessons flags
  are on; (ii) with the producer dead, there are zero `proposed` rows to
  approve. So promotion is structurally reachable but starved of input.
  **Dead point 3** (no proposed rows + no running promotion path in practice).

Net: derive is off → zero proposals → nothing to approve → injection (even if
flagged on) returns `[]` → agents see no lessons. The loop is intact end-to-end
in code; it is dark because the first domino (derivation flag) never falls.

### Flag documentation gap

`docs/ref/feature-flags.md` documents only `STRUCTURE_INCLUDE_TECH_DIR` (line 49)
and `ORB_ONLY_MODE` (line 57). None of `AGENT_LESSONS_ENABLED`,
`LESSON_DERIVATION_ENABLED`, `LESSON_INJECTION_ENABLED`, nor any
`CALIBRATION_MODE` appear. `docs/ref/incomplete-features.md:13` correctly states
calibration + engine-attribution are "fully implemented but env-gated… awaiting
data or operator decision." So the dormancy is intentional, but the flags are
under-documented relative to how load-bearing they are.

---

## (b) Reactivation plan — infra-now vs Karri-gated

### Buildable NOW as infra/plumbing (Claude/ai-1, no money-impact)

These make the loop *observable and primed* without changing any trading
behaviour. They satisfy prinsipp 2 (data never stops) and prinsipp 3 (small
curating adjustments may be automatic).

1. **Document the flags.** Add `AGENT_LESSONS_ENABLED`,
   `LESSON_DERIVATION_ENABLED`, `LESSON_INJECTION_ENABLED`, and the
   calibration-mode story (currently a hardcoded literal) to
   `docs/ref/feature-flags.md`. Pure docs.

2. **Make calibration mode env-driven (infra, no behaviour change while default
   stays RECOMMEND_ONLY).** Replace the hardcoded literal at orchestrator.ts:696
   with `runCalibration(this.db, calibrationMode())` where `calibrationMode()`
   reads `CALIBRATION_MODE` env and defaults to `"RECOMMEND_ONLY"`. This is a
   no-op at default; it just removes the need for a code edit to ever flip it.
   The *flip itself* to SAFE_AUTO_APPLY is Karri-gated (see below). Filing the
   env-var refactor is plumbing; turning the knob is strategy.

3. **Turn on derivation in DRY_RUN to prime + verify the producer** without
   writing: run `derive-lessons.mjs` with `FIREHOSE_FORCE=true
   LESSON_DERIVATION_DRY_RUN=true` against the DB. Confirms clusters exist,
   schema columns resolve, and would-be lessons look sane. No DB writes, no
   behaviour change. Surface the dry-run output in the morning digest
   (`digest-sections.mjs` already references `!lesson approve`).

4. **Build observability for the loop**: a dashboard/digest panel showing
   `agent_lessons` `countByStatus()` (client.ts:172) and recent `calibration_log`
   rows (already written every cycle in RECOMMEND_ONLY). Lets operator + Karri
   SEE what the engine *would* do before anything is applied. Pure read-side.

5. **Keep injection gated but verify the agent-side wiring** with a unit/integration
   check that risk-advisor + trade-critic actually receive a non-empty lessons
   block when fed an approved row (the call sites at risk-advisor.ts:113 /
   trade-critic.ts:68 exist; prove the formatting reaches the prompt).

### Requires Karri proposal + prinsipp-6 operator approval to ACTIVATE

These change money-near behaviour (thresholds, weights, what agents are told).
File a `docs/strategy/proposals/` doc; do NOT flip.

A. **`AGENT_LESSONS_ENABLED=true` + `LESSON_DERIVATION_ENABLED=true` (WRITE
   mode).** Starts writing `proposed` lessons. Arguably borderline-infra (it only
   writes proposals, changes no decisions), but the derived anti_pattern/pattern
   thresholds (WR ≤ 0.40 / ≥ 0.60, MIN_SAMPLE 5 — derive-lessons.mjs:65-67) are
   *strategy parameters*. Let Karri sign off on the thresholds even if the write
   itself is harmless. Also gated by prinsipp 6's 30-day-data bar — confirm
   `simulated_orders` has ≥30d of post-epoch closed trades first.

B. **`LESSON_INJECTION_ENABLED=true`.** This changes what risk-advisor and
   trade-critic are told, which influences their vetoes/sizing advice → directly
   money-near. Karri must approve the injected-prior semantics and the
   confidence/recency filters (minConfidence 0.5, validityDays 30,
   maxLessons 8 — injection.ts:52-54). Requires approved lessons to exist first
   (so A must land + operator must `!lesson approve` real rows).

C. **`CALIBRATION_MODE=SAFE_AUTO_APPLY`** (the autotune flip). This is the
   canonical prinsipp-6 action: it lets session thresholds AND engine
   multipliers self-adjust at runtime (`applied=true` in calibration_log,
   `setEnginePerformanceMultipliers` fires, scoring.ts:54 stops being a no-op).
   Hard-gated: 30+ days data + explicit operator approval + Karri review of the
   bounds (`BOUNDS` calibration.ts:52-60, `PERF_MULT_BOUNDS` 0.70..1.20).
   Recommend an intermediate step: `SHADOW_COMPARE` if/when implemented, to run
   calibrated logic in parallel for evaluation before APPLY.

D. **Promotion policy.** Today promotion is manual operator `!lesson approve`.
   Any *auto*-promotion rule (e.g. auto-approve at sample_size ≥ N + confidence
   ≥ X) is a strategy-governance decision → Karri + operator. Manual approval
   stays the default and is fine as infra.

---

## (c) Verdict — plumbing job or strategy-governance decision?

**Both, in sequence — but the gating bit is governance, not plumbing.**

The plumbing is ~90% done. Two whole learning subsystems are wired end-to-end:
the calibration consumer (scoring.ts:53) is live, the injection consumer
(risk-advisor/trade-critic) is live, the approval path (Discord listener) exists,
the producer (derive-lessons) exists and is hardened against schema drift. The
only genuinely *missing* infra is small: env-drive the calibration mode
(currently a hardcoded literal, orchestrator.ts:696) and add observability +
docs. A competent infra session closes that in an afternoon, with zero
behaviour change.

What is NOT a plumbing job — and is the real reason "nothing is learned at
runtime" — is the deliberate set of OFF flags and the one hardcoded
RECOMMEND_ONLY. Those are exactly the prinsipp-6 / Karri gates working as
designed. Flipping `SAFE_AUTO_APPLY` (autotune), `LESSON_INJECTION_ENABLED`
(changes what agents are told), and the derivation thresholds are all
money-near and explicitly require 30+ days of data + operator + Karri.

So: "active learning" is mostly a **strategy-governance decision wearing a thin
plumbing coat.** Claude/ai-1 should: (1) document the flags, (2) env-drive the
calibration mode, (3) run derivation in DRY_RUN to prove the producer, (4) build
the status/calibration_log observability panel. Then hand Karri a proposal for
the four activations (A–D) with the bounds and thresholds laid out, gated on the
30-day data check. Do not flip anything. The system is not failing to learn
because it can't — it's because the operator/strategy owner have correctly not
yet turned it on.

---

### File:line index

- orchestrator.ts:696 — hardcoded `runCalibration(..., "RECOMMEND_ONLY")`
- orchestrator.ts:633-640 — live loop uses static thresholds + demo boost (not calibration profile)
- calibration.ts:111-114 — `runCalibration` signature, default RECOMMEND_ONLY
- calibration.ts:285-296 — `applied = SAFE_AUTO_APPLY` (always false at runtime)
- calibration.ts:308-310 — engineMode mapping → calibrateEngineWeights
- calibration.ts:328-332 — `getActiveProfile` returns static baseline; no live caller
- calibrate-weights.ts:62-123 — engine weight calc; APPLY branch (112-123) never reached at runtime
- conviction/config.ts:107-123 — `setEnginePerformanceMultipliers` / `getEnginePerformanceMultiplier`
- conviction/scoring.ts:53-54 — LIVE consumer: `baseWeight * getEnginePerformanceMultiplier(...)`
- derive-lessons.mjs:48-54 — producer guard (dead point 1)
- derive-lessons.mjs:65-67 — derivation thresholds (Karri-owned)
- agent-lessons/injection.ts:33-38,50 — `isInjectionEnabled` (dead point 2)
- agent-lessons/injection.ts:52-54 — injection filters (Karri-owned)
- risk-advisor.ts:113 / trade-critic.ts:68 — LIVE injection call sites
- client.ts:110-124 — `approve()` proposed→approved
- client.ts:141-153 — `listApprovedFor` (approved-only)
- discord-listener.mjs:135-200 — `!lesson approve/archive/status` (promotion path exists)
- feature-flags.md:49,57 — only 2 flags documented; lessons/calibration flags absent
- incomplete-features.md:13 — "fully implemented but env-gated… awaiting data or operator decision"
