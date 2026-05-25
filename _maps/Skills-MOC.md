---
title: Skills-MOC
type: moc
created: 2026-05-25
purpose: Index of brain-tier, workspace-tier, project-tier, and system-injected skills across all three hierarchy tiers
related: [[2026-05-25-brain-upgrade-plan]]
tags: [moc, skills, registry, hermes, tier-3]
---

# Skills-MOC

Curated index of the three-tier skill hierarchy: brain-tier skills (live in `03-skills/`, invocable by orchestrator/agents), workspace-tier skills (live in `~/.claude/skills/`, auto-load via SKILL.md), project-tier skills (live in `<repo>/.claude/skills/`, scope-limited), and system-injected skills (bundled with Claude Code CLI, listed in session-start). Each skill is name-invokable with a structured trigger contract; see [[SKILL_REGISTRY_SPEC]] for the binding schema.

## Brain-tier skills

Live in `03-skills/` — Hermes-style reusable skills, workspace-scope, currently 5 active drafts (status `active` pending operator review per [[03-skills/README]]).

- [[brain-distill-daily]] — Nightly distillation of yesterday's command-center actions + Claude conversations into MemoryObjects; triggered nightly at 03:00 local OR on-demand for any past date (keywords: "distill yesterday", "process audit_log").
- [[youtube-ingest]] — Runs the youtube-ingest pipeline on a URL or drains `12-youtube/_queue/`; fetches metadata + transcript, distills into a brain note (keywords: "ingest video", "youtube transcript", "distill talk").
- [[github-discover]] — Searches gh + scores repos + distills top-N into `13-github-repos/` notes; reads from `13-github-repos/_queue/` or accepts a manual query string (keywords: "find repos", "gh search", "scout github").
- [[multi-agent-dispatch]] — Fans out a single intent to N parallel firm-bus agents via command-center orchestrator API; collects receipts in `00-firm-bus/feed.md` (keywords: "dispatch to all", "parallel agents", "fan out", "broadcast task").
- [[worktree-spawn-cleanup]] — Creates a new git-worktree for a task (spawn) OR GCs stale worktrees (cleanup) via the firm-worktree scripts; supports the Conductor-style isolated-branch workflow (keywords: "new worktree", "isolate branch", "cleanup worktrees", "GC branches").

See [[03-skills/README]] for subfolder lifecycle (`_proposed/` → root → `_archived/`; `_system/` is read-only mirror).

## Workspace-tier skills

Live in `~/.claude/skills/<name>/SKILL.md` — auto-loaded for any Claude Code session on this machine.

- **trading-knowledge** (`~/.claude/skills/trading-knowledge/SKILL.md`, v0.2.0) — Routes Claude through the operator's curated trading-knowledge library at `~/Obsidian/Brain/_library/trading/` (concepts/strategies/lessons/sources + INDEX). Triggers on strategy/trade/gate/regime/ORB/Karri/XAUUSD and ~30 other Nexus-domain keywords. Prevents two failure modes: (a) fabricating from training data when curated material exists; (b) over-fetching dozens of notes when tag-search suffices. Re-eval trigger: migrate to pgvector/Chroma when `lessons/` crosses ~30 entries.

## Project-tier skills

Live in `<repo>/.claude/skills/` — scope-limited to one repo. Currently **none deployed** — no `.claude/skills/` subfolders exist under any project in `/home/nithu/code/`. Planned candidates per [[2026-05-25-brain-upgrade-plan]]: Nexus-specific `postmortem-classify`, `gate-status-summarize`; thesis-specific `bibtex-fetch`, `figure-naming`.

## System-injected skills

Bundled with the Claude Code CLI; appear in the session-start `<system-reminder>` block; cannot be edited (mirrored read-only into `03-skills/_system/` per [[03-skills/README]] when needed). 13 standard skills as of session 2026-05-25:

| Skill | One-line purpose |
|---|---|
| `verify` | Run the app + observe behaviour to confirm a change actually works |
| `code-review` | Review the current diff for correctness bugs at low/medium/high effort |
| `loop` | Run a prompt or slash command on a recurring interval (or self-paced) |
| `schedule` | Create/update/list/run scheduled remote agents (routines) on cron |
| `run` | Launch and drive the project's app to see a change working live |
| `init` | Initialize a new CLAUDE.md with codebase documentation |
| `review` | Review a pull request |
| `security-review` | Complete a security review of pending changes on the current branch |
| `claude-api` | Build/debug/optimize Claude API + Anthropic SDK apps (incl. prompt caching, model migrations) |
| `update-config` | Configure the Claude Code harness via settings.json (hooks, permissions, env vars) |
| `keybindings-help` | Customize keyboard shortcuts in `~/.claude/keybindings.json` |
| `fewer-permission-prompts` | Scan transcripts + add a prioritized Bash/MCP allowlist to project settings |
| `trading-knowledge` | (Workspace-tier; appears here because Claude Code auto-injects it into the skills list) |

## Related

- [[SKILL_REGISTRY_SPEC]] — binding frontmatter schema + invocation contract for brain-tier skills.
- [[2026-05-25-brain-upgrade-plan]] — Module D (Skill Registry) covers auto-skill-creation gap; brain-tier is mostly greenfield outside of trading-knowledge.
- [[Github-Repos-MOC]] — the `github-discover` skill above wraps Module F's discovery pipeline; co-evolves with new GitHub-side capabilities.
- [[Memory-MOC]] — skills that emit distillation triggers (e.g. `brain-distill-daily`, `youtube-ingest`) write into the verbatim + distilled layers.
- [[Runbook-Multi-Agent-Dispatch]] — operational procedure that the `multi-agent-dispatch` skill wraps.
- [[System-Architecture-MOC]] — parent context for the three-tier skill hierarchy (Module D within the brain-OS upgrade plan).
- [[Tasks-MOC]] — `multi-agent-dispatch` fans out tasks from `10-tasks/_open/`; the two MOCs share the worktree-spawn skill as a primitive.
- [[Tools-MOC]] — registered MCPs (a separate roster of capabilities; skills compose on top of tools).
- [[Workflows-MOC]] — recurring workflows; many are candidate skills once stable.
- [[Youtube-MOC]] — the `youtube-ingest` skill above wraps Module E's ingestion pipeline; co-evolves with new YouTube-side capabilities.
- `_runbooks/` — operational procedures (conceptually similar to skills but human-executed; skills are agent-invokable wrappers around proven runbooks).

## Open questions

- Auto-promotion of `_proposed/` skills after N successful invocations vs. operator-only promotion — see [[System-Architecture-MOC]] open questions.
- Project-tier skill bootstrap: which repo gets the first `.claude/skills/`? Likely Nexus (`postmortem-classify`).
