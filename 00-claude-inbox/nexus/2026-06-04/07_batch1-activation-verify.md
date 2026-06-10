# Batch-1 activation verify — 2026-06-04 16:20Z

Operator flipped Batch-1 on Railway last night:
- `DAILY_TRADE_CAP_ENABLED` (Worker)
- `REGIME_DIRECTION_GATE_ENABLED` (Worker)
- `MANUAL_POSITION_CONTROL_ENABLED` (Worker + API)

Verification done READ-ONLY over HTTPS/443 (`pull-nexus-data.sh` + curl probes).
DB port 58688 and nexus-pg MCP are firewalled from this network — `gate_decisions.reason`
aggregation (the one thing that would settle BITES vs NO-OP) is **not** reachable from here.

## Per-flag verdict

| Flag | Service | Took effect? | Evidence |
|---|---|---|---|
| `REGIME_DIRECTION_GATE_ENABLED` | Worker | **YES** | `regime_direction_gate` is being written to `gate_decisions`: 19 evals / 7d, 12 / 3d (`/decision-funnel`). When the flag is OFF the gate returns early and writes nothing, so non-zero eval rows = flag active. |
| `DAILY_TRADE_CAP_ENABLED` | Worker | **YES** | `daily_trade_cap` writes rows too: 19 / 7d, 12 / 3d, 4 / 24h. Same soft-log-when-enabled logic. Producing gate_decisions rows as required. |
| `MANUAL_POSITION_CONTROL_ENABLED` | API | **NO (did NOT take — wrong deploy)** | `GET /positions/:id/manual-confirm-token` → **HTTP 404 "Route not found"**, not 403. Basic `GET /positions/:id` → 200, so the positions router IS mounted. The 404 means the deployed API build lacks the manual-control routes entirely. `/health.build.commit = e934e629` — that commit is **not in this branch's history** (`node-migration-nexus`, HEAD 8ddb445). Manual-control feature landed in `685164a` (2026-06-03 19:27). The API is running an older/divergent build that predates the feature. Flipping the env var on that build is inert — the code that reads it isn't deployed. |
| `MANUAL_POSITION_CONTROL_ENABLED` | Worker | **UNKNOWN** | Worker exec path (consumes the operator-intent blackboard msg) couldn't be exercised — no open positions to act on, and Worker env/commit not readable via Railway CLI from here (only API service vars are). Can't confirm the worker deploy includes `685164a` either. |

## Regime-direction gate verdict: **CAN'T-TELL — NEED LOGS** (leaning NO-OP right now)

The gate is live and evaluating, but every one of the 19/7d evals **passed** (0 would_reject, 0 hard_reject). That alone doesn't distinguish:
- **NO-OP**: regimeDirection resolved `null` → gate allows with `direction_unknown` (the historical 97.7%-null problem).
- **BITES-capable but with-trend**: direction resolved UP/DOWN but proposals happened to be with-trend / non-mean-reversion → `with_trend` / `not_mean_reversion_strategy`.

The distinguishing signal is `gate_decisions.reason`, which no HTTPS endpoint aggregates
(`/decision-funnel.topRejectReasons` only covers `would_reject=true` rows). DB is firewalled.

Contextual tell: current regime via `/operator/status` + activity-feed = **HIGH_VOLATILITY**,
not TRENDING. The classifier only runs in TRENDING (portfolio-brain.ts:212), so right now the
gate necessarily no-ops with reason `regime_not_trending` regardless of direction. To see it
potentially BITE you need a TRENDING regime window with a mean-reversion strategy
(`xau-scalp-overlap` / `xau-vol-expansion`) proposing counter-trend.

### Exact Railway Worker-log greps to settle it (operator action)

In Railway → **Worker** service → Logs:

- `grep "regime-direction: UP"` and `grep "regime-direction: DOWN"` → direction IS resolving → gate can BITE.
- `grep "regime-direction: INSUFFICIENT DATA"` → WARN, candle fetch failing/empty → broken, fix data path (this is the bad case).
- `grep "regime-direction: FLAT"` → INFO, `flat_close_move`/`flat_ema_slope`, genuine consolidation → null is correct, gate correctly no-ops.
- `grep "regime-direction:"` (all) → full distribution.

Log emitters: `apps/worker/src/firm/portfolio-brain.ts:228/232/236`.
Only emitted when regime===TRENDING — if you see none, the system simply hasn't been in
TRENDING since the flip (consistent with current HIGH_VOLATILITY).

Alternatively (when DB reachable from an unfirewalled host):
```sql
SELECT reason, COUNT(*) FROM gate_decisions
WHERE gate_name='regime_direction_gate' AND recorded_at > NOW() - INTERVAL '7 days'
GROUP BY reason ORDER BY 2 DESC;
```
`ok_up`/`ok_down`/`with_trend`/`regime_direction_counter_trend:*` = BITES-capable;
`direction_unknown` / `regime_not_trending` dominating = NO-OP.

## Worker / system health

`/health` = **ok**. db ok (4ms), broker ok (demo, bal 89795.94), blackboard fresh
(lastMarketRaw 167s), worker heartbeat 164s, cycle #260, 19 cyc/h, lastError null,
reconciliation ok (0 unresolved drift). System is healthy and cycling.

`lastDecisionSec = 91516` (~25h) — no trade-decision emitted in ~a day, consistent with
HIGH_VOLATILITY + 9 trades opened over the 3d window but `decisionsEmitted: 0` in the funnel.

## Flags that did NOT take / look wrong

1. **API manual-control = wrong deploy.** API serving `e934e629`, a commit off this branch
   and before the manual-control feature (`685164a`). Operator should redeploy the API from
   the branch that contains `685164a` (or merge to whatever main the API tracks) and re-probe:
   `GET /positions/<openId>/manual-confirm-token?action=manual-close` should return 200 + a
   token (or 503 if API_KEY unset), **not** 404/403.
2. **Worker manual-control + worker deploy commit unverified** — couldn't read Worker vars or
   exercise the intent path (no open positions). Confirm the Worker deploy also includes
   `685164a` before trusting manual-close in prod.
3. Regime gate **not yet observed biting** — expected, market hasn't been TRENDING since flip.
   Not a defect; needs a TRENDING window to produce the first real learning datapoint.

## Net

- Worker-side gates (regime-direction, daily-cap): **flips took, writing rows, healthy.**
- API manual-control: **flip is inert — stale/divergent API deploy lacks the routes (404).** Redeploy needed.
- First real regime-gate learning: **inconclusive from API alone; grep Worker logs for `regime-direction:` (need a TRENDING window).** Current regime HIGH_VOLATILITY → gate correctly dormant right now.
