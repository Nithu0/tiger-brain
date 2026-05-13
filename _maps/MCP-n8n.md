---
type: mcp
status: active
scope: workflow-crud
---
# MCP-n8n

n8n cloud MCP that lets Claude create / read / update / test workflows in operator's n8n instance. Tool names: `mcp__n8n__*`.

## Purpose
Build operator-facing automation glue (Telegram → orchestrator, Discord → Claude wakeup, scheduled audits) without operator needing to click through the n8n GUI for every iteration.

## Status (per `n8n_integration_pickup.md`, 2026-05-07)
- **WF#1** — Telegram orchestrator listener: **LIVE**. Operator can wake firm from phone via Telegram message.
- **WF#2** — Needs API_KEY + credential wired in n8n.
- **WF#3** — Needs migration applied before activation.

## Trial-plan limitation
Operator's n8n plan does **not** expose the REST API. All workflow ops therefore go through the MCP, not curl. Plan upgrade would unlock curl-based ops but isn't on the roadmap.

## When to reach for it
- Operator says "lag en workflow som …".
- Investigating why an existing workflow didn't fire (check executions via MCP).
- Refactoring a workflow that grew organically and needs cleanup.

## Boundaries
- Don't activate a workflow that touches real money flows without operator-OK + a [[Strategy-Proposal-Workflow]] entry.
- Webhook URLs in workflow config can contain secrets — never echo them back into transcripts; reference by node-id only.

Linked to: [[Tools-MOC]], [[Decision-Tools-Roster-Habit]]

Memory ref: `n8n_integration_pickup.md` (WF#1 = Telegram orchestrator listener, LIVE).
