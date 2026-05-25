---
title: ai-1 pane stalled — 6 Karri Discord dispatches pending
date: 2026-05-25
author: code-1
audience: operator
status: needs-decision
tags: [firm-bus, ai-1, karri, discord, blocker]
---

# ai-1 stalled — 6 Karri Discord dispatches stuck

## Symptom
ai-1 pane has been idle since 2026-05-24T15:24Z (last work-log). 6 dispatch requests queued in `inbox/ai-1.md`:
- 2 from code-1: Karri brief (~13:1xZ) + 56-PR session summary (15:35Z, 1803 chars)
- 4 from code-2: 13:15Z, 14:05Z, 16:00Z, 17:55Z (each contains Karri-bound brief)

## Two paths to clear

### Path A: engage ai-1 pane
1. `firm` or open nexus pane manually
2. ai-1 reads inbox + delivers all 6 to Karri Discord webhook (per 2026-05-23 pattern: HTTP 204 → done)
3. Each delivery acks via "ai-1 received dispatch" + feed line

### Path B: authorize direct webhook from code-1 pane
- Say "OK kjør send Karri-dispatches direkte fra code-1"
- code-1 reads each pending msg + POSTs to DISCORD_WEBHOOK_URL (need env var or webhook from `reference_karri.md`)
- Risk: external-message rule per CLAUDE.md — needs explicit kjør

## Recommend Path A (cleaner, preserves ai-1 ownership)

ai-1 pane has the existing infra (`apps/worker/src/firm/notifications/delivery.ts` plus the per-day patterns in inbox). 5-minute task once engaged.
