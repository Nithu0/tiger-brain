#!/usr/bin/env bash
# Nexus bash profile fragment — sourced from ~/.bashrc on every interactive shell.
#
# Provides:
#   - Oh My Posh prompt with the nexus-batman theme (same as PowerShell)
#   - Aliases: firm-status, firm-talk, wake, firm-start, firm-init
#
# Repo location is read from $NEXUS_REPO (set by install.sh in your env),
# defaulting to ~/code/ai-assistent.

# --- repo + theme paths ----------------------------------------------------

if [[ -z "${NEXUS_REPO:-}" ]]; then
    if [[ -d "$HOME/code/ai-assistent" ]]; then
        export NEXUS_REPO="$HOME/code/ai-assistent"
    fi
fi

NEXUS_TOOLS_DIR="${NEXUS_REPO:-}/tools/terminal"
NEXUS_THEME_PATH="$NEXUS_TOOLS_DIR/oh-my-posh/nexus-batman.omp.json"

# --- Oh My Posh init -------------------------------------------------------

if command -v oh-my-posh >/dev/null 2>&1; then
    if [[ -f "$NEXUS_THEME_PATH" ]]; then
        eval "$(oh-my-posh init bash --config "$NEXUS_THEME_PATH")"
    else
        eval "$(oh-my-posh init bash)"
        echo "[nexus] theme not found at $NEXUS_THEME_PATH -- using default theme."
    fi
fi

# --- aliases for Nexus firm scripts ---------------------------------------

firm-status() {
    local script="${NEXUS_REPO}/scripts/firm/status.mjs"
    if [[ ! -f "$script" ]]; then
        echo "firm-status: $script not found. Set NEXUS_REPO."
        return 1
    fi
    node "$script" "$@"
}

firm-talk() {
    local script="${NEXUS_REPO}/scripts/firm/talk.mjs"
    if [[ ! -f "$script" ]]; then
        echo "firm-talk: $script not found. Set NEXUS_REPO."
        return 1
    fi
    node "$script" "$@"
}

firm-start() {
    local script="${NEXUS_REPO}/scripts/firm/start.sh"
    if [[ ! -f "$script" ]]; then
        echo "firm-start: $script not found. Set NEXUS_REPO."
        return 1
    fi
    bash "$script" "$@"
}

firm-init() {
    local script="${NEXUS_REPO}/scripts/firm/init.mjs"
    if [[ ! -f "$script" ]]; then
        echo "firm-init: $script not found. Set NEXUS_REPO."
        return 1
    fi
    node "$script" "$@"
}

# wake "<message>" -- drop a wake.txt into the local firm control dir so the
# orchestrator picks it up next tick.
wake() {
    local msg="$*"
    if [[ -z "${msg// }" ]]; then
        echo 'wake: message required. Usage: wake "check overnight pnl"'
        return 1
    fi
    local firm_root="${FIRM_LOCAL_ROOT:-$HOME/nexus-firm-local}"
    local control_dir="$firm_root/control"
    mkdir -p "$control_dir"
    local wake_file="$control_dir/wake.txt"
    printf '%s' "$msg" > "$wake_file"
    echo "[wake] wrote to $wake_file"
}

# --- helpful printout on first launch -------------------------------------

if [[ -z "${NEXUS_PROFILE_SILENT:-}" && -n "${NEXUS_REPO:-}" ]]; then
    echo
    echo "  Nexus shell ready"
    echo "  repo:     $NEXUS_REPO"
    echo "  commands: firm-status | firm-talk | wake \"<msg>\" | firm-start | firm-init"
    echo
    export NEXUS_PROFILE_SILENT=1
fi

# --- FIRM_ROLE prompt prefix ----------------------------------------------
# When this shell was launched via firm-wt-split.sh / firm-wt-tabs.sh /
# firm-zellij.sh (i.e. `firm` / `firmt` / `firmz`), FIRM_ROLE is exported in
# the environment. We prepend a bold-cyan [role] tag to PS1 so the operator
# can tell panes apart at a glance.
#
# IMPORTANT: this block MUST run AFTER `oh-my-posh init bash` above, because
# oh-my-posh installs its own PROMPT_COMMAND that rebuilds PS1 each tick. We
# capture whatever PROMPT_COMMAND oh-my-posh left behind, then wrap it so the
# theme renders first and our prefix is prepended last (so it survives).
if [[ -n "${FIRM_ROLE:-}" ]]; then
    _NEXUS_OMP_PROMPT_COMMAND="${PROMPT_COMMAND:-}"
    _nexus_firm_prefix_apply() {
        # Run oh-my-posh's prompt builder first (if any), so $PS1 is fresh.
        if [[ -n "${_NEXUS_OMP_PROMPT_COMMAND:-}" ]]; then
            eval "$_NEXUS_OMP_PROMPT_COMMAND"
        fi
        # Bold cyan = \[\e[1;36m\], reset = \[\e[0m\].
        PS1="\[\e[1;36m\][${FIRM_ROLE}]\[\e[0m\] $PS1"
    }
    PROMPT_COMMAND='_nexus_firm_prefix_apply'
fi
