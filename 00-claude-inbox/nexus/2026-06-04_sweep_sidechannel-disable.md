# Nexus side-channel disable — exact switch + safety verdict (2026-06-04)

READ-ONLY investigation. Karri + operator approved DISABLING (not deleting) the order source that opens trades outside the firm decision funnel. This doc gives the precise switch, railway command(s), file:line proof, and the open-position safety verdict.

---

## TL;DR (the answer)

- **The side-channel that OPENS the orders is the Strategy Execution Bridge** (`runStrategyExecution`), NOT the importer. The importer (`oanda-sync.ts`) only LABELS fills `oanda_import:<strat>:blade_match` — it never places an order.
- **It bypasses the firm consensus decision funnel by design** (its own header: *"No Prism/Blade involvement. No cross-strategy consensus."*). That is why `decisionsEmitted=0` while trades open.
- **Deployed branch = `origin/main` @ `31d8e124`** (confirmed live via `/health` build.commit=`31d8e124`). The checked-out `node-migration-nexus` branch does NOT contain the FVG strategy module, so reading only the working tree under-reports the truth — I read the deployed commit.

### Disable switches (Railway flags, operator action, service = `Worker`)

Master kill (stops the WHOLE side-channel for all 8 swim-lane strategies incl FVG + trend-following):
```
railway variables --set "STRATEGY_EXECUTION_ENABLED=false" --service Worker
```

Surgical (turn off ONLY the two bleeders, leave the profitable vol-expansion/mean-reversion lanes running):
```
railway variables --set "FVG_ENABLED=false" --service Worker
railway variables --set "TREND_FOLLOWING_ENABLED=false" --service Worker
```

- **FVG disable ≠ delete.** `FVG_ENABLED=false` only stops the strategy from being evaluated each cycle. The `FVG_*` vars and code stay intact (memory `project_fvg_karri_wip` honored — nothing deleted). Note: there are TWO distinct FVG flags — `FVG_ENABLED` (the STRATEGY, the order source, on `origin/main`) vs `FVG_FILTER_ENABLED` (a confluence filter inside `entry-thesis.ts`, NOT an order source). Disable `FVG_ENABLED`, not the filter.
- All three are **pure Railway flag flips — no code change, instant 30s revert** by setting back to `true`.

### Safety verdict: SAFE. No orphaned positions.

- Open positions right now: **0** (DB `simulated_orders status='open'` = empty; broker flat per forensics). So even in theory nothing to orphan today.
- Structurally: position-management is gated by its OWN independent flag `POSITION_MANAGEMENT_ENABLED` (default true), and runs at the TOP of every cycle (Step 0a sync, Step 0b monitor, then `manageFirmPositions`) BEFORE the entry bridge (Step 1f). It does NOT depend on `STRATEGY_EXECUTION_ENABLED`/`FVG_ENABLED`/`TREND_FOLLOWING_ENABLED`. Any trade already open keeps getting SL/TP/BE/stale-exit tending after the source is off. **No fail-unsafe.**

---

## 1. What OPENS the orders (trace)

The single broker order entrypoint is `placeOandaOrder()` → `POST /v3/accounts/{id}/orders` (`apps/worker/src/services/oanda.service.ts:319`). It has exactly 3 callers:

| Caller | file:line | Path | Decision funnel? |
|---|---|---|---|
| Firm consensus (execution-manager) | `apps/worker/src/firm/managers.ts:1108` | requires an `approval` (real firm DECISION); gated by `BROKER_MODE` | YES — emits decisions, `execution_source=firm_strategy` |
| **Strategy Execution Bridge** | `apps/worker/src/firm/strategy-execution.ts:1021` | reads PROPOSAL per strategy topic, executes independently | **NO — bypasses consensus (the side-channel)** |
| Legacy bot-cycle | `apps/worker/src/jobs/bot-cycle.ts:25` | legacy paper/legacy path | gated OFF for XAUUSD via `LEGACY_XAUUSD_EXECUTION_ENABLED=false` |

The side-channel = caller #2. Flow on `origin/main`:

1. `orchestrator.ts` Step 1j (`isFvgEnabled()` gate) → `evaluateFvgEntry()` publishes a PROPOSAL to `FVG_TOPICS.signal` (`fvg/fvg-manager.ts:393-397`).
2. `orchestrator.ts:561` Step 1f → `runStrategyExecution(board, db)`.
3. `strategy-execution.ts:289` `runStrategyExecution` iterates `getStrategyConfigs()` (8 strategies incl `xau-fvg` topic at `:204`, `xau-trend-following` at `:146`), reads PROPOSALs, calls `maybeExecuteProposal`.
4. `maybeExecuteProposal` writes `blade_decisions(strategy=cfg.strategyId, approved=true)` at `strategy-execution.ts:754`, then places the real OANDA order at `:1021`.
5. Later, `oanda-sync.ts:207` `lookupBladeAttribution` reverse-matches the fill to that `blade_decisions` row (±2s window) and stamps `oanda_import:xau-fvg:blade_match_NNNms`. **Labeling only — not an order source.**

DB ground-truth (read-only): `blade_decisions` has `xau-fvg` = 11 rows / 10 approved, first `2026-06-01T00:13Z`; `xau-trend-following` = 5 rows / 5 approved. So the bridge has been actively approving + firing these.

## 2. The exact control + file:line proof

- `STRATEGY_EXECUTION_ENABLED` — master kill for the bridge. Proof: `strategy-execution.ts:294` `if (process.env.STRATEGY_EXECUTION_ENABLED === "false") return {…blocked: "STRATEGY_EXECUTION_ENABLED=false"}`. Header doc `:19`. **Default = enabled** (only the literal `"false"` disables; absent/unset = ON). This is why the side-channel runs without any flag being set.
- `FVG_ENABLED` — gates whether FVG produces signals at all. Proof: `fvg/config.ts:24-26` `isFvgEnabled() => process.env.FVG_ENABLED === "true"`; `orchestrator.ts:526` `if (isFvgEnabled()) { … evaluateFvgEntry() }`. Default OFF (`config.ts:17` "OFF by default — set FVG_ENABLED=true"). It is firing live → `FVG_ENABLED=true` is currently set on Railway (matches DB first-fire 2026-06-01).
- `TREND_FOLLOWING_ENABLED` — gates trend-following signals. Proof: `trend-following/config.ts:16-17` `isTrendFollowingEnabled() => process.env.TREND_FOLLOWING_ENABLED === "true"`. Currently `true` (documented in handoffs; firing live).

## 3. FVG enable mechanism + safe disable

- Enable mechanism on deployed code: **`FVG_ENABLED=true`** (the strategy). `FVG_FILTER_ENABLED` / `FVG_MIN_GAP_SIZE_USD` / `FVG_LOOKBACK_CANDLES` belong to the separate confluence FILTER in `fvg-detector.ts` (`:52` `FVG_FILTER_ENABLED === "true"`) used by `entry-thesis.ts:18` — that one does NOT place orders.
- Safe OFF: `railway variables --set "FVG_ENABLED=false" --service Worker`. Disable ≠ delete — vars + code remain; reversible in 30s. Honors `project_fvg_karri_wip` (never delete).
- (The 2026-06-03 var inventory listed only `FVG_FILTER_ENABLED` under the FVG section and missed `FVG_ENABLED` + `STRATEGY_EXECUTION_ENABLED`; the inventory is incomplete on these two. The live `/health` commit + DB blade_decisions prove the strategy path is the active one.)

## 4. Open-position safety check

- `manageFirmPositions` called at `orchestrator.ts:912`, gated only by `POSITION_MANAGEMENT_ENABLED` (`position-management/manager.ts:430`, default true), independent of all entry flags.
- Cycle order: Step 0a `syncOandaPositions` (`:287`) → Step 0b `monitorPositions` (`:374`) → `manageFirmPositions` (`:912`) all run BEFORE Step 1f entries. Disabling entries does not touch tending of open trades.
- Current open positions: 0. Verdict: **no orphan risk, no fail-unsafe.**

## 5. Railway flag vs code/default

- All disable options are **Railway flag flips (operator action)** — `STRATEGY_EXECUTION_ENABLED`, `FVG_ENABLED`, `TREND_FOLLOWING_ENABLED`. No code change, no deploy, 30s revert.
- No code/default change is needed to disable. (If operator ever wanted "off by default in code" that WOULD be a code change — not required here.)

## Recommendation (for operator/Karri, not auto-applied)

Per `feedback_batched_activation_over_blind` + prinsipp 1 (no auto-disable), do not flip autonomously. Recommended order:
1. Surgical first — `FVG_ENABLED=false` + `TREND_FOLLOWING_ENABLED=false` (the two confirmed bleeders: FVG −$1944/9, TF −$1196/4). Keeps the profitable vol-expansion + mean-reversion lanes alive.
2. Only use the master `STRATEGY_EXECUTION_ENABLED=false` if the intent is to route ALL execution through the firm consensus funnel (the +$2172/2 path) and silence every swim-lane at once.
