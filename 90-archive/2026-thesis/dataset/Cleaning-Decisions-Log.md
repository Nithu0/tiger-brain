---
tags: [thesis, dataset, cleaning]
created: 2026-05-08
type: atomic
---

# Cleaning Decisions Log

Append-only log of every decision that changes the dataset. Operator's source: `Master-oppgave/docs/thesis/data-cleaning-decisions.md`. This Obsidian note is the index, not the canonical log.

## Format (per entry)

```
## YYYY-MM-DD — short title
Decision / Reason / Effect (rows or metric delta) / Commit / Author
```

## Logged decisions (V4 era)

1. **V4 formula cleaner introduced** — drops polymer blends, multi-phase, unparsable doping. Effect: 1827 → 1496 rows (-18 %), 148 → 120 papers. R² shifted from -0.22 → +0.14.
2. **DOI-grouped CV adopted** — switched from random row-split to `GroupKFold` on DOI. No rows changed; R² fell to realistic 0.144 from leakage-inflated ~0.6. See [[DOI-Grouping-Leakage]].
3. **Conductivity-outlier policy** — values > 3σ in log-space flagged; kept if paper context confirms superionic. 0 rows removed.
4. **Arrhenius temperature-column required** — rows without T excluded from Eₐ-fit. 206 series candidate; 89 pass plausibility check.

> TODO: operator fill commit hashes from `battery-electrolyte-predictor` git history.
> TODO: operator backfill pre-V4 decisions still missing from this log.

## When a decision is overridden

Do not delete the old entry. Add a new one with explicit "Overrides YYYY-MM-DD entry above" line — see operator's own discipline note in source doc.

## Related

- [[Dataset-Truth]] — current numbers after these cleanings.
- [[Validation-Strategy]] — DOI-grouping decision deepened here.
- [[Advisor-Instructions]] — supervisor sign-off needed for some cleanings.
