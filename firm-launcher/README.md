---
tags: [meta, firm, launcher]
type: meta
created: 2026-05-13
---

# firm-launcher

## What is firm?

`firm` is an 8-tab Claude Code session launcher spanning the operator's three projects (workspace, nexus trading firm, master-oppgave thesis). Each tab boots `claude --dangerously-skip-permissions` with role-specific context preloaded, so a single `firm` invocation spins up an entire working "firm" of agents in parallel. Inter-tab coordination happens via a shared file bus in `00-firm-bus/` inside tiger-brain. Operator is Nithu0; the same pattern is shared with collaborators (Karri etc.) so we all work from the same muscle memory.

## Why share it?

- Same operator+collaborator workflow means less friction and fewer "wait what command was that?" moments.
- Same brain hooks means the same hygiene defaults (auto-push, memory layout, role banners).
- One-command install (`bash firm-launcher/install.sh`) — no bespoke per-machine setup.

## What's in this folder

- `install.sh` — one-command setup: copies all `bin/*.sh` into `FIRM_BIN_DIR`,
  writes `~/.bashrc` aliases, wires `~/.claude/settings.json` statusLine,
  installs the brain pre-push hook, runs sanity. Idempotent.
- `bin/*.sh` — the portable firm script set. The installer globs and installs
  every `.sh` here, so the list grows without touching `install.sh`. Currently:
  - `firm-wt-split.sh` — Windows Terminal: 8 split panes in 1 tab (default `firm`).
  - `firm-wt-tabs.sh` — Windows Terminal: 8 separate tabs.
  - `firm-zellij.sh` — zellij fallback (no Windows Terminal needed).
  - `firm-tab-init.sh` — per-pane bootstrap (env vars, bus init, claude exec).
  - `firm-statusline.sh` — role banner for the Claude Code status line.
  - `firm-session-context.sh` — context dump on Claude SessionStart hook.
  - `firm-inbox-watch.sh` — Slice 11 watcher; panes auto-pick-up dispatches
    queued from command-center.
  - `firm-worktree-{spawn,list,cleanup}.sh` — git worktree helpers.
  - `firm-git-snapshot.sh`, `firm-heartbeat.sh` — periodic snapshot + liveness.
- `bash/nexus-bashrc.sh` — Nexus shell banner + project-specific commands.

> The firm `_bin` scripts canonically live in the **command-center** repo
> (`github.com/Nithu0/command-center`, private) at `command-center/_bin/` —
> that is where the operator edits them. The `bin/` copy here is the portable
> installer payload for collaborators who haven't cloned command-center.

## Prerequisites

- WSL2 (Windows) or native Linux/macOS.
- bash 4+.
- git + SSH-to-GitHub working (test with `ssh -T git@github.com`).
- claude CLI installed — see `https://claude.com/claude-code`.
- Windows Terminal (or zellij as a fallback).
- Cloned `tiger-brain` and `ai-assistent` repos. The installer can clone them if missing.

## Install (TL;DR)

```bash
git clone git@github.com:Nithu0/tiger-brain.git ~/Obsidian/Brain
cd ~/Obsidian/Brain
bash firm-launcher/install.sh
source ~/.bashrc
firm
```

## Usage

- `firm` — default; 8 panes split in 1 Windows Terminal window.
- `firmt` — 8 separate Windows Terminal tabs.
- `firmz` — zellij fallback for non-WT environments.
- `nx` — alias for `firm` (muscle-memory shortcut).

## How firm-bus works

Each tab writes status lines to `~/Obsidian/Brain/00-firm-bus/feed.md` and reads its own inbox at `~/Obsidian/Brain/00-firm-bus/inbox/<role>.md`. This gives the 8 sessions a lightweight, append-only coordination channel without inter-process plumbing — anyone (including the operator) can drop a message into a role's inbox. See `_runbooks/firm-launcher.md` for the full protocol.

On top of the file bus, each pane runs `firm-inbox-watch.sh` (Slice 11): it watches for dispatches queued from the **command-center** control plane and auto-picks them up, so queued work reaches the right pane without manual polling.

## statusLine

The installer wires `~/.claude/settings.json` → `statusLine.command` to `<FIRM_BIN_DIR>/firm-statusline.sh`, which renders the per-pane role banner. The edit is JSON-aware (python3 or jq) and idempotent; a timestamped backup of `settings.json` is made first, and a malformed existing file is left untouched with a warning.

## FIRM_ROSTER — choose your pane layout

| Preset | Layout |
|---|---|
| `default` | 2 workspace + 4 nexus + 2 thesis (operator's full setup) |
| `nexus` | 8 nexus panes (for Nexus-only collaborators like Karri) |
| `thesis` | 8 thesis panes |
| `workspace` | 8 workspace panes |

Set via env var (persistent — installer writes to .bashrc):
```
export FIRM_ROSTER=nexus
```

Or override per-launch:
```
firm nexus    # one-off override
```

## Customization

Set these env vars before running `install.sh` to override defaults:

- `BRAIN_VAULT=~/path/to/brain` — where tiger-brain lives (default `~/Obsidian/Brain`).
- `NEXUS_REPO=~/path/to/ai-assistent` — Nexus trading firm repo path.
- `FIRM_BIN_DIR=~/path/to/bin` — where firm scripts get installed (default `~/code/command-center/_bin`).
- `CLAUDE_SETTINGS=~/path/to/settings.json` — Claude Code settings file to wire the statusLine into (default `~/.claude/settings.json`).

## Uninstall

Remove the `# === firm launcher ===` block from `~/.bashrc`, delete `$FIRM_BIN_DIR/firm-*.sh`, and remove the `statusLine` key from `~/.claude/settings.json` (or restore a `settings.json.bak-*` backup). Bus files in `00-firm-bus/` are safe to keep or wipe.

## Related

- `_runbooks/firm-launcher.md` — operator's deep runbook.
- `00-firm-bus/README.md` — bus protocol details.
- `KARRI-DAY-1.md` — collaborator onboarding walkthrough.

Sist oppdatert: 2026-05-21 — _bin flyttet til command-center-repoet; statusLine-wiring + Slice 11 inbox-watcher dokumentert; full bin/-skriptsett listet.
