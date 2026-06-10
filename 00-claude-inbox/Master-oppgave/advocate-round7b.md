# thesis-2 (ADVOCATE / FOR) — ROUND 7b (second final pass)
**2026-06-09T11:42Z · working tree (uncommitted veileder edits live) · READ-ONLY, no edits · 10 subagents**
For: thesis-1. This pass reconciles the panel conflict from round 7a and re-grounds every flag on the CORRECTED canonical.

---

## ⚠️ HEADLINE CORRECTION — do NOT revert the E_hull value
**thesis-3 flagged "C1: E_hull 0.043→0.046 BLOCKING". That is WRONG. My own round-7a defect #2 was the same mistake.** Both used the stale round-6 baseline.

- Commit **f217c68** (Jun 5, *after* round-6) deliberately set LiBiO₂ (mp-1205315) to **E_hull = 0.043 eV/atom + density 7.48 g/cm³** to match the actual Materials Project page (operator-provided). The Round-7 brief confirms "0.043 + 7.48 now canonical per f217c68."
- Verified: **0.043 and 7.48 are the ONLY values present; ZERO residue of 0.046 / 7.09 anywhere** in compiled chapters (incl. comma-decimal variants). `md_verification.tex:71`.
- The thesis even adds an honest, correct caveat at `md_verification.tex:73`: "strictly, 0.043 eV/atom is metastable… near-stable" — inside the stated 0–0.05 eV/atom window, consistent with `subsec:convex_hull`. **Airtight against an examiner who pulls mp-1205315.**

👉 **Action for thesis-1: do NOT change 0.043→0.046. Reverting would re-introduce the error.** Tell thesis-3 the C1 flag is retired (stale baseline).

---

## 🔴 REAL defects confirmed (fix before final PDF)
**D1 — `references.bib:633` co-author misspelled `Jafraa, Russlan` → `Jaafreh, Russlan`.**
Same person is `Jaafreh, Russlan` (line 549, own citekey `Jaafreh2024`) and `Jaafreh, R.` (line 11), always alongside Hamad. "Jafraa" on the *Alnubani2026LiAgent* entry is the odd one out — a real typo on the veileder's freshly-requested co-authored manuscript citation. HIGH.

**D2 — reproducibility break in the supplementary pipeline (genuine FileNotFoundError).** Concede-and-fix.
- `ml_training.py:31` reads `merged_dataset.xlsx` → **does not exist**. Real training file is `merged_dataset_filteredfinished.xlsx` (150 cols, has the required `Temp`/`cond(log)`/`material`). The file the **thesis names** as supplementary (`merged_database_classified.xlsx`, in `ml_results.tex:204` + `Methodology.tex:358`) has only 20 cols — **wrong schema, cannot train**. Triple-name mismatch.
- `ml_training.py:32` needs `merged_feature_cols.pkl` (exists, but listed nowhere as supplementary).
- Already tracked: `docs/thesis/SUBMISSION_CHECKLIST.md:23` (issue #78).
- **Minimal fix (Option A):** edit `ml_training.py:31` → `merged_dataset_filteredfinished.xlsx`; add `merged_feature_cols.pkl` + create `requirements.txt` (pandas, numpy, joblib, scikit-learn, lightgbm, xgboost — none exists yet) to the supplementary bundle; sync the two prose filenames (`ml_results.tex:204`, `Methodology.tex:358`). This LOCKS the reproducibility A-criterion (seed 42 determinism is real once the path is right). The author catching it pre-submission (it's in their own checklist) is itself a point in their favour.

**D3 — `main.tex:85` `\date{\today}` prints the compile date on the title page.** Hard-code `\date{June 2026}` (confirm month vs Inspera deadline). Small but real.

---

## 🟠 A-LEVERS — these turn adversary attacks into student credit (advocate-recommended, bounded)
**L1 — Compile the contribution statement (criterion 2.4 "degree of independence", scored).**
`chapters/drafts/contributions.tex` (205 lines, full split table, written *explicitly* for criterion 2.4) is **NOT `\input` in main.tex** — the single most rubric-relevant section the student already wrote is invisible. Add as `\chapter*{Author Contributions}` before References + fill placeholders (Ramzi A. A. Alnubani / Kotiba Hamad). PLUS de-passivise `md_verification.tex:37`: "Density-functional-theory calculations, **performed by the computational collaboration**, were carried out with Quantum ESPRESSO…". This simultaneously removes an over-claim (honesty↑) and makes the student's real core (dataset + ML pipeline + screening + LiBiO₂ selection) legible (independence↑). Strongest single lever.

**L2 — One co-authorship disclosure sentence (fixes "undisclosed self-citation").**
The student (Kukaraja) is **2nd author** of the cited manuscript, presented as a neutral group ref. Append to `Future_Work.tex:40`: *"The author of this thesis is a co-author of that manuscript, having contributed the dataset and prediction model described here; no result in this thesis depends on the platform."* Credits the student AND closes the transparency gap. Citation stays bounded (one appearance, Future-Work-only, `@unpublished`+"submitted").

**L3 — One linear-scale sentence removes the last methodology handhold.**
Headline error is only ever in log10. Add after the headline metrics (`ml_results.tex` ~L83): *"On the linear scale these correspond to a typical error of ~10^0.158≈1.44× (MAE) and ~10^0.283≈1.92× (RMSE) in σ — within a factor of 1.5–2 across more than eleven orders of magnitude."* (verified). **Do NOT add a per-compound Arrhenius baseline or grouped-CV R²** — that needs the V3/V4/grouped machinery the operator dropped, and the thesis already declines the generalisation claim such a baseline would defend.

---

## 🟡 Precision tightening (optional, keeps FOR-case intact)
- **"independently predicts" (Abstract:44, Intro:54/65/RQ4):** mild overclaim — Ch.6 verifies Li *mobility* (NEB ~0.27 eV / AIMD), not a σ-to-σ match. `discussion.tex:84` already concedes this; abstract/intro should match it. Bounded rewrite: "produces a conductivity estimate consistent with prior work, with facile Li⁺ transport supported by independent DFT/AIMD." Resolves an abstract↔discussion tension.
- **Abstract "1987–2026":** LEGIT + sourced (`dataset_results.tex:8,71` — earliest/latest publication year in the DB). Not a defect. Optionally macro-ise (`\dataYearMin/Max`) so it can't drift. My round-7a flag #3 is downgraded to "verified fine."
- **n=3 holdout:** actually aggregates **123 temperature points** (`ml_results.tex:148`) — a bootstrap CI on R²_log=0.89 is cheap and kills the "n=3" framing if you want it. A+ polish, not required.
- **MSD plot (Q4):** no MSD-vs-time figure exists, only 3D trajectory scatter. Adding one MSD(t) plot showing the linear diffusive regime is the cheapest way to pre-empt "show the diffusive regime." Requires a new figure — beyond "null feil," flag as optional.

## 🟢 Verified CLEAN (FOR-case)
- **AI-flag risk for compiled PDF: LOW.** 0 prose em-dashes, none of the flagged vocab, no synthetic triads in analytical prose. The ~5 em-dashes all live in `ai_disclosure.tex` which is **NOT compiled** (routed to the Inspera AI form) — zero PDF risk. Only clean `docs/thesis/ai_declaration_source.md` (goes on the form). Today's edits (acks Ramzi, FW manuscript) read clean; only soft tell = acks:18 "stands on the shoulders of an open-source ecosystem" (stock idiom, optional).
- **Borrowed figures all carry in-caption source cites** (`battery.png`→\cite{EVSahiHai2025}, `fig_sse_nature.png`→\cite{Famprikis2019NatMater}); both keys resolve. No attribution ding.
- **Front matter complete** (title, TMM4960, Dept of Mechanical & Industrial Eng, Supervisor Kotiba Hamad, author Nithusan Kukaraja, Lists of Abbreviations/Symbols). No placeholders.
- **Static integrity** (re-confirmed): all \Cref/\cite/\includegraphics/macros resolve; no active red wrappers; guardrails clean; numbers consistent.
- **Methodological honesty** is the FOR-case's spine: the interpolation/temperature-leakage caveat is stated in **4–5 places** (`ml_results.tex:119-138`, `Methodology.tex:259-272`, `discussion.tex:20,45,33`). The adversary's "honesty" charge actually fails — the honesty is present and thorough.

## Adversary top-5 → advocate posture
1. R²=0.971 interpolation → **STRONG** (pre-empted verbatim `ml_results.tex:129-138`). 2. n=3 holdout → **ADEQUATE** (123 pts, bootstrap CI available). 3. Own contribution → **ADEQUATE** → L1 fixes it. 4. Single AIMD/Haven=1 → **ADEQUATE**; premise partly false (thesis explicitly *refuses* to assume Haven / quote NE conductivity, `md_verification.tex:59-66`) — only gap is the missing MSD plot. 5. Self-citation → **disclosed & bounded**; D1 typo + L2 disclosure close it.

## Commit hygiene
Working tree re-adds the `\cite{Alnubani2026LiAgent}` that commit c72b6c8 dropped. Operator now WANTS the manuscript surfaced → the working tree is the desired state. **Commit it** (after D1–D3) so the repo stops contradicting its own HEAD. Don't revert.

## Bundle (for operator)
A = `main.pdf` (compile AFTER D1–D3; none exists yet). B = full LaTeX source (root + 11 chapters + 28 images incl. space-named `Images/data extraction.png`). C = supplementary code: `ml_training.py` + `merged_dataset_filteredfinished.xlsx` (the real one) + `merged_feature_cols.pkl` + new `requirements.txt`. AI-declaration form uploaded separately. **Open Q for operator: does Inspera (TMM4960) want PDF-only, or PDF + source + code?**

---
### Net advocate verdict
A-capable, submission-clean once **D1 (Jaafreh typo) + D2 (repro path) + D3 (\date)** are fixed — three small, contained fixes, none in prose quality. The 3 A-levers (L1 contribution statement, L2 co-author disclosure, L3 linear-scale sentence) are cheap and each credits the student further. **The single most important thing: do NOT revert 0.043→0.046.**

— thesis-2 (advocate)
