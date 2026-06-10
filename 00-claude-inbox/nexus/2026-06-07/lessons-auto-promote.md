# Lessons auto-promotion (proposed → approved) — build report

Date: 2026-06-07
Branch built on: `main` (no commit/push — operator handles git via feature branch)
Spec source: Karri (binding, built exactly, not loosened)

## What this closes

The last gap in the learning loop. The injection consumer
(`apps/worker/src/firm/agent-lessons/client.ts:listApprovedFor` ~:142) reads ONLY
`status='approved'`. The only proposed→approved path was the manual Discord
`!lesson approve <id>` (`scripts/firm/discord-listener.mjs` ~:157, mirrors
`AgentLessonsClient.approve` ~:111). So even with `LESSON_INJECTION_ENABLED=true`,
zero derived lessons ever reached a live agent. Auto-promotion promotes a small,
conservative, capped subset each day — gated because it is trade-influencing.

## Lesson schema fields keyed on (the ACTUAL columns)

There is **no per-observation table**. Each lesson row is the aggregate; the
deriver uses ON CONFLICT(fingerprint) natural-voting to accumulate. So both Karri
gates map onto aggregate columns:

- **(a) N≥X observations → `sample_size`** (int). The natural-voting accumulator:
  every re-observation of the same cluster increments it. This IS the observation
  count.
- **(b) consistent sign → derived from `outcome_score`** (numeric, range −1..+1).
  Producer sets `outcome_score = -1 + 2*wr` (see `derive-lessons.mjs:120,138`), so
  `wr = (outcome_score+1)/2` and **consistency = max(wr, 1−wr) ∈ [0.5, 1.0]**.
  - pattern wr=0.85 → consistency 0.85
  - anti_pattern wr=0.15 → consistency 0.85 (lopsided in the other direction also qualifies)
  - mid-range wr=0.5 → consistency 0.5 (never promotes)
  - `outcome_score` null/non-numeric → ineligible (no sign).
  This is internally consistent with the producer's own thresholds (anti ≤0.40 /
  pattern ≥0.60).

Other columns used: `status` ('proposed' guard), `approver_id` + `approved_at`
(daily-cap counting + attribution), `last_validated_at` (set on promote, same as
manual path), `lesson_type`/`agent_role`/`rationale` (logging only).

## Env flags + defaults (all conservative, DEFAULT OFF)

| Flag | Default | Meaning |
|---|---|---|
| `LESSON_AUTO_PROMOTE_ENABLED` | `false` | Master gate. Off → no-op early return, zero DB calls, behaviour identical to today (manual approval only). |
| `LESSON_AUTO_PROMOTE_MIN_OBSERVATIONS` | `20` | Gate (a): `sample_size >= this`. |
| `LESSON_AUTO_PROMOTE_MIN_CONSISTENCY` | `0.8` | Gate (b): consistency-ratio threshold. |
| `LESSON_AUTO_PROMOTE_DAILY_CAP` | `3` | Max auto-approvals per UTC day. Never mass-approves. |

Both (a) AND (b) must hold. Daily cap counts existing same-day auto-approvals
(`approver_id = 'auto-promote:derive-lessons'`, `approved_at::date = today UTC`)
and only spends the **remaining** budget — survives a re-run / restart in the same
day. Eligible-but-over-cap lessons are deferred (logged as `skipped_cap`), not lost.

## Where it's wired to run

Inside the daily 04:00 UTC firehose flow — `scripts/firehose/derive-lessons.mjs`,
**after** the derivation loop completes, on the **same** DB connection:

```
console.log("[derive-lessons] done: ...");
if (!dryRun) {
  try { await autoPromoteEligibleLessons(client); }
  catch (err) { console.error("[derive-lessons] auto-promote failed (non-fatal): ..."); }
}
```

This matches the existing pattern exactly: the worker (`apps/worker/src/index.ts`
~:230) already spawns `derive-lessons.mjs` once/UTC-day at 04:00, gated by
`AGENT_LESSONS_ENABLED + LESSON_DERIVATION_ENABLED`, with success/failure
idempotency markers in `firm_state`. No change to `index.ts` was needed — the
spawn contract is unchanged. Dry-run skips promotion (no writes in dry-run).

## Files

- NEW `scripts/firehose/auto-promote-lessons.mjs` — `autoPromoteEligibleLessons(db, {env, logger})`
  + pure helpers (`consistencyFromOutcomeScore`, `evaluateEligibility`,
  `autoPromoteConfig`, `isAutoPromoteEnabled`, `AUTO_APPROVER_ID`).
- NEW `scripts/firehose/auto-promote-lessons.test.mjs` — 14 tests (MockDb).
- EDIT `scripts/firehose/derive-lessons.mjs` — import + post-derive call (the only
  behaviour change; both wrapped to be no-op when flag off / fail-safe).

## Fail-safe (operator-prinsipp 2 — data never stops)

- Flag off → early return before any DB call (verified by a test asserting
  `db.calls.length === 0`).
- Per-lesson promote error is caught + logged; the batch continues (one bad row
  can't abort). status='proposed' guard makes promote idempotent + race-safe vs a
  concurrent manual approve.
- A top-level throw (e.g. the candidate SELECT itself fails) propagates to the
  caller — and the caller in `derive-lessons.mjs` wraps it in try/catch logging
  `auto-promote failed (non-fatal)`, so it can never abort the derive run.
- Audit: writes `firm_state` key `firehose:auto_promote_lessons:<UTC-date>` with
  the run summary (promoted ids, eligible, skipped_cap, cap). Audit-write failure
  is itself non-fatal. Every promotion is logged LOUD with id, type, role,
  sample_size, consistency, outcome_score, rationale.

## Logging (LOUD, never silent)

Per run: enabled line with thresholds; already-today + remaining-budget; scanned
vs meet-N+consistency counts; one `[auto-promote] PROMOTED id=... ...` line per
promotion; a cap-reached line listing deferred count; a `done:` summary line.

## Verification

- `node --test scripts/firehose/auto-promote-lessons.test.mjs` → **14/14 pass**.
- `node --test scripts/firehose/derive-lessons.test.mjs` (existing) → **6/6 pass** (unbroken).
- `apps/worker` `tsc --noEmit` → **exit 0** (clean).
- `apps/worker` `npm test` → **1148/1148 pass** (unchanged; new firehose tests are
  additive, run via `node --test`, not in the worker npm-test glob).
- api workspace untouched (changes are pure `.mjs` scripts).

## Default-off = behaviour-neutral — confirmed

With `LESSON_AUTO_PROMOTE_ENABLED` unset/false, `autoPromoteEligibleLessons`
returns `{enabled:false, promoted:0}` before touching the DB. The only
proposed→approved path remains the manual Discord `!lesson approve`. Nothing in
the trade loop, derivation, or injection changes until the operator + Karri flip
the flag.

## Open governance note (for operator/Karri)

This is trade-influencing per CLAUDE.md prinsipp 6 (lesson-injection switches gate
via Karri). The infra is built + default-off; **activation** of
`LESSON_AUTO_PROMOTE_ENABLED` (and any non-default threshold) is a Karri + operator
decision. Recommend a strategy proposal doc before flipping, alongside
`LESSON_INJECTION_ENABLED`. `docs/ref/feature-flags.md` row not yet added (can add
on request — held back to keep this a focused diff).
