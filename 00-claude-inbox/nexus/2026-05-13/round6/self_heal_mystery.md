# Self-heal mystery — 11.5 → 12.5 `regimeDirection=null` collapse

Round 6 forensic — investigator: Claude (Opus 4.7), 2026-05-13.

## TL;DR

**There was no self-heal. There was a deploy.** The TRENDING-`regimeDirection=null` rate did not "drop from 97.7% → 0%" because of market dynamics or a phantom fix. It dropped because commit `4c51309` (2026-05-11 20:08:25 UTC) **introduced** the `regime-direction.ts` classifier and the portfolio-brain wiring that publishes the field at all. The first blackboard message carrying the key `state.regimeDirection` is at **2026-05-11 20:26:20 UTC** — i.e. roughly when Railway finished deploying that commit. Every row before that has no `regimeDirection` key in `state`, so `state->>'regimeDirection' IS NULL` returns true vacuously. The A2 stat conflated "field absent (pre-deploy)" with "field present but null (post-deploy)". Confidence: **HIGH** (95%+). No code, env, or market mystery — pure deploy artifact.

## Inflection timestamp (hour-precision)

- **20:00–21:59Z 11.5** — first row with `regimeDirection` field present: **2026-05-11 20:26:20Z**. Regime was `MIXED_NO_EDGE` until 22:46Z so direction was correctly null (`not_trending`).
- **22:00Z 11.5** — first TRENDING hour after deploy: 2/2 rows have `regimeDirection="UP"` (0% null among TRENDING). First non-null direction: **2026-05-11 22:46:55Z**.
- From 12.5 00:00Z onward TRENDING-rows-with-field = TRENDING-rows-total (355/355 on 12.5).

## Top 3 candidates

### 1. Deploy of `4c51309` shipped the feature (CONFIRMED, ~95%)

`git show --stat 4c51309` shows the diff is the regime-direction-gate implementation (824 lines: `regime-direction.ts`, `gates/regime-direction-gate.ts`, portfolio-brain wiring, strategy-blade wiring, 27 new tests). The commit message is mislabeled `chore(env): document SL_COOLDOWN_*` due to a parallel-batch git race — documented retro in `dd0b1ba`. The mislabeling is what hid this from round 5.

Evidence FOR: timestamps align to the minute; pre-20:26Z rows have no `regimeDirection` key at all (verified with `state ? 'regimeDirection'`); diff adds exactly the `regimeDirection` and `regimeDirectionReason` publish in `portfolio-brain.ts:461-466`.

Evidence AGAINST: none.

### 2. Env-var flip on Railway (REJECTED)

The classifier runs unconditionally inside `portfolio-brain` whenever the regime is TRENDING — `REGIME_DIRECTION_GATE_ENABLED` only gates downstream gate enforcement, not the publish. No env-related commits in the inflection window other than `.env.example` doc syncs. Confidence: rejected.

### 3. Market regime change / candle-availability event (REJECTED)

The cross-period scan shows TRENDING rows existed every weekday from 29.4 onward (90, 0, 315, 0, 4, 296, 2, 601, 122, 28, 0, 7, 606, 355) with `trending_with_field=0` for ALL days before 11.5. There is no weekend-vs-weekday signal — weekends are simply low-message-count (OANDA closed) but TRENDING rows on weekends had the same "no field" behaviour as weekdays. Market-level explanation is incompatible with the evidence.

## Implication for monitoring

The C1-pivot regression-guard should NOT watch raw "TRENDING rows where `regimeDirection IS NULL` / total". That metric is a deploy-artifact for the first 24h after any classifier change.

What it SHOULD watch:

1. **`reason`-distribution among TRENDING rows.** Now that round-3 13.5 tagged `regimeDirectionReason`, alert on spikes in `candles_empty`, `fetch_error`, `non_finite_close`, `candles_not_array`, `candles_too_short_*`. A regression that breaks the H4 candle fetch will manifest as `candles_empty` or `fetch_error` jumping >5% over rolling 1h baseline.
2. **`flat_close_move` / `flat_ema_slope` baseline.** These are legitimate-null outcomes (price exactly flat across the 4-bar lookback). On XAUUSD this should be vanishingly rare (<0.5%); a sudden spike means either stale candles or a feed glitch.
3. **`state ? 'regimeDirection'` presence-check** as a deploy canary — alert if 0% of TRENDING rows in the last 10 min carry the field (regression that drops the publish entirely).
4. **Compute `direction != null` on TRENDING only post-deploy-canary**, not as a raw KPI. Pre-warm 30-min buffer after any worker restart before the alert arms (the first cycles after restart may legitimately have empty candle cache).

## One-line for round-7 / handoff

"The 11.5→12.5 self-heal is a measurement artifact: `4c51309` deployed at 20:08Z 11.5 introduced the field; pre-deploy rows lack the key and read as null in jsonb-path queries. The C1 regression-guard should watch `regimeDirectionReason` categories, not raw null-rate."

---

Verified queries — for replay:

```sql
-- Confirms feature did not exist pre-20:26Z 11.5
SELECT MIN(timestamp) FROM blackboard
WHERE topic='xauusd.portfolio.context' AND state ? 'regimeDirection';
-- → 2026-05-11 20:26:20.254Z

-- Confirms first non-null direction
SELECT MIN(timestamp) FROM blackboard
WHERE topic='xauusd.portfolio.context' AND state->>'regimeDirection' IS NOT NULL;
-- → 2026-05-11 22:46:55.720Z

-- Per-day check: trending rows with field present pre-12.5
SELECT date_trunc('day', timestamp) AS d,
       COUNT(*) FILTER (WHERE state->>'regime'='TRENDING') AS trending,
       COUNT(*) FILTER (WHERE state->>'regime'='TRENDING' AND state ? 'regimeDirection') AS w_field
FROM blackboard WHERE topic='xauusd.portfolio.context'
AND timestamp >= '2026-04-25' AND timestamp < '2026-05-13'
GROUP BY d ORDER BY d;
-- All days before 11.5: w_field = 0. 11.5: 14/606. 12.5: 355/355.
```

Commits referenced: `4c51309` (real implementation, mislabeled), `dd0b1ba` (retro doc that names 4c51309 as the impl), `1661bc6` (the SL_COOLDOWN doc-only commit at the same timestamp on the OTHER branch — parallel-batch race produced two commits with adjacent SHAs but different content).
