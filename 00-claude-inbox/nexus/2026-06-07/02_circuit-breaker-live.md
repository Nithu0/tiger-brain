# Position-size circuit breaker — live verification (2026-06-07)

**Verdict: breaker is LIVE + CLAMPING in code (on main `2b2d2ce`), but NOT YET EXERCISED by real data since the clamp-mode flip. No clamp event has fired on a live oversized signal yet — there are zero trades after the PR#67 deploy.**

Read-only audit. Live deploy = `2b2d2ce` (main). Data: `data/pull/*` pulled 2026-06-07 ~14:32.

---

## 1. Is the breaker on the live path + clamping? — YES (code-confirmed)

`positionSizeCircuitBreaker()` — `apps/worker/src/firm/strategy-execution.ts:117-138`.
Called at line **986**, immediately before `placeOandaOrder()` (line 1025) — last gate before the broker.

- **Clamp, not reject** (Karri 2026-06-05, PR #67 `184bf7b` / merge `72d94ba`): if `size > ceiling`, returns `clampedSize = ceiling` with `clamped:true`; caller reassigns `size = breaker.size` (line 994) and the trade proceeds at bounded size. Only a clamp-to-**0** (bad equity/price) aborts the trade.
- `ceiling = min(maxUnits, floor(maxNotionalPct/100 × equity / entryPrice))` — tighter of the two caps wins.
- Defaults in code: `POSITION_SIZE_CIRCUIT_BREAKER_ENABLED=true`, `MAX_UNITS_PER_TRADE=80`, `MAX_NOTIONAL_PCT=300`. Flag default ON; disabled only if Railway sets it false (30s rollback).
- Scalp ceiling (PR#67 item E): `managers.ts:826-836` — `SCALP_RISK_PCT` override now capped at **1.5%**; any value >1.5 (e.g. legacy 2.5) is rejected and Forge risk stands.

Unit tests confirm clamp shape: `strategy-execution.test.ts:437-484` (normal passes, oversized clamps, units-ceiling binds, disabled no-ops, zero-equity → 0 fail-safe, 300% boundary exclusive). 1111/1111 green per PR#67.

**Caveat:** no live status endpoint echoes the breaker config or any clamp counter. "Enabled in prod" is inferred from the code default + the absence of a disabling env, not positively observed. Minor observability gap.

## 2. Live trade data — any clamp since the flip? — NO EVIDENCE (no trades post-deploy)

Clamp-mode (PR#67) merged **2026-06-05 15:48 CET**. The latest trade in the data opened **2026-06-05 12:54** — *before* that deploy. `health.json` `lastDecisionSec ≈ 171575` (~47.6h) confirms no decisions/trades since ~Jun-5. So the clamp has had no oversized signal to act on yet; there is **no live clamp event to point to.**

Largest sizes since 2026-06-01 (notional% vs live ~$90k balance):

| Opened | Units | Notional% | Over cap? |
|---|---|---|---|
| 2026-06-01 00:13 | 158u | 799% | >80u, >300% |
| 2026-06-03 00:45 | 114u | 570% | >80u, >300% |
| 2026-06-02 15:03 | 86u | 432% | >80u, >300% |
| 2026-06-03 14:55 | 79u | 392% | >300% |
| 2026-06-05 03:38 | 58u | 287% | (just under) |

All of these (158/114/86/79u) reached the broker because they opened **before the breaker code was even on main** (PR#61 first merged 2026-06-04 01:08; clamp PR#67 the evening of 06-05). They are pre-breaker, not breaker failures. But they prove the firm was routinely producing >80u / >300% signals as recently as 4–6 days ago — i.e. the breaker *will* have live work to do on the next active session, and that next session is the real test.

**Can an 80u+ / 300%+ trade reach the broker now?** With the breaker enabled and `equity = OANDA balance`, no — the gate floors size at the tighter cap before `placeOandaOrder`. **Conditional on two things being true in prod (see §4): the flag is on, and `USE_OANDA_BALANCE=true`.** Not yet positively observed on live data.

## 3. Sanity checks

- **Would the historical 106u blowup be clamped to 80u today?** No — clamped to **~56u**, even tighter. At entry $4784 / $90k equity, the 300% notional cap binds (floor(3.0×90000/4784)=56) before the 80u cap. Test at `strategy-execution.test.ts:448-454` asserts exactly `clamped 106u → 56u`. **At current XAUUSD prices (~$4450–4800) the 300% notional cap is always the binding constraint (~56–60u); the 80-unit cap never fires — it only binds below ~$3375/oz.** Effective per-trade ceiling today is ~56–60u, not 80.
- **Scalp 1.5% ceiling in live sizing?** Code-present (`managers.ts:833`) and tighter than before. Can't confirm it bit on live data — `SCALP_RISK_PCT` only overrides in scalp regimes and only when the env is set; no recent scalp-clamp visible in the dataset.

## 4. Gaps / residual risk

1. **`USE_OANDA_BALANCE` dependency (top risk).** `virtualBalance` defaults to `DEMO_STARTING_BALANCE_USD = 10_000` (`strategy-execution.ts:363`, `packages/shared/src/constants.ts:21`) unless `USE_OANDA_BALANCE=true`. The notional% cap is computed against that equity. If the flag is OFF, 300% = $30k notional ≈ 6–7u at $4450 → the breaker would over-clamp almost everything to a handful of units. The June trades sized against ~$90k imply the flag IS on in prod, but the breaker's correctness is **silently coupled** to it. If anyone flips `USE_OANDA_BALANCE` off, the breaker mis-scales hard. Worth a guard/alert.
2. **Currency mismatch.** Notional is `units × entryPrice` in **USD**; OANDA equity is in **EUR** (~€89.8k). The % is computed across currencies. Conservative direction (EUR<USD → % slightly overstated → clamps marginally early), but it's an unmodeled ~10% skew in the cap.
3. **Per-trade only — no aggregate/concurrent cap (Karri follow-up).** Each trade is bounded to ≤300% notional, but N concurrent oversized entries can still stack total exposure well past 300%. Documented in the proposal (`2026-06-04_hard-position-size-circuit-breaker.md:79`): stacking is "a separate axis handled by per-strategy cooldowns/caps — not this breaker." This is the real remaining blowup vector — the 2026-04-21 event was a *cluster* of ~6×100u trades, and per-trade clamping alone would not have capped the aggregate.
4. **entryPrice-vs-fill nit.** Breaker uses intended `entryPrice` (line 986); the order submits the clamped `size` but fills at OANDA's actual price (line 1025), which diverges with slippage. So realized notional can drift slightly above the cap on adverse fills. Bounded/minor for XAU, but the cap is computed on intended, not realized, price.
5. **No observability of clamp events.** No status endpoint surfaces breaker config or a clamp counter; only a `logWarn("firm","circuit-breaker", …CLAMPED…)` line. To confirm the breaker is actually biting on the next active session, grep Worker logs for `circuit-breaker` / `CLAMPED`.

---

## Bottom line

- **Breaker live + clamping: YES in code on `2b2d2ce`; NOT YET exercised on live data** (no trades since the 2026-06-05 clamp deploy).
- **Evidence of a clamp since flip: NONE** — zero post-deploy trades; the next active session is the first real test. Grep Worker logs for `CLAMPED`.
- **Top residual risk: the per-trade-only design has no aggregate/concurrent cap** (the 2026-04 blowup was a cluster, not one trade) — *and* the cap's scaling silently depends on `USE_OANDA_BALANCE=true`. Both are Karri-gated follow-ups.
