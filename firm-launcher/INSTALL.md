---
tags: [meta, firm, launcher, install]
type: meta
created: 2026-05-13
---

# firm-launcher — install reference

## Install

```bash
git clone git@github.com:Nithu0/tiger-brain.git ~/Obsidian/Brain
cd ~/Obsidian/Brain
bash firm-launcher/install.sh
source ~/.bashrc

# install.sh will prompt for:
#   - name + email (for git config in cloned repos)
#   - FIRM_ROSTER preset (1=default, 2=nexus, 3=thesis, 4=workspace)
# All can be passed via flags: --name NAME --email EMAIL --roster nexus --yes
```

The installer:

- copies every `firm-launcher/bin/*.sh` script into `FIRM_BIN_DIR`
  (default `~/code/command-center/_bin`) and `chmod +x`'s them;
- wires `~/.bashrc` aliases — `firm`/`nx` → split-pane, `firmt` → tabs,
  `firmz` → zellij — plus an exported `FIRM_BIN_DIR`;
- wires `~/.claude/settings.json` → `statusLine.command` to
  `<FIRM_BIN_DIR>/firm-statusline.sh` (JSON-safe edit via python3/jq, with a
  timestamped backup; never sed);
- installs the brain pre-push hook and runs a brain sanity check.

It is idempotent — safe to re-run.

> The firm `_bin` scripts canonically live in the **command-center** repo
> (`github.com/Nithu0/command-center`, private) at `command-center/_bin/`.
> The `firm-launcher/bin/` copy in tiger-brain is the portable installer
> payload for collaborators without command-center cloned.

## Verify

```bash
command -v firm && command -v firmt && command -v firmz
ls ~/code/command-center/_bin/firm-*.sh
ls ~/Obsidian/Brain/00-firm-bus/
grep -o '"command": *"[^"]*firm-statusline.sh"' ~/.claude/settings.json
claude --version
```

## First launch

```bash
firm
```

## Failure modes

- `firm: command not found` → run `source ~/.bashrc` or open a new shell.
- `claude: command not found` → install Claude CLI from `https://claude.com/claude-code`, then re-run install.
- `wt.exe not found` (WSL) → use `firmz` (zellij) instead, or install Windows Terminal.
- `git@github.com: Permission denied` → fix SSH key with `ssh -T git@github.com` before cloning.
- Bus dir missing or unwritable → `mkdir -p ~/Obsidian/Brain/00-firm-bus/inbox && chmod -R u+rw ~/Obsidian/Brain/00-firm-bus`.
- `settings.json exists but is invalid JSON` → the installer refuses to touch a
  malformed file. Fix the JSON by hand, then re-run; a backup
  (`settings.json.bak-<ts>`) is made before any edit.
- No status banner in panes → confirm `~/.claude/settings.json` has
  `statusLine.command` pointing at `~/code/command-center/_bin/firm-statusline.sh`
  and that the script is executable.

Sist oppdatert: 2026-05-21 — _bin flyttet til command-center-repoet; statusLine-wiring + Slice 11 inbox-watcher.
