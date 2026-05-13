#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install-gh-cli.sh
#
# Installs the GitHub CLI (`gh`) on the operator's machine.
#
# Why this exists:
#   Needed for OPERATOR-NEXT-STEPS.md step 5+ in the brain vault:
#     - `gh repo create` to create the remote repository
#     - branch protection setup via `gh api`
#     - collaborator invites via `gh repo edit` / `gh api`
#
# Supported platforms:
#   - WSL / Ubuntu / Debian   -> official apt repo
#     (https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
#   - macOS                   -> `brew install gh`
#   - Other                   -> prints install URL and exits 1
#
# Flags:
#   --yes        Skip the confirmation prompt before `sudo` invocations
#   --help       Show this help and exit
# ---------------------------------------------------------------------------

set -euo pipefail

ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: install-gh-cli.sh [--yes] [--help]

Installs the GitHub CLI (`gh`).

Options:
  --yes     Skip confirmation prompt before sudo invocations.
  --help    Show this help message and exit.

Detects the OS:
  - WSL/Ubuntu/Debian -> official apt repo (requires sudo)
  - macOS             -> brew install gh
  - other             -> prints install URL and exits 1
EOF
}

for arg in "$@"; do
  case "$arg" in
    --yes) ASSUME_YES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage; exit 2 ;;
  esac
done

confirm() {
  # confirm "<message describing what will run>"
  local msg="$1"
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    echo "[--yes] $msg"
    return 0
  fi
  echo "About to run:"
  echo "  $msg"
  read -r -p "Proceed? [y/N] " ans
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) echo "Aborted by user."; exit 1 ;;
  esac
}

# Short-circuit if gh already on PATH
if command -v gh >/dev/null 2>&1; then
  echo "gh is already installed:"
  gh --version
  exit 0
fi

OS="$(uname -s)"

install_ubuntu_debian() {
  echo "Detected Ubuntu/Debian-family Linux. Installing gh via official apt repo."

  confirm "sudo mkdir -p -m 755 /etc/apt/keyrings && download GitHub CLI keyring -> /etc/apt/keyrings/githubcli-archive-keyring.gpg"
  sudo mkdir -p -m 755 /etc/apt/keyrings
  out="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
  wget -nv -O- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee "$out" > /dev/null
  sudo chmod go+r "$out"

  confirm "Write /etc/apt/sources.list.d/github-cli.list with the GitHub CLI apt repo"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=$out] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

  confirm "sudo apt update && sudo apt install gh -y"
  sudo apt update
  sudo apt install gh -y
}

install_macos() {
  echo "Detected macOS. Installing gh via Homebrew."
  if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: Homebrew (brew) not found. Install it first: https://brew.sh/" >&2
    exit 1
  fi
  confirm "brew install gh"
  brew install gh
}

if [[ "$OS" == "Linux" ]]; then
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}:${ID_LIKE:-}" in
      ubuntu*|debian*|*:*ubuntu*|*:*debian*) install_ubuntu_debian ;;
      *)
        echo "Unsupported Linux distro: ID=${ID:-unknown} ID_LIKE=${ID_LIKE:-unknown}" >&2
        echo "Install gh manually: https://github.com/cli/cli/blob/trunk/docs/install_linux.md" >&2
        exit 1
        ;;
    esac
  else
    echo "Cannot read /etc/os-release; unsupported Linux." >&2
    echo "Install gh manually: https://github.com/cli/cli/blob/trunk/docs/install_linux.md" >&2
    exit 1
  fi
elif [[ "$OS" == "Darwin" ]]; then
  install_macos
else
  echo "Unsupported OS: $OS" >&2
  echo "See install instructions: https://github.com/cli/cli#installation" >&2
  exit 1
fi

# Verify install
echo
echo "Verifying installation..."
if command -v gh >/dev/null 2>&1; then
  gh --version
else
  echo "ERROR: gh not found on PATH after install." >&2
  exit 1
fi

cat <<'EOF'

Next steps:
  1. Authenticate:   gh auth login
  2. Verify auth:    gh auth status
  3. Continue with OPERATOR-NEXT-STEPS.md step 5+.
EOF
