---
date: 2026-05-11
topic: discord-delivery
trigger: operator flipped DISCORD_LEGACY_ENABLED=true on Railway
status: verified
verdict: silent-but-no-trigger
---

# Discord delivery post-flip verification — 2026-05-11

## TL;DR

**Verdict: silent-but-no-trigger.** Pipeline is correctly wired and the master+legacy gates both pass. No artifacts have failed delivery. The reason no Discord pings are landing is that the only two firm-agents wired to `sendDiscordEmbed` via the audit-trail-aware bridge (`operator-brief`, `risk-advisor`) have not produced any *deliverable* events since the flip:
- `operator-brief` does not write artifacts of any kind matching `operator-brief` in `agent_artifacts` — looking at the last 24 h none have fired yet (next fire is morning brief, gated by date-of-day).
- `risk-advisor` IS running every ~5 min and emitting `xauusd.risk.advisory` to the blackboard. **Half are severity=OK ("no open positions")**, which short-circuits before `sendAdvisoryEmbed`. **WATCH/ALERT advisories did fire** in the last 30 min (12:14Z ALERT, 12:20Z WATCH) — but those calls don't pass `(db, artifactId)` to the bridge, so they leave no audit trail in `agent_artifacts.discord_delivery_status`. Discord-server inspection is the only ground truth for those.

## What I verified

### 1. Build is past the audit-trail commit
- `/health.build.commit` = `cb5f48c9` (current main HEAD)
- `f9f92d0 feat(observability): discord_delivery_status audit trail on agent_artifacts` is 4 commits behind HEAD → deployed.

### 2. Audit-trail columns exist
- `agent_artifacts.discord_delivery_status` (text) — present
- `agent_artifacts.discord_delivered_at` (timestamptz) — present

### 3. Recent artifacts (last 30 min — 4 rows)
All are `kind IN ('research_note','review')` with `discord_delivery_status = NULL` and `notified_at = NULL`. These kinds are written by the research drainer (`worker-research-drainer-12`) and atlas reviewer — neither calls `sendDiscordEmbed` at all, so `NULL` is correct/expected behavior, not a delivery failure.

### 4. Last 24h delivery status mix
| status | count |
|---|---|
| `null` | 10 |
| `sent` | 0 |
| `skipped_master_gate` | 0 |
| `skipped_legacy_gate` | 0 |
| `failed_*` | 0 |

→ No row has gone through the audit-writer path at all in the last day. Consistent with: `operator-brief` has not fired today, and `risk-advisor` doesn't pass `db`/`artifactId`.

### 5. operator-brief in last 6 h
Zero rows. `agent_artifacts` does not contain any `kind='operator-brief'`/`'morning-brief'`/`'brief'`. The morning brief is once-per-UTC-day gated; today's brief either fired before the audit trail existed, or hasn't fired yet this UTC day (12:37Z when checked).

### 6. risk-advisor activity (last hour)
10 advisories on `xauusd.risk.advisory`. Severity distribution:
- 3× OK ("No open positions — nothing to advise on") — does **not** call `sendAdvisoryEmbed` (gated by `if (severity !== "OK")` at `risk-advisor.ts:166`)
- 1× WATCH 12:20Z — "Short held into MIXED_NO_EDGE regime with persistent risk_level_high gate rejections — thesis decay risk." → should have fired embed
- 1× ALERT 12:14Z — "Regime shifted to HIGH_VOLATILITY against a TRENDING-entry short..." → should have fired embed
- 5× WATCH/normal/high earlier with `artifact_id: null` in state

Risk-advisor calls `sendAdvisoryEmbed({severity, headline, body, taskId})` WITHOUT `db`/`artifactId` → audit-trail UPDATE is a NO-OP for these (intentional, see `discord-bridge.ts:90`).

## Code-path map (where audit-trail is plumbed)

| Caller | Passes `(db, artifactId)`? | Audit trail? | Active? |
|---|---|---|---|
| `operator-brief.ts:171-179` → `sendMorningBriefEmbed` | yes (`db: ctx.db, artifactId: artId`) | yes | once-per-UTC-day, hasn't fired yet today |
| `risk-advisor.ts:166-168` → `sendAdvisoryEmbed` | no | no | fires on every WATCH/ALERT — confirmed running |
| `macro-event.ts` → `sendAdvisoryEmbed` | (not yet inspected — likely no `db`) | tbd | tbd |
| `research-drainer` / `atlas` / `daily-journal` / `strategy-tuner` / `client.ts` → INSERT artifacts | n/a (don't call Discord) | n/a — write artifacts, not embeds | running |

## What this means for the operator

1. **The flag flip itself worked.** No `skipped_master_gate` and no `skipped_legacy_gate` rows means both `AGENT_DISCORD_DELIVERY_ENABLED=true` AND `DISCORD_LEGACY_ENABLED=true` are honored.
2. **The reason there's no Discord traffic is upstream:** the only audit-instrumented call site (`operator-brief`) is dormant until tomorrow's UTC midnight.
3. **WATCH/ALERT advisories should be hitting Discord right now.** If they aren't, the failure is invisible to the DB — it's in the HTTP layer or env (`DISCORD_BOT_TOKEN` / `DISCORD_CHANNEL_ID`). Operator should glance at Discord channel for an ALERT around 12:14Z UTC and a WATCH around 12:20Z UTC.

## Recommended next actions (not done — read-only DB)

- **Operator check:** Look at the Discord channel for entries dated ~12:14Z and ~12:20Z UTC 2026-05-11. If present → pipeline is fully working. If absent → bot token or channel-id is wrong/missing in Railway env, since both gates are clearly open.
- **Code follow-up (separate proposal):** Thread `db`+`artifactId` through `sendAdvisoryEmbed` callers (`risk-advisor`, `macro-event`) so we get audit visibility for the high-frequency path. Currently only operator-brief (1×/day) shows up in the audit trail. Two-line change at `risk-advisor.ts:167`.
- **Tomorrow morning:** First UTC-day operator-brief should produce a `sent` row in `agent_artifacts.discord_delivery_status`. If it instead writes `skipped_legacy_gate` or `failed_http_*`, then we have a concrete bug. If it writes `sent` and the Discord channel shows the embed, the loop is closed.

## Raw queries used

```sql
-- schema check
SELECT column_name FROM information_schema.columns
WHERE table_name='agent_artifacts' AND column_name LIKE 'discord_%';

-- last-30min artifacts
SELECT id, kind, created_at, notified_at, discord_delivery_status, discord_delivered_at
FROM agent_artifacts
WHERE created_at > NOW() - INTERVAL '30 minutes'
ORDER BY created_at DESC LIMIT 20;

-- 24h status mix
SELECT discord_delivery_status, COUNT(*) FROM agent_artifacts
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY discord_delivery_status;

-- risk-advisor activity (blackboard, not agent_artifacts)
SELECT "timestamp", state->>'severity', state->>'headline'
FROM blackboard
WHERE topic='xauusd.risk.advisory'
ORDER BY "timestamp" DESC LIMIT 10;
```
