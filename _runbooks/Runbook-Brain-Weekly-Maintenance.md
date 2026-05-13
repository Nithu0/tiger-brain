---
tags: [runbook, maintenance, brain]
type: runbook
updated: 2026-05-13
---

# Runbook: Brain Automation (what runs automatically and when)

## TL;DR

Ingen ukentlig sjekkliste — alt er automatisert.
Denne fila viser hva som skjer i bakgrunnen.
Og hvordan å overstyre når det trengs.

## What runs automatically

| Trigger | Action | Where |
|---|---|---|
| Firm tab opens | `brain-session-start.sh --quiet`: git pull rebase, sanity, audit, hook-install if missing | `_bin/firm-tab-init.sh` calls it |
| Pre-push (local) | `sanity.sh` blocks bad pushes | `.git/hooks/pre-push` installed by `scripts/install-hooks.sh` (called by `setup-from-scratch.sh`) |
| Pull Request | `brain-checks` + `path-guard` + `gitleaks` run on every PR | GitHub Actions |
| Push to main | Same 3 workflows on main | GitHub Actions |
| 1st of month, 07:00 UTC | `archive_old_inbox.py --apply` opens auto-PR | `.github/workflows/monthly-inbox-archive.yml` |

## What still needs human attention (minimal)

- **Auto-PR from monthly archive** — review + merge once a month (one click)
- **Update `claude-context/CURRENT.md`** — when active focus shifts (operator decides cadence)
- **Update `01-CURRENT-FOCUS.md`** — same
- **Decide promotion of `_promote-candidates/`** — when a note feels ready

## Manual overrides (when automation gets in the way)

```bash
# Skip pre-push hook for one push:
git push --no-verify   # discouraged

# Skip brain-session-start in a firm tab:
BRAIN_SKIP=1 firm

# Run a deep audit manually:
cd ~/Obsidian/Brain && python3 scripts/brain_audit.py --strict
```

## When automation fails (debug)

- Tab boot slow → check `~/Obsidian/Brain/scripts/brain-session-start.sh --verbose`
- Pre-push hook broken → `cat .git/hooks/pre-push` + `bash scripts/install-hooks.sh --yes`
- CI failing → `https://github.com/Nithu0/tiger-brain/actions`
- Monthly archive stuck → check Actions tab for the scheduled run; manually trigger via `workflow_dispatch` if needed

## Disable everything (nuclear option)

```bash
rm .git/hooks/pre-push                   # disable local hook
# GitHub Actions can be disabled per-workflow at:
#   https://github.com/Nithu0/tiger-brain/actions
```

## Related

- [[Runbook-Brain-Post-Push-Cleanup]]
- [[Runbook-Branch-Protection]]
- [[When-Brain-Structure-Drifts]]

Sist oppdatert: 2026-05-13
