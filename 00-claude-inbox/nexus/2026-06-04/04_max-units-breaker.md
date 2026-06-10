# Max-units / hard-cap verification + circuit-breaker proposal review

**Date:** 2026-06-04
**Auditor:** Claude (read/analysis only — no code edits; any fix is a Karri proposal)
**Question (from ai-2 audit):** Is the absence of a hard max-position-size / max-notional / max-account-risk cap the real account-killer? Verify the gap precisely; assess the drafted circuit-breaker proposal.
**Verified against:** `00-claude-inbox/nexus/2026-06-03_ai-2_intent-vs-execution-audit.md` and proposal `docs/strategy/proposals/2026-06-03_hard-position-size-circuit-breaker.md`.

---

## HEADLINE VERDICT

**Does a working hard cap exist today that would stop a 106-unit / 12%-risk trade? NO.**

- There is an exposure-cap module (`firm/exposure/rules.ts` + `portfolio-check.ts`) with real caps, but it is **only wired into the LEGACY `managers.ts` path**, and it caps **risk-%, never units/notional**.
- The **LIVE path is `strategy-execution.ts::runStrategyExecution`** (orchestrator Step 1f, default ON via `STRATEGY_EXECUTION_ENABLED`). This path computes size directly from `cfg.riskPercent` and **never calls `performPortfolioCheck`, never reads `EXPOSURE_RULES`**. No aggregate-exposure cap, no per-trade $ ceiling, no max-units/max-notional clamp.
- `placeOandaOrder` (oanda.service.ts:278-306) has only a **lower-bound** clamp (`finalUnits < minUnits → minUnits`). There is **no upper bound** anywhere in the order path.

So ai-2's central claim is correct and, if anything, understated: not only is there no max-units cap, the one aggregate-exposure gate that DOES exist is not even on the live execution path.

---

## 1. What caps exist, where, and what they actually bound

| Cap | File | Bounds | On LIVE path? | Stops a 106-unit trade? |
|---|---|---|---|---|
| `maxRiskPerTradePct` (default 0.75, env `EXPOSURE_MAX_RISK_PER_TRADE_PCT`) | exposure/rules.ts:40 | risk-% per trade | NO (managers.ts only) | No — caps %, not units; tight SL still amplifies units within the % |
| `maxTotalExposurePct` (3.0) | rules.ts:42 | aggregate risk-% across open | NO (managers.ts only) | No (and not on live path) |
| `maxDirectionExposurePct` (2.0) | rules.ts:44 | per-direction risk-% | NO (managers.ts only) | No |
| `maxOpenTrades` (3) | rules.ts:46 | open-position COUNT, aggregate | NO (managers.ts only) | No — count, not size |
| `maxOpenPositions` (per-strategy, default 1) | strategy-execution.ts:79,482 | open-position COUNT, per strategy | YES | No — count, not size; and per-strategy so N strategies can each open 1 |
| `dailyLossLimitUsd` (env, live=$500) | strategy-execution.ts:~455 | realized $ loss/day | YES | No — fires AFTER losses realize; a single 106-unit trade can blow through it in one fill |
| `minUnits` clamp | oanda.service.ts:298 | lower bound only | YES | No — wrong direction |

**The decisive fact:** the live sizing line is
`strategy-execution.ts:900` → `dollarRisk = virtualBalance * (cfg.riskPercent/100) * chainLotEffective * sizingModifierMult * newsBoostMult`
`:901` → `sizeRaw = dollarRisk / stopLossPoints`
`:914` → `size = Math.floor(Math.abs(sizeRaw))`
…then straight to `placeOandaOrder`. Nothing between line 914 and the broker imposes a units or notional ceiling. The 04-21 amplification vector (tight SL × risk% × real balance) is **structurally intact** on the live path. ai-2's worked example holds: 0.5% × $4 SL × $50k ≈ 62 units with zero "bug".

---

## 2. The live config ai-2 cited — confirmed + corrected nuance

- `SCALP_RISK_PCT=2.5` — **this env var only feeds the LEGACY managers.ts path** (managers.ts:825, "SCALP_RISK_PCT overrides Forge risk in scalp regimes"). The live strategy-execution path uses **per-strategy `<STRAT>_RISK_PCT`** vars instead (`SCALP_OVERLAP_RISK_PCT`, `ORB_RISK_PCT`, …), each **defaulting to 0.5%** (bounded 0.1–5.0). So on the live path, scalp risk is 0.5% unless `SCALP_OVERLAP_RISK_PCT` is set. The 2.5% figure is a legacy-path value; worth Karri confirming which path is actually firing trades, but code + orchestrator say it's strategy-execution (firm path).
- `EXPOSURE_MAX_RISK_PER_TRADE_PCT=1.5` — confirmed as the env override for `rules.ts:40` (default 0.75). **But this only matters on the legacy path** — the live path never reads it. So setting it has no effect on live trades today.
- `RISK_LEVEL_HARD_GATE_ENABLED=false` — confirmed default false (foundation-gate.ts:239, new-gates.ts:112).
  - **What it does when true:** in `gates/new-gates.ts`, gate `risk_level` hard-rejects a trade when the risk-analyst `riskLevel ∈ {elevated, high, extreme}`. It is a **regime/risk-state entry block, NOT a size cap.** It would prevent *entering* during a flagged-risk window; it would do nothing to clamp the size of a trade that is allowed through.
  - **Why it's false:** by design — `new-gates.ts` is "log first, gate second"; all new gates ship OFF (soft-log to `gate_decisions`) until baseline data justifies activation. This is the standard Trinn-A scaffolding pattern, not a regression.
  - **Important:** ai-2's proposal item 2 ("re-enable RISK_LEVEL_HARD_GATE") would help reduce bad-context entries but is **orthogonal to the size-cap problem.** It is not the missing breaker. Worth flagging to Karri so it isn't treated as a substitute.

### Live risk posture (from `data/pull/`, 2026-06-04 ~16:19Z)
- Balance ~€89,796 (demo), 0 open trades, 0 notional, leverage 0.
- Daily loss today -€55.35 vs €500 limit (11% of limit). `dailyTradeCapEnabled=false`, `slCooldownEnabled=false`.
- Regime: portfolio `HIGH_VOLATILITY`, risk `normal`. (Note: HIGH_VOLATILITY regime-multiplier 0.60 only applies on the managers/portfolio-check path — again, not live.)
- All 6 strategies currently `shouldTrade=false` (no setup), so nothing is at risk this minute — but that's market conditions, not a cap.

---

## 3. Would ANYTHING have stopped today's 106-unit / 12%-risk trade? NO.

Walk it through on the LIVE path with the 04-21 inputs (tight $4 SL, high risk%, real balance):
1. `runStrategyExecution` → per-strategy `maxOpenPositions` (count) — passes if <1 open.
2. daily-loss guard — passes (loss not yet realized; this fires post-hoc).
3. size = balance × risk% / SL — **amplifies freely**, no clamp.
4. `placeOandaOrder` — floors fractional, clamps UP to min; **no max.** Sends to OANDA.

There is no flag you can flip today that adds an upper bound on units/notional. The closest existing lever — `EXPOSURE_MAX_RISK_PER_TRADE_PCT` / `EXPOSURE_MAX_TOTAL_PCT` — **does not execute on the live path**, so flipping it is inert for live trades. The only real mitigations live today are indirect: keep per-strategy `<STRAT>_RISK_PCT` low and `maxOpenPositions=1`. Neither is a hard catastrophic-outlier cap.

**Exact flags involved (for the record):**
- Missing entirely: `MAX_UNITS_PER_TRADE`, `MAX_NOTIONAL_PCT_OF_BALANCE` (proposed, not implemented).
- Exists but OFF and off-path: `EXPOSURE_MAX_RISK_PER_TRADE_PCT`, `EXPOSURE_MAX_TOTAL_PCT`, `EXPOSURE_MAX_DIRECTIONAL_PCT`, `EXPOSURE_MAX_OPEN_TRADES` (managers.ts path only).
- Exists, OFF, and is an entry block not a size cap: `RISK_LEVEL_HARD_GATE_ENABLED`.

---

## 4. Assessment of the proposal `2026-06-03_hard-position-size-circuit-breaker.md`

**Overall: sound diagnosis, correct instinct (cap independent of the risk formula), correctly routed through Karri. But it has two real gaps and one factual imprecision.**

What it gets right:
- Identifies the amplification vector and that remediation tuned inputs without adding a hard cap. Correct.
- Puts the breaker in the order path (`placeOandaOrder` / strategy-execution) — correct location, this is the one chokepoint both live and (mostly) paper flow through.
- Env-gated, rollback-safe, generous default. Correct per operator rollback-safety rule.
- Adds a regression test reproducing the 106-unit case. Correct and currently missing (no test asserts size fidelity, confirmed).

Gaps / corrections (for Karri, do not implement):

- **GAP A — aggregate / concurrent exposure is NOT covered.** The proposal caps **per-trade** units + notional only (`MAX_UNITS_PER_TRADE`, `MAX_NOTIONAL_PCT_OF_BALANCE`). The 04-21 blowup was *"multiple concurrent"* ~12%-risk trades. A per-trade cap of e.g. 4% still allows 3 strategies × 4% = 12% aggregate, because each runs its own `maxOpenPositions` count and the live path has **no aggregate gate at all**. The breaker must also cap **summed open notional / summed account-risk across ALL open positions at order time** (read open positions, add the prospective trade, reject/clamp if total > `MAX_TOTAL_NOTIONAL_PCT` or `MAX_TOTAL_ACCOUNT_RISK_PCT`). This is exactly what `performPortfolioCheck` was built to do but which the live path bypasses.

- **GAP B — the fix points at `managers.ts`-era assumptions; the real wiring problem is that the live path bypasses the exposure module.** The proposal treats the cap as a brand-new guard. Cleaner framing for Karri: either (i) wire `performPortfolioCheck` into `strategy-execution.ts` so the existing aggregate caps finally apply on the live path, then add a units/notional ceiling on top; or (ii) implement a standalone aggregate+per-trade breaker in the order path. Option (i) reuses tested code and closes the "caps exist but don't run" trap. Whichever, the breaker must enforce in **absolute units and notional**, not just risk-%, because risk-% does not bound units when SL is tight.

- **Imprecision — item 2 (re-enable `RISK_LEVEL_HARD_GATE_ENABLED`) is not a size cap** and shouldn't be bundled as if it closes the same hole. It's a risk-regime entry block (good to have, separate decision, separate data-readiness question). Recommend splitting it out so approving the breaker isn't coupled to a gate-activation that needs its own soft-log baseline review.

Minor:
- Item 3 (align SCALP_RISK_PCT) — note SCALP_RISK_PCT is legacy-path; the live equivalent is `SCALP_OVERLAP_RISK_PCT` (default 0.5%). Karri should confirm which path is live before "aligning".
- Default cap value: prefer expressing the per-trade ceiling as **notional %-of-balance** (e.g. cap units so notional ≤ X% of balance) rather than a raw unit count, since a fixed unit count means very different $ exposure as balance grows. A raw `MAX_UNITS_PER_TRADE` is a fine belt-and-suspenders second line, but the primary cap should scale with balance.

---

## TOP-2 IMPROVEMENTS TO THE PROPOSAL (the asked-for answer)

1. **Add an aggregate / concurrent-exposure cap, not just per-trade.** As written it only bounds a single trade; the 04-21 kill was multiple concurrent ~12%-risk positions. The breaker must, at order time, sum open-position notional + account-risk, add the prospective trade, and reject/clamp if the *total* exceeds `MAX_TOTAL_NOTIONAL_PCT` / `MAX_TOTAL_ACCOUNT_RISK_PCT`. Easiest correct route: wire the already-tested `performPortfolioCheck` into the LIVE `strategy-execution.ts` path (it's currently bypassed — caps exist but never run on live), then layer the absolute units/notional ceiling on top.

2. **Express the primary cap in absolute units/notional terms, and put it in the one order chokepoint independent of the risk-% math.** Risk-% does not bound units when SL is tight (that's the entire amplification mechanism). Cap so that `units × price ≤ MAX_NOTIONAL_PCT × balance` AND `units ≤ MAX_UNITS_PER_TRADE`, evaluated in `placeOandaOrder` / just before it, so it catches any caller (live, paper, future strategy) regardless of how size was derived. Keep ai-2's regression test, and extend it to also assert the *aggregate* path clamps 3×concurrent.

(Also recommend splitting the `RISK_LEVEL_HARD_GATE` re-enable out of this proposal — it's a separate entry-regime decision, not a size cap.)
