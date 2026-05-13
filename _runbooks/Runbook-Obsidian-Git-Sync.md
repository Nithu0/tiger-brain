---
type: runbook
tags: [runbook, obsidian, sync]
created: 2026-05-13
---
# Runbook: Obsidian-Git Sync

Pre-configured auto-sync of the Brain vault between operator's machine and Karri's machine through the shared GitHub account. The Obsidian Git plugin (by Vinzent03, plugin ID `obsidian-git`) handles pull/commit/push on intervals so the vault feels live.

## What is the plugin
- Community plugin: [github.com/Vinzent03/obsidian-git](https://github.com/Vinzent03/obsidian-git)
- Treats the vault folder as a git working tree.
- Runs `git pull` / `git add -A && git commit` / `git push` on configurable intervals.
- Surfaces conflicts in a source-control side panel.

## Why we use it
Operator and Karri both write to the same vault (Brain). Without auto-sync, edits diverge silently and someone overwrites someone else's note. Aggressive intervals give a near-live feel: an edit one of us makes is visible to the other within 7 minutes worst-case (2 min commit + 5 min push + 2 min pull on the receiver). Both push directly to `main` because the shared GitHub account is on the branch-protection bypass list (see [[Runbook-Branch-Protection]]).

## Settings (data.json) — what each interval does
- **`autoSaveInterval: 2`** — every 2 min, plugin runs `git add -A && git commit -m "<commitMessage>"` if there are changes.
- **`autoPushInterval: 5`** — every 5 min, plugin runs `git push` (after `git pull` because `pullBeforePush: true`).
- **`autoPullInterval: 2`** — every 2 min, plugin runs `git pull` to bring in the other party's commits.
- **`autoPullOnBoot: true`** — fresh pull when Obsidian starts, so we never start editing on stale state.
- **`syncMethod: "merge"`** — conflicts produce a merge commit, not a rebase. Easier to reason about for non-engineers.
- **`differentIntervalCommitAndPush: true`** — required so commit (2 min) and push (5 min) don't collapse to the same timer.
- **`disablePopups: true`** + **`disablePopupsForNoChanges: true`** — no toast spam every 2 min.

## Commit messages
Format: `auto-sync: <hostname> at <YYYY-MM-DD HH:mm:ss>`

Both operators can filter their own vs the partner's commits:
```bash
git log --grep "auto-sync"                           # all auto-sync
git log --grep "auto-sync: <operator-hostname>"      # operator only
git log --grep "auto-sync: <karri-hostname>"         # Karri only
git log --invert-grep --grep "auto-sync"             # manual commits only
```

## Branch
Pushes to whatever branch the working tree is on. For Brain that is `main`. Branch protection has a bypass list that includes the shared GitHub account, so direct push works (do NOT rely on this for code repos — Brain is the exception).

## Conflict handling
Plugin uses `merge` strategy.
- Clean merges: silent, you get an extra commit.
- Conflicting merges: plugin's source-control panel shows conflicted files. Resolve in Obsidian or drop to CLI:
  ```bash
  cd /home/nithu/Obsidian/Brain
  git status                # see conflicted files
  # edit conflict markers in conflicted notes
  git add <files>
  git commit
  ```
- Most conflicts on text notes auto-resolve because both sides usually edit different sections.

## Manual override
Command palette (Ctrl/Cmd+P):
- **"Obsidian Git: Commit all changes and push"** — force a sync now, don't wait for the timer.
- **"Obsidian Git: Pull"** — force a pull now.
- **"Obsidian Git: Open source control view"** — see what's staged/conflicted.

## Temporarily disable
Command palette:
- **"Obsidian Git: Disable auto pull"**
- **"Obsidian Git: Disable auto backup and auto push"**

Use when on flaky network, or when staging a large refactor of vault structure that you don't want fragmented across 30 auto-commits.

## CI cost mitigation
Brain repo has workflows (`brain-checks`, `path-guard`, `secrets-scan`) on push to main. Auto-push every 5 min = up to 288 workflow runs per day per operator. Mitigation options:
1. **`[skip ci]` in commit message**: GitHub Actions skips the run when commit message contains `[skip ci]`. Update `commitMessage` in `data.json` to `auto-sync: {{hostname}} at {{date}} [skip ci]`. Trade-off: brain-checks (Vale lint, link-checker) no longer runs on auto-sync commits — only on manual commits. Acceptable because manual commits are where real edits land; auto-sync mostly captures whitespace/cursor-position drift.
2. **Workflow-level filter**: add `if: ${{ !contains(github.event.head_commit.message, 'auto-sync:') }}` to each job. More explicit, but requires editing all three workflow files.

Recommended: option 1 (`[skip ci]` in commit message). Operator decides — see [[Runbook-Brain-Weekly-Maintenance]] for the weekly manual-lint pass that catches what gets skipped.

## Karri vs operator editing the same note
Same-section edits → merge conflict → resolve per "Conflict handling" above. Different-section edits → clean merge, both kept. Worst case: one note ends with conflict markers and surfaces in source-control panel within 7 minutes. No silent data loss because everything is committed every 2 min.

## What never auto-fires
- Push to anything except current branch (plugin doesn't switch branches).
- `git push --force` (plugin never force-pushes).
- Commits to a detached HEAD (plugin refuses and notifies).
- Pull when local has uncommitted changes (plugin auto-stashes, then pops).

## First-time setup on a fresh machine
1. Install Obsidian.
2. Clone Brain repo to `~/Obsidian/Brain` (or platform equivalent).
3. Open vault in Obsidian.
4. Settings → Community plugins → enable `obsidian-git` (auto-detects this `data.json` and applies all settings).
5. Verify status bar shows git state at bottom of window.
6. Make a test edit, wait 2 min, check `git log` — should see an `auto-sync:` commit.

## Linked
[[Runbook-Branch-Protection]] · [[Runbook-Brain-Weekly-Maintenance]] · [[Runbook-Brain-Post-Push-Cleanup]] · [[Runbook-Obsidian-Workspace-Drift]]

Sist oppdatert: 2026-05-13
