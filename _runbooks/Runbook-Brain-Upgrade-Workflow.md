---
title: Runbook — Brain Upgrade Workflow
type: runbook
created: 2026-05-25
status: v1.0
audience: operator + collaborators
purpose: Daily operational guide for the workspace-wide brain (memory + skills + ingestion + RAG)
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[System-Architecture-MOC]]"
tags: [runbook, brain, daily, ops]
---

# Runbook — Brain Upgrade Workflow

## What the brain does for you

The workspace brain is one persistent memory + skill + ingestion layer that spans all 6 projects in `/home/nithu/code/`. It distills your daily actions (commits, conversations, decisions, terminal logs) into `MemoryObject` rows that you can recall later via natural-language query (hybrid BM25 + HNSW + rerank, Tier 2 RAG default). It auto-ingests YouTube videos and GitHub repos you drop into queue folders, turns them into distilled brain-notes with source-ref backlinks, and proposes reusable skills from successful patterns. It runs background routines (nightly distill, weekly dead-link, daily stale-task), and lets you dispatch parallel sub-agents across the 8-pane firm-launcher with per-task isolated worktrees. Verbatim source is never deleted — distilled is index, source is truth.

## Daily operations

### A. Recall something I half-remember

1. `/brain recall "find that thing about X"` in any pane (CLI), OR open command-center web `/brain/recall`
2. Tier 2 returns top-5 hits, each rendered as `[exchange_core] → [source-ref backlink]`
3. Click the backlink to see verbatim source (never the distilled summary as final answer)
4. For complex multi-hop questions: `/brain ask "..."` → Tier 3 agentic loop (max 3 iterations, ~30s)

### B. Ingest a YouTube video

1. Copy the URL
2. Drop `YYYY-MM-DDTHHMM-<slug>.url` file in `~/Obsidian/Brain/12-youtube/_queue/` with the URL on one line
3. BrainOrchestrator picks up within 1h (when brain-G6 queue-watcher activated; until then run manually: `/skill youtube-ingest url=<url>`)
4. Result: distilled note at `12-youtube/<channel>/<YYYY-MM-DD-slug>.md` with 4-field frontmatter + anti-hype confidence score; verbatim transcript local-only in `_library/youtube/<channel>/<slug>/transcript.txt`

### C. Discover GitHub repos for a topic

1. Drop `YYYY-MM-DDTHHMM-<slug>.md` file in `~/Obsidian/Brain/13-github-repos/_queue/` containing `search: <gh-search-query>` in frontmatter or body
2. BrainOrchestrator picks up within 1h (brain-G6-gated, same as YouTube)
3. Result: scored repo notes at `13-github-repos/<owner>-<name>.md` (license-checked; GPL repos noted but no implementation-task proposed)
4. Never clones + runs — metadata + README + manifest only

### D. Invoke a skill

1. `/skill <name> <args>` in any pane
2. Or via command-center web: `/brain/skills` → click "Run"
3. Skill discovery covers 3 tiers: `~/.claude/skills/`, `<repo>/.claude/skills/`, `~/Obsidian/Brain/03-skills/`
4. Logs to `feed.md`; results stored as `MemoryObject` (audited)

### E. Claim + complete a task

1. `cd ~/code/<repo>` (whichever repo the task targets)
2. `~/code/command-center/_bin/firm-task-claim.sh` (lists open tasks in `10-tasks/_open/`) OR `firm-task-claim.sh T-2026-MM-DD-NNN` to claim a specific one
3. Task moves to `_in-progress/`, branch auto-named `<role>/<task-id>`, worktree spawned (brain-G3-gated)
4. Work on your branch; commit as usual
5. `~/code/command-center/_bin/firm-task-complete.sh T-2026-MM-DD-NNN` → commits + opens draft PR + flags operator
6. Operator OK kjør → push the PR; task moves to `_done/`

### F. Dispatch parallel sub-agents

1. From command-center web `/brain` page: enter intent + select target roles → "Dispatch"
2. Or append to `~/Obsidian/Brain/00-firm-bus/inbox/<role>.md` directly using the dispatch frontmatter (task_id, from, to, objective, branch, files_allowed, expected_output, tests, rollback, sla_seconds)
3. Receiving pane's `firm-inbox-watch.sh` (5s polling) shows banner + processes async
4. See [[Runbook-Multi-Agent-Dispatch]] for sizing rules (5/10/15-agent fanout)

### G. See what the brain remembers about a project

1. command-center web `/brain/memory` → filter by `project: <name>` + optional `source_type:`
2. Or CLI: `/brain recall "<project-name> recent decisions"` with project-scoped query
3. Returns last N MemoryObjects sorted by `created_at`, each with full 4-field distillation + source-ref

## Operator approval gates (still binding)

| Gate | Action | Why operator-gated |
|---|---|---|
| Per PR push | `git push` from any repo | CLAUDE.md mandate — no auto-push, no exceptions |
| brain-G3 worktree-default | `firm-wt-split.sh --worktree-default` becomes default | Changes daily pane-startup behavior |
| brain-G4 nightly-distill cron | crontab entry for `brain-distill-daily` skill | Writes to brain nightly without operator present |
| brain-G6 queue-watcher auto | BrainOrchestrator auto-picks `_queue/` files | First runs manual; auto only after 1 week proven |
| Strategy/risk | Any money-impact change in Nexus | Operator + Karri review per CLAUDE.md |
| New skill auto-promote | `_proposed/` → `03-skills/` active | Operator manually reviews proposed skills |

## Where things live

| Thing | Path |
|---|---|
| Plan | [[2026-05-25-brain-upgrade-plan]] |
| Specs (7 stk) | `08-system-architecture/specs/*.md` |
| MOCs | [[System-Architecture-MOC]], [[Memory-MOC]], [[RAG-MOC]], [[Skills-MOC]], [[Tasks-MOC]], [[Youtube-MOC]], [[Github-Repos-MOC]], [[Retrospectives-MOC]] |
| Live tracking | `~/Obsidian/Brain/00-firm-bus/feed.md` + `~/Obsidian/Brain/00-claude-inbox/command-center/2026-05-25-brain-upgrade-fase2.md` |
| Skills | `~/Obsidian/Brain/03-skills/` (operator-ref) + `~/.claude/skills/` (workspace) + `<repo>/.claude/skills/` (project) |
| Tasks | `~/Obsidian/Brain/10-tasks/_open/` + `_in-progress/` + `_done/` + `_blocked/` |
| Retrospectives | `~/Obsidian/Brain/09-retrospectives/` (per-uke roll-up, e.g. `2026-W22.md`) |
| YouTube notes (distilled) | `~/Obsidian/Brain/12-youtube/<channel>/` |
| YouTube queue (drop URLs here) | `~/Obsidian/Brain/12-youtube/_queue/` |
| GitHub repo notes (distilled) | `~/Obsidian/Brain/13-github-repos/` |
| GitHub queue (drop searches here) | `~/Obsidian/Brain/13-github-repos/_queue/` |
| Verbatim YouTube transcripts | `~/Obsidian/Brain/_library/youtube/` (local-only, gitignored) |
| Templates | `~/Obsidian/Brain/00-templates/` (8 stk: atomic/moc/skill/retrospective/task/memory-object/youtube-note/github-repo-note) |
| firm-launcher scripts | `~/code/command-center/_bin/firm-{wt-split,wt-tabs,zellij,tab-init,task-claim,task-complete,inbox-watch}.sh` |

## Common scenarios

### "I dropped a YouTube URL, nothing happened"

- Check BrainOrchestrator is running: `curl http://localhost:3000/api/health` (look for `brainOrchestrator: ok`)
- Check brain-G6 status — if queue-watcher not yet auto-activated, run manually: `/skill youtube-ingest url=<url>`
- Check `feed.md` for error logs: `tail -50 ~/Obsidian/Brain/00-firm-bus/feed.md | grep youtube`
- Last resort: verify yt-dlp + whisper installed on host

### "I want to know what the brain decided about X yesterday"

- `/brain recall "X yesterday"` — Tier 2 retrieves MemoryObjects + source-ref backlinks
- Or read `09-retrospectives/<current-week>.md` for a weekly summary roll-up
- Or browse `_decisions/` directly if it was an immutable decision (15+ dato-stemplede)

### "How do I add a new project to the workspace?"

1. Add row to `~/code/CLAUDE.md` "Projects in this workspace" table
2. Create per-project `<repo>/CLAUDE.md` per project-template (see existing projects)
3. Add brain folder `~/Obsidian/Brain/<NN>-<project>/` + MOC
4. Add to firm-launcher pane mapping in `command-center/_bin/firm-wt-split.sh` if it needs its own pane
5. Add `<repo>/.claude/skills/` for project-local skills

### "A task is stuck in `_in-progress/` for days"

- Stale-task routine (daily) flags tasks > 14 days as candidates for ping
- Operator gets inbox-note in `00-firm-bus/inbox/<role>.md` — decide: resume, reassign, or close
- Force-release: `firm-task-release.sh <task-id>` returns it to `_open/` (advisory lock, not enforced)

### "My recall returned junk"

- Tier 2 default uses hybrid BM25+HNSW+rerank; if MRR is poor for your query type, try Tier 3 agentic: `/brain ask "..."`
- Check eval set `08-system-architecture/eval/recall-eval-2026-05-25.md` — file a counter-example if your query should have hit
- Verify distillation ran for the relevant date: `/brain/memory` filter by date range

## Manual ingestion until brain-G6 activates

While brain-G6 (queue-watcher auto-pickup) is not yet activated, operator must trigger each ingestion manually. The queue folders are STILL the right place to drop URLs/queries — they just need a manual /skill invocation to actually process.

### YouTube manual ingest

#### Option A: Drop file + trigger
```bash
# 1. Drop URL in queue (good practice — keeps audit trail)
echo "https://youtube.com/watch?v=abc123" > ~/Obsidian/Brain/12-youtube/_queue/$(date -u +%Y-%m-%dT%H%M)-demo.url

# 2. Trigger ingest manually
/skill youtube-ingest url=https://youtube.com/watch?v=abc123
# OR (when invokeSkill via CLI is wired):
~/code/command-center/_bin/run-skill.sh youtube-ingest url=https://youtube.com/watch?v=abc123
```

#### Option B: Direct, no queue file
```bash
# Just trigger — no queue audit
/skill youtube-ingest url=https://youtube.com/watch?v=abc123
```

#### Option C: Programmatic from Node
```typescript
import { ingestVideo } from "@cc/youtube-ingest";

const result = await ingestVideo("https://youtube.com/watch?v=abc123");
console.log(result.notePath);
```

**Where output lands:**
- Distilled note: `~/Obsidian/Brain/12-youtube/<channel-slug>/<YYYY-MM-DD-video-slug>.md`
- Verbatim transcript (local only, .gitignored): `~/Obsidian/Brain/_library/youtube/<channel>/<slug>/transcript.txt`

**Prerequisites:**
- `yt-dlp` installed: `pip install yt-dlp` or `brew install yt-dlp`
- (Optional) `faster-whisper` for transcript fallback if YouTube auto-sub unavailable

**Expected runtime:** 30s-2min per video (depends on transcript availability + chunking complexity)

### GitHub discovery manual

#### Option A: Drop search + trigger
```bash
# 1. Drop search query in queue
cat > ~/Obsidian/Brain/13-github-repos/_queue/$(date -u +%Y-%m-%dT%H%M)-demo.md <<EOF
---
search: "agent orchestration TypeScript stars:>100"
limit: 5
---
EOF

# 2. Trigger discovery manually
/skill github-discover query="agent orchestration TypeScript stars:>100" limit=5
```

#### Option B: Direct, no queue file
```bash
/skill github-discover query="agent orchestration TypeScript stars:>100"
```

#### Option C: Programmatic from Node
```typescript
import { discoverRepos } from "@cc/github-discovery";

const result = await discoverRepos("agent orchestration TypeScript", { 
  limit: 5,
  min_stars: 100,
});
console.log(`Discovered ${result.repos.length} repos, ${result.tasks_proposed.length} task proposals`);
```

**Where output lands:**
- Distilled repo notes: `~/Obsidian/Brain/13-github-repos/<owner>-<name>.md`
- Implementation-task proposals (if relevance > 0.7 AND license_compatible AND risk < 0.4): `~/Obsidian/Brain/10-tasks/_open/T-<date>-NNN-<slug>.md`

**Prerequisites:**
- `gh` CLI installed + authenticated: `gh auth status`
- Anthropic API key set (for relevance scoring): check `$ANTHROPIC_API_KEY`

**Rate limits (per spec):**
- Max 50 search calls/day
- Max 20 extract calls/day
- 60s cooldown between calls
- Tracked in `state_kv` table (or in-memory until persisted)

### Skill brain-distill-daily manual

```bash
# Distill yesterday's audit_log entries:
/skill brain-distill-daily date=$(date -u -d yesterday +%Y-%m-%d)

# Distill a specific date:
/skill brain-distill-daily date=2026-05-24
```

**Prerequisites (depends on code-1 lane):**
- @cc/memory-engine implemented (C1-2 + C1-3)
- @cc/rag-engine semantic-chunker available (C1-4)

**Status:** Will return "deferred" until code-1's lane lands.

### Skill brain-recall manual

```bash
# Tier 2 default:
/skill brain-recall query="strukturert distillation paper"

# Tier 3 agentic (complex):
/skill brain-recall query="hva bestemte vi om refi-pilot i forrige uke" tier=3
```

**Prerequisites:**
- memory-engine + rag-engine (code-1 lane)
- Brain has been distilled at least once (pre-distill manifest tier S minimum)

### Why manual until brain-G6

brain-G6 (queue-watcher auto-pickup) requires:
1. youtube-ingest + github-discovery packages stable (✓ done D-2 + D-3)
2. Anti-hype filter validated on 5+ test URLs (operator action)
3. License-guard validated on 1+ GPL repo (acceptance test in D-3)
4. Rate-limit tracking confirmed working
5. Operator OK kjør per `[[Runbook-Brain-Preflight-Checklist]]` § brain-G6

Once brain-G6 activates, queue files are picked up automatically within ~1h.

### Cost estimate (manual ingestion phase)

| Action | Compute | API cost |
|---|---|---|
| 1 YouTube video (10 min) | ~30s CPU | ~$0.01 LLM (distill) |
| 1 GitHub search (5 repos) | ~60s wall | ~$0.05 LLM (scoring + distill) |
| 1 brain-distill-daily run | ~5min wall | ~$0.10 LLM (depends on day volume) |

**Daily budget at moderate use:** ~$1-3 USD in LLM costs.

## Maintenance cadence

| Frequency | What | Where / how |
|---|---|---|
| Per-action | distill `audit_log` row | nightly batch (brain-G4-gated) |
| Daily | stale-task scan (> 14 dager) | BrainOrchestrator trigger → inbox |
| Daily | repo-health audit (TS errors, dead deps) | report-only → `09-retrospectives/` |
| Hourly | YouTube + GitHub queue drain | BrainOrchestrator routines (brain-G6-gated) |
| Weekly | dead-link wikilink check | `10-tasks/_open/` if broken refs found |
| Weekly | retrospective generation | Sunday 22:00 → `09-retrospectives/<ISO-week>.md` |
| Weekly | arch-review (specs vs code drift) | `08-system-architecture/` drift-rapport |
| Monthly | spec-review pass + INTEGRATION_NOTES update | manual operator pass |
| Monthly | inbox archive | GitHub Actions auto-PR (1st of month, 07:00 UTC) |

All routines are REPORT-only — never auto-fix. Per CLAUDE.md operator-principle.

## Related

- [[Runbook-Brain-Weekly-Maintenance]] — what runs automatically + override commands
- [[Runbook-Multi-Agent-Dispatch]] — sizing rules for parallel sub-agent fanout
- [[Runbook-Obsidian-Git-Sync]] — vault push/pull mechanics
- [[2026-05-25-brain-upgrade-plan]] §2 (target arkitektur) + §13 (live status)
- [[System-Architecture-MOC]] — index over alle specs + arkitektur-noter
- [[Operator-Principles]] — binding rules (no auto-disable, OK kjør gate, secret handling)

---

Sist oppdatert: 2026-05-25 — v1.0, første utgivelse i sync med brain-upgrade fase 2 komplett.
