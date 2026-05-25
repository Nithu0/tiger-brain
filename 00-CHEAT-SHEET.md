---
title: Brain Cheat-Sheet
created: 2026-05-25
purpose: One-page fast lookup for brain operations
related:
  - "[[00-DASHBOARD]]"
  - "[[Runbook-Brain-Upgrade-Workflow]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [meta, cheat-sheet, ops]
---

# Brain Cheat-Sheet

> Single-page operator reference. For full detail, see [[Runbook-Brain-Upgrade-Workflow]].

## Recall something

```
/brain recall "vague memory"          # Tier 2 default (hybrid BM25 + HNSW + rerank)
/brain recall "exact phrase"          # Tier 1 fast
/brain ask "complex multi-hop"        # Tier 3 agentic (max 3 iter, ~30s)
```

Always click source-ref backlink. Distilled summary is index, not truth.

## Drop content into the brain

| Want | Drop where | Format |
|---|---|---|
| YouTube URL | `~/Obsidian/Brain/12-youtube/_queue/YYYY-MM-DDTHHMM-<slug>.url` | URL on one line |
| GitHub search | `~/Obsidian/Brain/13-github-repos/_queue/YYYY-MM-DDTHHMM-<slug>.md` | frontmatter `search:` field |
| Task | `~/Obsidian/Brain/10-tasks/_open/T-YYYY-MM-DD-NNN-<slug>.md` | frontmatter per template |
| Manual note | `~/Obsidian/Brain/<folder>/<slug>.md` | standard YAML frontmatter |
| Brain-dump / draft | `~/Obsidian/Brain/00-claude-inbox/<project>/` | freeform, promote later |
| Decision (immutable) | `~/Obsidian/Brain/_decisions/<slug>.md` | dato-stemplet |

## Invoke a skill

```
/skill brain-distill-daily date=2026-05-24
/skill youtube-ingest url=https://...
/skill github-discover query="topic stars:>100"
/skill multi-agent-dispatch intent="..." roles=ai-1,thesis-1
/skill worktree-spawn-cleanup action=spawn repo=~/code/X slug=mywork
```

Discovery order: `~/.claude/skills/` → `<repo>/.claude/skills/` → `~/Obsidian/Brain/03-skills/`.

## Task lifecycle

```
~/code/command-center/_bin/firm-task-claim.sh                    # list open tasks
~/code/command-center/_bin/firm-task-claim.sh T-2026-05-25-001   # claim by id
~/code/command-center/_bin/firm-task-complete.sh T-2026-05-25-001  # complete + draft PR
# Operator OK kjør → manual git push
```

Flow: `_open/` → `_in-progress/` (branch `<role>/<task-id>`, worktree if brain-G3) → `_done/`.
Stuck > 14 days flagged by daily stale-task routine. Force-release: `firm-task-release.sh <id>`.

## Pane / firm-bus

```
echo $FIRM_ROLE                                            # which pane am I?
tail ~/Obsidian/Brain/00-firm-bus/feed.md                  # recent events
cat ~/Obsidian/Brain/00-firm-bus/inbox/$FIRM_ROLE.md       # my inbox
# Append to peer inbox:
echo "## $(date -u +%FT%TZ) — from $FIRM_ROLE: ..." >> ~/Obsidian/Brain/00-firm-bus/inbox/peer-role.md
```

Read own inbox BEFORE acting. Long reports → `~/Obsidian/Brain/00-claude-inbox/<project>/`, never `feed.md`.

## Dispatch parallel sub-agents

- Web: command-center `/brain` → intent + roles → "Dispatch"
- CLI: append dispatch-frontmatter to `~/Obsidian/Brain/00-firm-bus/inbox/<role>.md` (fields: task_id, from, to, objective, branch, files_allowed, expected_output, tests, rollback, sla_seconds)
- Sizing rules: see [[Runbook-Multi-Agent-Dispatch]] (5/10/15 fanout)

## Operator-gates pending

- **brain-G3** worktree-default — see [[Runbook-Brain-Preflight-Checklist]]
- **brain-G4** nightly-distill cron — same
- **brain-G6** queue-watcher auto-pickup — same
- **Push-gate** — operator OK kjør per PR (always, no exceptions)
- **New-skill promote** — `_proposed/` → `03-skills/` requires operator review
- **Strategy/risk** — money-impact changes need operator + Karri review

## Where to find things

| Type | Path |
|---|---|
| Plan | [[2026-05-25-brain-upgrade-plan]] |
| Specs (7) | `08-system-architecture/specs/` |
| Eval | [[recall-eval-2026-05-25]] |
| MOCs (8) | `_maps/` ([[System-Architecture-MOC]], [[Memory-MOC]], [[RAG-MOC]], [[Skills-MOC]], [[Tasks-MOC]], [[Youtube-MOC]], [[Github-Repos-MOC]], [[Retrospectives-MOC]]) |
| Skills | `~/.claude/skills/` (workspace) + `~/Obsidian/Brain/03-skills/` (operator-ref) + `<repo>/.claude/skills/` (project) |
| Tasks | `10-tasks/_open/` · `_in-progress/` · `_blocked/` · `_done/` |
| Runbooks | `_runbooks/` |
| Templates (8) | `00-templates/` |
| Today's audit | [[2026-05-25-30-agent-audit]] |
| YouTube distilled | `12-youtube/<channel>/` |
| YouTube verbatim | `_library/youtube/` (gitignored, local-only) |
| GitHub distilled | `13-github-repos/` |
| Decisions (immutable) | `_decisions/` |
| Retrospectives | `09-retrospectives/<ISO-week>.md` |
| firm-launcher | `~/code/command-center/_bin/firm-*.sh` |

## Diagnostic

```
# Pre-push verify:
~/code/command-center/_bin/brain-preflight.sh

# Brain sanity (run before every push):
~/Obsidian/Brain/scripts/sanity.sh

# Test status:
cd ~/code/command-center && npm test

# Orchestrator health:
curl http://localhost:3000/api/health
```

## Maintenance cadence

| Frequency | What |
|---|---|
| Hourly | YouTube + GitHub queue drain (brain-G6-gated) |
| Daily | stale-task scan, repo-health audit |
| Nightly | distill `audit_log` → MemoryObjects (brain-G4-gated) |
| Weekly | dead-link check, retrospective (Sun 22:00), arch-review |
| Monthly | spec-review + inbox archive |

All routines REPORT-only — never auto-fix.

## Emergency

- Stuck? [[Runbook-Brain-Upgrade-Workflow]] § "Common scenarios"
- Broken brain? [[Runbook-Obsidian-Git-Sync]] to re-sync
- Lost? Read [[01-CURRENT-FOCUS]]
- YouTube drop didn't trigger? `tail -50 ~/Obsidian/Brain/00-firm-bus/feed.md | grep youtube`; if brain-G6 inactive, run `/skill youtube-ingest url=<url>` manually
- Recall returned junk? Try `/brain ask` (Tier 3); file counter-example in [[recall-eval-2026-05-25]]
