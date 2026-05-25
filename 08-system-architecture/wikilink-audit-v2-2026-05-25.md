---
title: Wikilink Audit v2 — 2026-05-25
date: 2026-05-25
status: v2 (post-D4/D8/D10/F10 stub-resolution)
purpose: Measure delta vs C-10's v1 audit (648 R / 38 S / 1 B)
related: ["[[wikilink-audit-2026-05-25]]", "[[2026-05-25-brain-upgrade-plan]]"]
tags: [audit, wikilinks, v2, delta]
---

# Wikilink Audit v2 — delta from v1

## Summary

Re-ran C-10's methodology (`grep -rno '\[\[[^]]*\]\]'` across the same scope, plus the new files created by D-4 / D-8 / D-10 / F-10), then categorized each occurrence as RESOLVED, STUB, BROKEN, or PLACEHOLDER (template-placeholder skipped exactly as in v1).

- **Scan scope (v2)**: same 7 original specs + 4 new stub specs from D-8 (`LICENSE_GUARD_SPEC`, `MEMORY_OBJECT_SPEC`, `RETROSPECTIVE_SPEC`, plus pre-existing `OBSIDIAN_BRAIN_STRUCTURE` etc.); `2026-05-25-brain-upgrade-plan.md`; `INTEGRATION_NOTES_v1.1.md`; all 54 files in `_maps/` (now includes 6 new MOCs from D-4 + Packages-MOC from F-10); 5 SKILL files; 3 pilot tasks + `HOW-TO-CREATE-TASK.md` from D-10; 6 READMEs; 8 templates; `09-retrospectives/2026-W22.md`; `HOW-TO-DROP-URL.md`; `HOW-TO-DROP-SEARCH.md`.
- **Total wikilink occurrences (v2)**: 933 (v1: 743 → +190)
  - **Counted (real links)**: 833 (v1: 687 → +146)
  - **Skipped (template placeholders inside code blocks / schemas)**: 100 (v1: 56 → +44) — includes the single bash `[[ -d "$WT_PATH" ]]` construct in `AGENT_ORCHESTRATION_SPEC.md:475`, classified as placeholder per v1 convention.
- **RESOLVED**: 803 (v1: 648 → **+155**)
- **STUB** (documented as forthcoming / external): 30 (v1: 38 → **−8**)
- **BROKEN** (action required): 0 (v1: 1 → **−1**)

Counts add up: 803 + 30 + 0 = 833 counted; +100 placeholders = 933 total.

### Delta vs v1

| Bucket | v1 | v2 | Δ |
|---|---:|---:|---:|
| RESOLVED occurrences | 648 | 803 | **+155** |
| STUB occurrences | 38 | 30 | **−8** |
| BROKEN occurrences | 1 | 0 | **−1** |
| Unique RESOLVED targets | 86 | 106 | +20 |
| Unique STUB targets | 16 | 8 | **−8** |
| Unique BROKEN targets | 1 | 0 | **−1** |
| Counted total | 687 | 833 | +146 |
| Health (RESOLVED / counted) | 94.3% | **96.4%** | +2.1pp |

The growth in total occurrences (+190) is dominated by new content (D-4 enriched MOCs each have ~30-60 wikilinks; D-8 stub specs each add 5-10; D-10 howtos add ~5; F-10 Packages-MOC adds ~40). Resolved-count growth (+155) exceeds total-counted growth (+146), so net brain health is up.

## Resolved stubs (STUB in v1, now RESOLVED in v2)

| Wikilink | Resolved by | Real file path | v1 occurrences |
|---|---|---|---:|
| `[[Retrospectives-MOC]]` | D-4 | `_maps/Retrospectives-MOC.md` | 5 |
| `[[Youtube-MOC]]` | D-4 | `_maps/Youtube-MOC.md` | 4 |
| `[[Github-Repos-MOC]]` | D-4 | `_maps/Github-Repos-MOC.md` | 4 |
| `[[LICENSE_GUARD_SPEC]]` | D-8 | `08-system-architecture/specs/LICENSE_GUARD_SPEC.md` | 1 |
| `[[MEMORY_OBJECT_SPEC]]` | D-8 | `08-system-architecture/specs/MEMORY_OBJECT_SPEC.md` | 1 |
| `[[RETROSPECTIVE_SPEC]]` | D-8 | `08-system-architecture/specs/RETROSPECTIVE_SPEC.md` | 2 |

`[[Operator-Principles]]` (D-8) was already RESOLVED in v1 (an existing copy lived under `01-nexus/operations/`); D-8's addition at `_decisions/Operator-Principles.md` and `_maps/Operator-Principles.md` is additive and does not change the audit verdict, but it removes the v1 "MEDIUM" risk noted in `INTEGRATION_NOTES_v1.1.md` B.3.

`[[Memory-MOC]]` and `[[RAG-MOC]]` (also flagged in the task brief as D-4 deliverables) were already RESOLVED in v1 — they appear in v1's RESOLVED examples list. D-4 expanded them substantially but did not resolve any new stubs for these two targets.

The three D-10 howtos (`HOW-TO-DROP-URL`, `HOW-TO-DROP-SEARCH`, `HOW-TO-CREATE-TASK`) exist on disk but currently have **zero inbound wikilinks** in the scanned scope — they are discoverable via folder navigation only. No delta in the audit. (Recommend: add a `[[HOW-TO-DROP-URL]]` link from `12-youtube/README.md` and equivalents in the next sprint so the howtos become first-class graph nodes.)

The F-10 `[[Packages-MOC]]` exists at `_maps/Packages-MOC.md` and is referenced 3× from within itself (self-links), but otherwise has zero inbound links from the scanned scope. Same recommendation: link from `System-Architecture-MOC.md` and/or `08-system-architecture/` README.

## Fixed BROKEN link

| v1 BROKEN | v2 status | Fix |
|---|---|---|
| `[[memory-distillation-spec]]` (typo at `specs/SKILL_REGISTRY_SPEC.md:196`) | RESOLVED | Line 196 now reads `[[MEMORY_DISTILLATION_SPEC]]` (uppercase). Verified by re-reading source. |

## Remaining stubs (still STUB in v2)

All 30 remaining stub occurrences are **deliberate** and documented in `INTEGRATION_NOTES_v1.1.md` sections B.4, B.5, B.7, plus two known fenced-code examples. Same 8 unique targets, all carried over from v1:

| Wikilink | v2 occurrences | Reason / disposition |
|---|---:|---|
| `[[CLAUDE.md]]` | 6 | NIT B.5 — external (`~/.claude/CLAUDE.md` and per-repo); `.stub-allow` planned per NIT 23. |
| `[[2603.13017v1]]` | 9 | NIT B.4 — PDF at `/home/nithu/code/2603.13017v1.pdf`; `.stub-allow` or `_library/papers/` stub planned. (4 new in v2, introduced by `_maps/Memory-MOC.md` and `_maps/RAG-MOC.md` enrichment in D-4.) |
| `[[reference_available_tools]]` | 5 | NIT B.7 — lives in `~/.claude/projects/-home-nithu-code/memory/`; `.stub-allow` planned. |
| `[[command-center]]` | 5 | Project-pointer; lives at `/home/nithu/code/command-center/`, not a brain note. (3 of these are new in v2, introduced by `_maps/Packages-MOC.md` from F-10.) |
| `[[handoffs/]]` | 2 | Folder reference (not a note); Obsidian will not resolve folder-targets. (1 new in v2 from `_maps/Retrospectives-MOC.md` D-4.) |
| `[[_decisions/2026-05-25-brain-upgrade]]` | 1 | Forthcoming decision file; existing nearest match is `08-system-architecture/2026-05-25-brain-upgrade-plan.md` (plan, not decision). |
| `[[katastrofedag-analyse-2026-05-12]]` | 1 | Inside fenced code block in `_maps/wikilink-validation-2026-05-13.md:132` — documented external-repo example, not a real link. |
| `[[reference_autopush]]` | 1 | Inside fenced code block in `_maps/wikilink-validation-2026-05-13.md:135` — documented memory-ref example, not a real link. |

**Unique stub count: 8 (down from 16 in v1).** All 8 remaining are recurring "documented-external" references awaiting the `.stub-allow` decision per `INTEGRATION_NOTES_v1.1.md` NIT 23. No spontaneous content-stubs exist.

## NEW broken links (introduced by phase 4-6 content)

**None.** The new D-4/D-8/D-10/F-10 files introduced 147 new counted wikilinks; all resolved except for 4 occurrences that re-cited existing-stub targets (`[[2603.13017v1]]` in `_maps/Memory-MOC.md` and `_maps/RAG-MOC.md`; `[[command-center]]` and `[[handoffs/]]` in new MOCs).

## NEW stubs (acceptable forward-references)

**None unique.** The 4 new occurrences flagged above re-cite the existing 8-stub vocabulary already tracked in `INTEGRATION_NOTES_v1.1.md`. No new stub target was introduced by phases 4-6.

## Methodology notes (for reproducibility)

1. **Grep**: `grep -rno '\[\[[^]]*\]\]'` over the file list in "Scan scope" above, captured to `/tmp/wl_v2_raw.txt` (933 lines).
2. **File index**: `find /home/nithu/Obsidian/Brain -name "*.md"` → 585 files. Built a set of basenames and a set of stripped paths.
3. **Classification** (per occurrence):
   - **PLACEHOLDER** (skipped, exactly as v1): regex match against `^<…>`, `^STUB:`, `^T-…`, `^Note$`, `^example$`, `^Future-Note`, `^target$`, `^TARGET`, `^your-note`, `^question-N`, `^ADR-…`, `^YYYY-`, fenced-code constructs `[[ -d "$WT_PATH" ]]`, etc. (66 unique placeholder targets, 99 occurrences.)
   - **RESOLVED**: target (after stripping `|alias`) matches a file basename or full subdir-path under brain.
   - **STUB**: target matches the 8 known deliberate-external/forthcoming targets above, OR target ends in `.md` (external `CLAUDE.md` pattern).
   - **BROKEN**: anything else. **Result: 0.**
4. **Cross-check**: every former v1 STUB target was re-resolved against the v2 file index; D-4/D-8 deliverables confirmed present at expected paths.
5. **Reproduction recipe**: re-run the grep above, run the categorizer (preserved inline in the audit shell history at `/tmp/wl_v2_raw.txt`), and `find … -iname "<target>.md"` to verify.

## Recommendations

1. **STUB cleanup (carry-over from v1)**: ratify the `.stub-allow` decision per `INTEGRATION_NOTES_v1.1.md` NIT 23 for the 8 recurring stubs (`CLAUDE.md`, `2603.13017v1`, `reference_available_tools`, `command-center`, `handoffs/`, `_decisions/2026-05-25-brain-upgrade`, `katastrofedag-analyse-2026-05-12`, `reference_autopush`). Either commit a `.stub-allow` at brain root OR write 1-line placeholder `.md` stubs. Operator-gated.
2. **Wire the orphaned new content**: `[[HOW-TO-DROP-URL]]`, `[[HOW-TO-DROP-SEARCH]]`, `[[HOW-TO-CREATE-TASK]]`, and `[[Packages-MOC]]` exist on disk but have zero inbound links. Add 1-line backlinks from `12-youtube/README.md`, `13-github-repos/README.md`, `10-tasks/README.md`, and `System-Architecture-MOC.md` in the next sprint so they become first-class graph nodes. Non-urgent.
3. **No BROKEN links exist.** Brain wikilink integrity is 96.4% RESOLVED (833 counted), with the remaining 3.6% (30 occurrences / 8 unique targets) all documented stubs. Up from 94.3% in v1.
4. **Next audit cadence**: weekly per `Runbook-Brain-Upgrade-Workflow.md` (or after the next major content push, whichever lands first).

## Sign-off

**Status: CLEAN.** Zero BROKEN links. All remaining stubs are documented deliberate-external references awaiting the `.stub-allow` decision. v1's lone typo (`memory-distillation-spec` → `MEMORY_DISTILLATION_SPEC`) is fixed in source. Phase 4-6 content (D-4 5 MOCs, D-8 4 stubs, D-10 3 howtos, F-10 Packages-MOC) introduced **no new broken or unmapped stubs**.

Delta summary: **−8 unique stubs, −1 BROKEN, +155 RESOLVED occurrences**, brain health up from 94.3% to 96.4%.
