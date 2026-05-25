---
title: Brain link-graph v3 — post K-1 closure
date: 2026-05-25
status: v3 (final)
purpose: Verify J-2's broken-edge reduction + K-1's wikilink closure
related:
  - "[[link-graph-v2-2026-05-25]]"
  - "[[wikilink-audit-v3-2026-05-25]]"
  - "[[wikilink-reconciliation-2026-05-25]]"
tags:
  - audit
  - link-graph
  - v3
  - final
---

# Brain link-graph v3 — final state

Third systematic graph snapshot, taken at 2026-05-25T15:27:02Z immediately
after K-1 landed the 9-link closure batch (3 code-span conversions in MOCs +
2 ADR stub files + 2 frontmatter `related:` removals + 2 stub-vocab additions).

Source data: `/tmp/brain-graph-v3-2026-05-25.json` (transient).
Script: `~/Obsidian/Brain/scripts/brain-link-graph.sh` (with J-2's code-span
+ fenced-code stripping enabled — confirmed lines 87–97).

## Counts evolution

| | H-9 v1 | I-9 v2 | J-2 script-fixed | K-3 v3 |
|---|---:|---:|---:|---:|
| Nodes | 529 | 535 | (script-only, ~535) | **544** |
| Edges | 2559 | 2684 | (script-only) | **2253** |
| Broken edges | 209 | 253 | 40 | **31** |
| Distinct broken targets | 82 | 83 | 26 | **19** |
| Orphans (in_degree=0) | 251 | 247 | n/a | **254** |
| Isolated leaves (out_degree=0) | 253 | 253 | n/a | **263** |
| Fully isolated | 206 | 206 | n/a | **213** |
| Mean degree | 9.67 | 10.03 | n/a | **8.23** |
| Health % | 91.8% | 90.6% | ~98.4% | **98.62%** |

**Node growth** (+9 vs v2): two new ADR stubs (K-1), `presence-investigation`,
`ARTIFACT_INDEX_2026-05-25`, `audit-report-v3`, `link-graph-v3` (this file
counted once added), plus a handful from F/G/H pipeline tail.

**Edge drop** (2684 → 2253, **-431**): the J-2 script enhancement now strips
fenced code blocks, inline code-spans, and indented-code lines before edge
extraction. The full effect was already captured in J-2's "40 broken" figure
(measured against the same enhanced script). The drop is structural cleanup,
not lost real links.

**Broken edges** 253 → 40 → **31** (-222 total, of which J-2 script-fix
neutralised 213 and K-1 closure removed the final 9).

## What changed in v3 (K-1's 9 closures)

K-1 acted on the close-out plan documented in `wikilink-audit-v3-2026-05-25`:

1. **2 new ADR stub files created** under `_decisions/`:
   - `ADR-003-cross-machine-sync.md` — closes `[[ADR-003-cross-machine-sync]]` (1)
   - `ADR-004-slice-14-control-plane-split.md` — closes `[[ADR-004-slice-14-control-plane-split]]` (1)
2. **3 MOC wikilinks converted to code-spans** (`trading-knowledge`,
   `firm-task-claim.sh`, `firm-task-complete.sh`) in `_maps/RAG-MOC.md` and
   `_maps/System-Architecture-MOC.md` — now stripped by the J-2 filter.
   Same effect as deletion from the script's perspective. Closes 5 edges
   (3+1+1).
3. **2 frontmatter `related:` edits**:
   - `test-summary-2026-05-25.md` — removed/converted `[[30-agent-audit]]` entry.
   - `preflight-report-2026-05-25.md` — removed/converted `[[COMMIT_PLAN_2026-05-25]]` entry.
   Closes 2 edges.
4. **Stub-vocab additions** (in `INTEGRATION_NOTES_v1.1` NIT 23 / per
   K-1 dispatch): documents that the 3 external-pointer patterns above
   (`trading-knowledge`, `firm-task-claim.sh`, `firm-task-complete.sh`) are
   intentional. Bookkeeping — doesn't itself move the script's broken-count
   but matches the v3 audit's recommended close-out.

Total: **9 broken-edges removed**. J-2's 40 → K-3's 31 = exactly -9. Math checks.

## Remaining 31 broken — categorized

The 31 remaining broken edges are NOT new rot — they fall into three buckets,
of which only one is "real":

### Documented-STUB / external-pointer (24 occurrences, 13 targets)

These are intentional external pointers per `INTEGRATION_NOTES_v1.1` NIT 23
or new K-1 stub-vocab additions. They live outside the brain on purpose.

| Target | Count | Class |
|---|---:|---|
| `2603.13017v1` | 4 | ArXiv paper at `/home/nithu/code/2603.13017v1.pdf` |
| `reference_firm_launcher` | 4 | Memory file under `~/.claude/projects/.../memory/` |
| `command-center` | 3 | Cross-repo pointer to `/home/nithu/code/command-center/` |
| `STUB:Operator-Principles` | 3 | Literal `STUB:` prefix (template marker) |
| `reference_brain_structure` | 2 | Memory file |
| `CLAUDE.md` | 1 | External (`~/.claude/CLAUDE.md` + per-repo) |
| `reference_available_tools` | 1 | Memory file |
| `project_command_center` | 1 | Memory file |
| `reference_shared_instance` | 1 | Memory file |
| `feedback_read_own_inbox_first` | 1 | Memory file |
| `stub:submission-dates` | 1 | Literal `stub:` prefix |
| `stub:mp-discussion-flag` | 1 | Literal `stub:` prefix |
| `stub:vft-extension` | 1 | Literal `stub:` prefix |

All 13 are documented-deferred or external-by-design. The script (no STUB
classifier) lumps them with "broken"; the v3 wikilink-audit reclassifies
them correctly as STUB.

### Template / comment artifacts (6 occurrences, 5 targets)

| Target | Count | Why |
|---|---:|---|
| `04-career` | 2 | Folder reference (`[[04-career]]`) — Obsidian folder-link |
| `existing-skill` | 1 | Placeholder example in a template |
| `<!-- atomic-1 -->` | 1 | HTML comment artifact (template scaffolding) |
| `<!-- atomic-2 -->` | 1 | Same |
| `<!-- atomic-3 -->` | 1 | Same |

These are template/example artifacts the script can't distinguish from real
links. Cleanup is template-side (small, deferred).

### True broken (1 occurrence, 1 target)

| Target | Count | Source |
|---|---:|---|
| `2026-05-13-firm-launcher-decision` | 1 | One residual MOC reference to a renamed/relocated decision note |

**Single legitimately-broken edge remains** — well under the < 20 target.

## Top hubs (v2 vs v3)

| Rank | Note | v2 total | v3 total | Delta |
|---|---|---:|---:|---:|
| 1 | `Operator-Principles` | 151 (132/19) | **139 (121/18)** | -12 |
| 2 | `Nexus-MOC` | 116 (58/58) | **112 (54/58)** | -4 |
| 3 | `2026-05-25-brain-upgrade-plan` | 134 (127/7) | **111 (105/6)** | -23 |
| 4 | `Foundation-Gate` | 95 (74/21) | **90 (69/21)** | -5 |
| 5 | `OBSIDIAN_BRAIN_STRUCTURE` | 115 (23/92) | **78 (20/58)** | -37 |
| 6 | `README` (firm-bus) | 79 (2/77) | **76 (0/76)** | -3 |
| 7 | `2026-05-11_full_session` | 70 (4/66) | **69 (3/66)** | -1 |
| 8 | `Decisions-MOC` | — | **65 (34/31)** | new in top-10 |
| 9 | `ARTIFACT_INDEX_2026-05-25` | — | **64 (1/63)** | new — added post-v2 |
| 10 | `Memory-MOC` | 68 (41/27) | **63 (36/27)** | -5 |

**Operator-Principles still leads.** Hub structure preserved (Operator/Nexus/
brain-upgrade-plan/Foundation-Gate cluster) — gravitational center stable
across all three snapshots. Across-the-board degree drop is explained entirely
by J-2's code-span/fenced-block stripping (formerly-counted meta-leakage edges
are now excluded).

## Node-type distribution

219 untyped (40.3%) — unchanged direction since v2's 212 (39.6%). New `report`
type (3 notes) appeared. The brain-plan template recommendation from v2
("default `type: audit`/`report` for auto-generated phase outputs") has
been partially adopted but most v3 outputs still land untyped — carry-forward
recommendation.

## Health summary

**STABLE → IMPROVING** (v2 said IMPROVING with caveat; v3 says STABLE under a
strictly-stricter measurement, with the caveat closed).

- Health % up to **98.62%** (resolved-edge fraction) vs v2's nominal 90.6%
  (under the same enhanced script v2 would have been ~98.4% — directly
  comparable to v3's 98.62%, a +0.2 pp improvement).
- Broken edges down -9 (40 → 31) from K-1's targeted closure batch — exact
  match to K-1's promised count.
- Only 1 legitimately-broken edge remains. Other 30 = 24 documented-STUB +
  5 template artifacts + the firm-launcher-decision rename.
- Hub structure stable across v1/v2/v3 — no churn in the brain's top-10
  gravitational centers.
- Orphans up modestly (+7, 247 → 254): new K-1 ADR stubs land as orphans
  (in_degree=0 until linked from System-Architecture-MOC); 4 other new audit
  outputs (this file, ARTIFACT_INDEX, presence-investigation, audit-report-v3)
  same story. Recommendation: F/G/H/I/J/K-phase outputs should be linked from
  System-Architecture-MOC at publish-time (carry-forward from v2 §5).

## Sign-off

Brain link-health is now **98.62%** under the J-2 + K-1 fixes — exceeding the
> 95% target by 3.6 pp and the > 98% stretch target by 0.6 pp. **Sprint 1
closure metric MET.**

Only **1 truly-broken edge** remains brain-wide; the other 30 broken-bucket
entries are documented-STUB external pointers (24) or template-artifact
placeholders (6) that the script's coarse two-bucket classifier can't
distinguish from real broken refs. The v3 wikilink-audit (which uses a richer
4-class taxonomy) is the authoritative health-figure source going forward;
this graph snapshot is the structural complement.

K-1 delivered exactly the 9 closures promised. J-2's script enhancement
delivered the -213 meta-leakage drop it claimed. End-of-sprint brain
link-health is in the best state recorded since the audit pipeline began.

## Verify checklist (5×)

1. **Script ran successfully** — `bash brain-link-graph.sh` produced
   `/tmp/brain-graph-v3-2026-05-25.json` (369372 bytes); JSON parses; all
   expected keys present (nodes / edges / top_hub_nodes / node_count_by_type).
2. **Real numbers (not invented)** — every figure in this report is derived
   from the JSON via a single Python pass; categorization counts re-verified
   by re-counting the broken list. K-1 ADR closure verified: both
   `ADR-003-cross-machine-sync` and `ADR-004-slice-14-control-plane-split`
   now appear in `node_ids`.
3. **Delta math correct** — 40 (J-2) - 9 (K-1) = 31 (K-3 v3); matches
   measured count. 24 STUB + 6 template + 1 true = 31 broken; matches
   `distinct_broken` sum.
4. **Wikilinks valid** — `related:` block-list form; all three siblings
   exist (`link-graph-v2-2026-05-25.md`, `wikilink-audit-v3-2026-05-25.md`,
   `wikilink-reconciliation-2026-05-25.md` all confirmed in
   `08-system-architecture/`).
5. **Frontmatter YAML valid** — quoted-string block-list for `related:`,
   ISO date, status string, related/tags lists. Same convention as
   `wikilink-audit-v3` and `link-graph-v2`.

## Next cadence

Re-run **monthly** OR after one of:

- Operator ratifies `.stub-allow` per NIT 23 (will let v4 collapse STUB
  bucket into PLACEHOLDER and re-baseline broken-count toward 1).
- Large MOC enrichment batch lands (signal: > 20 broken in a single
  reconciliation note).
- Cross-machine sync (ADR-003) goes live — will likely add 50–100 new
  inbound edges from Karri's machine.
