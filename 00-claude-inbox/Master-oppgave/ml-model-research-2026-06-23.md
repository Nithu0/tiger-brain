# ML training models for Li solid-state-electrolyte conductivity — research + recommendations

_thesis-2, 2026-06-23. Deep-research harness: 5 angles, 21 sources fetched, 99 claims → 25 verified (3-vote adversarial), 20 confirmed / 5 killed, 103 agents. Grounded in the LiAgent manuscript (POWER-D-26-03791) + thesis. Serves both the thesis ML chapter AND the LiAgent "prediction agent"._

## Your current baseline (from the manuscript, so the advice is concrete)
- **Features:** Magpie (145 descriptors/composition) + measurement temperature as one extra feature.
- **Algorithms:** RF, XGB, GB, NN; 80/20 split + 5-fold CV → **XGB best (R²=0.971, MAE 0.158 mS/cm)**, NN 0.946.
- **You already admit the leakage:** "testing points from the same composition are in both train and test … evaluates interpolation, not entirely new compositions."
- **External test (3 unseen compositions):** XGB R²=0.89, RMSE 0.142 mS/cm.
- **Only ionic conductivity (IC) is ML-predicted — activation energy is collected but never modelled.** ← biggest untapped extension.

## TL;DR
You're already on the **right algorithm family** (gradient boosting on composition features). The highest-payoff improvements are **not a fancier model** — they're (1) **fixing how you validate** (grouped/leave-one-composition-out CV + a 1-NN baseline), which turns your admitted 0.97→0.89 gap from a weakness into a rigorously-reported strength, and (2) adding **transfer-learned CrabNet** as a modern composition-only deep comparator with a real extrapolation story. Do **not** chase structure-based GNNs — they don't apply to composition-only candidates and lose to Random Forest on the closest SSE benchmark.

---

## Recommendations, ranked by expected payoff for THIS dataset

### 1. [HIGHEST payoff, ~1 day] Replace random k-fold with grouped / leave-one-composition-out CV + a 1-NN baseline
Random k-fold CV dramatically overestimates generalization across chemical families via a **"lookup-table" effect** (chemically-similar compounds in both train and test). This *is* the mechanism behind your 0.97 (interpolation) vs 0.89 (grouped) gap — it's expected and documented, not a flaw in your model. Report grouped-CV as the **headline**, add **leave-one-composition-out / leave-one-family-out** folds, and include a **1-nearest-neighbour baseline** to prove the model beats memorisation.
- Meredig et al., *Mol. Syst. Des. Eng.* 2018 — RF on superconductor Tc: R=0.87 under k-fold but **R=0.30 under LOCO-CV**; introduces the lookup-table effect + the mandatory 1-NN baseline. **DOI 10.1039/C8ME00012C**
- Durdy et al., *Digital Discovery* 2022 — LOCO-CV: each fold = a chemical cluster, measures extrapolation to qualitatively new chemistries. **DOI 10.1039/D2DD00039C**
- Hargreaves/Laskowski et al., *npj Comput. Mater.* 2022 — on Li-SSE conductivity, an AutoSklearn ensemble **collapses to a mean predictor under LOCO-CV** (the same gap, on your exact problem). **DOI 10.1038/s41524-022-00951-z**
- **Open choice (flag in thesis):** define LOCO folds by your 8 human families *or* by unsupervised composition clusters (DBSCAN) — the reported gap depends on which; state your choice.

### 2. [Validates what you did, ~0.5 day] Keep gradient boosting as the workhorse; report LightGBM/CatBoost + a voting ensemble next to XGB
On small tabular materials data (hundreds of compositions), gradient boosting / tree ensembles match or beat deep learning with far less tuning. Your XGB choice is already correct; adding sibling boosters + a voting ensemble is cheap robustness and pre-empts "did you try other models?".
- Shwartz-Ziv & Armon, *Information Fusion* 2022 — "XGBoost outperforms these deep models across the datasets … requires much less tuning." (2-1 verify) **arXiv 2106.03253**
- Ma et al., *J. Power Sources* 2024 — garnet SSE conductivity: **GBR best** among GBR/RF/XGB, R²~0.9. **DOI 10.1016/j.jpowsour.2024.234439**
- Hua et al., 2023 — ~120 SSEs: RF/GBR/XGB/voting-ensemble beat ANN & linear; **ANN fails on small data**. (2-1 verify) **PMC10173313**

### 3. [Modern DL comparator + extrapolation story, ~2–4 days] Add transfer-learned CrabNet (OQMD-pretrained → fine-tune on your IC)
The one **composition-only deep** approach with demonstrated value on *this exact problem*. Pretrained on OQMD formation energies then fine-tuned, it was the single best model across every metric and **both** CV schemes (~10% over random-init), and held skill under LOCO-CV where the AutoML ensemble collapsed — i.e. it's your best bet for genuine extrapolation to new compositions.
- Hargreaves/Laskowski et al., *npj Comput. Mater.* 2022 (820 entries / 403 compositions — the direct Li-SSE-conductivity ML study). **DOI 10.1038/s41524-022-00951-z**
- CrabNet — Wang et al., *npj Comput. Mater.* 2021 (Transformer self-attention over the formula). **DOI 10.1038/s41524-021-00545-1**
- Roost — Goodall & Lee, *Nat. Commun.* 2020 (formula → dense weighted element graph; more sample-efficient than Magpie-RF/ElemNet, crossover at O(10²) points — relevant at your size). **DOI 10.1038/s41467-020-19964-7**
- ⚠️ Caveat: that SSE paper's headline product is a *classifier*, so its regression gains are vs a weak baseline — frame CrabNet as "promising modern comparator", not "guaranteed large win on ~400 compositions".

### 4. [Saves effort + pre-empts an examiner question, 0 days] Do NOT pursue structure-based GNNs — and say why, with a citation
CGCNN/MEGNet/ALIGNN/M3GNet need atomic coordinates, which your *hypothetical* candidates (LiBiO₂-style screening outputs) don't have. On the closest experimental SSE benchmark (OBELiX), **Random Forest beats every geometric GNN** (test MAE 1.59 vs 2.74–2.89 in log₁₀ σ) — they overfit. One sentence with this citation turns "why no GNN?" into a defended design choice.
- OBELiX benchmark, 2025 — Table S1: RF 1.59, MLP 1.72, M3GNet 2.74 … SchNet 2.89; "simpler models outperform geometric GNNs." **arXiv 2502.14234** / *Digital Discovery* **DOI 10.1039/D5DD00441A**
- ALIGNN — Choudhary & DeCost, *npj Comput. Mater.* 2021 (line-graph/bond-angle GNN; structure-based). **DOI 10.1038/s41524-021-00650-1**

### 5. [Source-criticism / wider-context, the 20-pt grade lever, ~0.5 day] Benchmark against the canonical SSE-ML datasets/papers
Positioning your results against these directly answers the adversary's "cite-free discussion / place in wider context" critique.
- **Sendek et al.**, *Energy Environ. Sci.* 2017 — multi-descriptor logistic-regression conductivity screen; 12,831 MP candidates → 21 fast-conductor hits (the field's founding screen). **DOI 10.1039/C6EE02697D**
- **Hargreaves 2022** (820/403, 15 families) and **OBELiX 2025** (~599 RT conductivities, ~321 with CIFs) — the public benchmarks to compare your dataset's size/coverage against.

---

## ⚠️ Do NOT cite these (verifiers REFUTED them — attractive but false as stated)
- CrabNet beating Automatminer across 28 datasets (0-3). Cite CrabNet only as "composition-only Transformer", not "generally most accurate".
- Phonon/lattice-dynamics descriptors being *essential* / outperforming static descriptors (0-3). The RF R²=0.710 / 93%-classifier metrics (arXiv 2404.13858) are real; the "essential" framing is not.
- ALIGNN's "up to 85% accuracy edge over prior GNNs" (1-2). Not established as universal SOTA.
- The OBELiX "dataset-size is why RF won" argument (1-2) — RF's win is real; that *explanation* is not verified.
- Blanket "trees are SOTA at ~10K samples" (1-2). Hold to the **small-N** advantage only.

## Open gaps (honest — research did not close these)
1. **Activation-energy ML is essentially unanswered.** No AIMD-NEB-augmented or physics-informed **Ea**-prediction paper survived verification. Since you collect Ea but don't model it, this is a clean, novel **future-work** extension — but it needs a dedicated search (Arrhenius-constrained / NEB-trained models); don't claim an established method exists.
2. Concrete payoff of TL-CrabNet vs your Magpie+XGB on *your* 342-composition / 8-family set under identical LOCO-CV is untested (Hargreaves suggests ~10% on a different split).
3. Whether adding partial structure (space group / lattice, where available) to composition features helps grouped-CV generalisation, or GNNs stay inferior at this size.

## Suggested order
Do **#1 + #4 now** (highest grade-impact, lowest effort — and both are mostly writing + a CV-loop change). **#2 + #5** next (cheap, defensive). **#3** if you want a modern-DL headline. **Ea model (gap #1)** = the standout future-work / next-paper hook.

_Sources (21 fetched) and full verified-claim JSON: `tasks/w3wcqre82.output`. Time-sensitivity: tree-vs-DL consensus holds 2022–2026; newer tabular DL (TabPFN, FT-Transformer) narrows the small-N gap without overturning it._

---
## ⚠️ RECONCILED AGAINST THE ACTUAL CODE (read this before actioning — added after inspecting `battery-electrolyte-predictor/`)
The research above was written against the **manuscript** (random 80/20 split, IC-only). The **sister-repo pipeline is already more rigorous** — do NOT redo what's done:

| Rec | Manuscript state | Actual repo state | Net action |
|---|---|---|---|
| #1 Grouped CV | random 80/20 (leaky) | **DONE — grouped by DOI** (`src/splitting.py`: GroupShuffleSplit + GroupKFold + anti-leakage asserts) | **DOI-grouping ≠ composition-grouping.** Add **leave-one-family-out** and/or **composition-grouped** (LOCO) CV — closes the *composition*-leakage attack DOI-grouping leaves open. |
| 1-NN baseline | — | KNN already present (`models.py KNeighborsRegressor`, `nearest_training_examples`) | Just **report** 1-NN alongside LOCO results (Meredig honesty baseline). Cheap. |
| #2 GBT workhorse | RF/XGB/GB/NN | **DONE** — RF, HistGBR, XGB, LGBM, MLP all in `models.py`/`train_xgboost.py` | No gap. (Optional: CatBoost + voting ensemble.) |
| #3 CrabNet/Roost | absent | **absent** (sklearn/XGBoost only) | Genuine new comparator — still worth adding. |
| Ea modeling | not ML-predicted | **DONE** (`TARGET_EA`/`COL_EA`, grouped split on Ea) | "Ea not modeled" applies to the **manuscript only**. Repo already does it. |
| #4 skip GNNs / #5 benchmarks | — | not used | Valid as written — these are **thesis/manuscript text + citations**, not code. |

**Concrete top action (small, high grade-lever, infra already exists):** in `src/splitting.py`, add a `leave_one_family_out` / composition-grouped generator (group key from `feature_engineering.classify_family` / `ALL_FAMILIES`, or `COL_COMPOSITION`) parallel to the existing `grouped_kfold`. Report grouped-by-DOI (current), grouped-by-composition, and leave-one-family-out side by side + the 1-NN baseline. `pytest tests/ -v` must stay green (repo rule). Random seed 42 is sacred.
