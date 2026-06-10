# thesis-4 (DOMMER) — ROUND 7 FINAL pre-delivery verdict — 2026-06-09 @ working-tree (uncommitted)

Independent 10-agent judge sweep. Advocate (thesis-2) + adversary (thesis-3) ROUND-7 reports were dispatched in parallel and may post after this; this verdict is **independent** and will be reconciled if/when they land.

## VERDICT: SUBMISSION-CLEAN. Zero must-fix. Grade band B+/A- (~84/100).
The two operator-requested changes landed correctly in the working tree and verify clean cross-chapter. The only true action item is mechanical: **recompile the PDF** before zipping (none exists).

---

## 1. Operator's two changes — VERIFIED

**(a) Ramzi A. A. Alnubani added to acknowledgments** — `acknowledgments.tex:10-12`
- Placed immediately after supervisor Kotiba Hamad (line 6) — "alongside Kotiba" as the supervisor asked. ✓
- Name spelling EXACT match to `references.bib:615` (`Alnubani, Ramzi A. A.`). ✓
- "led the manuscript" supported — Ramzi is FIRST author in the bib. ✓
- "now submitted for publication" matches bib note. ✓

**(b) Manuscript-submitted in Future Work** — `Future_Work.tex:38-46`
- "submitted to the \emph{Journal of Power Sources}" + `\cite{Alnubani2026LiAgent}` restored; resolves to `references.bib:614` (`@unpublished`, note "Manuscript submitted to Journal of Power Sources"). Prose ↔ bib consistent. ✓
- Header comment (`Future_Work.tex:4-6`) no longer self-contradicts the cite. ✓

**(c) The c72b6c8 reversal is CLEAN.** The last commit dropped the cite as "unpublished/group-work-without-manuscript"; the working tree re-adds it as "submitted." Full cross-chapter sweep: **zero stale "unpublished / no manuscript" wording** anywhere. Manuscript + LiAgent + Alnubani appear ONLY in Future_Work + acknowledgments (+ bib) — never in chapters 1-7; generic "platform" mentions in discussion/conclusion are forward-looking and defer to \Cref{chap:future_work}. No double-claims, no content leak. Working-tree diff touches exactly 3 files (acks, FW, bib) — nothing unexpected.

## 2. Full submission-readiness — all PASS/CLEAN
- **Numbers / macro-lock:** every number matches `thesis_macros.tex` / canonical facts. 0.043 eV/atom + 7.48 g/cm³ are canonical (per f217c68); zero stale 0.046/7.09. No forbidden methods (SHAP/OOD/conformal/HistGBM/MP-as-feature/R²≈0.14/polymer) in any built chapter — grep hits were "shaped/shapes" false positives.
- **Citations:** 48 cite keys, 0 undefined; ~91 \Cref, 0 dangling; bib well-formed, 0 dup keys; Alnubani entry good.
- **Figures:** all 28 referenced images exist; 0 stale-backup references; Fig 6.2 is two-panel (cell + supercell); Fig 4.1 is the 4407-based current version.
- **Compile-readiness (static):** 0 active red markers (`\sv{}`/red wrappers all gone), balanced braces/envs, 0 dup labels, all macros defined. (No latex toolchain present → no real build run.)
- **AI-flag risk: LOW.** Both freshly-edited regions essentially clean. Humanizer passes are sufficient.

## 3. NON-BLOCKING — operator's call (none gate submission)
1. **CONCERN (only substantive one):** `acknowledgments.tex:10` credits Ramzi with "helped build and extend the LiAgent platform that this thesis feeds into," but `ai_disclosure.tex:113-121` frames the PhD candidate's contribution narrowly as DFT/AIMD and never names LiAgent. Mild inconsistency / soft over-claim. Operator should confirm the platform-building credit is accurate (it likely is — just not corroborated by the disclosure text). 1-line fix if desired.
2. AI-ism residue (cosmetic, LOW): "broader platform" (`Future_Work.tex:40`); doubled "landscape" (`discussion.tex:70`); acks "go beyond what these pages show" + double rule-of-three (`acknowledgments.tex:6-9`). Leaving them is fine.
3. `Images/data extraction.png` filename contains a SPACE — compiles but fragile; verify it renders in the final PDF (or rename to underscore).
4. Stale, **un-built** files in `chapters/`: `plan.tex` + `Methodology.tex.bak` contain forbidden terms (conformal/SHAP/HistGBM/Ea≈0.65). Not in the build, but do NOT ship them in any source zip.
5. A-lever (NICE-TO-HAVE, needs a pipeline run — code/thesis-2 domain): report a composition-grouped-CV R² alongside 0.971 + the n=3 holdout. Converts the main honest weakness into a number; could nudge B+→A. Not gating.

---

## 4. SUBMISSION ZIP / FILE CHECKLIST (Inspera)
Mechanics: upload **one thesis PDF** + (optionally) **one supplementary ZIP**; AI-declaration is a **separate form**.

**PRIMARY (uploaded separately, NOT in the zip):**
- [ ] `main.pdf` — **MUST GENERATE.** No compiled PDF exists in the repo. Recompile `main.tex` AFTER today's acks + Future_Work edits (and after committing). This is the one true action item.

**SUPPLEMENTARY ZIP (the thesis text explicitly promises these two → effectively required):**
- [ ] `ml_training.py` (repo root) — EXISTS
- [ ] `merged_database_classified.xlsx` (repo root) — EXISTS

**Optional supplementary (operator discretion):**
- `merged_dataset_filteredfinished.xlsx`, `merged_feature_cols.pkl`, `LiBiO2.cif`, `references/claims_verified.csv`

**SEPARATE NTNU form (NOT in zip, easy to forget):**
- [ ] AI-declaration form — fill from `docs/thesis/ai_declaration_source.md` / `chapters/ai_disclosure.tex`; upload as its own Inspera attachment.

**Do NOT include:** `chapters/drafts/**`, `*orig*.png`/`*STALE_backup*` figures, `~$Final.PPTX`, `.venv/`.

Ready-to-run supplementary-zip command (for thesis-1/operator to run from repo root, after the PDF is built):
```bash
cd /home/nithu/code/Master-oppgave
zip thesis_supplementary.zip ml_training.py merged_database_classified.xlsx
# optional: add LiBiO2.cif merged_dataset_filteredfinished.xlsx merged_feature_cols.pkl references/claims_verified.csv
```

## 5. Decisive grade factors
1. Discussion (20-pt criterion) is genuinely A-level — coherent argument, ethics + limitations + RQ-revisit present.
2. Theory chapter depth is exceptional.
3. Scope broad and ambitious.
4. Ceiling: generalization rests on n=3 holdout, no grouped-CV number (honesty caps the claim, doesn't raise it).
5. DFT/AIMD is collaborative (honestly disclosed).

Benchmark (Eksempel master oppgave / Mjanger 2025, experimental wet-lab, ~B/B+): this thesis sits **at or slightly above** that band — stronger theory + discussion + reproducibility; thinner independent generalization evidence.

**Bottom line: submittable as-is. Build the PDF, zip the two supplementary files, don't forget the AI form. Everything else is optional polish.**
