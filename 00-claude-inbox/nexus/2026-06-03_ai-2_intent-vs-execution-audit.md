# Intent-vs-Execution Divergence Audit — XAUUSD sizing/SL

**Date:** 2026-06-03
**Auditor:** ai-2 (forensic, skeptical)
**Question:** Can executed lot-size / SL still diverge from what the platform intended? Is the ~April 21-22 "100x blowup" genuinely fixed?

---

## TL;DR VERDICT

**The original blowup was NOT a "communication error" (intent-vs-execution transform bug). It was a SIZING-FORMULA AMPLIFICATION bug — the platform *intended* ~95-106 units. The formula did exactly what it was told.** That root cause is **FIXED** for the parameters that caused it (commit `8816365` + env-gating `2b1986b`).

The narrower question "can persisted size/SL diverge from what OANDA actually executed" is **PARTIALLY fixed**:
- **OANDA (live) path: GENUINELY FIXED.** Persisted `size`/`stop_loss`/`take_profit` are overwritten with broker-confirmed values (`actualUnits`, `oandaResult.stopLossPrice`). strategy-execution.ts:1057-1079.
- **Paper-only path: residual divergence risk.** `tryOpenPosition` independently *recomputes* size and SL from `(balance, riskPct, stopLossPoints)` and does NOT apply the sizing modifiers / chain-multiplier / news-boost that the live path applies. paper-execution.service.ts:263-270. Only matters when those modifiers are active (all default OFF) or in paper mode.
- **NO test anywhere asserts persisted size == broker-executed units, or that the risk-math is correct.** 1150/1150 green, but the divergence path is unguarded by tests. This is the loud gap.

---

## 1. What actually happened on 2026-04-21/22 (root cause of the 95-106 units)

Not a comms bug. A deliberate config change shipped at **Apr 21 01:08** in `7479b20`
("regime-dependent SL/TP + real OANDA balance + 5% risk in RANGING") stacked three
amplifiers into the sizing formula:

```
size = (balance * riskPct/100) / stopLossPoints
```

- RANGING SL tightened to **$4** (`stopLossPoints = 4`)
- risk raised to **5%**
- balance switched from hardcoded $10k to **real OANDA balance** (~$8.5k)

Result: `8500 * 0.05 / 4 ≈ 106 units`. That is exactly the operator's "~95-106 units,
≈100x normal 1.0". The 1.0-unit "normal" came from the *previous* regime (SL=$12-15,
1% risk, $10k → `10000*0.01/15 ≈ 6.6`, or with min-clamp/tighter risk ≈1). So the
"100x" is `(0.05/0.01) * (15/4) ≈ 18x` from params plus min-unit clamp effects — i.e.
the formula amplified, the broker faithfully executed ~106 units, and the loss was real.

**This is consistent with the operator's statement that the losses are real, but NOT with
"a different value got executed than decided."** The decided value *was* ~106 units. The
platform's intent was wrong, not its execution.

### Remediation commits (all landed Apr 21-23)
- `8816365` (Apr 21 09:26) — scalp/RANGING/VOLATILE risk **5% → 2.5%**. managers.ts:801.
- `50d102a` (Apr 21 01:18) — cap RANGING/VOLATILE to max 2 simultaneous trades.
- `2b1986b` (Apr 21 09:52) — **env-gate all regime/risk/balance overrides** (rollback w/o code).
- `08c04d3` / `3f91bf3` (Apr 21-22) — unrealized + realized PnL must multiply by size (was *1 for gold) — fixed the *reporting* of the loss, separate bug.
- `82c67c1` (Apr 23 15:55) — **delete DB trade if OANDA order fails** — no ghost positions (legacy managers.ts path).
- `24fd9cc` (Apr 16) — round XAU units to integer (predates blowup; unrelated to the 100x).
- `2825a72` (May 8) — XAU integer-only at the *boundary* (Math.floor in strategy-execution + oanda.service). This is the current firm-path rounding.

---

## 2. Current decision → persistence path (firm / TIER 3 — the live path)

File: `apps/worker/src/firm/strategy-execution.ts` → `maybeExecuteProposal()`

1. **SL distance computed** from absolute prices: `stopLossPoints = abs(entryPrice - stopLoss)` (line 490).
2. **Size computed** (line 900-901):
   `dollarRisk = balance * riskPct/100 * chainLotEffective * sizingModifierMult * newsBoostMult`
   `sizeRaw = dollarRisk / stopLossPoints`
3. **Floored to integer** at the boundary: `size = Math.floor(Math.abs(sizeRaw))` (line 914); skips trade if 0.
4. **OANDA order placed FIRST** with `size`, `stopLoss`, `takeProfitRaw` (line 945) — broker is source of truth.
5. **Broker truth captured** (lines 956-963): `actualEntryPrice`, `actualStopLoss = oandaResult.stopLossPrice ?? stopLoss`, `actualUnits = abs(oandaResult.units)`.
6. **DB INSERT** via `tryOpenPosition` (line 1007) — note it recomputes its own size internally.
7. **DB UPDATE overwrites with broker truth** (lines 1057-1077): `size = actualUnits`, `stop_loss = actualStopLoss`, `take_profit = actualTakeProfit`, `entry_price = actualEntryPrice`.

**=> For live OANDA trades, the persisted row matches the broker, not the intent.** Divergence
between intent and execution is *expected* (slippage/clamp) and is *logged structurally*
(line 969-971: `requestedUnits=X brokerUnits=Y intended=$Z`). This is correct and auditable.

### oanda.service.ts placeOandaOrder (lines 279-308)
- Floors fractional metal units (defensive; caller already floors).
- Clamps `< minUnits` up to `minUnits` (risk slightly higher than intended — logged).
- These transforms are bounded and logged. No hidden 100x multiplier, no unit (oz/lot) mismatch found. XAU is traded in whole troy ounces = units; no lot conversion layer exists.

---

## 3. Residual divergence risks (why this is PARTIALLY, not fully, closed)

### R1 — Paper path recomputes size & SL independently (paper-execution.service.ts:263-270)
`tryOpenPosition` computes `size = (balance * riskPct/100) / stopLossPoints` and derives
SL/TP from `fillPrice ± stopLossPoints`. This is a SECOND, independent computation that:
- Does NOT apply `chainLotEffective`, `sizingModifierMult`, or `newsBoostMult` (the live path does, line 900).
- For **live trades** this divergence is erased by the UPDATE at line 1066 (overwrites with `actualUnits`).
- For **paper-only trades** (`STRATEGY_EXEC_PAPER_ONLY=true`) the paper UPDATE block (lines 1080-1099) does **NOT overwrite size** — so the persisted size is whatever `tryOpenPosition` computed, which silently ignores the modifiers. **If any sizing modifier / chain / news-boost is ever enabled in paper mode, persisted size ≠ intended size.** All those flags default OFF, so today it's latent, not live.

### R2 — Ghost-position window in the firm path (OANDA-first, DB-second)
Live path places the OANDA order at line 945, then writes DB at 1007. If the worker crashes
between the fill and the DB write, there is a **real OANDA position with no Nexus row**. The
legacy `82c67c1` fix ("delete DB trade if OANDA fails") solved the *opposite* direction
(DB row, no OANDA fill) and lives in managers.ts — it does not cover this firm-path window.
Mitigation exists out-of-band: `oanda-sync.ts` backfills closed trades, and drift-monitor
reconciles DB vs OANDA (`7dbb187`, report-only). So it self-heals on reconciliation but is
**not transactionally guaranteed**.

### R3 — No test guards size/SL fidelity
1150/1150 tests pass, but:
- `strategy-execution.test.ts` only asserts metadata stamping (strategy_id, cycle_id, thesis keys), daily-loss/cap blocking, and dedup. It does **not** assert the persisted `size` equals `actualUnits`, nor that the UPDATE overwrites size with broker truth.
- `paper-execution.test.ts` asserts strategy_id stamping and cap behavior — **never asserts the computed `size` value** against the risk formula.
- There is **no regression test reproducing the 5%×$4-SL amplification** to prevent a future config change from re-creating a 100x position.

---

## 4. What still needs verification against LIVE data (cannot prove from code alone)

1. **Query `simulated_orders` for the live OANDA path:** confirm `size` on recent firm_strategy
   rows equals `initialUnits` reported by OANDA for the same `oanda_trade_id` (drift-monitor
   covers this but verify a sample manually via nexus-pg).
2. **Confirm current RANGING/scalp risk params** in Railway env (RISK_PCT defaults are 0.5% in
   strategy-execution.ts:122-172, but the legacy managers.ts path's `finalRiskPct=2.5` for scalp
   may still apply if that path is live). Check which execution path is actually firing.
3. **Confirm SL never re-derives from a stale `stopLossPoints`** when a position is modified post-entry
   (position-management/manager.ts — not audited here; out of scope but adjacent).
4. **Reproduce the worst-case size today:** `balance * maxRiskPct / minRealisticSL`. With 0.5% and a
   tight $4 SL on a $50k account: `50000*0.005/4 ≈ 62 units`. Still large. The amplification vector
   (tight SL × % risk × real balance) is *structurally intact* — only the risk% was lowered. A future
   tight-SL strategy could re-trigger large sizing without any "bug."

---

## RECOMMENDED FOLLOW-UPS (for Karri — strategy/risk owner, do not self-implement)

- Add a **hard max-units / max-notional cap** in `placeOandaOrder` (e.g. reject if units > N × baseline) as a circuit breaker independent of the risk formula. This is the missing guard that would have caught the 106-unit order regardless of params.
- Add a **regression test** that drives `maybeExecuteProposal` with a $4 SL + high balance and asserts size stays under a sane cap.
- Add a test asserting **persisted size == actualUnits** on the live path (pin the UPDATE-overwrites-broker-truth contract).
- Decide whether the paper-only path should mirror the live modifiers (R1) for shadow-mode fidelity.

---

### Evidence index (file:line)
- Sizing formula (live): strategy-execution.ts:900-914
- Broker-truth capture: strategy-execution.ts:956-963
- DB overwrite with broker truth (live): strategy-execution.ts:1057-1079
- Paper UPDATE (no size overwrite): strategy-execution.ts:1080-1099
- Independent recompute: paper-execution.service.ts:263-270, 291-311
- OANDA unit floor/clamp: oanda.service.ts:279-308
- Root-cause config: commit `7479b20` (Apr 21 01:08)
- Risk de-amplification: commit `8816365`, `2b1986b`
- Ghost-position fix (legacy path only): commit `82c67c1`
