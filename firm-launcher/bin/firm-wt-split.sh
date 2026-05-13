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

FIRM_ROSTER="${FIRM_ROSTER:-default}"

# --dry-run / -n: print the wt.exe argv array (one arg per line, with indices)
# and exit 0 without launching. Useful for debugging the build of `args`.
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN=1
  shift
fi

# Positional arg overrides FIRM_ROSTER env var (e.g. `firm-wt-split.sh nexus`).
if [[ $# -ge 1 ]]; then
  FIRM_ROSTER="$1"
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

# Roster selection: which 8 (role,project) pairs fill the 2x4 grid.
# Layout/geometry (split actions, --size, mf focus moves) is preserved across
# all presets — only the per-pane (role, project, dir) values change.
# Pane order = creation order shown in the header diagram (top L-to-R, then bottom L-to-R).
case "$FIRM_ROSTER" in
  default)
    # 2 workspace + 4 nexus + 2 thesis (original behaviour)
    roster=(
      "code-1:workspace"        "code-2:workspace"
      "ai-1:nexus"              "ai-2:nexus"
      "ai-3:nexus"              "ai-4:nexus"
      "thesis-1:master-oppgave" "thesis-2:master-oppgave"
    )
    ;;
  nexus|nexus-only)
    # 8 nexus panes (e.g. Karri's workstation)
    roster=(
      "ai-1:nexus" "ai-2:nexus"
      "ai-3:nexus" "ai-4:nexus"
      "ai-5:nexus" "ai-6:nexus"
      "ai-7:nexus" "ai-8:nexus"
    )
    ;;
  thesis|thesis-only)
    # 8 thesis panes
    roster=(
      "thesis-1:master-oppgave" "thesis-2:master-oppgave"
      "thesis-3:master-oppgave" "thesis-4:master-oppgave"
      "thesis-5:master-oppgave" "thesis-6:master-oppgave"
      "thesis-7:master-oppgave" "thesis-8:master-oppgave"
    )
    ;;
  workspace|workspace-only)
    # 8 workspace panes
    roster=(
      "code-1:workspace" "code-2:workspace"
      "code-3:workspace" "code-4:workspace"
      "code-5:workspace" "code-6:workspace"
      "code-7:workspace" "code-8:workspace"
    )
    ;;
  *)
    echo "firm-wt-split: unknown FIRM_ROSTER=$FIRM_ROSTER" >&2
    echo "  valid: default | nexus | thesis | workspace" >&2
    exit 1
    ;;
esac

if [[ "${#roster[@]}" -ne 8 ]]; then
  echo "firm-wt-split: roster must have exactly 8 entries, got ${#roster[@]}" >&2
  exit 1
fi

# Helper: split "role:project" → role, project, dir
# Sets globals R_ROLE, R_PROJECT, R_DIR for the given index.
_pane_lookup() {
  local entry="${roster[$1]}"
  R_ROLE="${entry%%:*}"
  R_PROJECT="${entry#*:}"
  case "$R_PROJECT" in
    workspace)      R_DIR="$CODE_DIR" ;;
    nexus)          R_DIR="$AI_DIR" ;;
    master-oppgave) R_DIR="$THESIS_DIR" ;;
    *)
      echo "firm-wt-split: unknown project '$R_PROJECT' in roster entry '$entry'" >&2
      exit 1
      ;;
  esac
}

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

# 1. new-tab (creates pane 1)
_pane_lookup 0
args+=( new-tab --title "$R_ROLE" wsl.exe --cd "$R_DIR" -- bash -lic "$INIT $R_ROLE $R_PROJECT" )

# 2. split-pane -V (pane 2, right of pane 1)
#    --size 0.75 → new pane takes 75% of pane1; pane1 keeps 25%
_pane_lookup 1
args+=( ";" split-pane -V --size 0.75 wsl.exe --cd "$R_DIR" -- bash -lic "$INIT $R_ROLE $R_PROJECT" )

# 3. split-pane -V (pane 3, right of pane 2)
#    --size 0.667 → new pane takes 2/3 of pane2 (which is 75%); pane2 shrinks to 25%, pane3 = 50%
_pane_lookup 2
args+=( ";" split-pane -V --size 0.667 wsl.exe --cd "$R_DIR" -- bash -lic "$INIT $R_ROLE $R_PROJECT" )

# 4. split-pane -V (pane 4, right of pane 3)
#    --size 0.5 → new pane takes 50% of pane3 (which is 50%); pane3 = 25%, pane4 = 25%
_pane_lookup 3
args+=( ";" split-pane -V --size 0.5 wsl.exe --cd "$R_DIR" -- bash -lic "$INIT $R_ROLE $R_PROJECT" )

# 5. focus back to pane 1 (top-left)
args+=( ";" mf left ";" mf left ";" mf left )

# 6. split-pane -H (pane 5, below pane 1)
#    --size 0.5 → equal top/bottom rows
_pane_lookup 4
args+=( ";" split-pane -H --size 0.5 wsl.exe --cd "$R_DIR" -- bash -lic "$INIT $R_ROLE $R_PROJECT" )

# 7. focus pane 2, split-pane -H (pane 6, below pane 2)
_pane_lookup 5
args+=( ";" mf up ";" mf right )
args+=( ";" split-pane -H --size 0.5 wsl.exe --cd "$R_DIR" -- bash -lic "$INIT $R_ROLE $R_PROJECT" )

# 8. focus pane 3, split-pane -H (pane 7, below pane 3)
_pane_lookup 6
args+=( ";" mf up ";" mf right )
args+=( ";" split-pane -H --size 0.5 wsl.exe --cd "$R_DIR" -- bash -lic "$INIT $R_ROLE $R_PROJECT" )

# 9. focus pane 4, split-pane -H (pane 8, below pane 4)
_pane_lookup 7
args+=( ";" mf up ";" mf right )
args+=( ";" split-pane -H --size 0.5 wsl.exe --cd "$R_DIR" -- bash -lic "$INIT $R_ROLE $R_PROJECT" )

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
