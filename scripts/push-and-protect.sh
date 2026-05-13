#!/usr/bin/env bash
# push-and-protect.sh
#
# Run AFTER you've created the GitHub repo. If repo doesn't exist yet:
#   gh repo create tiger-brain --private
# OR open https://github.com/new and fill in name=tiger-brain, visibility=private,
# no README/gitignore (repo already has them).
#
# This script handles: remote-add + push (main + feat-branch) + optional branch
# protection via gh api. Two modes:
#   easy (default) — remote-add + push only; UI steps printed for protection
#   full           — also configures branch protection via gh api
#
# Re-running is safe: refuses if `origin` already set unless --force.

set -euo pipefail

# ---- defaults ----
MODE="easy"
HANDLE="Nithu0"
REPO="tiger-brain"
REMOTE_URL=""
BRANCH="main"
FEAT_BRANCH="feat/brain-hardening"
ASSUME_YES=0
FORCE=0

usage() {
  cat <<EOF
Usage: $0 [--mode easy|full] [--handle <gh-handle>] [--repo <name>]
          [--remote-url <url>] [--branch <name>] [--feat-branch <name>]
          [--yes] [--force]

Defaults: mode=easy handle=$HANDLE repo=$REPO branch=$BRANCH feat-branch=$FEAT_BRANCH
EOF
}

# ---- parse args ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)        MODE="${2:-}"; shift 2 ;;
    --handle)      HANDLE="${2:-}"; shift 2 ;;
    --repo)        REPO="${2:-}"; shift 2 ;;
    --remote-url)  REMOTE_URL="${2:-}"; shift 2 ;;
    --branch)      BRANCH="${2:-}"; shift 2 ;;
    --feat-branch) FEAT_BRANCH="${2:-}"; shift 2 ;;
    --yes|-y)      ASSUME_YES=1; shift ;;
    --force)       FORCE=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

case "$MODE" in
  easy|full) ;;
  *) echo "ERROR: --mode must be 'easy' or 'full' (got '$MODE')" >&2; exit 2 ;;
esac

if [[ -z "$REMOTE_URL" ]]; then
  REMOTE_URL="git@github.com:${HANDLE}/${REPO}.git"
fi

confirm() {
  [[ "$ASSUME_YES" -eq 1 ]] && return 0
  local prompt="$1"
  read -r -p "$prompt [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

say() { printf "==> %s\n" "$*"; }
warn() { printf "!!  %s\n" "$*" >&2; }

# ---- 1. verify in a git repo ----
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: not inside a git repo. cd into the Brain vault first." >&2
  exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"
say "git repo: $REPO_ROOT"

# ---- 2. verify origin not set (unless --force) ----
if existing_url="$(git remote get-url origin 2>/dev/null)"; then
  if [[ "$FORCE" -eq 1 ]]; then
    warn "origin already set to: $existing_url — will overwrite (--force)"
    git remote remove origin
  else
    echo "ERROR: origin already set to: $existing_url" >&2
    echo "       re-run with --force to overwrite, or remove manually." >&2
    exit 1
  fi
fi

# ---- 3. verify branches exist locally ----
for b in "$BRANCH" "$FEAT_BRANCH"; do
  if ! git show-ref --verify --quiet "refs/heads/$b"; then
    echo "ERROR: local branch '$b' does not exist. Create it first." >&2
    exit 1
  fi
done
say "local branches OK: $BRANCH, $FEAT_BRANCH"

# ---- 4. confirm before remote add ----
say "mode:       $MODE"
say "remote URL: $REMOTE_URL"
if ! confirm "Add origin and push branches?"; then
  echo "aborted." >&2
  exit 1
fi

# ---- 5. add remote ----
git remote add origin "$REMOTE_URL"
say "remote added"

# ---- 6. test SSH (non-fatal; GitHub returns exit 1 with success message) ----
say "testing SSH to github.com ..."
ssh_out="$(ssh -T -o StrictHostKeyChecking=accept-new -o BatchMode=yes git@github.com 2>&1 || true)"
if grep -q "successfully authenticated" <<<"$ssh_out"; then
  say "SSH OK: $(grep -o 'Hi [^!]*' <<<"$ssh_out" || true)"
else
  warn "SSH check inconclusive. Output:"
  printf '    %s\n' "$ssh_out"
  warn "Continuing — push will fail loudly if auth is actually broken."
fi

# ---- 7. push main, then feat-branch ----
say "pushing $BRANCH ..."
git push -u origin "$BRANCH"
say "pushing $FEAT_BRANCH ..."
git push -u origin "$FEAT_BRANCH"

# ---- 8. branch protection (full mode only) ----
PROTECTION_STATUS="deferred (easy mode — set via UI)"
if [[ "$MODE" == "full" ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    warn "gh CLI not installed — falling back to easy mode for protection."
    warn "Install: see scripts/install-gh-cli.sh, then re-run with --mode full"
    PROTECTION_STATUS="skipped (gh not installed)"
  elif ! gh auth status >/dev/null 2>&1; then
    warn "gh installed but not authenticated. Run: gh auth login"
    PROTECTION_STATUS="skipped (gh not authenticated)"
  else
    say "configuring branch protection for $BRANCH via gh api ..."
    # Body sourced from OPERATOR-NEXT-STEPS.md step 6.
    protection_body='{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}'
    if printf '%s' "$protection_body" | gh api \
        -X PUT \
        -H "Accept: application/vnd.github+json" \
        "repos/${HANDLE}/${REPO}/branches/${BRANCH}/protection" \
        --input - >/dev/null; then
      PROTECTION_STATUS="enabled via gh api"
      say "branch protection enabled on $BRANCH"
    else
      warn "gh api call failed. Fallback — set protection in UI:"
      warn "  https://github.com/${HANDLE}/${REPO}/settings/branches"
      warn "  Add rule for '${BRANCH}': require PR + 1 review, no force-push, no deletion."
      PROTECTION_STATUS="failed via gh api — set via UI"
    fi
  fi
fi

# ---- 9. summary ----
cat <<EOF

================ SUMMARY ================
Repo:        https://github.com/${HANDLE}/${REPO}
Remote:      $REMOTE_URL
Pushed:      $BRANCH, $FEAT_BRANCH
Protection:  $PROTECTION_STATUS

Next manual steps:
EOF

if [[ "$MODE" == "easy" || "$PROTECTION_STATUS" != "enabled via gh api" ]]; then
  cat <<EOF
  1. Open https://github.com/${HANDLE}/${REPO}/settings/branches
  2. "Add branch ruleset" (or classic "Add rule") for '${BRANCH}':
       - Require a pull request before merging (1 approval)
       - Dismiss stale approvals on new push
       - Require linear history
       - Block force pushes
       - Block deletions
       - Require conversation resolution
  3. Save.
EOF
fi

cat <<EOF
  - Invite teammate: https://github.com/${HANDLE}/${REPO}/settings/access
=========================================
EOF
