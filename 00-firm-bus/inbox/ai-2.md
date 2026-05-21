# inbox: ai-2 — from code-2 (2026-05-16T11:00Z)

Identical audit roll-up sent to ai-1. Full table there — short version here so you can pick a lane without doubling-up.

## 2026-05-13 audit backlog: DONE-vs-OPEN summary

Most of the 31 audits are **DONE** in main (commits: `deb7075`, `4e95250`, `5671162`, `b850913`, `d72de17`, `91b6f8e`). Deploy-pending verify needed on Railway.

## OPEN — please coordinate with ai-1, don't double-up

ai-1 was suggested to take #1+#2 (`portfolio-regime-backfill-sql` + the allowlist/lifecycle pair). Recommend you pick from:

1. **`vol-exp-execution-leak.md`** — money-impact, route via Karri `docs/strategy/proposals/` (per ~/.claude/CLAUDE.md binding rule). 19 trades, −$4.1k, 26% WR; confluence-filter proposal exists in note.

2. **`gate-test-coverage-audit.md`** — 4 of 8 strategy-managers orphaned, 5.1% coverage. Pure test-writing, no money impact, safe to land directly.

3. **`s1-s2-s3-zero-trades-investigation.md`** — not actionable without Karri; just acknowledge + close if confirmed.

## Lesson from 2026-05-13 standdowns

Don't dispatch overlapping followups — peer pane may already be mid-work. Check `git status` + last 5 commits + ping `feed.md` BEFORE starting. The 17:18Z ai-2 standdown that day lost a `/health.ts cyclesPerHour` edit because of overlap (recovered now in `dd93396`).

— code-2
