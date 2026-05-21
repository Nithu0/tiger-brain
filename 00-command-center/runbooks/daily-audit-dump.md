---
tags: [command-center, runbook, audit]
type: runbook
created: 2026-05-16
---

# Daily audit dump

`scripts/audit-dump.ts` reads `audit_log` from `data/command-center.db` and writes a markdown file per day to the brain.

## Purpose

- Survives DB loss — brain is in git history.
- Cross-machine: brain syncs via Obsidian Git plugin, so audit trail is replicated.
- Human-readable: operator can scan a day's approvals/rejections without opening sqlite3.

## Dump location

`~/Obsidian/Brain/00-command-center/audit/YYYY-MM-DD.md`

One file per day, append-only within the day. Idempotent — re-running for the same day overwrites with the full day's content.

## Manual run

```bash
cd /home/nithu/code/command-center
npm run audit:dump            # convenience wrapper around tsx scripts/audit-dump.ts
```

Or for a specific date:

```bash
node --import tsx scripts/audit-dump.ts --date 2026-05-15
```

## Enable cron (Slice 3+)

Once Slice 3 lands the execution worker, schedule a daily dump just after midnight local time:

```cron
5 0 * * * cd /home/nithu/code/command-center && /usr/bin/npm run audit:dump >> data/audit-dump.log 2>&1
```

Verify with `crontab -l` and check the next morning that `audit/YYYY-MM-DD.md` for yesterday exists.

## Out of scope

- No retention policy in DB — `audit_log` is append-only forever in Slice 1. If size becomes an issue post-Slice 3, add a separate archive step that moves > 90-day rows to a cold table.
