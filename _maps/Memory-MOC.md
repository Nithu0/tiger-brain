---
tags: [moc, memory, claude-cognitive-os]
type: moc
created: 2026-05-08
---

# Memory-MOC

How Claude remembers things across sessions, machines, and projects. The cognitive OS treats memory as a layered hierarchy: each layer additive on the one above, scoped tighter as it descends.

## The hierarchy (read order)

1. **Global** — `~/.claude/CLAUDE.md`. Operator baseline that loads on every session, every project, every device. Communication style, safety rules, secret-handling, cross-repo discipline. See [[Global-CLAUDE-md]].
2. **Workspace** — `/home/nithu/code/CLAUDE.md`. Thin meta layer that points to project CLAUDE.md files. No project-specific content.
3. **Project** — `<repo>/CLAUDE.md` (e.g. `ai-assistent/CLAUDE.md`, `Master-oppgave/CLAUDE.md`). Domain context, sprint anchors, project-specific operator-prinsipper.
4. **Per-project memory** — `~/.claude/projects/<slug>/memory/`. Loaded automatically on session start in that project.

The full read-order from highest authority down is the [[Truth-Hierarchy]] (codebase + git → phase-status → operator-decisions → promoted memory → daily memory → raw scratchpads → archived).

## Per-project memory categories

Files in `~/.claude/projects/<slug>/memory/` are categorised by `type:` in their frontmatter:

- **`user`** — operator personality, working patterns, preferences. (e.g. `user_personality.md`, `user-orchestration-style.md`)
- **`feedback`** — corrections operator has given Claude that should not repeat. (e.g. `feedback_concise_communication.md`, `feedback_no_auto_activation.md`)
- **`project`** — current architectural snapshots, activation state. (e.g. `cognitive_os_state.md`, `agentic_team_activation_state.md`)
- **`reference`** — durable inventories Claude consults at session-start. (e.g. `reference_available_tools.md`, `reference_strategy_reviewer.md`)

`MEMORY.md` in that directory is the index: every file gets a one-line entry.

## Lifecycle

Memory entries flow through stages — see [[Memory-Lifecycle]]:

`RAW` (daily distilled) → `DISTILLED` (curated) → `PROMOTED` (durable, in repo) → `DEPRECATED` (kept for history) → `ARCHIVED` (read-only).

The Stop-hook distillation pipeline writes new RAW entries automatically; promotion remains operator-gated.

## Cross-project firewall

Each project gets its own memory dir. **Claude does not pollute one project's memory with another's content.** Cross-project audit lives at `docs/architecture/cross-project-fixes.md` in the Nexus repo.

## Related

[[Tools-MOC]] · [[Decisions-MOC]] · [[Workflows-MOC]] · [[Distillation-Hook]] · [[Session-Start-Hook]]
