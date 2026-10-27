---
tags: [thesis, concept, leakage, validation]
created: 2026-05-08
type: atomic
---

# DOI-Grouping vs Leakage

The single most important methodological decision in this thesis. Switching from random-row split to DOI-grouped split moved hold-out R² from a leak-inflated **~0.6** to a realistic **0.144**.

## The leakage failure mode

The dataset has many-to-one rows-per-paper:

> Same pellet measured at 25 / 50 / 75 / 100 °C → 4 rows, 1 DOI, identical composition + processing, only T differs.

Random row-split puts some of those 4 rows in train and some in test. The model sees the *same physical sample* in both — effectively memorizing it — and reports R² ≈ 0.6.

This is **not** a model in the wild. A user querying a new formula has no train-set neighbour at all.

## The fix

`sklearn.model_selection.GroupKFold` on the DOI column. Every paper's rows go to the same fold. 5-fold over the non-hold-out, 24 papers reserved as final hold-out.

→ Realistic R² = 0.144 emerges. Low but honest.

## What it tells us

The R² ceiling on this dataset is **inter-laboratory noise + composition-only ceiling**:

- Different labs, different starting reagents, different sintering recipes → measured σ for nominally-identical formulas can vary by an order of magnitude.
- Composition-only features (Magpie + MP scalars) cannot distinguish polymorphs or microstructure.

→ The thesis frames R² = 0.144 as a *symptom of literature heterogeneity*, not a model failure. That's the headline finding 1 (see `chapters/discussion.tex`).

## Related leakage controls

- **Family** is excluded from features (would partially recover the DOI-group signal).
- **MP NaN** → mean-impute, not its own indicator (would leak "novel material" signal).
- **No paper text embeddings** — would massively leak.

See [[Validation-Strategy]] for the operational rules.

## What random-row would still tell you (negatively)

If R² stays ≈ 0.144 even with random-row, the leak isn't there → look elsewhere. Operator did this sanity check before publishing the headline.

## Related

- [[Validation-Strategy]] — operational implementation.
- [[Dataset-Truth]] — the V4 numbers reflecting paper-grouping.
- [[Modeling-Method]] — why this matters even if you change the model.
