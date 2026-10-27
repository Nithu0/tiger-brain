---
tags: [thesis, methods, uncertainty, conformal]
created: 2026-05-08
type: atomic
---

# Conformal Prediction

Distribution-free uncertainty quantification on top of the RF. For α = 0.10, the conformal interval has empirical coverage close to 90 % under exchangeability.

## How it works (split CP)

1. Train RF on training fold.
2. Compute non-conformity scores (residuals |y - ŷ|) on the calibration fold.
3. q̂ = ⌈(n+1)(1-α)⌉-th smallest score → for α=0.10, V4 q̂ = **2.11**.
4. New prediction: `ŷ ± q̂` (in log10(σ)-space).

## Why this method here

- **Distribution-free:** no Gaussian-noise assumption. RF residuals on heterogeneous literature data are heavy-tailed → Gaussian intervals would mis-cover.
- **Model-agnostic:** wraps any point-predictor.
- **Coverage guarantee under exchangeability**: empirical coverage in V4 should track 90 %.

## Exchangeability caveat

DOI-grouping breaks strict exchangeability — papers are not i.i.d. samples. The thesis acknowledges this and reports empirical coverage on the hold-out as the actual evidence. See `chapters/Theoretical_Background.tex` § 2.7 + [[Validation-Strategy]].

## Coverage diagnostics

- Empirical coverage on 24 hold-out papers vs nominal 90 %.
- Conditional coverage by family (does Garnet under-cover while Sulfide over-covers?).
- Width vs ground truth — too-wide intervals are useless even if they cover.

> TODO: operator fill — coverage table from V4 hold-out once metrics.json finalized.

## Related

- [[Modeling-Method]] — pipeline step 5.
- [[Validation-Strategy]] — calibration set comes from CV folds, not hold-out.
- [[OOD-Detection]] — complementary scope-flag (CP is *how confident*, OOD is *am I in scope at all*).
