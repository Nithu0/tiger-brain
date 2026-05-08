---
tags: [thesis, logistics, timeline]
created: 2026-05-08
type: atomic
---

# Submission Timeline

[[stub]] — operator to fill specific dates after supervisor confirmation.

## Key milestones (template)

| Milestone | Target date | Status | Notes |
|---|---|---|---|
| V4 metrics frozen | > TODO | pending | required for `thesis_macros.tex` final values |
| All 4 wrong-paper citations replaced | > TODO | pending | see [[Citation-Verification-Pass5]] |
| AI-disclosure chapter approved | > TODO | pending | per [[Advisor-Instructions]] item 3 |
| Acknowledgments + PhD scope final | > TODO | pending | per [[Advisor-Instructions]] item 1 |
| Figure regeneration V2/V3 → V4 done | > TODO | pending | per [[Advisor-Instructions]] item 6 |
| Draft to supervisor for full read | > TODO | pending | — |
| Supervisor feedback incorporated | > TODO | pending | — |
| Final PDF compile (bibcheck + claims.csv) | > TODO | pending | — |
| **Submission** | > TODO | — | NTNU MTP master deadline |
| Defense / oral | > TODO | — | — |

## Hard rules before submission

- Every `\cite{key}` → at least one row in `references/claims.csv` with `verified=true`.
- All `> TODO` blocks in `Master-oppgave/docs/thesis/*.md` resolved or explicitly deferred.
- `pytest tests/` green in `battery-electrolyte-predictor/` at the commit cited in thesis.
- `RUBRIC.md` shows no red rows.

## Buffer policy

> TODO: operator decide. Suggested: 1 week buffer between "supervisor feedback in" and "submit" — assume 2 rounds of comments.

## Related

- [[Advisor-Instructions]] — many items here block submission.
- [[Citation-Verification-Pass5]] — citation-quality gate.
- [[Open-Questions]] — any open question that needs supervisor sign-off is on the critical path.
