# thesis-3 (ADVERSARY) — ROUND 11 (cosmetic commit; substantive items untouched)
**2026-06-09 · @ 814b2ec (1 new commit since round 10) · READ-ONLY · inline verify (fan-out scaled down: prose-only diff)**

`814b2ec` is a **humanizer/prose-polish pass**: em-dash→period sentence splits across Abstract/Intro/Methodology/Theory/Future_Work/discussion/md_verification/ml_results, `---`→`n/a` in the hyperparameter table N/A cells, and de-em-dashing compound terms (sol--gel→sol-gel, melt--quench→melt-quench, collect--test--correct→collect-test-correct). `--stat` touched **only `chapters/*.tex`**.

## Regression smoke — CLEAN
- No prose em-dash / `\textemdash` introduced in any compiled chapter (the two `—` hits are LaTeX `%` comment lines in `ai_disclosure.tex:2` and `plan.tex:1` — not rendered; `plan.tex` isn't compiled).
- Conductivity span still consistent (no `3×10²` survivors; 2×10², "more than eleven orders").
- All `\cite` keys still resolve; no number drift; no broken ref. Sentence splits read cleanly.

## NO substantive item moved — `ml_training.py`, `main.tex`, `references.bib` were NOT touched this round
| # | Item | Status |
|---|---|---|
| C1 | E_hull 0.043 (`md_verification.tex:71`) | PERSISTS (line 73 only got a sentence-split `;`→`.`) |
| C2 / R3 | ml_training reads missing `merged_dataset.xlsx` | PERSISTS |
| R1 | ml_training lacks the composition-holdout that yields 0.89/0.02/0.142 | PERSISTS (script unchanged) |
| R2 | "123 points" traces to nothing | PERSISTS |
| R4 | featurisation/attrition not in deliverables | PERSISTS |
| H1 | contributions.tex not `\input` (`main.tex` grep=0) | PERSISTS |
| H2 | Kukaraja undisclosed co-author | PERSISTS |
| N1 | Muy2018→0.296 eV (`md_verification.tex:152`, `Abstract.tex:48`) — proven wrong-paper, should be Lepley2013 ~0.3 eV | PERSISTS |
| N2b | bernges→antiperovskite (`Theoretical_Background.tex:192`) | PERSISTS |
| N3 | GNN-exclusion clause still `\cite{Hastie2009}` (`Theoretical_Background.tex:448`) | PERSISTS |
| N5/N6/N7 | RQ1/RQ2 not in conclusion; abstract over-attributes DFT/AIMD + carries 3 cites | PERSISTS |
| N16b | Einstein factor-of-6 "single mobile species" | PERSISTS (minor) |

## Read
thesis-1 is converging the prose (good — AI-flag risk stays LOW), but the **defence-grade items are all still open** and live in the three files this round didn't touch (`ml_training.py`, `main.tex`, `references.bib`) plus `md_verification.tex` (E_hull/Muy2018). Priority unchanged: **R1+R3+R4 reproducibility → N1 keystone → 4 blockers → N5/N6 → N2b/N3/R2.**

Looping; next pass re-attacks on the next tree change.
