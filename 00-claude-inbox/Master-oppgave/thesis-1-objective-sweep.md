# thesis-1 objective-verification sweep — 2026-06-02

10-agent read-only sweep over the finalised thesis. Complement to the FOR/AGAINST/JUDGE panel (which judges quality/grade); this track checks objective facts.

## CLEAN — no action needed
- **Numerical consistency:** perfect across all 11 files. Every canonical value (R²=0.971, holdout 0.89, 6555/187/452/4407/342/146, NEB 0.27/0.296, AIMD params) agrees everywhere. No stray old values (0.983, 0.74, 0.151, 0.30 eV, 6556, R²0.14, −0.22).
- **Cross-references:** no dead \ref/\Cref; no duplicate labels. (41 labels defined-but-unreferenced — normal for section labels; only 2 figure labels unused: fig:md_equilibration, fig:md_trajectories_panels — harmless.)
- **Citations:** all 48 \cite keys resolve in references.bib; 0 compile-breakers.
- **Theory coverage:** all 26+ concepts used in results/discussion are introduced in theory/methodology. No orphans.
- **Numbers↔framing (Abstract/Intro/Conclusion):** aligned; LiBiO2 correctly framed as verification (not discovery); inorganic scope consistent.
- **Language:** clean British English, no AI-isms, consistent em-dash style.

## REAL ITEMS — by type

### Decide (judgement, interacts with framing)
1. **GroupKFold theory orphan.** Theory still explains GroupKFold/GroupShuffleSplit (subsec:groupkfold — UNUSED label) but the final pipeline uses a random split. Options: (a) trim the GroupKFold subsection, or (b) tie it in by having the composition-level holdout (which is grouping-by-chemistry) reference the grouped-CV/exchangeability theory. (b) is better — turns an orphan into motivation. Relates to open task #67 (GroupKFold-vs-random-split sensor prep).

### Add (content the operator should drive — grade levers)
2. **Author Contributions section (criterion 2.4 Independence, 5 pts).** No explicit statement of what the student did independently vs the DFT/AIMD collaboration. The AI-disclosure scope-boundary covers part of this; a short "Author Contributions" statement would formalise it. Attribution-sensitive → operator decides wording.
3. **Norwegian Sammendrag.** Example thesis has English Abstract + Norwegian Sammendrag; this is a standard NTNU requirement and currently missing. High value, easy (translate the Abstract). Operator confirm.
4. **Abbreviations list** (XGBoost, RMSE, MAE, NEB, AIMD, Magpie, NASICON, SSE, DFT, …) — example has one; easy win.
5. **Depth/scope vs example thesis (~88 pp, 35 figs, 31 tables):** this thesis ~60–70 pp. Example is denser. Candidate thickening: more results figures, deeper discussion with worked examples, expanded Future Work, 2–4 appendices, ~20 more references. All operator-prioritised scope calls.

### Note only (no action / operator-gated)
6. **plan.tex** contains dropped-concept text (conformal/SHAP/HistGBM/GroupKFold) BUT is NOT \input in main.tex → never compiled, harmless. Could be deleted (operator-gated).
7. **Future_Work.tex** mentions SHAP/conformal/OOD — this is INTENTIONAL (operator-approved "research-group continuation"). Keep.
8. **2 unused bib entries** (Omee2024OODBenchmark, Musielewicz2024ConformalGNN) — uncited, won't print. Remove at next cleanup (cosmetic).
9. Optional filler tweaks: Theory:252 "plays a distinctive role", discussion:57 "A point worth drawing out" — defensible, low priority.

## Pending
- Agent #5 (figure/table hygiene) still running.
- Panel reports (advocate / adversary / judge) not yet in this folder — consolidate with them when they land.
