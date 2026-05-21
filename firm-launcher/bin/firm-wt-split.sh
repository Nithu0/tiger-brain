#!/usr/bin/env bash
# firm-wt-split.sh — open ONE Windows Terminal window with 8 panes (2 rows x 4 cols)
#
# Layout (pane numbers = creation order):
#   +--------+--------+--------+----------+
#   |   1    |   2    |   3    |    4     |  <- top row (created first, L-to-R)
#   | code-1 | code-2 |  ai-1  |   ai-2   |
#   +--------+--------+--------+----------+
#   |   5    |   6    |   7    |    8     |  <- bottom row (split-down from each top pane)
#   |thesis-1|  as-1  |soking-1|personal-1|
#   +--------+--------+--------+----------+
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

# Flag-parsing (rekkefølge-uavhengig):
#   --dry-run / -n  : skriv ut wt.exe argv (én arg per linje) og avslutt 0.
#   --codex         : alle paner peker til codex-worktrees (.worktrees/codex/<slug>/)
#                     i stedet for live branch i repo-root. Default slug = 'latest'.
#                     Krever at codex-worktrees finnes; advarsel + tilbud om å fortsette
#                     hvis noen mangler.
#   --slug <s>      : override slug for --codex (default 'latest').
#
# Default uten flagg = uendret oppførsel (live branch, ingen worktree).
DRY_RUN=0
CODEX=0
CODEX_SLUG="latest"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1; shift ;;
    --codex)      CODEX=1; shift ;;
    --slug)       CODEX_SLUG="${2:?--slug trenger en verdi}"; shift 2 ;;
    --slug=*)     CODEX_SLUG="${1#*=}"; shift ;;
    -h|--help)
      cat <<EOF
Bruk: $(basename "$0") [--dry-run] [--codex [--slug <slug>]]

  --dry-run         vis wt.exe-argv uten å starte
  --codex           alle paner i codex-worktrees (.worktrees/codex/<slug>/)
  --slug <slug>     codex slug (default 'latest')

Eksempler:
  $(basename "$0") --dry-run
  $(basename "$0") --codex --dry-run
  $(basename "$0") --codex --slug exp-2026-05-14
EOF
      exit 0
      ;;
    *) echo "firm-wt-split: ukjent flag '$1' (bruk --help)" >&2; exit 2 ;;
  esac
done

WT_EXE="/mnt/c/Users/nithu/AppData/Local/Microsoft/WindowsApps/wt.exe"
if [[ ! -x "$WT_EXE" ]]; then
  WT_EXE="$(command -v wt.exe || true)"
fi
if [[ -z "${WT_EXE:-}" || ! -x "$WT_EXE" ]]; then
  echo "firm-wt-split: wt.exe not found" >&2
  exit 1
fi

INIT="$HOME/code/command-center/_bin/firm-tab-init.sh"
if [[ ! -x "$INIT" ]]; then
  echo "firm-wt-split: init script missing: $INIT" >&2
  exit 1
fi

CODE_DIR="$HOME/code"
AI_DIR="$HOME/code/ai-assistent"
THESIS_DIR="$HOME/code/Master-oppgave"
AS_DIR="$HOME/code/AS"
# NB: SOKING_DIR inneholder mellomrom — alltid sitér ved bruk.
SOKING_DIR="$HOME/code/Søking fulltid"
PERSONAL_DIR="$HOME/code/Personlig"

# --codex: pek alle paner til codex-worktree under <repo>/.worktrees/codex/<slug>/
# Verifiser at hver eksisterer; advar (men fortsett) hvis noen mangler.
if [[ "$CODEX" -eq 1 ]]; then
  CODEX_WT_REL=".worktrees/codex/${CODEX_SLUG}"
  declare -a _missing=()
  for base_var in CODE_DIR AI_DIR THESIS_DIR AS_DIR SOKING_DIR PERSONAL_DIR; do
    base="${!base_var}"
    wt_path="${base}/${CODEX_WT_REL}"
    if [[ ! -d "$wt_path" ]]; then
      _missing+=( "$wt_path" )
    fi
    # rebind variabelen til worktree-pathen (selv hvis missing — bruker advares under)
    printf -v "$base_var" '%s' "$wt_path"
  done

  if [[ "${#_missing[@]}" -gt 0 ]]; then
    echo "[firm-wt-split] ADVARSEL — codex-worktrees mangler for slug '$CODEX_SLUG':" >&2
    for m in "${_missing[@]}"; do echo "  - $m" >&2; done
    echo "" >&2
    echo "Lag dem først, f.eks.:" >&2
    echo "  $HOME/code/command-center/_bin/firm-worktree-spawn.sh codex $HOME/code/ai-assistent $CODEX_SLUG" >&2
    echo "" >&2
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[firm-wt-split] (fortsetter likevel siden --dry-run er satt)" >&2
    else
      echo "firm-wt-split: avbryter. Lag worktrees eller kjør med --dry-run for å inspisere." >&2
      exit 1
    fi
  fi
fi

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
args+=( ";" split-pane -V --title "code-2" --size 0.75 wsl.exe --cd "$CODE_DIR" -- bash -lic "$INIT code-2 workspace" )

# 3. split-pane -V (pane 3 = ai-1, right of pane 2)
#    --size 0.667 → new pane takes 2/3 of pane2 (which is 75%); pane2 shrinks to 25%, pane3 = 50%
args+=( ";" split-pane -V --title "ai-1" --size 0.667 wsl.exe --cd "$AI_DIR" -- bash -lic "$INIT ai-1 nexus" )

# 4. split-pane -V (pane 4 = ai-2, right of pane 3)
#    --size 0.5 → new pane takes 50% of pane3 (which is 50%); pane3 = 25%, pane4 = 25%
args+=( ";" split-pane -V --title "ai-2" --size 0.5 wsl.exe --cd "$AI_DIR" -- bash -lic "$INIT ai-2 nexus" )

# Fokus er allerede på pane 4 (ai-2, top-right) etter siste -V splitten.
# Vi splittene bunn-rad høyre→venstre for å unngå asymmetrisk navigasjon-bug.
# Sekvens: split -H i aktiv pane (lager pane under), mf up (tilbake til top),
# mf left (én pane til venstre), gjenta.

# 5. split-pane -H (pane 5 = personal-1, below pane 4 = ai-2)
args+=( ";" split-pane -H --title "personal-1" --size 0.5 wsl.exe --cd "$PERSONAL_DIR" -- bash -lic "$INIT personal-1 personlig" )

# 6. focus pane 3 (ai-1), split-pane -H (pane 6 = soking-1, below pane 3)
#    NB: SOKING_DIR har mellomrom — dobbel-fnutter rundt variabelen er nødvendig.
args+=( ";" mf up ";" mf left )
args+=( ";" split-pane -H --title "soking-1" --size 0.5 wsl.exe --cd "$SOKING_DIR" -- bash -lic "$INIT soking-1 soking-fulltid" )

# 7. focus pane 2 (code-2), split-pane -H (pane 7 = as-1, below pane 2)
args+=( ";" mf up ";" mf left )
args+=( ";" split-pane -H --title "as-1" --size 0.5 wsl.exe --cd "$AS_DIR" -- bash -lic "$INIT as-1 AS" )

# 8. focus pane 1 (code-1), split-pane -H (pane 8 = thesis-1, below pane 1)
args+=( ";" mf up ";" mf left )
args+=( ";" split-pane -H --title "thesis-1" --size 0.5 wsl.exe --cd "$THESIS_DIR" -- bash -lic "$INIT thesis-1 master-oppgave" )

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  if [[ "$CODEX" -eq 1 ]]; then
    echo "[firm-wt-split] DRY-RUN (codex-modus, slug='$CODEX_SLUG') — would launch wt.exe with these args:"
  else
    echo "[firm-wt-split] DRY-RUN — would launch wt.exe with these args:"
  fi
  echo "  wt.exe \\"
  i=0
  for a in "${args[@]}"; do
    i=$((i+1))
    printf '    [%2d] %q\n' "$i" "$a"
  done
  exit 0
fi

if [[ "$CODEX" -eq 1 ]]; then
  echo "[firm-wt-split] launching 8 panes (2x4 grid, codex-modus slug='$CODEX_SLUG') via wt.exe…"
else
  echo "[firm-wt-split] launching 8 panes (2x4 grid) via wt.exe…"
fi
exec "$WT_EXE" "${args[@]}"
