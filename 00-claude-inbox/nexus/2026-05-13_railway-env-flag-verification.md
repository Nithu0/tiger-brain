---
date: 2026-05-13
type: audit
project: nexus
status: needs-operator-action
---

# Railway env-flag verification — 2026-05-13

## TL;DR

Live trading-flag state is **not exposed on any public endpoint**. Only authenticated `/operator/*`, `/diagnostic/*`, and `/firm-agents/*` could potentially echo env vars, and the worker boot log on Railway never includes them either (boot line only logs `llmConcurrency` + `commitSha`). Operator must verify flags directly in Railway → ai-assistent worker service → Variables tab.

## What I could verify remotely (public)

`GET /health` (api-production-b660): returns infra checks only.

```
status=ok, commit=5c07156d, db.ok=true (43ms), broker.ok=true mode=demo balance=89245.47,
blackboard lastMarketRawSec=58 lastDecisionSec=56095,
worker lastCycleNo=76 lastCycleDurationMs=5128 lastError=null,
reconciliation driftCountUnresolved=0 balanceDelta=13.63
```

Observations:
- Worker is alive and cycling (cycle 76, last cycle 55s ago).
- **`lastDecisionSec=56095` (~15.6 h) is concerning** — no firm decision logged since ~17:40 UTC 12.5. Either decisions aren't being written to blackboard, or no strategy fired a signal in the window. Cross-check with separate trade-flow audit.
- Build commit on prod = `5c07156d`. Cross-ref `git log` to confirm which proposals landed.

## What I could NOT verify remotely

All four authenticated endpoints (`/operator/readiness`, `/diagnostic/broker`, `/firm-agents/overview`, `/diagnostic`) returned `{"error":"Unauthorized"}`. I deliberately did not read `.env.local` to extract the API_KEY (per binding secret-handling rule). Even with auth, **none of these routes are coded to echo the trading flags below** — confirmed by grepping `apps/api/src/routes/{diagnostic,operator,operator-readiness,health}.ts` for the flag names: zero matches.

The worker boot log line (`apps/worker/src/index.ts:297-300`) prints only `llmConcurrency` and `commitSha`. There is no env-flag echo on boot.

## Operator-side check required — canonical list

In Railway → project `ai-assistent` → service `worker` → Variables tab, confirm:

| Flag | Expected | Why |
|---|---|---|
| `SL_COOLDOWN_ENABLED` | `true` | Operator says flipped Mon. firm_state has cooldown entries (working). gate_decisions empty — likely the gate writes to `firm_state` only, not `gate_decisions`. Verify flag = `true`. |
| `SESSION_BLOCK_ENABLED` | `true` | 4 hard rejects logged → confirmed working from DB. Just confirm flag present. |
| `REGIME_DIRECTION_GATE_ENABLED` | `?` | 0 gate_decisions rows. **Most likely unset / `false`**. Karri proposal landed in commit `4c51309` per commit log, but flag may not have been flipped on Railway. Check first. |
| `DAILY_TRADE_CAP_ENABLED` | `true` | 8 evals 0 rejects in DB → flag is set. Confirm present. |
| `MEAN_REVERSION_ENABLED` | `true` | Operator says true but **0 evidence S4 evaluating**. Check flag spelling. Also check `MEAN_REVERSION_*` sub-flags (config thresholds). |
| `SCALP_OVERLAP_ENABLED` | `false` | Karri flip Tue evening should have disabled. Verify. |
| `ORB_ENABLED` | `false` | Karri flip Tue evening should have disabled. Verify. |
| `POSITION_MANAGEMENT_ENABLED` | `true` | Foundation gate rule #2 — must be `true` for trading session. Per `docs/ref/feature-flags.md` line 39 default = `true`; verify Railway has not overridden. |

Same flags on `api` service (some are read API-side too) — quick sanity check both Variables tabs.

## Recommended follow-up (Claude-side, optional)

To make this verifiable remotely next time, **add a `/diagnostic/flags` route** in `apps/api/src/routes/diagnostic.ts` (auth-gated) that returns a JSON map of flag-name → bool for the ~15 trading flags. Then this audit becomes a single curl. Filing as a future proposal — non-strategic, observability-only, so no Karri review needed (per binding rule: "observability ... does NOT need a proposal"). Hold for operator OK before implementing.

Alternative: extend the worker boot `logInfo("worker", "boot", ...)` line at `apps/worker/src/index.ts:297` to include all `*_ENABLED` flags. Lands in Railway worker logs on every redeploy. Cheaper.

## Remote-verifiable vs operator-side summary

- **Remote-verifiable (today):** infra health, worker liveness, DB latency, broker mode, balance, cycle counters, blackboard staleness, commit SHA. → All green except `lastDecisionSec` ~15.6h staleness flag worth chasing.
- **Operator-side only (today):** every flag in the table above. No way around Railway Variables tab inspection until an env-echo endpoint or boot-log line is added.

## Action

1. Operator: open Railway → ai-assistent → worker → Variables, photograph or paste the 8 flag values back into this note (replace the `?` and check each row).
2. Once flags confirmed, decide whether `lastDecisionSec=56095` is from disabled strategies (expected) or a silent block (needs `silent-blocker-debug.md` playbook).
3. If operator wants the `/diagnostic/flags` endpoint added: say "OK kjør" and I'll ship it focused-diff style.
