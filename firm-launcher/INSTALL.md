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
```

## Verify

```bash
command -v firm && command -v firmt && command -v firmz
ls ~/Obsidian/Brain/00-firm-bus/
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

Sist oppdatert: 2026-05-13
