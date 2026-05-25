---
title: Runbook — Brain Preflight Checklist (brain-G3/G4/G6 activation)
type: runbook
created: 2026-05-25
audience: operator
purpose: Per-gate activation checklist to safely flip brain-G3 (worktree-default), brain-G4 (nightly-distill cron), brain-G6 (queue-watcher auto-pickup)
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[2026-05-25-operator-gate-naming]]"
  - "[[Runbook-Brain-Upgrade-Workflow]]"
tags: [runbook, operator-gates, preflight, safety, brain-gates]
---

# Runbook — Brain Preflight Checklist

> 3 operator-gates pending OK kjør: brain-G3, brain-G4, brain-G6. Each changes daily flow behavior — flip ONE at a time, observe for 24-48h, then next.

> **Disambiguation (H-10 reconcile, 2026-05-25):** These are the `brain-G*`
> gates — brain-upgrade workflow toggles for the Obsidian Brain. The sibling
> `infra-G*` family (Litestream replication, LAN exposure + auth, coverage
> gate enforcement) lives in command-center and is surfaced by the
> `/api/brain/decisions` endpoint — NOT covered here. Both families share
> bare letters by accident; the `brain-`/`infra-` prefix is the source of
> truth. Full rationale: [[2026-05-25-operator-gate-naming]].

Per CLAUDE.md operator-principle: irreversible / daily-flow-altering changes are operator-gated. This runbook gives the per-gate checklist so flipping is mechanical, not stressful. Default order: brain-G3 → brain-G4 → brain-G6 (least-risky to most-risky). Each gate is independent; you can stop after any of them.

---

## brain-G3 — Worktree-as-default in firm-wt-split.sh

**Status (2026-05-25):** ACTIVATED as OPT-IN flag. Default behavior unchanged. Operator opts in per-invocation via `firm --worktree-default`; flip default after 24-48h of clean opt-in usage.

### What changes
- `firm-wt-split.sh --worktree-default` creates `.worktrees/claude/<role>-<slug>/` per pane via `firm-worktree-spawn.sh` (idempotent), then launches wt.exe pointing each pane at its worktree
- Each pane starts on its own git branch (`claude/<role>-<slug>`, default slug `scratch-YYYY-MM-DD`)
- code-1 / code-2 panes target **command-center** (since `$HOME/code` is not a git repo); other panes target their natural repo
- Operator can OPT OUT (today this is the default; flag reserved for after default-flip) with `firm-wt-split.sh --legacy`
- `--worktree-default` and `--codex` are mutually exclusive

### Why operator-gated
- Changes the daily startup pattern of all 8 panes
- Disk usage increases (~50MB per worktree × 8 = ~400MB)
- Risk of orphan worktrees if cleanup-job (Module H `worktree-gc`) isn't running

### Preflight (run each before activation) — 2026-05-25 results
- [x] Disk space > 5GB free — **946G free** ✅
- [x] `firm-worktree-spawn.sh` tested + works — spawned + cleaned `claude/test-spawn-g3` in command-center and `claude/as-1-scratch-test-g3` in AS, both successful ✅
- [x] **Exception:** command-center, ai-assistent, Master-oppgave had uncommitted/untracked work at flag-add time. Since brain-G3 is OPT-IN (additive), this does NOT block the flag itself — operator should still ensure clean state before each `firm --worktree-default` invocation
- [x] AS, Personlig, Søking fulltid are all on `main`, clean ✅
- [ ] BrainOrchestrator `worktree-gc` trigger registered — **pending Module H** (does not block opt-in usage; matters before default-flip)
- [ ] Backup of current pane state captured (record current cwd + branch per pane in `00-firm-bus/feed.md`) — operator-step before first real invocation

### Activation
```bash
# Per-invocation opt-in (today's mode):
firm --worktree-default                          # default slug = scratch-YYYY-MM-DD
firm --worktree-default --slug fix-orb-gate      # custom slug
firm --worktree-default --dry-run                # preview without launching

# Default (unchanged, legacy):
firm

# Opt-out (reserved for after default-flip):
firm --legacy
```

### Default-flip checklist (later — after 24-48h of clean opt-in)
- Confirm 5+ successful `--worktree-default` sessions
- Confirm `worktree-gc` job exists and has cleaned ≥1 stale worktree
- Edit `firm-wt-split.sh`: set `WORKTREE_DEFAULT=1` as the initial value; ensure `--legacy` correctly resets it

### Rollback (if things go wrong)
```bash
firm --legacy  # fall back to shared-cwd mode
# remove worktrees manually if needed:
for repo in ~/code/{command-center,ai-assistent,Master-oppgave,AS,Personlig,"Søking fulltid"}; do
  git -C "$repo" worktree list
  # operator decides which to prune
done
```

### Observe for 24-48h
- Do panes start cleanly?
- Any merge-conflict surprises when switching panes?
- Disk usage growth manageable?
- Any orphan worktrees flagged by `worktree-gc`?

### Sign-off criteria for "brain-G3 stable, leave activated"
- 48h with no operator-flagged issues
- `worktree-gc` has cleaned ≥1 stale worktree successfully
- No daily-startup failures
- Operator confident with the new pane pattern

---

## brain-G4 — Nightly-distill cron activation

### What changes
- A cron job runs nightly at 03:00 local time
- Calls `/skill brain-distill-daily date=<yesterday>`
- Writes MemoryObjects to the brain (read-only of `audit_log`; write-only to memory tables)
- Distill report lands in `08-system-architecture/distill-report-<date>.md`

### Why operator-gated
- Writes to brain nightly without operator present
- Could fail silently (memory-engine bugs, sqlite locks, etc.)
- Could surface sensitive content into distilled layer if `sensitive:` flagging is wrong

### Preflight
- [ ] memory-engine package fully implemented (code-1 C1-2 + C1-3 landed + tested)
- [ ] `brain-distill-daily` skill tested manually 3+ times without errors
- [ ] Sample distilled MemoryObjects manually reviewed (no PII leak, no sensitive content)
- [ ] Sqlite-vec storage size < 1GB initially (`du -sh ~/code/command-center/data/`)
- [ ] Logrotate configured for distill report files (`08-system-architecture/distill-report-*.md`)
- [ ] Operator-alert mechanism tested (failure → `00-firm-bus/feed.md` line)
- [ ] Recall MRR ≥ 0.6 on eval-set per `08-system-architecture/eval/recall-eval-2026-05-25.md`

### Activation
```bash
# Operator only:
crontab -e
# Add: 0 3 * * * /home/nithu/code/command-center/_bin/run-skill.sh brain-distill-daily date=$(date -u -d yesterday +\%Y-\%m-\%d)
```

### Rollback
```bash
crontab -e
# Remove the line — distillation can still be triggered manually with /skill brain-distill-daily
```

### Observe for 1 week
- Daily reports landing in `08-system-architecture/distill-report-*.md`
- MemoryObjects count growing as expected (~30/day estimate)
- No silent failures (check `feed.md` each morning for the cron-result line)
- Operator-recall queries returning relevant results

### Sign-off criteria
- 7 successful runs
- Recall MRR ≥ 0.6 sustained on eval-set
- No sensitive content leaked into distilled layer
- No silent failures in week 1

---

## brain-G6 — Queue-watcher auto-pickup activation

### What changes
- BrainOrchestrator `youtube-queue` + `github-discovery` triggers ACTIVELY pick up files from `_queue/` folders
- Files picked up → tasks dispatched → ingestion runs → results in `12-youtube/` or `13-github-repos/`
- Operator no longer needs to manually invoke `/skill youtube-ingest` or `/skill github-discover`

### Why operator-gated
- Auto-execution of yt-dlp + gh API calls without operator-trigger
- Cost-tracking matters (YouTube: API quota; GitHub: rate-limit; per §7 risk-5 in plan)
- Could surface low-quality content into brain if anti-hype-filter is weak (per §3.4)

### Preflight
- [ ] `youtube-ingest` + `github-discovery` packages fully tested (D-2 + D-3 acceptance complete)
- [ ] Manual `/skill youtube-ingest url=<X>` run on 5 test URLs → all produce sensible notes
- [ ] Manual `/skill github-discover query=<X>` run on 3 test queries → all produce sensible repo notes
- [ ] Rate-limit tracking confirmed working (`firm_state` table updated; daily cap 50 search + 20 extract per §7 risk-10)
- [ ] HOW-TO-DROP-URL + HOW-TO-DROP-SEARCH instructions in `12-youtube/_queue/README.md` and `13-github-repos/_queue/README.md` tested by operator (drop one file each)
- [ ] License-guard verified on real GPL repo (D-3 acceptance test should cover; per [[LICENSE_GUARD_SPEC]])
- [ ] Anti-hype-filter tested on 3 known-junk YouTube URLs → all filtered out

### Activation
```bash
# Operator only — flip env flag in BrainOrchestrator config:
# (location TBD; likely command-center .env or similar)
export BRAIN_QUEUE_WATCHER_ENABLED=true
# Restart command-center API
```

### Rollback
```bash
export BRAIN_QUEUE_WATCHER_ENABLED=false
# Or simply remove files from _queue/ to stop further pickup
# Manual /skill invocations still work
```

### Observe for 1 week
- All `_queue/` drops processed within 1h (per §9 acceptance-test 2 + 3)
- Distilled notes pass operator-review (sample 5/week)
- No rate-limit blow-ups
- No GPL repo accidentally proposed as implementation-task
- No junk YouTube content slipped through anti-hype-filter

### Sign-off criteria
- 7 days of clean operation
- Confidence > 0.7 on average distilled note
- No operator-flagged false-positive ingestion
- License-guard caught at least 1 incompatible repo (or zero false-positives if no such repo dropped)

---

## All-3-active state (the target)

When brain-G3 + brain-G4 + brain-G6 all activated + stable:
- Brain self-updates daily (nightly distill)
- Operator drops URL/search → distilled note + implementation-task within 1h
- Every task is in its own worktree, doesn't conflict with others
- Cross-machine sync via Obsidian Git keeps Karri + operator in sync

This is the "autonomous AI-OS" target per [[2026-05-25-brain-upgrade-plan]] §9.

---

## General rollback principle

Per CLAUDE.md "no auto-disable" rule: these gates have rollback commands but the operator must explicitly invoke them. Health-checks REPORT to `00-firm-bus/feed.md`; operator decides handling. Never let a skill or orchestrator flip a gate off automatically based on anomaly detection — that's a slippery slope to silent degradation.

If an activated gate is causing problems but isn't outright broken, prefer to leave it on and file a `10-tasks/_open/` ticket rather than yo-yoing the activation state. Yo-yoing erodes confidence in the gate-system itself.

---

## Related

- [[2026-05-25-brain-upgrade-plan]] §6 (operator-gates) + §13 (status)
- [[2026-05-25-operator-gate-naming]] — disambiguation: brain-G* vs infra-G*
- [[Runbook-Brain-Upgrade-Workflow]] — daily operations + scenarios
- [[AGENT_ORCHESTRATION_SPEC]] §9 (worktree policy)
- [[YOUTUBE_INGESTION_SPEC]] §9 (rate-limits)
- [[GITHUB_DISCOVERY_SPEC]] §9 (rate-limits)
- [[MEMORY_DISTILLATION_SPEC]] — nightly-distill contract for brain-G4
- [[LICENSE_GUARD_SPEC]] — license-guard for brain-G6 repo ingestion

---

Sist oppdatert: 2026-05-25 — v1.0, første utgivelse parallelt med brain-upgrade fase 3.
