---
tags: [thesis, logistics, repos]
created: 2026-05-08
type: atomic
---

# Sister-Repo Relationship

The thesis project lives across **two** Git repositories. Knowing which is canonical for what prevents drift.

## The two repos

| Repo | Purpose | Canonical for |
|---|---|---|
| `Master-oppgave/` | LaTeX thesis (Overleaf-synced) | thesis prose, figures-in-thesis, BibTeX, RUBRIC.md |
| `battery-electrolyte-predictor/` | ML pipeline + Streamlit | code, data, tests, working method drafts |

Both: `github.com/Nithu0/<repo-name>`.

## Working-document convention

Live working documents (method drafts, results drafts, supervisor-meeting log) stay in `battery-electrolyte-predictor/docs/`. Those are the **source**; thesis chapters are the **destination**. Manual sync, not automated.

## The data flow

```
battery-electrolyte-predictor/
  reports/figures/*.png        ┐
  models/metrics.json          ┼─→  Master-oppgave/
  docs/method_report_draft.md  ┘     figures/
                                     results/thesis_metrics.json
                                     chapters/*.tex (manual sync)
                                     thesis_macros.tex (auto from metrics.json)
```

LaTeX macros in `Master-oppgave/thesis_macros.tex` read from `results/thesis_metrics.json` so numbers in the thesis always match the latest pipeline run. Status: see `Master-oppgave/SYNC.md`.

## Citation pattern in thesis

```latex
Code that produced Figure X.Y is available at
github.com/Nithu0/battery-electrolyte-predictor at commit \texttt{<hash>}.
```

Hash from: `cd ../battery-electrolyte-predictor && git rev-parse HEAD`.

## Auto-push rules

- `Master-oppgave/` auto-pushes on Stop (per `~/.claude/settings.json`).
- `battery-electrolyte-predictor/` does **not** auto-push from this repo — `pytest tests/` must be green before commit.

## PhD co-authorship

The platform has a PhD-student co-author. Credited in `chapters/Acknowledgments.tex`. Scope to be clarified at next supervisor meeting (see [[Advisor-Instructions]] item 1).

## Related

- [[Pipeline-Reproducibility]] — what makes the metrics.json reproducible.
- [[Streamlit-Platform]] — UI layer of the sister-repo.
- [[Advisor-Instructions]] — author-contribution clarifications.
