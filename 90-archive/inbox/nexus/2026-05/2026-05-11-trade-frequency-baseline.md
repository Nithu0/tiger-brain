# XAUUSD Auto-bot Trade Frequency Analysis
**Date:** 2026-05-11  
**Period Analyzed:** Last 30 days (2026-04-11 to 2026-05-11)  
**Question:** Is the bot supposed to fire more frequently than 2–5 trades/day?

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| **Median daily trades** | 7.5 |
| **25th percentile** | 3 |
| **75th percentile** | 9.75 |
| **Min daily** | 1 |
| **Max daily** | 24 |
| **Trading days (30d)** | 18 |
| **Zero-trade days (30d)** | 13 |
| **Total trades (30d)** | 150 |

---

## Daily Breakdown (Most Recent 18 Days)

| Date | Trades | P&L |
|------|--------|-----|
| 2026-05-10 | 7 | -1490.99 |
| 2026-05-07 | 1 | -563.64 |
| 2026-05-06 | 9 | -166.88 |
| 2026-05-05 | 9 | -211.17 |
| 2026-05-04 | 3 | -716.59 |
| 2026-05-03 | 6 | +2095.53 |
| 2026-04-30 | 8 | +494.51 |
| 2026-04-29 | 1 | -30.87 |
| 2026-04-28 | 6 | +794.32 |
| 2026-04-27 | 12 | -113.17 |
| 2026-04-26 | 3 | -8.91 |
| 2026-04-23 | 3 | +2414.78 |
| 2026-04-22 | 3 | -124.86 |
| 2026-04-21 | 8 | -3721.99 |
| 2026-04-20 | 10 | -7119.43 |
| 2026-04-19 | **24** | -105.55 |
| 2026-04-16 | **23** | +288.62 |
| 2026-04-15 | 14 | -138.95 |

---

## Trading Sessions (Hourly Distribution, Last 7 Days)

| Hour (UTC) | Trade Count |
|------------|-------------|
| 13:00 | **7** (peak) |
| 14:00 | 5 |
| 16:00 | 4 |
| 17:00 | 3 |
| 10:00, 11:00, 15:00, 18:00, 19:00 | 2 each |
| Sparse: 1:00, 3:00, 4:00, 6:00, 8:00 | 1 each |

**Session Activity:** Trading heavily concentrated in London open / AM hours (13:00–17:00 UTC). Sparse overnight activity.

---

## Verdict

**Is 2–5 trades/day the baseline?** No.

- **Expected range:** 3–10 trades/day (p25–p75)
- **Median:** 7.5 trades/day
- **Today (2026-05-11):** 7 trades (on track, within normal variance)

**Conclusion:**
1. The bot's **baseline is 7–8 trades/day**, not 2–5.
2. Days with 2–5 trades are **below-normal but not anomalous** (p25 = 3).
3. **Outlier days:** April 19 (24 trades, possible volatility spike) and April 16 (23 trades).
4. **13 zero-trade days** in 30-day window suggest scheduled downtime, market closure, or risk management pauses.
5. **Today is tracking normally** with 7 trades in ~18 hours elapsed.

**Operator expectation reconciliation:** If the operator expected 2–5/day, that baseline appears outdated. Current observed behavior is 1.5–3x higher on active trading days.

---

## Data Quality Notes

- All times in UTC (queries use `opened_at`)
- Bot identified by dominant `bot_id: 9b2f966c-09a9-46ec-bc6e-c7ae50fe1708` (140/150 trades)
- P&L aggregated but unfiltered (includes losing days, suggesting live risk exposure)
