#!/usr/bin/env bash
# karri-bootstrap.sh — fresh WSL Ubuntu to working `firm` in one shot.
#
# Run from inside WSL Ubuntu. Assumes:
#   - WSL2 + Ubuntu installed (you'd already be in bash if not)
#   - Claude Code installed (already true if you're using it)
#   - GitHub account = Nithu0 (shared with operator)
#
# Does NOT assume:
#   - SSH key set up — will guide if missing
#   - apt deps installed — installs what's needed
#   - Repos cloned — clones them
#   - .bashrc configured — calls install.sh to do it
#
# Usage:
#   bash karri-bootstrap.sh                        # interactive
#   bash karri-bootstrap.sh --name Karri --email karri@x.com   # non-interactive
#
# Idempotent. Safe to re-run.

set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────
# 0. Colors + helpers
# ─────────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; BOLD=$'\e[1m'; NC=$'\e[0m'
else
  GREEN=''; YELLOW=''; RED=''; BOLD=''; NC=''
fi
log() { echo "${BOLD}==>${NC} $*"; }
ok()  { echo "  ${GREEN}✓${NC} $*"; }
warn(){ echo "  ${YELLOW}⚠${NC} $*"; }
err() { echo "  ${RED}✗${NC} $*" >&2; }

GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
ASSUME_YES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)  GIT_USER_NAME="$2"; shift 2 ;;
    --email) GIT_USER_EMAIL="$2"; shift 2 ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) err "unknown arg: $1"; exit 2 ;;
  esac
done

# ─────────────────────────────────────────────────────────────────────────
# 1. Apt prerequisites
# ─────────────────────────────────────────────────────────────────────────
log "Installing prerequisites via apt (will prompt for sudo)..."
if sudo -n true 2>/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq git python3 python3-pip openssh-client curl ca-certificates
  ok "apt deps installed (git, python3, openssh, curl)"
else
  warn "sudo not cached. Re-running with prompt..."
  sudo apt-get update
  sudo apt-get install -y git python3 python3-pip openssh-client curl ca-certificates
  ok "apt deps installed"
fi

# ─────────────────────────────────────────────────────────────────────────
# 2. SSH key check + setup if needed
# ─────────────────────────────────────────────────────────────────────────
log "Checking SSH against GitHub..."
SSH_OUT=$(ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=5 \
             -T git@github.com 2>&1 || true)

if echo "$SSH_OUT" | grep -q "Hi Nithu0"; then
  ok "SSH works: authenticated as Nithu0"
elif echo "$SSH_OUT" | grep -q "Permission denied"; then
  err "SSH failed: GitHub rejected the key (or no key present)"
  echo
  if [[ ! -f $HOME/.ssh/id_ed25519 ]]; then
    echo "  No SSH key found at ~/.ssh/id_ed25519."
    echo "  Generate one with:"
    echo
    echo "    ssh-keygen -t ed25519 -C \"karri@$(hostname)\""
    echo "    cat ~/.ssh/id_ed25519.pub"
    echo
    echo "  Then add the pubkey at: https://github.com/settings/keys"
    echo "  (Log in as Nithu0 first.)"
    echo
    echo "  Re-run this script after that."
  else
    echo "  SSH key exists at ~/.ssh/id_ed25519 but isn't on the Nithu0 account."
    echo "  Show your pubkey:"
    echo "    cat ~/.ssh/id_ed25519.pub"
    echo "  Add it at https://github.com/settings/keys (as Nithu0)."
  fi
  exit 1
else
  warn "Unexpected SSH output:"
  echo "$SSH_OUT" | sed 's/^/    /'
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────
# 3. Clone tiger-brain if missing
# ─────────────────────────────────────────────────────────────────────────
BRAIN="$HOME/Obsidian/Brain"
log "Brain vault: $BRAIN"
if [[ ! -d "$BRAIN" ]]; then
  mkdir -p "$HOME/Obsidian"
  git clone git@github.com:Nithu0/tiger-brain.git "$BRAIN"
  ok "cloned tiger-brain"
else
  ok "already cloned (pulling latest)"
  ( cd "$BRAIN" && git pull --rebase --autostash 2>&1 | tail -3 )
fi

# ─────────────────────────────────────────────────────────────────────────
# 4. Hand off to install.sh with roster=nexus (Karri only works on Nexus)
# ─────────────────────────────────────────────────────────────────────────
log "Running firm-launcher/install.sh with roster=nexus..."
INSTALL_ARGS=(--roster nexus)
[[ -n "$GIT_USER_NAME"  ]] && INSTALL_ARGS+=(--name  "$GIT_USER_NAME")
[[ -n "$GIT_USER_EMAIL" ]] && INSTALL_ARGS+=(--email "$GIT_USER_EMAIL")
[[ "$ASSUME_YES" -eq 1  ]] && INSTALL_ARGS+=(--yes)

bash "$BRAIN/firm-launcher/install.sh" "${INSTALL_ARGS[@]}"

# ─────────────────────────────────────────────────────────────────────────
# 5. Verify
# ─────────────────────────────────────────────────────────────────────────
log "Verifying..."
if grep -q "firm launcher (installed by tiger-brain" "$HOME/.bashrc"; then
  ok ".bashrc updated with firm aliases"
fi
if [[ -x "$HOME/code/_bin/firm-wt-split.sh" ]]; then
  ok "firm scripts copied to ~/code/_bin/"
fi
if [[ -x "$BRAIN/.git/hooks/pre-push" ]]; then
  ok "pre-push hook installed in brain"
fi

echo
echo "${GREEN}${BOLD}Done.${NC} Last steps (manual):"
echo "  1. ${BOLD}Reload your shell${NC}:   source ~/.bashrc"
echo "  2. ${BOLD}Launch firm${NC}:         firm"
echo "  3. ${BOLD}Read the cheat sheet${NC}: cat $BRAIN/KARRI-DAY-1.md"
echo
echo "If firm doesn't launch, check:"
echo "  - Are you in WSL bash (not PowerShell)?  echo \$WSL_DISTRO_NAME"
echo "  - Is wt.exe on PATH?                     which wt.exe"
echo "  - Is claude on PATH?                     which claude"
