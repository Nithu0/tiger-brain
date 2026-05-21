#!/usr/bin/env bash
# firm-statusline.sh — statusLine-kommando for Claude Code.
#
# Claude sender JSON på stdin (session-state). Vi trenger ikke parse det —
# vi leser bare $FIRM_ROLE / $FIRM_PROJECT / $FIRM_COLOR fra miljøet.
# Disse exporteres av firm-tab-init.sh før `exec claude`.
#
# Output: ett enkelt linje, kort. Hvis ikke kjørt fra en firm-pane,
# fall tilbake til current-dir basename.

set -eu

# Drenér stdin uten å bruke den (unngå SIGPIPE hvis Claude lukker tidlig).
# `read -t 0` ville være best, men holder oss enkelt: cat > /dev/null i bakgr.
cat >/dev/null 2>&1 || true

RESET=$'\033[0m'

if [ -n "${FIRM_ROLE:-}" ] && [ -n "${FIRM_PROJECT:-}" ]; then
  color="${FIRM_COLOR:-}"
  printf '%s%s%s · %s\n' "$color" "$FIRM_ROLE" "$RESET" "$FIRM_PROJECT"
else
  # Ikke i firm-sesjon — vis bare current dir basename
  printf '%s\n' "$(basename "$PWD")"
fi
