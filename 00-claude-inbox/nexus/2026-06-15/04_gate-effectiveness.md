# Gate-effectiveness audit — are the live guards reducing the bleed?

Date: 2026-06-15. READ-ONLY. Source: `/decision-funnel` (API/443) + `gate_decisions` ⋈ `shadow_signals` ⋈ `simulated_orders` (nexus-pg, read-only). Windows: 14d for funnel, 21d for the join (more outcomes resolved).

## TL;DR verdict

The guards are **NEUTRAL-to-HARMFUL on the part of the firm they cover, and the actual bleed is bypassing them entirely.**

- The two gates that actually bite — **`mean_revert`** and **`risk_level`** — are **rejecting overwhelmingly WINNERS** in the shadow ledger. They are mis-calibrated.
- The circuit-breaker works **but only on the firm-strategy path**, which is +profit. The entire money loss comes from a **legacy "XAUUSD Auto" / no-signal path that never touches the gates or the breaker.**
- The ATR fix (#102/#103) is the one unambiguous win: regime now classifies sanely (TRENDING-dominant, NOISY_CHAOTIC down to 13%), not over-chaotic, and not obviously under-gating.

The firm bleeds because **92% of trades (34/39 over 21d) bypass the entire firm gate stack.** Tuning the gates won't fix that — the ungated legacy path has to be closed.

---

## 1. Which gates are LIVE + biting, and do they reject winners or losers?

`gate_decisions` 14d (hard_rejected): only **two** gates bite. Everything else is 0.

| Gate | evaluated | would_reject | hard_rejected | biting? |
|---|---|---|---|---|
| **mean_revert** | 134 | 56 | **56** | YES |
| **risk_level** | 55 | 27 | **26** | YES |
| sl_cooldown | 58 | 1 | 1 | barely |
| regime_direction_gate | 57 | 0 | 0 | no (passive) |
| daily_trade_cap | 57 | 0 | 0 | no (not hit) |
| entry_stack_cooldown | 55 | 0 | 0 | no |
| session_block | 55 | 0 | 0 | no |
| scalp_overlap_asia | 55 | 0 | 0 | no |
| ranging_conviction | 55 | 0 | 0 | no |
| min_rr | — | — | — | not in funnel (shadow-only, never blocks) |

### Cross-ref: would the hard-rejected signals have WON or LOST? (gate ⋈ shadow on cycle, 21d)

| Gate | rejected → tp_hit (WIN) | → sl_hit (LOSS) | → expired | net would-be R | reading |
|---|---|---|---|---|---|
| **mean_revert** | **49** | 7 | 45 | **+77.0 R** | rejecting WINNERS — HARMFUL |
| **risk_level** | **20** | 6 | 0 | **+31.0 R** | rejecting WINNERS — HARMFUL |
| session_block | 0 | 1 | 0 | −1 R | (1 sample, off) |
| sl_cooldown | 0 | 1 | 0 | −1 R | (1 sample) |

Both biting gates reject ~77–88% winners. Shadow tracking is validated: every outcome has `outcome_price` set, spread over many days, with realistic sl_hit counts — not a tracking artifact.

### Per-gate detail

**`mean_revert` — the single most mis-calibrated gate.**
Hard-rejects by strategy it blocked (21d): `xau-session-breakout` 90, `xau-fvg` 9, `xau-trend-following` 2.
It is **mis-named**: `gates/mean-revert-gate.ts` is actually a *continuation-blocker*. It blocks any continuation signal that fires **in the direction of a recent ≥2-ATR/90min impulse**, on the thesis "mean-revert likely ahead." But in the current TRENDING-UP market that exact cohort (session-breakout aligned with the impulse) shadow-tracked **102 tp / 16 sl / 54 expired = 86% win** over 21d. The impulse *continued*; it did not revert. The gate's premise is backwards for this regime.

**`risk_level` — second mis-calibrated gate.**
Narrowed by Karri 2026-06-10 to block-list `high,extreme`. But the blocked cohort is dominated by `risk_level_high` on **session-breakout: 18 tp / 0 sl** — pure winners. It also clips a few fvg/mean-reversion losers (good), but net it is rejecting the firm's best strategy. "high" risk-level is firing on normal-vol trend conditions (gold $4200) and catching the winning breakouts.

**Context: what actually traded.** Real closed firm-eligible trades 21d = 39 closed, **−$432.93 net, 14 W / 24 L (37% win)**. So the gates block the 86%-win session-breakout while the 37%-win live book runs. That is the textbook mis-calibration signature.

---

## 2. Circuit-breaker (80u / 300% notional): clamping anything? Oversized still getting through?

- `risk-snapshot`: `circuitBreaker: null`, `clamps: null`, `killSwitches: []`. No DAILY_LOSS_LIMIT or clamp events in `risk_events` for 21d (last critical was 2026-04-10).
- Caps: `MAX_UNITS_PER_TRADE=80`, `MAX_NOTIONAL_PCT=300` (≈64u at ~$90k equity / $4200). Default **ON**, but **per-trade only** (lives inside `executeStrategySignal`). The aggregate `PORTFOLIO_EXPOSURE_BREAKER` is default **OFF**.
- **Oversized trades ARE getting through** — max size 158u ($717k notional), 6 trades ≥64u, 3 ≥80u in 21d. But:

| Path | trades | net PnL | max size | gated by breaker? |
|---|---|---|---|---|
| firm-strategy (gated) | 5 | **+$2,146.85** | 79u | YES — caps held |
| no_signal / legacy | 34 | **−$2,579.78** | **158u** | **NO — bypasses breaker** |

The 158u/−$456, 114u/−$787, 86u/−$631 monsters all have `signal_id NULL` (bot **"XAUUSD Auto"** = −$695/26 trades, plus 8 fully-unattributed = −$1,885). These never enter the firm strategy-execution path, so the per-trade circuit-breaker never sees them. **The breaker is real and effective where it applies — but the oversized losers live entirely outside its reach.**

---

## 3. ATR fix (#102/#103): regime sane, or under-gating?

**Sane — this is the one clean win.**
- Live regime (`/operator/regime`): TRENDING / UP / volatility=**normal** (ADX 32.9, ATR 7.65 @ ~$4200 = 0.18%). Pre-fix absolute thresholds (>$7 = high, >$12 = extreme) would have called this "high." Reported normal ⇒ the price-relative path is active.
- Regime distribution 14d (55 cycles): TRENDING 49%, RANGING 24%, **NOISY_CHAOTIC 13%**, MIXED 13%, HIGH_VOL 2%. Pre-fix this was ~32% NOISY_CHAOTIC (per `vol-thresholds.ts` measurement). So chaos-overclassification is fixed.
- Not under-gating: TRENDING dominates and matches ADX 32.9. No evidence the fix opened the floodgates — the volume problem is the ungated legacy path, not regime mis-classification.

---

## 4. Net verdict — helping, neutral, or harmful? Which single gate is mis-calibrated?

**Net: the gate stack is HARMFUL on the firm path and IRRELEVANT to the bleed.**

1. The only two biting gates (`mean_revert`, `risk_level`) reject net-WINNERS (+77R and +31R of would-be edge blocked). They suppress the firm's best strategy (session-breakout, 86% shadow win) while the live book runs at 37%.
2. The circuit-breaker works but guards only the +profit firm path; the −$2,580 bleed is 34 ungated legacy "XAUUSD Auto" / no-signal trades the breaker can't see.
3. The ATR fix is correct and helping.

**Single most mis-calibrated gate: `mean_revert`** — a continuation-blocker whose core thesis (impulse → reversion) is inverted for the current trending regime; it blocked 49 winners vs 7 losers and is the largest blocked-edge (+77R). `risk_level` ("high" tier) is the runner-up.

### Operator actions (NOT auto-applied — gate/risk changes are Karri-gated per CLAUDE.md)
- **Highest leverage, not a gate change:** close/route the legacy "XAUUSD Auto" + no_signal execution path through the firm gate stack (or disable it). That is where 100% of the net loss is. Check `LEGACY_XAUUSD_EXECUTION_ENABLED` and the "XAUUSD Auto" bot.
- **Karri proposal** for `mean_revert`: in TRENDING-UP regime the align-with-impulse block is inverted — either gate it on regime (only block counter-trend in RANGING) or shelve it. It is currently destroying session-breakout edge.
- **Karri proposal** for `risk_level`: "high" is firing on normal-vol trend and clipping winners; re-examine whether the risk classifier's "high" still means anything post-ATR-fix.

---
*Generated by gate-effectiveness sweep. All figures read-only from production. No flags flipped, no trades touched.*
