---
tags: [moc, thesis, ml]
created: 2026-05-08
type: moc
---

# Thesis-MOC

Master's thesis at NTNU (Materials Technology / MTP): **ML-driven prediction of ionic conductivity (log10 σ) and activation energy (Eₐ) for solid-state Li-ion electrolytes**. Author: Nithusan Kukaraja. Sister-repo: `battery-electrolyte-predictor` (pipeline + Streamlit). LaTeX-thesis: `Master-oppgave/`.

This is the operator hub for the thesis cluster. Open Graph View — this subgraph should stand on its own. Only outbound bridge to other domains is via [[Workflows-MOC]] / [[Tools-MOC]] (shared tooling with Nexus).

## Dataset

- [[Dataset-Truth]] — what V4 IS: 120 papers, 1496 measurement rows, log10(σ) target.
- [[Cleaning-Decisions-Log]] — append-only decisions log (formula cleaner, polymer rules, outlier policy).
- [[Material-Families]] — Garnet / Sulfide / Argyrodite / NASICON tagging.

## Methods

- [[Modeling-Method]] — RF finalist, conformal prediction (q̂=2.11), kNN-OOD.
- [[Feature-Engineering]] — 141 features: Magpie + MP scalar + processing.
- [[Validation-Strategy]] — DOI-grouped 5-fold CV; 24 hold-out papers.
- [[Conformal-Prediction]] — distribution-free 90 % intervals.
- [[OOD-Detection]] — composition-space kNN p95 threshold.

## Engineering

- [[Sister-Repo-Relationship]] — Master-oppgave (LaTeX) ↔ battery-electrolyte-predictor (code).
- [[Streamlit-Platform]] — single-formula prediction UI; deferred features list.
- [[Pipeline-Reproducibility]] — `RANDOM_SEED=42`, `configs/v4.yaml`.

## Concepts

- [[Solid-Electrolyte-Basics]] — what makes a Li-ion conductor; bulk vs grain-boundary.
- [[Ionic-Conductivity]] — σ = nqμ; why log10(σ) is the target.
- [[Activation-Energy-Arrhenius]] — Eₐ from σ(T); Nernst-Einstein link.
- [[Magpie-Descriptors]] — composition-only featurization, what it captures.
- [[Materials-Project-Features]] — scalar struct-proxy via MP API.
- [[EIS-Decomposition]] — bulk + GB resistances, why processing matters.
- [[DOI-Grouping-Leakage]] — random vs paper-grouped split; leakage failure mode.

## Logistics

- [[Advisor-Instructions]] — pending questions per supervisor meeting (NTNU MTP).
- [[Submission-Timeline]] — deadlines, draft chapters, defense.
- [[Literature-Digest-Style]] — one-page-per-paper template, claims.csv link.
- [[Citation-Verification-Pass5]] — wrong-paper replacement workflow.

## Open Questions

- [[Open-Questions]] — 6 stubs operator should bring to advisor.

## Cross-bridges

- [[Workflows-MOC]] — shared workflow tooling (Obsidian, git, Claude Code).
- [[Tools-MOC]] — shared dev tools across Nexus + thesis.

---

**Update rule:** when a `docs/thesis/<name>.md` source changes, refresh the matching atomic note here. Do NOT mirror Nexus content into this domain.
