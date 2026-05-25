---
title: Obsidian Brain Structure Spec
date: 2026-05-25
status: v1.0.2
spec_for: Module C (Obsidian Brain folder restructure) — brain-upgrade-plan
author: A-3 (sub-agent)
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[SKILL_REGISTRY_SPEC]]"
  - "[[MEMORY_DISTILLATION_SPEC]]"
tags:
  - spec
  - obsidian
  - brain-structure
  - folders
  - frontmatter
---

# Obsidian Brain Structure Spec

> **Operator directive:** strukturert, mest avansert, brain skal være lærende.
>
> This spec defines the additive folder restructure, frontmatter v2, link rules,
> naming conventions, stable IDs, templates, migration plan, MOC updates, and
> sanity-check extensions for the workspace brain at `/home/nithu/Obsidian/Brain/`.

---

## 1. Overview

This document is the authoritative target-state spec for the Obsidian vault's
folder taxonomy and conventions after the 2026-05-25 brain upgrade. It is the
deliverable for **Module C** of [[2026-05-25-brain-upgrade-plan]] §2 and is
referenced by Module D (skills), Module E (YouTube ingest), Module F (GitHub
discovery), Module H (background routines), and Module I (worktree-as-default).

### 1.1 Purpose

- Codify which folders exist, what each is for, and what frontmatter contracts
  each note-type carries.
- Define the conventions that `BrainOrchestrator` (Module A) can rely on when
  parsing notes into structured tasks, MemoryObjects, and skill registrations.
- Specify a `sanity.sh` extension surface so violations are caught at the
  pre-push gate rather than at ingestion time.
- Make the vault **learning-capable**: every new folder either feeds the
  distillation pipeline or surfaces what the operator should review next.

### 1.2 Additive-only principle (binding)

This restructure **never moves, renames, or deletes** existing top-level
folders. The load-bearing structures `_decisions/`, `_maps/`, `_runbooks/`,
`_library/`, `00-claude-inbox/`, `00-firm-bus/`, `claude-context/`, `handoffs/`,
`90-archive/`, and the per-project folders (`01-nexus/`, `02-thesis/`,
`03-business/`, `04-career/`, `05-learning/`, `06-AS/`, `07-personlig/`) are
**frozen in place**. Anything that needs to age out moves to `90-archive/`,
never `rm`.

Any agent that proposes relocation is in violation of this spec and should be
stopped. See §12 anti-patterns.

### 1.3 Scope

In-scope: 6 new folders, frontmatter v2 contract, wikilink discipline,
templates, migration of scattered content into new folders by **copy** (with
the original kept in place and tagged `superseded-by: [[...]]`), MOC updates,
sanity-check additions.

Out-of-scope: distillation pipeline internals (see [[MEMORY_DISTILLATION_SPEC]]),
skill discovery internals (see [[SKILL_REGISTRY_SPEC]]), retrieval engine, web
dashboard changes.

---

## 2. Current folder taxonomy (audited 2026-05-25)

Derived from [[2026-05-25-brain-upgrade-plan]] §1.3 and a fresh `ls` of the
vault root. All entries are **load-bearing** and remain in place.

| Folder | Status | Purpose |
|---|---|---|
| `00-DASHBOARD.md` | strong | Single-screen vault overview, links per project |
| `00-CONTROL-PANEL.md` | strong | Operator's quick-control surface (timers, focus) |
| `01-CURRENT-FOCUS.md` | strong | This week's operator focus, not history |
| `00-claude-inbox/<project>/` | strong | Draft → inbox → promote → repo lifecycle |
| `00-firm-bus/` | strong | Multi-pane async substrate: `feed.md`, `PRESENCE.md`, `inbox/<role>.md` |
| `00-command-center/` | strong | Daily audit-dumps from the command-center app |
| `01-nexus/` | strong | XAUUSD trading firm MOCs, runtime pointers, decisions |
| `02-thesis/` | strong | Master's thesis (ML for solid-state electrolytes) MOC |
| `03-business/` | strong | Strategy notes, light ops for the AS/firm side |
| `04-career/` | strong | Job search, active-job-search MOC |
| `05-learning/` | strong | Learning notes (per topic) |
| `06-AS/` | strong | Regnskap, inntekt, drift av AS — owned by `as-1` pane |
| `07-personlig/` | strong | Effektivitet, mat, trening, vaner — owned by `personal-1` |
| `08-system-architecture/` | created 2026-05-25 | Specs, ADRs, eval-sets for the brain upgrade itself |
| `_decisions/` | strong, immutable | 15 dated decision-trees, append-only |
| `_maps/` | strong | 20+ MOCs, wikilink anchors per domain |
| `_runbooks/` | strong | 17 operational procedures |
| `_library/` | strong | Raw external material (`youtube/` placeholder, `raw/` sparse) |
| `_promote-candidates/` | strong | Staging before repo migration |
| `claude-context/` | strong, operator-owned | Claude session entry-point material |
| `handoffs/` | strong | Day-end handoffs across sessions/machines |
| `90-archive/` | strong | Cold storage; nothing deleted, only moved here |
| `scripts/` | strong, operator-owned | `sanity.sh`, `brain_audit.py`, `path_guard.py`, hooks |
| `firm-launcher/` | strong | Mirrored launcher docs (firm-bus integration) |
| `prompts/` | strong | Reusable prompt fragments |
| `security/` | strong | Security notes, incidents |

**Conventions that already work** (and are preserved verbatim by this spec):

- YAML frontmatter on every note (`tags`, `type`, `created`)
- Wikilinks only (`[[Note]]`), no markdown links inside the vault
- MOC-per-domain: every domain has one anchor MOC in `_maps/`
- Date-stamped filenames for time-sensitive content (`YYYY-MM-DD-slug.md`)
- `_promote-candidates/` as staging before repo migration

**Gaps this spec fills:**

- Stable IDs (today only wikilinks — fragile on export/rename)
- Per-note-type frontmatter contracts (current spec only requires 3 keys)
- A canonical home for skills, YouTube ingests, GitHub repo notes,
  retrospectives, and workspace tasks
- A template folder so agents emit notes in the right shape on first try

---

## 3. NEW folders specification

All six folders below are **additive**. Each is created with a `README.md` that
points at this spec and the relevant downstream module.

### 3.1 `03-skills/` — Skill registry, operator-visible tier

**Purpose:** human-readable home for reusable procedures and agent-roles. One
file per skill. Mirrors `~/.claude/skills/<name>/SKILL.md` (workspace-wide)
and `<repo>/.claude/skills/<name>/SKILL.md` (project-local) — this folder is
the **operator-reference tier**, indexable from Obsidian and auto-discovered
by `BrainOrchestrator` when frontmatter `auto_invocable: true` is set.

See [[SKILL_REGISTRY_SPEC]] for the 3-tier discovery rules.

**Required frontmatter** (note-type: `skill`):

```yaml
---
title: <Skill Title in Title Case>
type: skill
created: YYYY-MM-DD
uid: 01HXXXXXXXXXXXXXXXXXXXXXXXX        # UUIDv7, see §7
tags: [skill, <domain>, ...]
auto_invocable: true | false             # if true, BrainOrchestrator can dispatch
triggers: [<trigger-1>, <trigger-2>]     # event names or cron-like cadence
cost: low | medium | high                # rough $/run + latency tier
cache_strategy: none | session | persistent
inputs: { <key>: <type-or-example> }
outputs: { <key>: <type-or-example> }
tools: [<tool-or-package-name>, ...]
related: [[<MOC-or-spec>]], ...
status: proposed | active | deprecated
---
```

**Subfolders:**

- `03-skills/_proposed/` — auto-generated skill stubs from
  `skill-extract-from-success` routine. Operator must promote manually.
- `03-skills/_deprecated/` — formerly active skills, kept for traceability.

**Naming:** kebab-case filename mirroring the skill name
(`brain-distill-daily.md`, `youtube-ingest.md`).

### 3.2 `12-youtube/` — One note per video

**Purpose:** distilled metadata + entity extract per YouTube video. The full
transcript stays in `_library/youtube/<channel>/<date-slug>/transcript.txt`
(verbatim layer) — this folder holds only the distilled note.

**Required frontmatter** (note-type: `youtube-note`):

```yaml
---
title: <Video title, condensed>
type: youtube-note
created: YYYY-MM-DD
uid: 01HXXXXXXXXXXXXXXXXXXXXXXXX
channel: <channel name>
published: YYYY-MM-DD                     # video publish date
url: https://www.youtube.com/watch?v=...
transcript_path: _library/youtube/<channel>/<YYYY-MM-DD>-<slug>/transcript.txt
duration_seconds: <int>
confidence: 0.0-1.0                       # distill-LLM self-rating
hype_flags: [unsupported_claim, marketing_language, overlaps_existing_tool]
tags: [youtube, <topic-1>, <topic-2>]
related: [[<MOC>]], [[<related-note>]]
status: ingested | reviewed | archived
---
```

**Subfolders:**

- `12-youtube/_queue/` — operator drops one URL per file (or one URL per line in
  a single `queue.md`). `BrainOrchestrator` `youtube-ingest-drain` routine
  drains hourly. Format: filename = arbitrary, body = one URL on first line.
- `12-youtube/<channel>/` — per-channel grouping for browsability.

**Anti-pattern:** never dump the full transcript into the note body. Always
reference via `transcript_path`. See §12.

### 3.3 `13-github-repos/` — One note per repo

**Purpose:** distilled metadata + relevance/risk scoring per interesting GitHub
repository discovered by Module F (or dropped manually).

**Required frontmatter** (note-type: `github-repo-note`):

```yaml
---
title: <owner>/<repo>
type: github-repo-note
created: YYYY-MM-DD
uid: 01HXXXXXXXXXXXXXXXXXXXXXXXX
repo: <owner>/<repo>
url: https://github.com/<owner>/<repo>
stars: <int>
license: MIT | Apache-2.0 | GPL-3.0 | Other | None
last_commit: YYYY-MM-DD
language_primary: <language>
relevance_score: 0.0-1.0                  # heuristic + LLM scoring
risk_score: 0.0-1.0                       # license + install-hook + supply-chain
tags: [github, <topic-1>, <topic-2>]
related: [[<MOC>]], [[<related-skill>]]
status: discovered | reviewed | adopted | rejected
---
```

**Subfolders:**

- `13-github-repos/_queue/` — operator drops `search:<query>` per file. The
  `github-discovery-drain` routine drains hourly.
- `13-github-repos/_blocked/` — repos blocked by license-guard or
  install-script-guard (kept for audit, never auto-extracted).

**Naming:** `<owner>-<repo>.md` lowercase, slashes replaced with hyphens
(`anthropics-claude-code.md`).

### 3.4 `08-system-architecture/` — Already exists

Created 2026-05-25 to host this very spec. Layout:

```
08-system-architecture/
  2026-05-25-brain-upgrade-plan.md         # the parent plan
  specs/                                   # specs (MEMORY, AGENT, OBSIDIAN, YOUTUBE, GITHUB, SKILL)
  eval/                                    # eval-sets (recall queries, MRR targets)
  adrs/                                    # one ADR per binding architectural decision
```

**Required frontmatter** for specs (note-type: `spec`):

```yaml
---
title: <Spec Title>
date: YYYY-MM-DD
status: v<major>.<minor> draft | active | superseded
spec_for: <Module letter + name>
author: <agent-id or operator>
related: [[<other-spec>]], ...
tags: [spec, <domain>, ...]
uid: 01HXXXXXXXXXXXXXXXXXXXXXXXX
---
```

**Required frontmatter** for ADRs (note-type: `adr`):

```yaml
---
title: ADR-NNN — <decision title>
type: adr
created: YYYY-MM-DD
uid: 01HXXXXXXXXXXXXXXXXXXXXXXXX
status: proposed | accepted | superseded
supersedes: [[ADR-NNN-...]] | null
superseded_by: [[ADR-NNN-...]] | null
tags: [adr, <domain>]
---
```

### 3.5 `09-retrospectives/` — Weekly roll-ups

**Purpose:** per-ISO-week roll-up of what happened across all panes —
handoffs landed, decisions taken, tasks completed, what slipped, surprising
findings worth distilling. Produced every Sunday 22:00 by the
`weekly-arch-review` routine (Module H) and the per-Friday operator review.

**Required frontmatter** (note-type: `retrospective`):

```yaml
---
title: <YYYY> Week <NN> retrospective
type: retrospective
created: YYYY-MM-DD                       # the Sunday the retro is written
uid: 01HXXXXXXXXXXXXXXXXXXXXXXXX
week: YYYY-WNN                            # ISO week (e.g. 2026-W22)
projects: [nexus, thesis, command-center, as, soking, personlig]
sources:                                  # what was rolled up
  handoffs: [[handoffs/<file>]], ...
  decisions: [[_decisions/<file>]], ...
  tasks_done: [<task_id>, <task_id>]
  retrospectives_previous: [[09-retrospectives/YYYY-W(NN-1)]]
surprising_findings: <int>                # count, body lists them
suggested_skills: [<skill-name>, ...]     # candidates for 03-skills/_proposed/
tags: [retrospective, weekly]
related: [[Retrospectives-MOC]]
status: draft | published
---
```

**Naming:** `YYYY-WNN.md` (ISO week), e.g. `2026-W22.md`.

### 3.6 `10-tasks/` — Workspace-wide task backlog

**Purpose:** structured task-board parsed by `BrainOrchestrator`. Replaces the
ad-hoc TODO lines scattered across `00-claude-inbox/` and
`01-CURRENT-FOCUS.md`. Every task is a markdown file with rich frontmatter so
the orchestrator can plan, lease, and verify it.

**Subfolders** (the task moves between them as state changes — this is the
single exception to "no relocation" because it is the natural lifecycle of
the artifact, not a structural reshuffle):

- `10-tasks/_open/` — claimable
- `10-tasks/_in-progress/` — leased by a pane / agent
- `10-tasks/_blocked/` — waiting on operator OK kjør or external dependency
- `10-tasks/_done/` — completed, kept for retrospective + skill-extraction

**Required frontmatter** (note-type: `task`):

```yaml
---
title: <Short, imperative task title>
type: task
created: YYYY-MM-DD
uid: 01HXXXXXXXXXXXXXXXXXXXXXXXX
task_id: T-YYYY-MM-DD-NNN                 # human-readable, monotonic per day
owner: operator | <pane-role> | unassigned
files_allowed: [<glob-1>, <glob-2>]       # binding scope-cap
branch: <role>/<short-slug> | null
exit_criteria: <single sentence — what proves it's done>
tests: <command to run> | null
rollback: <how to revert if it goes wrong>
sla_seconds: <int>                        # 86400 = 1 day, 0 = no SLA
priority: P0 | P1 | P2 | P3
depends_on: [<task_id>, ...]
blocks: [<task_id>, ...]
project: <project-slug>
tags: [task, <domain>]
related: [[<spec-or-MOC>]]
status: open | in_progress | blocked | done | cancelled
operator_gate: true | false               # if true, requires OK kjør to start
auto_claim: true | false                  # if true, BrainOrchestrator may dispatch
---
```

**Naming:** `T-YYYY-MM-DD-NNN-<kebab-slug>.md`, e.g.
`T-2026-05-25-001-lift-firm-orchestrator.md`.

---

## 4. Frontmatter conventions (v2)

This section defines the **required minimum** and **strongly recommended**
fields per note-type. All keys are English. Content (note body) can be
Norwegian Bokmål or English per operator preference.

### 4.1 Universal required fields (all note-types)

| Key | Type | Notes |
|---|---|---|
| `tags` | list | Always present. At least one tag matching the note-type. |
| `type` | enum | One of: `atomic`, `moc`, `meta`, `skill`, `spec`, `adr`, `retrospective`, `task`, `memory-object`, `youtube-note`, `github-repo-note`, `runbook`, `decision`, `handoff` |
| `created` | date | ISO `YYYY-MM-DD` |

### 4.2 Strongly recommended universal fields

| Key | Type | Notes |
|---|---|---|
| `uid` | string | UUIDv7. Optional now, becomes required if vault is ever exported. See §7. |
| `related` | list of wikilinks | At least one MOC link for non-MOC notes. See §5. |
| `status` | enum | Note-type-specific (see per-type tables in §3). |

### 4.3 Per-note-type required-field summary

| Note-type | Universal | Type-specific required keys |
|---|---|---|
| `atomic` | tags, type, created | (none beyond universal) |
| `moc` | tags, type, created | `related` (sibling MOCs) |
| `meta` | tags, type, created | (none) |
| `skill` | tags, type, created, uid | `auto_invocable`, `triggers`, `cost`, `cache_strategy`, `inputs`, `outputs`, `tools`, `status` |
| `spec` | tags, type=spec implicit via dir | `date`, `status`, `spec_for`, `author` |
| `adr` | tags, type, created, uid | `status`, `supersedes`, `superseded_by` |
| `retrospective` | tags, type, created, uid | `week`, `projects`, `sources`, `status` |
| `task` | tags, type, created, uid | `task_id`, `owner`, `files_allowed`, `exit_criteria`, `sla_seconds`, `priority`, `status` |
| `memory-object` | tags, type, created, uid | `project`, `source_type`, `exchange_core`, `specific_context`, `confidence`, `source_ref` (see [[MEMORY_DISTILLATION_SPEC]]) |
| `youtube-note` | tags, type, created, uid | `channel`, `published`, `url`, `transcript_path`, `confidence`, `hype_flags` |
| `github-repo-note` | tags, type, created, uid | `repo`, `url`, `stars`, `license`, `last_commit`, `relevance_score`, `risk_score` |
| `runbook` | tags, type, created | `trigger`, `autonomy_level` (existing convention preserved) |
| `decision` | tags, type, created | `status`, `owner`, `reviewers` (existing convention preserved) |
| `handoff` | tags, type, created | `project`, `session`, `next` (existing convention preserved) |

### 4.4 Validation rules (enforced by sanity.sh — §11)

1. Frontmatter must be the first thing in the file, opened with `---` on line 1.
2. Frontmatter must be valid YAML (parsable by `yaml.safe_load`).
3. The three universal required keys must be present and non-empty.
4. `type` must be in the enum above; unknown types fail loudly.
5. If `type` requires additional keys (per §4.3), those keys must be present.
6. `created` must match `^\d{4}-\d{2}-\d{2}$`.
7. `uid`, when present, must match the UUIDv7 regex (§7).
8. Wikilinks in `related:` must resolve (or be explicit stubs — see §5).

---

## 5. Linking rules

### 5.1 Wikilinks only

- All intra-vault links use `[[Note-Name]]` or `[[Note-Name|Display Alias]]`.
- **No markdown-style links** (`[label](path)`) inside the vault. The only
  exception is external URLs (`https://...`), which must use markdown link
  syntax to stay browsable. Internal paths never.
- This rule is enforced by sanity.sh §11 check 4.

### 5.2 Upward-link contract

Every new non-MOC note must include at least one wikilink to a relevant MOC,
either via `related:` in frontmatter or inline in the body. This keeps the
graph connected and prevents orphan notes.

For new note-types this maps to:

| Note-type | Default upward MOC |
|---|---|
| `skill` | [[Skills-MOC]] |
| `spec`, `adr` | [[System-Architecture-MOC]] |
| `retrospective` | [[Retrospectives-MOC]] |
| `task` | [[Tasks-MOC]] |
| `youtube-note` | [[Youtube-MOC]] *(create when first note lands)* |
| `github-repo-note` | [[Github-Repos-MOC]] *(create when first note lands)* |
| `memory-object` | [[Memory-MOC]] |

### 5.3 Stub-links allowed

`[[Future-Note]]` is permitted and **encouraged** as a signal that something
worth writing exists. Sanity.sh treats an unresolved wikilink as a stub if:

- The link target ends with `?` (`[[Future-Note?]]`), OR
- The link target is prefixed `STUB:` (`[[STUB:Foo]]`), OR
- The link target appears in a per-vault `.stub-allow` file at repo root.

Otherwise, unresolved wikilinks are reported as dead links by the
`dead-link-check` routine (Module H).

### 5.4 Cross-tier linking

- Skills in `03-skills/` should link to the SKILL.md sibling in
  `~/.claude/skills/<name>/SKILL.md` via a `related:` entry that uses an
  inline path comment (not a wikilink — it points outside the vault).
- Tasks should link to the spec/ADR that justifies them.
- Retrospectives should link to every handoff, decision, and task they roll up.

---

## 6. Naming conventions

### 6.1 By note-type

| Note-type | Convention | Example |
|---|---|---|
| atomic | kebab-case | `git-worktree-workflow.md` |
| moc | Title-Case with hyphens, suffix `-MOC` | `Memory-MOC.md`, `Skills-MOC.md` |
| meta | UPPER-KEBAB or Title-Case | `BRAIN-RULES.md`, `00-DASHBOARD.md` |
| spec | UPPER_SNAKE_CASE inside `specs/` | `OBSIDIAN_BRAIN_STRUCTURE.md` |
| adr | `ADR-NNN-kebab-slug.md` | `ADR-001-uuidv7-stable-ids.md` |
| retrospective | `YYYY-WNN.md` | `2026-W22.md` |
| task | `T-YYYY-MM-DD-NNN-kebab-slug.md` | `T-2026-05-25-001-lift-firm-orchestrator.md` |
| memory-object | UUIDv7 only (machine-managed) | `01HXX....md` |
| youtube-note | `YYYY-MM-DD-kebab-slug.md` under `12-youtube/<channel>/` | `2026-04-12-anthropic-deep-dive.md` |
| github-repo-note | `<owner>-<repo>.md` | `anthropics-claude-code.md` |
| handoff | `YYYY-MM-DD-kebab-slug.md` | `2026-05-13_eod_nexus.md` |
| decision | `YYYY-MM-DD-kebab-slug.md` under `_decisions/` | `2026-05-14-control-plane-proposal.md` |
| runbook | `Runbook-Title-Case.md` (existing) or `kebab-case.md` | `Runbook-Push-Cycle.md` |

### 6.2 Time-sensitive content

Anything that captures a moment (decisions, handoffs, retrospectives, daily
notes, YouTube ingests) is **date-stamped in the filename**. This is binding.

### 6.3 Stable vs. living content

- Stable atomic notes: kebab-case, no date prefix.
- Living MOCs: Title-Case, no date prefix.
- Time-sensitive: date prefix per §6.2.

---

## 7. Stable IDs (UUIDv7)

### 7.1 Rationale

Wikilinks resolve by filename. If a file is renamed, all links break unless
the operator runs find-and-replace. For long-term archive-proofing (and any
future export to a non-Obsidian system), each note benefits from a **stable,
content-independent identifier** that survives renames.

UUIDv7 is chosen because:

- It's a standard (RFC 9562) — portable to any system.
- It's monotonic by timestamp — sortable.
- It's compact (26 chars in Crockford base32, or 36 with hyphens).
- It does not require coordination — any agent can mint one safely.

### 7.2 Convention

- `uid:` in frontmatter, format Crockford base32 (`01HXX...`, 26 chars).
- **Optional now, required for new note-types** (`skill`, `spec`, `adr`,
  `task`, `memory-object`, `youtube-note`, `github-repo-note`,
  `retrospective`).
- Existing notes (atomic, moc, meta, runbook, decision, handoff) may add
  `uid:` opportunistically. Sanity.sh does not require backfill.
- UID never changes. Filename can change freely.

### 7.3 Validation regex

```
^[0-9A-HJ-KMNP-TV-Z]{26}$
```

### 7.4 Generation

`scripts/mint-uid.sh` (to be added by Module C tooling) wraps a small
Python/Node generator. Operators and agents call it; never hand-write a UUID.

### 7.5 When stable IDs become critical

- Vault export (e.g. migrating to a different knowledge base)
- Cross-system reference (command-center DB rows linking back to brain notes)
- Long-term retrospective queries ("show me everything tagged with this UID")

---

## 8. Templates

Templates live in a new folder `00-templates/` (created by Module C). One file
per note-type. Operators and agents copy these as the starting point so
frontmatter is correct on first save.

### 8.1 Template files (all under `/home/nithu/Obsidian/Brain/00-templates/`)

1. `atomic.md` — minimal atomic note
2. `moc.md` — Map-of-Content scaffold
3. `skill.md` — skill registry entry, mirrors `~/.claude/skills/<name>/SKILL.md`
4. `retrospective.md` — weekly roll-up template
5. `task.md` — workspace task with full frontmatter contract
6. `memory-object.md` — distilled MemoryObject (rarely hand-written; mostly
   machine-emitted, but template documents the schema)
7. `youtube-note.md` — distilled video note
8. `github-repo-note.md` — distilled repo note
9. `spec.md` — specification document for `08-system-architecture/specs/`
10. `adr.md` — Architectural Decision Record for `08-system-architecture/adrs/`

### 8.2 Template contract

Each template:

- Opens with the frontmatter block exactly matching §3 / §4.3 for that note-type.
- Includes commented placeholders (`<...>`) for every required key.
- Includes a short "How to use this template" section in the body, below an
  `## Overview` H2, so operators can read the template itself for guidance.
- Ends with a `## Related` section pointing back to this spec.

### 8.3 Folder structure

```
00-templates/
  README.md                 # explains the template system, points here
  atomic.md
  moc.md
  skill.md
  retrospective.md
  task.md
  memory-object.md
  youtube-note.md
  github-repo-note.md
  spec.md
  adr.md
```

`00-templates/` is **not** parsed by `BrainOrchestrator` (templates are not
real notes). Sanity.sh skips frontmatter-validation inside this folder.

---

## 9. Migration plan

**Binding constraint:** migration is **copy + tag-as-superseded**, not move.
Originals stay in place to preserve all existing wikilinks. Each migrated
copy adds frontmatter `migrated_from: [[<original-path>]]` and the original
adds `superseded_by: [[<new-path>]]`. Nothing is deleted; the originals can be
archived in 90 days via the existing 30-day-inbox archive routine extended to
also archive superseded originals after 90 days untouched.

### 9.1 Per-folder migration map

| New folder | Existing scattered content to migrate (by copy) | Routine |
|---|---|---|
| `03-skills/` | `_runbooks/Runbook-*.md` tagged as procedures (e.g. `Runbook-Push-Cycle`, `Runbook-Multi-Agent-Dispatch`, `Runbook-Karri-Proposal-Send`, `Runbook-Brain-Weekly-Maintenance`, `git-worktree-workflow`) | One-shot migration pass during Module C kickoff; afterwards new skills are born directly in `03-skills/` |
| `12-youtube/` | `_library/youtube/` placeholders (currently empty) | No content to migrate; folder bootstraps with `_queue/` + `README.md` |
| `13-github-repos/` | Inline repo references inside `_maps/Tools-MOC.md` and various `01-nexus/` notes that mention external repos | Extract one note per repo; original notes keep wikilink to new note |
| `09-retrospectives/` | `handoffs/2026-*.md` rolled up by week + `handoffs/CURRENT-HANDOFF.md` for the open week | First retro written by hand (A-10 task), subsequent retros generated by `weekly-arch-review` routine |
| `10-tasks/_open/` | TODO lines currently in `01-CURRENT-FOCUS.md` + outstanding asks in `00-claude-inbox/<project>/` | One-shot: extract each TODO into a task file; keep TODO line in source with `→ [[T-...]]` link |
| `08-system-architecture/` | Already created 2026-05-25; brain-upgrade-plan + specs/eval/adrs go here directly | No migration needed |

### 9.2 Migration anti-rules (binding)

- Do NOT move `_decisions/`, `_maps/`, `_runbooks/`, `_library/`. Even when
  content is copied into `03-skills/`, the runbook stays.
- Do NOT rewrite existing wikilinks anywhere in the vault. Only add new ones.
- Do NOT bulk-rename existing files. Use UUIDv7 (§7) if rename-proofing is
  needed.
- Do NOT delete inbox content as part of migration. The 30-day inbox archive
  routine handles that on its own cadence.

### 9.3 Verification per migration batch

After each batch of migrated notes:

1. Run `bash scripts/sanity.sh` (with §11 extensions) — must exit 0.
2. Open the new folder in Obsidian — graph view should show new notes
   connected to MOCs.
3. Search vault for the original filename — every existing wikilink to it
   must still resolve.

---

## 10. MOCs to update

### 10.1 New MOCs to write (3)

Each new MOC lives in `_maps/` and follows the existing pattern (frontmatter
`type: moc`, sibling-links via `## Related`).

**Stub status (B-2 v1.0.1):** until each MOC file lands in `_maps/`, the
wikilinks `[[Skills-MOC]]`, `[[System-Architecture-MOC]]`, `[[Tasks-MOC]]`,
`[[Retrospectives-MOC]]`, `[[Youtube-MOC]]`, `[[Github-Repos-MOC]]`, and
`[[Memory-MOC]]` (existing) are expected unresolved targets. Add each name to
the vault-root `.stub-allow` file per §5.3 contract so sanity.sh §11.2
dead-link-check does not flag them. Drop the entry as each MOC is written.

1. **`_maps/Skills-MOC.md`** — index of all skills in `03-skills/`, grouped by
   `auto_invocable` vs. operator-only, with cost tier annotations. Linked
   from [[Tools-MOC]] and [[Workflows-MOC]].

2. **`_maps/System-Architecture-MOC.md`** — index of every spec in
   `08-system-architecture/specs/`, every ADR in `adrs/`, every eval-set in
   `eval/`. Linked from [[Decisions-MOC]] under a new "Architecture specs"
   section.

3. **`_maps/Tasks-MOC.md`** — live view of `10-tasks/`. Sections: Open,
   In-progress, Blocked, Done-this-week. Generated/updated by a small
   `scripts/tasks_moc_render.py` helper called by the weekly retrospective
   routine. Linked from [[00-DASHBOARD]] under a new "Workspace tasks"
   section.

### 10.2 Optional MOCs (created when first note lands)

4. **`_maps/Retrospectives-MOC.md`** — index of all weekly retros. Created
   when `2026-W21.md` lands.
5. **`_maps/Youtube-MOC.md`** — index of all ingested videos, grouped by
   channel + tag. Created when first video lands.
6. **`_maps/Github-Repos-MOC.md`** — index of all discovered repos, grouped
   by `status` (discovered / reviewed / adopted / rejected). Created when
   first repo lands.

### 10.3 Existing MOCs to extend (additive)

- `_maps/Decisions-MOC.md` — add "Architecture specs (2026-05-25)" section
  pointing at `08-system-architecture/specs/` and the new
  `System-Architecture-MOC`.
- `_maps/Memory-MOC.md` — add "MemoryObject layer (Module B)" section
  pointing at [[MEMORY_DISTILLATION_SPEC]].
- `_maps/Workflows-MOC.md` — add entries for new background routines from
  Module H (nightly-distill, dead-link-check, stale-task-detect,
  weekly-arch-review).
- `_maps/Tools-MOC.md` — add `[[Skills-MOC]]` cross-link.
- `00-DASHBOARD.md` — add a "Workspace tasks" section linking
  `[[Tasks-MOC]]`. **Operator-owned file** — change requires OK kjør per
  [[BRAIN-RULES]].

---

## 11. Sanity checks (extensions to `scripts/sanity.sh`)

The existing `scripts/sanity.sh` runs 8 sections. This spec adds 4 new
sections, all bash-implementable, all run after the existing 8.

### 11.1 Section 9 — Frontmatter validity

For every `.md` file under the vault (excluding `90-archive/` and
`00-templates/`):

1. Open the file. The first non-blank line must be `---`.
2. Capture the YAML block until the closing `---`.
3. Parse with `python3 -c "import yaml, sys; yaml.safe_load(sys.stdin)"`.
4. Assert the three universal required keys (`tags`, `type`, `created`) are
   present and non-empty.
5. Assert `type` is in the enum (§4.3).
6. Assert `created` matches `^\d{4}-\d{2}-\d{2}$`.
7. If `type` triggers additional required keys (per §4.3), assert those too.

**Implementation sketch:**

```bash
header "Frontmatter validity"
python3 scripts/check_frontmatter.py \
    --exclude '90-archive/' --exclude '00-templates/' --exclude 'scripts/' \
    --enum-types 'atomic,moc,meta,skill,spec,adr,retrospective,task,memory-object,youtube-note,github-repo-note,runbook,decision,handoff'
```

`scripts/check_frontmatter.py` is a new helper (Module C will add it). It
walks `.md` files, calls `yaml.safe_load`, applies the per-type rules from a
small spec-table, and exits non-zero on any failure.

### 11.2 Section 10 — Wikilink resolution

For every `[[...]]` in every tracked `.md`:

1. Strip alias suffix (`|...`).
2. Resolve to a `.md` file anywhere in the vault (Obsidian's link resolution
   is filename-based, ignoring folders).
3. If unresolved, check stub markers (`?` suffix, `STUB:` prefix, or entry in
   `.stub-allow`). If a stub, pass. Otherwise, fail with the offending file +
   line number.

**Implementation sketch:**

```bash
header "Wikilink resolution"
python3 scripts/check_wikilinks.py --stub-allow .stub-allow
```

### 11.3 Section 11 — No markdown-style links inside vault

Grep for `\]\(` in tracked `.md` files. Filter out external URLs (line
contains `http://` or `https://` after the `]`). Anything left is a forbidden
internal markdown link.

**Implementation sketch:**

```bash
header "No markdown-style internal links"
HITS="$(git ls-files -z '*.md' \
    | xargs -0 grep -nE '\]\([^h)][^)]*\)' \
    | grep -v 'http://' | grep -v 'https://' \
    || true)"
if [ -z "$HITS" ]; then
    note_pass "no markdown-style internal links found"
else
    note_fail "markdown-style internal links found (use [[wikilinks]]):"
    printf '%s\n' "$HITS" | sed 's/^/    /'
fi
```

### 11.4 Section 12 — Required folders present

After this spec lands, the vault must contain all 6 new folders + the
template folder. Sanity.sh asserts presence:

```bash
header "Required folders present (post-Module-C)"
REQUIRED_DIRS=(
    "03-skills"
    "12-youtube"
    "13-github-repos"
    "08-system-architecture"
    "09-retrospectives"
    "10-tasks"
    "00-templates"
)
missing=0
for d in "${REQUIRED_DIRS[@]}"; do
    if ! test -d "$d"; then
        note_fail "missing directory: $d"
        missing=$((missing+1))
    fi
done
[ "$missing" -eq 0 ] && note_pass "all 7 required folders present"
```

### 11.5 Section 13 — Task state machine integrity

For every file under `10-tasks/`:

1. Extract frontmatter `status:`.
2. Assert the file lives in the subfolder matching its status:
   - `status: open` → `_open/`
   - `status: in_progress` → `_in-progress/`
   - `status: blocked` → `_blocked/`
   - `status: done` → `_done/`
   - `status: cancelled` → `_done/` (treated as terminal)
3. Assert `task_id` matches the filename prefix.
4. Assert `files_allowed`, `exit_criteria`, and `priority` are present.

This catches the most common drift (operator manually edited status without
moving the file).

### 11.6 Failure behavior

All four new sections follow the existing sanity.sh pattern: collect failures,
print a summary, exit non-zero if any failed. No silent passes.

---

## 12. Anti-patterns (binding)

### 12.1 Structural

- **Never relocate** `_decisions/`, `_maps/`, `_runbooks/`, `_library/`,
  `claude-context/`, `00-claude-inbox/`, `00-firm-bus/`, or any
  `0N-<project>/` folder. They are load-bearing wikilink anchors.
- **Never delete files.** Use `90-archive/` for cold storage. Sanity.sh does
  not enforce this directly, but path-guard CI will reject any deletion in
  protected paths.
- **Never bulk-rename existing notes** to fit new conventions. Use UUIDv7
  for rename-proofing instead.
- **Clarification (B-2 v1.0.1):** renaming **new** folders during the initial
  design phase, before they contain shipped content, is allowed (e.g. the
  2026-05-25 B-1 rename of `06-youtube/` → `12-youtube/` and
  `07-github-repos/` → `13-github-repos/`, executed before any notes landed).
  Once a folder holds operator-authored content with inbound wikilinks, it
  becomes load-bearing and the anti-rename rule applies.

### 12.2 Linking

- **Never use markdown-style internal links** (`[label](path)`). Sanity.sh
  §11.3 will fail the push. Wikilinks only.
- **Never link across vault and external repo** with a single syntax. Inline
  paths to external files belong in code-block comments or a `path:` key in
  frontmatter, not in a wikilink.

### 12.3 Frontmatter

- **Never invent new top-level keys** without updating §4.3. Agents should
  fail loudly if they need a key not yet specified, not silently add one.
- **Never store secrets, tokens, API keys, or `.env` values** in
  frontmatter. Per [[BRAIN-RULES]] §Secrets.

### 12.4 Content

- **Never dump full YouTube transcripts** into `12-youtube/` notes. Store
  verbatim in `_library/youtube/<channel>/<slug>/transcript.txt` and
  reference via `transcript_path:`.
- **Never store full README/source dumps** in `13-github-repos/` notes.
  Distilled summary + key facts only. Verbatim stays in `_library/github/`
  if needed.
- **Never auto-promote** machine-generated notes to non-`_proposed/` or
  non-`_queue/` locations without operator review. Auto-skills land in
  `03-skills/_proposed/`, auto-tasks land in `10-tasks/_open/` only if
  `operator_gate: false`.

### 12.5 Automation

- **Never auto-disable** any check or gate based on noisy failures. Per
  [[STUB:Operator-Principles]] rule 1 (file pending — sanity.sh §11.2 treats
  `STUB:` prefix as an allowed unresolved-wikilink per §5.3).
- **Never run discovery scripts that clone and execute** external code.
  Module F (GitHub discovery) is metadata-only.
- **Never push** without explicit operator OK kjør. Per [[BRAIN-RULES]] and
  CLAUDE.md.

---

## 13. Cross-refs

- [[2026-05-25-brain-upgrade-plan]] — the parent plan; this spec is Module C
- [[SKILL_REGISTRY_SPEC]] — defines the 3-tier skill discovery + `03-skills/`
  contract referenced in §3.1
- [[MEMORY_DISTILLATION_SPEC]] — defines MemoryObject schema referenced in
  §3 (memory-object) and §4.3
- [[AGENT_ORCHESTRATION_SPEC]] — defines task lifecycle + lease protocol that
  `10-tasks/` (§3.6) implements the storage layer for
- [[YOUTUBE_INGESTION_SPEC]] — defines the ingest pipeline that writes to
  `12-youtube/` per §3.2
- [[GITHUB_DISCOVERY_SPEC]] — defines the discovery pipeline that writes to
  `13-github-repos/` per §3.3
- [[BRAIN-RULES]] — existing operating rules; this spec extends them
  additively, never overrides
- [[Memory-MOC]] · [[Decisions-MOC]] · [[Workflows-MOC]] · [[Tools-MOC]] —
  MOCs that will gain a cross-link to the new `Skills-MOC`,
  `System-Architecture-MOC`, and `Tasks-MOC` per §10.3
- [[STUB:Operator-Principles]] — the bedrock six rules referenced in §12.5
  (stub-marker per §5.3; file to be created — tracked as B-2 follow-up)
- Cross-module e2e integration suite (planned per INTEGRATION_NOTES v1.1 H.2)
  — lives at `command-center/packages/brain-orchestrator/tests/integration/`
  and asserts the full operator-drop → ingest → distill → RAG-retrieve loop
  against the folder taxonomy this spec defines.

---

## 14. Verify checklist (5× per operator §11 policy)

Per [[2026-05-25-brain-upgrade-plan]] §11 verifiserings-policy for
markdown-deliverables:

1. **Read-back** — all 13 required sections present: ✅
   Overview, Current taxonomy, NEW folders, Frontmatter v2, Linking,
   Naming, Stable IDs, Templates, Migration, MOCs, Sanity, Anti-patterns,
   Cross-refs.
2. **Cross-link validation** — all `[[wikilinks]]` either point at existing
   notes ([[2026-05-25-brain-upgrade-plan]], [[BRAIN-RULES]],
   [[STUB:Operator-Principles]] *(v1.0.1: stub-marked per §5.3 pending file
   creation)*, [[Memory-MOC]], [[Decisions-MOC]],
   [[Workflows-MOC]], [[Tools-MOC]], [[00-DASHBOARD]]) or are explicit
   sibling-spec stubs to be created by parallel agents A-1 through A-6
   ([[SKILL_REGISTRY_SPEC]], [[MEMORY_DISTILLATION_SPEC]],
   [[AGENT_ORCHESTRATION_SPEC]], [[YOUTUBE_INGESTION_SPEC]],
   [[GITHUB_DISCOVERY_SPEC]]) or new MOCs to be written per §10
   ([[Skills-MOC]], [[System-Architecture-MOC]], [[Tasks-MOC]],
   [[Retrospectives-MOC]], [[Youtube-MOC]], [[Github-Repos-MOC]]): ✅
3. **Frontmatter YAML syntax** — frontmatter block at top of file uses
   valid YAML, three required keys plus spec-specific keys: ✅
4. **Factual claims cross-checked** — vault folder list pulled from live
   `ls` of `/home/nithu/Obsidian/Brain/`; existing sanity.sh sections
   verified by reading `scripts/sanity.sh`; frontmatter conventions cross-checked
   against [[BRAIN-RULES]] §Link convention and existing
   `_decisions/2026-05-14-control-plane-proposal.md` frontmatter: ✅
5. **Scope-cap respected** — all proposals are additive; no existing folder
   is touched; no existing file is renamed; templates folder is the only
   write outside `08-system-architecture/`: ✅

**Verify checklist matches the 5 operator-stated requirements** for this
spec:

- [x] All 6 new folders specified with required frontmatter (§3.1–§3.6)
- [x] Template specifications complete (one per note-type, §8)
- [x] Migration plan doesn't violate "no relocation" (§9.2 binding rules)
- [x] Anti-patterns explicit (§12, 5 sub-sections)
- [x] Sanity-check additions are bash-implementable (§11, 4 new sections
  with implementation sketches)

---

## Changelog
- 2026-05-25 v1.0.2 — frontmatter YAML fix (block-list form): converted inline `related: [[X]], [[Y]]` flow-list to block-list with quoted wikilink strings; converted inline `tags: [...]` flow-list to block-list. Body untouched.
- 2026-05-25 v1.0.1 — applied B-2 MEDIUM fixes:
  - I.5: §12.1 clarified that renaming NEW folders pre-content is allowed; cites the B-1 `06-youtube`→`12-youtube` / `07-github-repos`→`13-github-repos` precedent.
  - B.3: §12.5 + §13 `[[Operator-Principles]]` rewritten as `[[STUB:Operator-Principles]]` per §5.3 stub-marker convention so sanity.sh §11.2 does not flag it; B-2 follow-up to create the actual file.
  - B.2: §10.1 added a "Stub status" note enumerating the 7 expected unresolved MOC wikilinks and instructing addition to vault-root `.stub-allow` until each MOC lands.
  - H.2: §13 cross-refs gained a pointer to the planned `command-center/packages/brain-orchestrator/tests/integration/` cross-module e2e suite.

---

*Sist oppdatert: 2026-05-25 av A-3 (v1.0); v1.0.1 B-2 MEDIUM pass av C-agent.
Additive only. Awaits operator OK kjør on G1 (folder creation) per
brain-upgrade-plan §6.*
