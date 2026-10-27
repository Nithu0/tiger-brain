---
tags: [thesis, methods, features]
created: 2026-05-08
type: atomic
---

# Feature Engineering

Total: **141 features** in V4. Three families: Magpie composition, MP scalar, processing. Sits next to [[Modeling-Method]] (this is about the columns; that one is about the pipeline).

## 1. Magpie composition descriptors

- **Count:** ~130 (depends on matminer version).
- **Source:** `matminer.featurizers.composition.ElementProperty.from_preset("magpie")`.
- **What:** statistics (min/max/mean/avg-dev/range/mode) over element properties (atomic radius, electronegativity, valence, group, row, oxidation-state span, ...) weighted by stoichiometry.
- **Why:** composition-only baseline that has been shown competitive on materials data. Requires no structure → entire V4 dataset can be featurized without per-row Materials-Project lookups.
- **Limit:** does not capture structure (LLZO ≠ Li-rich salt with the same formula). Discussed in Discussion + Future Work.

See [[Magpie-Descriptors]] for the concept-level explanation.

## 2. Materials Project (MP) scalar features

- **Count:** > TODO: operator fill exact count from V4 config.
- **Source:** Materials Project REST API (cached locally).
- **What:** per-formula scalars: `formation_energy_per_atom`, `band_gap`, `density`, `volume_per_atom`, ...
- **Why:** structure proxy without going to a full graph. Free if MP has the formula — covers most known solid electrolytes.
- **NaN handling:** missing formula → mean-impute from training to avoid "not in MP" becoming a leak signal. > TODO: operator confirm per-column strategy.

See [[Materials-Project-Features]] for the concept-level note.

## 3. Processing features

- **Count:** ~5–10 scalars.
- **Source:** manual extraction from paper tables during dataset build.
- **What:** sintering temperature, sintering time, atmosphere (categorical → one-hot), porosity if reported, dopant concentration when applicable.
- **Why:** microstructure parameters affect grain-boundary resistance and thus effective σ — anchor in [[EIS-Decomposition]] and theory § 2.1.
- **NaN handling:** numeric → median per family; categorical → "unknown" bucket. > TODO: operator document per-column.

## NaN strategy summary

| Type | Strategy | Examples |
|---|---|---|
| Magpie | Never NaN (formula deterministic) | — |
| MP scalar | Mean-impute from training | `band_gap` |
| Processing numeric | Median per family | sintering temp |
| Processing categorical | "unknown" bucket | atmosphere |

## Family tag is NOT a feature

Family (Garnet / Sulfide / ...) is excluded — would leak DOI-group structure (papers cluster by family). Used only for per-family MAE reporting and plot coloring. See [[Material-Families]].

## What was excluded and why

- **Structure (CIF-based) features:** too few rows have matched structures. Future Work.
- **Text embeddings from papers:** leakage risk + not reproducible without expensive LLM pipeline.
- **Expanded processing tables:** marginal gain low at n=120 papers.

> TODO: operator fill — ablation table once V4 is frozen.

## Related

- [[Modeling-Method]] — pipeline that consumes these.
- [[Magpie-Descriptors]] / [[Materials-Project-Features]] — concept-level.
- [[EIS-Decomposition]] — why processing features matter.
