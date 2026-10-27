---
tags: [moc, archive, thesis, ml, retired]
type: closing-moc
status: RETIRED
archived: 2026-07-27
archived_by: data-1
outcome: delivered
---

# Avslutnings-MOC — Masteroppgave (NTNU, batteri-elektrolytt-ML)

> **RETIRED 2026-07-27.** Masteroppgaven er **levert juni 2026**. Denne mappa (operatørens tenke-noter, opprinnelig `02-thesis/`, markert *Claude read-only*) er arkivert av data-1 under FIRM v2-migreringen. **Innhold er ikke redigert** — kun flyttet. Archive-don't-delete. Symlinkene `_chapters`/`_docs` er absolutte og peker fortsatt til det levende `Master-oppgave`-repoet.

## Hva oppgaven var

**ML-drevet prediksjon av ionisk konduktivitet (log₁₀ σ) og aktiveringsenergi (Eₐ) for faststoff Li-ion-elektrolytter.** NTNU, Materialteknologi (MTP). Forfatter: Nithusan Kukaraja.

## Nøkkelresultater (fra notatene)

- **Datasett V4**: 120 papers, 1496 måle-rader, log₁₀(σ) som target.
- **Modell**: Random Forest-finalist; konform prediksjon (q̂ = 2.11) for distribusjonsfrie 90 %-intervaller; kNN-OOD i komposisjonsrom (p95-terskel).
- **Features**: 141 (Magpie + Materials-Project-skalarer + prosessering).
- **Validering**: DOI-gruppert 5-fold CV; 24 hold-out papers (mot lekkasje).

## Hvor ligger alt (to-repo-split — pekere, ikke kopiert hit)

| Innhold | Kanonisk plassering |
|---|---|
| LaTeX-oppgave (prosa, figurer, BibTeX) | `~/code/Master-oppgave/` (auto-push til Overleaf på Stop) |
| ML-kode / pipeline / data / Streamlit | `~/code/Master-oppgave/battery-electrolyte-predictor/` (testede commits, `pytest tests/`) |
| Operatørens tenke-noter (denne mappa) | `90-archive/2026-thesis/` (var `02-thesis/`) |
| Kapittel-symlinker | `_chapters` → `Master-oppgave/chapters`, `_docs` → `Master-oppgave/docs` |
| Prosjektstatus (nå RETIRED) | `~/code/Master-oppgave/project_state.md` + `GOALS.md` |

## Innhold i arkivet (uendret)

- [[Thesis-MOC]] — original operatør-hub for hele thesis-klyngen.
- Dataset: [[Dataset-Truth]], [[Cleaning-Decisions-Log]], [[Material-Families]].
- Metoder: [[Modeling-Method]], [[Feature-Engineering]], [[Validation-Strategy]], [[Conformal-Prediction]], [[OOD-Detection]], [[Pipeline-Reproducibility]], [[Streamlit-Platform]].
- Konsepter: [[Solid-Electrolyte-Basics]], [[Ionic-Conductivity]], [[Activation-Energy-Arrhenius]], [[Magpie-Descriptors]], [[Materials-Project-Features]], [[EIS-Decomposition]], [[DOI-Grouping-Leakage]].
- Logistikk + open-questions: [[Sister-Repo-Relationship]], [[Submission-Timeline]], [[Citation-Verification-Pass5]], [[Open-Questions]].

> **NB (data-1):** `02-thesis/` var markert *Claude read-only*. Arkiveringen flytter men redigerer ikke. Se `migration/UNRESOLVED.md` for read-only-vs-arkiver-avveiingen — operatøren kan reversere med én flytt.
