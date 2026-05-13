---
date: 2026-05-13
type: audit
project: nexus
status: open
---

# Agent-bus dormant subsystems audit (13.5)

Read-only audit of three subsystems the broader agent-bus audit flagged as queued-but-not-progressing. Findings are code+DB based, no behaviour change.

## 1. Review-drainer — NO WORKER-SIDE DRAINER EXISTS

**State**: 4 `role='review'` tasks queued (oldest 2026-05-12T17:08Z, newest 19:57Z). 36 `role='review'` done historically — all claimed_by `atlas-2474-mp0zidi8` (local Ralph runner), most recent done 2026-05-11T16:44Z.

**Root cause**: The worker only drains `role='research'` (see `apps/worker/src/firm/agent-bus/research-drainer.ts:241` — `WHERE status='queued' AND role='research'`). Review tasks are drained by `scripts/agent-review-runner.mjs`, which only runs inside the local Ralph loop on operator's WSL box (`scripts/firm/ralph.mjs`). When operator's Ralph isn't running, review tasks just sit.

The 4 currently-queued reviews are postmortem-reviews (`created_by='agent-trigger:new_postmortem'`, model `claude-opus`), publishing started after Ralph last ran on 12.5 evening.

**What's needed to activate**:
- **Operator-side**: launch `firm-up` (zellij Ralph mirror) on the WSL box. The runner already exists and works — it drained 36 prior reviews. No code change.
- **OR (longer-term)**: build a worker-side `runReviewDrainer()` mirroring `runResearchDrainer` that calls Claude SDK. Would need a Claude API key on Railway + `FIRM_REVIEW_DRAINER_ENABLED` flag. Operator-gated (cost + strategy-impact).

## 2. agent_lessons — TABLE EXISTS, WORKER SPAWNS, SCRIPT MISSING FROM IMAGE

**State**: `agent_lessons` table exists (0 rows lifetime). `firm_state` shows `firehose:derive_lessons:2026-05-{07..13}` keys written daily at 04:xx UTC — meaning **both** `AGENT_LESSONS_ENABLED=true` **and** `LESSON_DERIVATION_ENABLED=true` ARE set on Railway worker (otherwise the early-return at `apps/worker/src/index.ts:225-226` would skip the state-key write).

**Root cause**: `apps/worker/src/index.ts:247` spawns `node scripts/firehose/derive-lessons.mjs` from `process.cwd()`. The Railway worker `Dockerfile` (`apps/worker/Dockerfile`) only COPYs `packages/shared/dist` and `apps/worker/dist` into the runtime image — `scripts/firehose/` is NEVER copied. The spawn fails with ENOENT, child exits non-zero, but the `firm_state` idempotency marker is written BEFORE the spawn (lines 232-238), so it looks like derivation ran. 156 closed XAUUSD trades in last 60 days = plenty of input data; pipeline just never reaches the SQL.

Verified: `derive-lessons.mjs:39-42` `isEnabled()` requires both flags true (matches what worker also checks). Insert logic at `derive-lessons.mjs:137-161` writes directly to `agent_lessons` with ON CONFLICT increment — would work if the script were on the image.

**What's needed to activate**:
1. Patch `apps/worker/Dockerfile` to copy `scripts/firehose/` into runtime stage (after line 30, e.g. `COPY scripts/firehose ./scripts/firehose`). Also need `pg` module available in runtime, which already is (worker uses it).
2. Redeploy worker.
3. Wait for next 04:00 UTC tick — but note the state-key for 2026-05-13 is already set, so it'll skip today. Manual re-run via `FIREHOSE_FORCE=true ... node scripts/firehose/derive-lessons.mjs` after deploy verifies the path.
4. Consider moving the state-key write to AFTER successful subprocess exit (bug: failed derive shouldn't be marked done).

**Note**: agent-lessons client.ts (`apps/worker/src/firm/agent-lessons/client.ts`) is wired and respects `AGENT_LESSONS_ENABLED`, but **no worker code path calls `.propose()`**. The only writer is the unshipped derive-lessons script. Phase C (lesson injection into agent prompts at `injection.ts`) is wired but gated behind `LESSON_INJECTION_ENABLED` (off).

## 3. Predictions — NO `predictions` TABLE; WRITES TO `firm_memory`

**State**: No `predictions` table exists in production (`information_schema.tables` LIKE '%predict%' → only `agent_lessons` matched the lesson-search; no predict-table). Memory note `agentic_team_activation_state.md` was imprecise — `REGRESSION_PREDICTOR` flag is actually `FIRM_AGENT_REGRESSION_PREDICTOR_ENABLED` and IS set on Railway.

**Where predictions go**: `regression-predictor.ts:179-203` writes to `firm_memory` with `memory_type='thesis'`, `importance=7`, structured JSON evidence. 4 rows confirmed today + yesterday:
- `xau-session-breakout prediction (2026-05-13)` Source=baseline, n=0
- `xau-volatility-expansion prediction (2026-05-13)` Source=baseline, n=0
- Same pair for 2026-05-12, regime HIGH_VOLATILITY/asian

**Sub-issue**: predictions show `Source: baseline (n=0)`. The predictor groups by `strategy_id` and requires `MIN_STRATEGY_TRADES=10` closed trades in last 60 days (`regression-predictor.ts:32, 125`). Two strategies cleared the bar but their `result_r` values are likely all NULL — `coerceR()` at lines 235-240 skips rows where `result_r` is not finite. So baseline stats compute over empty arrays (`statsOf` returns zeros at line 222). This means **strategies are firing but `simulated_orders.result_r` isn't being populated on close**.

`firm_agent:regression-predictor:last_run_date_iso=2026-05-13` confirms it ran at 04:04:55Z today — agent IS working, data input is the bottleneck.

**What's needed to activate (useful output)**:
1. **Predictor itself is "active"** — daily run, writing to `firm_memory`. No flag flip needed.
2. To get non-zero predictions: fix `result_r` population in the trade-close path. Audit `simulated_orders` close logic for where `result_r` is computed and persisted. Separate bug, NOT a flag issue.
3. **Naming clarification needed**: the agent-bus audit said "predictions table doesn't exist". Correct — by design. Output lives in `firm_memory` keyed by tag `prediction:<strategy>:<date>`. If a dedicated table is desired (for dashboard joins), that's a schema decision for Karri. Don't introduce without proposal.

## Cross-cutting

- **All three** are env-gated and default OFF except where operator explicitly flipped them; none auto-disable.
- **Documentation drift**: memory note used `REGRESSION_PREDICTOR` (incorrect short name); canonical is `FIRM_AGENT_REGRESSION_PREDICTOR_ENABLED` per `docs/ref/env-vars.md:123`.
- **No data loss**: 156 closed trades available, postmortems firing, predictions structured-persisted — backfill is possible once the Dockerfile fix lands for agent_lessons.

## Followups (no action taken, audit-only)

- [ ] Patch `apps/worker/Dockerfile` to ship `scripts/firehose/` (operator gate — touches Railway deploy)
- [ ] Move `firm_state` idempotency write to post-success in `apps/worker/src/index.ts:230-243`
- [ ] Investigate why `simulated_orders.result_r` is NULL on closed trades (separate from agent-bus)
- [ ] Decide review-drainer path: keep Ralph-on-WSL vs build worker-side `runReviewDrainer` (Karri)
- [ ] Update `agentic_team_activation_state.md` memory with correct flag name + clarification that "predictions table" is intentionally `firm_memory`
