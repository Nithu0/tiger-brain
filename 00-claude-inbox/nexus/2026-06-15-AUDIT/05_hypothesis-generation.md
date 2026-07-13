# Nexus Audit — Stages (6) Error Analysis + (7) Hypothesis Generation

Date: 2026-06-15
Auditor scope: lesson-derivation pipeline, agent_lessons, lesson injection, hypothesis structures.
Method: read-only code review + live DB (`mcp__nexus-pg-rw`).

## VERDICT: WEAK

Error/loss analysis runs automatically and is currently healthy (the 17-day crash is
genuinely fixed). But the output is **loss/win clusters with a fixed canned
recommendation**, not structured testable hypotheses, and nothing it produces feeds a
backtest or a task — it only becomes prompt text for two agents to "consider." That is
exactly the learn-by-thinking-more loop the operator rejected.

---

## Q1 — Does error analysis run automatically? Is it producing output or crashing?

**Runs automatically: YES. Currently healthy: YES (crash fixed).**

- Scheduler: `apps/worker/src/index.ts` (~line 231-283) — a `setInterval` daily trigger
  at 04:00 UTC spawns `scripts/firehose/derive-lessons.mjs` as a subprocess. State key
  `firehose:derive_lessons:<utc-date>` in `firm_state` guards against double-spawn and
  records success/failure.
- It is NOT an OS cron — it's an in-process interval inside the worker. Gated by
  `AGENT_LESSONS_ENABLED` + `LESSON_DERIVATION_ENABLED`.

**The 17-day crash is real and is in the DB as failure markers** (`firm_state`):
- `firehose:derive_lessons:2026-06-04:failed` … `2026-06-08:failed`, exitCode 1.
- 06-08 marker captured the stderr:
  `Error: Cannot find module '/app/apps/worker/scripts/firehose/derive-lessons.mjs'`
  → MODULE_NOT_FOUND. This is the script-path-across-cwd bug fixed in `676c222`
  (branch `fix/firehose-script-path`).
- **Recovery confirmed:** success markers exist for every day 2026-06-09 → 2026-06-15
  (no `:failed` suffix). New `agent_lessons` rows were written on 06-09, 06-10, 06-14,
  06-15. The fix is verified on live data, not just "tsc clean."

So: automatic ✓, not crashing now ✓, producing output ✓.

**Caveat — output quality is degraded by upstream data starvation.** Most derived
clusters bucket on `regime=UNKNOWN, session=UNKNOWN` and `close_reason=OANDA_EXTERNAL`
/ `OANDA_SL_TP` (see rows below). The deriver groups by
`portfolio_regime_at_entry / session_at_entry / close_reason` from `simulated_orders`,
and those columns are largely null/UNKNOWN, so the "clusters" are not actually
segmenting by anything actionable. A lesson that says "UNKNOWN regime in UNKNOWN
session" is not a usable error analysis.

## Q2 — Are outputs STRUCTURED HYPOTHESES or just clusters/vague text?

**Just clusters. NOT hypotheses.** This is the core failure for stage 7.

`buildLessonForCluster()` (derive-lessons.mjs:103-158) produces, per loss-cluster:
- `lessonType`: `anti_pattern` (WR ≤ 0.40) or `pattern` (WR ≥ 0.60)
- `condition`: `{regime, session, close_reason}`
- `action`: `{recommendation: "reject_or_size_down" | "favor_or_size_up", observed_wr,
  observed_avg_pnl}` — **the recommendation is a hard-coded constant string**, two
  possible values, with zero reasoning about WHICH change to make.
- `rationale`: a template f-string ("X regime in Y session … Z% WR over N trades…").

Map this against the required hypothesis fields:

| Required field        | Present? | Where / gap |
|-----------------------|----------|-------------|
| problem               | partial  | rationale string describes the loss cluster |
| supporting data       | yes      | observed_wr, avg_pnl, n in action_jsonb |
| proposed change       | **NO**   | only a canned 2-value enum, not a concrete change (no "add time filter 13:30–15:30", no param value) |
| expected effect       | **NO**   | not represented anywhere |
| test method           | **NO**   | nothing says how to test it |
| success criterion     | **NO**   | absent |
| rollback rule         | **NO**   | absent |

The example the operator wants — *"loses most 13:30–15:30 → test a time filter"* — cannot
even be expressed: there is no time-of-day clustering, no "proposed change" field beyond
reject/favor, and no test/criterion/rollback fields. **It is a loss-cluster labeler, not
a hypothesis generator.**

## Q3 — Is there a `hypotheses` table?

**NO.** Live schema check returned only: `agent_lessons`, `postmortems`,
`postmortem_streaks`, `signal_postmortem`. No `hypotheses` table exists anywhere.

"Hypotheses" live in two unrelated, weaker places:
1. `agent_lessons` rows (the clusters above) — closest thing, but not structured as
   hypotheses (see Q2).
2. `scripts/daily-analysis.mjs` `hypothesizeWhy()` / `printHypotheses()` — a **standalone
   manual CLI** that prints Norwegian per-trade hunches ("Lav confidence … borderline
   kvalitet") to the terminal. Not persisted, not structured, not scheduled, not wired
   into anything. Operator-run only.
3. `agent-trigger.ts:116` asks an LLM agent for "one falsifiable hypothesis" inside a
   free-text prompt — output is chat text, not a stored/testable record.

`agent_lessons` columns (live): id, agent_role, domain, lesson_type, status,
condition_jsonb, action_jsonb, outcome_score, sample_size, confidence, proposer_id,
approver_id, approved_at, fingerprint, embedding, rationale, created_at,
last_validated_at. No expected_effect / test_method / success_criterion / rollback
columns.

## Q4 — Do hypotheses feed anything testable, or just prompt text?

**Just prompt text. Confirmed by tracing every consumer of agent_lessons.**

- Consumers of `agent_lessons` / `listApprovedFor` / `LessonRow` (non-test, non-dist):
  `client.ts`, `injection.ts`, plus read-only display in API routes
  `explorer.ts`, `calibration.ts`, `firehose.ts`. That's it.
- `buildLessonContext()` (injection.ts) is called by exactly two agents:
  `risk-advisor.ts:114` and `trade-critic.ts:69`. It formats approved lessons into a
  markdown block injected into the agent's system prompt, prefaced with:
  *"Treat them as strong priors when relevant — but use judgment if context differs."*
  → **This is learn-by-thinking-more.** No code path turns a lesson into a backtest run,
  a parameter change, a gate, or a task/ClickUp item.
- The backtest scripts (`scripts/backtest-*.mjs`, `_fvg_backtest*.mjs`) are standalone
  manual sweeps. **Zero references to agent_lessons.** No automated lesson→backtest link.
- No `hypotheses`/task queue wiring; `agent_tasks` (if present) is not fed by the deriver.

### Activation state (why even the weak loop is mostly inert)
- Injection double-gated: `AGENT_LESSONS_ENABLED` + `LESSON_INJECTION_ENABLED`, both
  default OFF. Even when on, only `status='approved'` lessons inject.
- Promotion: only path to `approved` is manual Discord `!lesson approve <id>` OR
  `auto-promote-lessons.mjs` (gated `LESSON_AUTO_PROMOTE_ENABLED`, default OFF;
  Karri-owned because it alters trade decisions).
- Live row counts: **8 `proposed`, 3 `archived`, 0 `approved`.** So today, even if
  injection were enabled, `listApprovedFor` returns nothing → zero lessons reach any
  agent. The learning loop is connected but currently carries no payload.

## Live evidence (agent_lessons sample)

- id 11/10 (06-15): anti_pattern, `{UNKNOWN, UNKNOWN, OANDA_EXTERNAL}`, "0.0% WR over 7
  trades, net -1572.48", conf 0.875, proposed.
- id 7/6 (06-10): anti_pattern, `{TRENDING, unknown, OANDA_SL_TP}`, "16.7% WR over 6",
  conf 0.12.
- id 1-3 (05-21, archived): pre-crash rows; note id 2 "OANDA_BACKFILL … net -10841.42"
  — backfill noise treated as a tradeable loss cluster.
- All anti_pattern; recommendation always `reject_or_size_down`. No `pattern` rows have
  cleared. proposer_id = `derive-lessons-stats-<host>`.

---

## The gap, stated plainly

Between **"loss clusters injected into prompts"** (what exists) and **"structured
testable hypotheses"** (what's required):

1. **No proposed change.** A hypothesis must name a concrete, parameterized intervention
   (time filter, threshold value, gate). The system emits a 2-value enum
   (reject/favor) with no parameters.
2. **No expected effect / success criterion / rollback.** The four fields that make a
   hypothesis *falsifiable and reversible* simply do not exist in the schema.
3. **No test method and no executor.** A hypothesis must be runnable against the
   backtester or a shadow forward-test. The deriver has no edge to the backtest scripts.
4. **Dimension poverty.** Clustering is only regime×session×close_reason, and those are
   mostly UNKNOWN. The operator's canonical example (time-of-day) can't even be expressed
   — no intraday bucketing, no failed-criteria aggregation, no MFE/MAE.
5. **Terminal sink = a prompt.** The single wired output is text an LLM agent reads and
   "uses judgment" on — the explicitly-rejected learn-by-thinking-more pattern.

### Cheapest path to move WEAK → EXISTS (infra-only, Claude-ownable, no trade-decision change)
- Add a real `hypotheses` table (problem, supporting_data jsonb, proposed_change jsonb,
  expected_effect, test_method, success_criterion, rollback_rule, status, result jsonb).
- Have the deriver emit hypotheses, not just reject/favor: enrich clustering dims
  (add time-of-day, failed-criteria, MFE/MAE) so a "proposed change" can be concrete.
- Wire an automated executor: hypothesis → `backtest-strategies.mjs` (shadow/offline,
  no live behavior change) → write pass/fail vs success_criterion back to the row.
- Trade-altering activation (injecting/applying a *passed* hypothesis) stays Karri-gated.

The capture + scheduling + dedupe/voting + promotion plumbing is genuinely built and now
healthy — the missing piece is the hypothesis *object* and a test executor, not the
pipeline around it.
