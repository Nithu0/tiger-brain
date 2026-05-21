#!/usr/bin/env bash
# firm-zellij — fallback launcher for the 8-pane zellij layout (firm8).
#
# Use this when the operator wants a multi-project split-view across the
# code workspace, ai-assistent firm, and Master-oppgave thesis repo, but
# does NOT want the strict firm-mirror (which gates hard on preflight).
#
# Steps:
#   1. Symlink ~/.config/zellij/layouts/firm8.kdl → the repo file at
#      $HOME/code/ai-assistent/.zellij/layouts/firm8.kdl
#      so editing the repo file is the only source of truth. Idempotent —
#      pattern lifted from scripts/firm/firm-up.sh.
#   2. Optionally run the existing preflight at
#      scripts/firm/preflight.sh — but UNLIKE firm-up, do NOT fail if it
#      reports red. This is the fallback launcher, not the strict mirror.
#   3. exec zellij --layout firm8.
#
# Usage (from anywhere):
#   $HOME/code/command-center/_bin/firm-zellij.sh

set -euo pipefail

REPO_ROOT="${NEXUS_REPO_ROOT:-$HOME/code/ai-assistent}"

# (1) Symlink the global zellij layout to the repo copy. Idempotent.
GLOBAL_LAYOUT_DIR="$HOME/.config/zellij/layouts"
GLOBAL_LAYOUT="$GLOBAL_LAYOUT_DIR/firm8.kdl"
REPO_LAYOUT="$REPO_ROOT/.zellij/layouts/firm8.kdl"

if [[ ! -f "$REPO_LAYOUT" ]]; then
  echo "[firm-zellij] ERROR: repo layout missing at $REPO_LAYOUT" >&2
  exit 1
fi

mkdir -p "$GLOBAL_LAYOUT_DIR"

if [[ -L "$GLOBAL_LAYOUT" ]]; then
  current=$(readlink "$GLOBAL_LAYOUT")
  if [[ "$current" != "$REPO_LAYOUT" ]]; then
    echo "[firm-zellij] re-pointing $GLOBAL_LAYOUT → $REPO_LAYOUT (was $current)"
    ln -sf "$REPO_LAYOUT" "$GLOBAL_LAYOUT"
  fi
elif [[ -e "$GLOBAL_LAYOUT" ]]; then
  echo "[firm-zellij] $GLOBAL_LAYOUT exists as a regular file — backing up to .bak and replacing with symlink"
  mv "$GLOBAL_LAYOUT" "$GLOBAL_LAYOUT.bak.$(date +%Y%m%d-%H%M%S)"
  ln -s "$REPO_LAYOUT" "$GLOBAL_LAYOUT"
else
  echo "[firm-zellij] creating symlink $GLOBAL_LAYOUT → $REPO_LAYOUT"
  ln -s "$REPO_LAYOUT" "$GLOBAL_LAYOUT"
fi

# (2) Optional preflight — report only, never block. Fallback launcher
# must keep going even if .env / DB checks are red so operator can still
# get a split-view across projects.
PREFLIGHT="$REPO_ROOT/scripts/firm/preflight.sh"
if [[ -x "$PREFLIGHT" ]]; then
  echo "[firm-zellij] running preflight (advisory — failures will NOT block launch)…"
  if ! "$PREFLIGHT"; then
    echo "[firm-zellij] preflight reported issues — continuing anyway (fallback launcher)." >&2
  fi
else
  echo "[firm-zellij] no preflight at $PREFLIGHT — skipping."
fi

# (3) Launch.
echo "[firm-zellij] starting zellij --layout firm8…"
exec zellij --layout firm8
