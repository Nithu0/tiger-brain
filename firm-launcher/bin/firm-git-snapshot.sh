#!/usr/bin/env bash
# firm-git-snapshot.sh
#
# Itererer over kjente git-repoer og skriver én aggregert JSON-fil
# (~/Obsidian/Brain/00-firm-bus/git-snapshot.json) med per-repo status:
#   - branch
#   - ahead/behind vs. upstream (hvis det finnes)
#   - uncommitted-count (modified + untracked, tracked via `git status --porcelain`)
#   - last-commit sha, message, age_minutes
#
# Trigges av cron (anbefalt hvert 2.–5. minutt) eller manuelt.
# Atomic write (tmpfile + mv).

set -euo pipefail

REPOS=(
  "$HOME/code/ai-assistent"
  "${HOME}/Obsidian/Brain"
)

DEST="${HOME}/Obsidian/Brain/00-firm-bus/git-snapshot.json"
DEST_DIR="$(dirname "$DEST")"
mkdir -p "$DEST_DIR"

NOW_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NOW_EPOCH="$(date -u +%s)"

# Bygg array av repo-objekter via jq.
REPOS_JSON="[]"

for repo in "${REPOS[@]}"; do
  if [[ ! -d "$repo/.git" ]]; then
    # Repo-path eksisterer ikke eller er ikke et git-repo. Logg som "missing".
    REPOS_JSON="$(jq -n \
      --argjson existing "$REPOS_JSON" \
      --arg path "$repo" \
      '$existing + [{
        path: $path,
        name: ($path | split("/") | last),
        status: "missing"
      }]')"
    continue
  fi

  # Per-repo data, kjør i subshell for å unngå cwd-leak.
  branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"

  # ahead/behind vs. upstream — kan feile hvis ingen upstream.
  ahead=0
  behind=0
  if git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    counts="$(git -C "$repo" rev-list --left-right --count '@{u}'...HEAD 2>/dev/null || echo "0	0")"
    behind="$(echo "$counts" | awk '{print $1}')"
    ahead="$(echo "$counts" | awk '{print $2}')"
  fi

  uncommitted="$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  last_sha="$(git -C "$repo" log -1 --format=%H 2>/dev/null || echo "")"
  last_short="$(git -C "$repo" log -1 --format=%h 2>/dev/null || echo "")"
  last_msg="$(git -C "$repo" log -1 --format=%s 2>/dev/null || echo "")"
  last_epoch="$(git -C "$repo" log -1 --format=%ct 2>/dev/null || echo "0")"

  age_minutes=0
  if [[ "$last_epoch" -gt 0 ]]; then
    age_minutes=$(( (NOW_EPOCH - last_epoch) / 60 ))
  fi

  REPOS_JSON="$(jq -n \
    --argjson existing "$REPOS_JSON" \
    --arg path "$repo" \
    --arg name "$(basename "$repo")" \
    --arg branch "$branch" \
    --argjson ahead "$ahead" \
    --argjson behind "$behind" \
    --argjson uncommitted "$uncommitted" \
    --arg last_sha "$last_sha" \
    --arg last_short "$last_short" \
    --arg last_msg "$last_msg" \
    --argjson age_minutes "$age_minutes" \
    '$existing + [{
      path: $path,
      name: $name,
      status: "ok",
      branch: $branch,
      ahead: $ahead,
      behind: $behind,
      uncommitted: $uncommitted,
      last_sha: $last_sha,
      last_short: $last_short,
      last_msg: $last_msg,
      age_minutes: $age_minutes
    }]')"
done

TMP="$(mktemp "${DEST_DIR}/.git-snapshot.json.XXXXXX")"
trap 'rm -f "$TMP" 2>/dev/null || true' EXIT

jq -n \
  --arg generated_at "$NOW_ISO" \
  --argjson repos "$REPOS_JSON" \
  '{ generated_at: $generated_at, repos: $repos }' > "$TMP"

mv -f "$TMP" "$DEST"
trap - EXIT
exit 0
