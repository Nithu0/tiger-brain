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
WT_DEFAULT="/mnt/c/Users/nithu/AppData/Local/Microsoft/WindowsApps/wt.exe"
if [[ -x "$WT_DEFAULT" ]]; then
  WT="$WT_DEFAULT"
elif command -v wt.exe >/dev/null 2>&1; then
  WT="$(command -v wt.exe)"
else
  echo "firm-wt-tabs.sh: wt.exe not found at $WT_DEFAULT and not on PATH" >&2
  echo "  install Windows Terminal or set WT manually" >&2
  exit 1
fi

INIT="${FIRM_BIN_DIR:-$HOME/code/_bin}/firm-tab-init.sh"
if [[ ! -x "$INIT" ]]; then
  echo "firm-wt-tabs.sh: init script missing or not executable: $INIT" >&2
  exit 1
fi

# --- tab distribution -------------------------------------------------------
# Each row: <role> <abs-wsl-path> <project>
# code-1, code-2     -> $CODE_DIR              (workspace)
# ai-1..ai-4         -> $NEXUS_REPO            (nexus)
# thesis-1, thesis-2 -> $THESIS_REPO           (master-oppgave)
CODE_DIR="${CODE_DIR:-$HOME/code}"
NEXUS_REPO="${NEXUS_REPO:-$HOME/code/ai-assistent}"
THESIS_REPO="${THESIS_REPO:-$HOME/code/Master-oppgave}"
tabs=(
  "code-1   $CODE_DIR     workspace"
  "code-2   $CODE_DIR     workspace"
  "ai-1     $NEXUS_REPO   nexus"
  "ai-2     $NEXUS_REPO   nexus"
  "ai-3     $NEXUS_REPO   nexus"
  "ai-4     $NEXUS_REPO   nexus"
  "thesis-1 $THESIS_REPO  master-oppgave"
  "thesis-2 $THESIS_REPO  master-oppgave"
)

# --- build wt.exe argv ------------------------------------------------------
# We pass each action as a separate argv group, with literal `;` separators
# in their own argv slots. wt.exe treats a standalone `;` arg as an action
# delimiter — this avoids any shell-quoting fragility around the separator.
args=()

first=1
for row in "${tabs[@]}"; do
  # shellcheck disable=SC2206
  parts=( $row )                # role path project (no spaces inside fields)
  role="${parts[0]}"
  path="${parts[1]}"
  project="${parts[2]}"

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
