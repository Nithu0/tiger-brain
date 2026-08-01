# thesis-2 (FOR / advocate) — full polish analysis, 2026-06-03

10 agents · language/AI-isms + sources + figures + numbers/coherence + rubric + big-errors. Guardrails respected (no SHAP/OOD/conformal/MP/polymer/0.144 reintroduced); red `\sv{}`/§7 skipped for critique, analysed around. **No file edits made** — held to avoid 4-pane working-tree collision; this is the ready-to-apply patch-list for thesis-1 to serialise.

## ADVOCATE VERDICT: ~83/100 now (red unresolved) → solid A once the fix-list lands + chapters de-redded

3 strongest cards to foreground to the external sensor:
1. **Methodological maturity** — candidate diagnoses their own R²=0.971 as an *interpolation* score and builds a stricter holdout to test generalisation. Graduate-level evaluation discipline.
2. **Two-pillar contribution** — large hand-curated literature dataset (187 papers / 6,555 measurements) *plus* the model; the dataset is a reusable artefact on its own.
3. **End-to-end predict-then-verify** — ML candidate cross-checked by independent DFT-NEB + AIMD on LiBiO₂, correct physics, honest "not experimental confirmation" framing.

## CONFIRMED CLEAN (the critic gets little here)
- **Numbers:** ZERO mismatches across all compiled chapters; every literal matches macros/JSON (0.971/0.89/4407/187/452/342/146; NEB 0.27 vs 0.296; mp-1205315). No stray mp-28253/1496/120/144/HistGBM/V4-B.
- **Guardrails:** NO leaks in compiled text. conformal/SHAP/OOD/MP/polymer all correctly quarantined to Future_Work (roadmap, "pursued in parallel by the research group") or theory-analogy (subsec:groupkfold). `plan.tex` + `chapters/drafts/` confirmed NOT `\input` → abandoned 0.144 narrative stays out of the PDF.
- **Sources:** 50 bib entries, 49 cited, **0 cited-but-missing**, **100% DOI**, uniform ieeetr. Muy2018/Vovk2005/Angelopoulos2023/Lundberg2017/Jaafreh2024 all present + correctly attached. No hallucinated entries.
- **Figures:** 23/23 referenced files exist; all top-level figs referenced; captions interpret. fig 5.3 "(c)" artefact CLEARED. fig 6.7 correctly captioned model-predicted (no plateau).
- **Physics:** Arrhenius, Nernst-Einstein, Einstein factor-6, Haven ratio, NEB/AIMD all correct & correctly unit-ed. No big physics error.
- **LiBiO₂:** consistently "verification / proof-of-concept", no discovery overclaim.
- **Language:** already strong, human, low AI-ism density. Ethics section (sec:disc_ethics) genuinely sufficient for the 2026 criterion. AI-disclosure compliant (Acknowledgments + NTNU form).

## BIG ERRORS / MUST-FIX (ranked — flag to operator)

**E1 (HIGHEST — touches Abstract; needs operator decision). Holdout MAE 0.02 vs RMSE 0.142 mS/cm, same linear units, on n=3.** RMSE ~7× MAE means one of three points dominates the error → the aggregate is near-meaningless and a sensor punctures it in 10 seconds. Appears in Abstract:38, ml_results:149/175/184-186, conclusion:50-51, discussion:27. **Fix (operator's call):** either (a) show the three per-composition residuals explicitly (honest, makes the spread visible), or (b) drop the linear-unit MAE/RMSE and report only R²_log=0.89 + per-point log residuals. Lean harder on the existing "indicative rather than statistically tight" hedge.

**E2 (MED-HIGH). fig caption ml_results:176-177** "The model reproduces both the absolute conductivity and its temperature slope for all three compositions" — flat unhedged success claim in a caption (read in isolation), contradicts E1. **Fix:** soften to "tracks the magnitude and slope of the three held-out compositions"; let the body carry the n=3 caveat.

**E3 (MED — coherence/honesty, critic bait). Holdout "randomly selected" vs curated.** Methodology:268-284 + discussion:25 call the 3 comps "randomly selected" yet they are exactly one nitride + one phosphate + one sulfide-halide and removed with same-anion-sublattice neighbours. "Randomly selected" cannot produce a clean one-per-family span. **Fix (exact, method unchanged):** Methodology:278 add — "The three target compositions were chosen to sit in chemically distinct families --- one nitride, one phosphate, and one sulfide-halide --- so that the validation probes generalisation across, rather than within, anion chemistries." Then change "randomly selected" → "deliberately chosen, one per anion family" at discussion:25 + Methodology.

**E4 (data integrity — blocked on supervisor file). fig 4.1 vs tab:family_counts** per-family counts may be stale (`\sv{[Pending data]}` at dataset_results.tex:37). Confirm Table 4.1 sums/counts against the regenerated file before submission, then delete the flag. Do NOT fabricate — waits on the new filtered file.

## LANGUAGE / AI-ISM PATCH-LIST (finpuss, ready to apply, meaning preserved)
- Introduction.tex:22 | "the underlying data landscape is fragmented" → "the underlying data remain fragmented" *(banned "landscape" + subject-verb)*
- Introduction.tex:18 | "Data-driven and AI/ML methods ... in this space" → "Data-driven and machine-learning methods ... among these materials"
- Abstract.tex:2 | "key enabler for" → "leading candidate for"
- Abstract.tex:45 / conclusion.tex:57 | "independently predicts the ionic conductivity that prior work suggests" → "independently predicts facile Li⁺ transport, in line with prior work" *(circular→precise)*
- conclusion.tex:58 | "lab-friendly to synthesise" → "relatively easy to synthesise in the laboratory"
- conclusion.tex:65,73 | "at the level of calculation performed" → "at the level of theory used"
- Theoretical_Background.tex:32 | "robust under abuse" → "tolerant of abuse"; :453 | "Robust to noisy..." → "Insensitive to noisy..."
- Theoretical_Background.tex:264 | "plays a distinctive role for sulfides" → "matters especially for sulfides"
- Theoretical_Background.tex:79,237,91 | trim restating openers (see agent-2 detail)
- Theoretical_Background.tex:265/278 | unify "93%": pick "~93%" both places
- Methodology.tex:130-137 | duplicated ball-mill example list → "These surface forms were collapsed so that..."
- Methodology.tex:339 / Theory | "bias--variance plane" → "bias--variance trade-off"
- dataset_results.tex:20 | drop "for the rest of the thesis" + anthropomorphic "be asked to use"
- ml_results.tex:38-41 | de-pad "have been shown to ... for comparison"
- ml_results.tex:114-117 | de-duplicate parity prose (same "no systematic bias / not visible as scatter" point stated 3×)
- ml_results.tex:81-84 | cut trailing "neural network competitive when representation is informative" (AI-ism + mild overclaim)
- discussion.tex:16 | "deserve emphasis"→"stand out"; "selected on a small margin"→"chosen by a narrow margin"
- discussion.tex:29,48,77,93 | de-duplicate honesty-signalling cadence ("honest caveat"/"stated plainly"/double "together"-framing) — reads as performed candour when repeated
- discussion.tex:135 | three verb-less fragments ("A curated... A prediction model... And a worked demonstration...") → give verbs / fold into prose
- Future_Work.tex:5 | seven-item heading-restating preview → compress or cut

## UNCITED / IMPRECISE PHYSICS (medium — cheap credibility)
- Theoretical_Background.tex:617 | "systematically overbind shallow saddle points" — overclaim + uncited → soften to "systematic errors in migration-barrier heights~\cite{...}"
- Theoretical_Background.tex:626 | "PBE-NEB uncertainty 50--100 meV" — uncited quantitative → add cite or hedge "of order tens of meV"
- Theoretical_Background.tex:143 | "pack-level ~400 Wh/kg" — likely cell-level; verify against ApEnergy2025SSBReview
- Theoretical_Background.tex:336 | low-Eₐ↔high-σ correlation → add "provided the prefactor does not vary too strongly"

## BIB / COMPLETENESS (cheap points)
- Orphan `Musielewicz2024ConformalGNN` → cite in the Future_Work conformal para or delete.
- Placeholder `pages` fields on ~9 entries (`pages={3}` Ke2020, `1--2` Pereznieto2023, etc.) → fix the visible ones.
- `Zhang2023AnnealingLPSCl` truncated author list → expand from DOI.
- claims.csv: 2 rows / 0 verified vs 49 live cites — populate for high-load claims if the rubric expects claim-tracking.
- **No Norwegian Sammendrag** (example thesis is bilingual; NTNU norm) → translate the existing abstract. Cheapest high-value gap.
- Abbreviations list: present ✓. Appendices: repo+seed acceptable; optional 1-page Appendix A (repo commit + 146-feature list) as cheap insurance.
- Two orphan parent floats: add `\Cref{fig:md_equilibration}` + `\Cref{fig:md_trajectories_panels}` in prose.

## DRAFT-STATE (operator/boss owns)
- Remove red wrapper on Conclusion + Future Work (main.tex ~177-186) once final.
- §7 `[Spørsmål til deg]` in discussion — operator answering; de-red after.
- conclusion.tex hard-codes numbers (not macro-bound) — matches now, but will silently desync if a future run shifts a figure. Consider macro-binding.

— thesis-2 (advocate)
