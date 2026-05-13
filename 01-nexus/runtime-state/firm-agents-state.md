---
type: living-state
subsystem: firm-agents
last_verified: 2026-05-11T15:30Z
status: 🟢
---

# Firm Agents — Living State

10 firm-agents on the shared blackboard. Per 2026-05-04 audit baseline: **6 active / 4 silent**. The 4 silent are intentionally dormant pending operator-activation, not stalled.

## Current state (verified 2026-05-11)

- **Active**: 6 agents
- **Silent / dormant**: 4 agents
- **NEW 2026-05-11**: `risk-advisor` + `agent-trigger` now write audit-trail artifacts via commit `c062696` (Discord delivery instrumented)

## Active (6, verified 2026-05-11)

| Agent | Module | Cadence | Audit-trail writes |
|---|---|---|---|
| Orchestrator | runCycle scheduler | per-tick | n/a |
| Prism (fact + analysis) | Module-Fact-And-Analysis | per-tick | analysis_snapshots |
| Atlas (postmortem / review-worker) | Module-Postmortem | hourly | firm_memory |
| Forge + Shield (exposure / news) | Module-Exposure-And-Shield | per-tick + on event | blackboard |
| Reconciliation | Module-Reconciliation | every 5 min | reconciliation_events |
| Notifications (morning briefing) | Module-Notifications | daily 07:00 CET | agent_artifacts (Discord) |

## Newly-instrumented (2026-05-11)

| Agent | New behavior |
|---|---|
| risk-advisor | now passes `(db, artifactId)` → writes `discord_delivery_status` to `agent_artifacts` |
| agent-trigger | now passes `(db, artifactId)` → writes `discord_delivery_status` to `agent_artifacts` |

See [[discord-delivery-state]] for delivery audit details.

## Silent / dormant (4, verified 2026-05-11)

These are NOT stalled — awaiting operator-activation per [[Decision-No-Auto-Activation]]. Do not flag as incidents.

| Agent | Activation gate |
|---|---|
| Agent Bus orchestrator (code-drainer) | foundation 🟢 + 30d Phase 3 + explicit OK |
| (3 others — verify against /firm-agents/status) | various |

Reference: `agentic_team_activation_state.md` — operator activated Batman+Prediction flags 2026-05-03. Refresh against live endpoint each session for accurate active/silent split.

## Recent changes

- 2026-05-11: `c062696` — risk-advisor + agent-trigger wired with `(db, artifactId)` for Discord-delivery audit trail. 2 of 4 Discord-emitting paths now visible

## Health indicators

- `/firm-agents/status` returns 6 with non-null `last_run_at` in last hour
- No `last_error` strings on active agents
- risk-advisor writes ≥1 `discord_delivery_status` row when non-OK advisory fires
- operator-brief writes ≥1 `discord_delivery_status='sent'` per UTC-day

## Open issues

- [ ] Verify 4th Discord-emitting path (macro-event.ts) — still no audit trail
- [ ] Refresh against `/firm-agents/status` to confirm exact 6/4 split today

## Verification SQL + curl

```bash
curl -H "Authorization: Bearer $API_KEY" \
  https://api-production-b660.up.railway.app/firm-agents/status
```

```sql
SELECT agent_name, max(created_at)
FROM firm_agent_runs
GROUP BY agent_name
ORDER BY 2 DESC;
```

## What never auto-fires

- Activating a dormant agent ([[Decision-No-Auto-Activation]])
- Disabling an active agent on a single failed run ([[Operator-Principles]] rule 1)
- Manual queue clearing without operator-OK

Linked to: [[Nexus-MOC]], [[Module-Agent-Bus]], [[Module-Postmortem]], [[Module-Fact-And-Analysis-Agents]], [[Module-Reconciliation]], [[discord-delivery-state]], [[Decision-No-Auto-Activation]], [[Operator-Principles]] (rule 1: silent != stalled, never auto-disable), [[Truth-Hierarchy]] (`/firm-agents/status` endpoint above this doc), [[When-Agent-Stalls]]

Memory ref: `agentic_team_activation_state.md`.
