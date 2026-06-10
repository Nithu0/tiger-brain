# Verify ai-2's 5 new commits — node-migration-nexus

Date: 2026-06-04 | Verifier: code-1 (sole worker-test runner) | Branch: node-migration-nexus
Commits checked: 37e3da8, 7ec793c, 5341fb3, 8ddb445 (3f35f2a skipped — mine)

## Verdict

All real, all green, all behaviour-neutral (default-OFF as claimed). **No red flag.**
ORB backtest: **PARTIAL** — code path is now correct and unblocked, but the default
read target (`timeframe='1min'`) is NOT yet populated; requires the new backfill
script to run against prod (operator-gated). See section 3.

## 1. Test counts (exact)

| Suite | Result |
|---|---|
| apps/worker `tsc --noEmit` | PASS (exit 0) |
| apps/worker `npm test` | **1157 / 1157 pass**, 0 fail, 0 skipped, dur ~205s — matches ai-2's claim |
| apps/api `tsc --noEmit` | PASS (exit 0)* |
| apps/dashboard `tsc --noEmit` | PASS (exit 0) |

\* The npm-wrapped api tsc twice got SIGNAL 144 (sandbox kill, empty log — not a
type error). Running `node node_modules/typescript/bin/tsc --noEmit` from the
hoisted root TS = exit 0, zero diagnostics. API is genuinely clean.

## 2. Env-flag defaults — all behaviour-neutral

Every new env read across the commits:

- `BACKTEST_CANDLE_TABLE` → `ohlcv_candles`, `BACKTEST_CANDLE_SYMBOL` → `XAUUSD`,
  `BACKTEST_CANDLE_TIMEFRAME` → `1min`. Identifier-validated (`SAFE_IDENT` regex)
  before SQL interpolation. Backtest-only (apps/api), no live-loop touch.
- `CALIBRATION_MODE` → default `RECOMMEND_ONLY` (= the old hardcoded literal),
  unrecognised value falls back to RECOMMEND_ONLY (fail-safe). `SAFE_AUTO_APPLY`
  is the gated flip. orchestrator.ts:~717 now calls `calibrationMode()` instead
  of the literal `"RECOMMEND_ONLY"` — behaviour identical at default.
- `AGENT_LESSONS_ENABLED` / `LESSON_DERIVATION_ENABLED` / `LESSON_INJECTION_ENABLED`
  — read ONLY for status display in GET /calibration/status (`=== "true"`,
  default OFF). Not wired into any trade decision in these commits.
- `SHADOW_FORWARD_TEST_ENABLED` → default `"false"`. Both write paths
  (`recordForwardTestSnapshots` shadow-log.ts:346, `trackForwardTestOutcomes`:416)
  early-return when off → zero queries, zero overhead, table stays empty
  (rollback-safe). Loop calls are `.catch`-wrapped → never block the cycle
  (operator-prinsipp 2 respected).

No default changes live trade behaviour.

## 3. ORB backtest end-to-end (37e3da8) — PARTIAL

What's fixed: runner.ts previously read `backtest_xauusd_m1` (nonexistent →
threw on every call). Now reads `ohlcv_candles` (env-configurable), columns
remapped `mid_o/h/l/c` → `open/high/low/close`. Empty-data error now prints the
exact backfill command instead of a bare 500. Schema PK `(symbol, timeframe,
candle_time)` matches the backfill's `ON CONFLICT` key exactly.

Why only PARTIAL:
- `ohlcv_candles` EXISTS (schema.ts:826) and IS populated by the live firm —
  BUT the live firm hardcodes `tf = "15min"` (raw-data-persistence.ts:471). It
  writes 15min bars only.
- The runner DEFAULTS to reading `timeframe='1min'`. There is no 1min data in
  the table yet → the ORB replay will hit the empty-data branch and throw the
  (now-helpful) "run the backfill first" error.
- The fix is exactly the new `scripts/backfill-backtest-m1.mjs`: paginates OANDA
  M1, filters `complete`, mid prices, batched idempotent upsert with `--dry-run`.
  Correctly targets `symbol=XAUUSD, timeframe=1min`. Mirrors what the runner reads.
- Running the backfill needs OANDA_API_TOKEN + DATABASE_URL write to prod →
  operator-gated (DB write + external creds). Not runnable from this sandbox.
- Could NOT confirm row counts directly: prod DB unreachable from sandbox
  (EHOSTUNREACH on nexus-pg MCP). Conclusion is from code, not a live SELECT.

Two ways to make ORB replay actually run:
1. Operator runs `node scripts/backfill-backtest-m1.mjs --from=… --to=…` once
   (populates 1min), then the replay works as-is. RECOMMENDED.
2. Set `BACKTEST_CANDLE_TIMEFRAME=15min` to replay against the data already
   present — works immediately but coarser (15min base, not true M1 resample).

So: "we can finally backtest" is structurally TRUE (no more nonexistent-table
throw), but operationally still one backfill run away from producing results at
the default timeframe.

## 4. Learning primers (7ec793c) — confirmed

- `CALIBRATION_MODE` is now env-driven via `calibrationMode()` in calibration.ts;
  no-op at the RECOMMEND_ONLY default.
- The previously-hardcoded `"RECOMMEND_ONLY"` literal at orchestrator.ts (the
  `cycleCount % 20 === 0` calibration call, now ~line 717) is REPLACED by
  `calibrationMode()`. No stray hardcoded literal remains on that call path.

## 5. Governance (8ddb445) — confirmed

CLAUDE.md prinsipp 6 rescinded (30-day wait dropped; continuous learning;
trade-altering switches still Karri-gated). Two Karri proposals added
(activate-learning-loop, hard-position-size-circuit-breaker). Docs-only.
