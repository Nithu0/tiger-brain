# Trend-Pause Detection: Feasibility Analysis

**Date:** 2026-05-12  
**Analyst:** Claude Code (investigation)  
**Source:** `/home/nithu/code/ai-assistent/docs/ops/katastrofedag-analyse-2026-05-12.md`  
**Scope:** Read-only investigation — no implementation

---

## 1. Karri's "Trend-Pause" Definition

From the disaster analysis (6.5 incident):

**A trend-pause occurs when:**
- Market has been trending clearly in one direction (e.g., TRENDING_UP)
- Price consolidates/chops sideways briefly (pause in momentum, not reversal)
- **During this pause, the system rapidly flips direction signal 4+ times within 3 hours**
- Each flip triggers counter-trend mean-reversion trades
- Most of these trades lose (−$2484 on 5 consecutive losses)

**Key characteristic:** The trend is NOT reversing — it's pausing. But our regime-direction classifier sees the chop and flips UP→DOWN→UP→DOWN, catching the false signals rather than the real trend resumption.

From Karri's analysis (line 233-234):
> "All 3 katastrofer = strategien har ikke 'vet jeg er i trend / chop / pause?'-state. Når trend pauser, blir den blind."

**Translation:** When trend pauses, the system becomes blind to state.

---

## 2. Current Detection Capability

### What We Have NOW

**Portfolio Brain (portfolio-brain.ts):**
- Publishes `regimeDirection: "UP" | "DOWN" | null` on `xauusd.portfolio.context`
- Only computed when `regime === "TRENDING"` (via H4 4-bar close-move or EMA-slope)
- Filters out non-trending regimes to avoid false classifications

**Analyst Snapshots (strategy-snapshot.ts):**
- Captures per-strategy `direction` field every cycle
- Published direction is stored but no aggregation/change-tracking

**ATR Availability:**
- `atr_at_entry` captured in `simulated_orders` table
- Also available in strategy-execution.ts proposal state
- No historical ATR series or contraction detection

**What's Missing:**
- No tracking of `regimeDirection` changes over time
- No consolidation/pause detection (tight-range detection)
- No ATR-contraction vs recent-ATR comparison
- No direction-flip counter within a time window

---

## 3. Candidate Detection Signals

### Signal 1: Rapid Direction Flips

**Detection Logic:**
```
Count regimeDirection changes in last 30 minutes
IF changes >= 3 THEN pause_likely = true
```

**Source:** `regimeDirection` from `xauusd.portfolio.context.state` (blackboard)  
**Effort:** LOW — already published, just need to track history (3-message circular buffer)  
**Threshold:** 3+ flips in 30 min suggests consolidation  
**Reliability:** MODERATE — can trigger on chop that briefly looks like reversals

### Signal 2: ATR Contraction

**Detection Logic:**
```
current_atr < (median_atr_last_24h * 0.6)
=> consolidation detected
```

**Source:** ATR from `xauusd.analysis.technical` (blackboard) or `simulated_orders.atr_at_entry`  
**Effort:** MEDIUM — need to compute rolling median ATR (DB aggregation or in-memory)  
**Threshold:** <60% of 24h median = strong consolidation  
**Reliability:** HIGH — ATR contraction is objective and well-correlated with chop

### Signal 3: Price Range Compression

**Detection Logic:**
```
(high - low) over last N candles < some threshold (e.g., $3-5 for XAUUSD)
=> price is range-bound, not moving directionally
```

**Source:** Candle data (H1 or M15) from market-data.service  
**Effort:** MEDIUM — requires candle fetch + range calc  
**Threshold:** <$3 range on H1 = tight, consolidating  
**Reliability:** HIGH — direct measurement, not derived

---

## 4. Feasibility of Phase 1 Instrumentation

### Recommended Phase 1 Approach

**Goal:** Detect "trend-pause" moments with existing analyst snapshots, log for review.

**Implementation:**
1. Add `trend_pause_detected` field to `blackboard` table (BOOLEAN, nullable)
2. In orchestrator cycle (after regime classification, before strategy execution):
   - Fetch last 6 `xauusd.portfolio.context` messages
   - Count `regimeDirection` flips in last 30 min
   - Fetch latest ATR from `xauusd.analysis.technical`
   - If flips >= 3 OR (ATR < threshold) → set flag
3. Publish new message: `xauusd.portfolio.trend_pause_signal`
4. Write instrumentation logs to `firm_memory` table with tags: `["trend-pause", "consolidation"]`
5. Dashboard query: show count of pause-detected cycles per day

**Code Location:** `apps/worker/src/firm/portfolio-brain.ts` (extend `classifyRegime` function)

**DB Schema Change:** None required (use existing blackboard table)

**Effort Estimate:**
- Code: ~100 lines (flip counter, ATR fetch, publish)
- Tests: ~50 lines
- Total: 3-4 hours implementation
- No migration, no rollback complexity

---

## 5. Can We Implement Phase 1 with Current Signals?

**YES, with caveats:**

**✓ Rapid Direction Flips**
- `regimeDirection` is already published every cycle
- Can track history via simple in-memory circular buffer
- No new instrumentation needed

**~ ATR Contraction**
- ATR is published on `xauusd.analysis.technical`
- Would need rolling aggregation (compute 24h median)
- Alternative: Use `atr_at_entry` from closed trades + recent snapshots

**✗ Price Range Compression**
- Requires candle-level data series (not yet aggregated)
- Would add latency if fetched per-cycle
- Lower priority for Phase 1

---

## 6. Why This Matters for Karri

From the disaster analysis:

| Day | Issue | Current Detection | With Phase 1 |
|---|---|---|---|
| 6.5 | 4 direction flips in 3h, −$2484 | Regime stays TRENDING | Alerts: pause detected, cooldown triggered |
| 6.5 | ATR likely compressed during chop | No visibility | Can show: "ATR < threshold" |

**Phase 1 Impact:** Not a fix, but **visibility**. Karri can see:
1. When trend-pauses occur
2. Frequency and duration (consolidation windows)
3. Correlation with losses (is the pause always followed by loss-streak?)
4. Which strategies suffer most during pauses

---

## 7. Recommended Proposal Scope

### Option A: Phase 1 — Instrumentation Only
**Timeline:** 1 spike (4 hours)  
**Output:** Daily trend-pause summary + backtest query  
**Risk:** Very low — read-only instrumentation  
**Next:** After 3-5 days of logs, decide if we need gating or just observation

**Proposal File:**
- `docs/strategy/proposals/2026-05-12_trend_pause_instrumentation.md`
- Status: READY FOR IMPLEMENTATION
- Estimated impact: Visibility only (no PnL change, but enables better gating)

### Option B: Phase 2 — Gating (Conditional)
**Depends on:** Phase 1 logs + Karri review  
**Gate Logic:** When pause detected → raise SL_COOLDOWN duration from 60m to 120m?  
**Risk:** Medium — changes behavior without confirmed hypothesis  

### Option C: Await Karri Review
**If:** Karri thinks Phase 1 instrumentation isn't the right approach  
**Alternative:** Karri may prefer pause-detection in the regime classifier itself (Trend + Pause state)

---

## 8. Summary Table

| Aspect | Status | Effort | Risk | Feasibility |
|---|---|---|---|---|
| **Rapid direction flips** | Implementable | LOW | LOW | ✓ Ready |
| **ATR contraction** | Implementable | MEDIUM | LOW | ✓ Ready |
| **Range compression** | Implementable | MEDIUM | LOW | ✓ Possible |
| **Phase 1 scope** | Clear | 4h | Very Low | ✓✓ Go |
| **Phase 2 (gating)** | Pending | 8h | Medium | ~ After review |
| **Full trend-state** | Complex | 16h | Medium | ~ Strategy proposal |

---

## Recommendation to Karri

**Immediate next step:** Phase 1 — implement trend-pause instrumentation
- No behavior change
- Run for 3-5 days to validate hypothesis
- Builds confidence for Phase 2 gating decisions

**Timeline:** Present proposal `2026-05-12_trend_pause_instrumentation.md` for approval, then implement.

**Success metric:** By 2026-05-17, see:
- Trend-pause events logged daily
- Correlation with loss-streaks confirmed or refuted
- Recommendation for Phase 2 scope (if any)
