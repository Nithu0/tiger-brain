# Fix: GET /explorer/weaknesses data-honesty (2026-06-04)

Endpoint feeds the operator trust dashboard. Audit found ~half of its output was
stale or false: it hardcoded already-fixed weaknesses and judged liveness from
the legacy `bots`/`signals` tables the firm path abandoned — producing false
"No bots running / platform idle" and "Last signal 1522 min old" even while the
worker was healthily cycling (`/health` shows it green from a different source).

Branch: `node-migration-nexus`. NO commit/push/Railway (per instruction).

## Files changed
- `apps/api/src/routes/explorer.ts` — the `/explorer/weaknesses` handler.
- `apps/api/src/lib/weaknesses-firm-activity.ts` — NEW. Pure, testable firm
  liveness assessment (heartbeat + cycles/hour), mirrors `/health` tolerances.
- `apps/api/src/lib/weaknesses-firm-activity.test.ts` — NEW. 9 tests, all green.

## Verify
- `cd apps/api && npx tsc --noEmit` → exit 0.
- New test: 9/9 pass. Existing `npm test`: 19/19 pass (no regression).

## False claims REMOVED / CORRECTED

1. **"No historical bar replay for backtesting" (Architecture)** — REMOVED.
   FALSE: `apps/api/src/backtest/runner.ts` replays the ORB strategy against M1
   candles in `ohlcv_candles` (the same table the firm persists to), exposed via
   `POST /backtest`. Strategy logic CAN now be validated against historical data.

2. **"No slippage model in paper execution — fills assume exact price" (Execution)**
   — REMOVED. FALSE on two counts: (a) the firm trades real OANDA practice orders
   and records the ACTUAL fill price (`strategy-execution.ts`), so fills carry
   OANDA's real bid/ask; (b) the pure-paper path applies an explicit session-based
   slippage+spread model on entry AND exit
   (`paper-execution.service.ts` → `calculateFillRealism()`, called in
   `tryOpenPosition` line ~259 and on close ~194).

3. **"No spread model — entry/exit prices do not include broker spread" (Execution)**
   — REMOVED. Same reason as #2. Replaced both with ONE honest, narrower note:
   the paper slippage/spread model is an approximation (fixed session buckets),
   severity dropped medium→low, category `modeling-approximation`.

4. **"Position SL/TP checks run every ~10 minutes, not tick-by-tick" +
   "gap through stop losses between cycles" (Trust)** — CORRECTED. FALSE for the
   live-broker path: SL/TP are attached as native OANDA `stopLossOnFill`/
   `takeProfitOnFill` conditional orders (`oanda.service.ts`), enforced
   server-side tick-by-tick — the cycle interval does not gate them. Rewrote to a
   true, narrower caveat scoped to the pure-paper (no-broker) path only.

5. **"No bots are currently running — platform is idle" (Operations/Risk)** —
   REMOVED. The `SELECT COUNT(*) FROM bots WHERE status='running'` is ALWAYS 0:
   the firm pauses all non-XAUUSD bots and never sets `status='running'`
   (`apps/worker/src/index.ts:326`). Firm liveness now judged via heartbeat.

6. **"Last signal is N min old" / "No signals in database" (Data Freshness)** —
   REMOVED the `signals`-staleness check. `signals` rows only land when a trade
   FILLS (a few/day), so multi-hour-old is HEALTHY during low-ADX/low-ATR no-trade
   periods (same caveat as `/health` `lastDecisionSec`). The 30-min threshold
   produced false "stale" alarms. Replaced with heartbeat-based liveness.

7. **QDRANT trustImpact "Agents lose memory between sessions — no learning"** —
   CORRECTED (env-conditional check kept). FALSE: a Postgres firm-memory +
   `agent_lessons` layer provides recall (`firm-memory.ts`,
   `agent-lessons/client.ts`). Qdrant would add semantic-similarity search on
   top, not basic recall. Reworded the message + impact accordingly.

## Tables REPOINTED (legacy → firm-path source)

| Check | OLD (legacy/dead) | NEW (firm-path, same as /health) |
|---|---|---|
| Worker idle / liveness | `bots.status='running'` count | `firm_state` key `worker:heartbeat` age, tolerance 600s weekday / 5400s weekend |
| Data freshness | `signals` last `created_at` (30-min threshold) | `market_snapshots` cycles in last hour + heartbeat |

Each new query is wrapped in its own try/catch → null on missing table (never 500),
matching `/health`'s defensive style.

## Kept (genuinely still open)
- Provider gaps (env-conditional: POLYGON/QSTASH/SENTRY/LOGTAIL/OpenAI-Anthropic).
- Single worker instance / single Postgres (SPOF, low severity).
- Sub-agent statuses are role labels, not live process health (transparency).
- Execution mode = OANDA practice / demo capital (reworded from "simulated";
  it IS real practice fills, just not live money).
- Paper slippage/spread is a bucketed approximation (the one narrowed Execution note).
- Job-failure / queue-health checks (jobs + BullMQ) left untouched — still valid.

## Note / possible follow-up
The `/explorer/trades` and `/explorer/trades/:id` handlers still LEFT JOIN the
legacy `bots`/`signals` tables — but there it's correct (bot_id is a stub FK and
signals ARE written on fill), so I left them. Only the weaknesses liveness logic
was reading dead tables for a false conclusion.
