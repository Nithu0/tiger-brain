---
tags: [meta, operator, commit-prep]
type: recommendation
created: 2026-05-13
status: pending-operator-review
---

# Operator-mods recommendation — 2026-05-13

Read-only analysis of 31 unstaged modifications in `/home/nithu/Obsidian/Brain/` on branch `feat/brain-hardening`. No files touched, nothing staged, nothing committed.

## Summary

- **31 files modified, +137 / -10 lines total** (per `git diff --stat`).
- **30 files are content-additive** — pure link densification: new `[[wikilinks]]` to decision-trees, runbooks, living-state mirrors; small backfill sections in the MOCs ("Last big session" pointers, "Decision-trees" / "Runbooks" indexes). One date bump in `00-DASHBOARD.md`.
- **1 file is workspace state** — `.obsidian/graph.json` (only the `scale` field changed: `0.6666... → 1.0534...`, i.e. graph-view zoom level). Should not be tracked.
- **0 ambiguous files**. Intent is uniform and matches the 2026-05-11 cognitive-OS scaffolding session described in `Decisions-MOC` and `Memory-MOC`.
- **Recommendation: commit the 30 content files in a single commit; untrack + gitignore `.obsidian/graph.json`.**

## Recommended action per file

| File | Category | Recommendation | Reason |
|---|---|---|---|
| `.obsidian/graph.json` | Workspace state | **Do NOT commit; untrack + gitignore** | Only `scale` (zoom) changed; pure UI state |
| `00-DASHBOARD.md` | Content-additive | Commit | New "Health & ops" section, date bump 05-11 → 05-13, sanity.sh pointer |
| `01-nexus/Nexus-MOC.md` | Content-additive | Commit | "Brain (decision trees + runbooks)" backfill block (+15 lines of `[[wikilinks]]`) |
| `01-nexus/modules/Module-Agent-Bus.md` | Content-additive | Commit | Adds links to codex/gemini/local-mirror living-state + Karri |
| `01-nexus/modules/Module-Blackboard.md` | Content-additive | Commit | +2 link lines |
| `01-nexus/modules/Module-Exposure-And-Shield.md` | Content-additive | Commit | +2 link lines |
| `01-nexus/modules/Module-Fact-And-Analysis-Agents.md` | Content-additive | Commit | +2 link lines |
| `01-nexus/modules/Module-Notifications.md` | Content-additive | Commit | +2 link lines |
| `01-nexus/modules/Module-ORB.md` | Content-additive | Commit | Adds Operator-Principles + Strategy-Proposal-Workflow links |
| `01-nexus/modules/Module-Orchestrator.md` | Content-additive | Commit | +2 link lines |
| `01-nexus/modules/Module-Position-Management.md` | Content-additive | Commit | +3 link lines |
| `01-nexus/modules/Module-Postmortem.md` | Content-additive | Commit | +3 link lines |
| `01-nexus/modules/Module-Reconciliation.md` | Content-additive | Commit | +3 link lines |
| `01-nexus/operations/Demo-Mode.md` | Content-additive | Commit | +2 link lines |
| `01-nexus/operations/Foundation-Gate.md` | Content-additive | Commit | Links to Truth-Hierarchy, decision-tree, Karri, living-state |
| `01-nexus/operations/Karri.md` | Content-additive | Commit | Links to Foundation-Gate, Runbook, decision-tree, Truth-Hierarchy |
| `01-nexus/operations/OK-Kjor-Gate.md` | Content-additive | Commit | +2 link lines |
| `01-nexus/operations/Operator-Principles.md` | Content-additive | Commit | +4 link lines |
| `01-nexus/operations/Position-Management-Operations.md` | Content-additive | Commit | +4 link lines |
| `01-nexus/operations/Reconciliation.md` | Content-additive | Commit | +2 link lines |
| `01-nexus/operations/Strategy-Proposal-Workflow.md` | Content-additive | Commit | +3 link lines |
| `01-nexus/runtime/Phase-Status-Pointer.md` | Content-additive | Commit | Adds Truth-Hierarchy + Operator-Principles refs |
| `01-nexus/strategies/Strategy-ORB.md` | Content-additive | Commit | Karri + Operator-Principles + Truth-Hierarchy refs |
| `01-nexus/strategies/Strategy-Promotion-Workflow.md` | Content-additive | Commit | +4 link lines |
| `01-nexus/strategies/Strategy-Scalp-Overlap.md` | Content-additive | Commit | +3 link lines |
| `01-nexus/strategies/Strategy-Session-Breakout.md` | Content-additive | Commit | +3 link lines |
| `01-nexus/strategies/Strategy-Vol-Expansion.md` | Content-additive | Commit | +3 link lines |
| `_maps/Decisions-MOC.md` | Content-additive | Commit | Adds full "Decision-trees" + "Runbooks" index sections (+26 lines) |
| `_maps/Memory-MOC.md` | Content-additive | Commit | Adds last-session pointer + decision-trees/runbooks paragraph |
| `_maps/Tools-MOC.md` | Content-additive | Commit | One link retarget: WF-1 → MCP-n8n |
| `_maps/Workflows-MOC.md` | Content-additive | Commit | Adds Runbook-Quota-Upgrade entry + last-session pointer |

## Workspace-state files that should NOT be committed

- `.obsidian/graph.json` — graph-view zoom level. Re-changes every time the operator scrolls in graph view.

**Proposed `.gitignore` additions** (append to `/home/nithu/Obsidian/Brain/.gitignore`):

```gitignore
# obsidian graph-view zoom state (changes every interaction)
.obsidian/graph.json
```

Then untrack the currently-tracked copy without deleting it:

```bash
cd /home/nithu/Obsidian/Brain
git rm --cached .obsidian/graph.json
```

Note: the existing gitignore already excludes `.obsidian/workspace*`, `.obsidian/cache`, and `.obsidian/plugins/obsidian-local-rest-api/`. Adding `graph.json` fits the same pattern. Optionally consider `.obsidian/graph.json` plus other transient UI state if more turn up (`appearance.json` is usually stable, so leave it).

## Proposed single-commit message (heredoc-ready)

```
docs(brain): MOC backfill + module/operations link densification

Knowledge-graph densification across:
- Nexus-MOC + 10 modules + 7 operations + runtime/Phase-Status-Pointer + 5 strategies
- _maps/{Decisions,Memory,Tools,Workflows}-MOC backfill
- 00-DASHBOARD health/ops section + date bump

No deletions; only additions of [[wikilinks]] and small index sections
pointing to _decisions/, _runbooks/, and 01-nexus/runtime-state/ scaffolding
from the 2026-05-11 cognitive-OS push.

OPERATOR-APPROVED: routine MOC update
```

## Proposed split-commit approach (if finer history wanted)

Three logically-clean commits:

1. **`docs(brain): nexus modules + operations + strategies link backfill`** — `01-nexus/modules/`, `01-nexus/operations/`, `01-nexus/strategies/`, `01-nexus/runtime/Phase-Status-Pointer.md`, `01-nexus/Nexus-MOC.md` (24 files)
2. **`docs(brain): _maps MOC backfill (decisions/memory/tools/workflows)`** — `_maps/Decisions-MOC.md`, `_maps/Memory-MOC.md`, `_maps/Tools-MOC.md`, `_maps/Workflows-MOC.md` (4 files)
3. **`docs(brain): dashboard health section + date stamp`** — `00-DASHBOARD.md` (1 file)

(Plus a separate `chore(brain): untrack .obsidian/graph.json` commit for the gitignore change.)

## Exact ready-to-run commands

### Single-commit approach (recommended)

```bash
cd /home/nithu/Obsidian/Brain

# 1. Untrack workspace-state file + extend gitignore
printf '\n# obsidian graph-view zoom state (changes every interaction)\n.obsidian/graph.json\n' >> .gitignore
git rm --cached .obsidian/graph.json

# 2. Stage only the content directories (NOT .obsidian/)
git add 00-DASHBOARD.md 01-nexus/ _maps/ .gitignore

# 3. Sanity-check what's staged
git status --short
git diff --cached --stat

# 4. Commit (operator edits message inline)
git commit -m "$(cat <<'EOF'
docs(brain): MOC backfill + module/operations link densification

Knowledge-graph densification across:
- Nexus-MOC + 10 modules + 7 operations + runtime/Phase-Status-Pointer + 5 strategies
- _maps/{Decisions,Memory,Tools,Workflows}-MOC backfill
- 00-DASHBOARD health/ops section + date bump
- untrack .obsidian/graph.json (UI zoom state)

No deletions; only additions of [[wikilinks]] and small index sections
pointing to _decisions/, _runbooks/, and 01-nexus/runtime-state/ scaffolding
from the 2026-05-11 cognitive-OS push.

OPERATOR-APPROVED: routine MOC update
EOF
)"
```

### Split-commit approach (if finer history wanted)

```bash
cd /home/nithu/Obsidian/Brain

# Untrack graph.json first (separate chore commit)
printf '\n# obsidian graph-view zoom state\n.obsidian/graph.json\n' >> .gitignore
git rm --cached .obsidian/graph.json
git add .gitignore
git commit -m "chore(brain): untrack .obsidian/graph.json (UI zoom state)"

# Commit 1 — nexus subtree
git add 01-nexus/
git commit -m "docs(brain): nexus modules + operations + strategies link backfill"

# Commit 2 — _maps
git add _maps/
git commit -m "docs(brain): _maps MOC backfill (decisions/memory/tools/workflows)"

# Commit 3 — dashboard
git add 00-DASHBOARD.md
git commit -m "docs(brain): dashboard health section + date stamp"
```

Currently on branch `feat/brain-hardening` — operator decides whether to merge to `main` or land directly on `feat/brain-hardening` first.

## Decision for operator

Commit as-is (single) / split by area / discard? Reply with choice, or just run `git commit ...` yourself.

If you want me to execute, send "OK kjør single" or "OK kjør split" — per the global "OK kjør"-gate I will not run any of these commands until you do.
