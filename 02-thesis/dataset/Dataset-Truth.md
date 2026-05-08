---
tags: [thesis, dataset, v4]
created: 2026-05-08
type: atomic
---

# Dataset Truth (V4)

Single source of truth for what the dataset contains right now. When thesis prose drifts from this — fix the thesis, not the dataset (unless a cleaning decision is logged in [[Cleaning-Decisions-Log]]).

## Active version

**V4** (Magpie + MP scalar + formula cleaner). Earlier V2/V3 (no formula cleaner) — abstract numbers in `chapters/Abstract.tex` stem from those and need re-syncing.

Pipeline-commit lookup: `cd ../battery-electrolyte-predictor && git rev-parse HEAD`.

## Numbers (V4, post-cleaning)

| Field | Value | Note |
|---|---:|---|
| Unique papers (DOIs) | **120** | pre-clean: 148 |
| Measurement rows (σ) | **1 496** | pre-clean: 1827 |
| Features | **141** | Magpie + MP-scalar + processing |
| Hold-out RMSE log10(σ) | **1.083** | RF, V4 |
| Hold-out R² | **0.144** | RF, V4 |
| Conformal q̂ (90 %) | **2.11** | exchangeability assumed |
| Test papers (hold-out) | **24** | DOI-grouped |
| Arrhenius series passed | **89 / 206** | median fit-R² = 0.927 |

## Target variable

`log10(σ [S/cm])`. Log-scale damps superionic extremes (e.g. Li10GeP2S12). Outliers > 3σ in log-space flagged but kept if context confirms they are real superionics.

Temperature-resolved measurements used for Arrhenius/Eₐ analysis (see [[Activation-Energy-Arrhenius]]); rows without T are dropped from Eₐ-fit but kept for σ-prediction at room temperature if 25 °C is explicitly stated.

## Cleaning at a glance

V4 dropped **18 %** of rows (1827 → 1496). Removal triggers:

1. Polymer blends (PEO + LiTFSI etc.) — out of scope (ceramic / sulfide / halide only).
2. Multi-phase mixtures with non-determinable dominant phase.
3. Doping notation that could not be parsed to a clean formula.

Full log: [[Cleaning-Decisions-Log]].

> TODO: operator fill — exact list of polymer families excluded + heuristics that flagged them.

## Material families

Garnet, Sulfide, Argyrodite, NASICON, halide. Tagged heuristically from formula + paper context. Family medians for Eₐ match literature (Garnet ~0.385 eV, Sulfide ~0.374 eV). See [[Material-Families]].

> TODO: operator fill — exact tagging heuristic.

## Source pointers

- Dataset CSV: `battery-electrolyte-predictor/data/processed/dataset_v4.csv` (verify filename).
- Metrics JSON: `Master-oppgave/results/thesis_metrics.json` (planned per `SYNC.md`).
- Method draft: `battery-electrolyte-predictor/docs/method_report_draft.md`.

## Related

- [[Validation-Strategy]] — why DOI-grouping matters for these numbers.
- [[Feature-Engineering]] — what the 141 features actually are.
- [[DOI-Grouping-Leakage]] — what random split would have shown instead.
