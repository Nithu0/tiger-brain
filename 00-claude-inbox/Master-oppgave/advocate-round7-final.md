# thesis-2 (ADVOCATE / FOR) — ROUND 7 FINAL pre-submission report
**2026-06-09T11:28Z · @ working tree (uncommitted veileder edits live) · READ-ONLY, no edits made**
For: thesis-1 (coordinator). 10 disjoint subagents. This is the last advocate pass before the operator submits.

---

## TL;DR for thesis-1
The thesis is **A-capable and clean end-to-end**. The two new veileder requests are **already in the working tree and verified correct**. Compile-clean, figures-clean, guardrails-clean, numbers locked — **except 3 real defects** that must be fixed before the final PDF is built. None are structural; all are 1-line fixes. I fixed nothing (panel rule) — they are yours/operator's to apply.

### 🔴 3 DEFECTS TO FIX (ranked)
1. **`references.bib:615` — co-author surname misspelled on the NEW manuscript citation.**
   `author = {... and Jafraa, Russlan and ...}` → should be **`Jaafreh, Russlan`** (same person is spelled `Jaafreh, Russlan` at `references.bib:549`, the group's phonon-DOS paper). This is on the *Alnubani2026LiAgent* entry the veileder just asked to add — a co-author would notice. **HIGH priority** (it's literally the veileder's request).
2. **`chapters/md_verification.tex:68` — two wrong LiBiO₂ numbers in one sentence.**
   density `7.48` g/cm³ → should be **`7.09`** (canonical, DRIFT); E_hull `0.043` eV/atom → should be **`0.046`** (canonical; 0.043 is the manuscript value explicitly on the *forbidden* list per round-6 lock). Both contradict the locked canonical facts. Recommend also promoting both to macros in `thesis_macros.tex`. **HIGH priority** (contradicts mp-1205315 page the operator confirmed).
3. **`chapters/Abstract.tex:15` — "reported between 1987 and 2026" date span is untraceable.**
   This date range appears ONLY in the abstract; no macro or chapter carries it. Either verify it against the dataset and (ideally) macro-ise it, or drop the clause. **MEDIUM** (single unsourced abstract fact = the one number the adversary can poke).

---

## Veileder requests — VERIFIED DONE in working tree (FOR-case strengthener)
- **Acknowledgments (`acknowledgments.tex:10–12`):** Ramzi A. A. Alnubani named correctly, **immediately after** Kotiba Hamad, with an accurate, humble, well-bounded contribution ("helped build and extend the LiAgent platform … led the manuscript … now submitted"). Reads natural, no AI tell, no overclaim. **PASS.**
- **Future Work §The LiAgent Platform (`Future_Work.tex:40`):** submitted-manuscript mention is forward-looking-only, self-citation appropriately framed, no manuscript *content* pulled into the main report. `\cite{Alnubani2026LiAgent}` **resolves** (`references.bib:614`, `@unpublished` — correct type). Venue/status consistent across ack + FW + bib note. **PASS** (modulo defect #1, the co-author spelling).
- **Advocate value:** crediting the PhD collaborator + the submitted manuscript *strengthens* the thesis — honest authorship boundary (pre-empts "whose work is this?"), real-world impact (work feeds a peer-review-bound platform), and it's correctly placed in Future Work so no unpublished claim props up the thesis's own conclusions. Examiner risk of citing unpublished work is low and mitigated by `@unpublished` + "submitted".

---

## Clean-bill checks (all PASS)
- **Compile-readiness:** COMPILE-CLEAN. 48 \cite all resolve; 105 labels, 0 undefined \Cref/\ref, 0 duplicate labels; 28 \includegraphics all exist; all macros defined; **0 active `\sv{}` red notes; 0 active red wrappers** (Future Work is now un-redded). Cosmetic only: 5 uncited bib entries (incl. dead SHAP/OOD/conformal refs — harmless, dropped by ieeetr) + 32 orphan labels.
- **Figures:** FIGURES-CLEAN. 27 active figures, all referenced, all canonical (no `_orig/_prev/STALE_backup` variant active), captions free of placeholders/AI-isms, caption numbers match canonical facts. Fig 6.2 confirmed two-panel (unit cell + supercell), caption neutral on atom count.
- **Guardrails:** GUARDRAILS-CLEAN. No SHAP/OOD/conformal/HistGBM/R²-0.14/V3-V4 in main chapters (only in `plan.tex`, which is NOT `\input` by main.tex). Materials Project appears only as verification-stage structure lookup (mp-1205315) and theory/future-work, **never as a model feature** — discussion.tex:9 states this explicitly. Polymer/composite appear only in explicit out-of-scope declarations. Feature set consistently "145 Magpie + temperature (146)".
- **Numbers:** All headline numbers match locked macros + canonical facts (R²=0.971/0.283/0.158, holdout 0.89/0.02/0.142, 6555/187/452/9, 4407/342/146, family table incl. 21 nitrides summing to 6555, Ea ~24%, processing <15%, span "more than eleven orders", temp max 740 °C, NEB ~0.27 vs 0.296 eV, Li31Bi32O64/127 atoms). **Only** defect #2 drifts.
- **AI-flagging:** Risk **LOW**. 0 prose em-dashes anywhere, no inflated vocab, no vague attributions, no filler hedges. Only residual fingerprint: **7 "not X but Y" negative-parallelisms** (3 in discussion.tex, 3 in Theoretical_Background.tex, 1 in Future_Work.tex), plus the data-not-algorithm motif repeated verbatim across discussion. Operator's call — defensible academic rhetoric, not a hard tell. Optional 5-min polish list in appendix.
- **Argument coherence:** Spine **LANDS** (data-is-bottleneck argued, not restated; discussion non-concluding; conclusion concludes). All 4 RQs closed. No internal contradictions. **No hard claim-overreach.** 4 *soft* spots, all optional 1-word fixes (appendix).

---

## ADVOCATE FOR-case (criterion-mapped, evidence-backed)
Mapped against the MTP 2026 Standard Assessment Form (100 pts / 12 criteria) + RUBRIC + Eksempel-thesis benchmark. STRONG on every high-weight criterion:
- **Scope & complexity (15 pt):** curation (187 papers→6555 meas→452 comp) + 5-model ML + DFT/NEB/AIMD = three modes, not one. Strongest card.
- **Analysis & discussion (20 pt, decisive):** thesis-level argument (data > model); uncertainties section; **ethics section** (2026 form's new clause) tied to the work; processing-exclusion defended by the <15%-reporting figure (hardest-to-attack datum).
- **Rigor (10 pt):** seed 42, pinned versions, released code+data, composition-level holdout, first-principles cross-check — directly answers the new "reproducibility" clause.
- **vs Eksempel thesis (Mjanger 2025, 105 pp):** this thesis is a **structural superset** (adds List of Symbols, AI disclosure, Future Work) and **clearly exceeds** on reproducibility, methodological breadth, and table count (13 vs ~2). Only the example's raw figure count leads (35 vs 27) — narrow, genre-explained (experimental vs computational), outweighed by figure originality.

**Strongest one-sentence "why this is an A":** A substantial hand-curated 6,555-measurement open database + reproducible 5-algorithm pipeline (XGBoost R²=0.971) + closed-loop first-principles LiBiO₂ verification, where every headline number is self-limited in-text and the data-not-the-algorithm thesis is argued from both modelling and physics — satisfying the 2026 form's new reproducibility and ethics clauses.

**5 strengths worth amplifying (no new work):** (1) name the curated dataset as a *primary result* co-equal with the model in the abstract's last line; (2) keep the R²-self-limitation paragraph adjacent to the 0.971 table; (3) surface the reproducibility sentence once in the conclusion; (4) cross-ref the <15% figure at first feature-set mention (already done); (5) foreground the ML↔first-principles cross-disciplinary span in abstract/intro.

---

## SUBMISSION ZIP MANIFEST (for the operator — confirm portal needs first)
No `main.pdf` exists in the repo yet → **must compile before submitting** (`pdflatex → bibtex → pdflatex ×2`), **after** defects #1–#3 are fixed.

**Bundle A — graded PDF deliverable (Inspera usually wants only this):**
- `main.pdf` (compile it)

**Bundle B — full reproducible LaTeX source (have it ready in case the portal/supervisor asks):**
- Root: `main.tex`, `thesis_macros.tex`, `references.bib`
- Chapters (exactly the 11 `\input` by main.tex): `acknowledgments, Abstract, Introduction, Theoretical_Background, Methodology, dataset_results, ml_results, md_verification, discussion, conclusion, Future_Work` (all under `chapters/`)
- 28 images under `Images/` (incl. `NTNU_logo.png` and the space-named `Images/data extraction.png`)
- Optional: `results/thesis_metrics.json` (source-of-truth for numbers; NOT needed to compile — macros are baked into thesis_macros.tex)
- AI-declaration form → uploaded separately to Inspera (from `chapters/ai_disclosure.tex`), NOT inside either bundle.

**EXCLUDE (must NOT be zipped):** `.git/ .claude/ .judge_work/`, the whole `battery-electrolyte-predictor/` sister repo, `chapters/Methodology.tex.bak`, `chapters/drafts/`, `chapters/ai_disclosure.tex` + `chapters/plan.tex` (not \input), all `*:Zone.Identifier`, `~$Final.PPTX`, all PPTX/DOCX/XLSX/PKL raw assets, all reference/example PDFs, `LiBiO2.*`, every unused/`_orig/_prev/STALE_backup` image, `Images/_backup_pre_pptx/`, project meta-docs (`CLAUDE.md README.md RUBRIC.md SYNC.md ...`), `audio/ logs/ figures/`, LaTeX build artifacts (`*.aux *.log *.bbl ...`).

**Open question for operator:** Does the NTNU/Inspera MTP portal require only `main.pdf`, or also the full LaTeX-source zip? That decides A vs A+B.

---

## Appendix — OPTIONAL polish (operator's call; not defects)
**"not X but Y" softening (AI-flag LOW):** discussion.tex:13, :57, :61; Theoretical_Background.tex:75, :228, :506; Future_Work.tex:54.
**Soft overreach (1-word fixes, make predict-then-verify airtight):** conclusion.tex:6 "confirms"→"demonstrates"; Abstract:46 "predicts the conductivity prior work suggests"→"predicts facile transport, consistent with the candidacy"; RQ4/conclusion separate the model's *modest-σ* output from the NEB/AIMD *facile-hop* finding; conclusion:4 "indicate"→"support the reading" (symmetry with discussion's "consistent with").

— thesis-2 (advocate)
