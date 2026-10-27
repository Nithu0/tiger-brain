---
tags: [thesis, logistics, literature]
created: 2026-05-08
type: atomic
---

# Literature Digest Style

How papers are digested into a form that's safe to cite from. **One page per paper**, structured fields, no LLM hallucinations.

## Why

Each `\cite{key}` in the thesis needs at least one row in `references/claims.csv` (DOI, citekey, page, claim text, verified date, verified-by). The digest is the operator's reading note that backs the claims-row.

## File layout

Proposed: `references/digests/<citekey>.md`. One file per paper.

> TODO: operator confirm path or propose alternative.

## Template

```markdown
# <citekey> — <short title>

**DOI:** 10.xxxx/yyyy
**Authors:** <first author et al.>
**Year:** YYYY
**Journal:** <short name>
**Verified against full text:** YYYY-MM-DD (initials)

## Method
<2–4 sentences: synthesis, characterization, modelling approach.>

## Dataset
<What was measured / published. Sample count, T-range, method.>

## Conductivity range / key numbers
<Specific numbers the thesis can cite. e.g.:
- σ(25 °C) = 1.2e-3 S/cm (LLZO, 96 % dense)
- Eₐ = 0.34 eV (Arrhenius 25–100 °C)
- Synthesis: solid-state, 1100 °C / 12 h, Ar
>

## Key insight (1–2 sentences)
<Main finding the thesis can reference. Should stand alone.>

## Citation in thesis
<Where this is used. List of claims.csv row IDs.>

## Notes / caveats
<What the paper does NOT show. Known errors. Replacement candidates if any.>
```

## Field conventions

- **Verified against full text** = reader has downloaded the PDF and checked the claim against the text. Not abstract-only.
- **Conductivity range** = published log10(σ) values at known T. No room-T extrapolation unless the paper itself extrapolates.
- **Key insight** = take the paper at its word — not our interpretation.

## DOI validation

- Crossref API (free) for metadata cross-check.
- Better-BibTeX (Zotero) auto-exports to `references.bib`.
- Do NOT use OpenWebUI / generic LLMs as a citation source — not transparent.

## Pass 5

Pass 5 (`references/verification_pass5.md`) replaced 4 wrong-paper citations using abstract-match + full-text check. 78 % of claims now PDF-verified. See [[Citation-Verification-Pass5]].

## When a citation moves / disappears

1. Mark row in `claims.csv` with `verified=false` + comment.
2. Log in [[Cleaning-Decisions-Log]] if it impacts a dataset row.
3. Log in [[Advisor-Instructions]] if supervisor must approve.
4. Update `references/digests/<citekey>.md` with caveats.

> TODO: operator write first batch of digest files for the most-cited papers (Stramare2003, Inaguma1993, Bachman2016, Famprikis2019, Asano2018, Omee2024) as the reference implementation of this style.

## Related

- [[Citation-Verification-Pass5]] — wrong-paper replacement workflow.
- [[Advisor-Instructions]] — pending citation review.
