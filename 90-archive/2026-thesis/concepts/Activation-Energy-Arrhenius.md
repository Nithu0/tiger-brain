---
tags: [thesis, concept, arrhenius, eactivation]
created: 2026-05-08
type: atomic
---

# Activation Energy (Eₐ) via Arrhenius

The second target the thesis touches (alongside σ). Extracted from temperature-dependent σ measurements via the Arrhenius relation.

## The relation

σ(T) = σ₀ · exp(−Eₐ / kT)

Linearized:

ln σ(T) = ln σ₀ − Eₐ / (kT)

→ plot ln σ vs 1/T → slope = −Eₐ / k → Eₐ in eV.

## V4 numbers

- Series candidate: **206** (papers reporting σ at ≥ 3 distinct T).
- Pass plausibility (R² ≥ threshold + Eₐ in 0.1–1.0 eV range): **89**.
- Median fit-R²: **0.927**.
- Family medians match literature: Garnet ~0.385 eV (n=12), Sulfide ~0.374 eV (n=7).

> TODO: operator fill remaining family medians from V4 results.

## Plausibility filter

Series rejected if:
- Fewer than 3 (T, σ) points.
- Fit-R² below a threshold (operator decides exact cutoff).
- Eₐ outside physical range for solid Li⁺ conductors (typically 0.1–1.0 eV).

See [[Cleaning-Decisions-Log]] — Arrhenius-validation entry.

## Nernst-Einstein link

For dilute, non-correlated Li⁺ motion:

σ = (n · q² / kT) · D

Diffusivity D itself is Arrhenius. So Eₐ from σ(T) reflects the migration barrier for Li⁺ hopping — directly comparable across families. The Garnet-Sulfide difference (~0.385 vs ~0.374 eV) falls out of this physics, not folklore.

## Bulk vs effective Eₐ

If the measurement reports total σ (bulk + GB), the Arrhenius slope is a weighted average. EIS-decomposed Eₐ_bulk and Eₐ_GB can differ by 0.1–0.2 eV. The dataset uses effective Eₐ unless paper explicitly reports bulk-only — see [[EIS-Decomposition]].

## Related

- [[Ionic-Conductivity]] — the σ side of the same equation.
- [[Material-Families]] — family-level Eₐ comparison.
- [[Validation-Strategy]] — Arrhenius consistency is a secondary metric.
