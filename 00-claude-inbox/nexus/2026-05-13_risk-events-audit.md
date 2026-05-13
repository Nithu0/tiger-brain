---
date: 2026-05-13
type: audit
project: nexus
status: open
---

# Risk Events Audit — 2026-05-13

## Verdict: (c) writer was never wired into firm path

Lifetime stats:

| metric | value |
|---|---|
| lifetime count | **13** |
| first event | 2026-04-09 12:43:31 UTC |
| last event | 2026-04-10 06:09:43 UTC |
| 7d count | **0** |
| dormant since | ~33 days |

Lifetime distribution:

| event_type | count |
|---|---|
| BOT_CONFLICT | 9 |
| DAILY_LOSS_LIMIT | 3 |
| NEWS_BLACKOUT | 1 |

## Schema (present + applied)

```
id          TEXT PK
bot_id      TEXT (FK bots.id)
event_type  TEXT NOT NULL
detail      JSONB
created_at  TIMESTAMPTZ DEFAULT NOW()
```

Defined in `packages/shared/src/db/schema.ts:86-92`. No `level`/`severity` column.

## Writer status

`apps/worker/src/services/risk.service.ts:34-45` exports `logRiskEvent(db, botId, eventType, detail)`. **Function intact, zero callers.**

`apps/worker/src/jobs/bot-cycle.ts:12` still imports `logRiskEvent` from risk.service but never invokes it (`grep -c "logRiskEvent("` = 0). Orphan import.

### Root cause

Commit `6299ae3` ("Separate analysis from execution — bots analyze, Trading Manager decides") deleted all four call sites from `bot-cycle.ts`:

1. `NEWS_BLACKOUT` — calendar block path
2. `CHALLENGE_FAILED` — challenge-state failed branch
3. `BOT_CONFLICT` — direction-conflict skip path
4. `DAILY_LOSS_LIMIT` — risk.allowed=false branch

That commit moved decision-making to the firm orchestrator path. **Risk events were never re-wired in the new firm path** — `grep -rn "risk_events\|logRiskEvent" apps/worker/src/firm/` returns zero hits.

The 13 lifetime events all predate `6299ae3` (last write 2026-04-10). After that commit the legacy path was retired and risk-event writes ended.

## Read side still alive

`apps/worker/src/agents/briefing.agent.ts:42` still SELECTs from `risk_events` for the morning briefing ("Risk events: none" every day for 33+ days — silent log, no alarm).

## Minimal fix path

Re-wire `logRiskEvent` calls at the equivalent decision points in the firm path. Candidate sites:

- **Daily-loss limit hit** — wherever firm-side risk-gate denies a trade (search `services/risk.service.ts::checkRisk` callers in `firm/`)
- **News blackout** — news/calendar gate in firm gate-stack
- **Session/cooldown blocks** that operator cares about long-term (optional — would flood table; gate on severity)
- **Bot/strategy conflict** — if firm still has the concept

Cheapest first cut: 1 line in the firm daily-loss-limit denial branch + 1 line in news-blackout branch. Restores morning-briefing signal + audit trail without behavior change. Strategy-impact = none (write-only). No proposal needed per CLAUDE.md "observability" exemption.

## Open question for operator

Is the `risk_events` table still part of the intended architecture, or did Karri's design move risk signals to blackboard topics / firm-agent events? If the latter, deprecate `risk_events` table + remove the briefing query. If the former, file a wiring PR.

## References

- Schema: `packages/shared/src/db/schema.ts:86`
- Writer (orphan): `apps/worker/src/services/risk.service.ts:34`
- Removed call sites: `git show 6299ae3 -- apps/worker/src/jobs/bot-cycle.ts`
- Read site (still live): `apps/worker/src/agents/briefing.agent.ts:42`
