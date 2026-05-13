---
tags: [meta, inbox, triage]
type: report
created: 2026-05-13
status: pending-operator-review
---

# Inbox triage — 2026-05-13

Read-only sweep of `00-claude-inbox/nexus/` (`00-claude-inbox/thesis/` is empty). 30-day archive policy still hands-off — most files are 2 days old, so blanket auto-archive does not apply. This report flags supersession, promotion, and merge candidates the operator can act on now.

## Summary

- **Total inbox files:** 111 (nexus: 111, thesis: 0)
- **Date span:** 106 × 2026-05-11, 4 × 2026-05-12, 1 × 2026-05-13
- **Clusters identified (>=2 files):** 17
- **Promotion candidates:** 10 (permanent-reference content worth lifting)
- **Merge candidates:** 8 cluster groups (40 files collapse to ~8 consolidated notes)
- **Stale / superseded by `_runbooks/` or `runtime-state/`:** ~6 files
- **No-action-needed (let the 30-day archive handle):** ~55 files

## Per-cluster table

| Cluster | # files | Oldest | Newest | Recommended action |
|---|---:|---|---|---|
| discord-audit / discord-* | 6 | `2026-05-11-discord-audit-wire.md` | `2026-05-11-discord-audit-final.md` | **Merge into one** `discord-audit-trail-2026-05-11.md`. `discord-audit-final.md` is the wrap-up. |
| codex-phase-2a / codex-* | 9 | `2026-05-11-codex-activation-prep.md` | `2026-05-11-codex-phase2a-live.md` | **Merge** blocker-1/2/3 + e2e-test + test-task-cleanup + prod-readiness + activation-prep into `codex-phase-2a-activation.md`. `phase2a-live.md` is the wrap-up. |
| foundation-monitor / foundation-* | 4 | `2026-05-11-foundation-monitor.md` | `2026-05-11-foundation-monitor-verify.md` | **Merge** monitor + trigger-test + verify into one. Keep `foundation-gate-path.md` separate (it is a path-doc, promotion candidate). |
| metadata-fix / metadata-* | 5 | `2026-05-11-metadata-strip-fix.md` | `2026-05-11-metadata-fix-verified.md` | **Merge** strip-fix + partial + wakeup2 + verified into one timeline note. `metadata-fix-verified.md` is the wrap-up. |
| moc-backfill (rounds 1-3) | 3 | `2026-05-11-moc-backfill.md` | `2026-05-11-moc-backfill-round-3.md` | **Merge**. Round-3 explicitly closes the series. |
| deadlink-drain (r2-r3) | 2 | `2026-05-11-deadlink-drain-r2.md` | `2026-05-11-deadlink-drain-r3.md` | **Merge** — r3 brings count to 0; r2 supersedes itself. |
| phase-status refresh | 3 | `2026-05-11-phase-status-refresh.md` | `2026-05-11-phase-status-refresh-r7.md` | **Merge** all 3 into single phase-status-refresh log; r7 is final round. |
| retention / TTL | 5 | `2026-05-11-retention-design.md` | `2026-05-11-retention-verified.md` | **Promote `retention-design.md`** to `_decisions/`. Merge the 4 verify-rounds into one. |
| memory audit + cleanup + refresh | 3 | `2026-05-11-memory-audit.md` | `2026-05-11-memory-refreshes.md` | **Merge** into one audit-and-cleanup note. |
| doc-drift / doc-fixes / doc-sweep | 3 | `2026-05-11-doc-drift.md` | `2026-05-11-doc-sweep-round-2.md` | **Merge** — sweep-round-2 explicitly final. |
| followups (sweep + commit) | 2 | `2026-05-11-followups-sweep.md` | `2026-05-11-followups-commit.md` | **Merge**. |
| strategy-id backfill | 2 | `2026-05-11-strategy-id-backfill.md` | `2026-05-11-strategy-id-backfill-applied.md` | **Merge** — both terminate with "not applied"; together they form one decision log. |
| postmortem (model-audit / classifier-verify / streak-phase1) | 3 | `2026-05-11-postmortem-model-audit.md` | `2026-05-11-postmortem-classifier-verify.md` | Keep separate (3 distinct postmortems). No merge. |
| gemini (48p-diagnostic / fix-applied / tier1-verified) | 3 | `2026-05-11-gemini-48p-diagnostic.md` | `2026-05-11-gemini-tier1-verified.md` | **Merge** into one diagnostic-to-resolution timeline. tier1-verified is the wrap-up. |
| railway-redeploy-verify (11 + 12) | 2 | `2026-05-11-railway-redeploy-verify.md` | `2026-05-12-railway-redeploy-verify.md` | Keep separate (different push contents). |
| codex-prod-readiness blockers 1/2/3 | 3 | `2026-05-11-codex-blocker-1-cost.md` | `2026-05-11-codex-blocker-3-worktree.md` | Already counted in codex cluster above. |
| end-of-day (snapshot / verification) | 2 | `2026-05-11-end-of-day-verification.md` | `2026-05-11-end-of-day-snapshot.md` | **Merge** — both target 2026-05-11 EOD. |

## Top 10 promotion candidates

Files whose content is permanent-reference (decision, runbook-shaped, or strategy doc) rather than session log:

1. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-retention-design.md` — TTL policy table for 4 tables; reads as a `_decisions/` entry.
2. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-foundation-gate-path.md` — concrete GUL→GREEN path-doc with binding to operator-prinsipp 4; promote to `_runbooks/` or `_decisions/`.
3. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-pnl-bleed-analysis.md` — 5-day investigation; reusable analysis pattern + per-strategy breakdown.
4. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-strategy-regime-fit.md` — 30-day strategy/regime analysis; durable reference for Karri.
5. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-full-state-audit.md` — full Postgres + /health subsystem audit; pattern reusable.
6. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-codex-prod-readiness.md` — WAIT-30D verdict + 7-prefix air-gap analysis; promote to `_decisions/`.
7. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-cipher-9131-investigation.md` — incident postmortem with risk note; promote to `01-nexus/operations/` or `_decisions/`.
8. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-arch-concerns-filed.md` — architecture concern index; promote to `01-nexus/_repo-docs/` or `_decisions/`.
9. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-env-sync.md` — `.env.example` 50→208 sync closing audit finding #1; promote to `_decisions/`.
10. `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-vault-gaps.md` — vault-health audit driving subsequent restructure; promote to `_decisions/` as the trigger record.

## Merge candidates (groups of files that could be consolidated)

- **discord-audit-trail-2026-05-11** ← discord-audit-wire + discord-audit-extend + discord-audit-final + discord-post-flipverify + macro-event-discord-wire + karri-morning-discord-queued (6 → 1)
- **codex-phase-2a-activation-2026-05-11** ← codex-activation-prep + codex-blocker-1/2/3 + codex-e2e-test + codex-test-task-cleanup + codex-prod-readiness + codex-phase2a-live (9 → 1, but keep prod-readiness as separate promotion)
- **foundation-monitor-2026-05-11** ← foundation-monitor + foundation-monitor-trigger-test + foundation-monitor-verify (3 → 1)
- **metadata-fix-2026-05-11** ← metadata-strip-fix + metadata-fix-partial + metadata-fix-wakeup2 + metadata-fix-verified (4 → 1)
- **moc-backfill-2026-05-11** ← moc-backfill + moc-backfill-round-2 + moc-backfill-round-3 (3 → 1)
- **deadlink-drain-2026-05-11** ← deadlink-drain-r2 + deadlink-drain-r3 (2 → 1)
- **retention-verify-2026-05-11** ← retention-reap-verify + retention-reap-fix-verify + retention-verified (3 → 1, after promoting retention-design)
- **gemini-tier1-2026-05-11** ← gemini-48p-diagnostic + gemini-fix-applied + gemini-tier1-verified (3 → 1)

## Stale (event resolved or content rolled into `_runbooks/` / `runtime-state/`)

- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-snapshot-generated.md` — pointer-only note; the snapshot itself lives at `01-nexus/runtime-state/SNAPSHOT.md` (already authoritative). Safe to discard.
- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-end-of-day-snapshot.md` — round-13 EOD; content captured in `01-nexus/runtime-state/SNAPSHOT.md` per its TL;DR.
- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-round-5-post-push-verification.md` — push-not-landed status; resolved by `2026-05-11-railway-redeploy-verify.md`. Stale.
- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-metadata-fix-partial.md` and `metadata-fix-wakeup2.md` — superseded by `metadata-fix-verified.md`.
- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-deadlink-drain-r2.md` — superseded by r3 (0 remaining).
- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-followups-sweep.md` — superseded by `followups-commit.md`.

Patterns matching `_runbooks/Runbook-Post-Deploy-Verification.md` (post-deploy verifications) and `_runbooks/Runbook-Push-Cycle.md` (push-cycle verifies) already exist — the per-instance verify files (railway-redeploy-verify, post-deploy-verification, end-of-day-verification) are session logs and OK to let the 30-day archive sweep handle.

## Suggested commands

```bash
# Preview blanket archive (everything older than today — dry-run)
python3 scripts/archive_old_inbox.py --max-age-days 0

# Apply blanket archive (irreversible — needs operator OK)
python3 scripts/archive_old_inbox.py --max-age-days 0 --apply --yes

# Promote a single file (run from /home/nithu/Obsidian/Brain/)
mv 00-claude-inbox/nexus/2026-05-11-retention-design.md _promote-candidates/
mv 00-claude-inbox/nexus/2026-05-11-foundation-gate-path.md _promote-candidates/
mv 00-claude-inbox/nexus/2026-05-11-codex-prod-readiness.md _promote-candidates/
mv 00-claude-inbox/nexus/2026-05-11-env-sync.md _promote-candidates/
mv 00-claude-inbox/nexus/2026-05-11-cipher-9131-investigation.md _promote-candidates/
mv 00-claude-inbox/nexus/2026-05-11-arch-concerns-filed.md _promote-candidates/
mv 00-claude-inbox/nexus/2026-05-11-vault-gaps.md _promote-candidates/
mv 00-claude-inbox/nexus/2026-05-11-pnl-bleed-analysis.md _promote-candidates/
mv 00-claude-inbox/nexus/2026-05-11-strategy-regime-fit.md _promote-candidates/
mv 00-claude-inbox/nexus/2026-05-11-full-state-audit.md _promote-candidates/
```

## No-action-needed

Roughly **55 files** are fine as-is — single-topic session logs (ci-bootstrap, scalp-gate-fix, session-block-impl, sl-cooldown-impl, regime-gate-impl, perf-indexes, index-utilization, graph-densification, vol-exp-instrumentation, evaluategates-cleanup, conviction-quartile-phase1, agent-activation-readiness, analysis-snapshots-wire, analytics-export-endpoint, analyze-signals, backfill-script-built, brain-restructure, calibration-log-fix, challenge-async, clone-guide, context-map-refresh, code-debt, engine-scores-resurrection, explain-slow-queries, funnel-drain-fix, grant-select-applied, low-hanging-fruit, new-strategy-proposals, observe-only-prep, orchestrator-tests, phase-status-karri-batch, portfolio-brain-perf, post-deploy-activity-audit, post-deploy-verification, quota-pattern-saved, readme-refresh, readonly-grant-prep, recon-audit, snapshot-generated [also stale], strategy-blade-tests, thesis-quality-verify, trade-frequency-baseline, week-opening-synthesis, worker-build-post-husky-fix, 2026-05-12-daily-trade-cap-impl, 2026-05-12-trade-flow-snapshot, 2026-05-12-trend-pause-detection, 2026-05-13-brain-hardening-session). These can ride the 30-day auto-archive on 2026-06-10.

---

**Operator next step (suggested):** decide on promotion list (10 files), then merge groups, then let everything else go to archive on 2026-06-10. No automatic moves taken by this report.
