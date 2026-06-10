# thesis-3 (ADVERSARY) — ROUND 8 (deeper pass)
**2026-06-09 · @ e889712 + Overleaf auto-syncs · READ-ONLY · 10 subagents · new angles**

Round-7 covered structure/numbers/AI-tells. This round went deeper: **semantic** citation-content checking, physics/equations, figure-caption vs body, table arithmetic, abstract-vs-body, RQ→answer mapping, grammar/UK-English, completeness-vs-exemplar, and a regression check on the 3 new auto-sync commits. The 4 round-7 blockers ALL persist. Below are the **NEW** findings.

---

## ⛔ NEW must-fix (citation correctness — these are defence-grade)

**N1 — KEYSTONE BENCHMARK MAY BE A WRONG-PAPER CITATION.** The β-Li₃PS₄ NEB barrier **0.296 eV** — the single number the whole LiBiO₂ verification is benchmarked against (`md_verification.tex:151-152`, Abstract:48, conclusion:6, `\nebBenchmark`/`thesis_metrics.json:45`) — is cited to **`Muy2018Lattice`**, which is a *lattice-dynamics / phonon-band-centre* paper, **not** a β-Li₃PS₄ NEB study. Published β-Li₃PS₄ barriers (Lepley/Holzwarth 2013) sit 0.2–0.3 eV and are direction-dependent, so the value is plausible — but the *attribution* looks wrong. **Examiner: "Where in Muy 2018 is 0.296 eV?"** This is the load-bearing comparison of Ch.6 and it must be airtight. → verify the exact source/figure of 0.296 eV; re-cite the paper that actually reports it (likely Lepley & Holzwarth).

**N2 — Two more wrong-paper citations in Theory:**
- `Theoretical_Background.tex:11` — lead-acid "30–40 Wh/kg" cited to **`Pinzaru2014JES`**, which is a **garnet (Li₅₊₂ₓLa₃Nb₂₋ₓSmₓO₁₂) synthesis paper** — nothing about lead-acid. → re-cite a battery-tech review (Tarascon2001 is in the bib as a fallback).
- `Theoretical_Background.tex:192` — antiperovskite (Li₃OCl/Li₃OBr) conductivities cited **solely** to **`bernges2018competing`**, which is a **sulfide argyrodite** paper. (Same key at L177 is fine — sulfide.) → cite a real antiperovskite source (Zhao & Daemen Li₃OCl, JACS 2012).

**N3 — `Hastie2009` (general ML textbook) cited for the specific claim that 342 compounds is below the GNN-beats-tabular regime** (`Theoretical_Background.tex:448`). Wrong anchor — the right cites (`Grinsztajn2022Tabular`, `ShwartzZiv2022Tabular`) are two sentences earlier. → re-point.

**N4 — Numbers stated as fact with NO citation:** nitride "~0.2–0.4 eV" (`Theoretical_Background.tex:220`, families table cell); convex-hull "0.05 eV/atom synthetic-accessibility threshold" (`:380`, the actual rule, Jain2013 is cited only for the MP DB not the threshold — Sun 2016 is the usual source); halide "0.1–1 mS/cm…above 10 mS/cm" (`:181`, the cite is on the *next* sentence). → add cites or move them.

*(The serious pass-2 wrong-paper backlog — Buschmann perovskite, Hikima oxy-halide, Kucinskis cell-ageing, Zou halide — is CONFIRMED FIXED/removed. The verification pipeline cleared most of it. N1–N3 are what survived.)*

---

## 🟠 NEW grade-band

**N5 — RQ1 and RQ2 are NEVER answered in the conclusion.** The four RQs (`Introduction.tex:62-65`) are answered only in `discussion.tex:107` (RQ1) and `:109` (RQ2); the conclusion touches only RQ3/RQ4. The 2026 form scores "results clearly linked to the objectives." → add 1–2 sentences to the conclusion closing RQ1/RQ2, or make the discussion's :102-113 the canonical RQ-answer block and cross-ref it.

**N6 — Abstract over-attributes the collaborators' DFT/AIMD to the candidate.** `Abstract.tex:8-10,47-51` presents the DFT-NEB + AIMD in the same first-person project voice as the dataset/ML work, with zero hint the first-principles work was run by the collaboration (disclosed only in `discussion.tex:95`, `ai_disclosure.tex:117-119`). An examiner reading the abstract alone over-attributes the physics to the student. Reinforces H1. → one clause: "…tested against LiBiO₂ using collaborator-run first-principles and MD calculations."

**N7 — Abstract carries 3 `\cite`s** (`Ward2016`:25, `Jaafreh2024`:44, `Muy2018`:48). Abstracts are read detached from the bibliography (repositories/databases) and are conventionally citation-free. → drop all three; the refs reappear in the body.

---

## 🟡 NEW polish

- **N8 — Grammar fragment:** `Theoretical_Background.tex:178` "…modest uniaxial pressure. **Which together explain** both the low E_a…" — sentence can't start with "Which". → comma, or "These…explain". Genuine error a sensor will catch.
- **N9 — Discussion §Implications (`discussion.tex:115-120`) concludes** rather than analyses: `:118` "the most valuable thing this project produced may be the curated dataset itself" (verdict) and `:120` "the productive response is to treat data collection as…a living platform…" (recommendation). Violates the non-concluding convention; the conclusion repeats both. → move verdict/recommendation to the conclusion.
- **N10 — Confidence creep:** `conclusion.tex:4` says the model "has learned **genuine** structure–property relationships" on n=3 evidence; `discussion.tex:33` more correctly says "**consistent with** the model having learned…". → soften the conclusion to match.
- **N11 — Conclusion over-reaches into "living platform" advocacy** (`conclusion.tex:10`, ~40% of the closing) for a deliverable that was never an RQ. → compress to one sentence; let Future Work carry it.
- **N12 — Data-availability statement names no repo/commit** (`ml_results.tex:202-206` says "supplementary files" only), despite CLAUDE.md mandating a GitHub URL + commit hash, and `discussion.tex:100` calls openness "a research-integrity commitment" with no URL/DOI. → add the repo + commit-hash statement, or a Zenodo DOI.
- **N13 — E_a prediction asserted as trivial/feasible 4× but never demonstrated** (`Introduction.tex:74`, `dataset_results.tex:171`, `discussion.tex:93`, `Future_Work.tex:48-50`); the "physical link between σ and E_a" is claimed but no E_a prediction or feasibility number is shown. Reads as hand-waving. → soften the insistence, or drop to one Future-Work mention.
- **N14 — "342 compounds doesn't justify GNN/transformer" (`Introduction.tex:75`) is stated as a hard methodological claim but never quantified** anywhere. Examiner: "why 342? what's the threshold?" → add a one-line justification (tie to Grinsztajn/ShwartzZiv).
- **N15 — vs exemplar (Mjanger 2025, 105 pp):** no **Norwegian Sammendrag** (exemplar has one; standard NTNU, conspicuous to a Norwegian sensor — translate the abstract); **no Appendices at all** (exemplar has 6 — obvious appendix material exists: XGBoost hyperparameter grid, per-family feature table, the 9 screening candidates with σ+E_hull, full validation per-point table, DFT/AIMD convergence params; appendices bank "Form" + "reproducibility" points).
- **N16 — Physics prose nits:** `Theoretical_Background.tex:624` "PBE…systematically overbinds shallow saddle points" is an UNCITED directional claim that its own later source (`Devi2022`, L633) contradicts (Devi finds functional *spread*, not a consistent direction) → drop or replace. `Methodology.tex:656` justifies the Einstein factor-of-6 as "three Cartesian directions and a single mobile species" — the 6 = 2d (d=3); "single mobile species" is the wrong reason → reword. Nernst–Einstein at `Theoretical_Background.tex:335` is the H_R=1 special case written as a plain equality, justified 322 lines later → add a forward-ref clause. (All equations are otherwise physically/dimensionally correct — no CRITICAL physics error.)
- **N17 — Form:** orphan parent-figure labels `fig:md_equilibration`/`fig:md_trajectories_panels` (benign, sub-panels are cited); orphan table label `tab:ai-use` (`ai_disclosure.tex:82`, never \Cref'd — but that file isn't compiled); `fig:data_processing` caption omits axis/violin-width meaning; `Images/data extraction.png` has a **space** in the filename (fragile in zip/transfer → rename to `fig_data_extraction.png`).

---

## ✅ Verified clean this round
- **Regression check on the 3 auto-sync commits (514e7cd, c99fe55, e889712):** NO regression. They softened the algorithm-choice table (removed the over-strong "Highest test-set R²" claim — net improvement), added 2 tabular-ML refs (Grinsztajn/ShwartzZiv), added cross-refs, elaborated the MLP-vs-tree gap. No forbidden term, no em-dash, no locked-number change.
- **Tables:** all arithmetic clean (family counts sum to 6555 exactly; model rows monotonic, XGBoost best, all R²≥0.946 holds with NN=0.946; holdout macros consistent). No CRITICAL.
- **Equations:** Arrhenius (σ-form, correct E_a sign), Nernst-Einstein (dimensionally S/m), Einstein D=MSD/6t (correct for d=3), convex hull, R²/RMSE/MAE — all correct. Units (S/cm↔mS/cm, eV, K/°C, ps/fs) and log10 base consistent.
- **Figures:** no dangling \Cref (0 "??"), no dup labels, all images on disk, Fig 6.2 two-panel (a)/(b) labelling matches caption+body.
- **Spelling:** uniformly UK English (british babel); no US deviations.
- **Cross-refs/cites:** all 48 cite keys resolve; forbidden terms only in non-compiled drafts/.bak.

---

## ↩️ RECONCILIATION — do NOT revert Future_Work.tex:40
One subagent flagged the LiAgent-manuscript mention at `Future_Work.tex:40` as "a regression undoing operator decision c72b6c8 — revert it." **That recommendation is now stale.** The operator explicitly instructed THIS session (2026-06-09) to surface the submitted manuscript in Future Work. So the current text is CORRECT and intended. **Keep the cite + "submitted to J. Power Sources" sentence.** The only live concern remains **H2**: disclose the student's own co-authorship (`references.bib:633` lists Kukaraja as 2nd author) in one sentence, and keep the `@unpublished`/"submitted" hedging (already correct).

---

## 🎯 Updated top defence questions (round-8 deltas)
1. **"Where in Muy 2018 is the β-Li₃PS₄ 0.296 eV you benchmark against?"** (N1 — keystone)
2. **"Your conclusion never answers RQ1/RQ2 — were those objectives met?"** (N5)
3. **"The abstract reads as if you ran the DFT/AIMD — did you?"** (N6/H1)
4. (carried) n=3 holdout statistics; linear-scale headline error; personal-contribution boundary.
