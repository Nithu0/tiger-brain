# FIRM CHARTER — roles, ownership & workflow

**Status:** v1 — **operator-confirmed 2026-06-08.** Canonical role + collision-prevention contract for the 8-pane firm. Supersedes the thin `roster.md` table (which now points here). The code-1/code-2 split in §1 is binding (operator-confirmed); code-2 notified via inbox.

This file answers three questions so the team works as a team, not 8 agents colliding:
1. **Who owns what** (and what they must NOT touch).
2. **How we avoid breaking each other** (binding workflow rules).
3. **The shared substrate** (Brain memory/learning/automation everyone plugs into).

---

## 1. Leadership

**code-1 and code-2 are the two leaders.** They have full visibility into every project and the cross-cutting authority to coordinate, unblock, and arbitrate. That visibility is *why* they hold workspace-wide roles — they see the whole board, the single-project panes see one square.

Leaders do NOT do the single-project panes' domain work for them (e.g. code-1 does not write Nexus strategy code — that's ai-1/ai-2). Leaders build the shared systems, set the workflow, and dispatch/coordinate.

| Leader | Primary lane | Owns |
|---|---|---|
| **code-1** | Brain / AI-OS engine + datacenter | The Brain product packages (`brain-orchestrator`, `memory-engine`, `rag-engine`, `skill-registry`, `bus`, `agents`, `executor`, `youtube-ingest`, `github-discovery`), node-migration toward the mini AI datacenter, the memory/learning/automation systems, this charter + cross-project coordination. |
| **code-2** | Apps / infra / ops + tooling | command-center `apps/api` + `apps/web`, deploy (Docker/Railway/node-stack), env-health, MCP/tool setup, CI, and per-project support lanes when a single pane needs leader help (e.g. AS refi). |

Both have full read access everywhere. **Write-collision rule:** if a change is in the other leader's primary lane, hand it off via inbox rather than editing — unless it's a one-line cross-cutting fix you announce in `feed.md` the same minute.

---

## 2. Role ownership

Each pane **owns** its lane (decides + implements), must **not touch** the listed boundaries, and **hands off** across them via the other role's inbox.

| Role | Project | Owns | Must NOT touch | Hands off to |
|---|---|---|---|---|
| **code-1** | workspace | Brain/AI-OS engine, datacenter, memory/learning/automation, charter | Nexus trading code; code-2's apps/infra lane | code-2 (infra), ai-1/ai-2 (nexus) |
| **code-2** | workspace | command-center apps/api+web, deploy, env, MCP, CI, project support | Brain engine packages; live trading decisions | code-1 (brain), the owning pane |
| **ai-1** | nexus | Live ops: foundation gate, `/health`, Discord audit, deploys, env-flag truth on the worker | code-2/code-1 workspace packages; strategy *design* (that's ai-2) | ai-2 (strategy), operator (env) |
| **ai-2** | nexus | Strategy/risk proposals, postmortems, Karri handoffs, tests + observability | Live deploy/env flips (ai-1 + operator); workspace packages | ai-1 (ops), Karri (strategy review) |
| **thesis-1** | master-oppgave | Thesis writing + battery-electrolyte ML pipeline | Any non-thesis repo | code-1 (tooling help) |
| **as-1** | AS | Regnskap, inntekt-strategier, skattemelding, refi docs | Other projects | code-2 (refi/tooling) |
| **soking-1** | soking-fulltid | Jobbsøking ML/AI/data — scrape + CRM | Other projects | code-1 (scrape infra) |
| **personal-1** | personlig | Personlig optimalisering — effektivitet, mat, trening, søvn | Other projects | — |

**Nexus boundary (binding after 2026-06-08):** the trading platform (`ai-assistent`) belongs to ai-1 + ai-2. Leaders coordinate but do not edit Nexus strategy/firm/worker code or push Nexus commits.

---

## 3. Collision-prevention workflow (binding)

These rules exist because we have observed real collisions: shared-checkout concurrent edits causing transient build failures, pre-emptive edits before reading an inbox, and a shared task list polluted across roles.

1. **Read before you act.** On any non-trivial task: `tail -50 feed.md`, check `PRESENCE.md` for who's online, and read your own `inbox/<role>.md`. The session-start hook surfaces these — don't skip them. (See [[feedback_read_own_inbox_first]].)
2. **Stage explicit paths, never `git add -A`.** Shared checkouts mean a peer may have uncommitted work in the same tree. Commit only the files you changed. Suspect a concurrent peer for failures in files you didn't touch; re-run before concluding it's real. (See [[feedback_shared_instance_commit_hygiene]].)
3. **One owner per file at a time.** If you need to edit another role's lane, hand off via inbox. Don't pre-empt; if you already did, disclose it in full in their inbox so they can dedup/override.
4. **Task lists are per-role, not shared.** The harness task list is local working memory for one pane — do not treat another role's tasks as yours, and don't assume yours are visible to them. Cross-role work is dispatched via `inbox/<role>.md`, not the task list. Durable cross-pane state lives in `agent_tasks` (command-center TaskStore), not the ephemeral list.
5. **feed.md is append-only, one line per event.** Long reports go to `~/Obsidian/Brain/00-claude-inbox/<project>/`. Never edit old feed/PRESENCE rows.
6. **"OK kjør"-gate before every push.** No exceptions (operator-prinsipp 5).
7. **Money/strategy/risk changes route through review** (Karri for Nexus) before activation. Infra that doesn't change decisions runs freely.
8. **Verify before declaring done.** The user's experience is the bar, not "tsc clean + commit landed."
9. **One live session per role (enforced).** A role (`code-1`, `code-2`, `ai-1`, …) is a single live process. The firm launcher (`_bin/firm-tab-init.sh`) takes a per-role pidfile lock (`$XDG_RUNTIME_DIR/firm-role.<role>.pid`, falling back to `/tmp`) and **rejects a second launch** of an already-online role; stale locks (dead pid) auto-reclaim. The rare intentional dual-session case must be explicit: `FIRM_ALLOW_MULTI=1` **and** a per-role git worktree (rule 10) so the two sessions never share a branch. Do not run two panes for the same role on one checkout — that is exactly the collision that stacked 5 unpushed commits on 2026-06-09.
10. **No shared checkout per branch — isolate via per-role git worktree.** Two sessions must never edit the same working directory on the same branch. For workspace leader work in `command-center`, spin a per-role worktree off `origin/main` and work on a `code-1/<slug>` (or `code-2/<slug>`) branch:
    ```
    _bin/firm-worktree-spawn.sh claude <repo-path> <slug>   # creates .worktrees/claude/<slug> + branch claude/<slug>
    _bin/firm-worktree-list.sh                              # see all firm worktrees
    _bin/firm-worktree-cleanup.sh                           # dry-run; --force to prune clean/stale ones
    ```
    Never stack your commits on top of another role's feature branch. If you find yourself committing onto a peer's branch, stop and hand off via their inbox — the cleanup is destructive (see [[branch-recovery-2026-06-09]]). Worktrees keep `.git` shared but give each session its own files + branch + index, which removes the shared-checkout collision class entirely.

---

## 4. Shared substrate — Brain memory/learning/automation

Everyone plugs into the same Brain (command-center packages + `~/Obsidian/Brain`). This is what makes the team compound instead of repeat.

- **Memory** (`memory-engine`, Module B): distills durable facts from work. Per-project memory under `~/.claude/projects/<slug>/memory/`. Write what was non-obvious; don't duplicate what the repo records.
- **Learning** (`rag-engine` + skill registry): hybrid BM25+vector retrieval (bge-m3, MRR≈0.97) over the Brain; 3-tier reusable skills in `03-skills/`. Drop YouTube/GitHub sources in `12-youtube/_queue` + `13-github-repos/_queue` for auto-distill.
- **Automation** (`brain-orchestrator` Module A + C1-9 task-persistence + `@cc/brain-worker` pickup loop): always-on daemon (heartbeat/reaper/triggers) with `agent_tasks` + `firm_state` and a worker that claims→executes queued tasks — end-to-end autonomy. **Gates G4 (nightly-distill) + G6 (queue-watcher auto-pickup) flipped ON in node deploy 2026-06-08** (code defaults stay OFF for fresh boots). G6/ingest runs as-is; G4/distill needs `ANTHROPIC_API_KEY` on the node (haiku distiller, else candidate nights requeue).
- **Coordination** (`00-firm-bus`): feed/inbox/presence/roster + this charter.

**Datacenter goal:** run the whole stack 24/7 on the self-built local AI node (Tailscale-only). See [[project_node_migration]]. The substrate above is the software that the mini AI datacenter will host.

---

## 5. Escalation & handoff

- **Blocked on a peer** → write their inbox with concrete asks (what you did / what you need / files / commits). No FYI spam.
- **Blocked on operator** (env flips, money, irreversible) → one-line ping in `feed.md` + detail in `00-claude-inbox/`.
- **Cross-machine** (operator ↔ Karri) → Brain syncs every 2-5 min via Obsidian Git; for sub-minute use Discord.

---

*Update this file with a `## Update YYYY-MM-DD` block when the split or workflow changes. Don't delete sections.*

## Update 2026-06-08 — split operator-confirmed

Operator confirmed the code-1/code-2 leadership split (§1) as binding: **code-1** = Brain/AI-OS engine + datacenter + memory/learning/automation + coordination; **code-2** = command-center apps/infra/ops + tooling + project support. No longer a proposal — this is the working contract. code-2 informed via inbox; edit §1 + add a follow-on Update block here if the boundary needs to move.

## Update 2026-06-09 — shared-checkout collision + hardening

**What happened.** Two concurrent `code-1` sessions ran against the SAME `command-center` checkout on the SAME branch. The result was a three-way mess:
1. **Task-list pollution** — each pane treated the other's harness task list as shared state.
2. **5 stacked unpushed commits** — code-1 brain work (`d15ec58`, `e896f0c`, `e92148e`, `af17799`, `c9f4fd5`, plus a 6th HEAD commit `d383759`) piled on top of code-2's book-ingest commit (`d1e16ca`) on `feat/wf-knowledge-ingest-books`, mixing two roles' work on one feature branch 6 commits ahead of `origin/main`.
3. **Transient build breakage** — concurrent edits in one working tree.

This is the collision class §3 rule 1-4 already warned about, but the launcher did nothing to *prevent* it. Two fixes landed:

- **Single-session lock** (`_bin/firm-tab-init.sh`): per-role pidfile (`$XDG_RUNTIME_DIR/firm-role.<role>.pid`, fallback `/tmp`). A second launch of an already-online role is rejected with exit 3; dead/garbage pids auto-reclaim; opt-out via `FIRM_ALLOW_MULTI=1`. The lock survives the `exec claude` because the pid is unchanged, so it tracks the live claude process for the pane's whole lifetime. This is now §3 rule 9.
- **Per-role worktree isolation** (§3 rule 10, documented opt-in — see "Worktree decision" below): use `_bin/firm-worktree-spawn.sh` so two sessions never share a working dir/branch.

**Worktree decision (honest):** auto-worktree was **NOT** wired into `firm-tab-init.sh` by default. The spawn script needs `<model> <repo-path> <slug>` (no safe default slug per pane), `command-center` isn't even in its REPOS list yet, single-project panes (thesis with its auto-push hook, AS, etc.) would break if force-redirected into a worktree, and `wt.exe --cd` already sets each pane's directory. Forcing it risked breaking a normal `firm` launch — the explicit instruction was "do not force it." So worktrees stay **opt-in + documented** (§3 rule 10) with a recommendation to make per-role worktrees the default for the two workspace leader panes once the spawn script grows a per-role default slug and adds `command-center` to its repo list. The single-session lock is the immediate, zero-risk guard; the worktree convention is the structural fix to adopt next.

**Cleanup of the current mess:** see the operator-gated runbook [[branch-recovery-2026-06-09]] (`command-center/docs/ops/branch-recovery-2026-06-09.md`). It is a PLAN only — no git was executed by the session that wrote it.
