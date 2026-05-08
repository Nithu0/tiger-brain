---
tags: [thesis, open-question]
created: 2026-05-08
type: atomic
---

# Open Questions

Six gaps spotted while building this knowledge graph. Each one is something the operator should bring to the next supervisor session — the answer flows into [[Advisor-Instructions]].

## [[Question-1]] — How is V2/V3 history framed in the final thesis?

The abstract numbers in `chapters/Abstract.tex` are V2/V3 era; V4 is current. Options: (a) regenerate everything in V4; (b) mark V2/V3 as "project-thesis pilot" and keep them as historical context. Mirror in [[Advisor-Instructions]] item 6 (figures) and item 2 (results-tables).

## [[Question-2]] — VFT vs Arrhenius for sulfide glasses?

Some sulfide-glass entries may follow Vogel-Fulcher-Tammann rather than Arrhenius. Currently we use Arrhenius universally. Is this acceptable for the V4 plausibility filter or should VFT entries be a separate analysis? See [[Activation-Energy-Arrhenius]].

## [[Question-3]] — How to handle "not in MP" formulas for OOD?

Formulas missing from Materials Project get mean-imputed scalars. Should they additionally raise an OOD flag? Currently composition-OOD flag uses Magpie-only and is decoupled from MP-coverage. See [[OOD-Detection]] / [[Materials-Project-Features]].

## [[Question-4]] — PhD co-author scope in Acknowledgments?

Per [[Advisor-Instructions]] item 1, PhD-student scope (dataset extension, platform refactor, methodology feedback) needs explicit listing. Does the supervisor want a single "Author contributions" subsection or sentence-level credit per chapter? Affects [[Sister-Repo-Relationship]] citation pattern too.

## [[Question-5]] — Do we need explicit bulk-only σ subset analysis?

Most V4 papers report effective σ (bulk + GB). A subset reports EIS-decomposed bulk σ. Is a separate bulk-only model worth the n-loss, or is the GB-included story sufficient? See [[EIS-Decomposition]].

## [[Question-6]] — How does AI-disclosure chapter cover the Streamlit + Claude-assisted code?

Per [[Advisor-Instructions]] item 3, NTNU MTP rubric requires AI-use disclosure. The Streamlit app and parts of the pipeline used Claude-assistance. What level of granularity does the supervisor expect — per-file, per-feature, summary? Affects `chapters/ai_disclosure.tex`.

> TODO: operator add or replace these as the picture sharpens. Stub-style; rewrite when discussions advance.

## Related

- [[Advisor-Instructions]] — destination for resolved answers.
- [[Submission-Timeline]] — questions on the critical path.
- [[Thesis-MOC]] — back to hub.
