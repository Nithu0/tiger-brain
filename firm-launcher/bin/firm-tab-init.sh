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

bus_dir="$HOME/Obsidian/Brain/00-firm-bus"
inbox_dir="$bus_dir/inbox"
feed_file="$bus_dir/feed.md"

mkdir -p "$inbox_dir"
touch "$inbox_dir/${role}.md"

# Append online marker to the shared feed (one line, no heredoc).
printf -- '- %s %s online in %s\n' "$FIRM_TAB_OPENED_AT" "$role" "$project" >> "$feed_file"

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
  echo "[firm-tab-init] env_file_loaded=$([[ "$project" == nexus && -f "$HOME/code/ai-assistent/.env.local" ]] && echo yes || echo no)"
  exit 0
fi

# Background brain hygiene check (sanity + audit + pull) — see ~/Obsidian/Brain/scripts/brain-session-start.sh
bash "${HOME}/Obsidian/Brain/scripts/brain-session-start.sh" --quiet 2>&1 &

exec claude --dangerously-skip-permissions
