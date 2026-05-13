---
tags: [nexus, module, notifications, atlas]
type: atomic
created: 2026-05-08
---

# Module-Notifications

Owner: Atlas (operator-facing). Lives in `apps/worker/src/firm/notifications/`. Typed events + formatter layer + Discord webhook delivery with dedup + cooldown.

## What it does

Subscribes to typed events from [[Module-Blackboard]], formats them for Discord, delivers with dedup (don't spam the same event) + cooldown (don't spam the channel).

The marquee event is `DAILY_MORNING_BRIEFING` — fires once per UTC day on the first `LONDON_PREPARE` or `LONDON_ACTIVE` cycle. Replaces the terse `SESSION_STARTED` greeting.

## Sections of the morning briefing

- Market snapshot (price / RSI / ATR / ADX / MACD / EMA posture)
- Macro context (EUR/USD, TLT, SPY, USO, Silver, macro-analyst tone)
- Narrative pulse (headline count + top `narrative_clusters` theme + fear/greed)
- Firm plan today (regime, tradeability, active managers, thesis, conviction)
- Today's high-impact events
- Week ahead (non-compact only)
- Last 7 days — weekly lens (Monday only)
- Pending follow-ups (when present, from `firm/followups.ts`)

## Gate state

`lastBriefingDateIso` is in-memory in `detector.ts`. Worker restart during London may cause at most one extra briefing per day — intentional over silently skipping.

## Env flags

`DAILY_MORNING_BRIEFING_ENABLED=true` (default). `STATUS_REPORT_ENABLED=true`. Discord delivery is double-gated (see operator memory `project_discord_delivery_dual_gate.md`): both `AGENT_DISCORD_DELIVERY_ENABLED=true` AND `DISCORD_LEGACY_ENABLED=true` required for firm-agent pings.

## Key files

- `apps/worker/src/firm/notifications/` — module index, formatter, detector
- `apps/worker/src/firm/followups.ts` — pending-followup mechanism (operator-facing reminders)
- `apps/worker/src/firm/status-report.ts` — `RecommendedAction` computation (WAIT / OBSERVE / EXECUTE_CANDIDATE / DIAGNOSE)

## Related

- [[Module-Blackboard]] — source of typed events
- [[Module-Postmortem]] — feeds postmortem summaries
- [[Live-Endpoints]] — `/operator/status-report` exposes the same `RecommendedAction`
- [[OK-Kjor-Gate]] — operator copies the briefing's prompt block, then approves with "OK kjør"
- [[Foundation-Gate]] — followups feed rule 5
- [[Operator-Principles]] — prinsipp 1: health-check REPORTS via this module; operator decides handling
- [[discord-delivery-state]] — living-state for the double-gated delivery path
