---
tags: [thesis, dataset, families]
created: 2026-05-08
type: atomic
---

# Material Families

The V4 dataset spans several solid-electrolyte families. Each behaves differently; the model is evaluated per family in addition to overall.

## Families covered

| Family | Examples | Typical Eₐ | Notes |
|---|---|---|---|
| **Garnet** | LLZO, Li7La3Zr2O12 | ~0.385 eV (n=12) | bulk Li-ion conductor; doping (Al, Ta, Ga) common |
| **Sulfide** | Li6PS5Cl, Li10GeP2S12 (LGPS) | ~0.374 eV (n=7) | softer; air-sensitive; superionic σ at room T |
| **Argyrodite** | Li6PS5X (X = Cl, Br, I) | (varies) | sulfide subfamily; high σ when halide-doped |
| **NASICON** | Li1.3Al0.3Ti1.7(PO4)3 (LATP) | (varies) | 3D ion network; compatibility with Li metal limited |
| **Halide** | Li3YCl6, Li3InCl6 | (varies) | newer family; oxidatively stable |

> TODO: operator fill — exact n per family in V4 + median Eₐ from results.

## Why families matter

- **Per-family MAE** reported in `chapters/ml_results.tex` to expose where the model under-performs.
- **Family-median Eₐ validation** — sanity-check against literature; falls out of [[Activation-Energy-Arrhenius]] / Nernst-Einstein, not folklore.
- **Plot coloring** in scatter-plots and the [[Streamlit-Platform]] UI.

## What family is NOT

Not a model feature. Including it would leak DOI-group information (papers cluster by family). Family stays meta-data for evaluation only.

## Out of scope

Polymer / gel electrolytes (PEO + LiTFSI etc.) — explicitly removed by the V4 formula cleaner. See [[Cleaning-Decisions-Log]] entry on polymer rules.

## Related

- [[Dataset-Truth]] — overall numbers.
- [[Activation-Energy-Arrhenius]] — where family medians come from.
- [[Feature-Engineering]] — why family is excluded from features.
