---
type: claude-inbox
project: nexus
date: 2026-05-11
status: applied
commit: d81af0e
---

# macro-event Discord audit-trail — wired (Phase 3 of Discord-audit)

## Trigger

Follow-up to c062696 (risk-advisor + agent-trigger). Discord-comprehensive
audit on 2026-05-11 flagged macro-event as the remaining unaudited path:
`agent-bus/firm-agents/discord-bridge.ts:21` doc says "used by risk-advisor
+ agent-trigger + (unwired) macro-event". Final inbox note at
`2026-05-11-discord-audit-extend.md` line 85 explicitly flagged it.

## State before the fix

macro-event.ts did **not** call `sendAdvisoryEmbed` at all — it only
published to blackboard topic `xauusd.macro.events`. So the audit-doc
phrasing "passes call without (db, artifactId)" was slightly off:
there was no call yet. Net effect was the same — operator got zero
Discord pings for HOT macro clusters, and no audit-trail row.

## Fix applied

Added a thin Discord ping + agent_artifacts INSERT inside the
`severity !== "QUIET"` branch, mirroring risk-advisor exactly:

1. Generate `advisoryId = uuidv4()`.
2. INSERT into `agent_artifacts` with kind='advisory', metadata={agent,
   advisoryId, severity, eventCount, nextEvent}. Wrapped in try/catch so
   audit-row failure doesn't block the send.
3. Call `sendAdvisoryEmbed({severity, headline, body, taskId, db, artifactId})`
   so the bridge writes `discord_delivery_status` for this path.

### Severity mapping into bridge taxonomy

macro-event uses `QUIET | NORMAL | ACTIVE | HOT`; bridge expects
`OK | WATCH | ALERT`. Chosen mapping:

| macro-event | bridge | ping? |
|---|---|---|
| QUIET | (n/a) | no |
| NORMAL | WATCH | yes — heads-up for high-impact events ahead |
| ACTIVE | WATCH | yes |
| HOT | ALERT | yes |

Reasoning: macro-event already filters to `impact='high'` events in next
24h, so any non-QUIET cluster carries real positioning risk. NORMAL still
warrants a heads-up; QUIET is the no-events case.

If operator wants to gate this tighter (e.g. HOT-only), trivial follow-up:
flip the `severity !== "QUIET"` check to `severity === "HOT"`.

## Files touched

- `apps/worker/src/firm/agent-bus/firm-agents/macro-event.ts` (+40 lines)
  - Imports: `uuid`, `createHash`, `sendAdvisoryEmbed`
  - New block after blackboard publish: artifact-insert + bridge call

## Verification

- `cd apps/worker && npx tsc --noEmit` → clean
- `npm test` → **478/478 pass**, 0 fail, 15.4s
- Pre-commit hook ran tsc on touched workspace, passed

## Commit

`d81af0e feat(observability): wire macro-event Discord audit-trail`

Not pushed (operator-prinsipp 5: "OK kjør"-gate before push).

## Coverage now

Discord audit-trail (`agent_artifacts.discord_delivery_status`) populates
for **3 paths**:

1. operator-brief → `sendMorningBriefEmbed` (oldest, since Phase 6 wiring)
2. risk-advisor → `sendAdvisoryEmbed` (c062696, 2026-05-11)
3. agent-trigger → `sendTriggerEmbed` (c062696, 2026-05-11)
4. macro-event → `sendAdvisoryEmbed` (d81af0e, 2026-05-11) — NEW

All four follow the same INSERT-then-pass-artifactId pattern. The
audit-extend convention table (NULL = informational, NOT NULL = delivered
path) now applies to macro-event too.

## Out-of-scope follow-ups

- Operator may want to gate macro-event ping to HOT-only after observing
  Discord-channel noise from NORMAL/ACTIVE-level events.
- Same pattern remains unwired for any future agent that wraps a Discord
  send — would benefit from a small helper in `discord-bridge.ts` that
  takes (db, agent, severity, content) and does the INSERT + send in one
  call. Tracked as cleanup candidate.

## Audit-query rule (unchanged)

```sql
SELECT kind, discord_delivery_status, COUNT(*)
FROM agent_artifacts
WHERE created_at > NOW() - INTERVAL '24 hours'
  AND discord_delivery_status IS NOT NULL
GROUP BY 1, 2 ORDER BY 1, 2;
```

After this commit deploys + FIRM_AGENT_MACRO_EVENT_ENABLED is set, expect
new advisory-kind rows from macro-event in addition to risk-advisor's.
