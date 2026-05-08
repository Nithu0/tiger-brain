---
tags: [thesis, concept, descriptors, magpie]
created: 2026-05-08
type: atomic
---

# Magpie Descriptors

The composition-only featurization that anchors the V4 model. ~130 of the 141 features come from Magpie.

## What it computes

For a chemical formula (e.g. `Li7La3Zr2O12`):

1. Look up element-level properties for every element in the formula: atomic radius, electronegativity, valence, group, row, oxidation-state span, atomic mass, etc.
2. Weight by stoichiometry.
3. Compute statistics across the formula: min, max, mean, average deviation, range, mode.

→ a fixed-length feature vector (length depends on matminer version, ~130 in V4).

## Why composition-only

- **No structure required.** All 1496 V4 rows can be featurized with no Materials-Project lookup.
- **Cheap at inference.** A new formula featurizes in milliseconds.
- **Provably useful.** Magpie has been a competitive baseline on materials property prediction since Ward et al. 2016.

## What it does NOT capture

- **Structure.** LLZO and a hypothetical Li-rich salt with the same formula get identical Magpie features. The thesis acknowledges this as a known ceiling and lists structure-aware features (CIF-based, GNN) in Future Work.
- **Processing.** Sintering / atmosphere / porosity. Those come from separate processing features — see [[Feature-Engineering]].
- **Microstructure.** Grain size, GB density. Out of scope at composition-only level.

## Source

`matminer.featurizers.composition.ElementProperty.from_preset("magpie")`. matminer version pinned in `battery-electrolyte-predictor/requirements.txt`.

## Standardization

Magpie features are standardized (mean 0, std 1) before entering RF. Standardization stats fit on training fold only — never on hold-out.

> TODO: operator confirm — RF doesn't strictly need standardization, but it matters for the kNN-OOD that lives on the same feature space. See [[OOD-Detection]].

## Related

- [[Feature-Engineering]] — full feature inventory.
- [[Materials-Project-Features]] — the structure-proxy supplement.
- [[OOD-Detection]] — Magpie space is also the OOD-distance space.
