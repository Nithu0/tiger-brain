---
tags: [nexus, ops, proposal-workflow]
type: atomic
created: 2026-05-08
---

# Strategy-Proposal-Workflow

The `docs/strategy/proposals/` flow. Decision-source: `_repo-docs/ops/operator-decisions.md` 2026-05-08. **Binding** for any change with money-impact.

## Why this exists

Operator owns ops / infra. [[Karri]] owns strategy / risk. Without a forcing function, strategy changes were sliding through without partner review. Verbal-only had no audit trail. Slack-only was ephemeral. In-repo proposal docs were chosen — dated and status-tracked.

## What counts as a money-impact change

- Threshold changes on existing strategies
- Risk-sizing changes
- Order execution changes
- New strategy modules
- Gate logic changes
- Cooldown changes
- Position-management defaults

## What does NOT need a proposal

- Bug fixes that restore intended behaviour
- Observability work (logs, metrics, dashboards)
- Refactors with no behaviour change
- Backfills

## The flow

1. **Claude drafts proposal** — `docs/strategy/proposals/YYYY-MM-DD_<slug>.md` per the template at `docs/strategy/proposals/README.md`. Set `Reviewer: Karri`. See [[Karri]].
2. **Operator sends to Karri** — via `#strategy-review` Discord channel.
3. **Karri reviews** — async, may push back, request changes, approve.
4. **Operator confirms approval** — to Claude, in-session.
5. **Claude implements** — only after operator confirmation.
6. **Status tracked**: `proposed → approved → implemented (with commit SHA) → archived`.

## Counter-signal

If operator says "bare fix det" / "kjør på" inline on a specific item, implement directly. **Still** file a retroactive proposal afterwards as `Status: implemented (approved-verbally)` for audit trail. See [[OK-Kjor-Gate]].

## Related

- [[Karri]] — strategy reviewer
- [[Strategy-Promotion-Workflow]] — final promotion ladder
- [[Foundation-Gate]] — proposals can be drafted while red, but not implemented
- [[OK-Kjor-Gate]] — final activation gate
- [[Operator-Principles]] — prinsipp 4 + 5 binding
- [[Truth-Hierarchy]] — proposal docs in repo `docs/strategy/proposals/` are canonical; vault mirrors
- [[Runbook-Karri-Proposal-Send]] — the send-to-[[Karri]] procedure
- [[When-Strategy-Change-Tempting]] — decision-tree gating entry to this workflow
- [[Nexus-MOC]]
