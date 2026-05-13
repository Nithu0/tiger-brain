# S2 — Breakout Continuation deep-dive (2026-05-13)

## TL;DR

- **S2 today is "xau-session-breakout" (legacy)** — the new `xau-breakout-continuation` module landed 12.5 but only has 1 live trade. Dashboard's "Breakout Continuation (S2)" badge is mapped to the new module; the *behavior* operator is judging in the field is still the old session-breakout it was designed to replace.
- **Recent losses are not statistical noise — they fit a pattern.** Last 30 days: 15 trades, WR 30.8% (4W / 9L / 2BE), -$663.83, avg R +0.058. All 6 SL hits = -$1111; STALE_TRADE_EXIT close-bucket is near flat (+$11.66 across 6 trades). The strategy isn't bleeding from too-tight stops; it's bleeding from a few full-SL losses that hit when price reverses hard after entry.
- **Hypothesis: the bleed is consistent with Karri's trend-pause story.** The two worst SL hits (08.5 long $4741 → -$563, 12.5 short $4677 → -$386) both fired during portfolio_regime=TRENDING or against a clear higher-timeframe move, on a session-breakout that read pause/consolidation as the start of a new impulse. 2/2 trades with `portfolio_regime_at_entry=TRENDING` are losses. Sample tiny, but directionally aligned with the 152-trade analysis in `katastrofedag-analyse-2026-05-12.md`.

---

## What S2 is

**Code (new):** `apps/worker/src/firm/breakout-continuation/` — 8-filter pipeline: compression (ATR < 0.85 × 20-avg) → range (6-20 candles, < 1.2 × ATR) → breakout close → vol confirmation → retest → confirmation candle → anti-chase → session/cooldown. Default OFF in env per proposal; landed 12.5 but not active in production trade flow yet (1 trade total). Files: `breakout-continuation-manager.ts`, `config.ts` (19 env params, all clamped).

**Code (legacy, currently producing S2-labeled signals):** `firm-strategy:xau-session-breakout` is the live source emitting trades dashboard tags as S2 via the lineage backfill or via direct strategy_id. 14/15 closed trades in the 90-day window come from this source.

**Archetype:** breakout / momentum. Per `docs/strategy/proposals/2026-05-12_strategi_2_breakout_continuation.md`:
- Baseline WR claim: **35-45%**, avg R-multiple ≥ 2.0 on winners, max consecutive losses ≤ 3, no day-loss > $1000.
- Designed to fix the predecessor's "50% WR but negative PF" asymmetry by adding compression + retest + vol-confirmation filters.

**Gate deps:** session window (LONDON_ACTIVE, NY_CONTINUATION), ADX (trend-alignment when >30), cooldown 60min, daily cap 3, 2-losses-per-direction soft block. No regime_direction_gate hook visible in BC pipeline — it's a separate global gate.

---

## Baseline vs recent (90 days, 15 closed trades)

| Metric | Proposal target | Observed (last 30d) |
|---|---|---|
| WR (excl BE) | 35-45% | **30.8%** (4/13) |
| Avg R | +0.5+ implied | +0.058 |
| Total PnL | ≥ 0 over 14d | **-$663.83** |
| Avg win | – | +$210.52 |
| Avg loss | – | -$167.32 |
| Worst day | < $1000 | -$563 (08.5 single trade, RANGING-weekend hold) |

R-ratio collapses to ~1.26 win/loss while WR is 31% → expectancy negative. The proposal's 35-45% WR floor with avg-R 2.0+ winners would have produced +$ — current avg-R 1.26 + 31% WR is the exact "lower WR not compensated by R" failure mode.

Trade pacing: ~5 trades/week (close to the 3/day cap; not over-trading per se, but every shot matters more).

## Loss-pattern hypothesis (trend-pause aligned)

Of the 9 losses:
- 6 are **OANDA_SL_TP** (full SL hit) totaling -$1111. These are the bleed.
- 3 are STALE_TRADE_EXIT (small ticks, near flat).

Breakdown of the 6 SL hits:
- **08.5 long $4741 → -$563 (RANGING)**: held over weekend, max loss day. Friday-entry into RANGING tape that didn't continue.
- **12.5 short $4677 → -$386 (TRENDING)**: shorted into a NY-session breakout while portfolio regime was TRENDING. Classic counter-trend false-flip.
- 01.5 short $4561 → -$193 London (pre-NY reversal).
- 05.5 long $4584 → -$258 NY (faded into a TRENDING down move).
- 11.5 short $4669 → small (-$2.55) STALE under TRENDING.
- 29.4, 07.5 are small.

The 2 trades with `portfolio_regime_at_entry=TRENDING` are both losses; the 1 RANGING trade is the worst single loss. The remaining 12 trades have NULL regime tag (backfill gap), so the sample is thin — but the directional pattern matches Karri's hypothesis: S2 fires breakouts inside short pauses of a higher-TF move and gets run over when the move resumes. NY-session shorts are -$394 across 7 trades — the dominant bleed.

## Analysis-only next steps (no code changes)

1. **Backfill `portfolio_regime_at_entry` for the 12 NULL trades** — use `regime_snapshots` at `opened_at`. Then re-run the regime/outcome cross-tab on the full 15. If TRENDING-regime continues to underperform, that's actionable evidence for Karri.
2. **Mark each loss against H1+ EMA direction** (manual or via stored snapshots). Quantify "counter-H1-trend" share of the 6 SL hits. Hypothesis predicts ≥ 4/6.
3. **Compare new BC module's filter pipeline against the 6 SL hits**: would compression+retest+vol-confirmation have blocked them? Walk through `entry_snapshot` JSON if populated, or replay via raw-candle store.
4. **Quantify NY-shorts negative skew** — 7 trades, -$394, only 1 winner. Likely cluster-effect of trend-pause, but confirm before drawing structural conclusion.
5. **Confirm with Karri** before any tuning: this is the strategy his trend-pause hypothesis was framed around. Don't propose own changes (per memory rule).
