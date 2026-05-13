---
tags: [runbook, maintenance, brain]
type: runbook
created: 2026-05-13
---

# Runbook — Brain Weekly Maintenance

Operator's recurring routine for keeping the brain (Obsidian vault) healthy. Run on cadence below, or whenever the vault feels drifty.

## 1. When to run

- **Every Monday morning** as part of week-kickoff.
- **Ad-hoc** when the brain feels "drifty": broken links accumulating, dashboards stale, inbox bloated, audit warnings creeping up.

## 2. 5-minute version (always do)

```bash
cd ~/Obsidian/Brain
git pull --rebase                        # if teammate has been pushing
bash scripts/sanity.sh                   # must be 8/8
python3 scripts/brain_audit.py           # 0 errors target
```

If green: done. If not: see steps 3–7 to fix.

## 3. 15-minute version (do weekly)

- Update `claude-context/CURRENT.md` to reflect this week's active focus.
- Update `01-CURRENT-FOCUS.md` — what's primary, what's parked.
- Glance at `00-DASHBOARD.md` — does it still tell the truth?

## 4. Monthly tasks

```bash
# Archive old inbox
python3 scripts/archive_old_inbox.py     # dry-run first
python3 scripts/archive_old_inbox.py --apply --yes

# Promote candidates
ls _promote-candidates/                  # review with operator hat on
# move polished notes to their proper home
```

## 5. Quarterly tasks

- Refresh `SYSTEM-AUDIT.md` — re-run audit, update findings.
- Graph view sanity glance: see [[Graph-View-Curation]].
- Audit MOCs for stale links: `python3 scripts/brain_audit.py` warns count.
- Review `_decisions/` — any decisions that should be retired or updated?

## 6. On-demand triggers

- **"Inbox feels heavy"** → run inbox triage; consult `_promote-candidates/INBOX-TRIAGE-*.md`.
- **"Audit flags > 30 warnings"** → see [[When-Brain-Structure-Drifts]].
- **"Teammate's PR ready to merge"** → run `bash scripts/sanity.sh` locally first, then merge via UI.
- **"New project added"** → update `claude-context/SYSTEM-MAP.md` + `00-DASHBOARD.md`.

## 7. Health check (paste into terminal)

```bash
cd ~/Obsidian/Brain && \
  git status --short | head && \
  bash scripts/sanity.sh && \
  python3 scripts/brain_audit.py | tail -3
```

## 8. Red flags that stop the cadence

- **Audit errors > 0** → fix immediately, don't continue maintenance.
- **Sanity < 6/8** → investigate before any push.
- **Uncommitted changes > 50** → triage before maintenance.

## 9. Related

- [[When-Brain-Structure-Drifts]] — decision tree
- [[Runbook-Push-Cycle]]
- [[Graph-View-Curation]]

---

Sist oppdatert: 2026-05-13
