---
tags: [thesis, logistics, citations]
created: 2026-05-08
type: atomic
---

# Citation Verification — Pass 5

Pass 5 (April 2026) replaced 4 wrong-paper citations after a full-text re-check pushed PDF-verification rate to 78 %.

## What changed

| Removed | Reason | Replacement(s) |
|---|---|---|
| Buschmann2012LLZO | wrong-paper | Stramare2003, Inaguma1993 |
| Hikima2020 | wrong-paper | Bachman2016 |
| Kucinskis2022 | wrong-paper | Famprikis2019 |
| Zou2021 | wrong-paper | Asano2018, Omee2024 |

Source: `Master-oppgave/references/verification_pass5.md`.

## Placeholder citekeys still pending

- `Li2025LLZNOLLZTOPhase` — proposed replacement: Murugan2007.
- `Minkiewicz2023SEManufacturing` — proposed replacement: Schnell2018.

Awaiting supervisor sign-off — see [[Advisor-Instructions]] item 5.

## Pass-mechanism

Each pass walks every `\cite{key}` and:

1. Checks abstract match — does the claim in our prose match what the paper claims in its abstract?
2. If abstract OK: pull full text, verify the specific page / table / figure.
3. If mismatch: flag as wrong-paper, propose replacement, log in `verification_pass5.md`.
4. Update `claims.csv` row: `verified=true` with date + initials, OR `verified=false` with replacement candidate.

## When to do the next pass

Triggers:

- New citation added to `references.bib`.
- Supervisor flags a wrong-claim during review.
- Final pre-submission sweep ([[Submission-Timeline]] checklist).

## Related

- [[Literature-Digest-Style]] — the per-paper note backing each claim.
- [[Advisor-Instructions]] — review queue.
- [[Submission-Timeline]] — final pass before submit.
