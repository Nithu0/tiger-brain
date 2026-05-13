---
date: 2026-05-13
type: investigation
project: nexus
status: open
---

# Position-lifecycle blackboard gap — 4 silent topics with 0 lifetime rows

## TL;DR

Severity: **mostly cosmetic / audit-trail gap, NOT functional**. No live consumer is starving on these topics. Three of the four (`xauusd.position.opened`, `xauusd.position.closed`, `xauusd.execution.fills`) have **no producer AND no consumer** anywhere in the codebase — they are reserved-for-future allowlist entries. The fourth (`xauusd.portfolio.exposure_check`) has a producer and a CIO consumer, but both are inside the `bladeApproval` path which is bypassed by `ORB_ONLY_MODE=true`. Same root cause as `docs/ops/gate-silence-2026-05-08.md`.

## Findings

### AUDIT_ALLOWLIST (orchestrator.ts:72-80)

7 audit-grade topics. Live status:
- `xauusd.execution.reports` — writes (executionManager + strategy-execution path)
- `xauusd.execution.fills` — **0 rows, no producer, no consumer**
- `xauusd.position.opened` — **0 rows, no producer, no consumer**
- `xauusd.position.closed` — **0 rows, no producer, no consumer**
- `xauusd.event.policy` — **0 rows under ORB_ONLY_MODE** (producer in bladeApproval, consumer in operator-readiness)
- `xauusd.postmortem.reports` — (not checked in this audit)
- `xauusd.journal.daily` — (not checked in this audit)

### Topic 1: `xauusd.portfolio.exposure_check`

NOT in audit-allowlist, but listed by operator as silent.

- **Producer**: `managers.ts:511` inside `bladeApproval()`. Gated by `ORB_ONLY_MODE=false`.
- **Consumer**: `cio/review.ts:113` — counts Forge rejection codes for CIO review.
- **Why silent**: `orchestrator.ts:523-528` short-circuits `bladeApproval()` when `ORB_ONLY_MODE=true` (current prod since 2026-04-25 per `docs/ops/gate-silence-2026-05-08.md`).
- **Impact**: CIO review reports always show 0 Forge rejections. Cosmetic — CIO is read-only advisory.

### Topic 2: `xauusd.event.policy` (bonus, also silent)

- **Producer**: `managers.ts:435` inside `bladeApproval()`. Same gate.
- **Consumer**: `apps/api/src/routes/operator-readiness.ts:354, 389` (topicProbe + latest).
- **Impact**: `/operator/readiness` endpoint reports event-policy as missing/stale. Operator-facing display bug, not a decision blocker — event policy itself still computed inside `computeEventPolicy()` when called; just not exposed to the readiness probe under ORB_ONLY_MODE.

### Topics 3-5: `xauusd.position.opened` / `position.closed` / `execution.fills`

These are **completely unwired**.

- **Grep**: only references are the AUDIT_ALLOWLIST itself (`orchestrator.ts:74-76`), the retention exclusion list (`retention.ts:70-72`), and the retention test fixture.
- **No `board.publish({ topic: "xauusd.position.opened", ... })`** anywhere.
- **No consumer**: no `board.latest("xauusd.position.opened", ...)`, no `topicProbe("xauusd.position.opened", ...)`, no SQL `WHERE topic = 'xauusd.position.opened'`.

Position lifecycle in production flows via `simulated_orders` INSERT/UPDATE directly:
- Open: `apps/worker/src/firm/managers.ts:executionManager` (INSERT) + strategy-execution analogue.
- Close: `apps/worker/src/services/paper-execution.service.ts:checkAndClosePositions` (UPDATE) — does NOT touch blackboard.
- Operator-brief, dashboard, postmortem, OANDA sync all read `simulated_orders` directly.

So the topics are **placeholders in the allowlist, never wired up**. The allowlist was forward-looking — probably authored from `docs/ref/blackboard-topics.md` as an aspirational contract.

### Comparison to topics that DO write

`xauusd.signal.rejected` — published via `publishSignalRejection()` from inside `runStrategyExecution()` (active path under ORB_ONLY_MODE) at every reject. Lives in the live strategy-blade funnel, not in the dormant `bladeApproval` block. That's why it accumulates rows.

## Severity verdict

**Cosmetic + audit-trail gap. Not functional.**

- No consumer is silently waiting on these 3 topics. Dashboard, operator-brief, postmortem, OANDA sync all read `simulated_orders` directly — they don't even know the blackboard topics exist.
- `xauusd.portfolio.exposure_check` and `xauusd.event.policy` silence is a known cascade of `ORB_ONLY_MODE=true` (documented in `docs/ops/gate-silence-2026-05-08.md`). Side-effect: CIO Forge-rejection counter is permanently 0, `/operator/readiness` reports event-policy missing. Cosmetic.
- Real audit trail is `simulated_orders` table — that IS being written.

The misleading thing is that the AUDIT_ALLOWLIST advertises a contract ("these topics are audit-grade, never deleted") that 3 of 7 entries don't actually meet because nothing publishes them.

## Minimal fix proposal

Two options, both small:

**Option A — Trim the allowlist to reality (zero risk):**
Remove `xauusd.position.opened`, `xauusd.position.closed`, `xauusd.execution.fills` from `BLACKBOARD_AUDIT_ALLOWLIST` (orchestrator.ts) and the matching `AUDIT_TOPICS` in `retention.ts:70-72`. Update `docs/ref/blackboard-topics.md` to mark them "reserved-for-future, not currently produced". Same for `xauusd.event.policy` if we're not going to fix the ORB_ONLY_MODE bypass.

Pros: aligns advertised contract with actual behaviour. Health audit stops flagging them.
Cons: loses the aspirational target.

**Option B — Wire the producers (modest):**
Add `board.publish({ topic: "xauusd.position.opened", ... })` in both writers (legacy `executionManager` AND `runStrategyExecution`-execution-step) right after the `INSERT INTO simulated_orders`. Same for close path in `paper-execution.service.ts:checkAndClosePositions`. This restores the contract and gives Karri/CIO/postmortem an event stream for free.

Pros: real audit trail, lets future firm-agents react to lifecycle events without polling.
Cons: behaviour change in the live writer paths — should go through strategy-proposal review per project CLAUDE.md (not money-impact but touches execution path).

**Recommend Option A first** (Claude can do unilaterally — observability/docs only, no behaviour change). File Option B as a separate proposal for Karri review.

## Files referenced

- `apps/worker/src/firm/orchestrator.ts:72-80` (allowlist), `:523-528` (ORB_ONLY_MODE bypass)
- `apps/worker/src/firm/managers.ts:434-463` (event.policy producer), `:511-536` (exposure_check producer)
- `apps/worker/src/firm/cio/review.ts:110-118` (exposure_check consumer)
- `apps/api/src/routes/operator-readiness.ts:354, 389` (event.policy consumer)
- `apps/worker/src/services/paper-execution.service.ts:204-269` (close path — bypasses blackboard)
- `apps/worker/src/firm/retention.ts:70-72` (matching audit list)
- `docs/ops/gate-silence-2026-05-08.md` (root cause for the gated topics)
