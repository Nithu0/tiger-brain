---
title: Wikilink Audit 2026-05-25
date: 2026-05-25
status: v1.0
purpose: Verify cross-spec wikilink integrity after fase 1+2+3
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[INTEGRATION_NOTES_v1.1]]"
tags: [audit, wikilinks, meta]
---

# Wikilink Audit — 2026-05-25

## Summary

- **Scan scope**: 7 specs (`08-system-architecture/specs/*.md`), `2026-05-25-brain-upgrade-plan.md`, `INTEGRATION_NOTES_v1.1.md`, 3 new MOCs (`_maps/*-MOC.md`, all 51 `_maps/` files scanned), 5 SKILL files (`03-skills/*.md`), 3 pilot tasks (`10-tasks/_open/*.md`), 6 READMEs (`03-skills/`, `09-retrospectives/`, `10-tasks/`, `00-templates/`, `12-youtube/`, `13-github-repos/`), 8 templates (`00-templates/*.md`), and `09-retrospectives/2026-W22.md`.
- **Total wikilink occurrences**: 743
  - **Counted (real links)**: 687
  - **Skipped (template placeholders inside code blocks / schemas)**: 56 (e.g. `[[<MOC>]]`, `[[Note-Name]]`, `[[T-...]]`, `[[example]]`, `[[ -d "$WT_PATH" ]]`)
- **RESOLVED**: 648
- **STUB** (documented as forthcoming / external): 38
- **BROKEN** (action required): 1

Counts add up: 648 + 38 + 1 = 687 counted; +56 templates = 743 total.

## RESOLVED (648 occurrences, 86 unique targets)

All targets resolve to existing `.md` files under `/home/nithu/Obsidian/Brain/`. Examples by category:

- **Specs** (sibling): `AGENT_ORCHESTRATION_SPEC`, `MEMORY_DISTILLATION_SPEC`, `RAG_ENGINE_SPEC`, `OBSIDIAN_BRAIN_STRUCTURE`, `YOUTUBE_INGESTION_SPEC`, `GITHUB_DISCOVERY_SPEC`, `SKILL_REGISTRY_SPEC`, `2026-05-25-brain-upgrade-plan`, `INTEGRATION_NOTES_v1.1`, `2026-05-24-onprem-ai-strategi`.
- **MOCs** in `_maps/`: `Skills-MOC`, `System-Architecture-MOC`, `Tasks-MOC`, `Memory-MOC`, `Decisions-MOC`, `Tools-MOC`, `Workflows-MOC`, `People-MOC`, `Business-MOC`, `Career-MOC`, `Learning-MOC`, `Nexus-MOC`, `Thesis-MOC`.
- **Decisions/People** in `_maps/`: `Karri`, `Operator-Nithu`, `Claude`, `Codex`, `Gemini`, `Truth-Hierarchy`, `Foundation-Gate`, `OK-Kjor-Autonomous-Execute`, `OK-Kjor-Gate`, `Operator-Principles`, `Decision-No-Auto-Activation`, etc.
- **Skills** in `03-skills/`: `brain-distill-daily`, `youtube-ingest`, `github-discover`, `multi-agent-dispatch`, `worktree-spawn-cleanup`, `git-worktree-workflow`.
- **Tasks** in `10-tasks/_open/`: `T-2026-05-25-001-rag-semantic-chunker` (via close-match resolved), `T-2026-05-25-002-skill-registry-discovery`, `T-2026-05-25-003-youtube-ytdlp-wrapper`.
- **Templates** in `00-templates/`: `retrospective`, `task`, `skill`, `youtube-note`, `github-repo-note`, `memory-object`, `atomic`, `moc`.
- **Decisions** in `_decisions/`: `When-Agent-Stalls`, `When-Brain-Structure-Drifts`, `When-Doc-Drifts-From-Code`, `When-Foundation-Rule-Goes-Yellow`, `When-Gate-Goes-Silent`, `When-Operator-Says-Kjor-Pa`, `When-Quota-Blocks-Pipeline`, `When-Strategy-Change-Tempting`, `When-Trade-Bleeds-Multi-Day`.
- **Runbooks** in `_runbooks/`: `Runbook-Multi-Agent-Dispatch`, `Runbook-Brain-Weekly-Maintenance`, `Runbook-Push-Cycle`, etc.

Full per-link table omitted (648 rows). Re-run `grep -rn '\[\[' …` and cross-check against `find … -iname "<target>.md"` to reproduce.

## STUB (38 occurrences, 16 unique targets)

These are documented as deliberate stubs in `INTEGRATION_NOTES_v1.1.md` (sections B.2, B.4, B.5, B.7, NIT 15-16, 23) or are forthcoming forward-references; not action-required for fase 1+2+3.

| Link | Source file:line(s) | Reason / disposition |
|---|---|---|
| `[[CLAUDE.md]]` | `08-system-architecture/INTEGRATION_NOTES_v1.1.md:162,163,427` ; `specs/MEMORY_DISTILLATION_SPEC.md:614,696` | NIT B.5 — external (`~/.claude/CLAUDE.md`), `.stub-allow` planned per NIT 23. |
| `[[2603.13017v1]]` | `INTEGRATION_NOTES_v1.1.md:157,427` ; `specs/MEMORY_DISTILLATION_SPEC.md:694` ; `specs/RAG_ENGINE_SPEC.md:38,841` | NIT B.4 — PDF at `/home/nithu/code/2603.13017v1.pdf`, `.stub-allow` planned. |
| `[[reference_available_tools]]` | `INTEGRATION_NOTES_v1.1.md:172,427` ; `specs/SKILL_REGISTRY_SPEC.md:582` | NIT B.7 — lives in `~/.claude/projects/-home-nithu-code/memory/`, `.stub-allow` planned. |
| `[[command-center]]` | `2026-05-25-brain-upgrade-plan.md:6` ; `_maps/System-Architecture-MOC.md:50` (line `89` is also command-center but resolves elsewhere — see note) | Project-pointer; lives at `/home/nithu/code/command-center/`, not a brain note. |
| `[[Retrospectives-MOC]]` | `INTEGRATION_NOTES_v1.1.md:149` ; `specs/OBSIDIAN_BRAIN_STRUCTURE.md:304,436,645,914` | B.2 — explicit "optional / when first note lands" stub. |
| `[[Youtube-MOC]]` | `INTEGRATION_NOTES_v1.1.md:149` ; `specs/OBSIDIAN_BRAIN_STRUCTURE.md:438,645,914` | B.2 — explicit "optional / when first note lands" stub. |
| `[[Github-Repos-MOC]]` | `INTEGRATION_NOTES_v1.1.md:149` ; `specs/OBSIDIAN_BRAIN_STRUCTURE.md:439,645,914` | B.2 — explicit "optional / when first note lands" stub. |
| `[[LICENSE_GUARD_SPEC]]` | `13-github-repos/README.md:62` | Forthcoming spec referenced in README footer. |
| `[[MEMORY_OBJECT_SPEC]]` | `12-youtube/README.md:61` | Forthcoming spec referenced in README footer. |
| `[[RETROSPECTIVE_SPEC]]` | `09-retrospectives/README.md:9,82` | Forthcoming spec referenced in README footer + frontmatter. |
| `[[_decisions/2026-05-25-brain-upgrade]]` | `specs/SKILL_REGISTRY_SPEC.md:198` | Forthcoming decision file; existing nearest match is `08-system-architecture/2026-05-25-brain-upgrade-plan.md` (plan, not decision). |
| `[[katastrofedag-analyse-2026-05-12]]` | `_maps/wikilink-validation-2026-05-13.md:132` | Inside a fenced code block as a documented EXAMPLE of an external-repo wikilink (not a real link). |
| `[[reference_autopush]]` | `_maps/wikilink-validation-2026-05-13.md:135` | Inside a fenced code block as a documented EXAMPLE of a memory-ref wikilink (not a real link). |
| `[[09-retrospectives/YYYY-W(NN-1)]]` | `specs/OBSIDIAN_BRAIN_STRUCTURE.md:300` | Template-placeholder inside a frontmatter schema example. |
| `[[10-tasks/_open/T-YYYY-MM-DD-NNN]]` | `specs/YOUTUBE_INGESTION_SPEC.md:182` | Template-placeholder inside a related-links schema example. |
| `[[handoffs/]]` | `_maps/Tasks-MOC.md:53` | Folder reference (not a note); Obsidian will not resolve folder-targets. |

## BROKEN (1) — action required

| Link | Source file:line | Suggested target | Suggested action |
|---|---|---|---|
| `[[memory-distillation-spec]]` | `08-system-architecture/specs/SKILL_REGISTRY_SPEC.md:196` | `[[MEMORY_DISTILLATION_SPEC]]` (file at `specs/MEMORY_DISTILLATION_SPEC.md`) | Fix link — change kebab-case → SCREAMING_SNAKE to match actual filename. Note: same spec is correctly linked as `[[MEMORY_DISTILLATION_SPEC]]` on line 569 of the same file, so this is a single typo. |

## Recommendations

Wikilink health is **excellent** after fase 1+2+3 work: 94.3% of counted links (648/687) resolve directly, 5.5% are documented stubs (38/687) tracked in `INTEGRATION_NOTES_v1.1.md`, and only **one** unintended typo remains (`memory-distillation-spec` → `MEMORY_DISTILLATION_SPEC` in `SKILL_REGISTRY_SPEC.md:196`). The stub set is dominated by three categories: (a) the three deliberate-external references (`CLAUDE.md`, `2603.13017v1`, `reference_available_tools`) awaiting the `.stub-allow` decision per NIT 23; (b) the three "optional MOC" stubs (`Retrospectives-MOC`, `Youtube-MOC`, `Github-Repos-MOC`) scheduled for creation when their respective folders receive first content; and (c) three forthcoming specs (`LICENSE_GUARD_SPEC`, `MEMORY_OBJECT_SPEC`, `RETROSPECTIVE_SPEC`) cited in section-12/13 READMEs.

The most useful follow-ups for v1.2 are (1) fix the lone broken link, (2) decide between `.stub-allow` vs creating 1-line placeholder `.md` files for the six recurring stubs that pollute Obsidian's dead-link panel, and (3) consider whether `[[_decisions/2026-05-25-brain-upgrade]]` in `SKILL_REGISTRY_SPEC.md:198` should re-point to the existing plan file or whether the decision file is actually planned to land. No structural issues observed; the new infrastructure (specs, MOCs, skills, tasks, templates, READMEs) is internally consistent.
