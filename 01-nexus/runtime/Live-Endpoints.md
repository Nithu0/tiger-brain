---
tags: [nexus, runtime, endpoints]
type: atomic
created: 2026-05-08
---

# Live-Endpoints

Railway base URL: `https://api-production-b660.up.railway.app`. All endpoints public over HTTPS. Authenticated endpoints require `Authorization: Bearer $API_KEY` (operator's machine only — never paste into this vault).

## Endpoints

### `/health` — no auth

Returns DB / broker / blackboard / worker / reconciliation status as structured JSON. The fastest "is anything broken?" check. Operator's morning routine reads this.

### `/diagnostic/broker` — bearer auth

Full OANDA fetch attempt + advice. Includes account summary, current open trades, last sync timestamp, and a human-readable advice block for what to do if the broker is misbehaving.

### `/operator/*` — bearer auth

- `/operator/status-report` — same `RecommendedAction` (WAIT / OBSERVE / EXECUTE_CANDIDATE / DIAGNOSE) that powers the morning briefing
- `/operator/readiness` — readiness page powering the BalanceReconciliationWidget
- `/operator/broker-test` — broker connectivity smoke test

### `/firm-agents/*` — bearer auth

Firm-agent state per role (research, narrative, risk-advisor, trade-critic, daily-journal). Returns last-run timestamps + cooldown windows + recent results. Useful for verifying [[Module-Agent-Bus]] activation when applicable.

## Source mapping

| Endpoint | Source module |
|---|---|
| `/health` | aggregates from [[Module-Reconciliation]], [[Module-Blackboard]], orchestrator state |
| `/diagnostic/broker` | OANDA client probe |
| `/operator/status-report` | [[Module-Notifications]] formatter |
| `/operator/readiness` | [[Module-Reconciliation]] drift-monitor |
| `/firm-agents/*` | [[Module-Agent-Bus]] |

## What this domain does NOT contain

- Bearer tokens, API keys, OANDA secrets, Discord webhook URLs — never in this vault
- Account IDs / account numbers — operator-side only
- Operator's local `.env.local` values

Curl examples that are safe to keep here use `$API_KEY` as a placeholder. The actual token lives only in operator's local environment.

## Related

- [[Phase-Status-Pointer]] — single source of truth for live state
- [[Module-Reconciliation]] — `/health` and `/operator/readiness` consume from this module
- [[Module-Notifications]] — `/operator/status-report` shape
- [[Module-Agent-Bus]] — `/firm-agents/*` shape
- [[Reconciliation]] — operator-facing audit context
- [[Nexus-MOC]]
