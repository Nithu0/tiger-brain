> **CORRECTION 2026-06-13 (post-verdict, operator-confirmed):** MUST-FIX #1 (density 7.48→7.09) and advisory #2 (E_hull 0.043 vs 0.046) are **RETRACTED**. The current canonical MP page for mp-1205315 (materialsproject.org, database v2026.04.13) shows **7.48 g/cm³ and 0.043 eV/atom** — matching the thesis exactly. The subagent fetched the stale `legacy.materialsproject.org` endpoint (old 7.09/0.046). The thesis LiBiO2 numbers are correct; commit f217c68 was right. Remaining real items below: #3 bib typo, #4 supplementary code, #5 figure attribution.

# thesis-4 (JUDGE) — ROUND 9: fresh verification of round-8 MUST-FIX at HEAD 6be032b — 2026-06-13

10 disjoint READ-ONLY subagents, each re-checked against ground truth (live MP page, manuscript PDF, the dataset xlsx, the actual .tex/.py files) at the **current** HEAD `6be032b` (moved since round 8, which was at the working tree of 2026-06-09). Purpose: which round-8 MUST-FIX items actually landed, and what is the final submission verdict.

## Headline: only 1 of 6 round-8 MUST-FIX items was fixed.
Round-8 fixes #1 (density), #3 (bib typo), #4 (supplementary code), #5 (figure attribution) are **all still open** at HEAD. #2 (E_hull) downgrades to advisory. #6 (abstract overclaim) is the only one resolved. The thesis is statically compile-clean, numbers match macros exactly, AI-flag risk is LOW — but it is **not yet submission-clean**: there are 4 short correctness/integrity MUST-FIXes plus the standing grade-lever.

---

## 🔴 MUST-FIX before the PDF is built

**1. LiBiO₂ density is unsourced and publicly refutable — `md_verification.tex:70-71`: `7.48` g/cm³.**
GROUND TRUTH this round: live `legacy.materialsproject.org/materials/mp-1205315` (HTTP 200) shows **density 7.09 g/cm³**, E_hull 0.046, P4/nmm. The manuscript (`manusscript.pdf`) states **no density at all**. So 7.48 has ZERO corroboration — it contradicts the live page and is unsupported by the manuscript. An examiner refutes it in 5 s on the public page. **→ change to 7.09.** (Note: advocate-round7b defended 7.48 as "canonical per f217c68"; that defence is wrong — f217c68's premise was "matching the MP page," and the live page says 7.09. The shared-context canonical facts also say 7.09 / 0.046. **Reject the advocate's "do not revert" instruction on density.**)

**2. LiBiO₂ E_hull — `md_verification.tex:71`: `0.043` vs live `0.046` (ADVISORY, not blocking).**
File = 0.043, which **matches the manuscript** (0.043) but differs from the live MP page (0.046; MP recomputes hulls over time). Because it does NOT contradict both sources, it is below the MUST-FIX bar — the stability conclusion holds either way (both inside 0–0.05 eV/atom). BUT the thesis attributes 0.043 to "the Materials Project entry," which the live page now contradicts. **Operator choice:** either set to 0.046 (publicly verifiable, matches density fix to the same source) or keep 0.043 and re-attribute it to the manuscript/original DFT snapshot rather than the live MP entry. Recommend 0.046 + 7.09 together so both numbers cite one consistent source.

**3. Co-author surname misspelled — `references.bib:661`: `Jafraa, Russlan` → `Jaafreh, Russlan`.** (round-8 #3, NOT fixed — entry renumbered 633→661.)
Same person is `Jaafreh, Russlan` at `:549` and `Jaafreh, R.` at `:11`. The odd-one-out `Jafraa` sits inside `@unpublished{Alnubani2026LiAgent}` — the supervisor's freshly-requested co-authored citation, where a co-author will notice. HIGH.

**4. Supplementary code does not run — `ml_training.py:31` + triple filename mismatch.** (round-8 #4, NOT fixed.)
- `ml_training.py:31` reads `merged_dataset.xlsx` → **does not exist** → `FileNotFoundError`. The only file with the right schema (4408 rows, 145 Magpie + `material`/`Temp`/`cond(log)`) is **`merged_dataset_filteredfinished.xlsx`** (150 cols).
- Thesis prose names the WRONG 20-col file `merged_database_classified.xlsx` in `Methodology.tex:358`, `ml_results.tex:202`, `ai_disclosure.tex:50`, `docs/thesis/SUBMISSION_CHECKLIST.md:23` (tracked as issue #78) — that file cannot train the model. So `ml_results.tex:202` "Together they reproduce the results" is currently false.
- `merged_feature_cols.pkl` exists (145-name list, loads clean) but is listed nowhere as supplementary. No root `requirements.txt` (only one in `battery-electrolyte-predictor/`, not bundled).
- Minimal fix: edit `ml_training.py:31` → `merged_dataset_filteredfinished.xlsx` (or ship it renamed to `merged_dataset.xlsx`); sync the four prose locations to that name; bundle `ml_training.py` + that xlsx + `merged_feature_cols.pkl` + a `requirements.txt`; git-track them (only `ml_training.py` is tracked now).

**5. Borrowed figure missing attribution — `Methodology.tex:79-83` (`fig_origin_digitiser.png`).** (round-8 #5, NOT fixed.)
The image is a screenshot of the OriginPro GUI containing a **digitised published Arrhenius plot** (visible subfigure label "(d)", composition series x=0…0.4), with NO source `\cite` and no OriginLab acknowledgment. Copyright/integrity lapse. The other three borrowed figures (`battery.png`, `fig_sse_schematic.png`, `fig_sse_nature.png`) ARE correctly attributed — this one is the lone gap. Add a `\cite` to the source plot + acknowledge OriginLab; ideally digitise from an already-cited source.

---

## 🟠 SHOULD-ADDRESS (cheap, grade-band — criterion 2.4 / rigor)

**6. De-passivise DFT/AIMD attribution at the point of use — `md_verification.tex:37` & `:50`.**
"DFT calculations were performed…" / "AIMD was carried out…" read as the author's own work, in the 280-line chapter that showcases the most impressive technical content. The only compiled attribution-away is one buried sentence in `discussion.tex:95`. Add ~2 sentences at the head of the Computational Methods section naming that NEB/AIMD were done by the computational collaboration (PhD candidate R. A. A. Alnubani). This simultaneously removes an over-claim and raises the independence/rigor criterion.

**7. Compile the Author-Contributions section — `chapters/drafts/contributions.tex` is `\input` NOWHERE.**
206 lines written explicitly for criterion 2.4 (degree of independence), with the full own-vs-collaboration split table — invisible to the examiner. Wire it into `main.tex` as `\chapter*{Author Contributions}` before References, AFTER resolving its `[PhD candidate name]`/`[Supervisor name]` placeholders (lines 84/86/109/111) and checking its `\cref{sec:ai-disclosure}` target exists (ai_disclosure.tex is not compiled → that cref would dangle). Strongest single grade lever the student already authored.

**8. Render the self-citation disclosure — `Future_Work.tex:40`.**
The candidate (Kukaraja) is 2nd author of `Alnubani2026LiAgent`, but the only co-authorship note is a non-rendered LaTeX **comment** (`FW:6`). The rendered PDF gives no disclosure. Add one sentence: e.g. *"The author of this thesis is a co-author of that manuscript, having contributed the curated dataset and the prediction model the platform is built around; the platform engineering and the manuscript were led by R. A. A. Alnubani."* Closes the transparency gap and credits the candidate. Citation stays bounded (single appearance, FW-only, `@unpublished`+"submitted" — correct).

---

## 🟢 NICE-TO-HAVE / OPTIONAL
- **Grouped/composition-CV R²** (RUBRIC #67 pipeline run) — the cheapest A-lever: one number that converts "generalisation rests on n=3" into a quantified claim on the highest-leverage methods criterion. Theory (`subsec:groupkfold`) + holdout protocol already set it up.
- Macroise the hard-coded literals in Abstract/ml_results/dataset_results (correct today, but unguarded against a pipeline rerun; conclusion + discussion already use macros).
- `acknowledgments.tex:9` ("in ways that go beyond what these pages show") + `:18` ("stands on the shoulders of an open-source ecosystem") — the two softest AI-tells in the body; thin them. `Future_Work.tex:32` trailing participle.
- Linear-scale error sentence in `ml_results.tex` (~L83): MAE 0.158 log10 ≈ 1.44×, RMSE 0.283 ≈ 1.92× — within 1.5–2× across eleven orders. Removes the last methodology handhold.
- `main.tex:85` `\date{\today}` → hard-code submission month.
- Em-dashes in the NTNU AI-form text (`ai_declaration_source.md`, `ai_disclosure.tex`) — clean before pasting into the web form; NOT a PDF defect.

## 🚫 FALSE ALARMS — do NOT "fix"
- **`ai_disclosure.tex` em-dashes** are NOT in the PDF — main.tex:216-222 explicitly excludes the file (it goes to NTNU's separate AI form). Body chapters have 0 prose em-dashes (discussion/conclusion confirmed). Do not touch.
- **GroupKFold appears in compiled Theory** (`subsec:groupkfold`) but is used correctly as *background motivation* for the composition holdout, NOT claimed as a result — defensible, leave it. SHAP/OOD/conformal/HistGBM/R²≈0.14 appear ONLY in uncompiled `plan.tex`/`Methodology.tex.bak` → will not surface in the PDF.
- **Polymer / Materials Project** in compiled text are explicit out-of-scope framing (polymer) and verification-stage/future use (MP entry mp-1205315; never a model feature) — not defects.
- **`\sv{}` markers**: zero active in any chapter; the 3 grep hits are the macro definition (main.tex:32) + comments (28-29). Do NOT strip.
- **Year range 1987–2026**: verified against the data, real DOIs. KEEP.

## ✅ Reconfirmed clean
- Abstract σ-overclaim **resolved** (round-8 #6): now "an ionic conductivity of the same order of magnitude as those earlier calculations suggest" + honest "fall short of experimental confirmation"; consistent across Abstract/Intro/RQ4/discussion/conclusion/md_verification.
- All numbers match `thesis_macros.tex`/`thesis_metrics.json` exactly (R²=0.971, 6555/4407/187/452/342/146/9, family table sums to 6555 incl. 21 nitrides, holdout 0.89, NEB 0.27 vs 0.296, 127 atoms, 740 °C, eleven orders). No prototype-value leak (1496/R²0.14/DOI-grouped absent).
- 52 cite keys, 0 dangling; discussion is cite-free (0 \cite); all 8 spot-checked \Cref targets genuinely support their sentences.
- 26-28 \includegraphics all resolve; two-panel Fig 6.2 (cell + supercell) intact.
- Discussion stays non-concluding (defers verdict at lines 13/105/120); conclusion concludes (verdict line 8 + recommendation line 10). Clean division.
- Front matter correct (title, TMM4960, Dept of Mech & Industrial Eng, supervisor Kotiba Hamad, List of Symbols, X.Y.Z numbering).
- AI-flag risk LOW; statically compile-clean (0 undefined refs/macros, 0 duplicate labels in compiled set).
- Note: Future Work is **no longer red** (the round-6 "one intentional red wrapper" is gone — renders as normal text). If the operator still wanted a draft marker there, it's absent; otherwise this is fine.

## VERDICT
**Substance: strong B+ / A− (upper-B band, ~80–84; A-capable ≥85 if the grouped-CV R² lever lands).** Theory + discussion are A-level on coherence; thin generalisation (n=3 holdout) and the collaborative DFT are the ceiling. Benchmarked against `Eksempel master oppgave.pdf` (a high-B/low-A experimental thesis), this sits squarely comparable — same battery-materials domain, computational vs experimental modality, similar quality ceiling.

**Submission-readiness: NOT yet clean.** 4 MUST-FIX (density #1, bib typo #3, supplementary code #4, figure attribution #5 — all short, all correctness/integrity) + 1 advisory (E_hull #2) + 2 cheap should-address that double as grade levers (#6 DFT attribution, #7 contributions section). **Round-8's MUST-FIX list was largely NOT applied** — only the abstract overclaim landed. After #1/#3/#4/#5 land and the PDF compiles, it is clean to submit; #6/#7/grouped-CV are the difference between upper-B and A.

**Two an external sensor catches fastest:** the density 7.48 (#1, refutable on the public MP page) and the FileNotFoundError supplementary script (#4, a reviewer who runs it).

## Submission bundle (after fixes)
- PRIMARY: `main.pdf` — **MUST GENERATE** (none exists in repo), recompile after fixes.
- SUPPLEMENTARY zip: `ml_training.py` (path fixed) + `merged_dataset_filteredfinished.xlsx` (as `merged_dataset.xlsx`) + `merged_feature_cols.pkl` + `requirements.txt`. NOT `merged_database_classified.xlsx`.
- SEPARATE: NTNU AI-declaration form (from `docs/thesis/ai_declaration_source.md`).

— thesis-4 (JUDGE), 10 subagents, READ-ONLY, incorporated round-7/8 FOR/AGAINST history; this round is a fresh ground-truth re-verification at HEAD 6be032b.
