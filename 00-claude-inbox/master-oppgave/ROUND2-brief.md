# Judge-panel ROUND 2 — full pre-discussion analysis (2026-06-03 PM)

Assigned by thesis-1. This is the operator's **most important check so far** — be exhaustive on **language, sources, figures, coherence**. Everything must be perfect. Mindset: **finpuss only — do NOT make drastic changes; flag big errors to thesis-1, don't fix them yourself.** READ-ONLY on the repo (report only; no edits, no git). Run up to **10 subagents** (Agent tool, not Workflow).

## What changed since round 1 (re-review against current state)
- All result/figure figures refreshed from the latest PPTX: **fig 3.1** curation-flow (large fonts), **3.2** squiggles removed, **4.1/4.6** updated, **5.2** enlarged, **5.3** named version + "mS/cm" (was "m.S"), **6.1** screening, **6.7** LiBiO2 Arrhenius with RT-conductivity + composition label, plus the **SSE Nature figure** (`fig_sse_nature.png`, "Reproduced from Famprikis 2019") in Theory.
- **LiBiO2 structure corrected to mp-1205315: tetragonal P4/nmm, 8 atoms/cell, 7.09 g/cm³, E_h = 0.046 eV/atom.** AIMD cell stated as 32 formula units (Li31Bi32O64, 127 atoms) — the wrong "2×2×2" multiplier removed.
- Discussion rebuilt earlier: random-split R²=0.971 headline + 0.89 holdout + LiBiO2; RQ-table; **ethics section + external-literature comparison (4 cites) added**; abbreviations list added; RUBRIC remapped to the 2026 form; AI disclosure moved to the separate NTNU form (brief ack reference kept).

## Canonical facts (flag anything that drifts)
Random 80/20 split seed 42 → XGBoost R²=0.971 / RMSE=0.283 / MAE=0.158 (log10); 5 models all R²≥0.946. Holdout (3 random comps Li5SiN3, Li1.25Al0.25Zr1.75(PO4)3, Li6.5P0.5Si0.5S5I) → R²_log=0.89, MAE 0.02 mS/cm, RMSE 0.142 mS/cm. Dataset 6,555 meas / 187 pubs / 452 comps → 4,407 rows / 342 compounds / 146 features. LiBiO2 mp-1205315 (P4/nmm), NEB 0.27 eV vs β-Li3PS4 0.296 eV (Muy 2018), single 300 K AIMD.

## Ignore (operator-owned, still red — do NOT score as errors, but you MAY analyse the content around them)
- The 6 §7 `[Spørsmål til deg]` red author-questions in discussion.tex (operator is answering them now).
- The `[Pending data]` red flag on tab:family_counts (new filtered file pending from supervisor).
- The red `\begingroup\color{red}` wrappers on Conclusion + Future Work.

## Focus areas (assign across your 10 subagents)
1. **Language — top priority.** Hunt every trace of AI/robotic phrasing and non-British spelling across all chapters; produce a find→replace list (thesis-1 applies them; you don't edit). British English, ` --- ` em-dashes, no filler.
2. **Sources.** Every `\cite` actually supports its sentence; flag wrong-paper / overreach / uncited claims; check `references/claims*.csv` if useful.
3. **Figures.** Every figure referenced in text, caption matches the (updated) image content and the macros, no orphans, no off-page/overflow, units correct (watch for any residual "m.S").
4. **Coherence & flow** chapter-to-chapter; the golden thread Intro→…→Conclusion; any leftover dropped-prototype concept (SHAP/OOD/conformal/GroupKFold-as-headline/MP-features/polymer/R²0.14/HistGBM) is a serious flag.
5. **Against the 2026 assessment form + `Eksempel master oppgave.pdf` (an A thesis)** — where does this stand, what are the gaps.

## Roles
- **thesis-2 = ADVOCATE (FOR):** strongest honest case for the grade; defend design choices; map strengths to each 2026 criterion; the 5 things to amplify. → `advocate-round2.md`
- **thesis-3 = ADVERSARY (AGAINST):** harshest sensor; every weakness/overclaim/source-gap line-referenced; the 5 most dangerous defence questions. → `adversary-round2.md`
- **thesis-4 = JUDGE:** weigh FOR vs AGAINST against criteria + example thesis; grade-band verdict + prioritised fix-list (most needle-movement first); rule each adversary attack valid/partial/overstated. → `judge-round2.md`

Deliverables → `~/Obsidian/Brain/00-claude-inbox/master-oppgave/`. One feed.md line on done.
