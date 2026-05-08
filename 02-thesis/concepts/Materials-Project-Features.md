---
tags: [thesis, concept, descriptors, mp]
created: 2026-05-08
type: atomic
---

# Materials Project (MP) Scalar Features

Per-formula scalars pulled from the Materials Project REST API. Used as a cheap structure-proxy without going to a full crystal-graph featurization.

## What gets pulled

For each formula, MP returns scalars like:

- `formation_energy_per_atom` — thermodynamic stability proxy.
- `band_gap` — electronic-conductivity proxy (we want this **wide** for an electrolyte → no electron leakage).
- `density` (g/cm³).
- `volume_per_atom` — packing density.

> TODO: operator fill exact list and count from V4 config.

## Why include them

Pure Magpie (composition-only) cannot distinguish polymorphs. MP scalars are aggregate properties of the lowest-energy DFT-relaxed structure for that formula → at least *some* structure information makes it into the feature vector, very cheaply.

For a published electrolyte that exists in MP, this is essentially free DFT-derived information.

## Reliability caveats

- **DFT-derived ≠ experimental.** Band gap from PBE underestimates the true gap; formation energy is at 0 K, no entropy.
- **One polymorph per formula.** MP returns the lowest-energy convex-hull entry. If the experimental sample is a different polymorph, the scalar is misleading.
- **Coverage gap.** Not every formula in V4 has an MP entry. Missing → mean-impute (see NaN strategy in [[Feature-Engineering]]).

[[stub]] — operator may want to flag this in Discussion as a feature-space limitation alongside the composition-only ceiling.

## NaN handling

Missing → mean-impute from training distribution. Avoids letting "formula-not-in-MP" become a leak signal that correlates with paper recency or material novelty.

## Related

- [[Magpie-Descriptors]] — the larger feature family.
- [[Feature-Engineering]] — full inventory + NaN strategy.
- [[Solid-Electrolyte-Basics]] — band gap relevance to electrolyte function.
