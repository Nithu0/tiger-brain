# Session-Breakout SL bug-hunt — 13.5

## Verdict: **D + C** (spec is structurally wrong — fix-class = **proposal-required**)

**Not an unambiguous code bug.** SL placement does *exactly* what the spec says — but the spec itself uses **full prior-session-range width** as risk, with **zero swing-microstructure or ATR consideration**. Result: SL distances of $30–$85 on a strategy where TP1 = 1.5×risk, meaning a single normal retrace blows the trade.

Spec was approved against a 90d backtest claiming WR≈46%, mean PnL +$440. Live last 30d: **14 trades, 6 OANDA_SL_TP hits, –$1111 from those alone, 4 winners, –$631 net**. Spec did not survive contact with live volatility regime.

## Code site (no recent change — bug is original spec)

`apps/worker/src/firm/session-breakout/session-break-manager.ts:339-344`

```ts
const entryPrice = currentPrice;
const stopLoss   = direction === "long" ? range.low : range.high;  // ← opposite side of range
const risk       = Math.abs(entryPrice - stopLoss);
const takeProfit = direction === "long"
  ? entryPrice + SB_CONFIG.tpRMultiple * risk
  : entryPrice - SB_CONFIG.tpRMultiple * risk;
```

Logic unchanged since `7801a6e` (TIER 3 deploy 26.4). No recent quiet refactor. ATR not read, swing-low/high not read, regime not consulted. Same SL methodology for with-trend and against-trend breakouts.

## Evidence — 6 OANDA_SL_TP hits (30d)

| Date | Dir | Entry | SL | SL-dist | RangeWidth | EntryPos | PnL |
|---|---|---|---|---|---|---|---|
| 12.5 NY | short | 4677.09 | 4711.68 | **$34.6** | $32.3 | break_below_low+thin | –$387 |
| 08.5 NY | long | 4741.51 | 4697.05 | **$44.5** | $35.1 | breakout-with-trend | –$564 |
| 05.5 NY | long | 4584.90 | 4539.96 | **$44.9** | $45.2 | breakout-tag-of-high | –$258 |
| 01.5 Ldn | short | 4561.46 | 4647.05 | **$85.6** | $71.2 | wide-range break | –$194 |
| 29.4 NY | short | 4534.13 | 4581.47 | **$47.3** | (no row) | 3 min in-trade | –$3 (size cut) |
| 27.4 NY (stale) | short | 4676.38 | 4718.01 | $41.6 | — | stale_exit | –$9 |

Patterns:
- **SL = range-opposite always**, confirmed by joining `blackboard.signal` rows.
- **Risk-distance ≈ range width**, so a $35 range = $35 risk = a single XAUUSD daily ATR (M15-window ~$20–$25 in NY). Mean reversion of just **1×NY-ATR** is enough to tag SL.
- **`atr_at_entry` NULL on every single session-breakout row** → strategy never even captures ATR for postmortem. That's a separate observability bug, but it confirms the SL has no ATR coupling.
- 4 winners had SL-distances $30–$72 — overlap with losers. **SL distance is not the discriminator**; what kills trades is that retracement back into the broken range is structurally normal price action, and the SL sits exactly there.
- Worst loser (#2ad8de2c, 08.5): held 57h, hit SL after weekend gap on long-trade SL at $4697.05 (= prior London-range low). Classic "buy the breakout high → weekend reversal back into range → SL at structural pivot that the next session naturally tests".

## Why this is fix-class = **proposal-required** (not direct bug-fix)

This is not a wrong-ATR-window or a sign-flip. The strategy was *designed* this way and *approved* on backtest evidence. Replacing SL methodology = strategy/risk change → operator + Karri review per binding 2026-05-08 protocol.

## Proposed change (draft — for Karri review)

File proposal `docs/strategy/proposals/2026-05-13_session_breakout_sl_method.md`:

**Option 1 (mild):** Cap SL distance at `min(range_opposite, 1.0×ATR_M15)`. Falls back to range-side only when ATR < range/2. Smaller losses on wide-range days.

**Option 2 (recommended):** Two-piece SL = `entry ± max(0.6×ATR_M15, recent_swing_low_M5)` instead of range opposite. Couples SL to micro-structure that the breakout is supposed to defend. TP retained at fixed-R but R is now atr-anchored.

**Option 3 (kill):** Disable `SESSION_BREAKOUT_ENABLED` until backtest re-validated on 2026-04 → 2026-05 live regime. Strategy may simply not survive current XAUUSD vol profile (NY-ATR has been ~$22 vs $14 backtest window).

**Observability fix (no proposal — implement now):** capture `atr_at_entry` on session-breakout signal publish. Currently NULL → blind postmortem. Same one-line plumbing as ORB/vol-exp already do.

## Caveat

OANDA_SL_TP can also fire on TP. I filtered by `pnl < 0` to isolate SL hits — 6 unambiguous SL closes. STALE_TRADE_EXIT (5) and PARTIAL_CLOSE (1) excluded; those are management exits not SL bug evidence.

## Recommended next step

File proposal Option 2 + ship the `atr_at_entry` observability fix immediately so next 7d give Karri real data to decide on. Do NOT auto-disable — Karri reviewing trend-pause hypothesis already; this is adjacent.
