# Skills-eval — code-1 handoff (claude-trading-skills → Nexus)

**By:** ai-1 (Nexus lane)
**Date:** 2026-06-14
**Inputs:** code-1 handoff `/home/nithu/code/command-center/docs/ops/handoff-nexus-trading-skills.md`; ref repo `/home/nithu/code/_refs/claude-trading-skills` (skimmed top-5 SKILL.md + references); Nexus existing-systems map (Explore sweep).
**Status:** RESEARCH / decision-feed for Karri+operator. Nothing implemented. CONCEPT-port only — the ref repo's Python is FMP/Alpaca/equity-bound and is NOT reusable.

---

## Bottom line

code-1's read is correct. The ref repo is a US-equity Core+Satellite *universe screener* library; ~90% is dead weight for a single-instrument session-trader. What transfers is **methodology + memory/postmortem schema**, not code. Of the top-5, the ranking changes once you overlay what Nexus *already has* vs what's a genuine gap:

- Nexus already has a **complete postmortem module** (failureClass FSM, department scoring, lessons → firm_memory) and a **complete sizing gate** (Exposure-And-Shield). So `trade-performance-coach` (#2 in code-1) and `position-sizer` (#4) are mostly *already built* — porting them is low marginal value (a cross-check oracle at best).
- The real gaps are: (a) **rejected signals are never scored** (ai-2 BLOCKER 3 — the scorecard only logs quality-passers), and (b) **no codified accept-criteria / robustness gate** before flipping a shadow module live, and (c) **MAE not persisted** as a column.
- So the highest-value adoption is the one that plugs straight into the gap ai-2 already opened: **signal-postmortem's outcome-classification + feedback-to-weights loop**, wired so *rejected* signals get scored too.

---

## Top-3 adoptions, re-ranked for Nexus (vs code-1's generic ranking)

### #1 — signal-postmortem  (code-1 had it #3)
**Promoted to #1 because it lands directly on an already-open gap (BLOCKER 3) and reinforces the scorecard/meta-label work just shipped.** Lowest effort, highest leverage.

What ports (concept only):
- The **4-way outcome classification**: TRUE_POSITIVE / FALSE_POSITIVE / MISSED_OPPORTUNITY / REGIME_MISMATCH.
- The **regime-at-signal vs regime-at-exit** capture (distinguishes "strategy wrong" from "regime flipped").
- The **feedback-to-weights** shape: false-positive-rate-by-source → suggested weight adjustment, gated behind a **min-sample threshold (20+)** before any adjustment is even suggested.

What's equity-specific (drop):
- 5d/20d realized-return horizons → reframe to Nexus's intraday/session holding period (resolve against actual trade outcome or SL/TP candle-walk, which the forward-test path already does).
- ticker/source_skill universe attribution → collapse to S1–S4 strategy + filter-source.
- FMP price fetch → Nexus has its own OHLC + shadow-outcome resolver.

Where it plugs in (existing systems, do NOT reinvent):
- `apps/worker/src/firm/scorecard/scorecard-recorder.ts` — currently `recordSignalScorecard()` is called only AFTER `bladeApproval()` + quality-threshold, so **rejected signals are invisible**. The port = record the 5-filter verdict frame for *rejected* proposals too (a parallel rejected-signal scorecard row or a `was_rejected` flag + rejection stage), then resolve their would-be outcome via the existing shadow-log / forward-test resolver (`apps/worker/src/firm/shadow-log.ts` — `insertShadowSignal` / `resolveShadowOutcome` already capture blocked proposals with `ShadowBlockStage`). Most of the plumbing exists; this connects two systems that aren't talking.
- The classification + weight-feedback **derive/observability** half is Claude-infra (no trade-decision change). The half that *acts* on it (actually tuning meta-label / gate thresholds from false-positive rates) is **Karri-gated** (it alters trade decisions).

### #2 — backtest-expert  (code-1 had it #1)
**Kept high but #2: pure methodology, zero coupling, but it's a discipline/checklist, not a wired feedback loop — slower to show value than #1.**

What ports:
- "Beat the idea to death" — robustness over peak PnL; seek **plateaus not peaks** in parameter sweeps; punish with pessimistic fills.
- The **5-dimension verdict** (Sample Size / Expectancy / Risk Mgmt / Robustness / Execution Realism) → Deploy / Refine / Abandon.
- Sample-size discipline (min 30, prefer 100+, high-confidence 200+ trades) — directly applicable to the shadow-module activation decision.

What's equity-specific (drop / re-knob):
- Friction model → XAUUSD friction = **spread + session-gap + news-slippage**, not equity commissions.
- "Test every stock that met criteria" survivorship point → for one instrument it becomes "test every signal incl. the blocked ones" (which is exactly #1's value again — they reinforce each other).
- 5-10yr multi-regime requirement → Nexus has limited demo history; honest note: this gate may *fail on sample size* today, which is itself the useful output.

Where it plugs in:
- `docs/ops/new-strategy-gate.md` (the 5-rule foundation gate) — bake the robustness checklist + the Deploy/Refine/Abandon verdict + pessimistic-fill stress into the accept-criteria. The gap the Explore sweep found: criteria (WR, PF, max-DD) live in operator docs as prose, **not codified in the schema**, and gate-check is manual. This skill gives the codifiable rubric.
- Pure **Claude-infra** as a doc/checklist + (optionally) a TS port of the 5-dimension scorer. It only becomes Karri-gated if its verdict is wired to auto-block activation (it shouldn't — operator-prinsipp 1: health-checks REPORT, operator decides).

### #3 — trader-memory-core (MAE/MFE schema slice only)  (code-1 had it #5)
**Promoted over coach/sizer because it surfaces one concrete missing field, not a re-build of something Nexus already has.**

What ports:
- ONLY the **postmortem record schema slice**: confirm + persist **MAE** (Maximum Adverse Excursion). Explore sweep found `peak_price` / `peak_price_true` exist (so MFE is effectively captured via `peakRMultiple`), but **MAE has no column** — it's computed ad-hoc in postmortem and thrown away. That blocks queries like "MAE>2% but MFE<1% → whipsawed trades," which is exactly the signal #1's calibration loop wants.
- The thesis lifecycle FSM (IDEA→ENTRY_READY→ACTIVE→...→CLOSED) is **already** covered by Nexus's blackboard + position-management states — do NOT port it.

Where it plugs in:
- `packages/shared/src/db/schema.ts` (add a `worst_price` / `mae_*` column next to `peak_price`) + populate from the same per-cycle market-snapshot poll that already feeds `peak_price`, plus a backfill from broker candles (the `peak_price_true` backfill script is the template).
- Pure **Claude-infra** (a captured field, no trade-decision change). Per operator-prinsipp 2, capture/derive runs freely.

---

## What to DROP (and why)

- **trade-performance-coach** — Nexus's `postmortem.ts` already emits failureClass + management classification + department scores + lessons. The coach's *unique* axis is gate-adherence / risk-discipline / execution-quality framing, but its core is "human trader psychology" which is irrelevant to an automated system. Marginal value = a thin "did the strategy obey its own gates" report layered on existing postmortem output. Defer — not a gap, a nice-to-have.
- **position-sizer** — Exposure-And-Shield already does fixed-fractional + regime/mode/event multipliers with hard caps. The skill's ATR-sizing and Kelly are genuinely *absent* in Nexus, BUT: (a) ATR is already captured (just not fed to sizing), (b) Kelly-from-realized-stats is a **trade-decision-altering risk change → hard Karri-gate**, not something to lift opportunistically. Keep as a *reference calculator / cross-check oracle* idea for Karri, drop as an adoption.
- **Everything in code-1's SKIPPED list** — equity-universe screeners, dividends, breadth, 13F flows, options, equity macro-regime. No XAUUSD analog. (Honorable-mention `dual-axis-skill-reviewer` — deterministic+LLM dual-axis review — is a tooling idea for reviewing Nexus's own modules, unrelated to trading; file as a maybe, out of scope here.)

---

## The ONE to start + concrete Nexus adaptation

**Start: signal-postmortem, scoped to "score rejected signals" (closes ai-2 BLOCKER 3).**

Why this one first:
- It's the intersection of (a) an already-open blocker, (b) the scorecard/meta-label work just shipped, and (c) plumbing that mostly already exists (shadow-log already captures blocked proposals; scorecard already has the 5-filter frame). It's *connecting two existing systems*, not building new.
- It's mostly Claude-infra (capture/derive/observability) — runs freely under operator-prinsipp 2/6. Only the threshold-tuning tail is Karri-gated.

Concrete adaptation (sketch — NOT implemented):
1. **Record rejected signals.** In `scorecard-recorder.ts`, capture the 5-filter verdict frame for proposals that fail thesis-quality / blade / portfolio-brain, with the rejection stage tagged (reuse `ShadowBlockStage` from `shadow-log.ts`). Either a `was_rejected` flag on `signal_scorecards` or a parallel rejected table. **[Claude-infra]**
2. **Resolve their would-be outcome.** Point rejected rows at the existing shadow-outcome / forward-test resolver so each gets a realized R-multiple from candle-walk. **[Claude-infra]**
3. **Classify.** Apply the 4-way taxonomy (TP/FP/MISSED/REGIME_MISMATCH), reframed to session horizon, with regime-at-signal vs regime-at-exit. **[Claude-infra]**
4. **Aggregate, gated by min-sample (20+).** Produce false-positive-rate-by-strategy and "rejected-but-would-have-won" rate. Surface in the morning briefing / a dashboard panel. **[Claude-infra — REPORT only, per prinsipp 1]**
5. **(Karri-gated, separate proposal) Act on it.** Only when the operator/Karri approves: feed the false-positive / false-rejection rates into meta-label or gate-threshold tuning. This alters trade decisions → `docs/strategy/proposals/`. **[Karri-gated — do NOT bundle with steps 1-4]**

Net: steps 1-4 are a focused observability diff Claude can build now; step 5 is the only money-impact piece and routes through Karri.

---

## One-line ask for the decision

Approve building **signal-postmortem steps 1-4 (score + classify + report rejected signals)** as Claude-infra to close BLOCKER 3; backtest-expert robustness rubric (#2) lands as a `new-strategy-gate.md` checklist; MAE column (#3) as a capture-only schema add. The trade-altering threshold-tuning tail stays a separate Karri proposal.
