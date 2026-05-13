# Signal rejection deep-dive (24h)

**Run**: 2026-05-13 ~11:20 CET, `blackboard.xauusd.signal.rejected` last 24h
**Total rejections**: 3,099 (across 6 strategies)
**Trades executed (same window)**: 3 (session-breakout 1, vol-expansion 2)
**Signals that escaped to `.signal` topics**: 19 (sess-break 9, vol-exp 8, bo-cont 2)

---

## TL;DR (3 bullets)

- **Dominant blocker is intentional, not a bug**: `session_blocked: OVERLAP_ACTIVE` (11–14 UTC) accounts for **597 rejections** across trend-following + breakout-continuation + pullback-continuation. These 3 strategies are hard-coded to refuse signals during the London/NY overlap — by historical design (`new-gates.ts`: "16 trades, -$2151 net" past losses). The system is operating exactly as instructed.
- **Closest-to-firing strategy = xau-trend-following on ADX**: 28 of 164 ADX rejections are within 2 points of threshold (avg actual 17.1 vs threshold 22). Drop threshold 22→20 (still well above the canonical 18) and ~28 signals/24h unlock — but they would still hit the OVERLAP block in primary hours.
- **No broken-gate / always-rejects anomalies detected**. The `xau-volatility-expansion` ATR ratio gate is *almost* a hard reject (594 rejections at threshold 1.3, only 7 within 0.1 of passing) — gate works but threshold is steep vs. realized vol. Worth noting, not "broken".

---

## Per-strategy × stage breakdown

| Strategy | Top rejection stage | n | 2nd | n | 3rd | n |
|---|---|---|---|---|---|---|
| xau-trend-following | session_blocked (OVERLAP) | 252 | adx_too_low | 163 | session_not_allowed | 143 |
| xau-breakout-continuation | session_blocked (OVERLAP) | 252 | session_not_allowed | 207 | no_valid_range | 113 |
| xau-pullback-continuation | session_blocked (OVERLAP) | 252 | session_not_allowed | 207 | adx_too_low | 100 |
| xau-volatility-expansion | atr_ratio_below_threshold | 594 | cooldown_active | 100 | post_impulse_mean_revert_block | 4 |
| xau-mean-reversion | session_not_allowed | 153 | rsi_not_overbought | 54 | impulse_too_small | 46 |
| xau-session-breakout | per_strategy_cap | 6 | session_blocked_OVERLAP | 2 | — | — |

Total signals: TF 710 / BC 709 / PC 710 / VOL 708 / MR 253 / SBO 8.

---

## Top-10 rejection stages (all strategies)

| Stage | n | % | Notes |
|---|---|---|---|
| session_blocked (`OVERLAP_ACTIVE` + `NY_OPENING_RANGE`) | 756 | 24% | Hard rule, 3 strategies |
| session_not_allowed (Asia / Lon-prepare / Low-prio / Lon-OR) | 710 | 23% | Hard rule, allowed-list mismatch |
| atr_ratio_below_threshold | 594 | 19% | vol-expansion only (thr 1.3) |
| adx_too_low | 263 | 8% | TF + PC |
| vol_expansion_below_min | 185 | 6% | TF + PC (thr 1.05) |
| no_valid_range | 113 | 4% | Breakout-continuation |
| cooldown_active | 100 | 3% | Vol-exp |
| no_clean_breakout | 100 | 3% | Breakout-continuation |
| pullback_too_deep | 98 | 3% | TF + PC |
| rsi_not_overbought | 54 | 2% | Mean-reversion |

---

## Hour-of-day pattern (UTC)

OVERLAP-block lights up 11–14 UTC (3 strategies × ~57/hour). Pre-overlap (07–10 UTC) is **dominated by `adx_too_low` and `vol_expansion_below_min`** — i.e. the markets are too slow during the London-AM lull. Post-overlap (15–18 UTC) is where `xauusd.vol-expansion.signal` and `xauusd.session-break.signal` actually fire (8+9 emitted signals).

Quiet hours 00–06 UTC are correctly blocked by ASIA_OBSERVE / ASIA_PREPARE_FOR_LONDON / LONDON_OPENING_RANGE.

---

## Distance-to-passing analysis

| Strategy | Gate | thr | avg actual | avg gap | within 1 increment |
|---|---|---|---|---|---|
| trend-following | ADX | 22 | 17.1 | 4.9 | 28 within 2 (17%); 63 within 5 (38%) |
| pullback-continuation | ADX | 20 | 15.6 | 4.5 | 0 within 2; 87 within 5 (86%) |
| vol-expansion | ATR ratio | 1.30 | 0.82 | 0.48 | 7 within 0.1 (1%); 100 within 0.3 (17%) |
| mean-reversion | impulse ATR | 1.50 | 1.12 | 0.38 | 2 within 0.1; 19 within 0.2 (40%) |
| TF + PC | vol_expansion | 1.05 | 0.74 | 0.31 | **0** within 0.15 — market is structurally below this gate |

Key read: `vol_expansion_below_min @ 1.05` is bone-dry — XAU realized expansion is clustered ~0.72–0.81 right now (low-vol regime, consistent with Karri's "trend-pause" hypothesis). Lowering this threshold won't help unless it's halved.

---

## Single biggest mechanical blocker

**`session_blocked: OVERLAP_ACTIVE`** at 597 rejections — but this is the **deliberate** loss-prevention rule from `apps/worker/src/firm/gates/new-gates.ts:196`. Relaxing it requires Karri-review (strategy change). Not a candidate for zero-risk relaxation.

**Best zero-risk relaxation candidate**: `xau-trend-following` ADX threshold 22→20.
- 28/24h signals unlock at the `within_2` band, +35 at `within_5`.
- Still well above the canonical ADX-trending threshold of 18.
- Old TIER-3 default was 20 (raised to 22 during tune-up).
- Caveat: most of these signals still hit downstream OVERLAP block in primary hours — net unlock during NY_CONTINUATION only.

---

## Broken-gate scan

None confirmed broken. Two notable quirks:
- `xau-pullback-continuation` ADX has avg 15.55, **zero** within 2 of threshold 20 — every PC signal is structurally too low-ADX. Either PC's ADX measurement is divergent or current regime is genuinely ranging.
- `vol_expansion_below_min @ 1.05` has 0 within 0.15 of passing across 185 events — gate is correctly identifying low-vol, but if regime persists 7+ days this gate becomes effectively a hard "OFF".

Neither rises to "broken" — both reflect a calm market.

---

## Recommendation

1. **Do nothing reflexively on OVERLAP block**. It's the documented loss-prevention rule. If Karri wants to reopen, that's a proposal-doc decision.
2. **Propose ADX 22→20 for trend-following** as a low-risk surface-area widen. File proposal: `docs/strategy/proposals/2026-05-13_tf-adx-22-to-20.md`. Auto-send to Karri (within work-hours window).
3. **Tag for monitoring**: if `vol_expansion_below_min` blocks >150/day for 3+ consecutive days, that's a regime-detection signal worth surfacing in morning briefing (not auto-acting). Aligns with Karri's trend-pause hypothesis.
