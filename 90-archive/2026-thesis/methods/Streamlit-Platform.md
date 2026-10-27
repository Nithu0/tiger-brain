---
tags: [thesis, methods, ui, platform]
created: 2026-05-08
type: atomic
---

# Streamlit Platform

Single-formula prediction UI in `battery-electrolyte-predictor/app/streamlit_app.py`. Part of the operator's contribution (rubric 2.4) and a collaboration artefact with the PhD co-author.

## What it does (V4)

- Takes a chemical formula (+ optional processing input).
- Featurizes via Magpie + MP cache.
- Predicts log10(σ) with the RF model.
- Returns a conformal interval (90 % nominal) + OOD flag (kNN composition distance).
- Shows family tag if known.

## Who uses it

| User | Pattern | Frequency |
|---|---|---|
| Author (self) | sanity-check, demo | daily |
| Supervisor | demo in meetings | rare |
| PhD co-author | dataset exploration | > TODO |
| Examiner (submission) | live demo if relevant | once |

Not for external / industrial / open-source users until possible publication.

## What it explicitly does NOT do (deferred)

- **No structure input** (CIF / POSCAR). Composition-only — matches the model feature space.
- **No batch prediction** via file upload. One formula at a time.
- **No auth / multi-user.** Local Streamlit, not deployed.
- **No model retraining from UI.** Pipeline runs in terminal.
- **No dataset editor.** Dataset changes go via [[Cleaning-Decisions-Log]] + sister-repo PR.

## Visuals

- Scatter: predicted vs observed log10(σ) on hold-out.
- Per-family MAE bar chart.
- OOD-distance histogram with p95 threshold marked. See [[OOD-Detection]].
- Conformal interval as band around prediction. See [[Conformal-Prediction]].

> TODO: operator screenshot / wireframe link once V4 is frozen.

## Citation in thesis

```latex
The accompanying interactive prediction platform is available at
github.com/Nithu0/battery-electrolyte-predictor, jointly developed with
<PhD-name> (see Acknowledgments).
```

> TODO: operator + supervisor confirm exact wording (per [[Advisor-Instructions]] item 1).

## Open-source status

- License: MIT (already on GitHub).
- Pre-trained RF in `models/`; no retraining required to demo.
- `RANDOM_SEED=42`, `requirements.txt`, dataset + checkpoints versioned. See [[Pipeline-Reproducibility]].

## Post-thesis (deferred)

- Possible journal publication (platform + dataset).
- Extension to structure input via Materials Project graph.
- Active-learning loop: UI suggests next experiment from OOD + low-confidence regions.

All deferred — not part of thesis scope.

## Related

- [[Sister-Repo-Relationship]] — where the code lives.
- [[Conformal-Prediction]] / [[OOD-Detection]] — what the UI surfaces.
- [[Pipeline-Reproducibility]] — what makes the UI honest.
