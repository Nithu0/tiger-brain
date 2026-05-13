---
type: audit
batch: 2026-05-13-round3
source: _library/trading/concepts/karri_evidence_bar.md
status: distilled
---

# Audit — karri_evidence_bar.md distilled

## Inputs read
- `_library/trading/concepts/karri_mental_model.md` (sibling curriculum)
- `_library/trading/sources/karri_quotes_corpus.md` (raw quote harvest)
- `00-claude-inbox/nexus/2026-05-13/round2/16_karri_proposal_corpus.md` (24-proposal interpretation)

## Output
`_library/trading/concepts/karri_evidence_bar.md` — 5 sections (counts / doesn't count / structural override / checklist / examples) + "when in doubt" close, ~520 words inside the 400-600 target.

## Cross-checks
- "≥6mo OANDA H1" + "≥30 closed trades" both anchored to operator-prinsipp #6 + Karri's approval pattern (mental_model §"what Karri demands").
- Structural-override examples (R:R math, MFE=$0, acute incident + convergence at N=3-4) sourced from quote-corpus entry 11-may-D (regime_direction_gate Q5).
- Sweet-spot example: PR #24 + `pullback-continuation/config.ts` ADX 25→20 sweet-spot comment (quote-corpus 12-may-Q).
- Pushback example: vol_expansion_throttle_review "instrument first 14 days" (quote-corpus 11-may-H).
- Checklist is 5 items as the spec required.
- Closing line matches the spec: "FILE the proposal with 'Evidence pending' status rather than skipping it — Karri prefers a written record."

## Cross-links to keep coherent
- `karri_mental_model.md` §"What Karri demands of every proposal" overlaps but stays curriculum-level; the evidence-bar doc goes deeper on the structural override and the worked examples.
- No edits made to sibling files; this doc stands alone as the proposal-bar reference.
