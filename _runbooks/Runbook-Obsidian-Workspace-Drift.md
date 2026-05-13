---
tags: [runbook, obsidian, hygiene]
type: runbook
created: 2026-05-13
---
# Runbook: Obsidian Workspace Drift

## Problem

Obsidian writes to `.obsidian/*.json` files **constantly** as operator interacts with the UI — panning the graph, zooming, toggling themes, switching panes, opening files. If any of those files are git-tracked, the working tree is **always dirty**. `git status` becomes noise, accidental commits include UI churn, and operator wastes attention re-resetting state.

The Brain vault hit this when `.obsidian/graph.json` showed up as modified after every Obsidian session — purely from zoom/pan changes (the `scale` field flipping). No real config drift.

## What to gitignore (UI state — high-frequency churn)

| File | Why ignore |
|---|---|
| `.obsidian/workspace*` | Pane layout, open files, sidebar state. Already ignored. |
| `.obsidian/cache` | Local link/tag cache. Already ignored. |
| `.obsidian/graph.json` | Graph View pan/zoom/scale. `colorGroups` is config but empty in this vault — if operator ever sets color groups they care about, revisit. |
| `.obsidian/app.json` | Local app preferences (font size, default view mode). Per-machine. |
| `.obsidian/appearance.json` | Theme, accent color. Per-machine taste. |

## What to keep tracked (shared config — low churn, high value)

| File | Why keep |
|---|---|
| `.obsidian/core-plugins.json` | Which core plugins are enabled. Worth syncing across machines/teammates. |
| `.obsidian/community-plugins.json` | Plugin list. Same logic — share so machines stay aligned. |
| `.obsidian/hotkeys.json` | Keyboard shortcuts. Operator preference, but stable; share unless it becomes painful. |
| `.obsidian/plugins/<name>/data.json` | Per-plugin config. Case-by-case — most are stable. |
| `.obsidian/snippets/` (if present) | Operator CSS. Definitely share. |

## Standard procedure: a new file starts polluting `git status`

When a previously-quiet `.obsidian/*.json` starts showing up in `git status` after every Obsidian session, and the diff is pure UI state (cursor position, scroll, zoom, last-active-pane):

```bash
cd /home/nithu/Obsidian/Brain
echo ".obsidian/<filename>" >> .gitignore
git rm --cached ".obsidian/<filename>"
git commit -m "chore(obsidian): gitignore <filename> (UI state)"
```

Verify with `git status` — file should no longer appear as modified.

## Recovery

If operator accidentally deletes a tracked `.obsidian/*.json` they care about — **before** the deletion is committed:

```bash
git checkout HEAD -- .obsidian/<filename>
```

If the file was ignored and operator wants it tracked again:

```bash
# remove the gitignore line first, then:
git add -f .obsidian/<filename>
```

## Decision rule

Ignore if: file changes on every Obsidian session without operator deliberately editing it.
Track if: file represents a deliberate configuration choice that benefits from being shared.

If unsure: leave tracked, observe `git status` for a week, decide.
