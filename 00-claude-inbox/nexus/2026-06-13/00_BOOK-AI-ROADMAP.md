# Book → AI Modules: Consolidated Roadmap

**Date:** 2026-06-13
**Author:** Claude (synthesis agent — ran last)
**Status:** synthesis / proposal. Strategy-lane items gated on Karri.
**Source:** Karri's 5-book → 5-module mapping + Gold AI Master Prompt (5-filter per-signal flow).

> NOTE ON INPUTS: the sibling module specs (`module-market-structure.md`, `module-macro-intermarket.md`, `module-volume-price.md`, `module-ml.md`, `module-risk-psychology.md`, `master-prompt-integration.md`, `book-ingestion-pipeline.md`) were **not yet written** in `2026-06-13/` when this agent ran — only the watch files existed. This roadmap is synthesized from the book→module mapping plus a direct read of current Nexus state (`docs/ref/data-sources.md`, `docs/ops/firehose-setup.md`, the learning-loop + gate proposals, code grep for meta-labeling). When the module specs land, re-reconcile #1-first-piece / effort estimates against them — but the prioritization below is data- and lane-driven and should hold.

---

## TL;DR

- **The 5 modules are NOT equal-feasibility.** Two are data-blocked on spot gold, two are quick-win gates, one (ML/meta-labeling) is the deepest structural fit and the highest-leverage long build.
- **The Gold AI Master Prompt (5-filter per-signal flow) is the integration layer** — it's where every module plugs in as a filter. Build the *frame* first (a per-signal scorecard that logs each filter's verdict in shadow), then fill filters over time.
- **#1 first build: the meta-labeling scaffold** — a secondary model that scores P(win) on signals the primary strategies already emit, trained on data we *already persist*, run in **shadow** (logs, never vetoes) until Karri reviews. It's the deepest book→system fit (ML module / "Advances in Financial ML" triple-barrel + meta-label), it reuses the healthy derive loop, and it's the one build that compounds: every other module becomes a *feature* into it.

---

## Per-module assessment

| Module (book) | Already there | Data feasibility | #1 first piece | Effort | Lane |
|---|---|---|---|---|---|
| **Risk / Psychology** | Position sizing, daily loss cap, circuit-breaker (`hard-position-size`), 5 shadow gates, daily trade cap | Full — all internal state | **min-R:R gate** (reject/flag signals below a configurable reward:risk) in shadow | S | Claude-infra (gate scaffold) → Karri (activation) |
| **Macro / Intermarket** | FRED real-yield/DXY/breakeven fact, cross-asset candles (XAG/DXY/BTC), Forex Factory calendar, sentiment | High — feeds exist; intermarket is computable | **event-risk gate** (flag/suppress signals inside N-min window of high-impact calendar events) in shadow | S–M | Claude-infra (gate + scoring) → Karri (activation) |
| **ML** | Persisted training substrate (`simulated_orders`, `gate_decisions`, `signals`, `engine_scores`, `calibration_log`); healthy derive loop; calibration multipliers (SAFE_AUTO_APPLY approved) | Medium — sample is **thin** for heavy ML; fine for meta-labeling on existing signals | **meta-labeling scaffold** (P(win) on emitted signals, triple-barrier labels, shadow-only) | L | Claude-infra (build + shadow) → Karri (veto activation) |
| **Market Structure** | ORB, FVG detector, range-context, regime engine | High for swing/structure; **full Market Profile = long** | **swing-failure / liquidity-sweep tag** as a signal feature (not a gate yet) | M → L | Claude-infra (feature) → Karri (if it gates) |
| **Volume / Price (VPA)** | OANDA tick-volume only | **BLOCKED for true VPA** — spot gold has no real exchange volume; only broker tick-volume proxy | **tick-volume-confirmation feature** (delta vs rolling avg) as a weak feature, clearly labelled proxy | M | Claude-infra (feature, low priority) |

**Honest blockers:**
- **VPA is structurally limited.** No real volume on spot XAUUSD. Anything from the volume book is a *proxy* (broker tick-volume) — usable as a weak feature, NOT as a primary filter. De-prioritize; don't oversell it.
- **Heavy ML is sample-starved.** ~25–30 days of live demo data, blowup-skewed. Meta-labeling on *existing* signals is fine (it's a relabeling task on data we have); training a fresh from-scratch directional model is not — that's Phase 3 and data-gated.
- **Full Market Profile / full ML are long builds**, not week-1.

---

## Phased roadmap

### Phase 1 — this week, Claude-infra, default-OFF (shadow log only)
Pure infra + observability; no trade-decision change → runs freely under the learning-infra/strategy boundary.

1. **Master-Prompt scorecard frame** — a per-signal record that, for each fired signal, logs each filter's verdict + score (start with the filters we can compute today: R:R, event-proximity, regime-alignment, macro-bias). Writes to a `signal_scorecard` shadow log. *Unlocks:* the integration substrate every module plugs into; immediate observability of "what would each filter have said." *Dep:* none. *Lane:* Claude-infra.
2. **min-R:R gate (shadow)** — compute reward:risk per signal, flag sub-threshold. *Unlocks:* cheapest risk-book win; feeds scorecard. *Dep:* scorecard frame (or standalone). *Lane:* Claude-infra → Karri to activate hard.
3. **event-risk gate (shadow)** — flag signals inside N-min of high-impact Forex Factory events. *Unlocks:* macro-book win using a feed we already poll. *Dep:* Forex Factory service (exists). *Lane:* Claude-infra → Karri.
4. **meta-labeling scaffold (shadow, offline first)** — triple-barrier label the existing `simulated_orders`/`signals` history, train a first P(win) model, backfill a shadow `meta_label_score` per historical signal. *Unlocks:* the deepest build; turns Phase-1 features into model inputs. *Dep:* read-only PG access (firehose role exists). *Lane:* Claude-infra → Karri before it ever vetoes.

### Phase 2 — Karri-reviewed strategy adds (activation)
Each is a proposal in `docs/strategy/proposals/`; flips are env-gated, 30s-rollback.

5. **Activate min-R:R + event-risk gates hard** (after 3–5 day shadow shows sane block-rate). *Dep:* Phase-1 shadow data. *Lane:* Karri activation.
6. **Meta-label live as a soft veto / conviction-weight** — let `meta_label_score` *down-weight* conviction (not hard-block first), behind a flag, after shadow agreement is validated. *Dep:* Phase-1 #4 + shadow agreement report. *Lane:* Karri (this alters trade decisions — same gate as lesson-injection/SAFE_AUTO_APPLY).
7. **Swing-failure / liquidity-sweep feature into scoring** (market-structure book) once the feature is validated as a scorecard column. *Dep:* Phase-1 frame. *Lane:* Karri if it changes scoring.

### Phase 3 — long builds / data-dependent
8. **Full Market Profile** (value area, POC, developing VA). Long build. *Dep:* candle history + tooling. *Lane:* Claude-infra build → Karri activation.
9. **Fresh directional ML model** (not relabeling — actual signal generation). **Data-gated** — needs materially more live sample + regime coverage. *Dep:* months of data. *Lane:* Karri-heavy.
10. **VPA proxy module** (tick-volume) — only if Phase-1 weak-feature shows any signal. Low expected value given the data blocker. *Lane:* Claude-infra, low priority.

---

## The single highest-leverage first build

**Meta-labeling scaffold (Phase 1 #4), shadow-only.**

Why it wins on leverage/effort/feasibility:
- **Deepest book→system fit.** The ML module maps to López de Prado-style meta-labeling: don't predict direction, predict *whether the primary strategy's signal will succeed*. Nexus already *has* primary strategies emitting signals; meta-labeling is the canonical layer on top. No other module is this structurally aligned.
- **Trains on data we already persist.** `simulated_orders`, `signals`, `gate_decisions`, `engine_scores`, `calibration_log` are all populated and reachable via the existing read-only firehose role. No new data feed required.
- **Reuses the healthy derive loop.** Capture/derive is already running and Karri already approved the *pattern* of trade-altering learning (lesson-injection + SAFE_AUTO_APPLY, approved 2026-06-05) behind manual/bounded gates. Meta-label-as-veto is the same shape: build in shadow, activate behind a flag with Karri sign-off.
- **It's the sink for every other module.** Every Phase-1 feature (R:R, event-proximity, regime-alignment, macro-bias, later structure/VPA) becomes a *feature column* into the meta-labeler. Build the meta-label frame now and the rest of the roadmap compounds into it instead of fragmenting into N disconnected gates.
- **Zero live risk at start.** Shadow-only; it logs `P(win)` next to each signal and never touches execution until Karri reviews the shadow-vs-reality agreement.

Sequencing nuance: build the **scorecard frame (#1) and the meta-label scaffold (#4) together** — the scorecard is the feature-logging substrate, the meta-labeler is the model that consumes it. The R:R and event-risk gates (#2, #3) are the cheapest first *columns* in that scorecard.

---

## Ties to existing state

- **Derive loop healthy** → meta-labeling reuses the same capture/persist plumbing; no new ingestion risk.
- **Gate-loosening A/B pending (Karri)** → the meta-label soft-veto is the principled *replacement* for blind gate-loosening: instead of widening gates and hoping, let a model say *which* currently-blocked signals were actually good. Frame it to Karri as "data-driven gate calibration," which is exactly the open A/B question.
- **Meta-labeling is the deepest fit** → confirmed by code grep: zero meta-labeling exists today, but the entire training substrate is already persisted and the learning-loop activation pattern is already Karri-approved. Greenfield with the runway already poured.
- **Boundary discipline** → Phase-1 is all shadow/observability = Claude-infra, runs now under the learning-infra-vs-strategy boundary. Anything that *alters a trade decision* (Phase 2 onward) stays gated on Karri, consistent with operator-prinsipp 6 carve-out.

---

## Top-5 sequenced actions (with lanes)

1. **Build the Master-Prompt scorecard frame** — per-signal shadow record logging each filter's verdict. *Lane: Claude-infra. Now.*
2. **Build the meta-labeling scaffold (offline + shadow)** — triple-barrier labels on existing signal history, first P(win) model, shadow `meta_label_score`. *Lane: Claude-infra (build) → Karri (before any veto). Now, paired with #1.*
3. **Add min-R:R gate (shadow) as the first scorecard column.** *Lane: Claude-infra → Karri to activate. This week.*
4. **Add event-risk gate (shadow) using Forex Factory feed.** *Lane: Claude-infra → Karri to activate. This week.*
5. **File the proposal: "meta-label soft-veto + hard-gate activations"** for Karri, with the 3–5 day shadow-agreement report attached, framing it as the data-driven answer to the pending gate-loosening A/B. *Lane: Karri. After shadow data accrues.*

---

*Re-reconcile against the module specs once they land in `2026-06-13/`. Prioritization is data/lane-driven and expected stable; effort/#1-piece details may shift.*
