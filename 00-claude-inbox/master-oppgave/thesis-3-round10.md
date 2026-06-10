# thesis-3 (ADVERSARY) — ROUND 10 (tree changed; fixes landing)
**2026-06-09 · @ 8b14330 (2 new commits since round 8) · READ-ONLY · fan-out scaled to the 41-line diff**

thesis-1 is actively applying round-8 fixes. This round verifies what landed, confirms what persists, and surfaces a **major new reproducibility cluster** + a definitive verdict on the keystone benchmark.

---

## ✅ FIXED this round (verified)
- **N2 Pinzaru** → lead-acid now cites `Tarascon2001Nature` (`Theoretical_Background.tex:11`). *(minor: Tarascon2001 now appears 4× in that one paragraph — redundant; and it's a Li-focused review used for a lead-acid number, slightly weaker on-topic than Pinzaru was. Defensible, not blocking.)*
- **N4** hull-threshold 0.05 eV/atom → `Sun2016Metastability` (added to bib, DOI verified real); LLZO offset → `Murugan2007/Buschmann2012`.
- **N8** grammar fragment "Which together explain" → fixed.
- **N16 Nernst-Einstein** H_R=1 now forward-referenced at first appearance (`Theoretical_Background.tex:657`→`subsec:arrhenius_ne`).
- **Citation hygiene:** xgboost→`ChenGuestrin2016XGBoost`, lightgbm→`Ke2017LightGBM` (both DOI-verified; *Ke2017 page range is wrong — bib says 3146–3154, canonical is 3149–3157, minor*).
- **Abstract** "every record"→"essentially every record" (more honest); **ml_results** "fixed before model selection"→"fixed by cross-validation on the training set" — this RESOLVES the round-8 hyperparameter ambiguity (now consistent with Methodology). Extrapolation clause softened.
- **Conductivity max `3×10²→2×10²` mS/cm** — VERIFIED CONSISTENT: zero `3×10²` survivors anywhere; "more than eleven orders" still holds (1e-9→2e2 = 11.3 OoM). No regression.
- **Regression sweep across all 8 edited files + bib: CLEAN.** No forbidden term, no prose em-dash, no broken/undefined cite or ref, no duplicate bib key.

---

## ⛔ NEW high-severity — REPRODUCIBILITY (defence-grade; deeper than the round-7 path issue)

**R1 — The supplied `ml_training.py` does NOT contain the composition-level holdout that produces the generalisation result.** The script performs only the random 80/20 split + 5-fold CV (lines 42–139). There is **no composition holdout, no sibling removal, no three-composition validation** anywhere in it. Yet `\valRsq=0.89 / \valMAE=0.02 / \valRMSE=0.142` is the thesis's **only** generalisation evidence and is carried in the **abstract** (`Abstract.tex:38`), **conclusion** (`conclusion.tex:4`), and **discussion** (`discussion.tex:31,46,111`). `ml_results.tex:202-205` + `Methodology.tex:356-359` advertise the script "reproduce[s] the results in this chapter." At the defence: *"Show me where the held-out validation is computed"* → no answer in the supplied code. **This is the strongest open item.**

**R2 — "123 individual measurement points" (`ml_results.tex:147`) traces to nothing** — not in `thesis_macros.tex`, not in `thesis_metrics.json`, not in any script. A free-floating quantitative claim in a table caption (unlike 4407/342, which DO trace).

**R3 — Following the thesis literally, the pipeline cannot run.** `ml_training.py:31` reads `merged_dataset.xlsx` (does not exist). The file the thesis NAMES as the supplement, `merged_database_classified.xlsx`, has 20 columns and lacks `material`/`cond(log)`/`Temp` → KeyError. The only file with the right 150-col featurised schema, `merged_dataset_filteredfinished.xlsx` (4407×150), is **never named** in the thesis. (This is C2 escalated: not just a missing file — the named substitute has the wrong schema.)

**R4 — Featurisation absent from deliverables.** The matminer/Magpie step and the `6555→4407 / 452→342` parser-attrition that Methodology rests on (`Methodology.tex:215-224`) are in no supplied script (`ml_training.py:32` just loads pre-computed `merged_feature_cols.pkl`). The attrition is asserted, not reproducible.

→ Net: the "reproducible pipeline / data-availability" claim is **materially false as written**. Fix = ship the actual end-to-end script (featurisation + holdout) pointing at the correctly-named file, or honestly scope the availability statement to what's provided.

---

## ⛔ KEYSTONE — N1 CONFIRMED WRONG-PAPER (with the correct source)
WebSearch-verified: **`Muy2018Lattice`** (Muy et al., "Tuning mobility and stability… lattice dynamics," EES 2018) is a phonon-band-centre paper — it does **NOT** report a 0.296 eV β-Li₃PS₄ NEB barrier (it uses an ~0.5 eV *experimental* Ea from elsewhere). The defensible primary DFT-NEB source is **Lepley, Holzwarth & Du 2013 (PRB 88, 104103)** → 0.2–0.3 eV (direction-dependent). **No paper pins exactly "0.296 eV"** — so the value is over-precise as well as mis-attributed. → re-cite Lepley2013 and soften `\nebBenchmark` to ~0.3 eV (or "0.2–0.3 eV"). This number is in `md_verification.tex:152`, `Abstract:48`, `conclusion:6`, and `thesis_metrics.json:45` — the benchmark the whole LiBiO₂ verification rests on.

---

## 🟠 STILL PERSIST (unchanged this round)
| # | Item | Status | Evidence |
|---|---|---|---|
| C1 | E_hull 0.043→0.046 | PERSISTS | `md_verification.tex:71` |
| C2 | ml_training reads missing file (now see R3) | PERSISTS | `ml_training.py:31` |
| H1 | contributions.tex not `\input` | PERSISTS | `main.tex` grep = 0 |
| H2 | Kukaraja undisclosed co-author | PERSISTS | `references.bib:659` |
| N1 | Muy2018→0.296 eV | PERSISTS (now proven wrong-paper, see above) | `md_verification.tex:152` |
| N2b | **bernges2018→antiperovskite L192** | **PERSISTS** (a subagent mislabeled this "FIXED" but its own quote shows `\cite{bernges2018competing}` unchanged at L192 — only Pinzaru was swapped) | `Theoretical_Background.tex:192` |
| N3 | GNN-exclusion clause still cites only `Hastie2009` | PERSISTS | `Theoretical_Background.tex:448` (Grinsztajn/ShwartzZiv were added to the *preceding* sentence, not this clause) |
| N16b | Einstein factor-of-6 "single mobile species" wrong reason | PERSISTS (minor) | `md_verification.tex:656` |

Plus the round-8 grade-band/polish items not touched this round: N5 (RQ1/RQ2 absent from conclusion), N6/N7 (abstract over-attributes DFT/AIMD + carries 3 cites), N9–N15 (discussion-concludes, conclusion creep/platform, data-availability no repo/commit, E_a hand-waving, "342<GNN" unquantified, no Sammendrag/appendix), N17 (form: `data extraction.png` space, captions, orphan labels).

---

## 🎯 Top open items for thesis-1, by severity
1. **R1+R3+R4 reproducibility** — supplied script doesn't produce the holdout, reads a non-existent file, named supplement has wrong schema. Highest new risk.
2. **N1 keystone** — re-cite Lepley2013, soften 0.296→~0.3 eV.
3. **4 blockers** (E_hull, ml_training path, contributions-in-main, co-author disclosure).
4. **N5** RQ1/RQ2 in conclusion; **N6** abstract DFT/AIMD attribution.
5. **N2b** bernges antiperovskite; **N3** Hastie→Grinsztajn on the GNN clause; **R2** untraceable 123.

Looping continues; next pass re-attacks on the next tree change.
