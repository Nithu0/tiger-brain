---
title: Discord notifications layer — webhooks + double-gate + Karri format
source: Nexus codebase + docs/ref/notifications + memory bindings
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 4
claude_priority: P1
tags: [library, concept, discord, notifications, karri, observability]
status: distilled
---

# Discord notifications layer

Discord is the operator's primary observability + control surface for Nexus, and the only channel through which Claude can act externally. Five logical feeds, gated by env flags, with one critical double-gate trap.

## The five feeds

| Feed | Source | Env gate | Channel |
|---|---|---|---|
| Morning briefing | `firm/notifications/detector.ts` — `DAILY_MORNING_BRIEFING` event, once per UTC day on first `LONDON_PREPARE`/`LONDON_ACTIVE` | `DAILY_MORNING_BRIEFING_ENABLED` (+ `DISCORD_SEND_BRIEFINGS`) | Operator's firm channel via `DISCORD_WEBHOOK_URL` |
| Executions | trade-open / trade-close embeds from `services/discord.service.ts` | `DISCORD_LEGACY_ENABLED=true` + bot token + channel id | Same firm channel |
| Decisions / triggers / advisories | `firm/agent-bus/firm-agents/discord-bridge.ts` (added 03.5, commit `885249f`) wraps `sendDiscordEmbed` | `AGENT_DISCORD_DELIVERY_ENABLED=true` AND `DISCORD_LEGACY_ENABLED=true` | Same firm channel |
| Alerts (anomalies, gate flips, health) | `firm/notifications/delivery.ts` | `DISCORD_SEND_ALERTS=true` | Same firm channel |
| Karri review | Bash + jq POST to dedicated webhook | none — manual send pattern | Separate webhook (Karri-only, in `reference_strategy_reviewer.md`) |

## The double-gate gotcha (binding)

`AGENT_DISCORD_DELIVERY_ENABLED=true` alone is **silently inert**. The firm-agent bridge routes through `sendDiscordEmbed`, which early-returns when `DISCORD_LEGACY_ENABLED=false`. Both must be true for advisories / morning briefs / triggers to fire. Operator had previously turned `DISCORD_LEGACY_ENABLED` off to silence duplicate sends from the legacy stack — flipping the firm-agent flag without flipping the legacy flag = nothing fires. **Always recommend both together.** If operator reports "I flipped it but nothing showed up," check `DISCORD_LEGACY_ENABLED` first.

Related convention: `agent_artifacts.discord_delivery_status = NULL` means "this kind was never intended for the bridge" (e.g. `research_note`, internal `plan`), NOT "send was silently skipped". Filter on `IS NOT NULL` for audit queries.

## Orchestrator listener — mobile control

`scripts/firm/discord-listener.mjs` (added 03.5, commit `b3e7504`) lets operator wake the firm from their phone. Type `!firm <instruction>` in the configured channel, the listener writes to local firm-mirror dirs (`~/nexus-firm-local/...`), the orchestrator picks it up, reply lands in `outbox/`. Operator-side only — Railway can't access local filesystem. Setup: `DISCORD_BOT_TOKEN` + `DISCORD_FIRM_CHANNEL_ID` + MESSAGE CONTENT intent enabled in Developer Portal.

## Karri webhook — strategy review format

Dedicated webhook for strategy/risk proposals to Karri. Binding embed structure (operator 2026-05-08): each proposal Discord-message must have these 7 sections so Karri understands analysis + decision logic:

1. **Hva data viser** — what the data shows
2. **Root cause**
3. **Forslag** — proposal
4. **Alternativer jeg vurderte og forkastet** — alternatives considered + rejected with reasoning
5. **Strategisk vurdering for deg** — trade-offs, best/worst case, sample-size caveat
6. **Spørsmål jeg vil ha din vurdering på** — specific reviewer questions
7. **Rollback** — env-flag, code-revert path. Link to full proposal doc at end.

Send pattern: two-message format, embed 1 color `3447003` (blue) with greeting content, embed 2 color `16776960` (yellow) continuation. Verify HTTP 204 on each POST.

**Auto-send work-hours rule (binding 2026-05-11):** proposals filed during Nordic work hours (~09:00–17:00 CET) auto-send to Karri without per-message confirmation. Outside work hours: hold + send next morning. Override with "vent" / "hold" / "ikke send".

## What Claude can / cannot do via Discord

**CAN:**
- Send strategy proposals to Karri's webhook (auto during work hours, manual outside).
- Send morning briefing (automated via worker, Claude doesn't trigger).
- Send alerts / advisories with operator trigger ("send det", "shoot melding").
- Curl health/diagnostic endpoints and post results.

**CANNOT:**
- Direct-message individual Discord users (webhook-only access).
- Modify operator's Discord server settings, channel permissions, or bot configs.
- Flip env flags on Railway to change delivery routing — operator-only.
- Read `.env*` to discover webhook URLs not already in memory.

## Verbosity knob

`DISCORD_VERBOSITY=compact|standard|detailed` (default `standard`, parsed in `firm/notifications/config.ts`). Affects briefing density — `compact` drops the "Week ahead" section, `detailed` expands every section. Companion flags: `DISCORD_SEND_BRIEFINGS`, `DISCORD_SEND_DECISIONS`, `DISCORD_SEND_EXECUTIONS`, `DISCORD_SEND_ALERTS` (all default `true`).
