# WF lane replenish-5 — ADX/ATR null-rendering cascade (/firm/strategy-states)

Date: 2026-06-08
Lane: replenish-5 (ai-1 lane, surfaced by overblock-vs-dormant)
Constraint note: ADX/regime indicator code is ai-1-owned — I did READ-ONLY diagnosis there; the only code surface touched by the fix is the API observability route, not indicator computation.

## Verdict: ALREADY FIXED in working tree by sibling lane (replenish-1). No new build needed.

## Root cause (confirmed)
`/firm/strategy-states` (apps/api/src/routes/firm-memory.ts:402) rendered top-level
`market.adx` / `market.atr` as null permanently → dashboard StrategyEvaluatorPanel
showed "—" (panel lines 460/464).

The endpoint read adx/atr from `xauusd.market.raw`. That topic has TWO writers per cycle:
- `runPriceFeed` → `{ price, ... }`
- `runTechnicalFacts` → `{ indicators: { adx, atr, ... } }`

A `LIMIT 1` read flaps between the two shapes, and NEITHER carries adx/atr at the TOP
level (the technical writer nests them under `state.indicators`). So the typeof-number
top-level guard always fell through to null. Values exist in the eval path (strategies
read them fine via `readH1Indicators`) but never rendered on this surface.

## The fix (in working tree, NOT yet committed/pushed — staged by replenish-1)
firm-memory.ts:457-475 — behind `STRATEGY_STATES_ADX_FROM_H1` (default OFF):
- when ON, query the single-writer topic `xauusd.market.h1-indicators`
  (`{ atr14, adx, ema20, ema50 }` at top level, published once/cycle by fact-agents — no flap)
- map `atr14 → market.atr`, `adx → market.adx`
- flag OFF preserves the old (null) read EXACTLY → deploy is behaviour-neutral
- Observability-only: no indicator computation, no trade/gate logic touched (Karri-safe)

Source topic verified canonical: apps/worker/src/firm/h1-indicators.ts (single writer,
top-level shape matches the test fixture exactly).

## Verification
- `apps/api` test `firm-memory-strategy-states.test.ts`: 2/2 PASS (flag OFF stays null; flag ON → adx 31.2, atr 5.55 from atr14).
- Test is registered in apps/api package.json test script.
- `apps/api` `tsc --noEmit`: clean (exit 0).

## Lane outcome
This lane (replenish-5) is a DUPLICATE of replenish-1 — both target the same task. I created
branch `fix/wf-replenish-5-adx-atr-h1`, found the fix already present in the working tree,
verified it (tests + tsc), and DELETED my empty branch (it had no new commits, pointed at
main HEAD bdd773e). No redundant commit produced.

## Operator action needed
1. Whoever owns the replenish-1 commit/push must land it (route + test + package.json + docs/ref/feature-flags.md are staged but uncommitted). Standard "OK kjør"-gate before push.
2. After deploy, to actually populate the dashboard ADX/ATR, set Railway API env:
   `STRATEGY_STATES_ADX_FROM_H1=true`. Operator flips (I do not touch Railway env).
   Until flipped, behaviour is unchanged (adx/atr stay "—") — safe.

## Out of scope (noted, not actioned)
- Per-strategy `indicators` payload (the pass-through state JSON the panel maps per-strategy)
  is a separate concern; depends on each strategy publishing its own indicator snapshot.
  Not part of this top-level cascade fix.
- Unrelated untracked files present from other lanes: docs/ops/2026-06-08_operator-action-brief.md,
  docs/strategy/proposals/2026-06-08_remove-reversi.md — not mine, left untouched.
