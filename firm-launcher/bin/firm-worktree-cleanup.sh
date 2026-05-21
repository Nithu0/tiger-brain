#!/usr/bin/env bash
# firm-worktree-cleanup.sh — rydd opp i firm-worktrees som er ferdige eller stale.
#
# Default: TØRR-KJØRING. Viser hvilke worktrees som er kandidater for sletting
# (clean working tree + ingen unpushed commits, eller eldre enn N dager).
# Sletter ingenting uten --force.
#
# Bruk:
#   firm-worktree-cleanup.sh                          # vis alt (alle kandidater)
#   firm-worktree-cleanup.sh --older-than-days 7      # filtrer på alder
#   firm-worktree-cleanup.sh --force                  # faktisk slett
#   firm-worktree-cleanup.sh --force --older-than-days 14
#
# Aldri rør:
#   - main / master worktrees
#   - worktrees med uncommitted endringer (med mindre --force-dirty satt)

set -euo pipefail

FORCE=0
OLDER_THAN_DAYS=""
FORCE_DIRTY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)             FORCE=1; shift ;;
    --force-dirty)       FORCE_DIRTY=1; shift ;;
    --older-than-days)   OLDER_THAN_DAYS="${2:?--older-than-days trenger et tall}"; shift 2 ;;
    --older-than-days=*) OLDER_THAN_DAYS="${1#*=}"; shift ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "firm-worktree-cleanup: ukjent flag '$1'" >&2; exit 2 ;;
  esac
done

if [[ -n "$OLDER_THAN_DAYS" && ! "$OLDER_THAN_DAYS" =~ ^[0-9]+$ ]]; then
  echo "firm-worktree-cleanup: --older-than-days må være et ikke-negativt heltall" >&2
  exit 2
fi

REPOS=(
  "$HOME/code/ai-assistent"
  "$HOME/code/Master-oppgave"
  "$HOME/code/battery-electrolyte-predictor"
  "$HOME/code/research-os"
  "$HOME/Obsidian/Brain"
)

now_epoch=$(date +%s)

if [[ "$FORCE" -eq 1 ]]; then
  echo "[firm-worktree-cleanup] FORCE-modus: vil faktisk slette."
else
  echo "[firm-worktree-cleanup] TØRR-KJØRING (legg til --force for å faktisk slette)."
fi
if [[ -n "$OLDER_THAN_DAYS" ]]; then
  echo "[firm-worktree-cleanup] filter: bare worktrees eldre enn $OLDER_THAN_DAYS dager."
fi
echo ""

deleted=0
skipped=0
candidates=0

for repo in "${REPOS[@]}"; do
  [[ -d "$repo" ]] || continue
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || continue

  current_path=""
  current_branch=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      "worktree "*) current_path="${line#worktree }" ;;
      "branch "*)   current_branch="${line#branch refs/heads/}" ;;
      "detached")   current_branch="(detached)" ;;
      "")
        if [[ -n "$current_path" ]]; then
          rel="${current_path#$repo/}"

          # Skip main repo (path == repo)
          if [[ "$current_path" == "$repo" ]]; then
            current_path=""
            current_branch=""
            continue
          fi
          # Skip ikke-firm worktrees
          if [[ "$rel" != ".worktrees/"* ]]; then
            current_path=""
            current_branch=""
            continue
          fi

          # Sjekk alder
          if last_epoch=$(git -C "$current_path" log -1 --format='%ct' 2>/dev/null); then
            age_days=$(( (now_epoch - last_epoch) / 86400 ))
          else
            age_days=0
          fi
          age_pretty=$(git -C "$current_path" log -1 --format='%cr' 2>/dev/null || echo "(no commits)")

          # Filter på alder hvis satt
          if [[ -n "$OLDER_THAN_DAYS" && "$age_days" -lt "$OLDER_THAN_DAYS" ]]; then
            current_path=""
            current_branch=""
            continue
          fi

          # Sjekk om clean
          dirty=""
          if [[ -n "$(git -C "$current_path" status --porcelain 2>/dev/null)" ]]; then
            dirty="dirty"
          fi

          candidates=$((candidates+1))
          short_path="${current_path/#$HOME/~}"
          echo "  [$candidates] $short_path"
          echo "       branch:    ${current_branch:-(none)}"
          echo "       last:      $age_pretty (${age_days}d)"
          echo "       dirty:     ${dirty:-clean}"

          if [[ -n "$dirty" && "$FORCE_DIRTY" -ne 1 ]]; then
            echo "       action:    SKIP (uncommitted endringer; bruk --force-dirty for å overstyre)"
            skipped=$((skipped+1))
          elif [[ "$FORCE" -eq 1 ]]; then
            echo "       action:    SLETTER worktree + branch"
            extra=""
            [[ "$FORCE_DIRTY" -eq 1 ]] && extra="--force"
            if git -C "$repo" worktree remove $extra "$current_path" 2>&1 | sed 's/^/         /'; then
              if [[ -n "$current_branch" && "$current_branch" != "(detached)" ]]; then
                git -C "$repo" branch -D "$current_branch" 2>&1 | sed 's/^/         /' || true
              fi
              deleted=$((deleted+1))
            else
              echo "         (worktree remove feilet)"
            fi
          else
            echo "       action:    (ville slettet — legg til --force)"
          fi
          echo ""

          current_path=""
          current_branch=""
        fi
        ;;
    esac
  done < <(git -C "$repo" worktree list --porcelain)
done

echo "[firm-worktree-cleanup] kandidater: $candidates  slettet: $deleted  hoppet over: $skipped"
