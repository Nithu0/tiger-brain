---
tags: [thesis, methods, validation]
created: 2026-05-08
type: atomic
---

# Validation Strategy

How performance is measured. The split decision is the single biggest result-driver in this thesis — random row-splits would have given R² ≈ 0.6 (leak-inflated); paper-grouping gives R² = 0.144 (real). This is the headline finding.

## Split

- **Unit:** DOI (= paper). Never row-level random.
- **Hold-out:** 24 papers reserved entirely; never seen during CV or hyperparameter selection.
- **CV:** 5-fold DOI-grouped via sklearn `GroupKFold` on the DOI column.

## Why DOI-grouping

The same pellet/sample measured at multiple temperatures appears as N rows with identical composition + processing. A random split places some of those rows in train and some in test → the model sees the *same physical sample* in both → effectively memorization → optimistic R² ≈ 0.6.

Paper-grouping forces train and test to come from *different labs / different syntheses*. This exposes the real out-of-sample task: predicting σ for a composition the model has never seen, processed by a lab the model has never seen.

Concrete example: an LLZO pellet measured at 25 / 50 / 75 / 100 °C → 4 rows, 1 DOI, 1 fold. With `GroupKFold` all 4 rows always go together.

Concept-level write-up: [[DOI-Grouping-Leakage]].

## Metrics

- **Primary:** RMSE log10(σ), R² on hold-out.
- **Secondary:** per-family MAE (see [[Material-Families]]), Arrhenius consistency check on Eₐ predictions.
- **Conformal coverage:** empirical coverage at α=0.10 should ≈ 90 %; deviation reveals exchangeability assumption breakage.

## Calibration set for conformal

Pulled from the CV folds (not the hold-out). The hold-out is reserved purely for final reporting. q̂ = 2.11. See [[Conformal-Prediction]].

## OOD threshold calibration

p95 of training-distribution kNN distance in Magpie space → predictions outside this distance are flagged but still emitted. See [[OOD-Detection]].

## Leakage controls beyond DOI-grouping

- Family is **not** a feature (would leak DOI-group structure).
- MP NaN → mean-impute, not its own indicator (would leak "not-in-MP" signal).
- No text embeddings from paper bodies.

## Pointers

- `chapters/Methodology.tex` § Train/Test Split and Cross-Validation.
- `chapters/Theoretical_Background.tex` §§ 2.4–2.5.

## Related

- [[Modeling-Method]] — what this validation evaluates.
- [[Dataset-Truth]] — the 24 hold-out papers come from this dataset.
- [[DOI-Grouping-Leakage]] — concept-level deep dive.
