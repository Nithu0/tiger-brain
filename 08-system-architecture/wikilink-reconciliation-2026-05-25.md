---
title: Wikilink methodology reconciliation
date: 2026-05-25
status: v1.0
purpose: Reconcile G-3 vs H-9 wikilink counts
related:
  - "[[wikilink-audit-v2-2026-05-25]]"
  - "[[link-graph-insights-2026-05-25]]"
tags: [meta, audit, reconciliation, wikilinks]
---

# Wikilink methodology reconciliation

Two audits ran on the same brain on the same day and produced apparently
contradictory headline numbers. This note shows that **both are correct under
their stated methodology** — the discrepancy is scope + classification, not a
real disagreement.

## Counts

- **G-3 wikilink-audit v2**: 803 RESOLVED / 30 STUB / **0 BROKEN** = 96.4 %
  (counted base: 833 occurrences across 100 placeholders excluded)
- **H-9 link-graph**: 2559 edges, **209 broken** (~8 %), 82 distinct missing
  targets (from snapshot at 2026-05-25T14:57Z; live re-run at 17:03Z shows
  249 / 83 — graph grew +112 edges in ~2 hours from this and adjacent audit
  notes referencing missing targets, which is consistent with H-9's "slow
  organic growth" observation and does not change the reconciliation logic
  below)

The 0-vs-209 framing is the headline shock. It dissolves under three lenses:
**scan scope**, **classification policy**, and **how the parser handles
edge-cases**.

## Why the difference

### 1. Scope

| Audit | Files scanned |
|---|---|
| G-3 | The curated subset built by C-10 v1 plus the new D-4 / D-8 / D-10 / F-10 deliverables. Explicitly listed in the v2 methodology section. Roughly the "upgrade content" of phase 4-6 plus the 7 original specs, all MOCs, READMEs, templates, retros, and how-tos. |
| H-9 | Every `.md` under `~/Obsidian/Brain/` except `.git`, `.obsidian`, `_library`, `node_modules`, `__pycache__`. 529 nodes. |

H-9 sees the entire `00-claude-inbox/` archive (171 fully-isolated session
dumps, full of historical inline `[[...]]` references that were never meant
to resolve), all of `00-firm-bus/`, templates, prompts, security/, the
command-center ADRs, and the root-level snapshot files. G-3 deliberately
excluded these because v1's purpose was to measure the new brain-upgrade
content, not to police the inbox archive.

### 2. Classification policy

G-3 has **three buckets** plus a placeholder-skip:

- RESOLVED — target exists on disk
- STUB — target is one of 8 documented "deliberate-external" or
  "forthcoming" references tracked in `INTEGRATION_NOTES_v1.1`
- BROKEN — anything else (currently 0)
- PLACEHOLDER (skipped) — template tokens, bash constructs, schema examples

H-9 has **two buckets**:

- RESOLVED (edge target appears in the node set)
- BROKEN (everything else, **including** template placeholders, bash
  artifacts like `[[ -d "$WT_PATH" ]]`, and every G-3 documented stub)

So G-3's "0 broken" and H-9's "209 broken" are measuring different quantities
with the same word. They are not in conflict — they are answering different
questions.

### 3. Edge-case handling

Both strip `|alias` and `#anchor` before comparing targets — that bit is
consistent. The parser-level differences are:

| Edge case | G-3 | H-9 (`brain-link-graph.sh`) |
|---|---|---|
| `[[Note\|Alias]]` | strip alias, compare basename | strip alias, compare basename |
| `[[Note#Section]]` | strip anchor | strip anchor (`re.split(r'[#^]', ...)`) |
| `[[folder/note]]` | counted; resolved against subdir-paths in the file index | **skipped entirely** (the script does `if '/' in target: continue`) |
| `[[ -d "$WT_PATH" ]]` (bash) | PLACEHOLDER (skipped) | counted as broken edge |
| `[[<MOC>]]`, `[[Note-Name]]`, `[[...]]`, `[[X]]`, `[[Y]]` | PLACEHOLDER (skipped) | counted as broken edges |

The folder-path handling in particular means H-9 silently drops `[[handoffs/]]`
and similar — those don't show up in either bucket of H-9. There are 132
folder-path occurrences brain-wide that H-9's pipeline never sees.

## Reconciled "true" count

Re-running `brain-link-graph.sh` and splitting the 249 broken edges by the
three plausible categories:

| Definition | Count | Notes |
|---|---:|---|
| Template placeholders / bash artifacts | **113** | `[[X]]`, `[[Y]]`, `[[<MOC>]]`, `[[Note-Name]]`, `[[...]]`, `[[ -d "$WT_PATH" ]]`, `[[wikilinks]]`, `[[<placeholder>]]`, `[[<related-note>]]`, `[[T-...]]`, `[[example]]`, `[[<new-path>]]`, `[[<!-- atomic-N -->]]`, `[[wiki-links]]`, `[[STUB:Operator-Principles]]`, `[["$cmd_string" != *$'\n'*]]`, etc. G-3 skips all of these. H-9 counts them as broken. |
| G-3 documented stubs (deliberate-external) | **58** | `[[CLAUDE.md]]` (12), `[[2603.13017v1]]` (17), `[[reference_available_tools]]` (11), `[[command-center]]` (10), `[[katastrofedag-analyse-2026-05-12]]` (4), `[[reference_autopush]]` (4). G-3 calls these STUB; H-9 calls them BROKEN. |
| Genuinely broken (typos, dead-renames, missing files) | **78** | Across 48 distinct targets. Top examples: `[[memory-distillation-spec]]` (4 — all inside audit notes documenting the original typo, not live usage), `[[04-career]]` (4 — folder reference written as note), `[[reference_firm_launcher]]` (4 — external memory-file ref), `[[30-agent-audit]]` (3), `[[ADR-003-cross-machine-sync]]` (3), `[[2026-05-13-firm-launcher-decision]]` (3), `[[trading-knowledge]]` (3 — skill name written as note ref), `[[ADR-004-slice-14-control-plane-split]]` (2), `[[reference_brain_structure]]` (2), `[[stub:mp-discussion-flag]]` (2), and a long tail of single-use references in inbox dumps. |
| Folder-path style links (silently dropped by H-9) | 132 | Brain-wide grep count for `[[…/…]]`. Most legitimate (`[[01-nexus/...]]`-style cross-refs); G-3 evaluates these against subdir-paths, H-9 does not. |
| Anchor-only refs (`[[#section]]`) | 1 | Negligible; both audits handle correctly. |
| **Total `[[...]]` occurrences in brain** | **2829** | Full-brain grep. H-9 sees ~2697 (2829 − 132 folder-path); H-9 reported 2559 edges because additional placeholders inside frontmatter/code-fences fall outside the link-regex window. |

So under the strictest definition — **edges that point to a note that should
exist but doesn't** — there are **78 broken edges across 48 distinct
targets**, brain-wide. The 209 (now 249) figure is dominated by template
placeholders (113) plus documented stubs (58) that the operator has already
chosen not to "fix".

## Recommendation

- Treat **G-3 as authoritative for the brain-upgrade content** (new folders,
  post-2026-05-25 deliverables). For that scope, the brain is clean (0
  broken).
- Treat **H-9 as scan-of-record for the whole brain** (it is the only audit
  that touches `00-claude-inbox/`, root snapshots, ADRs, etc.) — but read its
  "broken" column with the three-way split above, not as a single number.
- The headline number worth tracking week-over-week is **78 genuinely-broken
  edges / 48 targets**, not 209/82.
- Most of the genuine 78 are in `00-claude-inbox/` historical dumps and
  reference now-renamed targets. Triage them in a "promote-or-archive" pass,
  not a "fix the link" pass.

## Next steps

- **G-7 follow-up**: extend `brain-link-graph.sh` with two optional flags:
  - `--stub-allow=<file>` — read a list of documented stub targets and
    classify them separately (STUB, not BROKEN).
  - `--skip-placeholders` — apply the G-3 placeholder regex set so template
    artifacts don't pollute the BROKEN count.
  With both flags, H-9's number would converge on G-3's methodology and the
  two audits would produce comparable headline numbers.
- **Weekly cadence** (per `Runbook-Brain-Upgrade-Workflow`): publish three
  numbers separately: `total_edges`, `documented_stubs`, `genuinely_broken`.
  Stop reporting a single conflated "broken" count.
- **Do not** try to "fix" the 209/249. Most are intentional inbox-archive
  references, template placeholders, or already-tracked external stubs
  awaiting the `.stub-allow` decision (`INTEGRATION_NOTES_v1.1` NIT 23).
- **Operator decision pending** (carry-over from v1): ratify the
  `.stub-allow` mechanism so the 6 recurring deliberate-external targets stop
  showing up in any audit at all.

## Sign-off

Both audits valid. Discrepancy explained: G-3 scans a curated subset and
applies a 4-class taxonomy; H-9 scans the entire vault and applies a 2-class
taxonomy. Under a uniform taxonomy the brain has **78 genuinely-broken edges
across 48 targets**, with the majority in inbox-archive material. No action
required beyond updating G-7's script and adopting a 3-number reporting
convention for future audits.
