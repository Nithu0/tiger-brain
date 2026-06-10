# thesis-2 ADVOCATE BRIEF — full panel report

Date: 2026-06-02 · Panel seat: **supportive/for** · 10 sub-agents, one per chapter/dimension · Grounded in the **real 2026 MTP assessment form** (PDF read directly).

## Bottom line (advocate's defensible read)

The thesis is a **coherent, honest, distinction-track piece of work today**, and reaches a clean A after a short, cheap fix-list. The defining virtue is *intellectual honesty*: the headline R²=0.971 is repeatedly self-demoted to an "interpolation score," the stricter composition-level holdout (0.89) is foregrounded, and LiBiO₂ is landed as a proof-of-concept verification, not a discovery. That self-awareness is exactly what the 2026 "Analysis and discussion" criterion rewards and is the strongest card we hold against the critic.

### Defensible score tally (2026 form, /100)

| Cat | Criterion | Max | Advocate-defensible now | After quick wins |
|---|---|---:|---:|---:|
| 1 | Academic foundation | 10 | 9 | 9 |
| 1 | Theoretical insight | 10 | 8 | 9 |
| 1 | Description of objectives | 5 | 5 | 5 |
| 2 | **Scope and complexity** | 15 | 12.5 | 13 |
| 2 | **Methodological rigor & appropriateness** | 10 | 7.5 | 9 |
| 3 | Results/work | 10 | 7.5 | 8.5 |
| 3 | **Analysis and discussion** | 20 | 15 | 17 |
| 3 | Conclusion and achievements | 5 | 4.5 | 5 |
| 4 | Structure | 5 | 5 | 5 |
| 4 | Language | 5 | 4 | 4.5 |
| 4 | Form | 5 | 4 | 5 |
| | **SUM** | **100** | **~82 (B, top)** | **~90 (A)** |

## CROSS-CUTTING FINDINGS (priority order — these recur across agents)

1. **METRICS PROVENANCE — highest priority.** Chapters are internally consistent everywhere (0.971 / 0.89 / 4,407 rows / 342 compounds / XGBoost), BUT `results/thesis_metrics.json` contradicts them: best_model="Random Forest", holdout_r2=**0.144**, rows=**1,496**, features=141, papers=120/148 — and the JSON is self-flagged "håndskrevet, foreløpig". `thesis_macros.tex` also disagrees with the JSON. So per the CLAUDE.md sync contract the numbers are **not traceable to the canonical source**. ml_results.tex also uses hardcoded literals, not the macros. → A critic cannot tell whether the chapter is ahead of a stale JSON or the numbers are unsourced. **Fix:** regenerate `thesis_metrics.json` from the actual final V4 run, wire ml_results.tex to the macros, reconcile model name + holdout + row/feature counts. This single fix closes the leakage-suspicion door and lifts Results + Methodological rigor together. *(agents 3, 5)*

2. **RED DRAFT + EMBEDDED `\sv{}` SUPERVISOR QUESTIONS.** discussion.tex (7 `[Spørsmål til deg]`) and md_verification.tex (3, incl. uncertainty over how the Arrhenius curve was produced) are still rendered in red. Highest-leverage, cheapest polish — they break the "finished argument" illusion and expose open questions an examiner would pounce on. Resolve/strip before submission. *(agents 6, 7, 9, 10)*

3. **ETHICS ABSENT from discussion.tex.** The 2026 form *explicitly* adds "analysis of relevant ethical issues" under the 20-pt Analysis-and-discussion criterion. ai_disclosure.tex covers research-conduct ethics (AI use, reproducibility) but NOT domain ethics. **Cheap fix (~1 paragraph, 3 sentences):** (a) data-provenance/publication-bias ethics, (b) ML-guided-discovery must narrow not replace the synthesis–EIS loop, (c) reproducibility ethics (open data + seed). Likely +1–2 on a 20-pt criterion. *(agent 7)*

4. **AI TOOL NOT IN REFERENCE LIST.** NTNU policy requires AI tools referenced in text AND in the reference list. references.bib has no Claude/Anthropic/research-os `@misc`; ai_disclosure.tex has zero `\cite`. Otherwise the AI chapter is genuinely strong (tool/role/oversight table, "no AI cited as fact", critical reflection). **Fix:** add `@misc` entries + `\cite` them → flips to full compliance. *(agent 9)*

5. **CURATION DEPTH MAY BE UNCOMPILED.** The strongest Scope-and-complexity evidence (8-stage lineage, outlier audit, family classifier, 5-iteration dataset history) lives in `chapters/drafts/data_pipeline/*.tex` and `drafts/platform/*.tex`. If these are not `\input` into the body, examiners can't see the depth and the row-count reconciliation (6,555 raw → 1,496/4,407 modelling subset) is invisible. **Fix:** confirm they compile into the thesis, or add a bridging figure/paragraph + forward-cites. *(agents 3, 4)*

6. **CONFORMAL / OOD ABSENT from compiled body.** UQ is computed (89.3% empirical vs 90% nominal coverage in the JSON) but not reported in any compiled chapter; exchangeability/OOD theory sits only in drafts. Defensible as a platform concern, but a 1-paragraph addition to Methodology + one number in ml_results is a cheap rigor gain. *(agents 2, 3, 5, 7)*

7. **PhD/DFT-MD ATTRIBUTION.** The DFT/NEB/AIMD work is collaborative but has no row in the contributions table and `[PhD candidate name]` is still a placeholder. Only discussion.tex:100 credits it. Add one contributions row + fill the name — disarms the "is this the student's work?" attack honestly. *(agent 6)*

8. **claims.csv 0/2 verified** — looks like a stub. Citation integrity itself is otherwise **excellent**: 50 bib entries, 48 cited keys, **0 cited-but-missing**, **100% DOI coverage**, uniform ieeetr, no hallucinated entries (spot-checked Ward2016/Jain2013/Giannozzi2009/Sendek2017 etc.). Populate claims.csv for the high-load claims (0.971, 0.89, LiBiO₂) + cite/delete 2 orphans. *(agent 8)*

9. **CRITERIA DRIFT (process).** `references/criteria.md` and `RUBRIC.md` are mapped to the **2025 specialization-project** rubric, not the 2026 master form. Methods category is now **Scope & complexity (15)** + **Methodological rigor (10)**, not the old Skill/Working-methods/Effort/Independence split; ethics is now explicit. Re-map RUBRIC.md before final. *(thesis-2 direct)*

## STRENGTHS TO DEFEND ALOUD (for the panel debate)

- **The golden thread holds.** All 4 RQs traverse theory→method→result→discussion→conclusion; `tab:disc_rq` re-answers all four with evidence pointers. Zero dangling cross-refs (118 `\Cref`, all resolve). Zero cross-chapter number mismatches. (agent 10)
- **Honesty as method.** Leakage is named and reframed, not hidden; the 0.971/0.89 distinction is set up in Methodology, paid off in Results, synthesised in Discussion — one idea carried cleanly through three chapters. (agents 1, 5, 7, 10)
- **Theory is mechanistic, not recited.** Arrhenius derived from hopping → Nernst-Einstein; EIS bulk vs grain-boundary with LLTO worked example; grouped-CV-as-leakage-diagnostic; Magpie critiqued for structural blindness. Academic foundation 9/10. (agent 2)
- **Substantial, reproducible data engineering.** 8-stage curation, "flag don't fix" provenance, seed-42 reproducibility matching code line-for-line, 5-iteration dataset history with a *retracted* inflated result reported unaltered. (agents 3, 4)
- **Closing-the-loop novelty.** ML candidate → DFT-NEB + AIMD verification on the same composition, benchmarked against β-Li₃PS₄, interpreted soberly. (agent 6)
- **Structure exceeds the approved example thesis** — adds dedicated Verification + Use-of-AI chapters; same IEEE/numeric reference family; `\Cref`/booktabs/siunitx discipline. (agent 9)

## ANTICIPATED CRITIC (thesis-3) LINES + OUR REBUTTALS

- *"0.971 is leakage-inflated overfitting."* → The thesis says so itself and foregrounds the 0.89 grouped holdout; the two are different tasks, not train-vs-test degradation. Self-disclosed, not concealed.
- *"LiBiO₂ is DFT agreeing with DFT, no experiment."* → Abstract + conclusion pre-empt verbatim: "synthesis and EIS still needed."
- *"Numbers don't trace to the metrics file."* → **This one lands** (finding #1). Concede and fix; don't spin.
- *"n=3 holdout is meaningless."* → Conceded in-text; LiBiO₂/DFT is independent corroboration. State n=3 explicitly.
- *"Ethics missing."* → **Lands** vs the 2026 form (finding #3). Cheap fix scoped.

## RECOMMENDED FIX ORDER (cheapest high-leverage first)

1. Strip red wrapper + all `\sv{}` author-questions (≈30 min, unblocks the "finished" read).
2. Regenerate + reconcile `thesis_metrics.json`, wire ml_results to macros (closes the biggest critic hit).
3. Add ethics paragraph to discussion.tex (≈3 sentences, +1–2 pts on the 20-pt criterion).
4. Add AI `@misc` bib entries + `\cite` (compliance flip).
5. Confirm curation/platform drafts compile into the body (Scope visibility).
6. Add contributions-table DFT row + PhD name; populate claims.csv; cite/delete 2 orphans; re-map RUBRIC.md to 2026 form; add Abbreviations page + confirm Norwegian Sammendrag.

— thesis-2 (advocate)
