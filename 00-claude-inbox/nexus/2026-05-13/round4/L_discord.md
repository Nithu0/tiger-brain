# Audit: discord_notifications_layer.md

**Output:** `~/Obsidian/Brain/_library/trading/concepts/discord_notifications_layer.md`
**Word count:** ~580 (target 400-600, in range)
**Date:** 2026-05-13

## Sources consulted

- `docs/ref/notifications.md` — morning briefing, follow-ups, checkpoint handoff
- `~/.claude/projects/-home-nithu-code-ai-assistent/memory/discord_orchestrator_listener.md` — listener script (9-day-old, flagged stale, verified vs current code path)
- `~/.claude/projects/-home-nithu-code-ai-assistent/memory/project_discord_delivery_dual_gate.md` — double-gate + NULL convention
- `~/.claude/projects/-home-nithu-code-ai-assistent/memory/reference_strategy_reviewer.md` — Karri webhook + 7-section embed format
- `apps/worker/src/firm/notifications/config.ts` — verified DISCORD_VERBOSITY parsing (compact|standard|detailed)
- `docs/ref/env-vars.md` — verified DISCORD_VERBOSITY default + companion flags

## Coverage checklist

- 5 feeds — covered (briefings, executions, decisions/bridge, alerts, Karri)
- Double-gate gotcha — covered with explicit "both must be true" + NULL convention sidenote
- Orchestrator listener `!firm <text>` — covered with operator-side caveat
- Karri 7 binding sections — covered verbatim from memory
- Auto-send work-hours rule (09-17 CET) — covered with override triggers
- Claude can/cannot table — covered (5 CAN + 4 CANNOT)
- Verbosity knob — covered with companion `DISCORD_SEND_*` flags

## Verification

- DISCORD_VERBOSITY values verified against `firm/notifications/config.ts` source.
- Double-gate claim verified against memory (memory cites commit `885249f` for bridge addition, `c062696` for audit-trail instrumentation).
- Karri webhook URL NOT included in distilled doc — kept as reference only ("in `reference_strategy_reviewer.md`") since this is a public-ish library doc.

## Frontmatter

```yaml
title: Discord notifications layer — webhooks + double-gate + Karri format
source: Nexus codebase + docs/ref/notifications + memory bindings
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 4
claude_priority: P1
tags: [library, concept, discord, notifications, karri, observability]
status: distilled
```

Status: complete.
