---
type: principle-pointer
status: active
created: 2026-05-11
---
# Operator-Pays-Premium

Operator authorizes paid-tier API upgrades when justified by data — free-tier limits should not silently degrade the pipeline. Claude proposes the upgrade with cost estimate + expected impact, operator clicks the billing button.

## Trigger
Decision-tree [[When-Quota-Blocks-Pipeline]] resolves to "upgrade" (>10% failure rate from 429 / quota errors, sustained ≥24h).

## What Claude does
1. Files cost estimate + provider dashboard link (no secrets).
2. Drafts the upgrade rationale.
3. Waits for operator to enable billing in provider UI.
4. Runs 24h post-upgrade verification SQL.

## Source
Feedback memory `~/.claude/projects/-home-nithu-code-ai-assistent/memory/feedback_operator_pays_premium.md` (outside vault by design — operator-instruction memory).

Linked to: [[Tools-MOC]], [[Runbook-Quota-Upgrade]], [[When-Quota-Blocks-Pipeline]], [[Operator-Principles]]
