#!/usr/bin/env bash
# Linux Obsidian installer for WSL2. Renders via WSLg (Win11) or VcXsrv (Win10).
# Vault stays in Linux filesystem at ~/Obsidian/Brain — fast (no \\wsl$\ bridge).

set -uo pipefail

# -----------------------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------------------
ASSUME_YES=0
SKIP_DEPS=0
SKIP_LAUNCHER=0
VERSION_TAG=""

BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons"
APPIMAGE_PATH="${BIN_DIR}/Obsidian.AppImage"
DESKTOP_FILE="${APP_DIR}/obsidian.desktop"

GH_API="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"
GH_DL="https://github.com/obsidianmd/obsidian-releases/releases/download"

APT_DEPS=(libfuse2 libgtk-3-0 libnss3 libasound2 libxss1)

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
log()  { printf '\033[1;34m[install-obsidian]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install-obsidian]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[install-obsidian]\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

confirm() {
  [[ "${ASSUME_YES}" -eq 1 ]] && return 0
  local prompt="${1:-Continue?}"
  read -r -p "${prompt} [y/N] " ans
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--yes] [--version <tag>] [--no-deps] [--no-launcher]

  --yes              Skip confirmation prompts
  --version <tag>    Install specific version tag (e.g. v1.5.12); default: latest
  --no-deps          Skip apt install of AppImage runtime dependencies
  --no-launcher      Skip writing ~/.local/share/applications/obsidian.desktop
  -h, --help         Show this help
EOF
}

# -----------------------------------------------------------------------------
# Arg parsing
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)         ASSUME_YES=1; shift ;;
    --version)     VERSION_TAG="${2:-}"; shift 2 ;;
    --no-deps)     SKIP_DEPS=1; shift ;;
    --no-launcher) SKIP_LAUNCHER=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) err "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

# -----------------------------------------------------------------------------
# 1. Detect WSL + Windows version (WSLg vs VcXsrv)
# -----------------------------------------------------------------------------
log "Detecting WSL environment..."

if ! grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
  warn "This doesn't look like WSL. Continuing anyway — AppImage should still work on native Linux."
fi

HAS_WSLG=0
if [[ -S /tmp/.X11-unix/X0 ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ -d /mnt/wslg ]]; then
  HAS_WSLG=1
fi

WIN_VER=""
if command -v cmd.exe >/dev/null 2>&1; then
  WIN_VER="$(cmd.exe /c ver 2>/dev/null | tr -d '\r' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
fi

if [[ "${HAS_WSLG}" -eq 1 ]]; then
  log "WSLg detected (Windows 11 or WSL2 with GUI support). No X-server setup needed."
else
  warn "WSLg not detected. Windows version: ${WIN_VER:-unknown}"
  cat >&2 <<'EOF'

You appear to be on Windows 10 (no WSLg). Install an X-server on Windows first:

  1. Download VcXsrv: https://sourceforge.net/projects/vcxsrv/
  2. Run XLaunch with these settings:
       - Multiple windows
       - Start no client
       - Disable access control: CHECKED
  3. Add to ~/.bashrc (or ~/.zshrc):
       export DISPLAY=$(ip route | awk '/^default/ {print $3}'):0.0
       export LIBGL_ALWAYS_INDIRECT=1
  4. Re-source your shell, then re-run this script.

EOF
  exit 1
fi

# -----------------------------------------------------------------------------
# 2. Resolve version
# -----------------------------------------------------------------------------
if [[ -z "${VERSION_TAG}" ]]; then
  log "Resolving latest Obsidian release tag from GitHub..."
  VERSION_TAG="$(curl -fsSL "${GH_API}" 2>/dev/null | grep -oE '"tag_name":\s*"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/' || true)"
  [[ -z "${VERSION_TAG}" ]] && die "Could not resolve latest version from GitHub API. Try --version <tag>."
fi
log "Target version: ${VERSION_TAG}"

# Obsidian release tags are like "v1.5.12"; AppImage name uses the numeric part.
VERSION_NUM="${VERSION_TAG#v}"
APPIMAGE_NAME="Obsidian-${VERSION_NUM}.AppImage"
APPIMAGE_URL="${GH_DL}/${VERSION_TAG}/${APPIMAGE_NAME}"

# -----------------------------------------------------------------------------
# 3. Install AppImage runtime deps via apt
# -----------------------------------------------------------------------------
if [[ "${SKIP_DEPS}" -eq 0 ]]; then
  MISSING=()
  for pkg in "${APT_DEPS[@]}"; do
    if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
      MISSING+=("${pkg}")
    fi
  done

  if [[ "${#MISSING[@]}" -gt 0 ]]; then
    log "Missing apt packages: ${MISSING[*]}"
    if confirm "Install via sudo apt-get?"; then
      sudo apt-get update -y
      sudo apt-get install -y "${MISSING[@]}" || warn "apt-get install reported errors — continuing."
    else
      warn "Skipping apt install. Obsidian may fail to launch if deps are missing."
    fi
  else
    log "All AppImage runtime deps already present."
  fi
else
  log "Skipping apt install (--no-deps)."
fi

# -----------------------------------------------------------------------------
# 4. Download AppImage
# -----------------------------------------------------------------------------
mkdir -p "${BIN_DIR}"

if [[ -x "${APPIMAGE_PATH}" ]]; then
  CURRENT_VER="$("${APPIMAGE_PATH}" --version 2>/dev/null | head -1 || true)"
  log "Existing AppImage found (${CURRENT_VER:-version unknown})."
  if ! confirm "Overwrite with ${VERSION_TAG}?"; then
    log "Keeping existing AppImage. Skipping download."
  else
    rm -f "${APPIMAGE_PATH}"
  fi
fi

if [[ ! -x "${APPIMAGE_PATH}" ]]; then
  log "Downloading ${APPIMAGE_URL}"
  if ! curl -fL --progress-bar -o "${APPIMAGE_PATH}.tmp" "${APPIMAGE_URL}"; then
    rm -f "${APPIMAGE_PATH}.tmp"
    die "Download failed. Check the version tag and network."
  fi
  mv "${APPIMAGE_PATH}.tmp" "${APPIMAGE_PATH}"
  chmod +x "${APPIMAGE_PATH}"
  log "Installed: ${APPIMAGE_PATH}"
fi

# -----------------------------------------------------------------------------
# 5. Verify it runs
# -----------------------------------------------------------------------------
log "Verifying AppImage..."
if "${APPIMAGE_PATH}" --version >/dev/null 2>&1; then
  log "AppImage executes cleanly."
else
  warn "--version probe failed. AppImage may still work GUI-side; missing libfuse2 is the usual culprit."
fi

# -----------------------------------------------------------------------------
# 6. Desktop launcher (Win11 surfaces this in Start Menu via WSLg)
# -----------------------------------------------------------------------------
if [[ "${SKIP_LAUNCHER}" -eq 0 ]]; then
  mkdir -p "${APP_DIR}" "${ICON_DIR}"
  cat > "${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Type=Application
Name=Obsidian
Comment=Knowledge base on top of a local folder of Markdown files
Exec=${APPIMAGE_PATH} %U
Icon=obsidian
Terminal=false
Categories=Office;Utility;
MimeType=x-scheme-handler/obsidian;
StartupWMClass=obsidian
EOF
  chmod 644 "${DESKTOP_FILE}"
  log "Wrote launcher: ${DESKTOP_FILE}"

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${APP_DIR}" >/dev/null 2>&1 || true
  fi
else
  log "Skipping desktop launcher (--no-launcher)."
fi

# -----------------------------------------------------------------------------
# 7. Final hints
# -----------------------------------------------------------------------------
cat <<EOF

============================================================
Obsidian ${VERSION_TAG} installed.

Launch:
  - CLI:        ${APPIMAGE_PATH}
  - Start Menu: "Obsidian" (Win11 surfaces WSL apps automatically)

First-time setup:
  1. Choose "Open folder as vault" → ${HOME}/Obsidian/Brain
  2. Trust the author when prompted
  3. Settings → Community plugins → Turn on community plugins

Vault location (${HOME}/Obsidian/Brain) lives inside the Linux
filesystem — avoid moving it under /mnt/c/... (slow + breaks fsnotify).
============================================================
EOF
