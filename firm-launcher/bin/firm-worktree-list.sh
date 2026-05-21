#!/usr/bin/env bash
# firm-worktree-list.sh — list alle firm-worktrees på tvers av kjente git-repos.
#
# Format: tabell med kolonner repo, model, slug, branch, last-commit-age.
# "main" / "master" worktrees vises også (markert med model=main).
#
# Bruk:
#   firm-worktree-list.sh

set -euo pipefail

# Kjente git-repos hvor vi forventer firm-worktrees.
REPOS=(
  "$HOME/code/ai-assistent"
  "$HOME/code/Master-oppgave"
  "$HOME/code/battery-electrolyte-predictor"
  "$HOME/code/research-os"
  "$HOME/Obsidian/Brain"
)

# Format-bredder
printf '%-32s  %-7s  %-28s  %-32s  %s\n' "REPO" "MODEL" "SLUG" "BRANCH" "LAST-COMMIT"
printf '%-32s  %-7s  %-28s  %-32s  %s\n' "----" "-----" "----" "------" "-----------"

shorten() {
  # Korter ned absolutt path til ~/... for lesbarhet
  local p="$1"
  echo "${p/#$HOME/~}"
}

for repo in "${REPOS[@]}"; do
  if [[ ! -d "$repo" ]]; then
    continue
  fi
  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    continue
  fi

  # parse `git worktree list --porcelain` blokker
  # hver blokk: "worktree <path>\nHEAD <sha>\nbranch <ref>\n\n"
  current_path=""
  current_branch=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      "worktree "*) current_path="${line#worktree }" ;;
      "branch "*)   current_branch="${line#branch refs/heads/}" ;;
      "detached")   current_branch="(detached)" ;;
      "")
        if [[ -n "$current_path" ]]; then
          # avled model + slug
          rel="${current_path#$repo/}"
          if [[ "$rel" == ".worktrees/"* ]]; then
            # .worktrees/<model>/<slug>
            rest="${rel#.worktrees/}"
            model="${rest%%/*}"
            slug="${rest#*/}"
          elif [[ "$current_path" == "$repo" ]]; then
            model="main"
            slug="-"
          else
            model="?"
            slug="$rel"
          fi

          # last commit age
          if last_age=$(git -C "$current_path" log -1 --format='%cr' 2>/dev/null); then
            :
          else
            last_age="(no commits)"
          fi

          printf '%-32s  %-7s  %-28s  %-32s  %s\n' \
            "$(shorten "$repo")" \
            "$model" \
            "$slug" \
            "${current_branch:-(none)}" \
            "$last_age"

          current_path=""
          current_branch=""
        fi
        ;;
    esac
  done < <(git -C "$repo" worktree list --porcelain)
done
