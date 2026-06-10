# Shadow forward-test fix — 2026-06-10

Branch: `fix/shadow-forward-test` (off origin/main `f4bfadf`). Observability/validation infra only, no trade-decision change. Default-behaviour-safe (only active when `SHADOW_FORWARD_TEST_ENABLED=true`).

## What the audit said vs what prod data actually shows

The audit premise ("EVERY row wouldFire:0, nothing resolves") was partly stale. Live `shadow_forward_test` snapshot (3,165 candles available, table back to 2026-06-07):

- would_fire IS being set true sometimes: session-breakout 65 true rows, mean-reversion 4 true rows. So would-fire extraction is NOT structurally broken for `shouldTrade`-publishing strategies.
- The resolver DID resolve 31 rows... but **every single resolved row is `tp_hit` with pnl_R = 1.5. ZERO sl_hit. ZERO expired.** That is the real defect — a win-only (useless) signal.
- Only 5 of 8 strategies captured (the 3 missing are simply disabled on prod — not forced on, see below).

## Root cause 1 (the fatal one): path-blind, win-biased resolver

`trackForwardTestOutcomes` compared each shadow entry against ONE current spot price (`fetchPrice`). That is path-blind:
- It can't tell whether SL or TP was reached first.
- With a stop sitting far above a falling (trending) market, the current spot is below TP and nowhere near SL, so **it can only ever record tp_hit** — an SL hit is structurally impossible. Hence 31/31 tp_hit, 0 sl_hit.

### Fix
New pure function `resolveOutcomeFromCandles()` that WALKS the OHLC bars after the shadow entry, bar by bar, and records whichever of SL/TP the price PATH touched first (long: high≥TP / low≤SL; short mirrored).
- Conservative tie-break: if a single bar's range spans both SL and TP we can't know intra-bar order, so we assume **stop hit first** (sl_hit) — never inflate the win rate.
- `trackForwardTestOutcomes` rewritten to read candles from `ohlcv_candles` (XAUUSD 15min, already persisted by raw-data-persistence — no extra market fetch), pull the window once (oldest-pending → now), and slice per-row. Falls back to 24h-expiry for no-setup rows.

## Root cause 2: Phase-2 strategies publish entry levels only to the *signal* topic, never the *state* topic

The forward-test reads each strategy's `.state` blackboard topic. mean-reversion, breakout-continuation and pullback-continuation publish `entryPrice/stopLoss/takeProfit` ONLY on their signal topic; their **state** publish omitted them. So their would_fire rows landed with entry/SL/TP = NULL and could never resolve (the 4 mean-reversion would_fire rows in prod are all entry=NULL). Scalp / session-break / vol-exp already carried levels in state.

### Fix
Added `entryPrice/stopLoss/takeProfit` (from `result.signal`) to the `.state` publish in all three managers:
- `mean-reversion/mean-reversion-manager.ts`
- `breakout-continuation/breakout-continuation-manager.ts`
- `pullback-continuation/pullback-continuation-manager.ts`

These are FACT/state snapshots (observability), not the execution signal — no trade-decision change.

## Would-fire extraction: verified correct, not changed

`extractForwardTestRow` reads `breakoutState==='CONFIRMED'` (ORB) / `shouldTrade` (everyone else). Confirmed against prod `state_snapshot` jsonb — would_fire correctly tracks `shouldTrade`. Added a test asserting shouldTrade:true → wouldFire:true so a future regression that nulls it gets caught. No code change to the extractor needed.

## Missing 3 strategies — NOT force-enabled (per instruction)

Captured set is `{breakout-continuation, mean-reversion, pullback-continuation, session-breakout, volatility-expansion}`. Missing: **xau-orb, xau-scalp-overlap, xau-trend-following** — these are simply disabled on prod (their `is*Enabled()` env-gate is off). `recordForwardTestSnapshots` only snapshots `strategiesToCapture().filter(s => s.enabled)`, so they're absent by design. Left as-is; enabling them is an operator/Karri call, not part of this infra fix.

## Does it now emit a usable signal?

Yes — once deployed with the flag on:
- The resolver will now produce genuine tp_hit AND sl_hit (path-aware), so win/loss/R-multiple becomes a real validation signal instead of an all-wins artefact.
- Existing 31 historically-resolved rows were resolved by the old biased logic; they stay tp_hit unless re-resolved. New pending rows (and any future would_fire rows from MR/BC/PC now that they carry levels) resolve correctly. (Optional backfill: reset `outcome='pending'` on the old auto-resolved rows so the new walker re-judges them — not done here, that's a DB write needing operator OK.)

## Files touched

- `apps/worker/src/firm/shadow-log.ts` — new `resolveOutcomeFromCandles()` + `ResolverCandle`; rewrote `trackForwardTestOutcomes` to walk candles.
- `apps/worker/src/firm/shadow-log.test.ts` — +11 tests (1 would-fire-signal, 10 walk-forward resolver incl. SL-before-TP, single-bar-spans-both conservative sl_hit, expiry, unsorted-candles). 19 → 26 tests in this file.
- `apps/worker/src/firm/mean-reversion/mean-reversion-manager.ts` — entry/SL/TP into state publish.
- `apps/worker/src/firm/breakout-continuation/breakout-continuation-manager.ts` — same.
- `apps/worker/src/firm/pullback-continuation/pullback-continuation-manager.ts` — same.

## Verify

- `npx tsc --noEmit` in apps/worker: exit 0 (note: had to `npm install` the worktree + rebuild `@ai-agent/shared` first — its stale dist was missing `envBoolFrom`, an environment issue unrelated to this change).
- `npm test` apps/worker: **1207 pass / 0 fail**.

## Operator follow-ups (not done, gated)

1. (optional) Backfill: re-open the 31 old auto-resolved rows for re-judgement by the candle walker → DB write, needs OK.
2. Enabling orb/scalp/trend-following capture is a strategy call (Karri), not infra.
