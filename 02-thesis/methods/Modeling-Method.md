---
tags: [thesis, methods, modeling]
created: 2026-05-08
type: atomic
---

# Modeling Method

The pipeline takes V4 dataset → fits a Random Forest → wraps it with conformal-prediction intervals + composition-space OOD flags. Tabular tree-based; no deep learning (n=120 papers too small for GNNs on structure).

## Headline choices

| Choice | V4 value | Why |
|---|---|---|
| Target | log10(σ [S/cm]) | log-scale damps superionic extremes |
| Split | DOI-grouped 5-fold CV + 24 hold-out papers | inter-lab noise dominates |
| Model finalist | **Random Forest** | best CV-RMSE among 4 compared |
| Compared | Ridge / KNN / RF / HistGBM | covers the tabular design space |
| Features | 141 (Magpie + MP-scalar + processing) | composition + scalar structure |
| Uncertainty | Conformal prediction (split CP, α=0.10) | distribution-free, see [[Conformal-Prediction]] |
| OOD | kNN p95 in Magpie space | composition-space, see [[OOD-Detection]] |

## Pipeline steps

1. **Load** — `data/processed/dataset_v4.csv` (120 papers, 1496 rows).
2. **Featurize** — Magpie via `matminer`, MP-scalar via Materials Project API (cached), processing-features extracted from paper tables.
3. **Split** — DOI-grouped (`GroupKFold`). 24 papers held out; remainder enters 5-fold CV. See [[Validation-Strategy]].
4. **Fit** — RF with `RANDOM_SEED=42` (reproducible).
5. **Conformal** — calibration set from CV-folds; q̂ = 2.11 at α=0.10.
6. **OOD** — kNN distances in Magpie space; p95 threshold calibrated on training distribution.
7. **Evaluate** — RMSE, R², per-family MAE, Arrhenius consistency.
8. **Persist** — `models/metrics.json` + `reports/figures/*.png`.
9. **Sync** — copy to `Master-oppgave/results/thesis_metrics.json` (planned).

## Why not deep learning / GNNs?

n = 148 papers (120 after cleaning) is too small for graph neural networks on structure. Tabular tree-based models dominate at this resolution. Discussed in `chapters/Theoretical_Background.tex` § 2.6 and reinforced in [[DOI-Grouping-Leakage]].

## Reproducibility

- `RANDOM_SEED=42` everywhere.
- All hyperparameters in `configs/v4.yaml` (verify path).
- Pipeline entry: `python run_pipeline.py --config configs/v4.yaml`.

> TODO: operator fill — precise hyperparameter table + per-family MAE table once V4 is frozen.

## Citation pattern in thesis

`Code that produced Figure X.Y is available at github.com/Nithu0/battery-electrolyte-predictor at commit <hash>.`

## Related

- [[Feature-Engineering]] — what the 141 features are.
- [[Validation-Strategy]] — DOI-grouping rationale.
- [[Conformal-Prediction]] / [[OOD-Detection]] — uncertainty + scope flags.
- [[Pipeline-Reproducibility]] — seeds, configs, environment.
