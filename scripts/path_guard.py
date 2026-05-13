#!/usr/bin/env python3
"""path_guard.py — PR path-change guard for the Obsidian Brain vault.

Model
-----
The Brain vault is operator-curated. Teammates may freely edit their own project
subspaces (e.g. ``01-nexus/``) and drop notes into the Claude inbox. Everything
else — decisions, runbooks, maps, automation, archives, and root-level
governance files — is considered protected and requires an explicit
``OPERATOR-APPROVED: <reason>`` line in the PR body before CI will let the
change through.

This script is meant to run inside a GitHub Actions PR workflow but also works
locally: when no PR body is supplied (neither ``--pr-body`` nor the ``PR_BODY``
env var), it falls back to scanning the most recent commit message for the
override marker so the operator can self-approve on their own machine.

Classification
--------------
Each changed path is bucketed as:

* ``protected``  — block unless override is present
* ``allowed``    — teammates may edit freely
* ``warn``       — operator-curated area; not blocking but flagged for review
* ``unknown``    — treated like ``warn`` so nothing slips through silently

Exit codes
----------
* ``0`` — allowed (possibly with warnings, or with override accepted)
* ``1`` — blocked (protected paths touched, no override marker)
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import PurePosixPath

# --- configuration -----------------------------------------------------------

PROTECTED_PREFIXES: tuple[str, ...] = (
    "_decisions/",
    "_maps/",
    "_runbooks/",
    "claude-context/",
    ".github/",
    "scripts/",
    "90-archive/",
)

PROTECTED_ROOT_FILES: frozenset[str] = frozenset({
    "00-DASHBOARD.md",
    "01-CURRENT-FOCUS.md",
    "BRAIN-RULES.md",
    "SYSTEM-AUDIT.md",
    "README.md",
    "CONTRIBUTING.md",
    "TEAMMATE-ONBOARDING.md",
    "FINAL-SHARING-CHECKLIST.md",
})

ALLOWED_PREFIXES: tuple[str, ...] = (
    "01-nexus/",
    "00-claude-inbox/nexus/",
    "00-claude-inbox/thesis/",
)

PROMOTE_PREFIX = "_promote-candidates/"
NEW_PROJECT_RE = re.compile(r"^0[3-9]-[^/]+/")  # 03-* through 09-*
OVERRIDE_RE = re.compile(r"^\s*OPERATOR-APPROVED:\s*(.+?)\s*$", re.IGNORECASE | re.MULTILINE)

# --- data --------------------------------------------------------------------

@dataclass
class Change:
    path: str
    status: str  # A/M/D/R/T/C

@dataclass
class Classified:
    protected: list[Change] = field(default_factory=list)
    allowed: list[Change] = field(default_factory=list)
    warn: list[tuple[Change, str]] = field(default_factory=list)  # (change, reason)

# --- helpers -----------------------------------------------------------------

def run_git_diff(base: str, head: str) -> list[Change]:
    """Return list of changed files between two SHAs, including renames."""
    cmd = [
        "git", "diff", "--name-status",
        "--diff-filter=ACMRTD",
        "--find-renames",
        base, head,
    ]
    try:
        out = subprocess.check_output(cmd, text=True)
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(f"path-guard: git diff failed: {exc}\n")
        sys.exit(2)
    except FileNotFoundError:
        sys.stderr.write("path-guard: git not on PATH\n")
        sys.exit(2)

    changes: list[Change] = []
    for line in out.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        status = parts[0]
        # Renames look like: R100\told\tnew  -> we care about the destination
        if status.startswith("R") or status.startswith("C"):
            if len(parts) >= 3:
                changes.append(Change(path=parts[2], status=status[0]))
        else:
            if len(parts) >= 2:
                changes.append(Change(path=parts[1], status=status[0]))
    return changes

def latest_commit_message() -> str:
    try:
        return subprocess.check_output(["git", "log", "-1", "--pretty=%B"], text=True)
    except Exception:
        return ""

def is_protected(path: str) -> bool:
    p = PurePosixPath(path).as_posix()
    if p in PROTECTED_ROOT_FILES:
        return True
    return any(p.startswith(pref) for pref in PROTECTED_PREFIXES)

def is_allowed(path: str) -> bool:
    return any(path.startswith(pref) for pref in ALLOWED_PREFIXES)

def classify(changes: list[Change]) -> Classified:
    out = Classified()
    for ch in changes:
        path = ch.path
        if is_protected(path):
            out.protected.append(ch)
        elif is_allowed(path):
            out.allowed.append(ch)
        elif path.startswith(PROMOTE_PREFIX):
            out.warn.append((ch, "promote-candidates: promotion still requires operator OK"))
        elif NEW_PROJECT_RE.match(path):
            out.warn.append((ch, "new top-level project added — operator should review structure"))
        else:
            out.warn.append((ch, "operator-curated area touched — flagged for review"))
    return out

def find_override(pr_body: str | None) -> str | None:
    text = pr_body or ""
    if not text:
        # fallback: scan last commit message (local-invocation self-approval)
        text = latest_commit_message()
    if not text:
        return None
    m = OVERRIDE_RE.search(text)
    return m.group(1).strip() if m else None

def format_paths(changes: list[Change], limit: int = 6) -> str:
    if not changes:
        return "(none)"
    items = [f"{c.status}:{c.path}" for c in changes[:limit]]
    extra = len(changes) - limit
    if extra > 0:
        items.append(f"...+{extra} more")
    return ", ".join(items)

# --- main --------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description="Brain vault PR path guard.")
    ap.add_argument("--base", required=True, help="Base SHA (merge target).")
    ap.add_argument("--head", default="HEAD", help="Head SHA (default HEAD).")
    ap.add_argument("--pr-body", default=None, help="PR body text (falls back to PR_BODY env).")
    ap.add_argument("--github-output", action="store_true", help="Emit GH Actions annotations.")
    ap.add_argument("--allow-no-changes", action="store_true", help="Don't fail on empty diff.")
    args = ap.parse_args()

    pr_body = args.pr_body if args.pr_body is not None else os.environ.get("PR_BODY")

    changes = run_git_diff(args.base, args.head)

    if not changes:
        msg = "path-guard: no files changed between base and head"
        if args.allow_no_changes:
            print(msg)
            if args.github_output:
                _set_output("result", "allowed")
            return 0
        print(msg + " (use --allow-no-changes to permit)")
        if args.github_output:
            print(f"::error::{msg}")
            _set_output("result", "blocked")
        return 1

    cls = classify(changes)
    override = find_override(pr_body)

    print(f"path-guard: {len(changes)} files changed")
    print(f"  PROTECTED (blocking unless OPERATOR-APPROVED): {format_paths(cls.protected)}")
    print(f"  ALLOWED:                                       {format_paths(cls.allowed)}")
    print(f"  WARN:                                          {format_paths([c for c, _ in cls.warn])}")

    # warnings → annotations
    if args.github_output:
        for ch, reason in cls.warn:
            print(f"::warning file={ch.path}::{reason}")

    # blocking decision
    if cls.protected and not override:
        print(
            f"RESULT: BLOCKED — {len(cls.protected)} protected file(s) touched, "
            "no OPERATOR-APPROVED marker in PR body."
        )
        print()
        print("How to override:")
        print("  Add a line to your PR description:")
        print("    OPERATOR-APPROVED: <short reason>")
        print("  Then re-run this workflow (push an empty commit or rerun from GitHub UI).")
        if args.github_output:
            for ch in cls.protected:
                print(f"::error file={ch.path}::Protected path edited without OPERATOR-APPROVED override")
            _set_output("result", "blocked")
        return 1

    if cls.protected and override:
        print(f"RESULT: ALLOWED with override. Override accepted: {override}")
        print("Protected files touched (reviewers, please sanity-check):")
        for ch in cls.protected:
            print(f"  - {ch.status} {ch.path}")
        if args.github_output:
            print(f"::notice::Override accepted: {override}")
            _set_output("result", "allowed")
        return 0

    if cls.warn and not cls.protected:
        print("RESULT: ALLOWED with warnings — see WARN list above; not blocking.")
        if args.github_output:
            _set_output("result", "allowed")
        return 0

    print("RESULT: ALLOWED — only teammate-editable paths touched.")
    if args.github_output:
        _set_output("result", "allowed")
    return 0

def _set_output(key: str, value: str) -> None:
    """Append a step output for GitHub Actions, if $GITHUB_OUTPUT is set."""
    path = os.environ.get("GITHUB_OUTPUT")
    if not path:
        return
    try:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(f"{key}={value}\n")
    except OSError as exc:
        sys.stderr.write(f"path-guard: could not write GITHUB_OUTPUT: {exc}\n")

if __name__ == "__main__":
    raise SystemExit(main())
