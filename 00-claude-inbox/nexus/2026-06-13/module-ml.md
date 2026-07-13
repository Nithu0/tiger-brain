# Module ML — López de Prado on Nexus

Analysis + spec only. No code shipped. Source: *Advances in Financial Machine Learning* (López de Prado, 2018).
Author: Claude (ML module). Date: 2026-06-13. Reviewer for any trade-altering switch: **Karri**.

---

## 0. TL;DR

Nexus has, almost by accident, already built most of the *plumbing* López de Prado prescribes — it just hasn't been named or formalized as ML. The shadow forward-test is a hand-rolled **triple-barrier labeler**. The conviction layer is a **primary model**. The lesson-derivation clusters are crude **meta-labels**. The calibration `SHADOW_COMPARE` mode is **walk-forward eval** without the purging.

The single highest-leverage move is **Meta-Labeling**: train a second model that takes the firm's existing primary signal (conviction direction) + context features (regime, ADX, session, macro) and outputs a calibrated **P(win)**, which then feeds sizing and the gate layer. It is the highest leverage because:

1. It reuses data already captured (no new collection needed).
2. It plugs straight into two existing seams — the conviction score and the position-sizing chain — without redesigning the firm.
3. It is the one López de Prado method that *directly raises the Sharpe of an existing signal* rather than just improving model hygiene.

**Hard constraint:** only ~200 closed trades exist (202 in the export, ~173 with clean risk basis). That is too thin for heavyweight ML and demands purged CV + a deliberately simple model (logistic regression, not a deep gradient-boost). Everything that *gates or sizes a live trade* is Karri/operator-gated. Everything that *labels, trains offline, and shadow-evaluates* is Claude-infra and can be built now.

---

## 1. Method-to-existing-system map

| López de Prado method | What it is | What Nexus already has | Gap to formalize |
|---|---|---|---|
| **Triple-Barrier labeling** | Label each event by which of {upper barrier (TP), lower barrier (SL), vertical barrier (time)} is hit first | `shadow-log.ts` already resolves `tp_hit / sl_hit / expired` against candles; `simulated_orders.close_reason` (TP_HIT/SL_HIT/STALE_TRADE_EXIT) + `result_r` are exactly the three-barrier outcomes | Make the labeler a standalone, candle-driven offline function over `ohlcv_candles` (not the coarse spot-mid proxy `shadow-log` uses); add proper vertical-barrier and per-bar high/low penetration |
| **Fractional Differentiation** | Difference a series *just enough* to be stationary while keeping memory (vs. full first-difference which discards memory) | Nothing. Features today are raw levels (`entry_price`, cross-asset levels) or already-bounded indicators (RSI, ADX, conviction 0–1) | Apply frac-diff to the *price-level* features (XAUUSD, DXY, SPY, silver) before they enter any model. Low priority — most useful features are already stationary-ish |
| **Meta-Labeling** | A **secondary** binary model that decides whether to *act on* a primary model's signal (and how big), trained on whether the primary signal would have won | Primary model = tiered conviction (`conviction/scoring.ts`, direction ±1). Crude meta-label proxy = lesson clusters (`derive-lessons.mjs`: WR per regime×session×close_reason → reject_or_size_down) | Replace the by-hand cluster rule with a learned P(win) model over the full feature vector. **This is the #1 build.** |
| **Walk-Forward validation** | Train on past, test on strictly-future, roll forward — never test on data older than training | `calibration.ts` `SHADOW_COMPARE` mode runs calibrated logic in parallel forward; predictions agent does daily forward stratified means | No formal walk-forward harness over the trade set. Need rolling train/test split by `opened_at`. |
| **Purged Cross-Validation** | Remove training samples whose label-window overlaps the test set (purge) + drop adjacent samples (embargo) to kill leakage from overlapping outcomes | Nothing — there is no CV at all today | Essential here precisely *because* sample size is tiny: naive k-fold on 173 trades will overstate accuracy badly. Purge by trade holding-period overlap + embargo a few bars. |

### The deeper point
Nexus's whole "firm" is a primary-model factory. Every strategy (ORB, scalp-overlap, session-breakout, vol-expansion) emits a directional signal; conviction fuses them into one direction + magnitude. López de Prado's central architectural recommendation is exactly this **separation of concerns**: let the primary model chase *recall* (find every plausible trade), and let a meta-model supply *precision* (decide which to actually take, and size). Nexus is one model away from that architecture.

---

## 2. Why Meta-Labeling is the #1 leverage now

**Claim:** of the five methods, meta-labeling is the only one that *raises the expectancy of the live signal* using data already on disk, and it lands in seams that already exist.

1. **The conviction layer is begging for a precision filter.** Today conviction direction sets the trade direction and a set of soft gates (`new-gates.ts`) + thesis-quality thresholds decide go/no-go. Those gates are hand-tuned WR rules. A meta-label model is the principled generalization: instead of "if RANGING and |conviction|<0.05 and thesis<60 then block", learn `P(win | regime, conviction, ADX, session, macro, ...)` and block/shrink when it's low.

2. **It uses the data we already collect, end-to-end.** Features live in `simulated_orders.entry_snapshot` + `market_snapshots` (RSI/ADX/MACD/cross-asset) + conviction columns. Labels come from the triple-barrier outcome we already compute (`result_r`, `close_reason`). No new instrumentation.

3. **It composes with sizing cleanly.** The sizing chain in `strategy-execution.ts` is multiplicative: `dollarRisk = balance × riskPercent × sizeChain × sizingModifier × newsBoost`. P(win) (or a Kelly-fraction derived from it) drops in as one more bounded multiplier — exactly the rollback-safe, env-gated shape operator wants. No structural change.

4. **Meta-labeling is robust on thin data — by design.** It is a *binary* problem (act / don't act) layered on top of an already-decent primary signal. You are not asking the model to predict direction from scratch (hard, needs lots of data); you are asking "given the firm already wants to go long here, will it win?" — a much lower-variance target. This is precisely the regime López de Prado recommends meta-labeling for: improve precision of an existing model without betting the farm on data volume.

5. **It dovetails with the calibration philosophy already in place.** `CALIBRATION_MODE` already has `RECOMMEND_ONLY → SHADOW_COMPARE → SAFE_AUTO_APPLY`. The meta-label scorer rides the same ladder: log-only → shadow-compare against actuals → (Karri-gated) live sizing influence.

**Why not the others first:** Frac-diff helps feature quality but most features are already bounded — marginal. Walk-forward + purged CV are *enablers* (you need them to trust the meta-model), not standalone wins — they ship *as part of* the meta-label build. Triple-barrier is mostly already done in spirit. So meta-labeling is both the payload and the thing that pulls the rest in.

---

## 3. Concrete meta-labeling pipeline

```
                        OFFLINE (Claude-infra, build now)
  ohlcv_candles (15m) ─┐
                       ├─► [A] Triple-Barrier Labeler ──► label y ∈ {0,1}  (win = TP-first)
  simulated_orders ────┘        (per closed trade: did TP barrier hit
        │                        before SL or vertical/time barrier?)
        │
        ├─ entry_snapshot ─┐
  market_snapshots ────────┤
   (RSI/ADX/MACD/EMA/      ├─► [B] Feature Builder ──► X  (one row per trade)
    ATR/cross-asset)       │      features: conviction_total/direction/timing,
  conviction_* columns ────┘      regime (1-hot), session (1-hot), ADX, ATR,
        │                          RSI, macro/cross-asset deltas, strategy_id,
        │                          hour-of-day, news_state
        ▼
  [C] Purged + Embargoed CV split  (by opened_at; purge overlapping
        │                           holding windows; embargo k bars)
        ▼
  [D] Model: start LogisticRegression (calibrated, class-weighted)
        │   later: shallow gradient-boost ONLY if data grows + CV holds
        ▼
  [E] Output: P(win) per trade, isotonic/Platt-calibrated
        │
        ▼
  [F] Shadow eval: walk-forward, compare P(win)-gated vs actual book
        │  metrics: precision/recall at threshold, Brier score, R uplift,
        │           Sharpe of "take only P(win)>τ" vs "take all"
        │
        └──────────────── persist to a meta_label_scores table ───────────┐
                                                                           │
                        LIVE (Karri/operator-gated)                       │
  primary signal (conviction direction) ──► [G] online featurize  ◄───────┘
        │                                         │
        ▼                                         ▼
  Blade gate layer  ◄── P(win) below τ → shrink/skip   (gate use: Karri-gated)
        │
        ▼
  strategy-execution sizing chain:
     dollarRisk × f(P(win))   ◄── sizing use: Karri-gated
        (f bounded, e.g. 0.5–1.2 like engine multipliers; or capped half-Kelly)
```

### Where each piece plugs into the existing tree

- **[A] Labeler** — new offline module (likely `scripts/firehose/label-triple-barrier.mjs` next to `derive-lessons.mjs`, or a `packages/ml/` workspace). Reads `ohlcv_candles` + `simulated_orders`. Reuses the barrier logic already in `shadow-log.ts:trackPendingOutcomes()` but candle-accurate (per-bar high/low) instead of spot-mid.
- **[B] Feature builder** — joins `simulated_orders.entry_snapshot` + nearest `market_snapshots` (±1 min on `opened_at`) + `conviction_*` columns. Most features already exist as columns; this is assembly, not collection.
- **[D] Model** — offline Python (`data/` already has `_recompute.py`; add `data/ml/` with scikit-learn). Keep it scikit-learn + a single pickled model artifact. Score export back to Postgres.
- **[F] Shadow eval** — mirrors the existing `/shadow/comparison` pattern: a `meta_label_scores` table + an API route that compares "what the meta-model would have gated" vs the realized book. This is the SHADOW_COMPARE analog and is the gate before anything touches live sizing.
- **[G] Live featurize + use** — the only live-path change. Reads the same features at decision time, loads the model artifact (or a distilled coefficient table for logistic — trivial to evaluate in TS without Python in the worker), emits P(win). Consumed in `new-gates.ts` (a new soft gate `meta_label_pwin`) and/or as a bounded multiplier in `strategy-execution.ts`. **Both behind env flags, default OFF, Karri-gated.**

### Label definition (be explicit)
- `y = 1` if the **TP barrier** is touched before the SL barrier and before the vertical (time) barrier; else `y = 0`. This is the meta-label conditioned on the firm *having taken the trade in the conviction direction*. Use candle high/low penetration, not close, to detect barrier touch. For trades that closed by STALE_TRADE_EXIT (vertical barrier), label by realized `result_r` sign as a fallback, but flag them — they are the ambiguous ones.

---

## 4. Sample-size caveat (the binding constraint)

- **~202 closed trades total**, 2026-04-16 → 2026-06-09, ~3.7/day. ~173 with a clean `original_risk_points` risk basis (the rest have null/unreliable R). **138 trades also need metadata backfill** (`strategy_id`, `atr_at_entry`, `entry_conviction_score`) per `phase-status.md` — that backfill is a prerequisite, or those rows drop out of the feature matrix.
- After filtering to clean-risk + complete-feature trades you likely have **~150 usable rows**. That is squarely in "be very careful" territory:
  - **No deep models.** Logistic regression (a handful of features) or, at most, a depth-2 gradient-boost with heavy regularization. A model with more parameters than ~n/10 effective samples will memorize noise.
  - **Purged CV is not optional.** With overlapping holding periods and 150 rows, naive k-fold leaks and will report fake +10–15pp accuracy. Purge by holding-window overlap + small embargo.
  - **Feature budget is tiny.** Pick ~5–8 features max (conviction_total, regime, session, ADX, ATR-normalized stop distance, one macro delta). Selecting from 30 candidate features on 150 rows is overfitting by feature-search.
  - **Report Brier score + calibration, not just accuracy.** The whole value is a *calibrated* P(win) for sizing; an uncalibrated 70%-accurate classifier is useless for Kelly sizing.
  - **Confidence intervals on everything.** A WR cell with n=8 (like several lesson clusters) has a ±35pp CI. Treat sub-30-sample cells as priors, not facts.
- **Conclusion:** what is *buildable and trustworthy now* is a **simple, calibrated, purged-CV logistic meta-scorer used in SHADOW mode** — it earns trust offline while the book grows. What *needs more data* (target ~400–600 closed trades, i.e. a few more months at current cadence) is letting that score actually gate/size live, and any move to gradient-boosting. The shadow phase doubles as the data-accumulation phase.

---

## 5. Phased plan

Legend: **[Claude]** = build freely (labeling, offline model, shadow eval, observability — no trade-decision change). **[Karri/operator]** = gated (anything that lets P(win) change a live gate or size).

### Phase 0 — Prerequisites [Claude]
- Backfill the 138 trades' missing metadata (`strategy_id`, `atr_at_entry`, `entry_conviction_score`) so the feature matrix isn't decimated.
- Stand up `data/ml/` (scikit-learn) + a `packages/ml/` or script home. No model yet.

### Phase 1 — Formal triple-barrier labeler [Claude]
- Candle-accurate labeler over `ohlcv_candles` + `simulated_orders` → per-trade `y ∈ {0,1}` + barrier-hit metadata.
- Validate it reproduces the existing `close_reason`/`result_r` outcomes (sanity check against reality).
- Persist labels to a `trade_labels` table. This is pure observability — ships immediately.

### Phase 2 — Feature builder + purged-CV harness [Claude]
- Assemble X from existing columns. Implement purged + embargoed CV split by `opened_at`/holding-window.
- Deliverable: a reproducible offline dataset + the CV harness. Still no live impact.

### Phase 3 — Offline meta-label model + honest eval [Claude]
- Train calibrated logistic regression. Report under purged CV: precision/recall at candidate thresholds, Brier score, calibration curve, and the key business metric — **R/Sharpe uplift of "take only P(win)>τ" vs "take all"**, with CIs.
- Write up as a strategy proposal in `docs/strategy/proposals/` for Karri (this is where the live-use ask gets reviewed).

### Phase 4 — Shadow-compare in production [Claude to build, log-only]
- `meta_label_scores` table + scorer running on every decision cycle, **logging P(win) only**, plus an API route mirroring `/shadow/comparison` that tracks would-the-meta-model-have-helped over time. Analogous to `CALIBRATION_MODE=SHADOW_COMPARE`. No gate, no size change. This accumulates the forward track record Karri needs.

### Phase 5 — Live gate influence [Karri/operator-gated]
- New soft gate `meta_label_pwin` in `new-gates.ts`, env-flagged (`META_LABEL_GATE_ENABLED`, default OFF), threshold env-tuned. Soft-log first (`would_reject`), hard-reject only after Karri sign-off, exactly like the existing gate ladder.

### Phase 6 — Live sizing influence [Karri/operator-gated]
- Bounded P(win)→size multiplier in the `strategy-execution.ts` chain (clamped, e.g. 0.5–1.2, or capped half-Kelly), env-flagged default-OFF. This is the highest-money-impact step and the last to flip. Requires the shadow track record from Phase 4 + a larger book (~400+ trades).

### Later / optional
- Fractional differentiation on price-level features if/when feature-importance shows the level features matter and stationarity is hurting.
- Gradient-boosting upgrade *only* once n and purged-CV stability justify it.

---

## 6. Boundary restatement (per operator principles)

- Claude owns the pipeline that **carries** learning: labeler, feature store, offline model, purged-CV harness, shadow-eval, observability tables/routes. All of Phases 0–4 ship freely and immediately under max-mode (capture/derive/observability/shadow forward-test).
- Karri owns the logic that **acts** on it: Phases 5–6 (P(win) actually gating or sizing a live trade) are trade-altering switches and go through `docs/strategy/proposals/` → Karri before any flag flips. Default OFF, env-gated, 30-second revertable.
- Sample size is the gate on ambition, not on whether to start. Build the offline + shadow stack now on 150 rows; let live influence wait for the book to grow and the shadow record to prove out.
