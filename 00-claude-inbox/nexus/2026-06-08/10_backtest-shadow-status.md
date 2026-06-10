# Backtest + Shadow forward-test capability status — 2026-06-08

Read/verify only. Verified against live API (`api-production-b660`, build `5fd39f9b`, worker healthy, db ok) + `main` (HEAD `4e25db6`). DB MCP tunnel was down (EHOSTUNREACH) so all live numbers come from authenticated API probes.

## TL;DR

- **What validates TODAY end-to-end:** the **event-driven shadow ledger** (`shadow_signals` via `/shadow/per-strategy`, `/shadow/comparison`, `/shadow/recent`). It is live, fresh (rows from today), resolving outcomes (`tp_hit`/`sl_hit`/`expired`) into real R-values, and already produces an actual-vs-shadow comparison across strategies. This is the only path producing a usable validation signal right now.
- **Shadow forward-test producing data:** **YES, but degenerate / not usable.** `SHADOW_FORWARD_TEST_ENABLED=true` on Railway; the dense per-cycle recorder runs every cycle. But every single row is `wouldFire:0` + `pending`, nothing ever resolves, and only 5 of 8 strategies are captured. No win/loss/R signal comes out.
- **ORB backtest:** wired and runs, but **fails today on missing M1 data**. Default timeframe is `1min`; the live firm only persists `15min`. M1 backfill has NOT run on Railway for any recent window. Confirmed by a live POST that returned the exact "No 1min candles found... Run the backfill first" error.
- **Single next action:** run the M1 backfill against the Railway DB for a recent window, then re-POST the ORB backtest. That is the smallest step that yields a real, resolvable validation number. (See caveat: forward-test would be the better long-term path but is currently broken — separate fix.)

## 1. Backtest — can POST /backtest run an ORB replay now?

Endpoint: `apps/api/src/routes/backtest.ts` → `runBacktest()` in `apps/api/src/backtest/runner.ts`.

- **Default timeframe:** `15m` is the API default in the POST handler (`resolvedTimeframe = timeframe ?? "15m"`), BUT the runner's **source candle series defaults to `1min`** (`BACKTEST_CANDLE_TIMEFRAME ?? "1min"`) and resamples up. So it always needs M1 base candles regardless of the requested output timeframe.
- **Data present?** Only **15min** is genuinely persisted. The `/candles` endpoint silently falls back to `h1` for `1min`/`5min`/`m1` (verified: all three return `timeframe:h1`). Only `15min` returns true 15min bars. No 1min series in `ohlcv_candles`.
- **Did the M1 backfill ever run on Railway?** No — not for any recent window. Live POST for 2026-05-08→2026-06-07 returned:
  > `status:"failed"` — `No 1min candles found in ohlcv_candles for XAUUSD ... Run the backfill first: node scripts/backfill-backtest-m1.mjs --from=2026-05-08 --to=2026-06-07`
- One **stored** backtest exists (`orb`, status `complete`, 2026-01-01→2026-05-13) — so a backtest succeeded once on an older window that had M1 data, but that window is stale and current windows have none.
- The runner is an honest **re-implementation** of ORB rules (port of `scripts/backtest-orb.mjs`), NOT the live `orb-manager.ts` code path. It explicitly flags this caveat. So even when it runs it validates a copy of the logic, not the real path.

**Works today end-to-end:** the backtest plumbing works (POST → runner → row flips complete/failed). The actual replay does NOT work for any current window because M1 base candles are absent. To make it work: `node scripts/backfill-backtest-m1.mjs --from=... --to=...` against the **prod** DB, then re-POST. The backfill script is additive/idempotent (`ON CONFLICT DO NOTHING`), reads OANDA XAU_USD, writes `timeframe=1min`. It needs `DATABASE_URL` pointed at prod + `OANDA_API_TOKEN` — note the repo `.env` `DATABASE_URL` is intentionally the local sandbox (per `scripts/mcp/nexus-pg.sh` safety note), so this is an operator-run step with a prod connection string, not a one-liner I can fire blindly.

## 2. Shadow forward-test — is it on and producing data?

- **Flag:** `SHADOW_FORWARD_TEST_ENABLED=true` on Railway. `/shadow/forward-test?days=30` returns `enabled:true` with real rows.
- **recordForwardTestSnapshots running each cycle?** YES. Wired in `orchestrator.ts:577` (per-cycle), with `trackForwardTestOutcomes` at `:612`. 371 cycles captured per strategy in last 30d (1855 rows total).
- **But the data is degenerate:**
  - **`wouldFire:0` for every strategy, every cycle** (0 of 1855). The recorder reads each strategy's latest `.state` blackboard row; the `would_fire` heuristic (`extractForwardTestRow`, `shadow-log.ts:271`) keys on `shouldTrade` (or `breakoutState==='CONFIRMED'` for ORB). Live `.state` rows never carry that → always non-firing.
  - **Every row stuck `pending`** (0 resolved, 0 expired). Non-firing rows have no entry/SL/TP triple, so `trackForwardTestOutcomes` can only expire them after 24h — yet `expired:0` too, so even the expiry path isn't flipping them. No win/loss/R ever emitges.
  - **Only 5 of 8 strategies captured** (breakout-continuation, mean-reversion, pullback-continuation, session-breakout, volatility-expansion). ORB, scalp-overlap, trend-following are not `enabled` on prod → not in the dense table. So the "8 strategies, real logic" promise is currently 5 strategies, and all silent.

**Producing usable data: NO.** Producing rows: yes. As a "validate every trade" signal it currently yields nothing.

## 3. Which validation path is closest to usable?

Re-frame: the question pits ORB-backtest (1 strategy, copy of logic) vs shadow forward-test (8 strategies, real logic, per-cycle). But the live data says the real winner is a third thing:

- **ORB backtest:** blocked on M1 data; 1 fix away (run backfill) but validates a *copy* of one strategy.
- **Shadow forward-test (`shadow_forward_test`):** enabled + running but degenerate (all pending/wouldFire:0, 5/8 strategies). Needs a code fix to the would_fire extraction + outcome resolver before it produces anything. Further from usable than it looks.
- **Event-driven shadow ledger (`shadow_signals`, `/shadow/per-strategy`):** ALREADY usable. Verified live: fresh rows today (2026-06-08), resolving outcomes with real R (`/shadow/recent` shows `sl_hit pnlR=-1`, `tp_hit pnlR=1.5`, `expired pnlR=0`), and `/shadow/per-strategy` returns a working actual-vs-shadow comparison (e.g. mean-reversion shadow 38% WR vs actual 53%, ORB shadow matches actual −1R, FVG actual 45% WR over 11 trades). This was the endpoint fixed in `7266953` (the label bug — see §4). It only covers strategies that *publish proposals* (event-driven, sparser than per-cycle), but it is real, resolving, and live.

## 4. Bugs

- **Shadow label bug — CONFIRMED FIXED on main** (commit `7266953`, cherry-pick of `e1edfac`, 2026-06-04). `/shadow/per-strategy` + `/shadow/comparison` filtered `outcome IN ('win','loss')` but the writer stores `tp_hit`/`sl_hit`/`expired` → those endpoints returned all-zeros forever. Now filters the stored values. Verified live: per-strategy returns non-zero wins/losses/R. This is the bug referenced in the task — fixed.
- **NEW (forward-test): wouldFire always 0 + rows never resolve.** `shadow_forward_test` records but produces no signal (see §2). Not a regression of the labeled bug above — a distinct, currently-unfixed dysfunction in `recordForwardTestSnapshots`/`extractForwardTestRow`/`trackForwardTestOutcomes`. The would_fire heuristic reads `state.shouldTrade`/`breakoutState` from blackboard `.state` rows that apparently don't carry those fields in live cycles, and pending rows never expire. Worth a focused fix if the dense forward-test is meant to be the "validate every cycle" path — but that's a code change, not just a flag flip.

## Single next action (recommended)

**Operator-run:** `node scripts/backfill-backtest-m1.mjs --from=2026-05-08 --to=2026-06-07` with a **prod** `DATABASE_URL` + `OANDA_API_TOKEN`, then re-POST `/backtest` for that window. This is the fastest path to ONE real, resolvable validation number today (ORB equity curve on real M1 bars).

In parallel (Claude-side, learning-infra, no Karri gate): fix the `shadow_forward_test` would_fire/resolve dysfunction so the dense per-cycle forward-test — the genuinely better "validate all live logic" signal — actually emits wins/losses/R. Until then, lean on `shadow_signals` (`/shadow/per-strategy`) as the working feedback signal for the learning loop.

## Source pointers (absolute)

- `/home/nithu/code/ai-assistent/apps/api/src/routes/backtest.ts` — POST/GET backtest
- `/home/nithu/code/ai-assistent/apps/api/src/backtest/runner.ts` — replay engine, M1 source default
- `/home/nithu/code/ai-assistent/apps/api/src/routes/shadow.ts` — `/shadow/*` endpoints
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/shadow-log.ts` — `recordForwardTestSnapshots`, `extractForwardTestRow`, `trackForwardTestOutcomes`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/orchestrator.ts:577,612` — per-cycle wiring
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/strategy-snapshot.ts:38` — `strategiesToCapture()` (8 descriptors)
- `/home/nithu/code/ai-assistent/scripts/backfill-backtest-m1.mjs` — M1 backfill
- Label-bug fix: commit `7266953`
