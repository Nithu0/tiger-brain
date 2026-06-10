# WF lane replenish-0 — Fix B: per-strategy reject-path adx/atr14 surfacing (P0)

Date: 2026-06-08
Lane: replenish-0 (surfaced by adx-rootcause)
Mode: READ-ONLY diagnosis (coordination: ai-1 owns the ADX/regime P0 + these four manager files; I did NOT edit code).
Verdict: **CONFIRMED P0, root cause isolated, ready-to-apply spec below for ai-1.**

## TL;DR

On every strategy *reject* path, the four entry managers publish `adx`/`atr14`
(and `atrRatio`) as `null` even when those indicators were already fetched and
the rejection was decided *on* them. The dashboard StrategyEvaluatorPanel reads
these straight from the published state JSON, so the ADX / ATR-ratio decision
nodes render amber **"unknown"** ("ADX not in last state row") instead of
green/red. Fix B = plumb the already-fetched values through the existing
`extras` mechanism (same pattern as commit `9aac16a` used for
regimeAllowed/rsi/impulseAtr/pullbackDepth). **Pure observability, zero
behaviour change, no flag needed.**

## Live proof (pulled over 443, 2026-06-08 ~11:13Z, `data/pull/strategy_states.json`)

- **mean-reversion**: `rejectReason: "adx_too_high: 41.8 > 25 (strong trend...)"`
  but `indicators.adx: null`. The reject STRING carries ADX=41.8; the structured
  field is null. Dashboard ADX node = "unknown" despite the strategy having
  rejected *on* ADX.
- **trend-following / pullback-continuation / breakout-continuation**: all
  `adx: null`, `atr14: null` (+ `atrRatio: null` for TF/BC) on their reject rows.

## Data flow (why null propagates)

1. Manager `publishState(...)` reads `result.signal?.adx ?? null` — `result.signal`
   is `null` on every reject, so adx/atr14 are always null on rejects.
2. Endpoint `GET /firm/strategy-states` (`apps/api/src/routes/firm-memory.ts:486`)
   maps the published `state` JSON straight into `indicators: state ?? null`.
3. `StrategyEvaluatorPanel.tsx:195/218` reads `row.indicators?.[meta.adxField]`
   / `[meta.atrRatioField]`. Not a number → renders node `status: "unknown"`
   with detail "ADX not in last state row" / "atrRatio not in last state row"
   (lines 205-213, 228-236).

## Root cause per file

All four already have the `extras` pattern from `9aac16a`, but adx/atr14/atrRatio
were left out of it (the prior PR only added regimeAllowed/rsi/impulseAtr/pullback).

- **trend-following-manager.ts** — `atr14`/`adx` available from line 237
  (`readH1Indicators`). `TFStateExtras` (l.191) has pullbackDepth + regimeAllowed
  but not adx/atr14/atrRatio. `publishState` (l.521-523) only uses `result.signal`.
  `atrRatio` is computed at l.263 (after the adx reject, before vol/trend rejects).
- **pullback-continuation-manager.ts** — `atr14`/`adx` from line 292.
  `PCStateExtras` (l.241) lacks adx/atr14/atrRatio. `publishState` l.542-543 signal-only.
  `atrRatio` computed l.313.
- **mean-reversion-manager.ts** — `atr14`/`adx` resolved by l.198 guard.
  `MRStateExtras` (l.141) lacks adx/atr14. `publishState` l.421-422 signal-only.
  (MR has no atrRatio concept — n/a, matches todos table.)
- **breakout-continuation-manager.ts** — WORST: `softReject` (l.538) takes NO
  `extras` param and `publishState` (l.593) has no extras mechanism at all.
  Needs the extras plumbing added (mirror the other three) plus `extras` threaded
  through every `softReject(...)` call. `atr14`/`adx` from l.354-361; `atrRatio`
  computed l.461. Note BC's state field for current ATR is `atrCurrent` (not
  `atr14`), and the dashboard `atrRatioField` for BC reads `atrRatio`.

## Ready-to-apply spec for ai-1 (Fix B)

Pattern is identical to `9aac16a`. For TF / PC / MR:

1. Add to the `*StateExtras` interface:
   ```ts
   adx?: number | null;
   atr14?: number | null;
   atrRatio?: number | null;   // TF + PC only (MR: skip)
   ```
2. Right after the `indicator_unavailable` guard (where atr14/adx are confirmed
   non-null), set `extras.adx = adx; extras.atr14 = atr14;`. For TF/PC, also set
   `extras.atrRatio = atrRatio;` immediately after `atrRatio` is computed (TF l.263,
   PC l.313) so the vol-expansion reject and everything downstream carries it.
3. In `publishState`, change the signal-only reads to prefer-signal-then-extras:
   ```ts
   adx: result.signal?.adx ?? extras.adx ?? null,
   atr14: result.signal?.atr14 ?? extras.atr14 ?? null,
   atrRatio: result.signal?.atrRatio ?? extras.atrRatio ?? null,  // TF/PC
   ```

For BC (extra step — no extras mechanism yet):
1. Add a `BCStateExtras` interface `{ adx?, atrCurrent?, atrRatio? }`.
2. Give `softReject(board, reason, extras: BCStateExtras = {})` the param and
   pass `extras` through `publishState`.
3. Thread an `extras` object through `evaluateBreakoutContinuationEntry`: set
   `extras.adx`/`extras.atrCurrent` after the `indicator_unavailable` guard (l.363),
   `extras.atrRatio` after l.461, and pass `extras` to every `softReject(...)` call.
4. In BC `publishState`, change l.609-610 to
   `atrCurrent: result.signal?.atrCurrent ?? extras.atrCurrent ?? null`,
   `atrRatio: result.signal?.atrRatio ?? extras.atrRatio ?? null`,
   `adx: result.signal?.adx ?? extras.adx ?? null`.

Caveat to honor: surface a value ONLY after the indicator guard passes — never
before, so "indicator_unavailable" rejects still legitimately show null (the node
*should* be unknown then). For rejects that fire BEFORE indicators are fetched
(cooldown, daily-cap, session) adx/atr14 stay null — correct, matches reality.

## Branch / build guidance for whoever applies

- BUILD = new branch `fix/wf-adx-reject-surfacing`, behaviour-neutral (observability
  only — no flag required per the todos doc; it changes only the reject-path FACT
  payload, never a trade decision).
- Verify: `cd apps/worker && npx tsc --noEmit` + `npm test` (478/478 must stay green;
  add/extend a manager test asserting the reject-path state row carries adx/atr14).
- After deploy, confirm via `data/pull/strategy_states.json` that an enabled
  strategy's reject row shows numeric `indicators.adx`/`atr14` (e.g. MR's
  `adx_too_high` row should show `adx: 41.8`, not null).

## Coordination note

This task is tagged "ai-1:" and ai-1 owns these four manager files for the
ADX/regime P0. To avoid concurrent edits / merge conflicts I did read-only
diagnosis only and produced the spec above. Recommend ai-1 fold Fix B into the
same branch as the ADX/regime fix since they touch overlapping lines in these
files. Strictly speaking Fix B is observability (Claude-domain), not strategy/risk
(Karri-domain) — no proposal doc needed; safe to ship directly.
