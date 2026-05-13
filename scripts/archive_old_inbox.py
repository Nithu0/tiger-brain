#!/usr/bin/env python3
"""Archive old Claude-inbox entries.

Implements the lifecycle promised in ``00-claude-inbox/README.md``:

    "Inbox entries auto-archived after 30 days into
     90-archive/inbox/<YYYY-MM>/"

Behavior
--------
- Walks ``00-claude-inbox/<project>/*.md`` files (e.g. ``nexus/``, ``thesis/``).
- For each file, determines age:
    1. Preferred: parse ``YYYY-MM-DD-`` prefix from filename.
    2. Fallback: use file mtime.
- A file is "old" when its date is more than ``--max-age-days`` (default 30)
  before today.
- Old files are moved to:
    ``90-archive/inbox/<project>/<YYYY-MM>/<filename>``
  preserving the project subfolder. The ``<YYYY-MM>`` comes from the parsed /
  fallback date.
- ``README.md`` and ``_README.md`` files at any level are skipped.

Safety
------
- Source files must live inside ``00-claude-inbox/``.
- Target paths must live inside ``90-archive/inbox/``.
- Default is ``--dry-run`` (prints plan, makes no moves). ``--apply`` actually
  moves files, with an interactive confirmation before the first move unless
  ``--yes`` is also passed.
- If a target file already exists, the new file is renamed with a
  ``-DUPE-N.md`` suffix so nothing is clobbered.

Exit code: 0 on success, 1 on error.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

INBOX_DIRNAME = "00-claude-inbox"
ARCHIVE_DIRNAME = "90-archive"
ARCHIVE_INBOX_SUBPATH = ("90-archive", "inbox")
SKIP_FILENAMES = {"README.md", "_README.md"}
DATE_PREFIX_RE = re.compile(r"^(\d{4})-(\d{2})-(\d{2})-")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Archive old entries from 00-claude-inbox/ into "
            "90-archive/inbox/<project>/<YYYY-MM>/. Dry-run by default."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Use --apply to actually move files. Add --yes to skip prompt.",
    )
    parser.add_argument(
        "--max-age-days",
        type=int,
        default=30,
        help="Files older than this many days are archived (default: 30).",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually move files. Without this, runs in dry-run mode.",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Skip interactive confirmation before the first move.",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help=(
            "Brain root path. Default: parent of the directory containing "
            "this script."
        ),
    )
    parser.add_argument(
        "--project",
        type=str,
        default=None,
        help="Restrict archiving to a single project subfolder (e.g. 'nexus').",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Suppress per-file output. Only print the summary.",
    )
    return parser.parse_args(argv)


def resolve_root(root: Path | None) -> Path:
    if root is not None:
        return root.resolve()
    return Path(__file__).resolve().parent.parent


def date_from_filename(name: str) -> date | None:
    m = DATE_PREFIX_RE.match(name)
    if not m:
        return None
    try:
        return date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    except ValueError:
        return None


def file_age_date(path: Path) -> date:
    parsed = date_from_filename(path.name)
    if parsed is not None:
        return parsed
    return datetime.fromtimestamp(path.stat().st_mtime).date()


def is_inside(child: Path, parent: Path) -> bool:
    try:
        child.resolve().relative_to(parent.resolve())
        return True
    except ValueError:
        return False


def unique_target(target: Path) -> Path:
    if not target.exists():
        return target
    stem = target.stem
    suffix = target.suffix or ".md"
    n = 1
    while True:
        candidate = target.with_name(f"{stem}-DUPE-{n}{suffix}")
        if not candidate.exists():
            return candidate
        n += 1


def discover_candidates(
    inbox_root: Path, project_filter: str | None
) -> list[Path]:
    if not inbox_root.is_dir():
        return []
    out: list[Path] = []
    for project_dir in sorted(inbox_root.iterdir()):
        if not project_dir.is_dir():
            continue
        if project_filter and project_dir.name != project_filter:
            continue
        for md in sorted(project_dir.glob("*.md")):
            if md.name in SKIP_FILENAMES:
                continue
            out.append(md)
    return out


def confirm_or_abort() -> bool:
    try:
        answer = input("Proceed with moves? [y/N] ").strip().lower()
    except EOFError:
        return False
    return answer in {"y", "yes"}


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    root = resolve_root(args.root)
    inbox_root = root / INBOX_DIRNAME
    archive_root = root / ARCHIVE_DIRNAME / "inbox"

    if not inbox_root.is_dir():
        print(f"ERROR: inbox not found at {inbox_root}", file=sys.stderr)
        return 1

    today = date.today()
    cutoff = today - timedelta(days=args.max_age_days)

    candidates = discover_candidates(inbox_root, args.project)
    plan: list[tuple[Path, Path, date]] = []
    skipped = 0

    for src in candidates:
        if not is_inside(src, inbox_root):
            skipped += 1
            continue
        file_date = file_age_date(src)
        if file_date > cutoff:
            skipped += 1
            continue
        project = src.parent.name
        ym = f"{file_date.year:04d}-{file_date.month:02d}"
        target_dir = archive_root / project / ym
        target = target_dir / src.name
        if not is_inside(target_dir, archive_root):
            print(f"REFUSE (target outside archive): {target}", file=sys.stderr)
            skipped += 1
            continue
        plan.append((src, target, file_date))

    mode = "APPLY" if args.apply else "DRY-RUN"
    if not args.quiet:
        print(f"[{mode}] root={root}")
        print(f"[{mode}] today={today} cutoff={cutoff} max_age_days={args.max_age_days}")
        print(f"[{mode}] candidates={len(candidates)} to_archive={len(plan)} skipped={skipped}")
        for src, target, d in plan:
            rel_src = src.relative_to(root)
            rel_tgt = target.relative_to(root)
            print(f"  {d}  {rel_src}  ->  {rel_tgt}")

    archived = 0
    if args.apply and plan:
        if not args.yes:
            if not confirm_or_abort():
                print("Aborted by user; no files moved.")
                return 0
        for src, target, _ in plan:
            try:
                target.parent.mkdir(parents=True, exist_ok=True)
                final_target = unique_target(target)
                shutil.move(str(src), str(final_target))
                archived += 1
                if not args.quiet:
                    print(f"MOVED {src.relative_to(root)} -> {final_target.relative_to(root)}")
            except OSError as e:
                print(f"ERROR moving {src}: {e}", file=sys.stderr)
                return 1

    total_skipped = skipped + (len(plan) - archived if args.apply else len(plan))
    if args.apply:
        print(f"Archived {archived} files. Skipped {skipped} (too new or not matched).")
    else:
        print(
            f"[DRY-RUN] Would archive {len(plan)} files. "
            f"Skipped {skipped} (too new or not matched). "
            f"Re-run with --apply to move."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
