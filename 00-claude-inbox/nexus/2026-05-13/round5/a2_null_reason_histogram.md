# A2 null-reason histogram — Round 5 deep-dive

**Window**: 2026-05-13 07:54:01Z (A2 deploy) → 09:18:47Z (~85 min)
**Rows**: 78 portfolio.context messages, 100% with `regimeDirectionReason` field present (A2 deploy confirmed live)

---

## TL;DR

**Dominant reason: `not_trending` (78/78 = 100%).**

**Karri-recommendation: NONE OF A/B/C — the C1 premise is gone.** The post-A2 window contains zero TRENDING regimes, so the classifier hasn't been forced to make a direction call yet. But the broader data tells a much more important story:

- **2026-05-11**: TRENDING with `direction=null` = 592/606 = **97.7%** (the original Round-2 finding)
- **2026-05-12**: TRENDING with `direction=null` = **0/355** (0%)
- **2026-05-13**: TRENDING with `direction=null` = **0/46** (0%)

**The classifier already self-healed between 05-11 16:00Z and 05-11 22:00Z** (last-null hour → first-OK hour). The 97.7% null-rate Karri is being asked to gate against no longer exists in production. The C1 proposal (null-direction-block) is solving yesterday's bug.

Action item for Karri: re-frame C1 as a **regression guard** ("alert if null-direction rate climbs back above X%"), not a blocking gate. The latter would be a no-op today.

---

## Histogram (post-A2 window only)

| reason | regime | direction | rows | % |
|---|---|---|---:|---:|
| `not_trending` | RANGING | null | 78 | 100.0% |

Single-bucket result. No TRENDING regime occurred during the 85-min sample, so no `flat_close_move`, `flat_ema_slope`, `candles_empty`, `candles_too_short_*`, `fetch_error`, or `non_finite_close` reasons were exercised. All 9 instrumented null-paths are dormant in this window because the precondition (regime=TRENDING) never fired.

Note: `not_trending` is **the correct null** — when regime is RANGING/MIXED/HIGH_VOLATILITY, "direction" is semantically meaningless. C1 should already treat this case as expected, not as a bug.

---

## Wider context: TRENDING by day

| day | TRENDING total | direction=UP | direction=DOWN | direction=null | null-rate |
|---|---:|---:|---:|---:|---:|
| 2026-05-10 | 7 | 0 | 0 | 7 | 100.0% |
| 2026-05-11 | 606 | 14 | 0 | 592 | **97.7%** |
| 2026-05-12 | 355 | 206 | 149 | 0 | **0.0%** |
| 2026-05-13 | 46 | 46 | 0 | 0 | **0.0%** |

The 11.5 → 12.5 transition is binary. Hour-resolution view confirms a clean inflection:

| 2026-05-11 hour (Z) | TRENDING null | TRENDING OK |
|---:|---:|---:|
| 00–16 | 591 | 0 |
| 22 | 0 | 2 |
| 23 | 0 | 12 |

Last null TRENDING at 16:00Z; first OK TRENDING at 22:00Z on the same day. No commits in that exact 6h window are obviously "fix classifier direction" — the likely candidates (`1790a75 fix(postmortem): wire regime + analyst-direction…`, `a2f1cbc fix(strategy-exec): wire …regime_at_entry`) landed earlier in the day. A Railway redeploy or env flip somewhere in 16–22Z is the better hypothesis. **Worth confirming** by checking Railway deploy log for 11.5 evening.

---

## Mapping to C1 options (if the bug returns)

The reason-categories Round 3 instrumented map to the proposals as follows:

| reason | semantic | Option A (hard-block) | Option B (M15 fallback) | Option C (soft-degrade) |
|---|---|---|---|---|
| `not_trending` | correct null (not a bug) | n/a — never hits C1 | n/a | n/a |
| `candles_empty` | data outage upstream | over-blocks (loses signal) | **best fit** — refetch / use M15 | conservative |
| `fetch_error` | transient broker/DB failure | over-blocks | **best fit** — retry path | acceptable |
| `flat_close_move` | trend exists but close-delta ~0 | over-blocks valid trends | helpful — alt measure (EMA slope) | acceptable |
| `flat_ema_slope` | trend exists but EMA flat | over-blocks valid trends | helpful — alt measure (close-delta) | acceptable |
| `candles_too_short_*` | cold-start, <N bars | over-blocks first ~N minutes after start | partial fix only | **best fit** — degrade gracefully |
| `non_finite_close` | NaN/Inf in price input | correct to block (data bug) | n/a — fix the bug | n/a |

**Theoretical recommendation if the 97.7%-null bug recurs**: Option B for `candles_empty` + `fetch_error` (data-availability paths), Option C for cold-start, and a separate bug-fix track for `non_finite_close`. Pure Option A (hard-block) is the wrong shape — it over-blocks the data-availability and flat-measure categories.

**Empirical recommendation today**: hold C1. The bug fixed itself. Replace the proposed gate with a Discord-alert health-check ("regimeDirection null-rate in TRENDING > 10% over 1h → ping Karri").

---

## Caveats

1. 85 min of post-A2 data is short — if a TRENDING regime emerges later today and the classifier degrades again, the reason-histogram becomes the diagnostic Round 3 promised. Worth re-running this query at end-of-day Europe session.
2. The 11.5 → 12.5 fix is unidentified. Recommend short audit: `git log --since="2026-05-11 16:00" --until="2026-05-11 22:00"` on worker + ops files, and Railway deploy timeline for that window. If we can't name the fix, we can't guarantee it's stable.
3. The Round-2 "97.7% null" was a real symptom. Don't dismiss the C1 proposal — frame it as observability + regression guard, not a runtime gate.

---

**Files**:
- `apps/worker/src/firm/classifier.ts:classifyTrendDirection()` — instrumented in Round 3 / A2
- `docs/strategy/proposals/` — C1 lives here pending decision
