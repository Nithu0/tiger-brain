---
date: 2026-05-11
type: ops-verify
commit: 53210f0
subject: Railway redeploy verify — husky-prepare fix
status: PASS
---

# Railway redeploy verify — commit `53210f0`

Verification that the husky-prepare CI fix landed cleanly on Railway worker + API.

## Result: PASS

Build commit on Railway matches HEAD. Worker ticking. No errors. DB + broker green.

## Sample 1 (initial, T+0)

```json
{
  "commit": "53210f04",
  "worker": {
    "ok": true,
    "lastHeartbeatSec": 20,
    "lastCycleNo": 7,
    "lastCycleDurationMs": 12206,
    "lastError": null
  }
}
```

## Sample 2 (mid, ~T+90s)

```json
{
  "commit": "53210f04",
  "worker": {
    "ok": true,
    "lastHeartbeatSec": 23,
    "lastCycleNo": 8,
    "lastCycleDurationMs": 2858,
    "lastError": null
  },
  "db": true,
  "broker": true
}
```

## Sample 3 (post-180s)

```json
{
  "commit": "53210f04",
  "worker": {
    "ok": true,
    "lastHeartbeatSec": 15,
    "lastCycleNo": 12,
    "lastCycleDurationMs": 3166,
    "lastError": null
  },
  "db": true,
  "broker": true
}
```

## Cycle progression

- Sample 1: cycle 7 (12.2s duration — post-deploy first cycle, normal cold start)
- Sample 2: cycle 8 (2.9s)
- Sample 3: cycle 12 (3.2s)

Cycles advancing 5 cycles across ~3 minutes — healthy ~30s cadence after the warm-up cycle.

## Persistence layer freshness (post-redeploy)

| Table | Last write |
|---|---|
| gate_decisions | 2026-05-11 13:33:04 |
| simulated_orders | 2026-05-11 13:33:04 |
| agent_artifacts | 2026-05-11 13:32:42 |
| blackboard | 2026-05-11 13:39:23 |

Blackboard advanced 13:37 → 13:39 between SQL samples. `gate_decisions` count over last 10min = 4. `blackboard` count over last 10min = 202. Orchestrator is fully operational.

Note: gate_decisions / simulated_orders / agent_artifacts haven't ticked in ~6 min — expected when no setup triggers the gate path; blackboard activity confirms the cycle is running.

## Deploy state

- HEAD locally = `53210f0 fix(ci): husky prepare must not fail in production builds (--omit=dev)`
- Railway commit reported = `53210f04` (matches HEAD)
- Deploy already complete by the time first /health probe ran (no waiting needed past initial 180s)
- `gh` CLI not available locally — could not query GitHub Actions check-runs

## Concerns

None. Clean redeploy. Worker, DB, broker all green. `lastError: null` across all samples.
