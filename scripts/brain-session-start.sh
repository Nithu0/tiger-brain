#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# brain-session-start.sh
#
# Called automatically by firm tab boot. Fast no-friction brain hygiene.
#
# Goals:
#   - FAST (under 2 seconds when green)
#   - Quiet on success (only output if something needs attention)
#   - Loud on real problems
#   - Auto-pull from origin if reachable; graceful fallback if offline
#   - Auto-install pre-push hook if missing
#   - NO interactive prompts (can't block tab boot)
#
# Flags:
#   --quiet (default)  : only print on errors/warnings
#   --verbose          : print all section status
#   --skip-pull        : skip git pull (e.g. offline)
#   --skip-audit       : skip slow audit check
#   --vault <path>     : override default ~/Obsidian/Brain
#
# Exit codes:
#   0 - all green OR vault missing/non-repo (don't break tab boot)
#   1 - audit reported errors
#
# All output goes to STDERR so callers' stdout stays clean.
# ---------------------------------------------------------------------------

set -uo pipefail

# --- arg parsing -----------------------------------------------------------
VAULT_DEFAULT="$HOME/Obsidian/Brain"
VAULT="$VAULT_DEFAULT"
MODE="quiet"
SKIP_PULL=0
SKIP_AUDIT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet)      MODE="quiet"; shift ;;
    --verbose)    MODE="verbose"; shift ;;
    --skip-pull)  SKIP_PULL=1; shift ;;
    --skip-audit) SKIP_AUDIT=1; shift ;;
    --vault)      VAULT="${2:-}"; shift 2 ;;
    *)            shift ;;  # ignore unknown to stay non-fatal
  esac
done

log() { echo "brain: $*" >&2; }
vlog() { [[ "$MODE" == "verbose" ]] && echo "brain: $*" >&2; return 0; }

# --- locate vault ----------------------------------------------------------
if [[ ! -d "$VAULT" ]]; then
  # Vault doesn't exist; quietly do nothing
  exit 0
fi

cd "$VAULT" 2>/dev/null || exit 0

# --- check git repo --------------------------------------------------------
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

# --- git pull (if remote exists and not skipped) --------------------------
if [[ $SKIP_PULL -eq 0 ]]; then
  if git remote get-url origin >/dev/null 2>&1; then
    if git pull --rebase --autostash --quiet 2>/dev/null; then
      vlog "pull: ok"
    else
      log "pull failed (offline?)"
    fi
  else
    vlog "pull: no remote"
  fi
else
  vlog "pull: skipped"
fi

# --- quick git status checks ----------------------------------------------
UNCOMMITTED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
UNPUSHED=$(git log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')

# --- pre-push hook installed? ---------------------------------------------
HOOKS_DIR="$(git rev-parse --git-path hooks 2>/dev/null)"
HOOK_PATH="$HOOKS_DIR/pre-push"

if [[ ! -x "$HOOK_PATH" ]]; then
  # Silently install inline (install-hooks.sh is interactive)
  if [[ -d "$HOOKS_DIR" ]]; then
    cat > "$HOOK_PATH" <<'HOOK'
#!/usr/bin/env bash
# Auto-installed by brain-session-start.sh.
# Runs scripts/sanity.sh before allowing a push.
set -e
echo "==> pre-push: running scripts/sanity.sh"
if ! bash "$(git rev-parse --show-toplevel)/scripts/sanity.sh"; then
  echo "pre-push: sanity FAILED — push blocked. Fix issues or use 'git push --no-verify' to bypass (NOT RECOMMENDED)."
  exit 1
fi
echo "==> pre-push: sanity passed; allowing push"
HOOK
    chmod +x "$HOOK_PATH" 2>/dev/null
    log "installed missing pre-push hook"
  fi
else
  vlog "hook: ok"
fi

# --- audit (optional) ------------------------------------------------------
AUDIT_RC=0
if [[ $SKIP_AUDIT -eq 0 ]]; then
  if [[ -f "scripts/brain_audit.py" ]]; then
    python3 scripts/brain_audit.py >/dev/null 2>&1
    AUDIT_RC=$?
    vlog "audit: rc=$AUDIT_RC"
  else
    vlog "audit: script missing, skipped"
  fi
else
  vlog "audit: skipped"
fi

# --- status summary --------------------------------------------------------
FINAL_RC=0
if [[ $AUDIT_RC -ne 0 ]]; then
  log "✗ audit FAIL — run scripts/sanity.sh"
  FINAL_RC=1
fi

if [[ $UNCOMMITTED -gt 0 || $UNPUSHED -gt 0 ]]; then
  log "⚠ ${UNCOMMITTED} uncommitted, ${UNPUSHED} unpushed"
fi

if [[ $FINAL_RC -eq 0 && $UNCOMMITTED -eq 0 && $UNPUSHED -eq 0 ]]; then
  vlog "✓ clean"
fi

exit $FINAL_RC
