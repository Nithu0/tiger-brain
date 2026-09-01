---
date: 2026-05-11
type: verification
status: NOT-DEPLOYED
commit: 6bdd38a
verdict: data-starved + deploy-pending
---

# Postmortem reclassifier (commit 6bdd38a) — verification

## TL;DR

**Fix is NOT live in production yet.** Railway `/health` reports `build.commit = a2f1cbc8`, which is the commit BEFORE `6bdd38a`. Only one postmortem has run since 15:00Z (the 16:43:48Z one), and it was produced by the old binary — none of the 6 new evidence fields are present.

Verdict: cannot verify classifier upgrade until Railway redeploys. No regression observed (the new code passed tsc and tests locally, but it has not been exercised against live data).

## Evidence

### Production build state
- `GET https://api-production-b660.up.railway.app/health` → `build.commit = "a2f1cbc8"`
- `a2f1cbc` is 1 commit older than `6bdd38a` on `main`
- Worker `lastCycleNo=98`, `lastHeartbeatSec=109` → process is healthy, just on old code

### Trade volume since 15:00Z deploy window
- `postmortems` rows since `2026-05-11T15:00:00Z`: **1**
- `firm_memory` postmortem rows in same window: **1** (trade-postmortem) + 2 trade-critic aggregations
- That one trade: `2320fd49…` — `xau-volatility-expansion`, LONG, TRENDING regime, `OANDA_SL_TP`, pnl `-527.40`, closed 16:43:43Z, postmortem ran 5s later at 16:43:48Z

### Evidence-fields wire-through check
Query: `firm_memory.evidence->>'marketRegimeAtEntry'`, `…->>'techDirectionAtEntry'`, `…->>'macroDirectionAtEntry'`, `…->>'counterTrend'`, `…->>'macroContradicts'`, `…->>'decisionCycleMatched'` across last 10 trade-postmortems.

Result: **all six fields NULL in every row, including the 16:43:48Z post-deploy-window row.** Confirms old binary still running.

Pre-existing evidence keys (`failureClass`, `marketThesisScore`, `executionWindowScore`, `wasChasing`, `closeReason`, `aiReview`, `managementClass`, `eventReview`) are all populated as before.

### Classification of the post-15:00Z trade

| Field | Value |
|---|---|
| trade_id | 2320fd49-1442-45f3-8c57-59d2caaf7ecb |
| strategy | xau-volatility-expansion |
| direction | long |
| close_reason | OANDA_SL_TP |
| portfolio_regime_at_entry | TRENDING |
| pnl | -527.40 |
| classification | RIGHT_THESIS_BAD_EXECUTION |
| marketThesisScore | 0 |
| executionWindowScore | 0 |
| entryThesisScore | 0 |

This trade is NOT a wrong-thesis case — direction (long) matched the trending-up regime and the contemporaneous tech direction (long, score 4 at 14:29Z). Even if `6bdd38a` had been live, `counterTrend` would have been `false` and classification would still have landed elsewhere — likely the `directionCorrect && !isSlLikeClose` branch, or fallen through to BAD_EXECUTION. The market-score=0 is the more interesting symptom — it suggests the decision-match still wasn't finding the right cycle (the new `decisionCycleId` plumbing would have fixed that if running).

### Would the fix have caught the 3 earlier scalp-overlap shorts?
Cross-checked against `xauusd.analysis.technical` snapshots in the 13:14–13:35Z window where those 3 SHORT trades opened:

| Trade open | tech direction |
|---|---|
| 13:14:31Z (entry) | short / neutral |
| 13:19:59Z (entry) | neutral |
| 13:33:04Z (entry) | neutral |

Tech direction was `neutral` or `short` at those entry times, NOT `long` as one might infer from a daily-trend view. With the new classifier:
- `regimeIsTrending` = true (TRENDING regime)
- `techDirection` ∈ {neutral, short}, `trade.direction = short`
- `counterTrend = regimeIsTrending && techDirection != null && techDirection !== "neutral" && techDirection !== trade.direction` → **FALSE** (either neutral, or same direction)
- So the fix as written would NOT have re-tagged those 3 as WRONG_THESIS based on tech-direction alone.

**This is a gap.** The narrative "counter-trend SHORT in trending-UP" was based on the daily/macro trend, not per-cycle tech. To catch those, the classifier would need to also consult `portfolio_regime_at_entry` direction (TRENDING-UP vs TRENDING-DOWN — but `portfolio_regime_at_entry` in this schema is just `TRENDING` with no direction) OR a longer-timeframe analyst snapshot. Macro was `long` at the time — `macroContradicts` would have been TRUE, but in the current code `macroContradicts` only adds a lesson, it does NOT trigger WRONG_THESIS by itself.

## Recommendations

1. **Operator action:** confirm Railway has redeployed `6bdd38a` (or push if it didn't auto-deploy). Re-run this verify script after the next trade closes.
2. **Classifier gap:** consider promoting `macroContradicts && regimeIsTrending` to trigger WRONG_THESIS as well, OR enrich `portfolio_regime_at_entry` with a direction component. Strategy proposal scope (Karri review).
3. **Data starvation:** 1 trade in ~3h is too thin for verdict either way; even after deploy lands, allow 24h of trade flow before declaring fix-working.

## Re-verify checklist (post-redeploy)

- [ ] `/health` `build.commit` = `6bdd38a` or later
- [ ] At least one new postmortem in `firm_memory` with `evidence->>'marketRegimeAtEntry'` IS NOT NULL
- [ ] `evidence->>'decisionCycleMatched' = 'true'` on most rows
- [ ] At least one WRONG_THESIS classification on a counter-trend SL'd trade
