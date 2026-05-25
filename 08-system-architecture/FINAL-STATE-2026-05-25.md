---
title: Brain final state — 2026-05-25T17:00Z
date: 2026-05-25
status: FINAL (post all 12 fases / 120 sub-agenter)
purpose: Consolidated final-state metrics after sprint 1 closure + execute-fase
related:
  - "[[audit-report-v4-2026-05-25]]"
  - "[[wikilink-audit-v3-2026-05-25]]"
  - "[[link-graph-v3-2026-05-25]]"
tags:
  - audit
  - final
  - sprint-1
  - brain
---

# Brain final state — 2026-05-25

## Brain content audit (v5)

- Issues: **1**
- Warnings: **2**
- Invalid YAML: **1** (`08-system-architecture/audit-report-v4-2026-05-25.md` — inline-flow `related: [[X]], [[Y]]` block-mapping parse error)
- Missing frontmatter: **0** (canonical run; all eligible notes have `---` opener)
- Broken wikilinks (script-detected potential): **102** (mostly bash-syntax false-positives + documented stubs + placeholder template strings inside specs/audit docs; see wikilink audit v4 below for the strict-classifier number)
- Markdown-style `.md` links (should be wikilinks): 5 files flagged
- Future-dated files: 0
- Required folders: all 16 present
- Required READMEs: all 7 present
- Status: **YELLOW** (1 residual YAML issue carried over from a previous-audit drop; read-only constraint blocked fix this run)

## Brain link-graph (v4)

- Nodes: **549**
- Edges: **2268**
- Broken edges: **32**
- Orphans (in_degree=0 AND out_degree=0): **213**
- Health: **98.6%** (resolved / total)
- Top hub: `_maps/Operator-Principles` (in_degree=121, out_degree=18)
- Runner-up hubs: `2026-05-25-brain-upgrade-plan` (106 in), `_maps/Foundation-Gate` (69 in), `01-nexus/Nexus-MOC` (54 in), `08-system-architecture/specs/OBSIDIAN_BRAIN_STRUCTURE` (20 in / 58 out)

## Wikilink audit (v4)

Same methodology as v3 (122-file curated scope, 4-class taxonomy, J-2 fenced-code + code-span filters, 8-stub vocabulary, 25 placeholder regexes).

- Total occurrences: **1493** (v3: 1447 → +46)
- Counted (real links): **890** (v3: 884 → +6)
- Resolved: **878** (v3: 864 → +14)
- Stub: **11** (v3: 11 → 0)
- Broken: **1** (v3: 9 → −8) — `[[COMMIT_PLAN_2026-05-25]]` in `preflight-report-2026-05-25.md` frontmatter
- Placeholder (skipped): **603** (fenced=60, code-span=532, bash=0, template=11)
- Health: **98.7%** (v3: 97.7 → +1.0 pp)

Sum check: 878 + 11 + 1 = 890 counted; 890 + 603 = 1493 total. ✓

### Stub vocabulary (unchanged from v3, 5 unique)

`2603.13017v1`, `CLAUDE.md`, `command-center`, `handoffs/`, `reference_available_tools`

### Broken (1 unique → 1 occurrence)

| Wikilink | Loc | Nature |
|---|---|---|
| `[[COMMIT_PLAN_2026-05-25]]` | `08-system-architecture/preflight-report-2026-05-25.md` frontmatter `related:` | Forward-reference; commit-plan doc never landed in brain. Easy close-out: remove the `related:` entry or create the stub. |

The other 8 v3 broken occurrences (3× `trading-knowledge`, `ADR-003-cross-machine-sync`, `ADR-004-slice-14-control-plane-split`, `firm-task-claim.sh`, `firm-task-complete.sh`, `30-agent-audit`) all closed between v3 and v4 — either added to documented-STUB list, stub files created, or frontmatter references trimmed during fase 11-12.

## Evolution table

| Audit | v1 | v2 | v3 | v4/v5 (FINAL) |
|---|---|---|---|---|
| brain-content (Issues) | 1 | 1 | 1 | **1** |
| brain-content (Invalid YAML) | 24 | 11 | 1 | **1** |
| brain-content (Missing frontmatter) | 135 | 24 (exempted) | 24 | **0** |
| brain-content (Broken wikilinks, script regex) | 90 | 95 | 102 | **102** |
| link-graph (Nodes) | n/a | ~525 | 529 | **549** |
| link-graph (Broken edges) | 209 | 253 | 31 | **32** |
| link-graph (Health %) | n/a | n/a | ~98.6 | **98.6%** |
| wikilink-audit (Resolved) | 648 | 803 | 864 | **878** |
| wikilink-audit (Stub) | 38 | 30 | 11 | **11** |
| wikilink-audit (Broken) | 1 | 0 | 9 | **1** |
| wikilink-audit (Health %) | 94.3 | 96.4 | 97.7 | **98.7%** |

## Reconciliation note: v5 "Issues=1" vs v4-audit-report claim of "Issues=0"

The v4 audit-report (`audit-report-v4-2026-05-25.md`) self-reports `Issues: 0` and `Status: GREEN`. My re-run reports `Issues: 1` because:

- That file itself has `related: [[audit-report-v3-2026-05-25]], [[wikilink-audit-v3-2026-05-25]]` (inline-flow form). PyYAML `safe_load` rejects it as a block-mapping parse error at line 1, column 1.
- The K-2 fix referenced in v4-audit-report did not land in this file. (Possible: fix landed in a different file, or commit got reverted/lost.)
- Constraint `files_allowed = FINAL-STATE-2026-05-25.md + tmp file` and "Read-only on brain content" prevented me from quoting the `related:` list here. **Recommended close-out (operator-gated): change `related:` in that file to block-list quoted form, ~30 seconds of edit, will move v5 Issues 1→0.**

This is the same class of issue that the v1 → v3 progression fixed in 23 other files. One residual instance remains. No regression risk — file is a historical audit artifact, not load-bearing.

## Link-graph broken-edges note: 31 → 32

One net new broken edge vs v3 link-graph. Sample from this run: `SPRINT-1-COMPLETE-2026-05-25 → COMMIT_PLAN_2026-05-25`, `2026-05-25-brain-upgrade-plan → command-center`, `MEMORY_DISTILLATION_SPEC → 2603.13017v1` (stub), `MEMORY_DISTILLATION_SPEC → CLAUDE.md` (stub), `SKILL_REGISTRY_SPEC → existing-skill` (placeholder).

Per wikilink-reconciliation methodology these split into:
- ~5 documented-STUB edges (the brain-link-graph script doesn't filter these — they show as broken under its 2-bucket classifier)
- ~10–15 placeholder/template wikilinks inside specs (e.g. `existing-skill`, `some-spec`)
- ~10 genuinely broken (the K-1 → wikilink-audit-v4 closures cleared most v3 ones, but the SPRINT-1-COMPLETE doc added new ones during fase 12 closure)

Under the strict v4 wikilink-audit classifier (applied to the curated 122-file scope), only **1** genuinely-broken occurrence remains.

## Orphans (213 of 549 nodes = 39%)

These are nodes with no incoming AND no outgoing edges in the graph. Mostly explained by:
- `00-firm-bus/inbox/*.md` — append-only inter-pane inboxes, not linked anywhere
- `00-claude-inbox/<project>/*.md` — audit/verification drops, not linked
- Recently-created date-stamped notes pending MOC linkage
- Historical `90-archive/` content (still scanned but disconnected by design)

Not a regression; expected under brain conventions. Trim target only if orphan ratio exceeds ~50% or if MOC enrichment lane is active.

## Sign-off

Brain audit + link-graph + wikilink all **YELLOW** (one residual YAML carry-over) → **PASS WITH CAVEAT** for sprint 1 final closure.

- Wikilink audit reached 98.7% health (target >95% **MET**) with 1 remaining broken occurrence — manageable.
- Link-graph stable at 98.6% health, broken-edge count 32 (was 31 in v3 — flat-ish; new SPRINT-1-COMPLETE content added 1 edge).
- Brain content audit has 1 residual YAML issue that requires a 30-second operator-gated edit to clear.

Sprint 1 final closure metric: **PASS** (all 3 audits within target bands; one cleanup task explicitly enumerated and operator-gated).

## Verify checklist (5×)

1. **All 3 audits ran**: brain-content (v5) via `brain-content-audit.sh`, link-graph (v4) via `brain-link-graph.sh /tmp/brain-graph-v4-final.json`, wikilink-audit (v4) via `/tmp/classify_v4.py` over `/tmp/wl_v4_scope.txt` (122 files) + `/tmp/wl_v4_all_files.txt` (591 files). ✓
2. **Real numbers (not invented)**: every figure traceable to `/tmp/audit_full.txt`, `/tmp/brain-graph-v4-final.json` (parsed via inline Python), and `python3 /tmp/classify_v4.py` stdout. No counts copied from prior reports without re-verification. ✓
3. **Evolution table correct**: v1/v2/v3 figures pulled from `audit-report-v4-2026-05-25.md` table + `wikilink-audit-v3-2026-05-25.md` table; v4/v5 column populated from this run only. ✓
4. **Status set**: brain-content YELLOW; link-graph YELLOW (target >95% met, flat broken-edges); wikilink YELLOW (target >95% met, 1 broken). Aggregate sprint-1 PASS WITH CAVEAT. ✓
5. **Frontmatter YAML valid**: block-list form with quoted strings (`"[[X]]"`), ISO date, status string, related/tags lists — matches K-2 fix pattern. ✓

## Methodology notes (reproducibility)

- Brain-content: `bash /home/nithu/Obsidian/Brain/scripts/brain-content-audit.sh` (canonical run captured at `/tmp/audit_full.txt`).
- Link-graph: `bash /home/nithu/Obsidian/Brain/scripts/brain-link-graph.sh /tmp/brain-graph-v4-final.json` (549-node graph; broken edges = `[e for e in edges if e.to not in {n.id for n in nodes}]`).
- Wikilink-audit: same `find ... -name "*.md"` scope as v3 (08-system-architecture + _maps + 03-skills top-level + 10-tasks + 00-templates + 09-retrospectives + 12-youtube + 13-github-repos = 122 files); brain-wide index (`-not -path .git/.obsidian/_library/node_modules/__pycache__`) = 591 files; classifier `/tmp/classify_v4.py` preserves v3's 8-stub vocabulary + 25 placeholder regexes + J-2 fenced-code + code-span filters verbatim.

## Next cadence

- Re-run quarterly OR after one of: brain orchestrator launch, code-1 lane landing, `.stub-allow` ratification (would re-baseline STUB count to 0).
- Earlier ad-hoc re-run if `wikilink-reconciliation` notes +20 broken edges brain-wide.

---

Generated by Claude Code agent at 2026-05-25T17:00Z after fase 12 closure + 120 sub-agent execute-fase. Read-only on brain content per task constraints.
