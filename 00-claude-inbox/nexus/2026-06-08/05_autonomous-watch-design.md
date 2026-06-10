# Autonomous watch — design + scaffold (2026-06-08)

Client-side READ-ONLY watch over the /443 pull channel. Pings ONLY on ALARM
(REPORT-only, no auto-disable — operator-prinsipp 1). Scaffold landed + verified;
NOT committed (operator-gated), scheduling is a separate operator step.

## Files
- **Script:** `scripts/ops/nexus-watch.sh` (read-only, no DB writes, no env mutation)
- **Runbook:** `docs/ops/nexus-watch-runbook.md`
- **Digest output:** `~/Obsidian/Brain/00-claude-inbox/nexus/<DAY>/watch-<TS>.md`
- **Dedup state:** `data/pull/.watch-state/last-alarms.json`

## What it monitors each run + thresholds

| Signal | Endpoint | HEALTHY | ALARM (pages) |
|---|---|---|---|
| Worker liveness/heartbeat | /health | ok, hb<30m, lastError=null, db.ok | unreachable / lastError set / db down / hb>1800s on weekday (relaxed→WARN if market closed) |
| Daily-loss vs limit | /firm/risk-snapshot | pct<80% | pctOfLimit >= 80% |
| Kill-switch / circuit-breaker clamps | /firm/risk-snapshot | none | any killSwitch active |
| Gate 100%-reject clamp | /decision-funnel?days=3 | no gate rejects all | gate with evaluated>=10 and hardRejected==evaluated |
| Expectancy drift | /analytics/performance | >= -75 USD | < -75 with n>=30 |
| Profit-factor drift | /analytics/performance | >= 0.6 | < 0.6 with n>=30 |
| Lessons proposed growth | /firehose/overview | low | +5 since last run → WARN (no page) |
| Calibration status | /operator/calibration-status | RECOMMEND_ONLY, autoApply off | autoApplyActive=true → WARN |
| Reconciliation drift | /health | 0 | >0 → WARN |
| Derive-status (#2) | /firehose/derive-status | n/a | tolerated (404 until #2 lands; logged, no false alarm) |

All thresholds env-overridable (NEXUS_WATCH_*). ALARM pages; WARN only in digest.
Note: PF/expectancy are lifetime-cumulative incl. pre-epoch backfill (current PF
0.71 / exp -50.15) — thresholds set loose on purpose to catch a real collapse,
not the known cold-start drag.

## Design properties
- Idempotent: one digest per run, no in-place edits.
- Dedup: same alarm won't re-page within NEXUS_WATCH_DEDUP_MIN (180m).
- Token read in subprocess (railway CLI → .env.local fallback), never echoed —
  same pattern as pull-nexus-data.sh.
- Delivery: always writes Brain digest; Discord ping ONLY with NEXUS_WATCH_PING=1
  AND a fresh (non-deduped) ALARM. Webhook from NEXUS_WATCH_DISCORD_WEBHOOK or
  DISCORD_ALERTS_WEBHOOK_URL in .env.local.
- REUSE=1 skips pulls and evaluates cached data/pull/*.json (no token needed).

## How to schedule (OPERATOR step — Claude does not auto-enable)
cron (weekdays, every 30m, page on alarm):
```
*/30 * * * 1-5  cd /home/nithu/code/ai-assistent && NEXUS_WATCH_PING=1 bash scripts/ops/nexus-watch.sh >> /tmp/nexus-watch.log 2>&1
```
Or a systemd --user timer (better on WSL across reboots). Dedup 180m keeps a
persistent alarm to ~1 page / 3h even at 30m cadence.

## Complement vs duplicate (vs cloud-side fab56f3)
Server-side worker already pages for: (1) hard single-trade loss, (2) loss-cap/
streak, (3) activation-health (ADX-null + gate-100%). Those are fast + in-loop +
fire even when this laptop is off.

Client-side watch deliberately:
- Does NOT alert single-trade hard losses (server owns #1 real-time).
- Overlaps coarsely on daily-loss + gate-100% as a CATCH-ALL if the worker's own
  alert path is down (webhook mis-set / worker crashed / DISCORD_LEGACY gate inert).
- ADDS what the server can't self-report: external worker-liveness/heartbeat
  (a dead worker can't page about its own death), reconciliation drift,
  expectancy/PF drift, proposed-lesson growth, calibration auto-apply state.

Net: server = in-loop + always-on; client = independent external observer that
survives a worker outage + adds drift/liveness. Dedup window >= worker debounce
so the two don't stack on one incident.

## Verify (all passed)
- `bash -n` clean.
- REUSE dry-run → verdict HEALTHY, all 9 signal lines parsed from real cached JSON.
- Forced ALARM (EXPECTANCY_USD=0) → fired correctly; 2nd run within window deduped
  (verdict back to HEALTHY). Test artifacts cleaned.

## Open follow-ups
- derive-status (#2) endpoint 404s today — watch tolerates it; tighten once landed.
- When a firm-epoch-scoped performance endpoint exists, point expectancy/PF at it
  and tighten thresholds (current loose thresholds are a backfill-drag workaround).
