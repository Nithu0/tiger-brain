#!/usr/bin/env bash
# firm-worktree-spawn.sh — opprett (eller gjenfinn) en git worktree for parallell agent-arbeid.
#
# Konvensjon (fra ~/Obsidian/Brain/_decisions/2026-05-14-16-pane-codex-parallell.md):
#   Worktree-path: <repo>/.worktrees/<model>/<slug>/
#   Branch-navn:   <model>/<slug>          (claude/auth-rework, codex/dashboard-mvp)
#
# Bruk:
#   firm-worktree-spawn.sh <model> <repo-path> <slug>
#
# Eksempler:
#   firm-worktree-spawn.sh claude $HOME/code/ai-assistent fix-orb-gate
#   firm-worktree-spawn.sh codex  $HOME/code/ai-assistent refactor-regime
#
# Idempotent: hvis worktree allerede finnes, skriv ut hvor og avslutt 0.
# Branch lages fra repo'ets nåværende HEAD (typisk main) hvis den ikke finnes.

set -euo pipefail

usage() {
  cat >&2 <<EOF
Bruk: $(basename "$0") <model> <repo-path> <slug>

  model      claude | codex
  repo-path  absolutt sti til git-repo (eks. $HOME/code/ai-assistent)
  slug       kort task-id (a-z, 0-9, bindestrek; eks. fix-orb-gate)

Eksempel:
  $(basename "$0") claude $HOME/code/ai-assistent fix-orb-gate
EOF
  exit 2
}

[[ $# -eq 3 ]] || usage

MODEL="$1"
REPO_PATH="$2"
SLUG="$3"

# --- validation ---------------------------------------------------------------

case "$MODEL" in
  claude|codex) ;;
  *) echo "firm-worktree-spawn: model må være 'claude' eller 'codex' (fikk '$MODEL')" >&2; exit 2 ;;
esac

if [[ ! -d "$REPO_PATH" ]]; then
  echo "firm-worktree-spawn: repo-path finnes ikke: $REPO_PATH" >&2
  exit 2
fi

if ! git -C "$REPO_PATH" rev-parse --git-dir >/dev/null 2>&1; then
  echo "firm-worktree-spawn: $REPO_PATH er ikke et git-repo" >&2
  exit 2
fi

# slug må være sane navn: a-z 0-9 bindestrek, ikke start/slutt med bindestrek
if ! [[ "$SLUG" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "firm-worktree-spawn: slug '$SLUG' er ikke gyldig (kun a-z, 0-9, bindestrek; ikke start/slutt på bindestrek)" >&2
  exit 2
fi

BRANCH="${MODEL}/${SLUG}"
WT_REL=".worktrees/${MODEL}/${SLUG}"
WT_PATH="${REPO_PATH}/${WT_REL}"

# --- idempotens: finnes worktree allerede? ------------------------------------

if [[ -d "$WT_PATH" ]] && git -C "$REPO_PATH" worktree list --porcelain | grep -Fxq "worktree $WT_PATH"; then
  echo "[firm-worktree-spawn] worktree finnes allerede: $WT_PATH"
  echo "  branch: $BRANCH"
  echo ""
  echo "Neste skritt:"
  echo "  cd $WT_PATH && claude --dangerously-skip-permissions"
  exit 0
fi

# --- branch: finnes lokalt? ---------------------------------------------------

if git -C "$REPO_PATH" show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  BRANCH_NEW=0
else
  BRANCH_NEW=1
fi

# --- lag worktree -------------------------------------------------------------

mkdir -p "$(dirname "$WT_PATH")"

if [[ "$BRANCH_NEW" -eq 1 ]]; then
  CURRENT_HEAD="$(git -C "$REPO_PATH" rev-parse --abbrev-ref HEAD)"
  echo "[firm-worktree-spawn] oppretter ny branch '$BRANCH' fra '$CURRENT_HEAD'"
  git -C "$REPO_PATH" worktree add -b "$BRANCH" "$WT_PATH" >&2
else
  echo "[firm-worktree-spawn] bruker eksisterende branch '$BRANCH'"
  git -C "$REPO_PATH" worktree add "$WT_PATH" "$BRANCH" >&2
fi

echo ""
echo "[firm-worktree-spawn] opprettet:"
echo "  path:   $WT_PATH"
echo "  branch: $BRANCH"
echo ""
echo "Neste skritt:"
echo "  cd $WT_PATH && claude --dangerously-skip-permissions"
