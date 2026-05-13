#!/usr/bin/env bash
# check-wslg.sh — detect WSL GUI (WSLg) support and report next steps
# for running Linux Obsidian inside WSL.
set -uo pipefail

# Color codes (skip if not a TTY)
if [[ -t 1 ]]; then
  RED=$'\033[31m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'
  BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; YELLOW=""; GREEN=""; BOLD=""; RESET=""
fi

say() { printf '%s\n' "$*"; }
hdr() { printf '\n%s== %s ==%s\n' "$BOLD" "$*" "$RESET"; }

# 1. Detect WSL
hdr "WSL detection"
if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
  say "${RED}ERROR:${RESET} \$WSL_DISTRO_NAME is empty — not running inside WSL."
  exit 1
fi
say "WSL distro: ${GREEN}${WSL_DISTRO_NAME}${RESET}"

# 2. Check WSLg signals
hdr "WSLg signal check"
WSLG_SIGNALS=0

if [[ -S /tmp/.X11-unix/X0 ]]; then
  say "  ${GREEN}[ok]${RESET} /tmp/.X11-unix/X0 socket present"
  WSLG_SIGNALS=$((WSLG_SIGNALS + 1))
else
  say "  ${YELLOW}[--]${RESET} /tmp/.X11-unix/X0 socket missing"
fi

if [[ -n "${DISPLAY:-}" ]]; then
  say "  ${GREEN}[ok]${RESET} \$DISPLAY=${DISPLAY}"
  WSLG_SIGNALS=$((WSLG_SIGNALS + 1))
else
  say "  ${YELLOW}[--]${RESET} \$DISPLAY is unset"
fi

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  say "  ${GREEN}[ok]${RESET} \$WAYLAND_DISPLAY=${WAYLAND_DISPLAY}"
  WSLG_SIGNALS=$((WSLG_SIGNALS + 1))
else
  say "  ${YELLOW}[--]${RESET} \$WAYLAND_DISPLAY is unset"
fi

if command -v glxinfo >/dev/null 2>&1; then
  if glxinfo -B >/dev/null 2>&1; then
    say "  ${GREEN}[ok]${RESET} glxinfo runs (GL stack reachable)"
    WSLG_SIGNALS=$((WSLG_SIGNALS + 1))
  else
    say "  ${YELLOW}[--]${RESET} glxinfo present but fails"
  fi
else
  say "  ${YELLOW}[--]${RESET} glxinfo not installed (optional)"
fi

# 3. Windows version
hdr "Windows host version"
WIN_VER_RAW="$(cmd.exe /c ver 2>/dev/null | tr -d '\r' | tr -d '\0')"
say "Raw: ${WIN_VER_RAW:-<unavailable>}"

WIN_BUILD=""
if [[ "$WIN_VER_RAW" =~ 10\.0\.([0-9]+) ]]; then
  WIN_BUILD="${BASH_REMATCH[1]}"
  say "Build: ${WIN_BUILD}"
fi

IS_WIN11=0
IS_WIN10=0
if [[ -n "$WIN_BUILD" ]]; then
  if (( WIN_BUILD >= 22000 )); then
    IS_WIN11=1
    say "Detected: ${GREEN}Windows 11${RESET} (build $WIN_BUILD)"
  elif (( WIN_BUILD >= 19041 && WIN_BUILD <= 19045 )); then
    IS_WIN10=1
    say "Detected: ${YELLOW}Windows 10${RESET} (build $WIN_BUILD)"
  else
    say "Detected: unknown Windows build ($WIN_BUILD)"
  fi
else
  say "${YELLOW}Could not parse Windows build.${RESET}"
fi

# 4. Decision tree
hdr "Verdict"
if (( WSLG_SIGNALS >= 2 )); then
  say "${GREEN}${BOLD}GREEN:${RESET} ${GREEN}WSLg appears active — ready to install Obsidian.${RESET}"
  say ""
  say "Next step:"
  say "  bash /home/nithu/Obsidian/Brain/scripts/install-obsidian-linux.sh"
  exit 0
elif (( IS_WIN11 == 1 )); then
  say "${YELLOW}${BOLD}YELLOW:${RESET} ${YELLOW}Windows 11 but WSLg signals weak.${RESET}"
  say ""
  say "Next step (run in Windows PowerShell, then reopen WSL):"
  say "  wsl --shutdown"
  say "  wsl --update"
  say "  # then reopen the WSL terminal and re-run this script"
  exit 0
elif (( IS_WIN10 == 1 )); then
  say "${RED}${BOLD}RED:${RESET} ${RED}Windows 10 — WSLg not available.${RESET}"
  say ""
  say "Next steps:"
  say "  1. Install VcXsrv on Windows: https://sourceforge.net/projects/vcxsrv/"
  say "  2. Launch XLaunch (disable access control)"
  say "  3. Add to ~/.bashrc:"
  say "     export DISPLAY=\$(grep nameserver /etc/resolv.conf | awk '{print \$2}'):0.0"
  say "     export LIBGL_ALWAYS_INDIRECT=1"
  exit 0
else
  say "${YELLOW}${BOLD}UNKNOWN:${RESET} could not classify host — manual review needed."
  exit 0
fi
