#!/usr/bin/env bash
# Run ONCE after initial GH setup to verify gates work. NOT for ongoing testing —
# runs against the real repo, creates real (then-deleted) PRs.
#
# Verifies path-guard + CODEOWNERS + brain-checks CI gates by opening 4 PRs and
# inspecting their CI results. Each branch + PR is cleaned up at the end.
#
# Usage:
#   ./smoke-test-pr.sh [--repo <owner>/<name>] [--skip <test>] [--keep] [--dry-run]
#
# Requires: gh CLI (authenticated), git, openssl, jq optional.

set -euo pipefail

# --- defaults ------------------------------------------------------------
REPO=""
SKIP_TESTS=()
KEEP_BRANCHES=0
DRY_RUN=0
TODAY="$(date +%Y-%m-%d)"
VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- arg parsing ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)    REPO="$2"; shift 2 ;;
    --skip)    SKIP_TESTS+=("$2"); shift 2 ;;
    --keep)    KEEP_BRANCHES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

cd "$VAULT_ROOT"

if [[ -z "$REPO" ]]; then
  origin_url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "$origin_url" ]]; then
    echo "ERROR: no --repo given and no origin remote." >&2; exit 2
  fi
  REPO="$(echo "$origin_url" \
    | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
fi

# --- preflight -----------------------------------------------------------
command -v gh  >/dev/null || { echo "ERROR: gh CLI not installed"; exit 2; }
command -v git >/dev/null || { echo "ERROR: git not installed";    exit 2; }
command -v openssl >/dev/null || { echo "ERROR: openssl not installed"; exit 2; }
gh auth status >/dev/null 2>&1 || { echo "ERROR: gh not authenticated"; exit 2; }

echo "Repo:        $REPO"
echo "Vault root:  $VAULT_ROOT"
echo "Date tag:    $TODAY"
echo "Dry run:     $DRY_RUN"
echo "Keep:        $KEEP_BRANCHES"
echo "Skip tests:  ${SKIP_TESTS[*]:-(none)}"
echo

# --- state for cleanup ---------------------------------------------------
declare -a OPEN_PRS=()
declare -a OPEN_BRANCHES=()
ORIG_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
STARTED_AT="$(date -u +%FT%TZ)"

cleanup() {
  set +e
  echo
  echo "--- cleanup ---"
  # Try to close any remaining PRs (in case of mid-run abort)
  for pr in "${OPEN_PRS[@]:-}"; do
    [[ -n "$pr" ]] || continue
    echo "Closing leftover PR #$pr (delete-branch)…"
    gh pr close "$pr" --repo "$REPO" --delete-branch >/dev/null 2>&1 || true
  done
  # Drop any stale local branches
  for br in "${OPEN_BRANCHES[@]:-}"; do
    [[ -n "$br" ]] || continue
    git branch -D "$br" >/dev/null 2>&1 || true
  done
  # Restore worktree
  git checkout -- . >/dev/null 2>&1 || true
  git checkout "$ORIG_BRANCH" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# --- helpers -------------------------------------------------------------
skipped() {
  local name="$1"
  for s in "${SKIP_TESTS[@]:-}"; do [[ "$s" == "$name" ]] && return 0; done
  return 1
}

run() {
  # Echo + execute (or just echo under --dry-run)
  echo "  \$ $*"
  [[ "$DRY_RUN" -eq 1 ]] && return 0
  eval "$@"
}

# Wait for CI on a PR, return overall conclusion in stdout: pass|fail|unknown
wait_ci() {
  local pr="$1"
  if [[ "$DRY_RUN" -eq 1 ]]; then echo "pass"; return; fi
  # --watch blocks until all checks finish; exit code 0=pass, 8=fail, others=unknown
  if gh pr checks "$pr" --repo "$REPO" --watch >/dev/null 2>&1; then
    echo "pass"
  else
    local rc=$?
    if [[ "$rc" -eq 8 ]]; then echo "fail"; else echo "unknown"; fi
  fi
}

# Result row: name|expected|actual|verdict
declare -a RESULTS=()
record() { RESULTS+=("$1|$2|$3|$4"); }

start_test() {
  local name="$1" branch="$2"
  echo
  echo "============================================================"
  echo "  $name  (branch: $branch)"
  echo "============================================================"
  run "git checkout main"
  run "git pull --ff-only origin main"
  run "git checkout -b '$branch'"
  OPEN_BRANCHES+=("$branch")
}

commit_and_push() {
  local branch="$1" msg="$2"
  run "git add -A"
  run "git commit -m '$msg

OPERATOR-APPROVED: smoke test'"
  run "git push -u origin '$branch'"
}

close_pr() {
  local pr="$1"
  [[ -z "$pr" ]] && return 0
  if [[ "$KEEP_BRANCHES" -eq 1 ]]; then
    run "gh pr close '$pr' --repo '$REPO'"
  else
    run "gh pr close '$pr' --repo '$REPO' --delete-branch"
  fi
  # Remove from open list
  local new=()
  for x in "${OPEN_PRS[@]:-}"; do [[ "$x" != "$pr" ]] && new+=("$x"); done
  OPEN_PRS=("${new[@]:-}")
}

open_pr() {
  local title="$1" body="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then echo "DRYRUN-PR"; return; fi
  local url
  url="$(gh pr create --repo "$REPO" --base main --title "$title" --body "$body")"
  # Extract PR number from URL tail
  basename "$url"
}

# --- TEST-1: allowed path -----------------------------------------------
if ! skipped TEST-1; then
  BR="smoke/01-nexus-allowed-$TODAY"
  start_test "TEST-1 allowed-path" "$BR"
  run "echo '<!-- smoke test -->' >> 01-nexus/Nexus-MOC.md"
  commit_and_push "$BR" "smoke: TEST-1 allowed path append"
  PR="$(open_pr "smoke TEST-1: allowed path" "Allowed-path smoke test. Expect CI green.")"
  OPEN_PRS+=("$PR")
  RES="$(wait_ci "$PR")"
  record "TEST-1 allowed" "pass" "$RES" "$([[ "$RES" == pass ]] && echo PASS || echo FAIL)"
  close_pr "$PR"
fi

# --- TEST-2: protected path, no override --------------------------------
if ! skipped TEST-2; then
  BR="smoke/protected-blocked-$TODAY"
  start_test "TEST-2 protected-no-override" "$BR"
  run "echo '<!-- smoke -->' >> _decisions/When-Trade-Bleeds-Multi-Day.md"
  # local commit needs override so the pre-commit/local guard doesn't block us
  commit_and_push "$BR" "smoke: TEST-2 protected (no override in PR body)"
  PR="$(open_pr "smoke TEST-2: protected, no override" "smoke test, should fail")"
  OPEN_PRS+=("$PR")
  RES="$(wait_ci "$PR")"
  record "TEST-2 protected-blocked" "fail" "$RES" "$([[ "$RES" == fail ]] && echo PASS || echo FAIL)"
  close_pr "$PR"
fi

# --- TEST-3: protected path, with override ------------------------------
if ! skipped TEST-3; then
  BR="smoke/protected-approved-$TODAY"
  start_test "TEST-3 protected-with-override" "$BR"
  run "echo '<!-- smoke approved -->' >> _decisions/When-Trade-Bleeds-Multi-Day.md"
  commit_and_push "$BR" "smoke: TEST-3 protected with override"
  PR="$(open_pr "smoke TEST-3: protected with override" \
       "OPERATOR-APPROVED: smoke test — should pass path-guard")"
  OPEN_PRS+=("$PR")
  RES="$(wait_ci "$PR")"
  record "TEST-3 protected-override" "pass" "$RES" "$([[ "$RES" == pass ]] && echo PASS || echo FAIL)"
  close_pr "$PR"
fi

# --- TEST-4: secret leak -------------------------------------------------
if ! skipped TEST-4; then
  BR="smoke/secret-leak-$TODAY"
  start_test "TEST-4 secret-leak" "$BR"
  # Fake-looking GitHub PAT; should trip the secret scan in brain-checks
  FAKE_PAT="ghp_$(openssl rand -hex 20)"
  run "printf '%s\n' '$FAKE_PAT' >> 01-nexus/Nexus-MOC.md"
  commit_and_push "$BR" "smoke: TEST-4 fake secret leak"
  PR="$(open_pr "smoke TEST-4: secret leak" "Secret-scan smoke test. Expect brain-checks fail.")"
  OPEN_PRS+=("$PR")
  RES="$(wait_ci "$PR")"
  record "TEST-4 secret-leak" "fail" "$RES" "$([[ "$RES" == fail ]] && echo PASS || echo FAIL)"
  close_pr "$PR"
fi

# --- report --------------------------------------------------------------
echo
echo "============================================================"
echo "  smoke-test-pr.sh report   started: $STARTED_AT"
echo "============================================================"
printf "%-28s | %-8s | %-8s | %s\n" "test" "expected" "actual" "verdict"
printf -- "----------------------------+----------+----------+--------\n"
overall=0
for row in "${RESULTS[@]:-}"; do
  IFS='|' read -r name exp act verdict <<<"$row"
  printf "%-28s | %-8s | %-8s | %s\n" "$name" "$exp" "$act" "$verdict"
  [[ "$verdict" == "PASS" ]] || overall=1
done
echo
if [[ "$overall" -eq 0 ]]; then
  echo "ALL GATES VERIFIED."
else
  echo "ONE OR MORE GATES FAILED — investigate above."
fi
exit "$overall"
