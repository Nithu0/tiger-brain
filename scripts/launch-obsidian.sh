#!/usr/bin/env bash
# launch-obsidian.sh — open the brain vault in local Linux Obsidian
set -uo pipefail

OBSIDIAN_BIN="${OBSIDIAN_BIN:-$HOME/.local/bin/Obsidian.AppImage}"
VAULT="${BRAIN_VAULT:-$HOME/Obsidian/Brain}"

if [[ ! -x "$OBSIDIAN_BIN" ]]; then
  echo "Obsidian not found at $OBSIDIAN_BIN" >&2
  echo "Install with: bash scripts/install-obsidian-linux.sh" >&2
  exit 1
fi
if [[ ! -d "$VAULT" ]]; then
  echo "Vault not found at $VAULT" >&2
  exit 1
fi

# Launch in background, detached
nohup "$OBSIDIAN_BIN" "obsidian://open?vault=Brain&path=$VAULT" >/dev/null 2>&1 &
disown
echo "Obsidian launching with vault: $VAULT"
