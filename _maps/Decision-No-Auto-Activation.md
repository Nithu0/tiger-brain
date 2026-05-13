---
type: decision
status: binding
decided: 2026-05-08
---
# Decision: No auto-activation

Claude never flips Railway env flags, activates dormant agents, sends Discord pings, or pushes to main without an explicit operator trigger. Report-and-recommend is the correct shape; acting on a recommendation requires a fresh "OK kjør" from the operator.

## Why
Operator-prinsipp 1 + 2 say data must keep flowing and strategies/gates must not auto-disable from anomaly detection. The symmetric rule — Claude must not auto-**enable** either — closes the loop. The harness already blocks `git push origin main`; this decision extends the same posture to Railway, Discord, and any other side-effect surface.

## Scope
Applies to:
- Railway env vars and service restarts (operator-only, no Railway MCP installed).
- Discord webhook posts to external humans (Karri, channels). Internal/log webhooks operator has whitelisted are fine.
- Any feature flag that changes trading-loop behaviour, money sizing, or strategy gating.
- Manual SQL via [[MCP-nexus-pg-rw]] — every write requires sign-off.

Does **not** apply to:
- File edits in the repo (still subject to "OK kjør" before push per [[OK-Kjor-Gate]]).
- Read-only queries via [[MCP-nexus-pg]].
- Writing to the [[Obsidian-Bridge]] inbox / `_promote-candidates/`.

## Counter-signal
Inline "kjør på" / "OK kjør" / "letsgooo" + the specific action named = green light to act on that action. Generic enthusiasm doesn't generalise to unrelated surfaces.

## Trace
`feedback_no_auto_activation.md` memory; appended to `docs/ops/operator-decisions.md` 2026-05-08.

Linked to: [[Decisions-MOC]], [[Operator-Principles]], [[OK-Kjor-Gate]], [[OK-Kjor-Autonomous-Execute]]
