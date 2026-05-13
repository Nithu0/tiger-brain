#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install-hooks.sh
#
# Installs a local git pre-push hook in the brain vault that runs
# `scripts/sanity.sh` before every push.
#
# Skipping the hook with `git push --no-verify` is allowed but discouraged
# per BRAIN-RULES.md.
#
# Behavior:
#   - Runs from the vault root regardless of caller's cwd.
#   - Refuses to run if the vault is not a git repo.
#   - If a pre-push hook already exists, prompts for:
#       overwrite | skip | backup-and-replace (default)
#   - Pass --yes (or -y) to skip the prompt and backup-and-replace silently.
#   - Writes a new pre-push hook, makes it executable, and verifies install.
# ---------------------------------------------------------------------------

set -euo pipefail

# Parse args
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y) ASSUME_YES=1 ;;
    *) echo "ERROR: unknown argument: $arg" >&2; exit 1 ;;
  esac
done

# Always operate from the vault root (parent of scripts/)
cd "$(dirname "$0")/.."
VAULT_ROOT="$(pwd)"

echo "Vault root: $VAULT_ROOT"

# Ensure this is a git repo with a hooks dir
if [[ ! -d "$VAULT_ROOT/.git" ]] && [[ ! -f "$VAULT_ROOT/.git" ]]; then
  echo "ERROR: $VAULT_ROOT is not a git repo (.git missing). Initialize git first." >&2
  exit 1
fi

# Resolve hooks dir (handles git worktrees / submodules where .git is a file)
if [[ -f "$VAULT_ROOT/.git" ]]; then
  HOOKS_DIR="$(git -C "$VAULT_ROOT" rev-parse --git-path hooks)"
else
  HOOKS_DIR="$VAULT_ROOT/.git/hooks"
fi

if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "ERROR: hooks dir not found: $HOOKS_DIR" >&2
  exit 1
fi

HOOK_PATH="$HOOKS_DIR/pre-push"

if [[ -e "$HOOK_PATH" ]]; then
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    backup="$HOOK_PATH.bak-$ts"
    mv "$HOOK_PATH" "$backup"
    echo "Backed up existing hook to: $backup"
  else
    echo
    echo "Existing pre-push hook found at: $HOOK_PATH"
    echo "--- begin existing hook ---"
    cat "$HOOK_PATH"
    echo "--- end existing hook ---"
    echo
    echo "Choose action:"
    echo "  [o] overwrite (replace without backup)"
    echo "  [s] skip (leave existing hook in place; exit)"
    echo "  [b] backup-and-replace  [default]"
    read -r -p "Action [o/s/B]: " action
    case "${action:-b}" in
      o|O) echo "Overwriting existing hook." ;;
      s|S) echo "Skipping. Existing hook left untouched."; exit 0 ;;
      b|B|"")
        ts="$(date +%Y%m%d-%H%M%S)"
        backup="$HOOK_PATH.bak-$ts"
        mv "$HOOK_PATH" "$backup"
        echo "Backed up existing hook to: $backup"
        ;;
      *) echo "Unknown choice '$action'. Aborting." >&2; exit 1 ;;
    esac
  fi
fi

cat > "$HOOK_PATH" <<'HOOK'
#!/usr/bin/env bash
# Installed by scripts/install-hooks.sh from the brain vault.
# Runs scripts/sanity.sh before allowing a push.
set -e
echo "==> pre-push: running scripts/sanity.sh"
if ! bash "$(git rev-parse --show-toplevel)/scripts/sanity.sh"; then
  echo "pre-push: sanity FAILED — push blocked. Fix issues or use 'git push --no-verify' to bypass (NOT RECOMMENDED)."
  exit 1
fi
echo "==> pre-push: sanity passed; allowing push"
HOOK

chmod +x "$HOOK_PATH"

# Verify
if [[ -x "$HOOK_PATH" ]]; then
  echo
  echo "Installed pre-push hook at: $HOOK_PATH"
  ls -l "$HOOK_PATH"
else
  echo "ERROR: hook was not installed correctly (not executable)." >&2
  exit 1
fi

cat <<EOF

Uninstall instructions:
  rm "$HOOK_PATH"
  # or, if you used backup-and-replace, restore the previous hook with:
  #   mv "$HOOK_PATH.bak-<timestamp>" "$HOOK_PATH"

Bypass for a single push (discouraged per BRAIN-RULES.md):
  git push --no-verify
EOF
