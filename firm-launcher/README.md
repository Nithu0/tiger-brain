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

- `install.sh` — one-command setup (writes aliases, ensures bus dir, links scripts).
- `bin/firm-wt-tabs.sh` — Windows Terminal: 8 separate tabs.
- `bin/firm-wt-split.sh` — Windows Terminal: 8 split panes in 1 tab (default `firm`).
- `bin/firm-tab-init.sh` — per-tab bootstrap (env vars, bus init, claude exec).
- `bin/firm-session-context.sh` — context dump on Claude SessionStart hook.
- `bin/firm-zellij.sh` — zellij fallback (no Windows Terminal needed).
- `bash/nexus-bashrc.sh` — Nexus shell banner + project-specific commands.

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

## Customization

Set these env vars before running `install.sh` to override defaults:

- `BRAIN_VAULT=~/path/to/brain` — where tiger-brain lives (default `~/Obsidian/Brain`).
- `NEXUS_REPO=~/path/to/ai-assistent` — Nexus trading firm repo path.
- `FIRM_BIN_DIR=~/path/to/bin` — where firm scripts get linked (default `~/.local/bin`).

## Uninstall

Remove the `# === firm launcher ===` block from `~/.bashrc` and delete `$FIRM_BIN_DIR/firm-*.sh`. Bus files in `00-firm-bus/` are safe to keep or wipe.

## Related

- `_runbooks/firm-launcher.md` — operator's deep runbook.
- `00-firm-bus/README.md` — bus protocol details.
- `KARRI-DAY-1.md` — collaborator onboarding walkthrough.

Sist oppdatert: 2026-05-13
