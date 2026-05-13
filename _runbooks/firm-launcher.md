---
date: 2026-05-13
type: runbook
project: workspace
status: active
---

# firm-launcher

Operational runbook for the `firm` multi-terminal launcher.

## 1. What firm does

`firm` opens 8 Claude Code sessions in parallel across operator's projects in a single Windows Terminal window (default: split-view). Each pane is wired to a distinct `FIRM_ROLE` + `FIRM_PROJECT` and announces itself on the shared firm-bus (`~/Obsidian/Brain/00-firm-bus/`) so the 8 agents can coordinate without stepping on each other. Goal: one keystroke to bring the whole agentic team online.

## 2. Prerequisites

- Windows Terminal installed; `wt.exe` accessible from WSL via `/mnt/c/Users/nithu/AppData/Local/Microsoft/WindowsApps/wt.exe`.
- Claude CLI installed via NVM at `/home/nithu/.nvm/versions/node/*/bin/claude`.
- `~/Obsidian/Brain/00-firm-bus/` exists (auto-created on first launch if missing).

## 3. How to invoke

| Command | Effect |
|---|---|
| `firm` | Default split-view — 8 panes in 1 WT tab |
| `firmt` | 8 tabs in 1 WT window (fallback if split-view feels cramped) |
| `firmz` | zellij layout fallback (if WT misbehaves) |
| `nx` | Alias — same as `firm` |

Note: `firm!` does NOT work — bash reserves `!` for history expansion. Use `firm` (or `nx`).

## 4. What each pane/tab does

Each pane runs `firm-tab-init.sh` which:

- Sets `FIRM_ROLE` (e.g. `ai-1`), `FIRM_PROJECT` (e.g. `nexus`), `FIRM_TAB_OPENED_AT` (ISO timestamp).
- Appends an "online" line to `~/Obsidian/Brain/00-firm-bus/feed.md`.
- Touches `~/Obsidian/Brain/00-firm-bus/inbox/$FIRM_ROLE.md` so the inbox exists for peers.
- Execs `claude --dangerously-skip-permissions`.

## 5. Default role/project distribution

Source of truth: `~/Obsidian/Brain/00-firm-bus/roster.md`.

| Pane | FIRM_ROLE | FIRM_PROJECT | cwd |
|---|---|---|---|
| 1 | ai-1 | nexus | `~/code/ai-assistent` |
| 2 | ai-2 | nexus | `~/code/ai-assistent` |
| 3 | ai-3 | nexus | `~/code/ai-assistent` |
| 4 | thesis-1 | master | `~/code/Master-oppgave` |
| 5 | thesis-2 | master | `~/code/Master-oppgave` |
| 6 | battery-1 | battery | `~/code/battery-electrolyte-predictor` |
| 7 | ops | workspace | `~/code` |
| 8 | scratch | workspace | `~` |

## 6. firm-bus protocol (3 rules)

1. **Read before write** — read your `inbox/$FIRM_ROLE.md` + last 30 lines of `feed.md` before non-trivial work.
2. **Handoff via inbox** — leave a markdown block in `inbox/<peer-role>.md`, date-stamped (`## 2026-05-13 14:32 — from ai-1`).
3. **Announce completion** — append `done: <one-liner>` to `feed.md` when a chunk finishes so others can pick up.

## 7. Common errors + fixes

- **WT error `0x80070002 ERROR_FILE_NOT_FOUND`** — usually means the wt.exe-side command included a literal newline/heredoc. Fix: all firm scripts now factor per-pane init through `firm-tab-init.sh` to keep the wt.exe arg single-line.
- **`firm!`-as-command** — bash history-expansion blocks it. Use `firm` (or `nx`).
- **Zellij copy/paste friction** — enter scroll mode with `Ctrl+S`, select with `v`, yank with `y`. Or set `mouse_mode: false` in zellij config to fall back to terminal-native mouse select.
- **`claude: command not found` in a pane** — NVM PATH didn't load; ensure `bash -lic` is used (login + interactive shells source `.bashrc`).
- **`wt.exe: command not found` from WSL** — confirm Windows Terminal is installed and `/mnt/c/Users/nithu/AppData/Local/Microsoft/WindowsApps/wt.exe` exists.

## 8. Inverse — graceful shutdown

Close each pane normally with `exit` or `Ctrl+D`. The init script's `exec claude` means killing claude drops to bash (since the launcher uses `; exec bash` fallback in some variants). Alternatively: `wt.exe -w 0 focus-tab && wt.exe close-tab`, or just close the window.
