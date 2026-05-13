---
type: decision-tree
trigger: 4+ trades opened in single UTC day before 12:00 UTC
autonomy_level: report-only-during-day
---
# When Day Hits Overtrading Pattern

## Trigger
- 4+ trades opened in single UTC day before 12:00 UTC
- 5+ trades opened mid-day with net negative PnL
- Mixed-direction pattern within same session (flip-flop)

## Pattern Karri identified (12.5)
- **6 av 7 dager med ≥8 trades endte i tap** (-$13,225 total)
- Vinner-day-threshold: 6 trades
- TIER 3 better than legacy, but missing "trend-pause-bevissthet"

## Action by classification
- **4-5 trades pre-12:00 UTC**: log + watch, don't intervene
- **6+ trades pre-12:00 UTC**: REPORT to operator (overtrading risk signal)
- **8+ trades total**: high-confidence katastrofedag pattern
  - If DAILY_TRADE_CAP_ENABLED=true: gate kicks in automatically
  - Else: REPORT, never auto-disable per operator-prinsipp 1

## Examples from history
- 21.4: 10 trades all LONG → -$7,119 (legacy knife-catching)
- 22.4: 8 trades all LONG → -$3,722 (legacy chop)
- 6.5: 9 trades mixed → -$211 (TIER 3 flip-flop)
- 11.5: 8 trades → -$1,893 (today)

## Linked
[[Operator-Principles]], [[Foundation-Gate]]

External (ai-assistent repo):
- `docs/analysis/katastrofedag-analyse-2026-05-12.md` — full Karri pattern analysis (12.5)
- `docs/decisions/2026-05-12_daily_trade_cap.md` — daily trade-cap gate decision
