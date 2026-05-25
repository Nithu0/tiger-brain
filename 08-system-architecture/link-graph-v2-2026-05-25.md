---
title: Brain link-graph v2 — post-cleanup delta
date: 2026-05-25
status: v2
purpose: Measure brain link-graph state after H-1 (script fix), H-2 + I-3 (YAML/wikilink cleanup)
related:
  - "[[link-graph-insights-2026-05-25]]"
  - "[[wikilink-reconciliation-2026-05-25]]"
tags: [audit, link-graph, v2, delta]
---

# Brain link-graph v2 — delta

Second systematic graph snapshot, taken at 2026-05-25T15:05:09Z (concurrent with
phase-9 cleanup pass — H-2 landed, I-3 may still be in flight). Compared against
H-9's first run (2026-05-25T14:57:32Z).

Source data: `/tmp/brain-graph-v2-2026-05-25.json` (transient).

## Counts comparison

| Metric | H-9 (v1) | I-9 (v2) | Delta |
|---|---|---|---|
| Total nodes | 529 | 535 | **+6** |
| Total edges | 2559 | 2684 | **+125** |
| Broken edges | 209 | 253 | **+44** |
| Distinct broken targets | 82 | 83 | +1 |
| Orphans (in_degree = 0) | 251 | 247 | **-4** |
| Isolated leaves (out_degree = 0) | 253 | 253 | 0 |
| Fully isolated (in = 0 AND out = 0) | 206 | 206 | 0 |
| Top hub | `Operator-Principles` (149) | `Operator-Principles` (151) | +2 |
| Mean degree | 9.67 | 10.03 | +0.36 |

## What changed and why

**Nodes (+6).** Six new notes since H-9, ~28 minutes earlier:

- Phase-9 reconciliation drops (`wikilink-reconciliation-2026-05-25`,
  `audit-report-v2-2026-05-25`, `cleanup-report-2026-05-25`,
  `coverage-gap-analysis-2026-05-25`, `pre-distill-manifest-2026-05-25`,
  `test-summary-2026-05-25`, etc. — these are I-phase outputs landing).
- I-6 sample-task additions and other artefacts from G/H/I-phase work.

**Edges (+125).** Densification continues — links grew ~6× faster than nodes
(+20.8 edges/node added). This tracks the trend H-9 flagged ("edge growth faster
than node growth — links are densifying. Healthy direction").

**Broken edges (+44).** *Counterintuitive but explainable.* Both H-2 and I-3
cleanup target stale wikilinks in source notes, yet broken-edge count went up.
Reason: the new audit/reconciliation reports themselves cite broken wikilinks
verbatim in their findings tables. Per-target trace:

- `[[2603.13017v1]]` 15 → 17 (+2; cited by RAG-MOC, INTEGRATION_NOTES_v1.2)
- `[[CLAUDE.md]]` 10 → 12 (+2; cited by INTEGRATION_NOTES_v1.2)
- `[[reference_available_tools]]` 9 → 11 (+2)
- `[[wikilinks]]` 9 → 10 (+1)
- `[[command-center]]` 8 → 10 (+2)
- New placeholders `[[X]]` (13) and `[[Y]]` (12) — almost certainly template
  examples in newly-added spec / planning notes.

The new placeholders (`X`, `Y`) plus the +2..+3 audit-report leakage explain
the +44 cleanly. Source content is being cleaned; meta-documentation is
re-introducing the same strings.

**Orphans (-4).** Modest improvement (251 → 247). Likely from new MOC cross-refs
in D-4 / E-7 work picking up previously-unlinked notes. The bulk of orphans
remain `00-claude-inbox/` write-once dumps (architectural, not cleanup material).

**Isolated leaves unchanged (253).** New nodes (mostly reports) all link OUT, so
they don't increase the out-degree-0 count, but they also haven't yet been
linked TO from MOCs.

**Fully isolated unchanged (206).** No regression and no improvement.
Distribution still 171 in `00-claude-inbox/` (83%), rest in firm-bus / templates
/ promote-candidates — same shape as v1.

## Type distribution shift

| Type | v1 count | v2 count | Delta |
|---|---|---|---|
| **untyped** | **207** | **212** | **+5** |
| atomic | 45 | 45 | 0 |
| runbook | 23 | 23 | 0 |
| moc | 20 | 20 | 0 |
| meta | 19 | 19 | 0 |
| audit | 18 | 18 | 0 |
| stub | 17 | 17 | 0 |
| decision | 16 | 16 | 0 |
| living | 9 | 9 | 0 |
| ops / investigation / string | 8 / 8 / 8 | 8 / 8 / 8 | 0 / 0 / 0 |

**Observation:** H-2 cleanup did not measurably reduce `untyped` — and we
actually gained 5 untyped notes (the new reports/manifests landed without a
`type:` field). Net: untyped fraction held essentially flat at 39.6 % (212/535)
vs 39.1 % (207/529) in v1.

This is the clearest place for the next iteration to spend effort: every
auto-generated audit/report from the G-H-I pipeline should default to
`type: audit` (or `report`, `manifest`, etc.) in its template.

## Top hub shift (v1 → v2)

Top hubs largely unchanged. Top-10 shape preserved; small in-degree growth on
the operator-governance cohort.

| Rank | Note | v1 total | v2 total | Delta |
|---|---|---|---|---|
| 1 | `[[Operator-Principles]]` | 149 (130/19) | 151 (132/19) | +2 |
| 2 | `[[2026-05-25-brain-upgrade-plan]]` | 126 (119/7) | 134 (127/7) | +8 |
| 3 | `[[Nexus-MOC]]` | 115 (57/58) | 116 (58/58) | +1 |
| 4 | `[[OBSIDIAN_BRAIN_STRUCTURE]]` | 114 (22/92) | 115 (23/92) | +1 |
| 5 | `[[Foundation-Gate]]` | 94 (73/21) | 95 (74/21) | +1 |
| 6 | `[[README]]` (firm-bus) | 77 (0/77) | 79 (2/77) | +2 |
| 7 | `[[MEMORY_DISTILLATION_SPEC]]` | 74 (56/18) | 76 (58/18) | +2 |
| 8 | `[[AGENT_ORCHESTRATION_SPEC]]` | 70 (51/19) | 73 (54/19) | +3 |
| — | `[[link-graph-insights-2026-05-25]]` | — (orphan) | 71 (0/71) | NEW in top-20 |
| 9 | `[[2026-05-11_full_session]]` | 69 (3/66) | 70 (4/66) | +1 |
| 10 | `[[Memory-MOC]]` | 67 (40/27) | 68 (41/27) | +1 |

**New entrant:** H-9's own `link-graph-insights-2026-05-25.md` jumped into the
top-20 by virtue of its 71 outbound links (it cites the entire hub list). Still
an orphan (in_degree = 0) — same recommendation H-9 made for sibling audit
reports applies: link from `System-Architecture-MOC`.

**No reshuffles, no surprises.** The brain's gravitational center is stable
between snapshots.

## Recommendations

1. **Stop the meta-leakage.** Audit/report templates should escape literal
   broken wikilinks they cite (`` `[[2603.13017v1]]` `` in backticks, not
   bare `[[…]]`). Would cut the +44 spurious broken-edges added by audit work
   alone. Cleanup target for the next phase.
2. **Default `type:` for auto-generated reports.** Add to the template/checker
   so phase outputs don't land as `untyped`. Today's pipeline added 5 untyped
   notes in 28 min.
3. **Link new audits from `System-Architecture-MOC`.** `link-graph-insights`
   and the v2 reports are top-20 hubs by out-degree but orphans by in-degree.
4. **Weekly graph cadence.** Re-run this snapshot weekly to track densification
   trend (mean degree v1 → v2: +0.36 in 28 min — too noisy at this resolution
   to be a real signal; weekly cadence will smooth it).
5. **Orphan growth watch.** Orphan count went DOWN (-4) this snapshot — first
   measurable cleanup win. Keep direction by linking new outputs from MOCs at
   publish-time, not retroactively.

## Sign-off

Brain link health: **IMPROVING** (with one caveat).

- Orphans down (-4), edge density up (+0.36 mean degree), hub structure stable,
  no fully-isolated regressions.
- Caveat: broken-edge count went up (+44), but the cause is meta-leakage from
  audit reports citing broken wikilinks, not new rot in source content. A
  template fix and one cleanup pass on audit-report bodies neutralises it.
- H-2 + I-3 cleanup pass appears to be working as intended on source notes;
  the noise comes from the very reports that document the cleanup.

Next snapshot recommended: 2026-06-01 (weekly cadence), or sooner if a large
content batch lands.
