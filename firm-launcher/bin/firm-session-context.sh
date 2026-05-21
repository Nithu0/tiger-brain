#!/usr/bin/env bash
# firm-session-context.sh — SessionStart hook for firm-launched Claude tabs.
#
# Emits a short context block telling the in-tab Claude its role, the recent
# firm-bus feed, and any pending inbox items. Skips silently when FIRM_ROLE
# is unset so non-firm sessions are untouched.
#
# Wired into ~/.claude/settings.json under hooks.SessionStart. Output is
# captured by Claude Code and surfaced as additional SessionStart context.
#
# SAFETY:
#   - Read-only. Never edits feed.md, inbox, or any settings.
#   - Hard caps total output to MAX_CHARS to protect context budget.
#   - Never reads .env / secrets.

set -u
# no `set -e`: a missing optional file must not abort the dump.

# Silent skip for non-firm sessions.
if [ -z "${FIRM_ROLE:-}" ]; then
  exit 0
fi

BUS_DIR="$HOME/Obsidian/Brain/00-firm-bus"
FEED_FILE="$BUS_DIR/feed.md"
INBOX_FILE="$BUS_DIR/inbox/${FIRM_ROLE}.md"
MAX_CHARS=4000

main_dump() {
  echo "### firm-launched session"
  echo "Role: ${FIRM_ROLE} | Project: ${FIRM_PROJECT:-unknown} | Opened: ${FIRM_TAB_OPENED_AT:-unknown}"
  echo

  echo "### recent firm-bus feed (last 30 lines)"
  if [ -r "$FEED_FILE" ]; then
    tail -n 30 "$FEED_FILE"
  else
    echo "(no feed.md at $FEED_FILE)"
  fi
  echo

  if [ -r "$INBOX_FILE" ] && [ -s "$INBOX_FILE" ]; then
    echo "### your inbox"
    cat "$INBOX_FILE"
    echo
  fi
}

RAW=$(main_dump 2>/dev/null)
if [ "${#RAW}" -gt "$MAX_CHARS" ]; then
  printf '%s' "$RAW" | head -c "$MAX_CHARS"
  printf '\n... (output truncated at %d chars)\n' "$MAX_CHARS"
else
  printf '%s\n' "$RAW"
fi

exit 0
