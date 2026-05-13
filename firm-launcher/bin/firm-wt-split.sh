#!/usr/bin/env bash
# firm-wt-split.sh — open ONE Windows Terminal window with 8 panes (2 rows x 4 cols)
#
# Layout (pane numbers = creation order):
#   +--------+--------+--------+--------+
#   |   1    |   2    |   3    |   4    |   <- top row (created first, L-to-R)
#   | code-1 | code-2 |  ai-1  |  ai-2  |
#   +--------+--------+--------+--------+
#   |   5    |   6    |   7    |   8    |   <- bottom row (split-down from each top pane)
#   |  ai-3  |  ai-4  |thesis-1|thesis-2|
#   +--------+--------+--------+--------+
#
# Each pane runs (directly, no outer bash -c wrap):
#   wsl.exe --cd <abs-path> -- bash -lic '<INIT> <role> <project>'
#
# The single-quoted inner string is the contract that keeps wt.exe from
# choking — it must stay single-line, no heredoc, no $(...) inside.
#
# WT pane-split semantics:
#   split-pane -V  -> creates pane to the RIGHT (side-by-side, "vertical split")
#   split-pane -H  -> creates pane BELOW (stacked, "horizontal split")
#   move-focus (mf) -> shift focus to a neighbour pane

set -euo pipefail

# --dry-run / -n: print the wt.exe argv array (one arg per line, with indices)
# and exit 0 without launching. Useful for debugging the build of `args`.
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN=1
  shift
fi

WT_EXE="/mnt/c/Users/nithu/AppData/Local/Microsoft/WindowsApps/wt.exe"
if [[ ! -x "$WT_EXE" ]]; then
  WT_EXE="$(command -v wt.exe || true)"
fi
if [[ -z "${WT_EXE:-}" || ! -x "$WT_EXE" ]]; then
  echo "firm-wt-split: wt.exe not found" >&2
  exit 1
fi

INIT="${FIRM_BIN_DIR:-$HOME/code/_bin}/firm-tab-init.sh"
if [[ ! -x "$INIT" ]]; then
  echo "firm-wt-split: init script missing: $INIT" >&2
  exit 1
fi

CODE_DIR="${CODE_DIR:-$HOME/code}"
AI_DIR="${NEXUS_REPO:-$HOME/code/ai-assistent}"
THESIS_DIR="${THESIS_REPO:-$HOME/code/Master-oppgave}"

# Per-pane invocation:
#   wt.exe action ... -- wsl.exe --cd <path> -- bash -lic '<INIT> <role> <project>'
#
# We pass wsl.exe directly to wt.exe as the pane's program. No `bash -c` wrap on
# the Windows side. The inner shell command (`<INIT> <role> <project>`) is a
# single-quoted single-line string so wt.exe's argv parser doesn't split it.

# Action separator: a standalone `;` argv element (literal, no shell expansion).
# Build the argv as a bash array.
args=( -w new )

# NOTE: bash -lic <CMD> parses CMD as shell. If we wrap in single quotes
# ('<INIT> role project'), bash strips the quotes but keeps the contents
# as ONE word — then tries to exec the whole thing as a single program
# name with spaces. That's a "No such file or directory" bug. So: pass
# UNQUOTED so bash word-splits cmd + args correctly. Our role/project
# values have no spaces so no further quoting is needed.

# 1. new-tab (creates pane 1 = code-1)
args+=( new-tab --title "code-1" wsl.exe --cd "$CODE_DIR" -- bash -lic "$INIT code-1 workspace" )

# 2. split-pane -V (pane 2 = code-2, right of pane 1)
#    --size 0.75 → new pane takes 75% of pane1; pane1 keeps 25%
args+=( ";" split-pane -V --size 0.75 wsl.exe --cd "$CODE_DIR" -- bash -lic "$INIT code-2 workspace" )

# 3. split-pane -V (pane 3 = ai-1, right of pane 2)
#    --size 0.667 → new pane takes 2/3 of pane2 (which is 75%); pane2 shrinks to 25%, pane3 = 50%
args+=( ";" split-pane -V --size 0.667 wsl.exe --cd "$AI_DIR" -- bash -lic "$INIT ai-1 nexus" )

# 4. split-pane -V (pane 4 = ai-2, right of pane 3)
#    --size 0.5 → new pane takes 50% of pane3 (which is 50%); pane3 = 25%, pane4 = 25%
args+=( ";" split-pane -V --size 0.5 wsl.exe --cd "$AI_DIR" -- bash -lic "$INIT ai-2 nexus" )

# 5. focus back to pane 1 (top-left)
args+=( ";" mf left ";" mf left ";" mf left )

# 6. split-pane -H (pane 5 = ai-3, below pane 1)
#    --size 0.5 → equal top/bottom rows
args+=( ";" split-pane -H --size 0.5 wsl.exe --cd "$AI_DIR" -- bash -lic "$INIT ai-3 nexus" )

# 7. focus pane 2, split-pane -H (pane 6 = ai-4, below pane 2)
args+=( ";" mf up ";" mf right )
args+=( ";" split-pane -H --size 0.5 wsl.exe --cd "$AI_DIR" -- bash -lic "$INIT ai-4 nexus" )

# 8. focus pane 3, split-pane -H (pane 7 = thesis-1, below pane 3)
args+=( ";" mf up ";" mf right )
args+=( ";" split-pane -H --size 0.5 wsl.exe --cd "$THESIS_DIR" -- bash -lic "$INIT thesis-1 master-oppgave" )

# 9. focus pane 4, split-pane -H (pane 8 = thesis-2, below pane 4)
args+=( ";" mf up ";" mf right )
args+=( ";" split-pane -H --size 0.5 wsl.exe --cd "$THESIS_DIR" -- bash -lic "$INIT thesis-2 master-oppgave" )

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "[firm-wt-split] DRY-RUN — would launch wt.exe with these args:"
  echo "  wt.exe \\"
  i=0
  for a in "${args[@]}"; do
    i=$((i+1))
    printf '    [%2d] %q\n' "$i" "$a"
  done
  exit 0
fi

echo "[firm-wt-split] launching 8 panes (2x4 grid) via wt.exe…"
exec "$WT_EXE" "${args[@]}"
