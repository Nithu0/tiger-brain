# thesis-3 (ADVERSARY) — ROUND 7 / FINAL pre-submission verdict
**2026-06-09 · @ working-tree state · READ-ONLY, no edits made · 10 subagents**

Scope this round adds two operator asks: (1) PhD candidate **Ramzi A. A. Alnubani** added to acknowledgments next to Kotiba — DONE, present at `acknowledgments.tex:10-12`; (2) the **submitted LiAgent manuscript** surfaced in Future Work — DONE, `Future_Work.tex:38-40`. Both landed. My job is to attack what remains.

**Bottom line:** the thesis is in genuinely good shape and the body would not trip an AI-detector. It is NOT yet "null feil." There are **2 blocking data/repro defects**, **3 grade-band levers**, and a cluster of polish items. None are in the prose quality — they are in numbers, attribution, and the supplementary bundle.

---

## ⛔ CRITICAL — fix before submit (blocking)

**C1 — E_hull contradiction: thesis says 0.043, round-6 locked it to 0.046.**
`md_verification.tex:68` states "energy above the convex hull of $0.043$~eV/atom." Round-6 brief is explicit: *"E_hull stays 0.046 eV/atom (operator-confirmed from the mp-1205315 page; manuscript's 0.043 is NOT to be used."* The thesis is carrying the **forbidden manuscript value**. Two independent subagents flagged this. There is no `\ehull` macro, so it is unguarded. → **Operator/thesis-1 reconcile: change 0.043 → 0.046, or confirm the lock was reversed.** This is the single hardest integrity snag.

**C2 — Reproducibility break: the attached training script can't find its data.**
`ml_training.py:31` reads `merged_dataset.xlsx`; that file **does not exist** in the repo (only `merged_dataset_filteredfinished.xlsx` and the promised `merged_database_classified.xlsx`). Line 32 needs `merged_feature_cols.pkl`, which exists but is **not listed anywhere** as a supplementary file. A grader running the attached script against the attached DB gets `FileNotFoundError`. The thesis (ai_disclosure.tex) promises deterministic regeneration. → Either point the script at the file actually shipped + add `merged_feature_cols.pkl` to the bundle, or rename. The repo's own `docs/thesis/SUBMISSION_CHECKLIST.md#78` already flags this.

---

## 🚫 NOT a defect — do not "fix" (false alarm caught)

**The `claude-opus-4-7` / `claude-sonnet-4-6` model IDs in `ai_disclosure.tex:15,87` are REAL and CORRECT.** One subagent claimed they "don't exist" — that is wrong (it reasoned from stale training data). `claude-sonnet-4-6` is a released ID; Opus 4.7 is a real model. **Leave the disclosure model ids alone.** Flagging so nobody edits a valid id into an invalid one.

---

## 🟠 GRADE-BAND LEVERS (the gap to an A is evidence + attribution, not prose)

**H1 — Personal contribution boundary is not delineated in the *compiled* thesis.**
DFT/NEB/AIMD (all of Ch.6) were done by the computational collaboration, but `md_verification.tex:37` uses agentless passive ("calculations were performed") that reads as the author's own work. The only explicit handoff in the compiled document is a half-sentence at `discussion.tex:95`. A full `chapters/drafts/contributions.tex` exists ("performed independently by the author", etc.) but is **NOT `\input` in main.tex**. "Degree of independence" is a scored 2026 criterion. → cheapest fix: compile a contributions statement + de-passivise `md_verification.tex:37` ("calculations, performed by the computational collaboration, ...").

**H2 — Student is an undisclosed co-author of the manuscript the thesis cites.**
`references.bib:615` author list = `Alnubani, Kukaraja, Jafraa, Hamad` — the candidate (Kukaraja) is **2nd author** of `Alnubani2026LiAgent`, yet `Future_Work.tex:40` and the acknowledgments present it as a neutral group reference. An examiner pulling the bib sees undisclosed self-citation. The `@unpublished` + "submitted to J. Power Sources" hedging is correct and the cite appears ONLY in Future Work (no result rests on it), so **keep it** — but add one sentence disclosing co-authorship. This simultaneously fixes the transparency gap AND legitimately credits the student for platform work (currently near-zero visible credit). Aligns with the operator's intent to surface the manuscript. *(Also confirm 3rd-author spelling "Jafraa, Russlan" against the real author list.)*

**H3 — Headline error never translated to linear scale; no leak-free/grouped CV number.**
Best clean methodological hits, neither pre-empted: (a) MAE=0.158 log10 = a **~1.44× factor** on σ, RMSE=0.283 = **~1.92×** — the results chapter reports headline error only in log10; the only mS/cm figures shown are the flattering n=3 holdout ones. (b) The grouped/composition-level protocol is *described* (`Methodology.tex:274-293`) but **no DOI-/composition-grouped CV R² is ever reported** — only n=3. A-lever #3 from the RUBRIC still open. → at minimum add one sentence stating the linear-scale factor + a per-compound Arrhenius baseline as the floor; ideally one pipeline run reports a grouped-CV R².

---

## 🟡 MEDIUM / polish

- **M1 — AI-tells are confined to `ai_disclosure.tex` (NOT compiled).** All 4–5 prose em-dashes in the entire source live in `ai_disclosure.tex:15,17,60,62` (+ a quoted one at :9). Ironic that the AI-disclosure chapter is the only em-dash carrier — but it is routed to the NTNU Inspera form (`main.tex:216-222`), not the PDF, so **zero em-dashes render in the thesis body**. Clean them in the source/`docs/thesis/ai_declaration_source.md` since that text goes on the form. Body prose verdict: **LOW AI-flag risk** (no delve/leverage/underscore/furthermore/moreover; humanizer worked). Minor: rule-of-three at `Introduction.tex:16` and back-to-back triads at `acknowledgments.tex:6-9`; "stands on the shoulders of an open-source ecosystem" (`acknowledgments.tex:18`) stock idiom.
- **M2 — RQ4 / Abstract "independently predicts" overclaims Ch.6.** `Abstract.tex:45`, `Introduction.tex:54,65` say the model "independently predicts" LiBiO₂ conductivity, but Ch.6 only produces a model Arrhenius *extrapolation* + confirms Li *mobility* (no independent σ value to match). `discussion.tex:84` concedes this honestly. → soften RQ4 wording to "produces an estimate consistent with prior work; facile Li⁺ transport supported by independent DFT/AIMD."
- **M3 — n=3 holdout metrics mix scales.** R²_log=0.89 (log) reported alongside MAE=0.02 / RMSE=0.142 mS/cm (linear); RMSE is ~7× MAE → one point dominates. Never discussed. Add a half-sentence.
- **M4 — Macros wired only into discussion+conclusion.** Abstract/Intro/dataset_results/ml_results/md_verification hard-code every canonical number (0.971, 6555, 4407, 342, 0.27, 127, ...). Values currently match `thesis_metrics.json` (PASS, no contradiction today), but a pipeline rerun would silently desync 5 chapters. Not blocking; long-term hygiene.
- **M5 — Figure quality + attribution.** `Images/data extraction.png`, `battery.png`, `fig_sse_nature.png`, `fig_origin_digitiser.png` are screenshot/borrowed-grade vs the clean exported plots; confirm borrowed figures (battery schematic, sse_nature) carry a source citation in-caption. Form ding.
- **M6 — `\date{\today}` (`main.tex:85`)** prints the compile date — hard-code submission month before final upload.
- **M7 — Working tree vs commit c72b6c8.** Latest commit message says it *dropped* the LiAgent cite + bib entry; working tree **re-adds both** (consistent, cite resolves at `references.bib:614`, compiles clean). Given the operator now WANTS the manuscript surfaced, the working-tree state is the desired one → **commit it** so the repo stops contradicting its own HEAD. Don't revert.

---

## ✅ Verified clean (defensive notes)
- **Static integrity:** every `\Cref`/`\ref` resolves (0 dangling `??`); all 28 `\includegraphics` point at canonical files (no `_orig`/`_backup`/`STALE` variants referenced); 0 active red/draft wrappers (the "one remaining red wrapper" expectation is stale — there are none); `Methodology.tex.bak`/`plan.tex`/`drafts/` not `\input`; all macros defined.
- **Citations:** all 48 cite keys resolve in references.bib; no duplicate keys, no fake DOIs.
- **No forbidden leftovers** (SHAP/OOD/conformal/MP-as-feature/polymer/HistGBM/R²0.14/V3/V4) anywhere in the compiled chapters — all hits are in the non-compiled `plan.tex` or are legitimate (GroupKFold *described* as method, MP as data-source/verification, polymer explicitly out-of-scope).
- **Numbers consistent:** 6555/187/452/9 → 4407/342/146, conductivity "more than eleven orders ~1e-9→3e2 mS/cm", temp max 740 °C, AIMD 127 atoms/5.8 ps — all internally consistent. Only numeric contradiction is C1 (E_hull).
- **Methodological honesty:** the temperature-leakage interpolation caveat is stated in FOUR places (`ml_results.tex:119-138`, `Methodology.tex:259-272`, `discussion.tex:20,45`); imbalance, single-AIMD, composition-only ceiling all conceded. This pre-empts the leakage attack well.

---

## 🎯 Top-5 defence questions (ranked by grade-band risk)
1. **"0.971 is interpolation along Arrhenius lines (temp is a feature) — why is it the headline, and what does ML add over a per-compound Arrhenius fit?"** Pre-empted as a caveat but no baseline reported. (H3)
2. **"n=3 holdout — what's the CI on R²=0.89, and why are R²(log) and MAE/RMSE(linear) mixed in one headline?"** Conceded but unquantifiable. (M3/H3)
3. **"Strip out the collaborators' DFT/AIMD and the PhD's platform — what is uniquely YOUR master's contribution, and where does the thesis say so?"** Weakest-defended; only `discussion.tex:95`. (H1)
4. **"Single 5.8 ps AIMD, one vacancy, Haven=1 — verification or one noisy point? Show the MSD diffusive regime."** Well-hedged; residual = no MSD-plateau plot, and the chapter title says "Verification".
5. **"You cite an unpublished manuscript you co-authored — appropriate, and disclosed?"** (H2/C1 — the manuscript's 0.043 E_hull also leaked into the thesis.)

## 📦 Zip manifest → see thesis-3 handoff in thesis-1 inbox (full A/B/C checklist).
