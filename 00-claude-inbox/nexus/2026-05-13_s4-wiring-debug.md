---
date: 2026-05-13
type: investigation
project: nexus
status: open
---

# S4 Mean-Reversion — wiring debug (read-only diagnosis)

## TL;DR

**Wiring is complete and the strategy IS running.** 253 evaluations on `xauusd.mean-reversion.state` since 00:44 UTC 2026-05-13. The reason for 0 trades is **not a wiring bug** — it's a market-condition issue: impulse magnitudes have not exceeded the 1.5 ATR threshold today. Loosen `MR_IMPULSE_THRESHOLD_ATR` (e.g. 1.2-1.3) or wait — no code fix needed.

## What's wired (verified)

1. **Orchestrator Step 1i** (`apps/worker/src/firm/orchestrator.ts:430-443`)
   - Imports `evaluateMeanReversionEntry` (line 53) + `isMeanReversionEnabled` (line 54).
   - Calls evaluator inside the env-flag check; uses fresh `xauusd.market.raw` price fact. Identical pattern to S1/S2/S3.

2. **Strategy-execution config-entry** (`apps/worker/src/firm/strategy-execution.ts:146-152`)
   - `strategyId: "xau-mean-reversion"` — matches the operator's expected ID.
   - `topic: MR_TOPICS.signal` (= `xauusd.mean-reversion.signal`) — execution bridge listens on the right topic.
   - Env vars: `MEAN_REVERSION_MAX_OPEN_POSITIONS`, `MEAN_REVERSION_DAILY_LOSS_LIMIT_USD`, `MEAN_REVERSION_RISK_PCT`.

3. **Module surface** (`apps/worker/src/firm/mean-reversion/`)
   - `config.ts` — `isMeanReversionEnabled()` reads `process.env.MEAN_REVERSION_ENABLED === "true"`.
   - `mean-reversion-manager.ts` — emits `state` (always, every cycle) + `signal` (only on PROPOSAL). State emits include reject reason for observability.
   - `MR_ALLOWED_SESSIONS = { NY_CONTINUATION, LONDON_ACTIVE }`.
   - No early-exit on missing env; always emits state.

4. **Git log**
   - `8fb60b1` feat(mean-reversion): STRATEGI 4 — counter-trend MVP (default OFF)
   - `d4f38f0` Merge PR #23
   - `310054c` tune(mean-reversion): sweet-spot defaults from 6mo backtest (PR #24)
   - `b2f994a` feat(dashboard/signals): S4 badge

## Live evidence — env flag IS on and strategy IS running

`blackboard` query: `xauusd.mean-reversion.state` has **253 rows** since 2026-05-13 00:44 UTC, most recent 09:18 UTC. If `MEAN_REVERSION_ENABLED` were false the early-exit at `mean-reversion-manager.ts:139-141` would have returned without publishing state — but we see state being published every cycle (≈ every 65s). **Conclusion: env flag is live.**

`xauusd.mean-reversion.signal` (PROPOSAL topic) row count: **0**. No PROPOSAL has ever been emitted → execution bridge has nothing to consume → 0 trades, 0 snapshots tied to this strategy, 0 gate_decisions. This is consistent with the operator's symptoms and confirms the bottleneck is *upstream* of the execution bridge.

## Reject-reason breakdown (253 evaluations)

| Reason | Count | Window (UTC) | Note |
|---|---|---|---|
| `session_not_allowed` | 153 | 00:44 - 07:29 | ASIA + LONDON_PREPARE + LONDON_OPENING_RANGE — all expected outside `{NY_CONTINUATION, LONDON_ACTIVE}` |
| `rsi_not_overbought` | 54 | 08:01 - 08:59 | Inside session, but RSI never hit ≥ 60 (no overbought setup) |
| `impulse_too_small` | 46 | 07:30 - 09:18 | Impulse-magnitude failed `≥ 1.5 ATR` filter |

Impulse-magnitude distribution (when it was the reject reason):
- `< 1.0 ATR`: 28 (61%)
- `1.0–1.2 ATR`: 0
- `1.2–1.4 ATR`: 16 (35%)
- `1.4–1.5 ATR`: 2 (4%)
- max observed today: **1.49 ATR** (one tick below threshold)
- avg: 1.11 ATR

## Most-likely root cause

**Market regime today is too quiet for the 1.5 ATR threshold.** Sweet-spot tuning (PR #24) was based on a 6-month backtest. Today's H1 candles have not produced impulses ≥ 1.5 ATR over the 2-candle lookback. Combined with overlapping ADX < 25 + RSI > 60/< 40 filters, the strategy is correctly waiting.

Secondary observation: `MR_ALLOWED_SESSIONS` excludes much of the day (~60% of evaluations were outside the window). For 24h coverage assessment, this is by design — but it does reduce trade opportunities. Karri-decision whether to add `OVERLAP_ACTIVE`.

## What would unblock S4 (operator decisions, do not auto-do)

1. **Loosen impulse threshold** — flip `MR_IMPULSE_THRESHOLD_ATR=1.2` on Railway. With current data, that would have produced ~18 candidates today (those in 1.2–1.5 buckets) for downstream RSI/ADX filtering. **Karri-review required** — this is a strategy-tuning change.

2. **Wait for higher-vol day** — no action; today is genuinely quiet. The 6mo backtest had 54 trades = ≈ 1 trade per 3.3 trading days at 1.5 ATR. Zero on day 1 live is within normal distribution.

3. **Expand allowed sessions** — adding `OVERLAP_ACTIVE` (London-NY overlap, typically the highest-vol window) would increase coverage by ~3 hr/day. Karri-review required.

4. **Sanity-check ATR calc** — if `fetchATR("XAUUSD", "1h", 14)` is returning too high a value vs reality, the ATR-normalized impulse would look small. Worth spot-checking from a separate ATR source. Low-priority — the relative ordering across strategies looks reasonable.

## Files touched (read only — no edits)

- `apps/worker/src/firm/orchestrator.ts` (lines 53-54 imports, 430-443 Step 1i)
- `apps/worker/src/firm/strategy-execution.ts` (lines 44, 146-152)
- `apps/worker/src/firm/mean-reversion/config.ts` (full file)
- `apps/worker/src/firm/mean-reversion/index.ts` (full file)
- `apps/worker/src/firm/mean-reversion/mean-reversion-manager.ts` (full file)
- `apps/worker/src/firm/session-window.ts` (state enum check)
- `docs/ops/2026-05-13_evening_handoff.md` (deploy claims verified)

## DB queries used (for audit)

```sql
-- Confirm strategy is emitting state every cycle (proves env flag is on)
SELECT topic, COUNT(*) FROM blackboard
WHERE topic LIKE '%mean-reversion%' GROUP BY topic;
-- → state: 253, signal: 0

-- Reject-reason breakdown
SELECT (CASE bucket logic on thesis) AS reason, COUNT(*)
FROM blackboard WHERE topic = 'xauusd.mean-reversion.state' GROUP BY reason;

-- Impulse-magnitude distribution from rejected events
SELECT bucket, COUNT(*) FROM (
  SELECT REGEXP_MATCH(thesis, 'impulse_too_small: ([0-9.]+) ATR')[1]::float AS atr
  FROM blackboard WHERE thesis LIKE 'impulse_too_small%'
) t GROUP BY bucket;
```
