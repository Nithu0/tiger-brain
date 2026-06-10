# Regime gates live — is regimeDirection computed, are gates biting?

Date: 2026-06-10 | Build: f4bfadf | Source: nexus-pg MCP (live, NOT dead) + gate code + technical blackboard
Scope: READ/VERIFY ONLY.

## TL;DR

- **regimeDirection now computed live: YES.** Today (06-10) the gate is recording `regimeDirection=DOWN`, `regime=TRENDING` on a sustained run of cycles. Direct evidence below.
- **Regime gates biting: NO — gate has hard-rejected 0 / 127 times ever.** Direction is computed but the gate never fires, for two reasons unrelated to ADX.
- **Premise correction (important):** ADX was NOT null before the flag flip. ADX has been present in the technical blackboard every single day for 14 days (Twelve Data supplies it; the OANDA fallback is only a backstop). So the recent `INDICATOR_OANDA_FALLBACK_ENABLED=ON` is NOT what "turned on" direction. What changed today is simply that the market is genuinely trending hard (ADX 31-33). This REFUTES the "ADX still null" hypothesis — the ADX-fix agent's premise that direction was null *because ADX was null* does not hold against live data.

## 1. Decision-funnel: regime_direction_gate

3-day and 7-day funnel both show `regime_direction_gate`: evaluated 28/36, **hardRejected 0, wouldReject 0, passed all**. No bites.

Lifetime gate_decisions (since 2026-05-13):

| reason | n | regime | regimeDirection |
|---|---|---|---|
| regime_not_trending | 79 | RANGING/MIXED/HIGH_VOL/EVENT/NOISY | null |
| not_mean_reversion_strategy | 48 | TRENDING | UP/DOWN |

- hard_rejects = **0 / 127**, would_rejects = **0 / 127**. The gate has NEVER blocked anything.
- regimeDirection populated (UP or DOWN) since **2026-05-15** — not new today.

## 2. Live regime classification — direction IS produced

Today's gate rows (06-10 12:18–12:30Z), verbatim context:
```
regime=TRENDING, direction=short, strategyId=xau-session-breakout, regimeDirection=DOWN
```
~19 consecutive cycles today, all TRENDING + regimeDirection=DOWN. So regimeDirection is computed and flowing.

regimeDirection distribution (lifetime): DOWN/TRENDING ×45, UP/TRENDING ×3, rest null (non-trending regimes). Direction is published on the separate `regimeDirection` field; base regime string stays bare "TRENDING" (by design — see regimes.ts:44-54). The premise's "TRENDING_UP/TRENDING_DOWN" combined label does not exist in this codebase; gate reads `regime==="TRENDING"` + separate `regimeDirection`.

ADX in technical blackboard, last cycles: 31.4–33.6 (all > 30 → TRENDING). adx_source field is null (not stamped). ADX-present-per-day over 14d: **adx_present == total EVERY day** (e.g. 06-10: 439/439; 06-09: 691/691; 05-27: 251/251). ADX was never null. What varied is adx>30 count: 435/439 today vs 69/691 on 06-09 — i.e. market regime, not data availability.

## 3. Why the gate never bites — TWO real reasons (neither is ADX)

### Reason A — naming mismatch: the obvious mean-reversion strategy is NOT in the block-list
`regime-direction-gate.ts:38` `MEAN_REVERSION_STRATEGIES = [xau-scalp-overlap, xau-vol-expansion, xau-volatility-expansion]`.
The live strategy actually named `xau-mean-reversion` is **NOT** in that list.

Smoking gun — 2026-06-05, two cycles:
```
strat=xau-mean-reversion, direction=long, regimeDirection=DOWN, regime=TRENDING
→ reason=not_mean_reversion_strategy (ALLOW)
```
This is a LONG into a DOWN-trend in a TRENDING regime — the *exact* counter-trend pattern the gate exists to block — and it was allowed, purely because `xau-mean-reversion` isn't on the block-list. The gate computed direction perfectly and still whiffed on its most obvious target. The block-list catches `xau-volatility-expansion` (also fired, but SHORT in TRENDING-DOWN = with-trend, correctly allowed).

### Reason B — when direction IS known + strategy WOULD match, it happens to be with-trend or breakout
Today's runs are `xau-session-breakout` (a breakout strategy, deliberately excluded line 14) → always `not_mean_reversion_strategy`. No counter-trend mean-reversion proposal has coincided with a known direction *and* a block-listed strategy id.

## 4. Other regime-dependent gates (cross-check)

- **mean_revert** (separate gate, impulse-based, not regimeDirection): biting hard — `mean_revert_block` hard-rejected **52** times (last 06-09 17:56). `no_recent_impulse` 75× pass. This is the gate doing the actual counter-trend work right now, NOT regime_direction_gate.
- **ranging_conviction**: 50 evals, 0 hard-rejects, reason=null (pass-through). Not biting; expected, since regime is TRENDING not RANGING today.

No behavioural change in these two attributable to the flag flip.

## Conclusion

- **regimeDirection computed live: YES** (TRENDING + DOWN today, present since 05-15).
- **ADX fallback EFFECTIVE? Moot / mis-framed.** ADX was already present continuously via Twelve Data; the OANDA fallback is an unused-in-practice backstop here. Direction being computed is NOT contingent on the fallback. This REFUTES the ADX-fix agent's premise that direction was null because ADX was null — the live data shows ADX non-null for 14 straight days.
- **regime_direction_gate biting: NO (0/127 ever).** Root cause is NOT data — it's a strategy-id naming mismatch (`xau-mean-reversion` absent from `MEAN_REVERSION_STRATEGIES`), which let a textbook counter-trend long-in-downtrend through on 06-05. Fixing the list (adding `xau-mean-reversion`, and likely `xau-fvg` if Karri considers it mean-reversion-class) is the lever — that is a strategy/risk change → Karri proposal, not a Claude-side flip.

Caveat: this is the gate's recorded decisions; if some mean-reversion proposals are rejected upstream (risk_level, mean_revert) before reaching regime_direction_gate, the gate would never see them. risk_level is rejecting ~23/28 cycles (risk_level_high) in the 3d window, so upstream rejection masks some of the gate's would-be workload.
