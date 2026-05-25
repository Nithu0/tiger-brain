---
title: Brain link-graph insights — 2026-05-25
date: 2026-05-25
status: v1.0 (first analysis run)
purpose: Insights from G-7's brain-link-graph.sh dump
source_data: /tmp/brain-graph-2026-05-25.json (transient)
related:
  - "[[wikilink-audit-v2-2026-05-25]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [insights, graph-analysis, brain]
---

# Brain link-graph insights — 2026-05-25

First systematic graph analysis of the brain. Snapshot taken with
`brain-link-graph.sh` at 2026-05-25T14:57:32Z. G-7's earlier test-run reported
525 nodes / 2482 edges; this run shows 529 / 2559 — small organic growth (+4
notes, +77 edges) consistent with normal activity, no anomalies.

## Graph metrics

- **Total nodes (notes):** 529
- **Total edges (links):** 2559
- **Mean degree:** 9.67 (= 2 * edges / nodes)
- **Most-connected node:** `[[Operator-Principles]]` (in: 130, out: 19, total: **149**)
- **Distinct broken-link targets:** 82 (209 broken edges total — ~8% of all links resolve to nothing)

## Top 20 hubs

| Rank | Note | In-degree | Out-degree | Total | Type |
|---|---|---|---|---|---|
| 1 | `[[Operator-Principles]]` | 130 | 19 | 149 | principle |
| 2 | `[[2026-05-25-brain-upgrade-plan]]` | 119 | 7 | 126 | (untyped) |
| 3 | `[[Nexus-MOC]]` | 57 | 58 | 115 | moc |
| 4 | `[[OBSIDIAN_BRAIN_STRUCTURE]]` | 22 | 92 | 114 | (untyped) |
| 5 | `[[Foundation-Gate]]` | 73 | 21 | 94 | gate |
| 6 | `[[README]]` | 0 | 77 | 77 | (untyped) |
| 7 | `[[MEMORY_DISTILLATION_SPEC]]` | 56 | 18 | 74 | (untyped) |
| 8 | `[[AGENT_ORCHESTRATION_SPEC]]` | 51 | 19 | 70 | (untyped) |
| 9 | `[[2026-05-11_full_session]]` | 3 | 66 | 69 | (untyped) |
| 10 | `[[Memory-MOC]]` | 40 | 27 | 67 | moc |
| 11 | `[[Decisions-MOC]]` | 35 | 31 | 66 | moc |
| 12 | `[[Karri]]` | 45 | 18 | 63 | person |
| 13 | `[[SKILL_REGISTRY_SPEC]]` | 44 | 18 | 62 | (untyped) |
| 14 | `[[System-Architecture-MOC]]` | 22 | 38 | 60 | moc |
| 15 | `[[Truth-Hierarchy]]` | 48 | 8 | 56 | principle |
| 16 | `[[_README]]` | 6 | 45 | 51 | (untyped) |
| 17 | `[[Tools-MOC]]` | 39 | 12 | 51 | moc |
| 18 | `[[Thesis-MOC]]` | 24 | 27 | 51 | moc |
| 19 | `[[INTEGRATION_NOTES_v1.1]]` | 10 | 40 | 50 | (untyped) |
| 20 | `[[RAG_ENGINE_SPEC]]` | 28 | 21 | 49 | (untyped) |

**Observation:** the top-3 hubs (`Operator-Principles`, `2026-05-25-brain-upgrade-plan`,
`Nexus-MOC`) carry disproportionate centrality. `Operator-Principles` alone is
referenced 130 times — it's the gravitational center of the brain. The upgrade-plan
note's hub status is artifact-of-the-moment: a lot of recent inbox/audit dumps
reference it. Expect it to decay over time.

## Orphan candidates (in_degree = 0)

**Count: 251 / 529 (47.4 % of vault)** — nothing links TO these notes.

Caveats:
- The brain is heavily dated-log oriented (`00-claude-inbox/<project>/<date>` dumps).
  Many "orphans" are session logs that were *never meant* to be MOC-linked — they're
  write-once archive. So 47% is high, but not all of it is actionable.
- Genuine orphan candidates are those with **high out_degree** (active, link-rich,
  but no one links back).

### Top 10 high-signal orphans worth re-surfacing

| Note | Out-degree | Path | Likely action |
|---|---|---|---|
| `[[README]]` | 77 | `00-firm-bus/README.md` | Intentional (top-level entry); skip |
| `[[audit-report-2026-05-25]]` | 44 | `08-system-architecture/` | Link from System-Architecture-MOC |
| `[[wikilink-audit-v2-2026-05-25]]` | 29 | `08-system-architecture/` | Link from System-Architecture-MOC |
| `[[2026-05-11-deadlink-drain-r3]]` | 25 | `00-claude-inbox/nexus/` | Archive (old inbox dump) |
| `[[wikilink-validation-2026-05-13]]` | 16 | `_maps/` | Link from System-Architecture-MOC |
| `[[00_SYNTHESIS]]` | 13 | `00-claude-inbox/nexus/2026-05-13/` | Promote or archive |
| `[[2026-05-11-graph-densification]]` | 11 | `00-claude-inbox/nexus/` | Archive |
| `[[00_ROUND2_SYNTHESIS]]` | 10 | `00-claude-inbox/nexus/2026-05-13/round2/` | Promote or archive |
| `[[2026-05-11-moc-backfill-round-2]]` | 9 | `00-claude-inbox/nexus/` | Archive |
| `[[brain-task-list]]` | 8 | `03-skills/` | Link from a skills/MOC index |

## Isolated leaves (out_degree = 0)

**Count: 253 / 529 (47.8 % of vault)** — these notes don't link out to anything.

### Top 10 popular leaves (high in-degree, zero out-degree)

| Note | In-degree | Path | Category |
|---|---|---|---|
| `[[2026-05-24-onprem-ai-strategi]]` | 11 | `03-business/` | Likely intentional (stub strategy doc) |
| `[[discord-delivery-state]]` | 9 | `01-nexus/runtime-state/` | Runtime state — intentional |
| `[[ADR-002-sqlite-then-postgres]]` | 4 | `00-command-center/ADRs/` | ADR — could link to prior ADRs |
| `[[OPERATOR-NEXT-STEPS]]` | 3 | (root) | Could link to current focus / MOCs |
| `[[ADR-001-architecture]]` | 3 | `00-command-center/ADRs/` | Could link to specs |
| `[[firm-launcher]]` | 3 | `_runbooks/` | Should link to operator-principles, OK-Kjor-Gate |
| `[[05_cross_strategy_regime]]` | 3 | `00-claude-inbox/nexus/2026-05-13/` | Inbox dump — fine |
| `[[SECURITY-INCIDENT-API-KEY]]` | 2 | (root) | Should link to security/ runbooks |
| `[[SYSTEM-AUDIT]]` | 2 | (root) | Should link to System-Architecture-MOC |
| `[[STATE-2026-05-13-FINAL]]` | 2 | (root) | Snapshot — could link to current state |

**Fully isolated** (in=0 AND out=0): **206 notes (38.9 %)** — completely disconnected
from the graph.

Folder distribution of fully-isolated notes:

| Folder | Count |
|---|---|
| `00-claude-inbox` | 171 |
| `00-firm-bus` | 15 |
| `00-templates` | 6 |
| `_promote-candidates` | 5 |
| `.github` | 3 |
| `01-nexus` | 1 |
| `security` | 1 |
| `00-command-center` | 1 |
| `_runbooks` | 1 |
| `firm-launcher` | 1 |
| `prompts` | 1 |

**Verdict:** 83 % of fully-isolated notes live in `00-claude-inbox/` (write-once
session/audit dumps — expected to be unlinked). The remaining 35 notes (firm-bus,
templates, promote-candidates, .github templates, security, prompts) are mostly
intentional fixtures (templates, issue-templates, runtime-state) — not cleanup
candidates.

## Type distribution

| Type | Count | % of vault |
|---|---|---|
| **untyped** | **207** | **39.1 %** |
| atomic | 45 | 8.5 % |
| runbook | 23 | 4.3 % |
| moc | 20 | 3.8 % |
| meta | 19 | 3.6 % |
| audit | 18 | 3.4 % |
| stub | 17 | 3.2 % |
| decision | 16 | 3.0 % |
| living | 9 | 1.7 % |
| string / investigation / ops | 8 each | 1.5 % each |
| workflow / mcp / claude / verification | 7 each | 1.3 % each |
| (54 other types) | 1-6 each | < 1 % each |

**Recommendation:** 39 % untyped is the biggest single signal. A frontmatter
audit pass (extending H-2's work) is warranted. Additionally, the long tail of
**54 types with ≤ 6 notes** suggests type sprawl — many of these could collapse
into the existing canonical set (atomic / moc / runbook / decision / meta /
audit / stub / living). One immediate cleanup: `moc` (20) vs `MOC` (1) — case
typo, merge.

## Mutual-link clusters (cohesive topic groups)

296 mutual link pairs detected (pairs where A→B and B→A both exist).

### Strongest mutual-link clusters

**Cluster 1 — Operator decision core**
`Operator-Principles` ↔ `Foundation-Gate` ↔ `OK-Kjor-Gate` ↔ `Truth-Hierarchy` ↔
`Nexus-MOC` ↔ `Karri` ↔ `Strategy-Proposal-Workflow` ↔ `Strategy-Promotion-Workflow` ↔
`When-Operator-Says-Kjor-Pa`. This is the densest cluster — the "operator
governance" cohort. Healthy.

**Cluster 2 — System-architecture / specs**
`OBSIDIAN_BRAIN_STRUCTURE` ↔ `MEMORY_DISTILLATION_SPEC` ↔ `SKILL_REGISTRY_SPEC` ↔
`System-Architecture-MOC`. Specs cross-reference each other well; MOC sits in
the middle.

**Cluster 3 — Nexus session-archive**
`Nexus-MOC` ↔ `2026-05-11_full_session` (a single dated session note that became
a hub). Slightly odd shape — one date-stamped note links 66 outward but receives
3 back. Probably worth promoting its content into atomic notes and archiving.

No proper community-detection was run; for deeper analysis use NetworkX
(`nx.algorithms.community.greedy_modularity_communities`) on the next pass.

## Broken-link hygiene

**209 edges (~8 % of all links) point to nonexistent notes** across 82 distinct
broken targets.

Top broken targets (each ≥ 5 references):

| Refs | Broken target | Likely cause |
|---|---|---|
| 15 | `[[2603.13017v1]]` | ArXiv paper ID — never created as a note |
| 10 | `[[CLAUDE.md]]` | Wikilink to a non-`.md`-as-note file (links should use path, not wikilink) |
| 9 | `[[wikilinks]]` | Generic word in prose got auto-wrapped |
| 9 | `[[reference_available_tools]]` | Memory file outside vault — wrong syntax |
| 8 | `[[command-center]]` | Should be a MOC; doesn't exist yet |
| 7 | `[[Note-Name]]` | Template placeholder leaked into real notes |
| 6 | `[[...]]` | Literal ellipsis (template artifact) |
| 5 | `[[-d "$WT_PATH"]]` | Bash snippet wrapped as wikilink (code-block escaping bug) |
| 5 | `[[<MOC>]]` | Template placeholder |
| 5 | `[[STUB:Operator-Principles]]` | Old stub-naming convention |

Several patterns here cross-reference the existing `wikilink-audit-v2-2026-05-25`
work and should feed back into it.

## Operator-actionable findings

1. **Hub nodes that could become MOCs themselves** — high in-degree, no MOC
   marker:
   - `[[MEMORY_DISTILLATION_SPEC]]` (56 in), `[[AGENT_ORCHESTRATION_SPEC]]` (51 in),
     `[[SKILL_REGISTRY_SPEC]]` (44 in), `[[RAG_ENGINE_SPEC]]` (28 in),
     `[[YOUTUBE_INGESTION_SPEC]]` (28 in), `[[GITHUB_DISCOVERY_SPEC]]` (27 in) —
     these specs act as MOCs without the label. Consider adding `type: moc` or
     promoting via Specs-MOC parent.
   - `[[2026-05-25-brain-upgrade-plan]]` (119 in) — second-highest in-degree.
     Dated planning doc with MOC-like usage. Decide: promote to permanent
     `Brain-Upgrade-MOC` or accept its sunset as a moment-in-time plan.

2. **Orphan notes worth re-linking from a MOC** — top targets:
   - `[[audit-report-2026-05-25]]`, `[[wikilink-audit-v2-2026-05-25]]`,
     `[[wikilink-validation-2026-05-13]]` → add to `System-Architecture-MOC`
   - `[[brain-task-list]]` → add to a skills index

3. **Dead-end leaves to expand** — high in, zero out (each *is* known, but
   doesn't help readers discover anything else):
   - `[[ADR-002-sqlite-then-postgres]]` and `[[ADR-001-architecture]]` should
     cross-reference each other and the relevant specs.
   - `[[firm-launcher]]`, `[[SECURITY-INCIDENT-API-KEY]]`, `[[SYSTEM-AUDIT]]`,
     `[[OPERATOR-NEXT-STEPS]]` are all "popular-but-blind" — adding 2-3 outgoing
     links each would significantly improve navigation.

4. **Cleanup batch (low risk)**:
   - Merge type `MOC` (1 note) into `moc` (20 notes) — case typo.
   - 54 single-use type values — collapse into canonical 8-10 types.
   - 39 % untyped — frontmatter audit pass (extends H-2).

5. **Inbox archive** — 171 fully-isolated notes in `00-claude-inbox/` consume
   ~32 % of vault. Most are intentional write-once. Consider moving everything
   pre-2026-05-13 to `90-archive/` to clean up the live graph.

## Comparison to G-7 baseline

| Metric | G-7 test-run | This run (2026-05-25 14:57Z) | Delta |
|---|---|---|---|
| Nodes | 525 | 529 | +4 |
| Edges | 2482 | 2559 | +77 |
| Top hub | Operator-Principles | Operator-Principles | unchanged |

Vault is growing slowly (~4 notes since G-7's test). Edge growth (+77) faster
than node growth (+4) — links are densifying. Healthy direction.

## Next analysis cadence

- **Monthly** (or after major content additions). Compare hub-shifts, orphan
  count, broken-link count over time.
- **Better cluster detection** next run: use NetworkX
  (`greedy_modularity_communities` or `louvain_communities`) instead of the
  mutual-pair heuristic. Worth a small `brain-link-graph-analyze.py` script.
- **Broken-link followups** — many overlap with `[[wikilink-audit-v2-2026-05-25]]`.
  Next pass should diff broken-target lists across audits to confirm cleanup
  is sticking.
