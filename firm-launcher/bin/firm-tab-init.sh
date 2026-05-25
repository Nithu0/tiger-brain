#!/usr/bin/env bash
# firm-tab-init.sh — per-tab initialization for the firm-mirror multi-tab launch.
#
# Invoked from within each Windows Terminal tab (via wsl.exe -- bash -lic).
# Keeping this as a STANDALONE script (no heredoc, no inline multi-line) is
# deliberate: wt.exe action-strings split on newlines, so a previous heredoc-
# based approach hit 0x80070002 ERROR_FILE_NOT_FOUND. Do NOT inline this back.
#
# Usage: firm-tab-init.sh [--dry-run] <role> <project>
#   role     e.g. ai-1, code-2, thesis-1
#   project  e.g. nexus, workspace, master-oppgave

# WARNING: invoked from wt.exe via:
#   wsl.exe --cd <path> -- bash -lic "$INIT $role $project"
#
# The bash -lic command MUST be passed UNQUOTED at the call site. If
# the caller wraps in single quotes ('$INIT $role $project'), bash -c
# strips the quotes but keeps the contents as ONE word, leading to
# "No such file or directory" on a path-with-spaces. See firm-wt-split.sh
# comments for the correct pattern.

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

if [[ $# -lt 2 ]]; then
  echo "firm-tab-init.sh: missing args" >&2
  echo "usage: firm-tab-init.sh <role> <project>" >&2
  echo "  example: firm-tab-init.sh ai-1 nexus" >&2
  exit 2
fi

role="$1"
project="$2"

if [[ -z "$role" || -z "$project" ]]; then
  echo "firm-tab-init.sh: role and project must be non-empty" >&2
  exit 2
fi

export FIRM_ROLE="$role"
export FIRM_PROJECT="$project"
FIRM_TAB_OPENED_AT="$(date -u +%FT%TZ)"
export FIRM_TAB_OPENED_AT

# Farge-koding pr. prosjekt (ANSI escape-sekvens). Brukes av firm-statusline.sh
# og kan også brukes i shell-prompts. Default = ingen farge (tom string).
case "$project" in
  workspace)      FIRM_COLOR=$'\033[90m' ;;  # grå
  nexus)          FIRM_COLOR=$'\033[33m' ;;  # gul (XAUUSD gull)
  master-oppgave) FIRM_COLOR=$'\033[34m' ;;  # blå
  AS)             FIRM_COLOR=$'\033[32m' ;;  # grønn
  soking-fulltid) FIRM_COLOR=$'\033[36m' ;;  # cyan
  personlig)      FIRM_COLOR=$'\033[35m' ;;  # magenta
  *)              FIRM_COLOR="" ;;
esac
export FIRM_COLOR

bus_dir="$HOME/Obsidian/Brain/00-firm-bus"
inbox_dir="$bus_dir/inbox"
feed_file="$bus_dir/feed.md"
presence_file="$bus_dir/PRESENCE.md"

mkdir -p "$inbox_dir"
touch "$inbox_dir/${role}.md"

# Append online marker to the shared feed (one line, no heredoc).
printf -- '- %s %s online in %s\n' "$FIRM_TAB_OPENED_AT" "$role" "$project" >> "$feed_file"

# Append presence row on pane start (per I-8 Option A). Matches PRESENCE.md
# header: | Time | User | Role | Project | Status |
firm_user_tag="$(git config --global user.name 2>/dev/null | tr -d ' ' || echo unknown)"
printf -- '| %s | %s | %s | %s | online |\n' \
  "$FIRM_TAB_OPENED_AT" "${firm_user_tag:-unknown}" "$role" "$project" >> "$presence_file"

# Load project-specific .env.local so MCP servers (e.g. nexus-pg requiring
# NEXUS_READONLY_PG_URL) resolve their env vars. Without this the nexus-pg
# MCP throws a /doctor warning on the 4 ai-* panes. Sourced; never printed.
# Use `set -a` so all assignments become exported, then `set +a` to revert.
case "$project" in
  nexus)
    env_file="$HOME/code/ai-assistent/.env.local"
    if [[ -f "$env_file" ]]; then
      set -a
      # shellcheck disable=SC1090
      source "$env_file" 2>/dev/null || true
      set +a
    fi
    ;;
esac

if [[ "$DRY_RUN" == "1" ]]; then
  echo "[firm-tab-init] DRY-RUN — would now exec: claude --dangerously-skip-permissions"
  echo "[firm-tab-init] FIRM_ROLE=$FIRM_ROLE FIRM_PROJECT=$FIRM_PROJECT"
  # Skriv ut FIRM_COLOR som lesbar streng (escape \033 → \\033) så det vises i logger
  echo "[firm-tab-init] FIRM_COLOR=$(printf '%s' "$FIRM_COLOR" | sed 's/\x1b/\\033/g')"
  echo "[firm-tab-init] env_file_loaded=$([[ "$project" == nexus && -f "$HOME/code/ai-assistent/.env.local" ]] && echo yes || echo no)"
  exit 0
fi

# Sett Windows Terminal pane-tittel via OSC 2 escape-sekvens.
# Format: "<role> · <project>" — kort, identifiserer panen i den 8-pane gridden.
printf '\033]2;%s · %s\007' "$role" "$project"

# Slice 11 — pane auto-pickup. Show any dispatches already sitting in this
# pane's inbox, then launch the background watcher (standalone script — no
# heredoc, keeping the discipline this file's header warns about) that polls
# the inbox and prints a loud banner whenever command-center dispatches work.
inbox_file="$inbox_dir/${role}.md"
if [[ -s "$inbox_file" ]]; then
  echo "── pending inbox ($role) ───────────────────────────────────────"
  cat "$inbox_file"
  echo "────────────────────────────────────────────────────────────────"
fi
watch_script="$(dirname "${BASH_SOURCE[0]}")/firm-inbox-watch.sh"
if [[ -x "$watch_script" ]]; then
  "$watch_script" "$role" &
fi

# Background brain hygiene check (sanity + audit + pull) — se ~/Obsidian/Brain/scripts/brain-session-start.sh
# Output goes to a log file, not the terminal — otherwise it lands on top of
# Claude's TUI (race: brain check ≈2s, claude render is faster in some panes,
# slower in others, leading to inconsistent "brain: ✗ audit FAIL" splatter
# across some panes but not others).
brain_log="${HOME}/Obsidian/Brain/.brain-session-start.log"
bash "${HOME}/Obsidian/Brain/scripts/brain-session-start.sh" --quiet >>"$brain_log" 2>&1 &

exec claude --dangerously-skip-permissions
