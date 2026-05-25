---
title: Skills Registry
folder: 03-skills
created: 2026-05-25
purpose: Reusable Hermes-style skill registry (Tier 3 of three-tier hierarchy); each SKILL.md is invocable by name
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[SKILL_REGISTRY_SPEC]]"
tags: [skills, registry, hermes, tier-3]
---

## Purpose

This folder is the Tier-3 skill registry in the three-tier hierarchy (Tier 1 = orchestrator built-ins; Tier 2 = project agents; Tier 3 = reusable skills). Each skill lives as a single `SKILL.md` file with structured frontmatter describing trigger keywords, inputs, outputs, and invocation contract. Skills are name-invocable — the BrainOrchestrator or any agent can call `<skill-name>` and the contract is honored without further prompting. Auto-generated drafts land in `_proposed/` pending operator review; superseded versions move to `_archived/`; system-injected references (read-only mirrors of CLI-bundled skills) live in `_system/`.

## Subfolders

| Subfolder | Purpose |
|---|---|
| `_proposed/` | Auto-generated skill drafts pending operator review |
| `_archived/` | Superseded skill versions retained for reference |
| `_system/` | Read-only mirrors of system-injected skills (do not edit) |

## Naming convention

`<kebab-case-name>.md` — e.g. `brain-search.md`, `youtube-distill.md`, `task-claim.md`. Name MUST match the invocation token used by orchestrator/agents.

## Frontmatter convention

Required fields per spec (see [[SKILL_REGISTRY_SPEC]]):

- `name` — kebab-case, matches filename
- `version` — semver
- `triggers` — array of keywords/phrases that activate the skill
- `inputs` — schema of expected args
- `outputs` — schema of return contract
- `tier` — always `3`
- `status` — `active` | `proposed` | `archived` | `system`

## Workflow

1. Operator or auto-distiller identifies a reusable capability
2. Draft lands in `_proposed/` with `status: proposed`
3. Operator reviews + promotes to `03-skills/` root with `status: active`
4. Orchestrator/agents invoke by name
5. On replacement: old version moves to `_archived/`; new takes its slot

## Anti-patterns

- One-off scripts (those belong in project repos)
- Skills without a clear trigger contract (vague triggers cause misfires)
- Editing `_system/` files (read-only mirrors)
- Skills that bypass operator gates for irreversible actions

## Related

- [[2026-05-25-brain-upgrade-plan]]
- [[SKILL_REGISTRY_SPEC]]
- [[AGENT_ORCHESTRATION_SPEC]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
