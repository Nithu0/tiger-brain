# Per-trade forensic prompt — "why exactly did the firm make THIS trade?"

_thesis-2 (researcher, operator-directed), 2026-07-03. Reusable instrument for going through trades ONE AT A TIME. Codex + firm-agents + any Claude pane can run it. Read-only. Companion to the bleed diagnosis (`2026-07-01_bleed-diagnosis-and-fix-plan.md`) and the running defect-forensic workflow (`wcaii29az`)._

## How to use
Feed ONE trade (a `simulated_orders` / journal_trades row + its `id`) into the prompt below. It forces a full decision-provenance reconstruction. Run it per trade for the last 7d; cluster the answers to find the systematic bleed. Where a field can't be reconstructed from captured data, the answer is literally the gap the monitor must close (feeds the provenance design).

## Data sources to join for ONE trade (parameter lineage map)
- `simulated_orders` — the order + metadata (strategy_id, direction, atr_at_entry, entry_conviction_score, execution_source, spread_at_entry, regime/session at entry).
- `decision_funnel` / `gate_decisions` — which gates evaluated, passed, hard-rejected, or would-reject (shadow) for the cycle that opened it + their margins.
- `engine_scores` — per-engine directional/timing scores that fed conviction (⚠ known gap: TIER-3 opens have been landing with 0 engine_scores — record when empty).
- `firm_state engine_multipliers:current` — the SAFE_AUTO_APPLY multiplier applied to each engine weight at decision time (or 1.0 if RECOMMEND_ONLY / post-restart).
- blackboard events (thesis, challenge, contradiction score) for the cycle.
- `agent_lessons` (approved) — any lesson injected into risk-advisor/trade-critic prompts (advisory only today).
- `postmortem` on the closed trade — classification + reasoning.
- `meta_label_scores` — shadow P(win) if scored.

## THE PROMPT (paste per trade)
```
You are reconstructing the full decision provenance of ONE trade in the Nexus XAUUSD demo firm. READ-ONLY. Cite file:line in /home/nithu/code/ai-assistent and the exact DB rows. If a fact cannot be recovered from captured data, write "NOT CAPTURED — <what's missing>" — do not guess.

TRADE: <paste the row + id>

Answer every section for THIS trade:

1. DATA BASIS — what market data did the decision actually use? Price, ATR-at-entry, spread, candle window, and the TIMESTAMP + FRESHNESS of each. Was any input stale at decision time?

2. PARAMETER LINEAGE — for EACH parameter that entered the decision (conviction thresholds min-direction/timing/total, engine base weights, engine performance multipliers, sizing inputs, gate thresholds, regime/session labels): give (a) its VALUE at decision time, (b) its SOURCE — config default / env override / SAFE_AUTO_APPLY-calibrated / lesson-injected / detector-computed — with file:line, and (c) WHY it had that value (who/what last set it).

3. WHY THIS TRADE — which engine/thesis drove it? Give the conviction breakdown (direction, timing, total vs the min gates) and which gates passed with what margin. Name the single factor that pushed it over the line.

4. INFLUENCE MAGNITUDE — rank the factors by how much each CONTRIBUTED to the decision (attribution). Quantify: which engine weight × multiplier dominated the conviction sum? If one engine's SAFE_AUTO_APPLY multiplier (0.70–1.20) changed the ranking, say so and by how much.

5. INTERFERENCE — which signals CONTRADICTED or disturbed the choice? Contradiction score + its components, dissenting engines, any gate that would-rejected in shadow (min_rr, regime_direction), any risk-advisor/trade-critic warning. Was the trade taken DESPITE a red signal? Which one?

6. COUNTERFACTUAL — the minimal change that would have flipped this to no-trade (one threshold, one engine weight, one gate). This localizes the fragile parameter.

7. OUTCOME vs EXPECTATION — resultR, closeReason, MFE/MAE, hold time. Was the thesis right but execution wrong, or thesis wrong? (Match the postmortem classification; challenge it if the data disagrees.)

8. IMPROVEMENT — was this an instance of a KNOWN anti-pattern (e.g. counter-trend entry in a trending regime — the −2108 cluster)? Would an approved lesson have caught it IF the lesson→gate wire existed? What ONE parameter should change next time, and what GATE does that change need (operator-flip / bug-fix / Karri-proposal)?

End with: the 3 provenance fields that were NOT CAPTURED for this trade — these are what the monitor must add.
```

## Cluster the per-trade answers into these questions
- Which strategy × regime × session is doing the bleeding? (expect counter-trend-in-trending + NY.)
- How often did a SAFE_AUTO_APPLY multiplier ≠ 1.0 change the engine ranking on a losing trade? (Confirms whether the one live learning wire is actively harmful.)
- How often were trades opened with 0 engine_scores? (engineBlindOpen incidence.)
- How often was a trade taken DESPITE a shadow would-reject (min_rr, regime_direction)? (Gates that should be hard but are shadow.)
- Which provenance field is "NOT CAPTURED" most often? (Ranks the monitor's build order.)
