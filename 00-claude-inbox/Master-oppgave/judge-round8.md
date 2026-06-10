# thesis-4 (DOMMER) — ROUND 8: adjudicated reconciliation of FOR/AGAINST + corrected verdict — 2026-06-09

Reconciles advocate (`advocate-round7-final.md`) + adversary (`thesis-3-round7.md`) against my own round-7 verdict, each contested point verified against GROUND TRUTH (live Materials Project page, the in-repo manuscript PDF, the dataset xlsx, the actual files). 10 fresh subagents.

## ⚠️ I am CORRECTING my round-7 verdict.
Round 7 said "zero must-fix, keep 0.043/7.48." That was wrong on the LiBiO₂ numbers — I trusted commit f217c68 without checking the live MP page. The advocate + adversary were right to flag it (though for the wrong reason — the round-6 lock). There is now a real, short MUST-FIX list. None are structural; the thesis is still a strong B+/A- on substance. But it is NOT yet "null feil."

---

## 🔴 MUST-FIX before the PDF is built (integrity/correctness)

**1. LiBiO₂ density is wrong — `md_verification.tex:71`: `7.48` → `7.09` g/cm³.**
GROUND TRUTH: I fetched the live MP page (`legacy.materialsproject.org/materials/mp-1205315`, HTTP 200, server-rendered HTML) — it states **Density 7.09 g/cm³**, **E_hull 0.046 eV/atom**, space group P4/nmm. The manuscript (`manusscript.pdf`) gives E_hull 0.043 and **no density at all**. So 7.48 has ZERO corroboration; f217c68's "matching the MP page" was mistaken on density. An examiner can refute 7.48 in 5 seconds on the public page. **Change to 7.09.**

**2. LiBiO₂ E_hull — `md_verification.tex:71`: reconcile `0.043` (split evidence).**
Live MP = **0.046**; manuscript = **0.043** (MP recomputes hull energies over time). Both sit inside the 0–0.05 eV/atom window, so the *stability conclusion is unaffected either way*. But the thesis currently attributes 0.043 to "the Materials Project entry mp-1205315," which the live page contradicts. **Operator: open the mp-1205315 page yourself and set the number to what it shows (currently 0.046); OR keep 0.043 and re-attribute it to the manuscript/original DFT snapshot — not to the MP page.** Recommend matching the live page (0.046) since that is publicly verifiable. Add an `\ehull`/`\density` macro while you're at it.

**3. Co-author surname misspelled — `references.bib:633`: `Jafraa, Russlan` → `Jaafreh, Russlan`.**
Same person spelled "Jaafreh, Russlan" at `references.bib:549` and "Jaafreh, R." at `:11`; canonical published name is **Jaafreh** (verified via his indexed papers with Kotiba Hamad). This is on the citation the supervisor explicitly asked to add — a co-author would notice. NB the submitted manuscript byline itself typo'd it as "Jafraa" (its own reference list uses "Jaafreh") — worth telling Ramzi for the manuscript, but the thesis bib should use the correct **Jaafreh**. HIGH.

**4. Supplementary code does not run — `ml_training.py:31` + thesis text mismatch.**
Script reads `merged_dataset.xlsx` → does NOT exist → `FileNotFoundError`. The ONLY file with the required schema (4407 rows, all 145 Magpie features + `material`/`Temp`/`cond(log)`) is **`merged_dataset_filteredfinished.xlsx`**. The file the thesis text + checklist name (`merged_database_classified.xlsx`, 20 cols) is the wrong one — it crashes the script. Fix:
- `ml_training.py:31` → read `merged_dataset_filteredfinished.xlsx` (or ship it renamed to `merged_dataset.xlsx`).
- Supplementary zip = **`ml_training.py` + `merged_dataset_filteredfinished.xlsx` + `merged_feature_cols.pkl`** (the .pkl is loaded at line 32 and was missing from the manifest).
- Reconcile the thesis text naming the wrong file: `Methodology.tex:358`, `ml_results.tex:204`, `ai_disclosure.tex:51`, `docs/thesis/SUBMISSION_CHECKLIST.md:22-23` all say `merged_database_classified.xlsx` → should name the file that actually reproduces.

**5. Borrowed figure missing attribution — `Methodology.tex:79` (`fig_origin_digitiser.png`).**
It is a screenshot of the OriginPro GUI containing a **digitised published Arrhenius plot**, with NO source `\cite` and no software acknowledgment — an integrity/copyright lapse. (The other 3 borrowed figures — `battery.png`, `fig_sse_nature.png`, `fig_sse_schematic.png` — ARE correctly attributed.) Add a `\cite` for the source plot + acknowledge OriginLab; ideally use a plot from an already-cited source.

**6. Abstract overclaim — `Abstract.tex:43-46`: "reproduces the ionic conductivity those earlier calculations suggest".**
The thesis never matches a σ value; Ch.6 produces a model Arrhenius *extrapolation* and DFT/AIMD confirm *mobility* (NEB ~0.27 eV, mobile Li sublattice). `discussion.tex:84` + `conclusion.tex:6` concede this honestly — so the abstract contradicts the body. Change "reproduces the ionic conductivity" → "produces a conductivity estimate; DFT-NEB and AIMD independently confirm facile Li⁺ transport." (`Theoretical_Background.tex:374` even states the thesis does NOT reproduce the phonon-DOS computation, so there is no σ anchor to "reproduce.")

## 🟠 SHOULD-ADDRESS (cheap, grade-band)

**7. De-passivise DFT/AIMD attribution — `md_verification.tex:37` & `:50`.** "calculations were performed" reads as the author's own; the only handoff is one buried line at `discussion.tex:95`. Name the computational collaboration at the point of use (~2 sentences). (Adversary slightly overstated "a scored Degree-of-independence criterion" — in the 2026 form independence is folded into Rigor/10pt — but the fix is still worth it.)

**8. Disclose co-authorship — one sentence at `Future_Work.tex:40`.** The candidate (Kukaraja) is 2nd author of `Alnubani2026LiAgent`, presented as a neutral "in the group" reference. Add e.g.: *"The author is a co-author of this manuscript, contributing the curated dataset and the prediction model the platform is built around; the platform engineering and the manuscript were led by R. A. A. Alnubani."* Keep the cite (`@unpublished`+"submitted" is correct). Discloses the self-citation AND credits the candidate — matches the operator's intent.

## 🟢 NICE-TO-HAVE / OPTIONAL
- Align `Introduction.tex:54` + RQ4 `:65` wording with the softened σ-vs-mobility claim (#6).
- Grouped/composition-CV R² + linear-scale error factor (MAE 0.158 log10 ≈ 1.44×) — needs a pipeline run; the standing A-lever.
- Macroise dataset numbers incl. `\YearMin`/`\YearMax` (1987/2026), E_hull, density (currently hard-coded literals; values correct today but unguarded against a pipeline rerun).
- n=3 holdout mixed-scale note (M3); `\date{\today}` → hardcode submission month (M6).
- Clean em-dashes in the **NTNU AI-form text** (`ai_declaration_source.md:12,26` + `ai_disclosure.tex:15,17,60,62`) before pasting — this is form text, NOT in the PDF.

## 🚫 FALSE ALARMS — do NOT "fix" (would INTRODUCE errors)
- **"1987–2026 date range untraceable"** (advocate #3) — WRONG. Verified against the data: min year **1987**, max **2026**, real DOIs; also appears in `Methodology.tex:95` + `dataset_results.tex:8`, not abstract-only. KEEP.
- **"3 active `\sv{}` red markers, strip before compiling"** (zip agent) — FALSE. The 3 grep hits are the `\sv` macro *definition* (`main.tex:32`) + 2 *comments* (`main.tex:28-29`). ZERO active red markers in any chapter. Do NOT strip; keep the `\sv` definition. PDF is not gated on this.
- **Model IDs `claude-opus-4-7` / `claude-sonnet-4-6`** (`ai_disclosure.tex:15,16,87`) — REAL released IDs. Do NOT "correct" them.

## ✅ Reconfirmed clean (round 7 holds)
Ramzi ack placement + spelling; manuscript-submitted framing + `\cite{Alnubani2026LiAgent}` resolves; c72b6c8 reversal is clean (working tree is the desired state — **commit it**, M7); all other numbers match macros (R²=0.971, 6555/4407/187/452/342/146/9, NEB 0.27 vs 0.296, 127 atoms, 740 °C, eleven orders); all 48 cites resolve, 0 dangling refs; 28 figures exist, none stale; body-prose AI-flag risk LOW; statically compile-clean.

## VERDICT
**Substance: strong B+/A-** (discussion + theory A-level; thin generalization + collaborative DFT are the ceiling). **Submission-readiness: 6 MUST-FIX (all short, all correctness/integrity — not quality) + 2 cheap should-address.** Round-7's "zero must-fix" is retracted. After items 1-6 land and the PDF recompiles, it is clean to submit. The density (#1) and the abstract overclaim (#6) are the two an external sensor is most likely to catch.

## Zip (after fixes)
- PRIMARY: `main.pdf` — MUST-GENERATE (none exists), recompile after fixes.
- SUPPLEMENTARY zip: `ml_training.py` + `merged_dataset_filteredfinished.xlsx` (as `merged_dataset.xlsx`) + `merged_feature_cols.pkl`. NOT `merged_database_classified.xlsx`.
- SEPARATE: NTNU AI-declaration form (from `docs/thesis/ai_declaration_source.md`).
- LaTeX source: not required by Inspera (open Q for operator/supervisor).
