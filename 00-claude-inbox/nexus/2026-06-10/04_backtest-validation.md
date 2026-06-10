# Backtest validation — the single concrete path to a usable signal

Date: 2026-06-10
Scope: READ/ANALYSIS ONLY. No code changed, no DB writes, no Railway mutations.
Author: Claude (agent 4 — backtest-validation)

## TL;DR

The `/backtest` API runner is blocked by exactly one thing: **`ohlcv_candles` holds only `15min` bars; the runner reads `1min` (M1) by default and there are zero M1 rows.** Last real failed run (2026-06-08) confirms it verbatim.

Three usable paths exist. Recommendation: **run the M1 backfill once on Railway (5 min, operator-gated), then re-POST `/backtest`** — that gives the faithful, intended ORB validation number this week. A 15min-coarse run is available *today* with no backfill as a cross-check, and the shadow_signals ledger already gives a real live-R number right now (+0.28R over 437 graded signals).

---

## 1. Blocker confirmed (live evidence)

`ohlcv_candles` (symbol=XAUUSD), as of now:

| timeframe | bars | first | last |
|---|---|---|---|
| 15min | 3165 | 2026-04-22 05:00Z | 2026-06-10 12:15Z |

No `1min` rows at all. The worker only ever writes **closed 15-min bars** (`apps/worker/src/firm/raw-data-persistence.ts:15` + `:533`), so M1 will never appear from the live loop — it must be pulled from OANDA.

The API runner reads its SOURCE series from env `BACKTEST_CANDLE_TIMEFRAME` (default `1min`), independent of the request's `timeframe` field (which only controls *resampling*). So a `timeframe=15m` POST still tries to load 1min and throws. Proof — most recent `backtests` row:

```
id=9ee2bdcf… strategy=orb timeframe=15m status=failed  (2026-06-08 10:33Z)
warning: "No 1min candles found in ohlcv_candles for XAUUSD between
          2026-05-08 and 2026-06-07. Run the backfill first:
          node scripts/backfill-backtest-m1.mjs --from=2026-05-08 --to=2026-06-07"
```

(The only `complete` backtest row, 2026-05-21, predates the repoint to `ohlcv_candles` — not reproducible against the current source.)

## 2. Does the M1 backfill script work? What does the operator run, and where?

`scripts/backfill-backtest-m1.mjs` — reviewed end-to-end. It is correct and safe:
- Pulls `XAU_USD` M1 mid candles from OANDA (paginated, 5000/page, `complete`-only).
- UPSERTs into `ohlcv_candles` as `symbol=XAUUSD, timeframe=1min` with `ON CONFLICT DO NOTHING` — **idempotent, additive, zero trading-loop interaction**, re-runnable on overlapping windows.
- `--dry-run` fetches + reports counts without writing.

**Env it needs:** `OANDA_API_TOKEN`, `DATABASE_URL` (and optional `OANDA_API_URL`, defaults to the practice host). All three already live in the Railway worker/API service env — so **no secrets need to be added** to run it there.

**Can it be triggered via an endpoint instead of a Railway shell?**
No. I checked: `apps/api/src/routes/diagnostic-backfill.ts` exists but backfills `original_risk_points` on reconcile rows — unrelated to candles. There is **no M1-candle backfill endpoint**. So the script must run in a shell with DB + OANDA access. Two ways:

- **(A) Railway shell** on the worker or api service:
  ```
  node scripts/backfill-backtest-m1.mjs --from=2026-03-10 --to=2026-06-09
  ```
  (~90 days ≈ a few minutes; OANDA caps 5000 bars/page, script paginates.)
  Optionally `--dry-run` first to sanity-check the bar count.

- **(B) Operator's own laptop**, if `.env` at repo root has prod `DATABASE_URL` + `OANDA_API_TOKEN` (Claude is deny-ruled from reading `.env`, so cannot confirm locally). Same command from repo root.

After the backfill, re-POST `/backtest` (timeframe `15m` or `5m`) and the runner resamples the new M1 base into a real ORB equity curve.

## 3. Alternative: run on existing 15min data TODAY (coarse-but-real)

Yes — works with **no backfill**. The source timeframe is env-overridable and validated by a safe-identifier regex (`runner.ts:47-49`). Set on the API service:

```
BACKTEST_CANDLE_TIMEFRAME=15min
```

Then POST `/backtest` with `timeframe=15m`. The runner loads the 3165 existing 15min bars and (resample is a no-op at 15m) runs the same ORB session logic. Real broker candles, real ORB rules — coarser SL/TP fill granularity than M1 (intrabar wicks between 15min closes are invisible, so TP/SL-hit timing is approximate). Good enough for a directional sanity number; not the final word.

Caveat: this is an env flip on the API service (operator-gated, rollback = unset the var). It does not alter any trade decision — pure read path — so it is low-risk, but still a Railway mutation only the operator can make.

## 4. Shadow-forward-test path (real R, available right now)

`shadow_signals` is healthy and needs nothing run:
- 471 signals, **437 with realized R**, first 2026-04-28, last 2026-06-10 12:30Z (live).
- **avg pnl_simulated_r = +0.28R.**

This is a real, already-graded forward-test number — no backfill, no env flip, no deploy. It is the most defensible validation signal we have *today*, though it measures the live-gated signal stream, not a clean historical ORB replay.

---

## Recommendation (single next action)

**Operator runs the M1 backfill on a Railway shell, then re-POSTs `/backtest`.** It is the only path to the faithful, intended ORB validation number, it is idempotent/additive/safe, and it needs no new secrets (Railway env already has them). One-time cost ~5 min.

While that is pending, two zero-work cross-checks already exist: the live shadow ledger (+0.28R / 437 graded) and an optional `BACKTEST_CANDLE_TIMEFRAME=15min` coarse replay.

### Exact next action

1. **WHO:** operator (Railway shell access — Claude cannot open a Railway shell or read prod `.env`).
2. **WHERE:** Railway → worker (or api) service → Shell.
3. **WHAT (type exactly):**
   ```
   node scripts/backfill-backtest-m1.mjs --from=2026-03-10 --to=2026-06-09
   ```
   (optional dry-run first: append `--dry-run`)
4. **EXPECTED OUTPUT:** `[backfill-m1] done — <N> new rows inserted (...)` with N in the tens of thousands (≈ trading-minutes over the window). `ohlcv_candles` then has a `1min` timeframe row-set.
5. **THEN:** POST `/backtest` (`{"strategyName":"orb","timeframe":"15m","dateFrom":"2026-03-10","dateTo":"2026-06-09"}`) → row flips `complete`, `results.summary` carries trades / winRate / totalR / avgR / maxDrawdown.

No code change, no proposal needed — backfill + observability are firmly on the Claude-owns side of the learning-infra boundary; only the Railway-shell execution requires the operator.
