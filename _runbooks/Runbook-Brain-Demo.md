---
title: Runbook — Brain System Demo (15 min)
type: runbook
created: 2026-05-25
audience: operator + visitors (Karri, future collaborators)
purpose: 15-minute end-to-end demo of the brain — verify everything works
related:
  - "[[Runbook-Brain-Upgrade-Workflow]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [runbook, demo, walkthrough, e2e]
---

# Runbook — Brain System Demo (15 min)

> Run this end-to-end demo to (a) verify the brain works after a fresh pull, (b) show someone the system, (c) refresh your own mental model.

## Prerequisites (1 min)

- command-center running locally: `cd ~/code/command-center && npm run dev`
- Or hosted at Railway URL (substitute below where you see `http://127.0.0.1:3200`)
- Obsidian open on `~/Obsidian/Brain/`
- One firm pane active: `echo $FIRM_ROLE` returns non-empty (e.g. `ai-1`)
- `gh` CLI authenticated (`gh auth status`) — only needed if Part 4 goes past demo-stop

## Part 1 — See what's there (2 min)

### Dashboard

1. Open `~/Obsidian/Brain/00-DASHBOARD.md` in Obsidian
2. Note the "Brain System" section (added 2026-05-25)
3. Click into `[[System-Architecture-MOC]]` — see the architecture map
4. Click into `[[2026-05-25-brain-upgrade-plan]]` — see the full plan

### Web UI

1. `xdg-open http://127.0.0.1:3200/brain/` (or paste Railway URL into browser)
2. Notice the 6 sub-pages: recall, memory, skills, tasks, routines, rag
3. Click into `/brain/skills` — see the 7 skills (5 brain + workspace `trading-knowledge` + invokes)
4. Click into `/brain/tasks` — see 3 pilot tasks in `_open/`

## Part 2 — Drop content into the brain (3 min)

### YouTube

1. Pick a short educational YouTube URL (operator-curated)
2. Drop into `12-youtube/_queue/`:
   ```bash
   echo "https://youtube.com/watch?v=dQw4w9WgXcQ" > ~/Obsidian/Brain/12-youtube/_queue/$(date -u +%Y-%m-%dT%H%M)-demo.url
   ```
3. Until brain-G6 activated, run manually:
   ```bash
   /skill youtube-ingest url=https://youtube.com/watch?v=dQw4w9WgXcQ
   ```
4. See result in `~/Obsidian/Brain/12-youtube/<channel-slug>/<date-slug>.md`

### GitHub

1. Pick a tech topic
2. Drop search:
   ```bash
   cat > ~/Obsidian/Brain/13-github-repos/_queue/$(date -u +%Y-%m-%dT%H%M)-demo.md <<'EOF'
   ---
   search: "agent orchestration TypeScript stars:>100"
   limit: 3
   ---
   EOF
   ```
3. Until brain-G6 activated, run manually:
   ```bash
   /skill github-discover query="agent orchestration TypeScript stars:>100" limit=3
   ```
4. See results in `~/Obsidian/Brain/13-github-repos/<owner>-<name>.md` (plus possible implementation-task in `10-tasks/_open/`)

## Part 3 — Recall something (2 min)

### Via CLI (when RAG implemented by code-1)

```bash
/brain recall "structured distillation paper"
```

Expected (once C1-4 lands): top-5 hits with `[ref:<id>]` backlinks pointing to brain notes mentioning the paper.

### Via web UI

1. `xdg-open http://127.0.0.1:3200/brain/recall`
2. Type query into input
3. Hit "Recall"
4. Currently 503 until C1-4 lands — shows graceful "kommer snart" card

## Part 4 — Task lifecycle (3 min)

### Claim

```bash
cd ~/code/command-center
~/code/command-center/_bin/firm-task-claim.sh                    # list available
~/code/command-center/_bin/firm-task-claim.sh T-2026-05-25-002   # claim a pilot
```

Note: file moves from `10-tasks/_open/` to `10-tasks/_in-progress/`.

### Work

Skip the actual implementation — just demo the lifecycle.

### Complete (in demo mode — abort before push)

```bash
# DO NOT run this in demo:
# ~/code/command-center/_bin/firm-task-complete.sh T-2026-05-25-002
```

Instead, restore:

```bash
mv ~/Obsidian/Brain/10-tasks/_in-progress/T-2026-05-25-002*.md ~/Obsidian/Brain/10-tasks/_open/
```

(Optionally hand-edit frontmatter back to `status: open` + drop `claimed_at`/`claimed_by` lines.)

## Part 5 — Sub-agent dispatch (3 min)

### Via firm-bus inbox

```bash
echo "## $(date -u +%FT%TZ) — from $FIRM_ROLE: demo dispatch" >> ~/Obsidian/Brain/00-firm-bus/inbox/ai-2.md
```

Receiving pane gets banner via `firm-inbox-watch.sh` within 5s.

### Via command-center API

```bash
curl -X POST http://127.0.0.1:3100/api/terminals/dispatch \
  -H 'content-type: application/json' \
  -d '{"intent":"demo dispatch","roles":["ai-2"]}'
```

See result in `feed.md` + `ai-2` inbox.

## Part 6 — Read the audit trail (2 min)

```bash
cat ~/Obsidian/Brain/00-claude-inbox/command-center/2026-05-25-30-agent-audit.md
```

Shows full 30+ agent breakdown — operator can see every decision + deliverable.

Also:

```bash
tail -50 ~/Obsidian/Brain/00-firm-bus/feed.md
```

Chronological event log (last 50 lines).

## Part 7 — Health check (1 min)

```bash
# Preflight (full):
~/code/command-center/_bin/brain-preflight.sh

# Brain sanity (fast):
~/Obsidian/Brain/scripts/sanity.sh

# Test suite:
cd ~/code/command-center && npm test
```

Expected: 522/522 tests passing, sanity green, preflight pass.

## After the demo

- Discuss: which gate is the most valuable to activate first (brain-G3, brain-G4, or brain-G6)?
- Discuss: what skills should be added next?
- Drop a real task in `10-tasks/_open/` for follow-up work

## Time check

| Part | Estimated |
|---|---|
| Prereqs | 1 min |
| 1 See what's there | 2 min |
| 2 Drop content | 3 min |
| 3 Recall | 2 min |
| 4 Task lifecycle | 3 min |
| 5 Sub-agent dispatch | 3 min |
| 6 Audit trail | 2 min |
| 7 Health check | 1 min |
| **Total** | **~17 min** |

(15 min target; ~2 min buffer for slow loads / questions.)

## Related

- [[Runbook-Brain-Upgrade-Workflow]] — daily ops, more detail
- [[Runbook-Sample-Task-Walkthrough]] — just task lifecycle
- [[Runbook-Brain-Preflight-Checklist]] — gate activation
- [[2026-05-25-brain-upgrade-plan]] — full architecture

---

Sist oppdatert: 2026-05-25 — v1.0, første utgivelse sammen med brain-upgrade fase 2 demo-pakke.
