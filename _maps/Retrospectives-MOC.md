---
title: Retrospectives-MOC
type: moc
created: 2026-05-25
purpose: Index of the 09-retrospectives/ folder + weekly roll-up cadence (ISO week, 10-section schema, orchestrator-triggered)
related: [[2026-05-25-brain-upgrade-plan]]
tags: [moc, retrospectives, weekly, roll-up, brain-upgrade]
---

# Retrospectives-MOC

Curated index of `09-retrospectives/` — the weekly roll-up system. Each retrospective is one `.md` file per ISO week (`YYYY-WNN.md`) following a 10-section schema. The BrainOrchestrator triggers a draft retrospective every **Sunday 22:00 local** (per [[AGENT_ORCHESTRATION_SPEC]] §8.1 weekly cadence); operator reviews, edits, and seals. Retrospectives are the durable successor to the daily `handoffs/` notes — handoffs are state-passing across sessions; retrospectives are reflective roll-ups of an entire week. This MOC points only — binding truth lives in the folder README + the forthcoming spec.

## Folder

- [[09-retrospectives/README]] — folder conventions, naming (`YYYY-WNN.md`, ISO-week), the binding **10-section schema** (Highlights / Lowlights / Decisions / Architectural changes / Tasks completed / Tasks blocked / Open questions / Learning / Next-week focus / Metrics), and the forthcoming [[RETROSPECTIVE_SPEC]] (stub at README:9 + README:82).

## Template

- [[00-templates/retrospective]] — boilerplate frontmatter + 10-section skeleton. Used by the orchestrator's draft-generation step and by hand-authored entries.

## Current

- [[2026-W22]] — first retrospective in the system (week of 2026-05-25, **in-progress**). Will be sealed Sunday 2026-05-31 22:00 once the orchestrator's draft + operator review pass.

## Cadence

Per [[AGENT_ORCHESTRATION_SPEC]] §8.1 (weekly trigger row):

| Trigger | When | What |
|---|---|---|
| Weekly draft | Sun 22:00 local | BrainOrchestrator scans the week's `audit_log` + `_done/` tasks + `handoffs/` + distilled MemoryObjects → fills the 10-section template → writes `09-retrospectives/YYYY-WNN.md` as a draft. |
| Operator review | Sun/Mon | Operator edits draft, promotes "Decisions" entries into `_decisions/`, files follow-ups as tasks in `10-tasks/_open/`. |
| Seal | After review | Frontmatter `status: sealed`; file becomes read-only convention. |

ISO-week numbering rationale: aligns with `git log --date=format:%G-W%V` and most CI dashboards; avoids ambiguous month-boundary roll-ups.

## Roll-up sources

What the orchestrator-generated draft pulls from (per [[AGENT_ORCHESTRATION_SPEC]] §8.1 + [[MEMORY_DISTILLATION_SPEC]] §5):

- `audit_log` rows from the verbatim memory layer (per-action records over the past 7 days).
- `10-tasks/_done/` entries with `closed_at` in the past 7 days.
- `10-tasks/_blocked/` entries with `blocker` set during the past 7 days.
- `handoffs/` notes from the past 7 days (replaced by retrospective once the week seals).
- Distilled MemoryObjects with `kind: decision` over the past 7 days.

## Related

- [[Tasks-MOC]] — task `_done/` is one of the primary input streams to the weekly roll-up.
- [[handoffs/]] — predecessor format; daily state-passing, supplanted at week-end by the retrospective.
- [[2026-05-25-brain-upgrade-plan]] §2.C — Module C (folder taxonomy) is where `09-retrospectives/` was scaffolded.
- [[System-Architecture-MOC]] — parent context.
- [[Memory-MOC]] — distilled `decision` MemoryObjects are pulled into the "Decisions" section of each retrospective.
- [[Decisions-MOC]] — promoted decisions from retrospectives flow into `_decisions/`.
- [[AGENT_ORCHESTRATION_SPEC]] §8.1 — the binding weekly-trigger row.
- [[00-templates/retrospective]] — the schema source.
- [[OBSIDIAN_BRAIN_STRUCTURE]] §10 — folder placement + frontmatter contract.
- [[RETROSPECTIVE_SPEC]] — **stub** — forthcoming binding spec promoted from [[09-retrospectives/README]] §9/§82.

## Open questions

- **Stub** — [[RETROSPECTIVE_SPEC]] needs to land before the second retrospective (target W23) so the schema is binding rather than convention.
- **Stub** — monthly + quarterly roll-up cadences: do these auto-generate from sealed weekly retrospectives, or remain hand-authored? Defaults to hand-authored per [[Operator-Principles]] (no auto-promotion of strategic content).
- **Stub** — retention: weekly retrospectives are durable; should they live indefinitely under `09-retrospectives/` or auto-archive to `90-archive/retrospectives/<YYYY>/` after one year? Mirror the inbox retention pattern.
- **Stub** — orchestrator behaviour when the operator misses a review (draft sits unsealed for >7 days) — escalate via firm-bus feed, or auto-seal with `status: auto-sealed` marker?

---

*This MOC will harden as the spec promotes from README to standalone. Folder README is the current binding convention until then.*
