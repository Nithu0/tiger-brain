#!/usr/bin/env bash
# Karri / new-collaborator one-command installer. Idempotent — safe to re-run.
#
# Installs the operator's `firm` 8-Claude launcher setup on a fresh WSL/Linux
# machine. Handles pre-flight checks, repo cloning, script install, .bashrc
# wiring, ~/.claude/settings.json statusLine, brain pre-push hook, and a final
# sanity check.
#
# NOTE: the firm `_bin` scripts canonically live in the command-center repo
# (github.com/Nithu0/command-center, private) at command-center/_bin/. The copy
# bundled here under firm-launcher/bin/ is the portable installer payload for
# collaborators who may not have command-center cloned — this installer copies
# those into $FIRM_BIN_DIR (default: ~/code/command-center/_bin).
#
# Usage:
#   bash install.sh [--yes] [--with-thesis|--no-thesis]
#                   [--brain-vault PATH] [--nexus-repo PATH]
#                   [--firm-bin-dir PATH] [--no-shellrc]
#                   [--name NAME] [--email EMAIL]
#                   [--roster default|nexus|thesis|workspace]

set -uo pipefail

# ---------- defaults ----------
BRAIN_VAULT="${BRAIN_VAULT:-$HOME/Obsidian/Brain}"
NEXUS_REPO="${NEXUS_REPO:-$HOME/code/ai-assistent}"
THESIS_REPO="${THESIS_REPO:-$HOME/code/Master-oppgave}"
# _bin canonically lives inside the command-center repo (moved from ~/code/_bin).
FIRM_BIN_DIR="${FIRM_BIN_DIR:-$HOME/code/command-center/_bin}"
CLAUDE_SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
ASSUME_YES=0
WITH_THESIS=0
NO_SHELLRC=0
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
FIRM_ROSTER_DEFAULT="${FIRM_ROSTER_DEFAULT:-}"

# ---------- pretty printing ----------
c_reset=$'\033[0m'; c_red=$'\033[31m'; c_yel=$'\033[33m'
c_grn=$'\033[32m'; c_blu=$'\033[34m'; c_bold=$'\033[1m'

info()  { printf "%s[info]%s %s\n"  "$c_blu"  "$c_reset" "$*"; }
ok()    { printf "%s[ ok ]%s %s\n"  "$c_grn"  "$c_reset" "$*"; }
warn()  { printf "%s[warn]%s %s\n"  "$c_yel"  "$c_reset" "$*" >&2; }
err()   { printf "%s[fail]%s %s\n"  "$c_red"  "$c_reset" "$*" >&2; }
hdr()   { printf "\n%s== %s ==%s\n" "$c_bold" "$*" "$c_reset"; }

confirm() {
  # confirm "prompt" — returns 0 on yes, 1 on no. --yes skips.
  local prompt="$1"
  if [[ "$ASSUME_YES" -eq 1 ]]; then return 0; fi
  read -r -p "$prompt [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

# ---------- arg parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)             ASSUME_YES=1 ;;
    --with-thesis)     WITH_THESIS=1 ;;
    --no-thesis)       WITH_THESIS=0 ;;
    --brain-vault)     BRAIN_VAULT="$2"; shift ;;
    --nexus-repo)      NEXUS_REPO="$2"; shift ;;
    --firm-bin-dir)    FIRM_BIN_DIR="$2"; shift ;;
    --no-shellrc)      NO_SHELLRC=1 ;;
    --name)            GIT_USER_NAME="$2"; shift ;;
    --email)           GIT_USER_EMAIL="$2"; shift ;;
    --roster)          FIRM_ROSTER_DEFAULT="$2"; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *)
      err "unknown arg: $1"; exit 2 ;;
  esac
  shift
done

TS="$(date +%Y%m%d-%H%M%S)"

hdr "firm-launcher installer"
info "BRAIN_VAULT  = $BRAIN_VAULT"
info "NEXUS_REPO   = $NEXUS_REPO"
info "FIRM_BIN_DIR = $FIRM_BIN_DIR  (canonical: command-center repo)"
info "SETTINGS     = $CLAUDE_SETTINGS"
info "with-thesis  = $WITH_THESIS   no-shellrc = $NO_SHELLRC   yes = $ASSUME_YES"

# ---------- 1. pre-flight ----------
hdr "1. pre-flight checks"

# bash >= 4
if [[ -n "${BASH_VERSINFO:-}" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
  ok "bash ${BASH_VERSION}"
else
  err "bash >= 4 required (found: ${BASH_VERSION:-unknown})"; exit 1
fi

if command -v git >/dev/null 2>&1; then
  ok "$(git --version)"
else
  err "git not found — install git first"; exit 1
fi

if command -v claude >/dev/null 2>&1; then
  ok "claude $(claude --version 2>/dev/null | head -1)"
else
  warn "claude CLI not found — install Claude Code before running 'firm'"
fi

HAS_WT=0
if command -v wt.exe >/dev/null 2>&1; then
  ok "wt.exe present (Windows Terminal)"
  HAS_WT=1
else
  warn "wt.exe not found — will fall back to zellij (firmz)"
fi

# SSH to GitHub
info "testing SSH to github.com..."
SSH_OUT="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)"
if echo "$SSH_OUT" | grep -q "successfully authenticated"; then
  ok "$(echo "$SSH_OUT" | head -1)"
else
  err "SSH to github.com failed:"
  echo "$SSH_OUT" >&2
  err "fix your SSH key + GitHub access before re-running"
  exit 1
fi

# ---------- 1b. interactive prompts (name/email/roster) ----------
hdr "1b. collaborator setup"

if [[ -z "${GIT_USER_NAME:-}" && "$ASSUME_YES" -eq 0 ]]; then
  read -rp "Your name (for git commit attribution; leave blank to use existing config): " GIT_USER_NAME
fi
if [[ -z "${GIT_USER_EMAIL:-}" && "$ASSUME_YES" -eq 0 ]]; then
  read -rp "Your email: " GIT_USER_EMAIL
fi

if [[ -z "${FIRM_ROSTER_DEFAULT:-}" && "$ASSUME_YES" -eq 0 ]]; then
  echo
  echo "Firm pane layout — which projects do you work on?"
  echo "  1) default       (2 workspace + 4 nexus + 2 thesis) — operator's split"
  echo "  2) nexus         (8 nexus panes) — Nexus-only collaborator like Karri"
  echo "  3) thesis        (8 thesis panes)"
  echo "  4) workspace     (8 workspace panes)"
  read -rp "Choose [1-4, default 1]: " roster_choice
  case "${roster_choice:-1}" in
    1) FIRM_ROSTER_DEFAULT=default   ;;
    2) FIRM_ROSTER_DEFAULT=nexus     ;;
    3) FIRM_ROSTER_DEFAULT=thesis    ;;
    4) FIRM_ROSTER_DEFAULT=workspace ;;
    *) FIRM_ROSTER_DEFAULT=default   ;;
  esac
fi
FIRM_ROSTER_DEFAULT="${FIRM_ROSTER_DEFAULT:-default}"

info "git name   = ${GIT_USER_NAME:-<keep existing>}"
info "git email  = ${GIT_USER_EMAIL:-<keep existing>}"
info "roster     = $FIRM_ROSTER_DEFAULT"

# ---------- 2. detect / clone repos ----------
hdr "2. repo checkout"

clone_if_missing() {
  local repo_url="$1" target="$2" label="$3"
  if [[ -d "$target/.git" ]]; then
    ok "$label exists: $target"
  elif [[ -d "$target" ]]; then
    warn "$label dir exists but is not a git repo: $target — skipping clone"
  else
    info "cloning $label -> $target"
    mkdir -p "$(dirname "$target")"
    if git clone "$repo_url" "$target"; then
      ok "cloned $label"
    else
      err "failed to clone $label from $repo_url"
      return 1
    fi
  fi
}

clone_if_missing "git@github.com:Nithu0/tiger-brain.git" "$BRAIN_VAULT" "tiger-brain"
clone_if_missing "git@github.com:Nithu0/ai-assistent.git" "$NEXUS_REPO"  "ai-assistent"

if [[ "$WITH_THESIS" -eq 1 ]]; then
  clone_if_missing "git@github.com:Nithu0/Master-oppgave.git" "$THESIS_REPO" "Master-oppgave"
else
  info "skipping Master-oppgave (pass --with-thesis to include)"
fi

# apply per-repo git config (only if a name was provided)
if [[ -n "${GIT_USER_NAME:-}" ]]; then
  ( cd "$BRAIN_VAULT" && git config user.name "$GIT_USER_NAME" && git config user.email "$GIT_USER_EMAIL" )
  echo "  ✓ git config set for $BRAIN_VAULT: $GIT_USER_NAME <$GIT_USER_EMAIL>"
  if [[ -d "$NEXUS_REPO" ]]; then
    ( cd "$NEXUS_REPO" && git config user.name "$GIT_USER_NAME" && git config user.email "$GIT_USER_EMAIL" )
    echo "  ✓ git config set for $NEXUS_REPO"
  fi
  if [[ -d "$THESIS_REPO" ]]; then
    ( cd "$THESIS_REPO" && git config user.name "$GIT_USER_NAME" && git config user.email "$GIT_USER_EMAIL" )
    echo "  ✓ git config set for $THESIS_REPO"
  fi
fi

# ---------- 3. install firm scripts ----------
hdr "3. install firm scripts"

SRC_BIN="$BRAIN_VAULT/firm-launcher/bin"
if [[ ! -d "$SRC_BIN" ]]; then
  err "source dir not found: $SRC_BIN (is the brain vault clone OK?)"
  exit 1
fi

mkdir -p "$FIRM_BIN_DIR"
ok "FIRM_BIN_DIR ready: $FIRM_BIN_DIR"

shopt -s nullglob
for src in "$SRC_BIN"/*.sh; do
  base="$(basename "$src")"
  dst="$FIRM_BIN_DIR/$base"
  if [[ -f "$dst" ]]; then
    if cmp -s "$src" "$dst"; then
      ok "$base unchanged"
      continue
    fi
    if confirm "overwrite existing $dst (backup will be made)?"; then
      cp -p "$dst" "$dst.bak-$TS"
      cp -p "$src" "$dst"
      chmod +x "$dst"
      ok "updated $base (backup: $dst.bak-$TS)"
    else
      warn "skipped $base"
    fi
  else
    cp -p "$src" "$dst"
    chmod +x "$dst"
    ok "installed $base"
  fi
done
shopt -u nullglob

# ---------- 4. nexus-bashrc ----------
hdr "4. nexus-bashrc"

NEXUS_BASHRC="$NEXUS_REPO/tools/terminal/bash/nexus-bashrc.sh"
FALLBACK_BASHRC="$BRAIN_VAULT/firm-launcher/bash/nexus-bashrc.sh"

if [[ -f "$NEXUS_BASHRC" ]]; then
  ok "nexus-bashrc.sh present in ai-assistent"
elif [[ -f "$FALLBACK_BASHRC" ]]; then
  warn "nexus-bashrc.sh missing in ai-assistent — copying from brain fallback"
  mkdir -p "$(dirname "$NEXUS_BASHRC")"
  cp -p "$FALLBACK_BASHRC" "$NEXUS_BASHRC"
  ok "installed nexus-bashrc.sh from fallback"
else
  warn "no nexus-bashrc.sh source found (neither $NEXUS_BASHRC nor $FALLBACK_BASHRC)"
fi

# ---------- 5. .bashrc wiring ----------
hdr "5. ~/.bashrc wiring"

FIRM_MARKER="# === firm launcher (installed by tiger-brain/firm-launcher/install.sh) ==="

if [[ "$NO_SHELLRC" -eq 1 ]]; then
  info "--no-shellrc set — leaving ~/.bashrc untouched"
elif [[ ! -f "$HOME/.bashrc" ]]; then
  warn "~/.bashrc does not exist — creating one"
  touch "$HOME/.bashrc"
fi

if [[ "$NO_SHELLRC" -ne 1 ]]; then
  if grep -qF "$FIRM_MARKER" "$HOME/.bashrc" 2>/dev/null; then
    ok "firm block already present in ~/.bashrc"
  else
    cp -p "$HOME/.bashrc" "$HOME/.bashrc.bak-$TS" 2>/dev/null || true
    {
      cat <<EOF

# === firm launcher (installed by tiger-brain/firm-launcher/install.sh) ===
# 8-Claude launcher across projects (workspace, nexus, master-oppgave).
# Bus: ~/Obsidian/Brain/00-firm-bus/  |  Runbook: ~/Obsidian/Brain/_runbooks/firm-launcher.md
# firm _bin lives in the command-center repo (~/code/command-center/_bin).
export NEXUS_REPO="\${NEXUS_REPO:-\$HOME/code/ai-assistent}"
export FIRM_BIN_DIR="\${FIRM_BIN_DIR:-$FIRM_BIN_DIR}"
if [[ -f "\$NEXUS_REPO/tools/terminal/bash/nexus-bashrc.sh" ]]; then
  source "\$NEXUS_REPO/tools/terminal/bash/nexus-bashrc.sh"
fi
alias firm="\$FIRM_BIN_DIR/firm-wt-split.sh"
alias firmt="\$FIRM_BIN_DIR/firm-wt-tabs.sh"
alias firmz="\$FIRM_BIN_DIR/firm-zellij.sh"
alias nx="\$FIRM_BIN_DIR/firm-wt-split.sh"
EOF
      if [[ "$FIRM_ROSTER_DEFAULT" != "default" ]]; then
        echo "export FIRM_ROSTER=\"$FIRM_ROSTER_DEFAULT\""
      fi
      echo "# === end firm launcher ==="
    } >> "$HOME/.bashrc"
    ok "appended firm block to ~/.bashrc (backup: ~/.bashrc.bak-$TS)"
  fi
fi

# ---------- 5b. ~/.claude/settings.json statusLine ----------
hdr "5b. ~/.claude/settings.json statusLine"

# Wire statusLine.command -> $FIRM_BIN_DIR/firm-statusline.sh so every firm
# pane shows the role banner. Edited JSON-safely (python3 or jq), never sed.
STATUSLINE_CMD="$FIRM_BIN_DIR/firm-statusline.sh"

if [[ ! -f "$FIRM_BIN_DIR/firm-statusline.sh" ]]; then
  warn "firm-statusline.sh not found in $FIRM_BIN_DIR — statusLine will point at a missing script"
fi

mkdir -p "$(dirname "$CLAUDE_SETTINGS")"

if [[ -f "$CLAUDE_SETTINGS" ]]; then
  cp -p "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak-$TS"
  info "backed up settings.json -> $CLAUDE_SETTINGS.bak-$TS"
fi

settings_done=0

if command -v python3 >/dev/null 2>&1; then
  if python3 - "$CLAUDE_SETTINGS" "$STATUSLINE_CMD" <<'PYEOF'
import json, sys, os
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.isfile(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, ValueError) as e:
        sys.stderr.write("settings.json is not valid JSON (%s) — refusing to edit\n" % e)
        sys.exit(3)
    if not isinstance(data, dict):
        sys.stderr.write("settings.json top-level is not an object — refusing to edit\n")
        sys.exit(3)
sl = data.get("statusLine")
if not isinstance(sl, dict):
    sl = {}
sl["type"] = "command"
sl["command"] = cmd
data["statusLine"] = sl
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("statusLine.command = %s" % cmd)
PYEOF
  then
    ok "settings.json statusLine wired (python3)"
    settings_done=1
  else
    rc=$?
    if [[ "$rc" -eq 3 ]]; then
      err "settings.json exists but is invalid JSON — fix it manually, then re-run"
    else
      warn "python3 edit of settings.json failed (rc=$rc)"
    fi
  fi
elif command -v jq >/dev/null 2>&1; then
  TMP_SETTINGS="$CLAUDE_SETTINGS.tmp-$TS"
  if [[ -f "$CLAUDE_SETTINGS" ]]; then
    if jq --arg cmd "$STATUSLINE_CMD" \
         '.statusLine = ((.statusLine // {}) + {type: "command", command: $cmd})' \
         "$CLAUDE_SETTINGS" > "$TMP_SETTINGS" 2>/dev/null; then
      mv "$TMP_SETTINGS" "$CLAUDE_SETTINGS"
      ok "settings.json statusLine wired (jq)"
      settings_done=1
    else
      rm -f "$TMP_SETTINGS"
      err "jq could not parse settings.json — fix it manually, then re-run"
    fi
  else
    if jq -n --arg cmd "$STATUSLINE_CMD" \
         '{statusLine: {type: "command", command: $cmd}}' > "$CLAUDE_SETTINGS"; then
      ok "created settings.json with statusLine (jq)"
      settings_done=1
    fi
  fi
fi

if [[ "$settings_done" -ne 1 ]]; then
  if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
    # No JSON tool but no existing file either — safe to write a minimal one.
    cat > "$CLAUDE_SETTINGS" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "$STATUSLINE_CMD"
  }
}
EOF
    ok "created minimal settings.json with statusLine (no python3/jq found)"
  else
    warn "neither python3 nor jq available — NOT editing existing settings.json"
    warn "manually set statusLine.command to: $STATUSLINE_CMD"
  fi
fi

# ---------- 6. brain pre-push hook ----------
hdr "6. brain pre-push hook"

HOOK_INSTALLER="$BRAIN_VAULT/scripts/install-hooks.sh"
if [[ -x "$HOOK_INSTALLER" || -f "$HOOK_INSTALLER" ]]; then
  if (cd "$BRAIN_VAULT" && bash scripts/install-hooks.sh --yes); then
    ok "brain pre-push hook installed"
  else
    warn "install-hooks.sh exited non-zero — inspect manually"
  fi
else
  warn "no $HOOK_INSTALLER — skipping (brain hook install)"
fi

# ---------- 7. brain sanity ----------
hdr "7. brain sanity"

SANITY="$BRAIN_VAULT/scripts/sanity.sh"
if [[ -f "$SANITY" ]]; then
  if (cd "$BRAIN_VAULT" && bash scripts/sanity.sh); then
    ok "brain sanity passed"
  else
    warn "brain sanity reported issues — read output above"
  fi
else
  warn "no $SANITY — skipping sanity check"
fi

# ---------- 8. summary ----------
hdr "done — next steps for Karri"

cat <<EOF

  1. Restart your shell, or:  source ~/.bashrc
  2. Launch the 8-Claude session:
       firm        (Windows Terminal split — preferred)
       firmt       (Windows Terminal tabs)
       firmz       (zellij fallback if no wt.exe)
  3. Read these in your Obsidian vault:
       $BRAIN_VAULT/WELCOME.md
       $BRAIN_VAULT/TEAMMATE-ONBOARDING.md
       $BRAIN_VAULT/_runbooks/firm-launcher.md

  Bus / coordination:  $BRAIN_VAULT/00-firm-bus/
  firm scripts:        $FIRM_BIN_DIR  (canonical copy: command-center repo)
  statusLine:          $CLAUDE_SETTINGS -> $STATUSLINE_CMD

  Each firm pane runs firm-inbox-watch.sh (Slice 11) — it auto-picks-up
  dispatches queued from command-center, so queued work lands without
  manual polling.

  Re-run this installer any time — it is idempotent.

EOF

if [[ "$HAS_WT" -eq 0 ]]; then
  warn "wt.exe was missing — use 'firmz' (zellij) until you install Windows Terminal"
fi

ok "install complete"
