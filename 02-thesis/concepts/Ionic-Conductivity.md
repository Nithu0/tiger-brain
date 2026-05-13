---
tags: [thesis, concept, conductivity]
created: 2026-05-08
type: atomic
---

# Ionic Conductivity (σ)

The target variable in this thesis: **log10(σ [S/cm])**.

## Definition

σ = n · q · μ

where n = mobile-ion density, q = ion charge (= e for Li⁺), μ = ionic mobility. Units: S/cm (siemens per cm).

For solid Li-ion electrolytes at room temperature, σ ranges roughly 10⁻⁸ → 10⁻² S/cm (10 orders of magnitude). Liquid carbonate baselines: ~10⁻² S/cm.

## Why log10

- **10-orders-of-magnitude span** → linear-scale model would be dominated by the few superionic outliers.
- **Multiplicative noise** — relative error in σ is roughly constant in log-space, satisfying the homoscedasticity that least-squares regressors assume.
- **Arrhenius linearity** — log σ vs 1/T is linear by construction, see [[Activation-Energy-Arrhenius]].

Operator's outlier policy: superionic Li10GeP2S12 etc. are **kept** even when > 3σ in log-space — they are real, not measurement errors. See [[Cleaning-Decisions-Log]].

## Temperature dependence

σ(T) follows Arrhenius (or Vogel-Fulcher-Tammann for some glasses):

σ(T) = σ₀ · exp(−Eₐ / kT)

→ a single Arrhenius fit yields Eₐ + σ₀ from a series of (T, σ) measurements.

## Bulk vs effective σ

EIS lets you separate **bulk** σ (intra-grain Li⁺ transport) from **grain-boundary** σ. The thesis dataset reports effective σ — what a battery cell would see — which is the GB-limited value for densely-sintered ceramics. See [[EIS-Decomposition]].

## Stub: VFT extension

> TODO: operator decide whether VFT (Vogel-Fulcher-Tammann) is in scope for any sulfide-glass entries in V4. Currently we use only Arrhenius.

[[stub:vft-extension]]

## Related

- [[Activation-Energy-Arrhenius]] — Eₐ from σ(T).
- [[Solid-Electrolyte-Basics]] — physical context.
- [[EIS-Decomposition]] — measurement methodology.
