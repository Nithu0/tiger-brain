# thesis-3 (ADVERSARY) — ROUND 12 (repro "fix" attempted — and it backfired)
**2026-06-09 · @ 4c4465e (2 commits since round 11) · READ-ONLY · fan-out scaled to a 4-file diff**

Commits `6566a73`+`4c4465e` touched Abstract, Methodology, ml_results, references.bib (16 lines). Real attempts at the abstract overclaim + the reproducibility cluster. One genuinely helps; the repro fix introduces a NEW, checkable defect.

## ✅ FIXED / improved
- **N6 (overclaim) — PARTIALLY FIXED.** Abstract:44 "the model **reproduces** the ionic conductivity those earlier calculations suggest" → "the model **predicts an ionic conductivity of the same order of magnitude as** those earlier calculations suggest." Now matches the body's order-of-magnitude framing. *(Remaining N6 half — abstract still doesn't flag DFT/AIMD as collaborator-run — and N7, abstract still carries Jaafreh2024+Muy2018 cites — NOT addressed.)*
- **N12 (data-availability) — addressed in text.** Methodology:359 + ml_results:205 now add the sister-repo URL + commit `c412df9`. Good intent. BUT see the new defect below.
- **M3 (n=3 metric scale-mixing) — FIXED.** ml_results:147 caption now explains the RMSE>MAE gap ("back-transformed conductivity residuals are heavy-tailed, a few high-conductivity points dominating the squared error") and clarifies "123 individual measurement points... not over three single values." Good.
- **Sun2016 bib** — number/pages completed (`e1600225`, no. 11). Minor item closed.

## ⛔ NEW DEFECT (HIGH) — the reproducibility pointer is broken two ways
ml_results:205 now claims: *"The complete pipeline that reproduces the results in this chapter, **including the grouped composition-level holdout of \Cref{sec:ml_validation}**, is available in the sister repository (...commit `c412df9`)."* Verified against the local sister repo `/home/nithu/code/Master-oppgave/battery-electrolyte-predictor`:

1. **`c412df9` is NOT pushed to origin.** It is 1 commit ahead of `origin/main` (`eb67169`); it is on no remote branch. An examiner who opens `github.com/Nithu0/battery-electrolyte-predictor` and looks for commit `c412df9` **will not find it**. The thesis cites a specific public-looking hash that is local-only.
2. **The composition-level 3-holdout is not in that commit.** `src/splitting.py` contains only **DOI/paper-grouped** splitting (`grouped_train_test_split`, `grouped_kfold` — grouped by `COL_DOI`). There is **no three-composition holdout, no sibling/anion-neighbour removal, no `Li5SiN3`/validation-composition list, no `0.89`/`123`** anywhere in `src/` (greps for `holdout|sibling|neighbour|composition-level` and for the validation compositions/`0.89`/`123` return nothing relevant). So the specific code the new sentence promises — the holdout that yields `\valRsq=0.89/\valMAE=0.02/\valRMSE=0.142` — **could not be located** at `c412df9`.

Net: round 10's R1 ("the holdout code isn't in the supplied script") is NOT fixed — it's now a *stronger, falsifiable* claim ("the holdout is reproducible at commit c412df9") that fails on access AND content. → **(a) push `c412df9` and confirm the repo is public; (b) actually add the composition-holdout code that regenerates 0.89/0.02/0.142, or soften the sentence to claim only what the repo contains (DOI-grouped CV + XGBoost training).** *(Fair-flag: I may have missed the holdout if it lives in an unusual file/function — thesis-1 should confirm where 0.89/0.02/0.142 is computed.)*

Note the file architecture R3/R4 IS coherent in the repo: `config.py` makes `merged_dataset.xlsx` a **processed output** of featurisation from `merged_database_classified.xlsx`, so the repo generates it. But the **attached supplementary `ml_training.py` still reads `merged_dataset.xlsx` standalone** (line 31) with no featurisation step attached — so a grader running the *attachment* (not the repo) still hits FileNotFoundError. The attachment and the repo now tell different stories.

## 🟠 STILL PERSIST (untouched this round)
| # | Item | Status | Evidence |
|---|---|---|---|
| C1 | E_hull 0.043→0.046 | PERSISTS | `md_verification.tex:71` |
| C2 | attached ml_training.py reads missing `merged_dataset.xlsx` | PERSISTS | `ml_training.py:31` |
| R1 | holdout code reproducing 0.89/0.02/0.142 | PERSISTS (see new defect — not in c412df9) | — |
| R2 | "123 points" traces to no macro/json (now at least explained) | PERSISTS (minor) | `ml_results.tex:147` |
| H1 | contributions.tex not `\input` | PERSISTS | `main.tex` grep=0 |
| H2 | Kukaraja undisclosed co-author | PERSISTS | `references.bib` |
| N1 | Muy2018→0.296 eV (proven wrong-paper; → Lepley2013 ~0.3 eV) | PERSISTS | `md_verification.tex:152`, `Abstract.tex:48` |
| N2b | bernges→antiperovskite | PERSISTS | `Theoretical_Background.tex:192` |
| N3 | GNN-exclusion clause still `\cite{Hastie2009}` | PERSISTS | `Theoretical_Background.tex:448` |
| N5 | RQ1/RQ2 not answered in conclusion | PERSISTS | — |
| N6b/N7 | abstract DFT/AIMD attribution + 3 cites | PERSISTS | `Abstract.tex` |
| N16b | Einstein factor-of-6 wording | PERSISTS (minor) | `md_verification.tex:656` |

## Regression check — CLEAN
No forbidden term, no em-dash, no broken/undefined cite, conductivity span still consistent, no number/macro drift from these 4-file edits.

## Priority for thesis-1
1. **Repro (new defect): push `c412df9` + ensure the holdout code is actually in it** (or soften the claim). Highest, because it's now a falsifiable statement in the thesis.
2. **N1 keystone** (Muy2018→Lepley2013, ~0.3 eV).
3. **4 blockers** (E_hull, attached-script path, contributions-in-main, co-author disclosure).
4. **N5 RQ1/RQ2 in conclusion; N6b abstract attribution.**
5. N2b / N3 / N7.

Looping; next pass re-attacks on the next tree change.
