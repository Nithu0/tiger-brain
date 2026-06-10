# Learning-loop activation map — verified

Author: ai (read/analysis only) · 2026-06-04 · Repo: /home/nithu/code/ai-assistent
Context: prinsipp 6 (30-day autotune wait) rescinded 2026-06-03 → continuous learning allowed.
Only the trade-CHANGING switches still gate via Karri. Nothing flipped here; this is a map.

---

## 1. Verification of ai-2's corrected claims

All four claims VERIFIED against current HEAD (node-migration-nexus, after 7ec793c).

| Claim | Verdict | Evidence |
|---|---|---|
| Lesson injection IS wired in live agents | TRUE | `buildLessonContext(...)` called at `risk-advisor.ts:113` and `trade-critic.ts:68`; imported at risk-advisor:21 / trade-critic:18. |
| Engine-multiplier CONSUMER is live | TRUE | `conviction/scoring.ts:53-54`: `perfMult = getEnginePerformanceMultiplier(...)`, `weight = baseWeight * perfMult` on every cycle. |
| PRODUCER only fires in APPLY branch → RECOMMEND_ONLY = no-op (mult stuck at 1.0) | TRUE | `setEnginePerformanceMultipliers` is only called inside `if (mode === "APPLY")` at `calibrate-weights.ts:112-116`. `calibration.ts:333-334` maps engineMode = APPLY only when `mode === "SAFE_AUTO_APPLY"`. Default RECOMMEND_ONLY → APPLY branch never runs → `getEnginePerformanceMultiplier` returns neutral 1.0 → scoring multiply is a no-op. |
| Hardcoded "RECOMMEND_ONLY" literal at orchestrator:696 now env-driven after 7ec793c | TRUE — FIXED | Now `runCalibration(this.db, calibrationMode())` at `orchestrator.ts:719` (import line 23). `calibrationMode()` (`calibration.ts:43-49`) reads `CALIBRATION_MODE` env, defaults RECOMMEND_ONLY, unrecognised value → RECOMMEND_ONLY (fail-safe). Behaviour-neutral at default; the flip is now an env change, not a code change. |

### Correction to the GOAL's flag names (IMPORTANT)

The task brief lists `AGENT_KNOWLEDGE_ENABLED` + `KNOWLEDGE_INJECTION_ENABLED` as the
lesson-injection gate. That is WRONG — those gate a SEPARATE subsystem.

There are **two distinct injection subsystems**, both wired into the same two agents:

1. **agent-lessons** (the loop in scope here: derive → propose → approve → inject)
   - Gate: `AGENT_LESSONS_ENABLED` + `LESSON_INJECTION_ENABLED` (`agent-lessons/injection.ts:33-37`)
   - Call sites: risk-advisor:113, trade-critic:68 (`buildLessonContext`)
2. **agent-knowledge** (YouTube/GitHub-style ingested knowledge, NOT the trade-outcome learning loop)
   - Gate: `AGENT_KNOWLEDGE_ENABLED` + `KNOWLEDGE_INJECTION_ENABLED` (`agent-knowledge/injection.ts:30-31`)
   - Call sites: risk-advisor:114, trade-critic:69 (`buildKnowledgeContext`)

For the trade-outcome learning loop, the Karri-gated injection flags are
**`AGENT_LESSONS_ENABLED` + `LESSON_INJECTION_ENABLED`** — not the KNOWLEDGE pair.
(If operator also wants ingested-knowledge injection live, the KNOWLEDGE pair is a
separate, also-money-near activation; out of scope for the lessons loop.)

---

## 2. Exact ordered activation map

### (a) SAFE / infra — flip freely post-prinsipp-6 (Claude/operator, no Karri)

These prime and observe the loop without changing any trade decision.

1. **`AGENT_LESSONS_ENABLED=true`** + **`LESSON_DERIVATION_ENABLED=true`**
   → turns on the PRODUCER. Worker auto-runs `derive-lessons.mjs` daily at 04:00 UTC
   (`apps/worker/src/index.ts:229-233`, idempotent per UTC-day via `firm_state`).
   Writes rows with `status='proposed'` only (`derive-lessons.mjs:221`). Changes NO
   trade decision — proposed lessons are never injected. This is the "derivation WRITE"
   step.
   - Caveat: ai-2 flagged the derivation thresholds (anti_pattern WR ≤ 0.40 / pattern
     ≥ 0.60, MIN_SAMPLE 5) as strategy params. They only affect WHICH proposals get
     written, not any live decision, so writing proposals is safe. If you want Karri
     to bless the thresholds before they shape the proposal set, do it — but it does
     not block flipping these two for capture/observability.
   - Optional dry-run first (zero writes): `FIREHOSE_FORCE=true LESSON_DERIVATION_DRY_RUN=true node scripts/firehose/derive-lessons.mjs`.

2. **`CALIBRATION_MODE=RECOMMEND_ONLY`** (already the default — leave as-is)
   → calibration computes + logs recommendations to `calibration_log` with
   `applied=false` every 20 cycles. Observability only. Nothing to flip; just confirm
   it is not set to OFF.

3. **`SHADOW_FORWARD_TEST_ENABLED=true`** (optional, infra)
   → per-cycle shadow_forward_test rows (what each strategy WOULD do). Pure read-side
   forward-test, zero trade impact (default OFF; 7ec793c).

4. **Observability** (already shipped, no flag): `/calibration/status` (mode + lesson
   countByStatus + multipliers + log) and the `/learning` dashboard panel (5341fb3).
   Use these to watch what the loop WOULD do before any trade-changing flip.

Net effect of (a): proposals accumulate, calibration recommendations + shadow
forward-test fill up, all visible — and **not one live trade decision changes.**

### (b) Trade-CHANGING — require Karri sign-off (do NOT flip)

Activate in this order; each depends on the prior.

A. **`LESSON_INJECTION_ENABLED=true`** (with `AGENT_LESSONS_ENABLED=true` from (a))
   → injects APPROVED lessons into risk-advisor + trade-critic prompts → changes
   vetoes/sizing advice. Karri must approve injected-prior semantics + filters
   (minConfidence 0.5, validityDays 30, maxLessons 8 — `injection.ts`). Requires
   approved lessons to exist first (see blocker below).

B. **`CALIBRATION_MODE=SAFE_AUTO_APPLY`**
   → `applied=true`, `setEnginePerformanceMultipliers` fires, scoring.ts:54 stops
   being a no-op → engine weights + session thresholds self-adjust at runtime.
   Karri reviews `BOUNDS` (calibration.ts) + `PERF_MULT_BOUNDS` (0.70..1.20). Consider
   intermediate `SHADOW_COMPARE` if/when implemented.

C. **Auto-promotion of agent_lessons (proposed → approved)** — NOT BUILT YET.
   Today the consumer reads `status='approved'` only (`client.ts:141-145`); the only
   promotion path is manual `!lesson approve <id>` via the Discord listener
   (`discord-listener.mjs`). No `autoApprove`/`auto_promote` code exists anywhere
   (grep clean). Any auto-promotion rule (e.g. confidence ≥ X + sample ≥ N) is a
   strategy-governance decision → Karri + operator, AND a new build.

(The `AGENT_KNOWLEDGE_ENABLED` + `KNOWLEDGE_INJECTION_ENABLED` pair is a separate
money-near activation for ingested-knowledge injection; list it for Karri only if
operator wants that subsystem live too.)

---

## 3. Proposal review — docs/strategy/proposals/2026-06-03_activate-learning-loop.md

**Mostly correct and well-scoped. Three gaps:**

- **Correct:** the two trade-altering flips (LESSON_INJECTION + CALIBRATION_MODE=
  SAFE_AUTO_APPLY) are exactly right and the file:line refs (risk-advisor:113,
  trade-critic:68, scoring:53-54) are accurate. Rollback story (env → 30s) holds.
  Status `proposed`, Reviewer Karri, HOLD-until-morning note all present.

- **Gap 1 — missing flag in the injection activation.** Proposal item 1 says
  "`LESSON_INJECTION_ENABLED=true` (+ `AGENT_LESSONS_ENABLED=true`)". Correct, but it
  does not state that `AGENT_LESSONS_ENABLED` is ALSO required for the producer in
  the "already activating as pure infra" line — it lists only `LESSON_DERIVATION_ENABLED`
  there (line 22). Derivation needs BOTH `AGENT_LESSONS_ENABLED` AND
  `LESSON_DERIVATION_ENABLED` (`derive-lessons.mjs:51-52`). Minor, but the infra line
  understates the flag set.

- **Gap 2 — the proposed→approved starvation is named but not framed as a blocker.**
  The proposal mentions approval is manual `!lesson approve` and auto-promotion is a
  separate build (good, it's in "Questions for Karri"). But it does not call out that
  **injection (A) is inert until at least one lesson is approved**, so flipping
  `LESSON_INJECTION_ENABLED` alone changes nothing until the manual approval (or a
  future auto-promotion) runs. Activation A's real precondition is "≥1 approved lesson",
  not just the flag.

- **Gap 3 — no mention of the derivation thresholds being Karri-owned strategy params.**
  ai-2's plan flags WR ≤0.40/≥0.60 + MIN_SAMPLE 5 as strategy parameters worth Karri's
  eyes. The proposal treats derivation as pure infra. Defensible (it only writes
  proposals), but worth a one-liner so Karri sees the thresholds.

Verdict: ship-able as-is for Karri, but add the "≥1 approved lesson is a precondition
for injection" note and the `AGENT_LESSONS_ENABLED` clarification.

---

## 4. The proposed→approved pipeline gap

- Producer writes `status='proposed'` (`derive-lessons.mjs:221`).
- Consumer (`listApprovedFor`, `client.ts:141-145`) reads `status='approved'` ONLY.
- Promotion bridge: `approve()` (`client.ts:110-124`) flips proposed→approved, but its
  only caller is the manual Discord command `!lesson approve <id>`.
- **No auto-promotion exists** (grep for autoApprove/auto_promote/auto-promot: empty).

So even with all of (a) on for weeks, `proposed` lessons pile up and inject NOTHING
until a human runs `!lesson approve`. Auto-promotion is unbuilt AND governance-gated.

---

## Single biggest remaining blocker to lessons reaching a live decision

**The proposed → approved promotion gap.** The injection consumer reads
`status='approved'` only, the sole promotion path is manual Discord `!lesson approve`,
and no auto-promotion code exists. Even after flipping every (a)-safe flag and the
Karri-gated `LESSON_INJECTION_ENABLED`, zero lessons reach risk-advisor/trade-critic
until someone manually approves them (or auto-promotion is built + Karri-approved).
The flag flips are necessary but not sufficient — the loop is starved at the approval
weld point, not the injection weld point.

(Distinct, smaller blocker for the calibration half: `SAFE_AUTO_APPLY` is the only
thing that makes the engine-multiplier producer fire; until then scoring.ts:54 stays a
1.0 no-op. That one IS purely a single Karri-gated flag flip, no extra build.)
