---
tags: [thesis, concept, eis, measurement]
created: 2026-05-08
type: atomic
---

# EIS Decomposition (Bulk vs Grain-Boundary)

How σ is actually measured for a sintered ceramic electrolyte, and why it justifies including processing features in the model.

## The measurement

Electrochemical impedance spectroscopy (EIS): apply small AC voltage, sweep frequency, measure complex impedance Z(ω). Plot −Im(Z) vs Re(Z) (Nyquist plot).

For a typical solid electrolyte:

- **High-frequency semicircle** → bulk-grain contribution. Resistance R_bulk → σ_bulk.
- **Mid-frequency semicircle** → grain-boundary contribution. R_GB → σ_GB.
- **Low-frequency tail** → electrode interface (blocking or ion-blocking).

Fit equivalent circuit (R_b ‖ C_b) — (R_GB ‖ C_GB) — Warburg → R_total = R_bulk + R_GB → σ_eff.

## Why decomposition matters

For the thesis, σ_eff (bulk + GB) is what the model targets — that's what battery cells experience.

But: R_GB depends heavily on **processing** (sintering temperature, time, atmosphere, density). Two papers can report the same composition with σ_eff differing by an order of magnitude purely because of processing.

→ This is why processing features are in the model even when composition dominates featurization. See [[Feature-Engineering]] § processing features.

## What V4 reports

The dataset records σ_eff as published. We do **not** re-decompose into bulk + GB ourselves — that would require digitizing Nyquist plots from each paper. Instead:

- σ_eff is the target.
- Processing features are the proxy for the GB contribution.
- > TODO: operator + advisor decide if a subset of papers with explicit bulk-only σ should be a separate analysis.

## Implication for OOD

A formula with novel processing (sintering recipe far from training) is OOD even if the composition is well-covered. The current [[OOD-Detection]] only flags composition-OOD — processing-OOD is a noted gap.

## Pointers

- `chapters/Theoretical_Background.tex` § 2.1 (EIS / electrochemistry primer).

## Related

- [[Solid-Electrolyte-Basics]] — bulk vs GB intuition.
- [[Feature-Engineering]] — processing features.
- [[Ionic-Conductivity]] — definition of σ being measured.
