#!/usr/bin/env bash
# firm-inbox-watch.sh — pane-side auto-pickup watcher for command-center dispatches.
#
# Watches the firm-bus inbox file for THIS pane's role and surfaces a loud
# banner when command-center (or any peer) appends new content. Polls with
# `stat` every ~5s — deliberately NO inotify dependency, so it is portable
# and WSL-safe with zero tool installs.
#
# Launched in the background by firm-tab-init.sh (after it touches the inbox,
# before `exec claude`). Can also be run standalone for testing.
#
# Usage: firm-inbox-watch.sh [role]
#   role  e.g. ai-1, code-2 — defaults to $FIRM_ROLE.
#
# Behaviour:
#   - Quiet when nothing changes (no spam).
#   - On inbox GROWTH: bordered banner + terminal bell to the pane tty,
#     prints the newly-appended delta lines, and appends ONE receipt line
#     to feed.md so command-center's live view registers the pickup.
#   - Read-only on inbox files. Only ever writes the single receipt line
#     to feed.md — never PRESENCE.md, never the inbox.
#   - Idempotent: a pidfile guards against a second watcher for the same
#     role double-firing.
#   - Exits cleanly when the parent pane dies (parent-PID poll + signal trap).

set -uo pipefail

# --- resolve role ---------------------------------------------------------
role="${1:-${FIRM_ROLE:-}}"
if [[ -z "$role" ]]; then
  echo "firm-inbox-watch.sh: no role given and FIRM_ROLE unset" >&2
  echo "usage: firm-inbox-watch.sh <role>" >&2
  exit 2
fi

bus_dir="$HOME/Obsidian/Brain/00-firm-bus"
inbox_file="$bus_dir/inbox/${role}.md"
feed_file="$bus_dir/feed.md"

POLL_INTERVAL=5

# --- pidfile / single-instance guard -------------------------------------
run_dir="${XDG_RUNTIME_DIR:-/tmp}"
pidfile="${run_dir}/firm-inbox-watch.${role}.pid"

if [[ -f "$pidfile" ]]; then
  old_pid="$(cat "$pidfile" 2>/dev/null || true)"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    # A live watcher for this role already exists — do not double-fire.
    echo "firm-inbox-watch.sh: watcher for '$role' already running (pid $old_pid); exiting" >&2
    exit 0
  fi
  # Stale pidfile — previous watcher is gone.
  rm -f "$pidfile" 2>/dev/null || true
fi

echo "$$" > "$pidfile"

# Parent PID captured at launch — when firm-tab-init.sh backgrounds us, this
# is the pane shell. When the pane dies the watcher should follow.
parent_pid="$PPID"

cleanup() {
  rm -f "$pidfile" 2>/dev/null || true
  exit 0
}
trap cleanup EXIT INT TERM HUP

# --- file-size helper (portable) -----------------------------------------
file_size() {
  # Echoes the byte size of $1, or 0 if it does not exist.
  if [[ -f "$1" ]]; then
    stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null || echo 0
  else
    echo 0
  fi
}

# --- ensure inbox exists; seed the baseline size --------------------------
mkdir -p "$bus_dir/inbox"
[[ -f "$inbox_file" ]] || touch "$inbox_file"

last_size="$(file_size "$inbox_file")"

# --- main poll loop -------------------------------------------------------
while true; do
  # Exit if the parent pane shell has gone away.
  if ! kill -0 "$parent_pid" 2>/dev/null; then
    cleanup
  fi

  sleep "$POLL_INTERVAL"

  cur_size="$(file_size "$inbox_file")"

  if [[ "$cur_size" -gt "$last_size" ]]; then
    # New content appended — compute the delta lines.
    delta_bytes=$(( cur_size - last_size ))
    delta_text="$(tail -c "$delta_bytes" "$inbox_file" 2>/dev/null || true)"
    # Count non-empty new lines for the banner / receipt.
    new_lines="$(printf '%s' "$delta_text" | grep -c . || true)"
    [[ -z "$new_lines" ]] && new_lines=0

    now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # --- loud bordered banner to the pane tty ---
    printf '\a'  # terminal bell
    printf '\n'
    printf '╔══════════════════════════════════════════════════════════════╗\n'
    printf '║  📥 NEW DISPATCH FROM COMMAND-CENTER                          ║\n'
    printf '║  role: %-54s ║\n' "$role"
    printf '║  %s new line(s) in your inbox%*s║\n' "$new_lines" $(( 36 - ${#new_lines} )) ""
    printf '║  run:  cat %-51s ║\n' "$inbox_file"
    printf '╠══════════════════════════════════════════════════════════════╣\n'
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      printf '║  %s\n' "$line"
    done <<< "$delta_text"
    printf '╚══════════════════════════════════════════════════════════════╝\n'
    printf '\n'

    # --- append ONE receipt line to feed.md ---
    printf -- '- %s %s received dispatch (inbox +%s lines)\n' \
      "$now_iso" "$role" "$new_lines" >> "$feed_file"

    last_size="$cur_size"
  elif [[ "$cur_size" -lt "$last_size" ]]; then
    # Inbox shrank (truncated/rotated) — re-baseline silently, no banner.
    last_size="$cur_size"
  fi
done
