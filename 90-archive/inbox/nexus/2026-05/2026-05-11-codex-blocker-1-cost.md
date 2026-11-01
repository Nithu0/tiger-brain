---
date: 2026-05-11
project: nexus
topic: codex-prod-readiness
status: implemented
---

# Codex prod-readiness blocker #1 — cost cap

## Context

Codex Phase 2a runner (`scripts/agent-codex-runner.mjs`) had no daily
cost cap. Schema fields `cost_usd / tokens_in / tokens_out` in
`agent_results` are hardcoded to 0 because Codex CLI (beta) doesn't
expose token counts in stdout, and Codex pricing isn't published yet.

This was blocker #1 of 3 from the Codex prod-readiness review.

## Choice: invocation-count cap (not USD cap)

Per the pragmatic alternative in the task brief: a token-based USD cap
isn't reliably constructable today, so cap by **invocation count**
instead. Operator can scale the cap up when comfortable; flip to a
real USD cap once Codex CLI surfaces token telemetry and OpenAI
publishes Codex pricing.

## Implementation

Single env-var + a single DB count query before each claim.

- `AGENT_CODEX_DAILY_INVOCATIONS_MAX` (default `50`, bounded 1..10000)
- Counts rows in `agent_results` joined to `agent_tasks` where
  `t.role='code'`, `r.status<>'error'`, and `r.created_at >= UTC-midnight`.
- Drain-loop aborts before claiming next task if today's count >= cap.
- Logged abort message includes count, cap, and env-var name for
  observability.

### Files

- `scripts/agent-codex-runner.mjs` — added `DAILY_INVOCATIONS_MAX`
  const, `countTodayInvocations()` helper, pre-claim check at the top
  of the drain loop, header docstring update.
- `.env.example` — added commented entry with explanation that this is
  a cost-cap proxy until Codex CLI exposes token counts.

### Why "non-error" counts only

Failed/errored drains (worktree-create failure, codex spawn error,
trading-loop-guard refusal) cost effectively nothing — they don't
invoke the Codex API. Counting only `status<>'error'` results means
the cap reflects real spend, not noise.

### Why UTC-midnight

Single timezone-stable boundary across local and Railway runners. If
operator prefers Europe/Oslo wall-clock midnight later, swap `'UTC'`
to `'Europe/Oslo'` in the `date_trunc` call.

## Verification

- `node --check scripts/agent-codex-runner.mjs` — clean.
- No TS files touched.
- No trading-loop files touched.

## Operator action when activating

Set `AGENT_CODEX_DAILY_INVOCATIONS_MAX` on Railway (the worker
service) when enabling Codex Phase 2a. Default is `50` which assumes
small/short tasks. Lower to `10` for first day in prod; raise when
behavior is understood.

## Deferred (blocker #1 partial — open follow-on)

True USD cap is deferred. When Codex CLI exposes token counts:

1. Parse them out of stdout/stderr (likely a JSON footer).
2. Multiply by Codex public pricing (when published).
3. Store as `cost_usd / tokens_in / tokens_out` on `agent_results`.
4. Replace `countTodayInvocations` with a `SUM(cost_usd)` query +
   `AGENT_CODEX_DAILY_BUDGET_USD` env-var.

## Commit

(See main thread for SHA — invocation cap only; no push.)

## Remaining Codex prod-readiness blockers (#2, #3)

This note only closes #1. Operator: review the original prod-readiness
report to dispatch #2 and #3 in parallel sessions.
