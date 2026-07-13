# Edge-existence analysis — does Nexus make money anywhere?

Date: 2026-06-15
Scope: READ/ANALYSIS ONLY. Source: `simulated_orders` (closed trades, n=209) + `shadow_signals` (n=478 resolved) via nexus-pg-rw.
Window: closes 2026-04-16 → 2026-06-15.

## TL;DR verdict

**Not structurally negative — but no statistically-proven positive edge yet either.** The headline −$11.2k is a measurement artifact: 79 `OANDA_BACKFILL` import positions (sized up to 106 lots, no strategy logic) account for −$10.8k of it. **Strip those and the firm-attributed book is essentially flat: −$360 over 130 trades (−$2.77/trade).**

The real, actionable finding is **a directional/gate edge, not a strategy edge**:
1. Specific strategy×direction subsets are clearly positive in the live book (vol-expansion shorts, mean-reversion longs).
2. In shadow, **blocked signals beat fired signals for every strategy** — the gates are inverted and throwing away the better trades.

Path forward = **"trade the right subset + fix the inverted gates"**, NOT "scrap and rewrite strategy logic." But sample sizes are too small to bet real capital on yet — every strategy-level CI straddles zero.

---

## 1. The −$11k is mostly a backfill artifact

| bucket | n | total PnL | exp/trade | avg size | max size |
|---|---|---|---|---|---|
| OANDA_BACKFILL (import/legacy) | 79 | **−$10,797** | −$136.67 | 23 | 106 |
| firm-attributed | 130 | **−$360** | −$2.77 | 35 | 446 |

The entire loss is in one week (Apr 19–25, −$8,657) of backfill imports — pre-firm positions sized 70–106 lots vs modern firm trades that mostly size <70. These have no `strategy_id`, no `execution_source`, `close_reason='OANDA_BACKFILL'`. **They should be excluded from any edge judgment** (and from the dashboard's headline PnL — they're contaminating it). The "London-NY-Overlap −$5.3k @ 30% WR" figure in the brief does not reproduce against this table; session metadata is mostly NULL pre-Apr 27, so session-sliced PnL is unreliable. Treat session/regime slices as unusable (see §4).

---

## 2. Where the firm makes money — live book (backfill excluded)

| strategy | n | total | exp/trade | WR | PF | 95% CI on exp |
|---|---|---|---|---|---|---|
| xau-volatility-expansion | 44 | +$2,277 | +$51.74 | 43% | 1.28 | **[−124, +227]** |
| xau-mean-reversion | 16 | +$1,268 | +$79.28 | 50% | 1.58 | **[−123, +282]** |
| xau-scalp-overlap | 7 | −$213 | −$30 | 43% | 0.80 | [−291, +230] |
| xau-session-breakout | 23 | −$882 | −$38 | 26% | 0.53 | [−123, +47] |
| xau-trend-following | 5 | −$807 | −$161 | 20% | 0.33 | — |
| xau-orb | 5 | −$1,300 | −$260 | 0% | 0.00 | — |
| xau-fvg | 20 | −$2,208 | −$110 | 35% | 0.43 | [−256, +36] |

**Honesty check:** the two positive strategies have positive point estimates but **both CIs include zero**. The variance is large (SD ~$590 on vol-expansion). This is *suggestive* edge, not *proven* edge. We cannot reject "these are zero-edge with lucky draws" at n=44/16.

### The sharper signal — direction within strategy
| strategy×direction | n | total | exp | WR |
|---|---|---|---|---|
| **vol-expansion SHORT** | 28 | **+$2,600** | +$93 | 50% |
| vol-expansion LONG | 16 | −$323 | −$20 | 31% |
| **mean-reversion LONG** | 15 | **+$1,621** | +$108 | 53% |
| mean-reversion SHORT | 1 | −$352 | — | 0% |

The entire vol-expansion edge is in SHORTS; longs are a drag. Mean-reversion is a longs business. This is the cleanest "lean into it / cut the rest" lever in the live data.

---

## 3. Shadow ledger — and it DISAGREES with the live book (key finding)

Shadow has 478 resolved signals with `pnl_simulated_r`. **Caveat: shadow R is a coarse fixed-RR simulator** — values bucket to 0.00 / +1.50 / −1.00, no slippage/spread modeled, so it *overstates* clean edge. Use it for direction, not dollars.

**The inverted-gate finding — fired vs blocked avg R, per strategy:**
| strategy | fired n | fired R | blocked n | blocked R |
|---|---|---|---|---|
| vol-expansion | 44 | **−0.18** | 18 | **+0.71** |
| session-breakout | 20 | +0.02 | 332 | **+0.43** |
| scalp-overlap | 7 | +0.67 | 8 | +1.06 |
| mean-reversion | 0 | — | 17 | +0.18 |
| fvg | 0 | — | 19 | −0.11 |

**For every strategy with a sample, the signals the gates BLOCKED outperformed the ones they let through.** The entry-gating is selecting the wrong subset. Note this contradicts the live book (live vol-expansion *executed* trades made money; shadow says executed vol-expansion was −0.18R) — likely because live PnL is dollar-weighted and shadow is fixed-R, and because shadow's blocked-set includes the big winners the live book never got to take.

**Biggest blocked edge:** xau-session-breakout SHORTS — n=304, avg **+0.53R**, sum +161R — almost all blocked. The gates killing them:
- `cap-reached per-strategy cap (1/1)` — 91 signals, +0.13R (cap too tight)
- `mean_revert_block` — ~60 signals, many at **+1.5R** (block is firing against profitable shorts)
- `spread_gate_proxy` — ~20 signals at **+1.5R** (proxy too aggressive)
- `session_blocked_NY_OPENING_RANGE` — 40 signals at +0.84R

These four gates are the prime suspects for throwing away edge. (They're shadow-sim numbers — verify against real fills before acting, since spread/slippage is exactly what shadow ignores and exactly what these gates claim to protect against.)

---

## 4. The bleeders to cut/gate

Clear negatives (live, backfill excluded):
- **xau-orb**: n=5, 0% WR, −$1,300, PF 0.00 — cut or gate hard. (Shadow agrees: fired −0.80R.)
- **xau-fvg**: n=20, −$2,208, PF 0.43 — worst $ bleeder among real strategies. (Karri WIP per memory — flag, don't unilaterally cut.)
- **xau-trend-following**: n=5, −$807, 20% WR — too small to judge but uniformly bad.
- **vol-expansion LONGS** and **mean-reversion SHORTS** — the losing halves of the two winners.

Session/regime slices are NOT reliable blee(der evidence: 124/209 trades have NULL session, 189/209 NULL regime. The apparent "asia 0% WR" / "NY_CONTINUATION −$320/trade" buckets are n=4 each and pre-date metadata capture. **Do not gate by session/regime off this data** — the coverage isn't there. (Recommend: backfill `session_at_entry`/`regime_at_entry` from `opened_at` + market snapshots before trusting any session cut.)

---

## 5. Verdict

**Lean-into-subset, with a gate fix — NOT structural-negative-needs-new-logic.**

Reasoning:
- The edge is **not negative across the board**. Stripped of backfill noise the book is flat, and there are coherent positive subsets (vol-expansion shorts +$93/trade n=28; mean-reversion longs +$108/trade n=15) that show up in *both* WR and PF, not just total $.
- But it is **not proven positive** — all strategy CIs straddle zero. This is a "promising signal at low n" situation, not a green light to scale.
- The highest-leverage fix is **the inverted gates**, not the strategies: shadow shows the firm is systematically blocking its better signals (especially session-breakout shorts) and firing its worse ones. Fixing gate selection could convert the flat book to positive without any new strategy logic.

### Recommended actions (priority order)
1. **Exclude OANDA_BACKFILL from headline PnL/dashboards** — it's distorting every aggregate (ops/observability, no strategy change → can do now).
2. **Strategy-reviewer (Karri) items** — these are trade-altering, route via `docs/strategy/proposals/`:
   - Tighten/cut xau-orb and review xau-fvg.
   - Bias vol-expansion toward shorts, mean-reversion toward longs (directional gate).
   - Re-examine `mean_revert_block`, `spread_gate_proxy`, `cap-reached (1/1)`, `session_blocked_NY_OPENING_RANGE` — shadow says they block +0.5 to +1.5R shorts. Validate against REAL fills first (shadow ignores spread, which is what these gates exist for).
3. **Data hygiene** — backfill session/regime metadata so session×strategy edge becomes analyzable; current session slices are unusable.

### Confidence
Medium-low on the dollar magnitudes (small n, wide CIs, shadow is coarse). High on the qualitative shape: (a) the loss is a backfill artifact, (b) directional asymmetry within the two winners is real, (c) the gates are blocking better signals than they fire. Do NOT scale capital on this; do tighten the obvious bleeders and investigate the inverted gates.
