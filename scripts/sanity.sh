#!/usr/bin/env bash
# sanity.sh — local pre-push gate for the Brain vault
#
# This is the one-command sanity check. Run it before `git push`.
# Equivalent to CI for non-PR contexts (CI runs the same checks on PRs).
#
# Usage:
#   bash scripts/sanity.sh
#   bash /home/nithu/Obsidian/Brain/scripts/sanity.sh
#
# Exit 0 if everything is green; exit 1 if any check fails.
# Each check runs even if previous failed — failures are collected and
# reported in a final summary.

set -euo pipefail

# Always run from vault root regardless of cwd
cd "$(dirname "$0")/.."

# --- state ---
FAILED=()
SECTION_FAILED=0
SECTION_NAME=""
PASSED=0
TOTAL=0

# --- pretty helpers ---
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

header() {
    # Close previous section if any
    if [ -n "$SECTION_NAME" ]; then
        if [ "$SECTION_FAILED" -eq 0 ]; then
            PASSED=$((PASSED+1))
            printf '  %s[OK]%s section: %s\n' "$GREEN" "$RESET" "$SECTION_NAME"
        else
            FAILED+=("$SECTION_NAME")
            printf '  %s[FAIL]%s section: %s\n' "$RED" "$RESET" "$SECTION_NAME"
        fi
    fi
    SECTION_NAME="$1"
    SECTION_FAILED=0
    TOTAL=$((TOTAL+1))
    printf '\n%s==> %s%s\n' "$BOLD" "$1" "$RESET"
}
note_pass() { printf '  %s[OK]%s %s\n' "$GREEN" "$RESET" "$1"; }
note_fail() { printf '  %s[FAIL]%s %s\n' "$RED" "$RESET" "$1"; SECTION_FAILED=1; }
note_skip() { printf '  %s[SKIP]%s %s\n' "$YELLOW" "$RESET" "$1"; }
close_sections() {
    if [ -n "$SECTION_NAME" ]; then
        if [ "$SECTION_FAILED" -eq 0 ]; then
            PASSED=$((PASSED+1))
            printf '  %s[OK]%s section: %s\n' "$GREEN" "$RESET" "$SECTION_NAME"
        else
            FAILED+=("$SECTION_NAME")
            printf '  %s[FAIL]%s section: %s\n' "$RED" "$RESET" "$SECTION_NAME"
        fi
        SECTION_NAME=""
    fi
}

# --- 1. brain_audit.py ---
header "brain_audit.py"
if python3 scripts/brain_audit.py; then
    note_pass "brain_audit.py exited 0"
else
    note_fail "brain_audit.py (non-zero exit)"
fi

# --- 2. path_guard.py (local) ---
header "path_guard.py (local)"
# Use HEAD^ fallback in case there's only one commit
BASE_REF="$(git rev-parse HEAD^ 2>/dev/null || git rev-parse HEAD)"
if python3 scripts/path_guard.py --base "$BASE_REF" --head HEAD --allow-no-changes; then
    note_pass "path_guard.py exited 0"
else
    note_fail "path_guard.py (non-zero exit)"
fi

# --- 3. YAML syntax ---
header "YAML syntax (.github/workflows)"
if python3 -c 'import yaml' 2>/dev/null; then
    for f in .github/workflows/*.yml; do
        [ -e "$f" ] || continue
        if python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$f" 2>/dev/null; then
            note_pass "parsed $f"
        else
            note_fail "invalid YAML: $f"
        fi
    done
else
    note_skip "skipped (no pyyaml)"
fi

# --- 4. Python syntax ---
header "Python syntax (scripts/*.py)"
if python3 -m py_compile scripts/*.py 2>&1; then
    note_pass "all scripts/*.py compile cleanly"
else
    note_fail "Python syntax errors in scripts/*.py"
fi

# --- 5. Bash syntax ---
header "Bash syntax (scripts/*.sh)"
bash_ok=1
for f in scripts/*.sh; do
    [ -e "$f" ] || continue
    if ! bash -n "$f" 2>&1; then
        note_fail "bash syntax error: $f"
        bash_ok=0
    fi
done
if [ "$bash_ok" -eq 1 ]; then
    note_pass "all scripts/*.sh parse cleanly"
fi

# --- 6. Required files presence ---
header "Required files presence"
REQUIRED=(
    "README.md"
    "BRAIN-RULES.md"
    "00-DASHBOARD.md"
    "claude-context/START-HERE.md"
    "scripts/brain_audit.py"
    "scripts/path_guard.py"
    ".github/CODEOWNERS"
    "SYSTEM-AUDIT.md"
)
missing=0
for f in "${REQUIRED[@]}"; do
    if ! test -f "$f"; then
        note_fail "missing: $f"
        missing=$((missing+1))
    fi
done
if [ "$missing" -eq 0 ]; then
    note_pass "all 8 required files present"
fi

# --- 7. gitignore protects secrets ---
header "gitignore protects local REST API secret"
SECRET_PATH=".obsidian/plugins/obsidian-local-rest-api/data.json"
if git check-ignore -q "$SECRET_PATH" 2>/dev/null; then
    note_pass "$SECRET_PATH is gitignored"
else
    note_fail "$SECRET_PATH NOT gitignored (or git check-ignore unavailable)"
fi

# --- 8. No secret-like strings in tracked files ---
header "No secret-like strings in tracked files"
HITS="$(git ls-files -z \
    | xargs -0 grep -nE 'ghp_[a-zA-Z0-9]{30,}|sk-ant-[a-zA-Z0-9_-]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]+PRIVATE KEY-----' 2>/dev/null \
    | grep -v 'SECURITY-INCIDENT' \
    | grep -v 'scripts/sanity.sh' \
    | grep -v 'scripts/brain_audit.py' \
    || true)"
if [ -z "$HITS" ]; then
    note_pass "no secret-like strings found"
else
    note_fail "secret-like strings found in tracked files:"
    printf '%s\n' "$HITS" | sed 's/^/    /'
fi

# Close the final section
close_sections

# --- summary ---
printf '\n%s================================%s\n' "$BOLD" "$RESET"
if [ "${#FAILED[@]}" -eq 0 ]; then
    printf '%ssanity: %d/%d checks passed%s\n' "$GREEN" "$PASSED" "$TOTAL" "$RESET"
    exit 0
else
    printf '%ssanity: %d/%d checks passed (%d failed)%s\n' \
        "$RED" "$PASSED" "$TOTAL" "${#FAILED[@]}" "$RESET"
    printf '\nFailed checks:\n'
    for f in "${FAILED[@]}"; do
        printf '  - %s\n' "$f"
    done
    exit 1
fi
