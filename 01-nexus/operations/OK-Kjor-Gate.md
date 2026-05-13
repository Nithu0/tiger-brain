---
tags: [nexus, ops, ok-kjor]
type: atomic
created: 2026-05-08
---

# OK-Kjor-Gate

Operator-approval gate. Source: [[Operator-Principles]] (prinsipp 5). **No exceptions.** "OK kjør" must be explicit, in-session, before any push or activation.

## What needs explicit "OK kjør"

- `git push origin main` (or any push that affects shared remote state)
- Flipping any Railway env var (`POSITION_MANAGEMENT_ENABLED`, `ORB_ENABLED`, `AGENT_BUS_ENABLED`, etc)
- Activating any agent / strategy / gate
- Sending external messages on operator's behalf (Discord pings, Slack, email)
- Installing tools with broad permissions
- Modifying secrets
- Database migrations
- Running destructive ops (force push, reset --hard, branch deletes, file deletes)

## What does NOT need OK kjør

- Reading docs / running queries via `mcp__nexus-pg__query`
- Drafting proposals (writing the doc, not implementing)
- Type-checks, tests, dry-runs
- Small janitor jobs per [[Operator-Principles]] prinsipp 3 — dedupe, TTL, retention, low-value memory pruning
- Bug fixes that restore intended behaviour (allowed, but still file a retroactive proposal if money-impact, see [[Strategy-Proposal-Workflow]])

## Operator's autonomous-execute triggers

These count as "OK kjør" for the duration of the action:

> "OK kjør", "kjør på", "kjør alle", "letsgooo", "BYGG ALT", "max"

When seen, dispatch agents / take action immediately. From global CLAUDE.md.

## Counter-signal

If operator says "bare fix det" / "kjør på" inline on a money-impact item, implement directly — but file a retroactive proposal as `Status: implemented (approved-verbally)` for audit trail. See [[Strategy-Proposal-Workflow]].

## Why it exists

Prinsipp codified after the demo-mode auto-degrade incident. Even in demo, every flag flip can change agent cost, queue load, or downstream behaviour. Status-report-without-acting is the correct shape when operator asks "is everything finished".

## Related

- [[Operator-Principles]] — prinsipp 5 source
- [[Foundation-Gate]] — both gates must be green for new strategies
- [[Strategy-Proposal-Workflow]] — Karri review precedes OK kjør for money-impact changes
- [[Strategy-Promotion-Workflow]] — final activation step
- [[Module-Notifications]] — morning briefing surfaces a ready-to-paste prompt; operator acts then says OK kjør
- [[When-Operator-Says-Kjor-Pa]] — decision-tree for the autonomous-execute trigger
- [[Runbook-Push-Cycle]] — OK-kjør-gate fires inside this runbook before `git push`
