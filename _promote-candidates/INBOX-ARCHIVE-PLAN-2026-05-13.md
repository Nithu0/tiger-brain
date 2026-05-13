---
tags: [meta, inbox, archive-plan]
type: report
created: 2026-05-13
status: pending-operator-review
---

# Inbox Archive Plan — 2026-05-13

One-shot dry-run audit of `scripts/archive_old_inbox.py`. No files moved.
Operator reads this and chooses Option A / B / C below.

## 1. Summary

Today = **2026-05-13**. Inbox candidates discovered: **115 files** (all under
`00-claude-inbox/nexus/`, no other project subfolders are populated).

| Run | Cutoff date | Would-archive | Skipped |
|---|---|---|---|
| Default `--max-age-days 30` | 2026-04-13 | **0** | 115 |
| `--max-age-days 1` | 2026-05-12 | **110** | 5 |
| `--max-age-days 0` (archive all) | 2026-05-13 | **115** | 0 |

Filename date prefixes break down as: **106 from 2026-05-11**, **4 from
2026-05-12**, **5 from 2026-05-13**. The 11th was the big `Brain restructure`
day, which explains the spike.

## 2. Default 30-day dry-run output

```
[DRY-RUN] root=/home/nithu/Obsidian/Brain
[DRY-RUN] today=2026-05-13 cutoff=2026-04-13 max_age_days=30
[DRY-RUN] candidates=115 to_archive=0 skipped=115
[DRY-RUN] Would archive 0 files. Skipped 115 (too new or not matched). Re-run with --apply to move.
```

Clean no-op. Script behaves as designed for the documented 30-day lifecycle.

## 3. Aggressive `--max-age-days 0` dry-run output (first 20 files)

```
[DRY-RUN] root=/home/nithu/Obsidian/Brain
[DRY-RUN] today=2026-05-13 cutoff=2026-05-13 max_age_days=0
[DRY-RUN] candidates=115 to_archive=115 skipped=0
  2026-05-11  00-claude-inbox/nexus/2026-05-11-agent-activation-readiness.md  ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-analysis-snapshots-wire.md     ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-analytics-export-endpoint.md   ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-analyze-signals.md             ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-arch-concerns-filed.md         ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-backfill-script-built.md       ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-brain-restructure.md           ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-calibration-log-fix.md         ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-challenge-async.md             ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-ci-bootstrap.md                ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-cipher-9131-investigation.md   ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-clone-guide.md                 ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-code-debt.md                   ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-codex-activation-prep.md       ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-codex-blocker-1-cost.md        ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-codex-blocker-2-pr-crash.md    ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-codex-blocker-3-worktree.md    ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-codex-e2e-test.md              ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-codex-phase2a-live.md          ->  90-archive/inbox/nexus/2026-05/...
  2026-05-11  00-claude-inbox/nexus/2026-05-11-codex-prod-readiness.md        ->  90-archive/inbox/nexus/2026-05/...
  ... [95 more lines redacted; see /tmp/archive-max-days-0.txt] ...
[DRY-RUN] Would archive 115 files. Skipped 0 (too new or not matched). Re-run with --apply to move.
```

All 115 moves are inside `00-claude-inbox/nexus/` → `90-archive/inbox/nexus/2026-05/`.
No files would cross project boundaries.

## 4. Recommendation (operator decides)

- **Option A — recommended: leave as-is.** Files are all <30 days, the
  documented lifecycle hasn't triggered yet, and the 106 files from 2026-05-11
  still belong to the active triage horizon. The default 30-day run is a
  no-op today.
- **Option B — 2-day window.** Archive 2026-05-11 and earlier (110 files),
  keep today + yesterday hot.
  Run: `python3 scripts/archive_old_inbox.py --max-age-days 2 --apply --yes`
- **Option C — clean slate.** Archive everything (115 files).
  Run: `python3 scripts/archive_old_inbox.py --max-age-days 0 --apply --yes`

Lean toward Option A unless inbox volume actively blocks triage. The 2026-05-11
spike is artificial (Brain restructure day), not a recurring pattern.

## 5. Files that would move to `90-archive/inbox/nexus/2026-05/` (Option C, partial)

Full list lives in `/tmp/archive-max-days-0.txt`. Highlights:

- 106 × `2026-05-11-*.md` (post-restructure flood: codex-blockers, deadlink-drains,
  retention-verifies, foundation-monitor, gemini fixes, memory-cleanup,
  moc-backfill, postmortems, strategy-id-backfill, vault-gaps, etc.)
- 4 × `2026-05-12-*.md` (daily-trade-cap-impl, railway-redeploy-verify,
  trade-flow-snapshot, trend-pause-detection)
- 5 × `2026-05-13-*.md` (today — see section 6)

## 6. What's NEW in inbox — today 2026-05-13 (NEVER auto-archive these)

These 5 files are TODAY's drops. The default 30-day run protects them
indefinitely. Only Option C would touch them.

- `2026-05-13-brain-hardening-session.md`
- `2026-05-13_firm-launch-failure-diagnosis.md`
- `2026-05-13_firm-launch-failure-diagnosis-2.md`
- `2026-05-13_research-os-audit.md`
- `2026-05-13_session-hook-proposal.md`

Note the underscore-separator variant (`2026-05-13_*`) — script's
`DATE_PREFIX_RE` correctly matches both `-` and `_` separators because the
regex only anchors `^\d{4}-\d{2}-\d{2}-`. Wait: it requires a trailing dash,
not underscore. The underscore-prefixed files therefore fall through to
**mtime fallback** in `file_age_date()`. They still resolve to 2026-05-13
because their mtimes match, but worth knowing for naming convention going
forward — prefer the `YYYY-MM-DD-` hyphen prefix to stay on the parser's
fast path.

Also present but not in inbox flat-list: `00-claude-inbox/nexus/2026-05-13/`
is a **subdirectory** (synthesis + deep-dives + round2/round3 folders).
The script only walks `*.md` directly under each project, so this
subdirectory is invisible to the archiver. If those should ever auto-archive,
the script needs a recursive walk. Out of scope for today.

## 7. Cross-reference — recurring schedule recommendation

This report is one-shot. For ongoing lifecycle hygiene, add a monthly cron
once Option A/B/C is settled:

```cron
0 0 1 * *  cd /home/nithu/Obsidian/Brain && python3 scripts/archive_old_inbox.py --apply --yes
```

Runs at 00:00 on the 1st of each month with the documented 30-day default.
Operator adds when ready — do not auto-install.

---

Generated by dry-run only. No state changed. Source outputs preserved at
`/tmp/archive-dryrun.txt`, `/tmp/archive-max-days-0.txt`,
`/tmp/archive-max-days-1.txt`.
