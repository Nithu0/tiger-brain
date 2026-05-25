---
title: Note Templates
folder: 00-templates
created: 2026-05-25
purpose: Stable templates for note-types; used by firm-task-claim.sh + manual operator-creation
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[OBSIDIAN_BRAIN_STRUCTURE]]"
tags: [templates, scaffolds, conventions]
---

## Purpose

This folder holds the stable templates for every note-type in the brain. Each template is a minimal scaffold — required frontmatter + section headers + `<!-- fill me -->` markers. Templates are copied (not symlinked) into target folders so that downstream edits never accidentally mutate the canonical scaffold. Used by `firm-task-claim.sh` when creating a new task from a template, by the BrainOrchestrator when generating drafts, and by the operator for manual note creation.

## Subfolders

None — flat folder by design.

## Naming convention

`<note-type>.md` — singular, lowercase, no prefix. E.g. `atomic.md`, `task.md`, `skill.md`.

## Frontmatter convention

Each template embeds the frontmatter scaffold for its target note-type — see the destination folder's README for the canonical contract. Template frontmatter fields use `<!-- fill me -->` markers where operator-input is required.

## Workflow

1. New note-type needed → operator writes template here
2. Scripts (`firm-task-claim.sh`, etc.) read template, substitute values, write to destination
3. Operator may copy manually: `cp 00-templates/atomic.md <destination>/<slug>.md` then fill markers
4. Template updates affect FUTURE notes only — existing notes untouched

## Anti-patterns

- Editing a copy of a template in this folder (defeats canonical purpose)
- Templates with project-specific values (templates are generic)
- Templates without `<!-- fill me -->` markers (operator/script has no signal where to act)
- Symlinking templates into target folders (mutation risk)

## Related

- [[2026-05-25-brain-upgrade-plan]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
- [[SKILL_REGISTRY_SPEC]]
- [[AGENT_ORCHESTRATION_SPEC]]
