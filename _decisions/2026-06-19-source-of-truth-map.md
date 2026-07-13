---
title: Source-of-truth map — one authority per knowledge type
type: decision
date: 2026-06-19
status: active
author: code-2 (ops)
supersedes: []
related:
  - "[[../../code/command-center/docs/ops/MEMORY-OS-AUDIT.md]]"
  - "[[2026-06-19-source-of-truth-map]]"
tags: [decision, memory, source-of-truth, cleanup, consolidation]
---

# Source-of-truth map

Consolidation note from the memory-system audit (`command-center/docs/ops/MEMORY-OS-AUDIT.md`
§5 + §13). Problem being fixed: the *same* knowledge lives in Obsidian + memory.db +
`~/.claude` memory + repo CLAUDE.md + CURRENT-STATE, with no clear authority — fragmentation,
not lack of structure. This note declares the single authoritative source per knowledge type.
Everything else is a mirror/snapshot of the authority, not a competing copy.

## Authoritative source per knowledge type

| Knowledge type | Authoritative source | Everything else is |
|---|---|---|
| Raw session history | `memory.db` verbatim | — (the record) |
| Distilled facts / learnings | `memory.db` memory_objects | mirrored to Obsidian on-demand |
| Project status NOW | `<project>/project_state.md` | CURRENT-STATE.md = git snapshot only |
| Decisions log | `Brain/_decisions/` (+ DB `decisions_json`) | keep ONE, link the other |
| Operator / firm rules (stable) | `~/.claude/CLAUDE.md` + `00-firm-bus/CHARTER.md` + repo `CLAUDE.md` | — |
| Human notes / runbooks | Obsidian (`_runbooks/`, domain folders) | — |
| Weekly health/drift | `Brain/_reviews/weekly/2026-Wxx.md` | — |
| Cost log | `Brain/_costlog/2026-MM.md` (new, per audit §5) | — |

**Rules of thumb:**
- CLAUDE.md holds *stable rules*, never sprint/slice status. The cc-CLAUDE.md "Slices 1-13 /
  Slice 14 not started" footer was stale — corrected 2026-06-19 to point at `project_state.md`
  for live status.
- For "what's the current state of X" → read `<project>/project_state.md`, not CLAUDE.md, not
  CURRENT-STATE (which is only a git snapshot).
- For "did we already decide X" → search `_decisions/` first; if it's only in DB, mirror a note.
- A decision and its later realization (shipped code) should not both claim to be "the plan" —
  once shipped, the proposal note is superseded (see flag list below).

## Superseded decision-notes (FLAGGED, not moved — archiving is operator-gated)

These older `_decisions/` notes are now superseded by shipped reality. Listed for the operator
to move to `90-archive/` later; do NOT delete or move without operator approval.

- `2026-05-14-control-plane-proposal.md` — status: proposal. Superseded: command-center is built
  (Slices 1-13 code-complete). The proposal is now history; live status → `command-center/project_state.md`.
- `2026-05-14-16-pane-codex-parallell.md` — status: proposal. Superseded: firm-launcher shipped
  (8-pane WT split + variants in `command-center/_bin/`); the 16-pane Codex proposal was not the
  path taken.
- `2026-05-14-job-scrape-feasibility.md` — status: draft for operator review. Superseded by the
  soking-fulltid pipeline direction (draft-only, human submits); keep as feasibility background.
- `2026-05-14-nav-feed-verification.md` — status: verified. Point-in-time verification; fold into
  the soking-fulltid `project_state.md` when that file is created (audit task #5).

Notes deliberately NOT flagged (still authoritative as stable rules / ADRs):
`ADR-003-cross-machine-sync.md`, `ADR-004-slice-14-control-plane-split.md`,
`Operator-Principles.md`, `2026-05-25-operator-gate-naming.md`,
`2026-06-03_activation-judge-stance.md`, and all `When-*.md` decision-trees.
