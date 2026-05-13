#!/usr/bin/env python3
"""
brain_audit.py — structural and hygiene audit for the Obsidian Brain vault.

Runs from `scripts/`. Vault root is one directory up. Standard-library only,
Python 3.11+. Exit code 0 = pass, 1 = fail (errors found, or warnings under
--strict).

Checks (one function per check, each returning list[Finding]):
  1.  required_files
  2.  required_folders
  3.  secret_scan
  4.  broken_wikilinks       (warning-level)
  5.  duplicate_current_md
  6.  current_in_archive
  7.  todo_in_sources        (warning-level)
  8.  big_generated_folders
  9.  unsupported_binaries   (warning-level)
  10. nexus_linked_from_dashboard
  11. decision_log_presence
  12. handoff_file           (warning-level)

Flags:
  --strict          warnings become errors for exit-code purposes
  --github-output   emit ::error / ::warning annotations for GitHub Actions
  --root <path>     override vault root (for testing)
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

# ---------- types ----------

LEVEL_ERROR = "error"
LEVEL_WARN = "warning"

SKIP_DIRS = {".git", ".obsidian", "90-archive"}
SKIP_DIRS_FOR_BINARIES = {".obsidian", "90-archive"}

REQUIRED_FILES = [
    "README.md",
    "BRAIN-RULES.md",
    "00-DASHBOARD.md",
    "01-CURRENT-FOCUS.md",
    "SYSTEM-AUDIT.md",
    "CONTRIBUTING.md",
    "TEAMMATE-ONBOARDING.md",
    ".github/CODEOWNERS",
    ".github/pull_request_template.md",
    ".github/workflows/brain-checks.yml",
    ".github/workflows/path-guard.yml",
    "claude-context/START-HERE.md",
    "claude-context/RULES.md",
    "claude-context/SYSTEM-MAP.md",
    "claude-context/CURRENT.md",
    "scripts/brain_audit.py",
    "scripts/path_guard.py",
    "prompts/CLAUDE-BRAIN-AUDIT-PROMPT.md",
    "prompts/CLAUDE-NEXUS-WORKER-PROMPT.md",
    "prompts/CLAUDE-HANDOFF-PROMPT.md",
]

REQUIRED_FOLDERS = [
    "00-claude-inbox",
    "01-nexus",
    "02-thesis",
    "03-business",
    "04-career",
    "05-learning",
    "90-archive",
    "_decisions",
    "_maps",
    "_runbooks",
    "claude-context",
    "scripts",
    ".github",
    "prompts",
]

BIG_GENERATED = {
    "node_modules", ".venv", "venv", "__pycache__",
    "dist", "build", ".next", "target",
}

BINARY_EXTS = {
    ".exe", ".dll", ".so", ".dylib",
    ".zip", ".tar", ".gz", ".7z",
    ".mp4", ".mov",
}

SOURCE_OF_TRUTH = [
    "README.md", "00-DASHBOARD.md", "01-CURRENT-FOCUS.md", "BRAIN-RULES.md",
]

# ---------- secret patterns ----------

SECRET_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("openai-key", re.compile(r"\bsk-[A-Za-z0-9]{20,}\b")),
    ("anthropic-key", re.compile(r"\bsk-ant-[A-Za-z0-9_\-]{20,}\b")),
    ("github-token", re.compile(r"\bgh[poursr]_[A-Za-z0-9]{20,}\b")),
    ("aws-access-key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("jwt-like", re.compile(r"\b[A-Za-z0-9._-]{20,}\.[A-Za-z0-9._-]{20,}\.[A-Za-z0-9._-]{20,}\b")),
    ("generic-secret",
     re.compile(r"""(?ix)
        (?P<key>secret|token|password|api[_-]?key)
        \s*[:=]\s*
        ['"]?(?P<val>[A-Za-z0-9_\-]{16,})['"]?
     """)),
]

# allow env-var name mentions or empty values: KEY=  or just bare API_KEY
ENV_NAME_ONLY = re.compile(r"^[A-Z][A-Z0-9_]*$")


@dataclass
class Finding:
    level: str        # "error" or "warning"
    msg: str
    path: str         # repo-relative; "" if vault-global
    line: int = 0     # 0 = no line


# ---------- helpers ----------

def iter_md_files(root: Path, skip: set[str]) -> Iterable[Path]:
    for dirpath, dirnames, filenames in os.walk(root):
        # prune
        dirnames[:] = [d for d in dirnames if d not in skip]
        for f in filenames:
            if f.lower().endswith(".md"):
                yield Path(dirpath) / f


def iter_all_files(root: Path, skip: set[str]) -> Iterable[Path]:
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in skip]
        for f in filenames:
            yield Path(dirpath) / f


def rel(root: Path, p: Path) -> str:
    try:
        return str(p.relative_to(root))
    except ValueError:
        return str(p)


def redact(s: str, keep: int = 4) -> str:
    if len(s) <= keep * 2:
        return "***"
    return f"{s[:keep]}…{s[-keep:]}"


# ---------- checks ----------

def check_required_files(root: Path) -> list[Finding]:
    out: list[Finding] = []
    for f in REQUIRED_FILES:
        if not (root / f).is_file():
            out.append(Finding(LEVEL_ERROR, f"missing required file: {f}", f))
    return out


def check_required_folders(root: Path) -> list[Finding]:
    out: list[Finding] = []
    for d in REQUIRED_FOLDERS:
        if not (root / d).is_dir():
            out.append(Finding(LEVEL_ERROR, f"missing required folder: {d}/", d))
    return out


def check_secret_scan(root: Path) -> list[Finding]:
    out: list[Finding] = []
    for md in iter_md_files(root, SKIP_DIRS):
        try:
            text = md.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            for name, pat in SECRET_PATTERNS:
                for m in pat.finditer(line):
                    # filter false positives for generic-secret
                    if name == "generic-secret":
                        val = m.group("val")
                        # skip if it's just an env var name in caps
                        if ENV_NAME_ONLY.match(val):
                            continue
                        # skip placeholder-y values
                        if val.lower() in {"your_key_here", "xxx", "todo", "placeholder", "example"}:
                            continue
                        matched = val
                    else:
                        matched = m.group(0)
                    out.append(Finding(
                        LEVEL_ERROR,
                        f"possible secret ({name}): {redact(matched)}",
                        rel(root, md),
                        lineno,
                    ))
    return out


WIKILINK_RE = re.compile(r"\[\[([^\[\]\|\n]+?)(?:\|[^\[\]\n]*)?\]\]")
URL_LIKE = re.compile(r"^[a-z]+://", re.IGNORECASE)

# Fenced code-block opener: ``` or ~~~ (optionally followed by an info string).
_FENCE_RE = re.compile(r"^(\s*)(`{3,}|~{3,})\s*([^\s`~]*)\s*$")
# Inline single-backtick code spans on a single line. We deliberately do NOT
# match across newlines (Markdown inline code can't span lines), and we keep
# this conservative: one or more backticks delimiting a span.
_INLINE_CODE_RE = re.compile(r"`+[^`\n]*?`+")


def _filter_markdown_text(content: str) -> str:
    """Return `content` with markdown code regions and YAML frontmatter
    blanked out (replaced by empty lines / spaces) so downstream regex
    checks won't match inside them.

    Strips:
      - YAML frontmatter at top of file (between two `---` lines)
      - Triple-backtick or triple-tilde fenced blocks (multi-line)
      - Inline single-backtick code spans (`...`) on a single line

    Line count is preserved so reported line numbers stay accurate.
    """
    lines = content.splitlines(keepends=False)
    n = len(lines)
    i = 0

    # YAML frontmatter: only if the very first line is exactly `---`.
    if n > 0 and lines[0].strip() == "---":
        j = 1
        while j < n and lines[j].strip() != "---":
            j += 1
        if j < n:
            # Blank out frontmatter including the closing `---`.
            for k in range(0, j + 1):
                lines[k] = ""
            i = j + 1

    # Fenced code blocks. Track opener fence char + length; close needs
    # matching fence char with at least as many chars and no trailing
    # info string.
    while i < n:
        m = _FENCE_RE.match(lines[i])
        if m:
            fence = m.group(2)
            fence_char = fence[0]
            fence_len = len(fence)
            # blank the opening fence line
            lines[i] = ""
            i += 1
            while i < n:
                line = lines[i]
                stripped = line.lstrip()
                if stripped.startswith(fence_char * fence_len):
                    # Closing fence: same char, >= length, nothing but
                    # the fence on the line (info strings only allowed
                    # on openers).
                    rest = stripped.lstrip(fence_char)
                    if rest.strip() == "":
                        lines[i] = ""
                        i += 1
                        break
                lines[i] = ""
                i += 1
        else:
            i += 1

    # Inline code spans on surviving lines.
    out_lines: list[str] = []
    for line in lines:
        if "`" in line:
            # Replace inline spans with spaces to preserve column count.
            line = _INLINE_CODE_RE.sub(lambda mm: " " * len(mm.group(0)), line)
        out_lines.append(line)

    return "\n".join(out_lines)


def check_broken_wikilinks(root: Path) -> list[Finding]:
    # build index of all md basenames (lowercase, no extension)
    index: set[str] = set()
    for md in iter_md_files(root, {".git", ".obsidian"}):  # archive included for targets
        index.add(md.stem.lower())

    out: list[Finding] = []
    broken: list[tuple[str, int, str]] = []
    for md in iter_md_files(root, SKIP_DIRS):
        try:
            text = md.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        # Strip code blocks / frontmatter so documentation examples don't
        # get flagged as broken wikilinks.
        filtered = _filter_markdown_text(text)
        for lineno, line in enumerate(filtered.splitlines(), 1):
            for m in WIKILINK_RE.finditer(line):
                target = m.group(1).strip()
                if not target:
                    continue
                if URL_LIKE.match(target):
                    continue
                if target.lower().startswith("stub:"):
                    continue
                # strip subpath/heading anchors
                base = target.split("#", 1)[0].split("/")[-1].strip()
                if not base:
                    continue
                key = base.lower()
                if key.endswith(".md"):
                    key = key[:-3]
                if key not in index:
                    broken.append((rel(root, md), lineno, target))

    # cap to top 20
    for path, lineno, target in broken[:20]:
        out.append(Finding(LEVEL_WARN, f"broken wikilink: [[{target}]]", path, lineno))
    if len(broken) > 20:
        out.append(Finding(
            LEVEL_WARN,
            f"...and {len(broken) - 20} more broken wikilinks (showing top 20)",
            "",
        ))
    return out


def check_duplicate_current_md(root: Path) -> list[Finding]:
    out: list[Finding] = []
    for md in iter_md_files(root, SKIP_DIRS):
        if md.name == "CURRENT.md":
            rp = rel(root, md)
            if not rp.startswith("claude-context/"):
                out.append(Finding(
                    LEVEL_ERROR,
                    "duplicate CURRENT.md outside claude-context/",
                    rp,
                ))
    return out


def check_current_in_archive(root: Path) -> list[Finding]:
    out: list[Finding] = []
    archive = root / "90-archive"
    if not archive.is_dir():
        return out
    for dirpath, _, filenames in os.walk(archive):
        for f in filenames:
            if "CURRENT" in f:
                out.append(Finding(
                    LEVEL_ERROR,
                    f"file marked CURRENT inside 90-archive/: {f}",
                    rel(root, Path(dirpath) / f),
                ))
    return out


TODO_RE = re.compile(r"\b(TODO|FIXME)\b")


def _active_todos_section(text: str) -> str:
    """Return the 'Active TODOs' section body from 01-CURRENT-FOCUS.md if present."""
    lines = text.splitlines()
    out_lines: list[str] = []
    inside = False
    for ln in lines:
        if re.match(r"^#+\s*Active TODOs", ln, re.IGNORECASE):
            inside = True
            continue
        if inside:
            if re.match(r"^#+\s+", ln):
                break
            out_lines.append(ln)
    return "\n".join(out_lines)


def check_todo_in_sources(root: Path) -> list[Finding]:
    out: list[Finding] = []

    # gather "allowed" TODO contexts from 01-CURRENT-FOCUS.md Active TODOs section
    allowed_lines: set[str] = set()
    focus = root / "01-CURRENT-FOCUS.md"
    if focus.is_file():
        try:
            active = _active_todos_section(focus.read_text(encoding="utf-8", errors="replace"))
            for ln in active.splitlines():
                stripped = ln.strip()
                if stripped:
                    allowed_lines.add(stripped)
        except OSError:
            pass

    targets: list[Path] = []
    for name in SOURCE_OF_TRUTH:
        p = root / name
        if p.is_file():
            targets.append(p)
    for sub in ("_decisions", "_maps"):
        d = root / sub
        if d.is_dir():
            for md in d.glob("*.md"):
                targets.append(md)

    for md in targets:
        try:
            text = md.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        is_focus = md.name == "01-CURRENT-FOCUS.md"
        if is_focus:
            # only scan outside the Active TODOs section
            active = _active_todos_section(text)
            scan_text = text.replace(active, "")
        else:
            scan_text = text
        for lineno, line in enumerate(scan_text.splitlines(), 1):
            if TODO_RE.search(line):
                if line.strip() in allowed_lines:
                    continue
                out.append(Finding(
                    LEVEL_WARN,
                    f"unanchored TODO/FIXME in source-of-truth file: {line.strip()[:120]}",
                    rel(root, md),
                    lineno,
                ))
    return out


def check_big_generated_folders(root: Path) -> list[Finding]:
    out: list[Finding] = []
    for dirpath, dirnames, _ in os.walk(root):
        # prune .git/.obsidian for speed, but check for big generated dirs everywhere else
        dirnames[:] = [d for d in dirnames if d not in {".git", ".obsidian"}]
        for d in list(dirnames):
            if d in BIG_GENERATED:
                full = Path(dirpath) / d
                out.append(Finding(
                    LEVEL_ERROR,
                    f"generated folder should not be in vault: {d}/",
                    rel(root, full),
                ))
    return out


def check_unsupported_binaries(root: Path) -> list[Finding]:
    out: list[Finding] = []
    one_mb = 1024 * 1024
    skip = {".git"} | SKIP_DIRS_FOR_BINARIES
    for f in iter_all_files(root, skip):
        ext = f.suffix.lower()
        try:
            size = f.stat().st_size
        except OSError:
            continue
        if ext in BINARY_EXTS:
            out.append(Finding(
                LEVEL_WARN,
                f"unsupported binary type ({ext})",
                rel(root, f),
            ))
        elif size > one_mb:
            out.append(Finding(
                LEVEL_WARN,
                f"large file ({size // 1024} KB > 1 MB)",
                rel(root, f),
            ))
    return out


def check_nexus_linked_from_dashboard(root: Path) -> list[Finding]:
    out: list[Finding] = []
    dash = root / "00-DASHBOARD.md"
    if not dash.is_file():
        # already reported by required_files
        return out
    try:
        text = dash.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return out
    if "[[Nexus-MOC]]" in text:
        return out
    if "01-nexus/" in text or "01-nexus]]" in text or "[[01-nexus" in text:
        return out
    out.append(Finding(
        LEVEL_ERROR,
        "00-DASHBOARD.md missing link to [[Nexus-MOC]] or 01-nexus/",
        "00-DASHBOARD.md",
    ))
    return out


def check_decision_log_presence(root: Path) -> list[Finding]:
    out: list[Finding] = []
    d = root / "_decisions"
    if not d.is_dir():
        return out  # already reported
    md_files = list(d.glob("*.md"))
    if not md_files:
        out.append(Finding(
            LEVEL_WARN,
            "_decisions/ has no .md files",
            "_decisions",
        ))
        return out
    newest = max((f.stat().st_mtime for f in md_files), default=0)
    age_days = (time.time() - newest) / 86400.0
    if age_days > 60:
        out.append(Finding(
            LEVEL_WARN,
            f"_decisions/ newest entry is {age_days:.0f} days old (>60)",
            "_decisions",
        ))
    return out


def check_handoff_file(root: Path) -> list[Finding]:
    out: list[Finding] = []
    handoffs = root / "handoffs"
    if not handoffs.is_dir():
        out.append(Finding(
            LEVEL_WARN,
            "no handoffs/ directory (structural advice — not required)",
            "handoffs",
        ))
        return out
    current = handoffs / "CURRENT-HANDOFF.md"
    if current.is_file():
        return out
    any_md = any(handoffs.glob("*.md"))
    if not any_md:
        out.append(Finding(
            LEVEL_WARN,
            "handoffs/ exists but contains no .md files",
            "handoffs",
        ))
    return out


# ---------- runner / output ----------

CHECKS: list[tuple[str, callable]] = [
    ("required_files", check_required_files),
    ("required_folders", check_required_folders),
    ("secret_scan", check_secret_scan),
    ("broken_wikilinks", check_broken_wikilinks),
    ("duplicate_current_md", check_duplicate_current_md),
    ("current_in_archive", check_current_in_archive),
    ("todo_in_sources", check_todo_in_sources),
    ("big_generated_folders", check_big_generated_folders),
    ("unsupported_binaries", check_unsupported_binaries),
    ("nexus_linked_from_dashboard", check_nexus_linked_from_dashboard),
    ("decision_log_presence", check_decision_log_presence),
    ("handoff_file", check_handoff_file),
]


def suggest_next(findings: list[tuple[str, Finding]]) -> str:
    errors = [(c, f) for c, f in findings if f.level == LEVEL_ERROR]
    warns = [(c, f) for c, f in findings if f.level == LEVEL_WARN]
    if errors:
        c, f = errors[0]
        return f"Suggested next action: fix [{c}] {f.msg} ({f.path or 'vault'})"
    if warns:
        c, f = warns[0]
        return f"Suggested next action: review [{c}] {f.msg} ({f.path or 'vault'})"
    return "Suggested next action: nothing — vault audit clean."


def emit_human(findings_by_check: dict[str, list[Finding]]) -> tuple[int, int]:
    total_err = 0
    total_warn = 0
    for name, _ in CHECKS:
        items = findings_by_check.get(name, [])
        errs = sum(1 for f in items if f.level == LEVEL_ERROR)
        wrns = sum(1 for f in items if f.level == LEVEL_WARN)
        total_err += errs
        total_warn += wrns
        if not items:
            print(f"[{name}] OK")
            continue
        print(f"[{name}] {errs} error(s), {wrns} warning(s)")
        for f in items:
            loc = f.path or "(vault)"
            if f.line:
                loc += f":{f.line}"
            print(f"  - {f.level.upper()}: {f.msg}  @ {loc}")
    return total_err, total_warn


def emit_github(findings_by_check: dict[str, list[Finding]]) -> tuple[int, int]:
    total_err = 0
    total_warn = 0
    for name, _ in CHECKS:
        for f in findings_by_check.get(name, []):
            kind = "error" if f.level == LEVEL_ERROR else "warning"
            path = f.path or "."
            line_part = f",line={f.line}" if f.line else ""
            msg = f"[{name}] {f.msg}".replace("\n", " ")
            print(f"::{kind} file={path}{line_part}::{msg}")
            if f.level == LEVEL_ERROR:
                total_err += 1
            else:
                total_warn += 1
    print(f"::notice::brain_audit summary — {total_err} error(s), {total_warn} warning(s)")
    return total_err, total_warn


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit the Obsidian Brain vault.")
    parser.add_argument("--strict", action="store_true",
                        help="treat warnings as errors for exit code")
    parser.add_argument("--github-output", action="store_true",
                        help="emit GitHub Actions annotations")
    parser.add_argument("--root", type=str, default=None,
                        help="override vault root (default: parent of this script)")
    args = parser.parse_args()

    here = Path(__file__).resolve().parent
    root = Path(args.root).resolve() if args.root else here.parent
    if not root.is_dir():
        print(f"vault root not a directory: {root}", file=sys.stderr)
        return 1

    findings_by_check: dict[str, list[Finding]] = {}
    flat: list[tuple[str, Finding]] = []
    for name, fn in CHECKS:
        try:
            results = fn(root)
        except Exception as exc:  # pragma: no cover — defensive
            results = [Finding(LEVEL_ERROR, f"check raised: {exc!r}", "")]
        findings_by_check[name] = results
        for f in results:
            flat.append((name, f))

    if args.github_output:
        errs, warns = emit_github(findings_by_check)
    else:
        errs, warns = emit_human(findings_by_check)
        if errs == 0 and warns == 0:
            print("PASS")
        else:
            print(f"{'FAIL' if errs else 'PASS-with-warnings'}: {errs} errors, {warns} warnings")

    print(suggest_next(flat))

    if errs > 0:
        return 1
    if args.strict and warns > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
