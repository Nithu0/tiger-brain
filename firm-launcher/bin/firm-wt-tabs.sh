#!/usr/bin/env bash
# firm-wt-tabs.sh — open 8 Windows Terminal tabs in ONE new WT window, each
# running the firm-tab-init.sh bootstrapper for its assigned role.
#
# Why this script exists + 2 historical bugs to NOT reintroduce:
#
#   Bug 1 (fixed): a multi-line `cat <<EOF` heredoc inside `bash -lic "..."`
#                  → wt.exe split argv on newlines → 0x80070002 ERROR_FILE_NOT_FOUND.
#                  Fix: keep the inner command single-line (no heredoc, no
#                  multi-line strings).
#
#   Bug 2 (fixed): wrapping the single-line inner command in LITERAL single
#                  quotes ('$INIT $role $project') → bash -c strips quotes
#                  but keeps contents as ONE WORD with spaces → exit 127
#                  "No such file or directory". Fix: pass UNQUOTED so bash
#                  word-splits cmd + args correctly. Our values have no
#                  spaces so this is safe.

set -euo pipefail

# --- arg parsing ------------------------------------------------------------
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN=1
  shift
fi

# --- locate wt.exe ----------------------------------------------------------
# Portable: WSL-interop PATH first, then any Windows user's WindowsApps dir
# (glob — works regardless of the Windows username).
WT="$(command -v wt.exe 2>/dev/null || true)"
if [[ -z "${WT:-}" || ! -x "$WT" ]]; then
  for cand in /mnt/c/Users/*/AppData/Local/Microsoft/WindowsApps/wt.exe; do
    [[ -x "$cand" ]] && { WT="$cand"; break; }
  done
fi
if [[ -z "${WT:-}" || ! -x "$WT" ]]; then
  echo "firm-wt-tabs.sh: wt.exe not found (PATH or /mnt/c/Users/*/...WindowsApps)" >&2
  echo "  install Windows Terminal, or set WT manually" >&2
  exit 1
fi

INIT="$HOME/code/command-center/_bin/firm-tab-init.sh"
if [[ ! -x "$INIT" ]]; then
  echo "firm-wt-tabs.sh: init script missing or not executable: $INIT" >&2
  exit 1
fi

# --- tab distribution -------------------------------------------------------
# Bruker parallelle arrays i stedet for space-splittede strenger fordi
# soking-1's CWD inneholder mellomrom ("Søking fulltid"). Tab-rekkefølgen
# speiler den nye 2x4 grid-distribusjonen i firm-wt-split.sh:
#   Row 1: code-1, code-2 (workspace), ai-1, ai-2 (nexus)
#   Row 2: thesis-1 (master-oppgave), as-1 (AS), soking-1 (soking-fulltid),
#          personal-1 (personlig)
roles=(    "code-1"            "code-2"            "ai-1"                          "ai-2"                          "thesis-1"                          "as-1"                "soking-1"                          "personal-1" )
paths=(    "$HOME/code"  "$HOME/code"  "$HOME/code/ai-assistent" "$HOME/code/ai-assistent" "$HOME/code/Master-oppgave"   "$HOME/code/AS" "$HOME/code/Søking fulltid"   "$HOME/code/Personlig" )
projects=( "workspace"         "workspace"         "nexus"                         "nexus"                         "master-oppgave"                    "AS"                  "soking-fulltid"                    "personlig" )

# --- build wt.exe argv ------------------------------------------------------
# We pass each action as a separate argv group, with literal `;` separators
# in their own argv slots. wt.exe treats a standalone `;` arg as an action
# delimiter — this avoids any shell-quoting fragility around the separator.
args=()

first=1
for i in "${!roles[@]}"; do
  role="${roles[$i]}"
  path="${paths[$i]}"
  project="${projects[$i]}"

  # Inner command for `bash -lic <CMD>`. Must be a single-line string (no
  # heredoc, no $(), no double-quote interpolation). Do NOT wrap in single
  # quotes — bash -c would strip them and keep the contents as ONE word,
  # producing "No such file or directory" for a path-with-spaces. Pass
  # UNQUOTED so bash word-splits cmd + args correctly. Our values have no
  # spaces so this is safe.
  inner="${INIT} ${role} ${project}"

  if [[ $first -eq 1 ]]; then
    args+=( new-tab --title "$role" wsl.exe --cd "$path" -- bash -lic "$inner" )
    first=0
  else
    args+=( ";" new-tab --title "$role" wsl.exe --cd "$path" -- bash -lic "$inner" )
  fi
done

# --- launch -----------------------------------------------------------------
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'firm-wt-tabs.sh: --dry-run — would exec %q with %d args:\n' "$WT" "${#args[@]}"
  i=0
  for a in "${args[@]}"; do
    printf '  [%2d] %q\n' "$i" "$a"
    i=$((i + 1))
  done
  exit 0
fi

exec "$WT" "${args[@]}"
