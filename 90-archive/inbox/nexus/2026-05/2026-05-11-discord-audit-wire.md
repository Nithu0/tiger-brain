# 2026-05-11 — Discord audit-trail wire for risk-advisor + agent-trigger

## Gap

`discord_delivery_status` column (added in audit-2026-05-11 migration) was only being populated by `operator-brief` (~1 send/day). Two higher-frequency paths were unaudited:

- `risk-advisor` → `sendAdvisoryEmbed`: ~10 advisories/hour when severity != OK
- `agent-trigger` → `sendTriggerEmbed`: fires per high-priority (>=105) task created (loss_streak, regime_flip, gate_spike)

Both paths called the send function WITHOUT passing `db` + `artifactId`, so the audit-trail UPDATE in `recordDeliveryStatus` no-op'd silently (`if (!db || !artifactId) return`).

## Path chosen: Path 2 (thin INSERT)

Investigation confirmed neither risk-advisor nor agent-trigger currently INSERT into `agent_artifacts`. Path 1 (just plumb existing IDs) wasn't available.

Followed the `operator-brief` pattern (`apps/worker/src/firm/agent-bus/firm-agents/operator-brief.ts:126`) — INSERT a small artifact row with `kind`, `content`, `sha256`, `bytes`, `metadata` then pass the new ID + `db` to the send function. Wrapped both INSERTs in try/catch so a failure NEVER blocks the Discord send (degrades gracefully to NULL audit, same as before this patch — never worse).

Schema cost: small. Risk-advisor publishes only on `severity !== "OK"` (already infrequent). Agent-trigger only on priority>=105. Estimated combined growth: <20 rows/hour.

## Files touched

- `apps/worker/src/firm/agent-bus/firm-agents/risk-advisor.ts` — added `createHash` import + INSERT block inside `if (severity !== "OK")` branch (lines 167-187 area)
- `apps/worker/src/firm/agent-bus/agent-trigger.ts` — added INSERT block inside `if (priority >= HIGH_PRIORITY_THRESHOLD)` branch (publishOnce helper); pass `db` + `artifactId` to `sendTriggerEmbed`
- `apps/worker/src/firm/agent-bus/agent-trigger.test.ts` — added 2 mock-response slots to the "discord bridge fires when AGENT_DISCORD_DELIVERY_ENABLED=true" fixture (one per high-priority trigger that fires)

`discord-bridge.ts` already had optional `db`+`artifactId` params + the UPDATE logic — no change needed there. Function signatures were forward-compatible.

## Verification

- `cd apps/worker && npx tsc --noEmit` → clean
- `cd apps/worker && npm test` → 445/445 pass (baseline 443; +2 from someone else's WIP in research-drainer area)
- Behavior change: zero. Audit-trail change only.

## Expected `discord_delivery_status` mix post-deploy

Assuming `AGENT_DISCORD_DELIVERY_ENABLED=true` and `DISCORD_LEGACY_ENABLED=true` (the double-gate from memory `project_discord_delivery_dual_gate.md`):

- `sent` — happy path, ~85-95% of all sends
- `skipped_master_gate` — populated retroactively when env flag disabled mid-run (rare)
- `skipped_legacy_gate` — when `DISCORD_LEGACY_ENABLED=false`; common on staging
- `failed_http_<status>` — Discord 429/5xx; rare but expected during incidents
- `failed_<error_name>` — node-level errors (lowercased exception name, truncated to 60 chars)

Quick reconciliation query for tomorrow:

```sql
SELECT kind,
       discord_delivery_status,
       COUNT(*) AS n,
       MIN(created_at) AS first_seen,
       MAX(discord_delivered_at) AS last_delivered
  FROM agent_artifacts
 WHERE created_at >= NOW() - INTERVAL '24 hours'
   AND kind IN ('advisory', 'trigger', 'journal')
 GROUP BY 1, 2
 ORDER BY 1, 3 DESC;
```

If `discord_delivery_status IS NULL` rows persist for `kind IN ('advisory','trigger')` 30+ minutes after delivery should have fired, suspect:
1. Master gate flipped (`AGENT_DISCORD_DELIVERY_ENABLED`)
2. INSERT into agent_artifacts failed silently (check Railway logs for `[firm.agent-trigger]` or `[firm.risk-advisor]` errors — but try/catch swallows so worth a separate counter later)

## Commit

`feat(observability): close Discord audit-trail gap for risk-advisor + agent-trigger` — SHA captured at commit time.

## Followups (NOT done here, but worth queueing)

- Counter metric on the INSERT try/catch so silent failures surface in dashboard
- Dashboard widget showing `discord_delivery_status` mix over last 24h
- Backfill: rows older than this commit's deploy timestamp will have NULL forever — fine, just document the cutoff
