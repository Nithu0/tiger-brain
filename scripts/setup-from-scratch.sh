#!/usr/bin/env bash
# setup-from-scratch.sh
#
# Bootstraps the Brain vault on a fresh machine (operator or teammate).
#
# Modes:
#   easy      (default) Clone the vault, point Obsidian at it, run brain_audit.
#             No external installs.
#   advanced  Easy mode PLUS: install pre-commit hook that runs brain_audit
#             before each commit, and print Claude Code install instructions.
#
# Usage:
#   ./setup-from-scratch.sh --repo <git-url> [--mode easy|advanced] [--dest <path>]
#
# Safety:
#   - set -euo pipefail: exit on any failure
#   - Never overwrites an existing destination without explicit confirmation
#   - Never auto-installs system packages; prints instructions instead
#
# After cloning this script onto a new machine, make it executable once:
#   chmod +x scripts/setup-from-scratch.sh

set -euo pipefail

# ---------- defaults ----------
MODE="easy"
DEST="${HOME}/Obsidian/Brain"
REPO=""

# ---------- helpers ----------
info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$*"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$*"; }
err()   { printf "\033[1;31m[err]\033[0m   %s\n" "$*" >&2; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$*"; }

usage() {
  cat <<EOF
Usage: $0 --repo <git-url> [--mode easy|advanced] [--dest <path>]

Required:
  --repo <git-url>     Git URL of the Brain vault (e.g. git@github.com:owner/brain.git)

Optional:
  --mode easy|advanced (default: easy)
  --dest <path>        (default: ${HOME}/Obsidian/Brain)
  -h, --help           Show this help

Examples:
  $0 --repo git@github.com:owner/brain.git
  $0 --repo git@github.com:owner/brain.git --mode advanced
EOF
}

confirm() {
  # confirm "message"  -> returns 0 if user said yes
  local prompt="${1:-Continue?} [y/N] "
  local reply
  read -r -p "$prompt" reply || return 1
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------- parse args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"; shift 2
      ;;
    --dest)
      DEST="${2:-}"; shift 2
      ;;
    --repo)
      REPO="${2:-}"; shift 2
      ;;
    -h|--help)
      usage; exit 0
      ;;
    *)
      err "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$REPO" ]]; then
  err "--repo is required"
  usage
  exit 1
fi

case "$MODE" in
  easy|advanced) ;;
  *) err "--mode must be 'easy' or 'advanced' (got: $MODE)"; exit 1 ;;
esac

info "Mode: $MODE"
info "Dest: $DEST"
info "Repo: $REPO"

# ---------- pre-flight ----------
info "Pre-flight checks..."

if ! command -v git >/dev/null 2>&1; then
  err "git is not installed."
  err "Install git (https://git-scm.com/downloads) and re-run."
  exit 1
fi
ok "git found: $(git --version)"

if ! command -v python3 >/dev/null 2>&1; then
  err "python3 is not installed."
  err "Install Python >= 3.11 (https://www.python.org/downloads/) and re-run."
  exit 1
fi

PY_VER="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
PY_MAJOR="${PY_VER%%.*}"
PY_MINOR="${PY_VER##*.}"
if (( PY_MAJOR < 3 )) || { (( PY_MAJOR == 3 )) && (( PY_MINOR < 11 )); }; then
  err "python3 is $PY_VER but >= 3.11 is required."
  err "Upgrade Python and re-run."
  exit 1
fi
ok "python3 found: $PY_VER"

# ---------- clone ----------
if [[ -e "$DEST" ]]; then
  warn "Destination already exists: $DEST"
  if [[ -d "$DEST/.git" ]]; then
    info "Looks like an existing git repo. Skipping clone."
  else
    if confirm "Overwrite existing non-repo path? (this will NOT be done automatically)"; then
      err "Refusing to delete. Move or rename $DEST yourself, then re-run."
      exit 1
    else
      err "Aborting per user choice."
      exit 1
    fi
  fi
else
  info "Cloning $REPO into $DEST..."
  mkdir -p "$(dirname "$DEST")"
  git clone "$REPO" "$DEST"
  ok "Cloned."
fi

# ---------- verify ----------
cd "$DEST"

if [[ ! -f "scripts/brain_audit.py" ]]; then
  warn "scripts/brain_audit.py is missing in the vault."
  warn "Skipping audit step. The vault may not be fully set up yet."
else
  info "Running brain_audit.py..."
  if python3 scripts/brain_audit.py; then
    ok "brain_audit.py is green."
  else
    err "brain_audit.py reported findings. Address them before sharing."
    # Do not exit 1 here — a fresh clone with findings is still a valid setup.
    # Operator can review the output and decide.
  fi
fi

# ---------- advanced extras ----------
if [[ "$MODE" == "advanced" ]]; then
  info "Advanced mode: installing pre-commit hook..."

  HOOK_PATH=".git/hooks/pre-commit"
  if [[ -e "$HOOK_PATH" ]]; then
    warn "$HOOK_PATH already exists."
    if ! confirm "Overwrite existing pre-commit hook?"; then
      info "Keeping existing pre-commit hook untouched."
    else
      cat > "$HOOK_PATH" <<'HOOK'
#!/usr/bin/env bash
# Brain vault pre-commit: run brain_audit before allowing the commit.
set -euo pipefail
if [[ -f scripts/brain_audit.py ]]; then
  python3 scripts/brain_audit.py
fi
HOOK
      chmod +x "$HOOK_PATH"
      ok "Pre-commit hook installed."
    fi
  else
    cat > "$HOOK_PATH" <<'HOOK'
#!/usr/bin/env bash
# Brain vault pre-commit: run brain_audit before allowing the commit.
set -euo pipefail
if [[ -f scripts/brain_audit.py ]]; then
  python3 scripts/brain_audit.py
fi
HOOK
    chmod +x "$HOOK_PATH"
    ok "Pre-commit hook installed."
  fi

  info "Claude Code install instructions:"
  cat <<'EOF'
  Claude Code is not auto-installed by this script.
  See https://claude.com/claude-code for the current install command.

  Once installed, Claude Code will pick up the global config at
  ~/.claude/CLAUDE.md and any project-level CLAUDE.md it finds.
EOF
fi

# ---------- footer ----------
cat <<EOF

----------------------------------------------------------------------
Setup complete.

Open the vault in Obsidian:
  File -> Open Folder as Vault -> $DEST

Read this first:
  $DEST/TEAMMATE-ONBOARDING.md

If anything looks off, run:
  python3 $DEST/scripts/brain_audit.py
----------------------------------------------------------------------
EOF
