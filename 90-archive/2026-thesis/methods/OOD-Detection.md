---
tags: [thesis, methods, uncertainty, ood]
created: 2026-05-08
type: atomic
---

# OOD Detection

Composition-space out-of-distribution flag. Catches when a query formula sits in a region the training set did not cover — conformal-prediction width alone won't tell you that (CP assumes exchangeability with training; if you've left the manifold, the interval is meaningless even if narrow).

## Method

- kNN distance in **Magpie feature space** (~130 dims).
- Distance metric: Euclidean on standardized Magpie features.
- Threshold: **p95** of pairwise nearest-neighbour distances on the training set.
- New prediction: flag if its kNN distance > p95 threshold.

## Why composition-space (not structure-space)

The model only sees composition (Magpie + MP scalars). A formula chemically far from training is what should trigger the flag, not a structure novelty (which the model can't see anyway). See [[Magpie-Descriptors]].

## What it does NOT cover

- **Structural OOD** — same composition, novel polymorph. Outside scope; flagged in Future Work.
- **Processing OOD** — sintering recipe far from training. Processing features are too sparse (~5–10) for a separate OOD on them.
- **Temperature extrapolation** — handled separately via Arrhenius fit-quality check; see [[Activation-Energy-Arrhenius]].

## Calibration

p95 calibrated on the training distribution itself — the threshold is "this formula is further than 95 % of training pairs." Tunable per use-case (e.g. p99 for stricter scope).

## Use in the Streamlit app

- Display: kNN-distance histogram with p95 threshold marked.
- Per-prediction badge: "in-scope" / "OOD-flag".
- Co-displayed with conformal interval — both are needed (see [[Conformal-Prediction]]).

## Pointers

- `chapters/Theoretical_Background.tex` § OOD discussion.
- `chapters/Methodology.tex` § Uncertainty Quantification.

## Related

- [[Conformal-Prediction]] — complementary uncertainty layer.
- [[Magpie-Descriptors]] — feature space the OOD is measured in.
- [[Streamlit-Platform]] — where this is surfaced to the user.
