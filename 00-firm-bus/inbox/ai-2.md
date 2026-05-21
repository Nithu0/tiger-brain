# inbox: ai-2 — from ai-1 (2026-05-21T05:45Z)

Operator ran "kjør full analyse MED ai-2 + alle oppgaver som gjenstår" in the
ai-1 pane. I (ai-1) took the two silent-regression diagnoses + the push gate.
Picking lanes so we don't double up — **check `git log --oneline -5` +
`git status` before you start.**

## What ai-1 has done / owns (do NOT touch)
- Diagnosed `agent_lessons` 0-rows + `risk_events` silence — both written into
  `docs/ops/known-failures.md`. Root causes: Railway worker env-flags + a dead
  NEWS_BLACKOUT code path. Neither is fully autonomous-fixable.
- Landed `e299a2d` — failure-marker observability for the lesson subprocess.
- Owns: push handoff (12 commits), phase-status update, operator-action roll-up.

## Your lane — OPEN audit items
1. **`gate-test-coverage-audit.md`** — 4 of 8 strategy-managers orphaned, 5.1%
   coverage. Pure test-writing, no money-impact, safe to land directly.
   **Best autonomous pickup — start here.**
2. **`vol-exp-execution-leak.md`** — money-impact. A
   `2026-05-12_vol_exp_confluence_filter.md` proposal already exists in the
   queue. Do NOT implement — verify the proposal still matches the data, ping
   feed.md if it does. Karri-gated.
3. **`portfolio-regime-backfill-sql.md`** + allowlist/lifecycle pair — SQL +
   observability. Take if you have spare cycles after #1; else ai-1 folds them
   into the operator roll-up.

## Hard constraints
- 07:45 CET — before Karri work-hours (09:00). Do NOT auto-send any Karri
  proposal before 09:00; file + hold.
- Push to main is operator-gated ("OK kjør"). ai-1 holds the 12-commit push.
- Drop a one-liner to `feed.md` when you claim #1.

— ai-1

---
(earlier — code-2 2026-05-16T11:00Z, superseded by the split above)
Most of the 31 2026-05-13 audits are DONE in main. Full table in inbox/ai-1.md.
