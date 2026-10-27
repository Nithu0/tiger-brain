---
tags: [thesis, concept, electrolyte]
created: 2026-05-08
type: atomic
---

# Solid Electrolyte Basics

A solid-state Li-ion electrolyte transports Li⁺ between anode and cathode without a liquid solvent. Goal: high ionic conductivity (σ ≥ 10⁻³ S/cm at room T), low electronic conductivity, electrochemical + chemical stability vs Li metal and the cathode.

## Why solid-state

- **Safety:** no flammable liquid carbonates.
- **Energy density:** enables Li-metal anodes → ~theoretical-max anode capacity.
- **Form factor:** thin-film + bipolar stacking possible.

## Cost of going solid

- σ usually 1–3 orders of magnitude lower than liquid carbonates (~10⁻² S/cm).
- Interfacial resistance with electrodes can dominate the cell impedance.
- Manufacturing (sintering, pressure) is harder than wet-cell.

## Bulk vs grain-boundary

Effective σ is the series combination of bulk-grain and grain-boundary contributions. EIS (electrochemical impedance spectroscopy) decomposes them — see [[EIS-Decomposition]].

Processing parameters (sintering T, time, atmosphere, density) shift the GB term substantially, which is why those features matter even for an ML model — see [[Feature-Engineering]].

## Families covered in this thesis

Garnets (LLZO), sulfides (LGPS, argyrodites), NASICON-type oxides (LATP), halides. Polymer / gel electrolytes are out of scope — see [[Material-Families]].

## Why ML is plausibly useful here

The composition → σ map is high-dimensional, non-linear, and discovery is currently driven by intuition + DFT screening. Tabular ML on a composition descriptor (Magpie) is cheap to query and provides a first-pass scope/uncertainty estimate via [[Conformal-Prediction]] + [[OOD-Detection]].

## Pointers

- `chapters/Theoretical_Background.tex` §§ 1–2 (Li-ion overview, electrolyte types).
- `chapters/Introduction.tex` § Background.

## Related

- [[Ionic-Conductivity]] — what σ actually measures.
- [[EIS-Decomposition]] — bulk + GB separation.
- [[Material-Families]] — which families are in V4.
