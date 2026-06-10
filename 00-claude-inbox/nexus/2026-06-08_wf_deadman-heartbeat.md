# WF lane: deadman-heartbeat — DESIGN + n8n (2026-06-08)

Agent: ai-2 firm worker. Status: DESIGN ONLY. Nothing enabled. No code committed (this lane is pure design + spec).

## TL;DR

The one failure no in-process monitor can catch is **total worker death**: when the
worker process dies, `loss-and-activation-monitor`, `foundation-monitor`,
`flow-watcher` and the heartbeat-writer all die with it — silence, not an alert.
The fix is an **external** dead-man watcher that lives outside the worker, polls
`/health` over 443, and pings Discord when the worker heartbeat goes stale or the
API is unreachable.

`/health` already exposes everything we need — no new worker code, no DB access,
no schema change. The watcher is read-only and behaviour-neutral by construction.

n8n MCP is **NOT reachable** this session (confirmed: no `mcp__n8n__*` tool in the
deferred-tool roster; matches memory `n8n_integration_pickup.md` — the local MCP
entry was removed 2026-05-13, pending REST API). So I deliver: (A) the n8n workflow
JSON as a ready-to-import draft, and (B) a Railway-cron / standalone-script
alternative. Operator picks the host. **Neither is enabled.**

## Why external (the gap)

The worker writes its own pulse every cycle:

- `apps/worker/src/firm/orchestrator.ts:820-844` — fire-and-forget upsert into
  `firm_state (key='worker:heartbeat')`, value `{cycleNo, cycleDurationMs, lastError}`,
  `updated_at = NOW()` each cycle.

Every existing anomaly alert (loss-cap, activation-health, foundation-flip,
flow-watcher) runs *inside* `runCycle()`. If the worker crashes, OOMs, hangs, or
Railway stops the service, no cycle runs → no alert fires. The heartbeat *row* just
sits there ageing. The dashboard `/explorer/weaknesses` and `/health` already
*recognise* this (`apps/api/src/lib/weaknesses-firm-activity.ts`), but nothing
*pushes* it — operator must be looking. The dead-man watcher closes that loop.

## Polling target: GET /health (already live)

Confirmed live this session (pulled over 443):

```json
"worker": {
  "ok": true,
  "lastHeartbeatSec": 31,
  "lastCycleNo": 351,
  "lastCycleDurationMs": 9169,
  "cyclesPerHour": 55,
  "lastError": null
}
```

Source of truth: `apps/api/src/routes/health.ts:209-263` (`checkWorker`). It reads
`EXTRACT(EPOCH FROM (NOW() - updated_at))` on the `worker:heartbeat` row, returns
`lastHeartbeatSec` (null if row/table absent) and `ok = age <= 600`.

Base URL: `https://api-production-b660.up.railway.app` (canonical — memory
`reference-railway-api.md`). Auth: `Authorization: Bearer $API_KEY`.

### Why /health and not direct DB
The network firewall blocks 5432/58688/SSH; only 443 works. The API service is a
**separate process** from the worker, so `/health` keeps answering even when the
worker is dead — which is exactly the signal we want. Direct DB polling would also
work for (b)/(c) but not for (d) API-down, and it isn't reachable from operator's
network anyway.

## Alert conditions (the watcher fires Discord on ANY of)

| # | Condition | Meaning | Severity |
|---|---|---|---|
| a | HTTP request fails / times out / status != 200 | API itself down OR network — partial outage | high |
| b | `checks.worker.ok === false` OR `checks.worker.lastHeartbeatSec === null` | worker row missing / API says not-ok | high |
| c | `checks.worker.lastHeartbeatSec > tolerance` | worker stalled / dead | high |

**Tolerance must mirror the codebase** (`weaknesses-firm-activity.ts:54-56`,
`heartbeatToleranceSec`): **600s on weekdays, 5400s on weekends** (worker
legitimately throttles to ~1 cycle/h when market is closed). A naive fixed
threshold would false-alarm every weekend. The watcher computes weekend from UTC
day-of-week (Sat/Sun), matching the API.

**Recovery / flap control:** edge-triggered. Alert once on DOWN transition; send a
single "RECOVERED" when it returns healthy. Persist `last_state` (UP/DOWN) so a
2-min poll does not spam. For n8n: store in a static-data / workflow variable. For
the script: a tiny state file (e.g. `/tmp/nexus-deadman.state`).

**Poll cadence:** every 2 min. With 600s weekday tolerance that gives ~5 polls of
headroom before a real stall trips — fast enough to catch a dead worker within a
few minutes, slow enough to be free.

**Consecutive-failure debounce:** require 2 consecutive bad polls before firing (so
one transient 502 from a Railway redeploy doesn't page). Redeploys of the API are
brief; redeploys of the worker reset the heartbeat fresh, so they won't trip (c).

## Discord payload

Reuse the canonical webhook env `DISCORD_ALERTS_WEBHOOK_URL` (fallback
`DISCORD_WEBHOOK_URL`) — same as `foundation-monitor.ts:531` and
`flow-watcher/index.ts:510`. Embed:

- DOWN: title "🔴 Nexus worker DEAD-MAN" (no emoji in code per operator pref — use
  text "[DEAD-MAN] Nexus worker"), red `0xf85149`, fields: condition (a/b/c),
  `lastHeartbeatSec`, `lastCycleNo`, `status`, timestamp, "Check worker service on
  Railway".
- RECOVERED: text "[RECOVERED] Nexus worker", green, `lastHeartbeatSec` now fresh.

> REPORT-ONLY, operator-prinsipp #1: the watcher never restarts, never flips a
> flag, never touches trading. It pages a human. Operator decides handling.

---

## (A) n8n workflow JSON (import-ready draft — NOT activated)

Schedule trigger (2 min) → HTTP Request GET /health → Function (evaluate +
edge-detect via workflow static data) → IF down/recovered → Discord (HTTP POST to
webhook). The `active: false` flag keeps it dormant on import.

```json
{
  "name": "Nexus Worker Dead-Man Heartbeat",
  "active": false,
  "settings": { "executionOrder": "v1" },
  "nodes": [
    {
      "parameters": { "rule": { "interval": [{ "field": "minutes", "minutesInterval": 2 }] } },
      "id": "cron",
      "name": "Every 2 min",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1.1,
      "position": [240, 300]
    },
    {
      "parameters": {
        "url": "https://api-production-b660.up.railway.app/health",
        "options": { "timeout": 15000, "response": { "response": { "neverError": true, "fullResponse": true } } },
        "sendHeaders": true,
        "headerParameters": { "parameters": [
          { "name": "Authorization", "value": "=Bearer {{$env.NEXUS_API_KEY}}" }
        ] }
      },
      "id": "http",
      "name": "GET /health",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [460, 300],
      "continueOnFail": true
    },
    {
      "parameters": {
        "functionCode": "const sd = $getWorkflowStaticData('global');\nconst prev = sd.lastState || 'UP';\nlet down = false, reason = '', hb = null, status = null, cycle = null;\nconst item = items[0].json || {};\nconst code = item.statusCode || (item.error ? 0 : 200);\nif (code !== 200) { down = true; reason = `API unreachable / HTTP ${code}`; }\nelse {\n  const body = item.body || item;\n  const w = (body.checks && body.checks.worker) || {};\n  status = body.status; cycle = w.lastCycleNo; hb = w.lastHeartbeatSec;\n  const now = new Date();\n  const dow = now.getUTCDay();\n  const weekend = (dow === 0 || dow === 6);\n  const tol = weekend ? 5400 : 600;\n  if (w.ok === false || hb == null) { down = true; reason = 'worker.ok=false or heartbeat missing'; }\n  else if (hb > tol) { down = true; reason = `heartbeat ${hb}s > tolerance ${tol}s`; }\n}\n// consecutive-failure debounce\nsd.fails = down ? (sd.fails || 0) + 1 : 0;\nconst confirmedDown = sd.fails >= 2;\nlet emit = null;\nif (confirmedDown && prev === 'UP') { sd.lastState = 'DOWN'; emit = 'DOWN'; }\nelse if (!down && prev === 'DOWN') { sd.lastState = 'UP'; emit = 'RECOVERED'; }\nreturn emit ? [{ json: { emit, reason, hb, status, cycle } }] : [];"
      },
      "id": "eval",
      "name": "Evaluate + edge-detect",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [680, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "={{$env.DISCORD_ALERTS_WEBHOOK_URL}}",
        "sendBody": true,
        "specifyBody": "json",
        "jsonBody": "={\n  \"embeds\": [{\n    \"title\": \"{{$json.emit === 'DOWN' ? '[DEAD-MAN] Nexus worker' : '[RECOVERED] Nexus worker'}}\",\n    \"color\": {{$json.emit === 'DOWN' ? 16270159 : 4243543}},\n    \"description\": \"{{$json.reason}}\",\n    \"fields\": [\n      { \"name\": \"lastHeartbeatSec\", \"value\": \"{{$json.hb}}\", \"inline\": true },\n      { \"name\": \"lastCycleNo\", \"value\": \"{{$json.cycle}}\", \"inline\": true },\n      { \"name\": \"status\", \"value\": \"{{$json.status}}\", \"inline\": true }\n    ]\n  }]\n}"
      },
      "id": "discord",
      "name": "Discord alert",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [900, 300]
    }
  ],
  "connections": {
    "Every 2 min": { "main": [[{ "node": "GET /health", "type": "main", "index": 0 }]] },
    "GET /health": { "main": [[{ "node": "Evaluate + edge-detect", "type": "main", "index": 0 }]] },
    "Evaluate + edge-detect": { "main": [[{ "node": "Discord alert", "type": "main", "index": 0 }]] }
  }
}
```

n8n setup notes (operator):
1. Import → leave **inactive**.
2. Add n8n env / credentials: `NEXUS_API_KEY` (the API service `API_KEY`),
   `DISCORD_ALERTS_WEBHOOK_URL`. Do NOT inline secrets in the node.
3. Test once via "Execute Workflow" against current healthy state → expect no
   Discord (emit empty). Then optionally simulate by temporarily setting tolerance
   low in the Function to confirm an alert fires.
4. Activate only when satisfied. (This lane does not activate it.)

## (B) Railway-cron / standalone-script alternative (NOT enabled)

If n8n stays out of reach, a self-contained poller is the zero-dependency path.
Proposed location if BUILT later: `scripts/ops/deadman-heartbeat.sh` on a NEW branch
`feat/wf-deadman-heartbeat`, behind a default-OFF flag `DEADMAN_ENABLED` (script
exits 0 immediately unless `DEADMAN_ENABLED=true`), so merging is behaviour-neutral.
Host options: (1) Railway cron service running every 2 min; (2) operator's own
machine cron; (3) a free uptime service (UptimeRobot/BetterStack) pointed at a thin
public `/health/worker` proxy — but that needs an unauthenticated route, so skip
unless operator wants it.

Script spec (pseudocode — NOT written this lane, design only):

```sh
# deadman-heartbeat.sh  (default OFF: exits unless DEADMAN_ENABLED=true)
[ "${DEADMAN_ENABLED:-false}" = "true" ] || exit 0
BASE=https://api-production-b660.up.railway.app
STATE=${DEADMAN_STATE_FILE:-/tmp/nexus-deadman.state}   # holds UP|DOWN + failcount
resp=$(curl -s -m 15 -w '\n%{http_code}' -H "Authorization: Bearer $API_KEY" "$BASE/health")
code=last line; body=rest
weekend? -> tol = (Sat|Sun) ? 5400 : 600     # mirror heartbeatToleranceSec()
down = (code!=200) || worker.ok==false || hb==null || hb>tol
debounce: 2 consecutive downs before DOWN; edge-detect against $STATE
on DOWN-edge  -> curl POST $DISCORD_ALERTS_WEBHOOK_URL  (text "[DEAD-MAN] ...")
on UP-edge    -> curl POST ... ("[RECOVERED] ...")
# REPORT ONLY. Never restarts, never flips flags. (operator-prinsipp #1)
```

Railway cron host (operator action, NOT done here): a tiny cron service in the
Nexus project, schedule `*/2 * * * *`, env `DEADMAN_ENABLED=true`, `API_KEY`,
`DISCORD_ALERTS_WEBHOOK_URL`, `DEADMAN_STATE_FILE=/data/deadman.state` on a small
volume (or use Railway's persistent storage; without a volume the state resets each
run → it would re-alert on every DOWN poll, so a 2-min state store is required for
flap control).

## Recommendation

n8n path (A) is preferred: it's off-box (survives a full Nexus-project outage,
which a Railway-cron-in-the-same-project does NOT — if Railway is down, both the
worker and a Railway cron die together, defeating the dead-man). Put the watcher
where it can outlive the thing it watches. Operator's n8n cloud instance is the
right home. Until n8n REST/MCP is wired, operator can import the JSON above by hand.

## Comparison vs in-process monitors (why this is additive, not duplicate)

- `loss-and-activation-monitor` / `foundation-monitor` / `flow-watcher`: in-process,
  catch *behavioural* anomalies while alive. Blind to their own death.
- `/health` + `/explorer/weaknesses`: already *detect* stale heartbeat, but **pull**
  — need a human watching the dashboard.
- **dead-man watcher (this lane): external + push.** The only thing that pages on
  total worker (or API) death. Complements, does not replace.

## No-action confirmation

- No Railway env flipped. No push/merge. No trade. No strategy/risk/gate change.
- No ADX/regime/indicator code touched (ai-1 owns that P0; this lane read
  `weaknesses-firm-activity.ts` for tolerance constants only).
- No code committed — pure design. If operator says BUILD, the script path is a
  new branch + default-OFF `DEADMAN_ENABLED` flag, tsc + tests before commit.
- n8n workflow JSON drafted but NOT created/activated (n8n MCP unreachable anyway).
