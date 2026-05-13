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

# Identify the human operator. Prefer FIRM_USER, then git user.name from the
# brain repo, then $USER as last resort. Sanitized to a single token so the
# grep -v filter below works reliably.
GIT_USER="${FIRM_USER:-}"
if [ -z "$GIT_USER" ]; then
  GIT_USER=$(cd "$BUS_DIR/.." 2>/dev/null && git config user.name 2>/dev/null || true)
fi
if [ -z "$GIT_USER" ]; then
  GIT_USER="${USER:-unknown}"
fi
# Collapse whitespace to underscore for the bracket-tag form `[name]`.
GIT_USER_TAG=$(printf '%s' "$GIT_USER" | tr -s '[:space:]' '_')

main_dump() {
  echo "### firm-launched session"
  echo "User: ${GIT_USER_TAG} | Role: ${FIRM_ROLE} | Project: ${FIRM_PROJECT:-unknown} | Opened: ${FIRM_TAB_OPENED_AT:-unknown}"
  echo

  echo "### recent peer activity (last 20 lines of feed.md, own entries filtered)"
  if [ -r "$FEED_FILE" ]; then
    # Filter own entries (matched by `[GIT_USER_TAG]`) so we see peer work.
    # If filtering leaves nothing, fall back to plain tail so the operator at
    # least sees the most recent feed state.
    PEERS=$(tail -n 200 "$FEED_FILE" | grep -v "\[${GIT_USER_TAG}\]" | tail -n 20)
    if [ -n "$PEERS" ]; then
      printf '%s\n' "$PEERS"
    else
      echo "(no peer entries yet — showing last 20 lines)"
      tail -n 20 "$FEED_FILE"
    fi
  else
    echo "(no feed.md at $FEED_FILE)"
  fi
  echo

  if [ -r "$INBOX_FILE" ] && [ -s "$INBOX_FILE" ]; then
    # Count message headers (lines starting with `## `) as a rough message count.
    MSG_COUNT=$(grep -c '^## ' "$INBOX_FILE" 2>/dev/null || echo 0)
    echo "### your inbox (${MSG_COUNT} pending message$( [ "$MSG_COUNT" = "1" ] || echo s ))"
    cat "$INBOX_FILE"
    echo
  else
    echo "### your inbox (0 pending messages)"
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
