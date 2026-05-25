---
title: Skill Registry Spec
date: 2026-05-25
status: v1.0.2
spec_for: Module D (Skill Registry) — brain-upgrade-plan
author: A-6 (sub-agent)
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[AGENT_ORCHESTRATION_SPEC]]"
tags:
  - spec
  - skills
  - registry
  - hermes
  - auto-creation
---

# Skill Registry Spec

> Module D of the workspace-wide brain upgrade. Three-tier registry that makes skills **discoverable**, **invocable** (manual + auto), and **auto-creatable** from successful task patterns (Hermes-style). Operator-review-required for every auto-promotion — no autonomy escape.

---

## 1. Overview

The skill registry is the workspace's index of reusable procedures. Today the only first-class skill is `~/.claude/skills/trading-knowledge/SKILL.md`. Everything else lives as implicit knowledge in `_runbooks/`, scattered scripts in `command-center/_bin/`, or operator muscle-memory. The registry promotes those to first-class, callable artifacts with structured frontmatter, discovery, and an audit-trail for invocations.

**Purpose:**
- **Discoverable** — every skill is indexed by `name`, `description`, `when_to_use`, and tier; reachable from CLI, web UI, and `BrainOrchestrator`.
- **Invocable** — operator can `/skill <name>` from any pane; `BrainOrchestrator` can publish `agent_tasks(role: skill-runner, payload: { skill: <name>, args, invoker })` (see §6.1).
- **Auto-creatable** — task completions flagged `surprising_finding:true` propose new SKILL.md drafts into `03-skills/_proposed/`; operator manually promotes.
- **Three-tier** — workspace-wide, project-local, brain-reference. Project wins over workspace on name conflict.

**Non-goals:**
- Not a code-execution sandbox. Skills describe procedures + commands; the harness (Claude Code) or `BrainOrchestrator` runs them.
- Not a replacement for system skills (verify/code-review/loop/etc.). System skills stay read-only references.
- Not a money-impact autopilot. Risk-bearing skills (trades, deploys, secrets) are documentation-only; operator runs the commands.

---

## 2. Three-tier hierarchy

| Tier | Path | Loaded when | Use case |
|---|---|---|---|
| **Tier 1: workspace** | `~/.claude/skills/<name>/SKILL.md` | Every Claude Code session, every pane | Cross-project skills (e.g. `multi-agent-dispatch`, `verify-claim`, `update-config`) |
| **Tier 2: project** | `<repo>/.claude/skills/<name>/SKILL.md` | Claude Code session when `pwd` is inside `<repo>` | Project-local skills (e.g. `nexus-deploy-check`, `thesis-render-pdf`, `as-fakturasvar`) |
| **Tier 3: brain** | `~/Obsidian/Brain/03-skills/<name>.md` | Indexed by `BrainOrchestrator`; auto-invocable if frontmatter `auto_invocable: true` | Operator-reference + automatable workflows (e.g. `brain-distill-daily`, `youtube-ingest`, `github-discover`) |

**Conflict rule (binding):** if the same `name` exists in multiple tiers, **project wins over workspace wins over brain**. The registry logs the conflict and surfaces it in `/brain skills list --conflicts`. Never silently shadow.

**Tier boundaries (binding):**
- Tier 1 and Tier 2 use the `<name>/SKILL.md` directory convention (matches existing `~/.claude/skills/trading-knowledge/SKILL.md`). Allows companion files (`README.md`, `examples/`, fixtures).
- Tier 3 uses a flat `<name>.md` (no subdirectory). Operator browses these in Obsidian like any other note. Wikilinks resolve cleanly.
- `auto_invocable: true` is **only valid for Tier 3**. Tier 1/2 are session-context (Claude reads them); Tier 3 can be triggered by `BrainOrchestrator` without an active Claude session.

---

## 3. SKILL.md schema (frontmatter)

All three tiers share the same frontmatter schema. YAML, parsed strictly.

```yaml
---
name: brain-distill-daily              # kebab-case, unique within tier, [a-z0-9-]+
description: Nightly run distilling yesterday's command-center actions + Claude conversations into MemoryObjects.
tier: workspace | project | brain
project_scope: ai-assistent/**         # required iff tier=project (glob relative to /home/nithu/code); may be literal sentinel "workspace" when tier=brain to mark workspace-wide applicability
when_to_use: |
  Trigger keywords: distill, recall, memory.
  Trigger contexts: nightly cron (03:00 local), manual /skill brain-distill-daily.
  Anti-patterns: never invoke during active trading session, never on 00-firm-bus/feed.md (low-signal).
inputs:                                # array-of-objects (one entry per arg)
  - name: date
    type: string                       # string|bool|number|url|array|object
    required: true
    default: yesterday                 # omit if required:true with no default
  - name: dry_run
    type: bool
    required: false
    default: false
outputs:                               # array-of-single-key-objects (return-shape contract)
  - count_new_objects: number
  - count_promoted_to_brain: number
  - errors: array
harness_tools:                         # Claude Code built-in tools the harness must grant (Bash, Read, Write, Edit, Grep, etc.)
  - Bash
  - Read
  - Write
system_tools:                          # external packages / CLIs / services the skill invokes
  - "@cc/memory-engine"
  - sqlite-fts5
cost_estimate: low | medium | high     # low=<$0.05, medium=$0.05-$0.50, high=>$0.50 per invocation
cache_strategy: ephemeral | persistent | none
auto_invocable: false                  # only valid for tier=brain; default false
created: 2026-05-25T14:00:00Z          # ISO 8601 UTC
created_by: operator                    # operator | auto-extracted-from-task-<id>
confidence: 0.85                       # 0.0-1.0
validation_passes: 0                   # int; incremented on success, see §6
version: 0.1.0                         # semver; optional, defaults to 0.1.0; required on new skills going forward (see §8.2)
---
```

**Field reference:**

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | kebab-case string | yes | Must match `^[a-z][a-z0-9-]{2,49}$`. Globally unique within its tier. |
| `description` | one-line string | yes | Specific enough for the ranker — answer "when would Claude invoke this?" |
| `tier` | enum | yes | `workspace` \| `project` \| `brain`. Must match physical path. |
| `project_scope` | glob \| sentinel | iff tier=project | Relative to `/home/nithu/code`. Validated at index time. **Sentinel exception:** literal value `workspace` is allowed when `tier=brain` to mark the skill as workspace-wide applicable (does NOT scope to a single repo). Validator accepts globs (tier=project) OR `workspace` (tier=brain) OR absent (tier=workspace). |
| `when_to_use` | multi-line string | yes | Keywords + contexts + anti-patterns. Drives ranker + operator UI. |
| `inputs` | array-of-objects | yes | Arg schema as an ordered list. Each entry: `{ name: string, type: string\|bool\|number\|url\|array\|object, required: bool, default?: any, notes?: string }`. Empty `[]` if no args. See TS interface §4. |
| `outputs` | array-of-objects | yes | Return shape as an ordered list of single-key objects: `[{ field_name: type-name }, ...]`. Type-names: `number`, `string`, `bool`, `array`, `object`. Empty `[]` if side-effects only. |
| `harness_tools` | string[] | yes | Claude Code built-in tools the harness must grant (e.g. `Bash`, `Read`, `Write`, `Edit`, `Grep`). Validated at invocation time against the harness's available tool list (§11). |
| `system_tools` | string[] | yes | External packages / CLIs / services the skill calls (e.g. `@cc/memory-engine`, `sqlite-fts5`, `yt-dlp`, `gh`). Validated at invocation time for presence on `$PATH` or in `package.json` workspace (§11). Empty `[]` if the skill only uses harness tools. |
| `cost_estimate` | enum | yes | `low` \| `medium` \| `high`. Surfaced in operator UI before run. |
| `cache_strategy` | enum | yes | `ephemeral` (per-invocation) \| `persistent` (across invocations) \| `none`. |
| `auto_invocable` | bool | brain only | `true` means BrainOrchestrator can trigger without operator. |
| `created` | ISO 8601 UTC | yes | Immutable; never updated post-creation. |
| `created_by` | string | yes | `operator` \| `auto-extracted-from-task-<id>`. |
| `confidence` | float 0.0–1.0 | yes | Updated by §6 invocation outcomes. |
| `validation_passes` | int | yes | Incremented on each successful invocation. |
| `version` | semver string | recommended | Defaults to `0.1.0` if absent (back-compat). Required on all new skills going forward. Bumped per §8.2 rules. |

**Validation (at index-build time):**
- Unknown frontmatter keys → warning, not error (forward-compatible).
- Missing required field → skill skipped, logged to `skill-registry.log`.
- Invalid `tier` ↔ path mismatch (e.g. `tier: brain` in `~/.claude/skills/`) → skill skipped, error.
- `auto_invocable: true` outside `tier: brain` → skill skipped, error.
- `cost_estimate: high` + `auto_invocable: true` → warning surfaced in operator UI; not blocked.
- `inputs` not an array → skill skipped, error (`expected array-of-objects, got <type>`).
- `outputs` not an array → skill skipped, error (`expected array-of-single-key-objects, got <type>`).
- `inputs[].name` collision (duplicate arg names) → skill skipped, error.
- `project_scope` present + `tier=workspace` → warning (ignored field).
- `project_scope: workspace` + `tier=project` → skill skipped, error (sentinel only valid for tier=brain).
- `harness_tools` references a non-existent Claude tool → warning (forward-compatible against new harness tools).
- `system_tools` reference fails presence check at invocation time → invocation blocked per §11 (not at index time, since `$PATH` can drift).

---

## 4. SKILL.md body template

After the frontmatter, the body follows this fixed-order template. Sections may be empty but must be present (parser checks).

```markdown
## Purpose

One paragraph: what this skill achieves, and why it exists. Reference the user/business problem.

## When to use

Explicit triggers (keywords, file patterns, time-of-day, upstream events).
Explicit anti-patterns (when NOT to use, even if it looks like a match).

## Inputs

Human-readable table mirroring the frontmatter `inputs:` array (one row per arg). Body table is documentation; frontmatter is the contract.

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `date` | string (YYYY-MM-DD) | yes | — | Operator timezone |
| `dry_run` | bool | no | false | Count without persisting |

Optional TypeScript interface (for skills with non-trivial input shapes; not required):

​```ts
interface BrainDistillDailyInputs {
  date: string;          // YYYY-MM-DD
  dry_run?: boolean;     // default false
}
​```

## Steps

Numbered procedure. Each step describes a discrete operation. Include decision-points (`If X, then Y, else Z`).

1. ...
2. ...

## Tools / commands

Exact bash / tool invocations. Operator copy-pastable.

​```bash
npm -w @cc/memory-engine run distill -- --date 2026-05-24
​```

## Pitfalls

Known failure modes. Each entry: `<symptom>` → `<root cause>` → `<mitigation>`.

## Validation checks

How to verify the skill produced correct output. Each check has an explicit command + expected result.

## Example usage

One concrete invocation end-to-end. Include sample input + abbreviated output.

## Related

Wikilinks to companion skills, runbooks, decisions:
- [[MEMORY_DISTILLATION_SPEC]]
- [[Runbook-Brain-Weekly-Maintenance]]
- [[_decisions/2026-05-25-brain-upgrade]]
```

**Why fixed order:** the index-builder extracts each section by header. Re-ordering breaks ingestion. Operator can add freeform notes between sections, but the eight headers must appear in order.

---

## 5. Discovery mechanism — `packages/skill-registry`

Lives in `command-center/packages/skill-registry/`. TypeScript, ESM, `better-sqlite3` for the index cache.

**Responsibilities:**
1. Scan all three tiers on `BrainOrchestrator` startup + on inotify file-change.
2. Parse frontmatter + extract section headers from each `SKILL.md`.
3. Build an in-memory + on-disk SQLite index keyed by `name`, with tier, path, frontmatter blob, last-modified, validation-passes.
4. Expose query API (CLI, REST, in-process).
5. Detect + log conflicts (same `name` in multiple tiers).

**Scan paths (default):**
- Tier 1: `~/.claude/skills/*/SKILL.md`
- Tier 2: `/home/nithu/code/*/.claude/skills/*/SKILL.md`
- Tier 3: `~/Obsidian/Brain/03-skills/*.md` (excluding `_proposed/`, `_archived/`, `_system/`)

**Code skeleton:**

```
packages/skill-registry/
  package.json
  tsconfig.json
  src/
    index.ts                  # public API
    scan.ts                   # walk three tiers
    parse.ts                  # frontmatter + section extraction (gray-matter + remark)
    validate.ts               # schema check per §3
    store.ts                  # SQLite cache (better-sqlite3)
    conflict.ts               # tier-priority resolution + conflict log
    watcher.ts                # chokidar inotify
    api/
      routes.ts               # /api/brain/skills/* (mounted in apps/api)
    cli/
      list.ts                 # brain skills list
      show.ts                 # brain skills show <name>
      run.ts                  # brain skills run <name> <args>
      validate.ts             # brain skills validate (CI gate)
    invocation/
      run.ts                  # execute skill (per §6)
      audit.ts                # write to agent_audit on every invocation
      loop-guard.ts           # max depth 3 (per §11)
    auto-create/
      propose.ts              # Hermes-style draft from task outcome
      template.ts             # SKILL.md scaffold generator
  tests/
    scan.test.ts
    parse.test.ts
    validate.test.ts
    conflict.test.ts
    invocation.test.ts
    auto-create.test.ts
  fixtures/
    valid-workspace-skill/
    valid-project-skill/
    valid-brain-skill/
    invalid-tier-mismatch/
    conflict-same-name/
```

**REST API (mounted under `apps/api/src/routes/brain.ts`):**

| Method | Path | Returns |
|---|---|---|
| GET | `/api/brain/skills` | All skills, grouped by tier; query params: `?tier=`, `?search=`, `?auto_invocable=` |
| GET | `/api/brain/skills/:name` | Single skill: frontmatter + body sections + invocation history |
| GET | `/api/brain/skills/:name/runs` | Recent invocation audit entries |
| POST | `/api/brain/skills/:name/invoke` | Invoke skill with body args; returns task_id (async) |
| POST | `/api/brain/skills/reindex` | Force re-scan (operator-only) |
| GET | `/api/brain/skills/conflicts` | List of name-collisions across tiers |

**CLI:**

```bash
brain skills list                                 # all, grouped by tier
brain skills list --tier=brain --auto-invocable   # filtered
brain skills show brain-distill-daily             # full SKILL.md + run history
brain skills run brain-distill-daily date=2026-05-24
brain skills validate                             # CI gate; exits non-zero on broken skill
brain skills conflicts                            # show collisions
```

---

## 6. Invocation protocol

Two paths, same audit trail.

### 6.1 Manual invocation

Operator types `/skill <name> <args>` in a Claude Code pane.

1. Pane intercepts `/skill` → calls `POST /api/brain/skills/:name/invoke` (over local HTTP to `apps/api`).
2. Registry validates `tools_required` are present (per §11).
3. Registry inserts `agent_tasks` row with `role: skill-runner`, `payload: { skill: <name>, args, invoker: operator }`.
4. `BrainOrchestrator` claims the task in next tick, runs `Steps` from SKILL.md body via the appropriate engine (Claude Code session or direct command runner).
5. Result written to `agent_results` + audit entry in `agent_audit`.
6. Pane polls task status, surfaces output.

### 6.2 Auto invocation (Tier 3 only, `auto_invocable: true`)

Triggered by `BrainOrchestrator` from §H routines in brain-upgrade-plan (`nightly-memory-distill`, `youtube-ingest-drain`, etc.).

1. Trigger publishes `agent_tasks(role: skill-runner, payload: { skill: <name>, args, invoker: BrainOrchestrator, trigger: <trigger_name> })`.
2. Same execution + audit path as manual.
3. `cost_estimate: high` auto-invocations also publish a notification to `00-firm-bus/feed.md` so operator can intervene.

**Trigger registration bridge (skill → AGENT_ORCHESTRATION_SPEC §8):**

`auto_invocable: true` is a declarative flag — the registry alone does NOT schedule the skill. The bridge into `BrainOrchestrator`'s trigger registry works as follows:

1. At registry scan time (§5), every Tier 3 skill with `auto_invocable: true` is collected into a `SkillTrigger[]` list.
2. The skill's frontmatter MUST also declare HOW it gets triggered, via a sibling `trigger_binding:` field with one of two shapes:
   - **Cycle-bound** (cron-style): `trigger_binding: { kind: "cycle", expr: "cycleNo % 720 === 0", description: "hourly at idle cadence" }` — registered into `BrainOrchestrator` as a built-in trigger that calls `enqueue(role: skill-runner, payload: { skill: <name>, ... })`.
   - **Event-bound** (post-hook): `trigger_binding: { kind: "event", on: "agent_audit.insert", filter: "outcome=success && surprising_finding=true" }` — registered into the event-listener interface added per INTEGRATION_NOTES C.6 (`Trigger.onEvent(ctx, event)`).
3. On `BrainOrchestrator` startup, the registry calls `orchestrator.registerSkillTriggers(skillTriggers)` which merges them into the built-in trigger table (§8.1 of AGENT_ORCHESTRATION_SPEC).
4. If `trigger_binding` is absent from an `auto_invocable: true` skill → validator errors at index time (skill skipped).
5. `BrainOrchestrator` owns scheduling + dispatch; registry owns the binding declarations. No double-execution path.

**Note for the 5 ship-day skills (§9):** `brain-distill-daily`, `youtube-ingest`, and `github-discover` all want `auto_invocable: true` in their final state. Until A-9's files add the `trigger_binding:` field, the registry treats them as manual-only (matching their current `auto_invocable: false`). Promotion to auto-invocation requires operator-edit to add the binding.

### 6.3 Validation tracking

Every invocation updates the skill's frontmatter via the registry:

- **Success** → `validation_passes += 1`; `confidence = min(1.0, confidence + 0.02)` (capped).
- **Failure** → `validation_passes` unchanged; `confidence = max(0.0, confidence - 0.05)` (floored).
- **Repeated failure** (`confidence < 0.3`) → `BrainOrchestrator` publishes `agent_tasks(role: review, payload: { skill: <name>, reason: low-confidence })` for operator review; skill is **not** auto-disabled (per CLAUDE.md "no auto-disable").

Frontmatter updates go through `validate.ts` first; if the file has drifted (operator edited mid-flight), the update is skipped and a conflict logged.

### 6.4 Audit shape

Every invocation writes one row to `agent_audit`:

```ts
interface SkillAuditEntry {
  task_id: string;
  skill_name: string;
  skill_tier: 'workspace' | 'project' | 'brain';
  skill_version: string;          // from frontmatter, see §8
  invoker: 'operator' | 'BrainOrchestrator' | `auto-extracted-from-task-${string}`;
  trigger?: string;               // for auto-invocation, the routine name
  args: Record<string, unknown>;
  started_at: string;             // ISO
  finished_at?: string;
  outcome: 'success' | 'failure' | 'timeout' | 'blocked';
  outputs?: Record<string, unknown>;
  error?: string;
  depth: number;                  // invocation depth, see §11
}
```

---

## 7. Auto-skill-creation (Hermes-style)

The headline feature: when a task succeeds in a way that surprises the LLM, the system proposes a new skill capturing the pattern. Operator-review-required before promotion. No exceptions.

### 7.1 Trigger criteria

All three conditions must hold:

1. **Task completed** with `outcome: success` in `agent_audit`.
2. **Surprising finding flag** — the executing LLM, in its task-completion report, set `surprising_finding: true` (a structured boolean in the result schema). This means: the path-to-success was non-obvious; future similar tasks would benefit from this procedure.
3. **No existing skill matches** — the auto-create pipeline runs `brain skills list --search=<task-keywords>`; if any existing skill's `when_to_use` or `description` substring-matches the task summary, the auto-create is **skipped** (operator gets a "consider extending [[existing-skill]]" suggestion instead).

### 7.2 Pipeline

1. `BrainOrchestrator` post-task hook detects the three conditions.
2. Dispatches a `role: skill-extractor` sub-task to Claude (Haiku or Sonnet, never Opus — cost discipline).
3. Sub-task receives: task description, `agent_audit` trace, `agent_results` output, files touched.
4. Sub-task emits a SKILL.md draft using the §4 template, with frontmatter populated:
   - `name`: kebab-cased summary of the task
   - `description`: one-line from task summary
   - `tier`: defaults to `brain` (most flexible — operator can move to Tier 1/2 on promotion)
   - `when_to_use`: keywords from task description + audit trace
   - `inputs`: array-of-objects (§3 schema) inferred from task payload — one entry per input arg observed in the audit trace, with `name`, `type`, `required: false` (auto-extracted defaults to optional), inferred `default` if a constant appears
   - `outputs`: array-of-single-key-objects (§3 schema) inferred from result shape
   - `harness_tools`: Claude tools actually invoked during execution (from audit trace — typically a subset of `Bash`, `Read`, `Write`, `Edit`, `Grep`)
   - `system_tools`: external packages / CLIs actually called (from audit trace tool-use entries)
   - `cost_estimate`: derived from token usage in audit trace
   - `cache_strategy`: `ephemeral` (safe default)
   - `auto_invocable`: `false` (always — operator must explicitly flip and add `trigger_binding:` per §6.2)
   - `created_by`: `auto-extracted-from-task-<task_id>`
   - `confidence`: `0.3` (starts low; promotion path raises it)
   - `validation_passes`: `0`
   - `version`: `0.1.0`
5. Draft written to `~/Obsidian/Brain/03-skills/_proposed/<name>.md`.
6. Notification published to `00-firm-bus/feed.md`: `proposed skill: <name> (from T-<id>). Review at 03-skills/_proposed/<name>.md.`

### 7.3 Promotion mechanism (operator-only)

No automatic promotion ever. Operator's flow:

1. Operator opens `~/Obsidian/Brain/03-skills/_proposed/<name>.md` in Obsidian.
2. Edits the draft (tighten `description`, fix `when_to_use`, vet `tools_required`).
3. Moves the file:
   - Stay in brain: `mv _proposed/<name>.md ../  ` → promoted to Tier 3, registry picks it up on next scan.
   - Promote to workspace: `mv _proposed/<name>.md ~/.claude/skills/<name>/SKILL.md` (operator creates the directory).
   - Promote to project: `mv _proposed/<name>.md /home/nithu/code/<repo>/.claude/skills/<name>/SKILL.md`.
4. Operator must update `tier:` frontmatter to match new location (`brain` → `workspace` or `project`); `brain skills validate` catches mismatches.
5. Registry inotify-watcher detects the move, re-validates, surfaces in `/api/brain/skills`.

**Reject path:** operator moves the file to `~/Obsidian/Brain/03-skills/_rejected/<name>-YYYY-MM-DD.md`. The registry then suppresses re-proposal for the same `name` for 30 days (anti-spam).

### 7.4 Anti-spam guards

- Max 5 auto-proposed skills per day (registry rate-limit).
- Cooldown per `name`: rejected names suppressed 30 days; promoted names suppressed forever (already exists).
- Audit trace required: no proposal without a `task_id` back-reference.
- Operator dashboard widget (`/brain/skills/proposed`) surfaces pending review queue with age.

---

## 8. Per-skill versioning

Skills evolve. The registry tracks versions to avoid silent breakage of callers (operator memory, automation, dashboards).

### 8.1 Storage

- Tier 1 + Tier 2 skills are git-tracked in the parent repo (`.claude/skills/` lives inside the repo or in `~/.claude/` which is operator-versioned separately).
- Tier 3 skills are git-tracked in the brain repo (`tiger-brain`).

### 8.2 Version field

Frontmatter adds an optional `version: <semver>` field (defaults to `0.1.0` if absent). Schema-breaking changes (renaming/removing keys in `inputs`, changing required-ness, changing `outputs` shape) bump the **major** version. Non-breaking additions bump **minor**. Body-only edits (clearer text, fix typos) bump **patch**.

### 8.3 Major-bump archival

On a major bump, the old SKILL.md is archived **before** the new file is committed:

- Tier 1/2: copy current file to `<repo>/.claude/skills/<name>/_archived/<name>-v<N>.md` (or `~/.claude/skills/<name>/_archived/...`).
- Tier 3: copy to `~/Obsidian/Brain/03-skills/_archived/<name>-v<N>.md`.

The archived file gets `status: archived` and `archived_at: <ISO>` appended to frontmatter. The registry surfaces archived versions in `/brain skills show <name> --history`.

### 8.4 Caller migration

Major bumps emit a notification to `00-firm-bus/feed.md`: `skill <name> bumped to v<N>. Callers: <list of agent_audit entries that referenced v<N-1> in last 30d>.` Operator reviews + updates callers.

---

## 9. Default skills to ship (5 initial)

Written by A-9 in parallel per parallell-todo §4.3. All Tier 3 (`03-skills/`), `auto_invocable` per skill specifics. Names + purpose:

| Name | Tier | auto_invocable | Purpose |
|---|---|---|---|
| `brain-distill-daily` | brain | true | Nightly distill of command-center actions + Claude conversations into MemoryObjects (paper 2603.13017v1 schema). Driven by `nightly-memory-distill` routine at 03:00 local. |
| `youtube-ingest` | brain | true | Process a URL in `12-youtube/_queue/`: yt-dlp transcript → whisper fallback → distill to `12-youtube/<channel>/<date>.md`. Driven by `youtube-ingest-drain` hourly. |
| `github-discover` | brain | true | Process a `search:...` file in `13-github-repos/_queue/`: `gh search repos` → score → extract README+manifest → distill to `13-github-repos/<owner-name>.md`. Driven by `github-discovery-drain` hourly. |
| `multi-agent-dispatch` | brain | false | Manual-only. Codify the [[Runbook-Multi-Agent-Dispatch]] pattern as an invocable skill: takes task spec, fans out N agents, aggregates reports. |
| `worktree-spawn-cleanup` | brain | false | Manual-only. Wrap `firm-worktree-spawn.sh` + `firm-worktree-cleanup.sh` with structured args + audit. |

All five start with `confidence: 0.7` (hand-authored, not auto-extracted), `validation_passes: 0`. Operator-authored frontmatter `created_by: operator`.

---

## 10. System-skill integration (read-only)

The 13 system skills auto-injected per session (`trading-knowledge`, `update-config`, `verify`, `code-review`, `loop`, `schedule`, `run`, `init`, `review`, `security-review`, `claude-api`, `fewer-permission-prompts`, `keybindings-help`) are **read-only references**.

**Documentation mechanism:**
- For each system skill, create `~/Obsidian/Brain/03-skills/_system/<name>.md`.
- Frontmatter: `tier: brain`, `auto_invocable: false`, `created_by: operator`, `confidence: 1.0`, **plus** `is_system_skill: true` (registry treats as read-only).
- Body: short description, pointer to upstream definition (e.g. "defined by Claude Code harness; do not modify").
- Registry surfaces these in `/brain skills list --system` for operator browsability.
- `validation_passes` is **never incremented** for system skills (they're harness-managed, the registry has no execution authority).

**Binding constraint:** `_system/` is operator-write-only. Auto-creation never proposes into `_system/`. Registry `validate` errors if a non-`is_system_skill` skill appears in `_system/`.

---

## 11. Failure modes

| Failure | Detection | Handling |
|---|---|---|
| **Skill name conflict** (same `name` in 2+ tiers) | `conflict.ts` at scan time | Project > workspace > brain. Loser shadowed. Conflict logged + surfaced in `/api/brain/skills/conflicts`. Operator UI shows warning badge. |
| **Missing `harness_tools` or `system_tools`** | `validate.ts` at invocation time | Invocation blocked. `outcome: blocked`, `error: missing harness_tools: <list> / system_tools: <list>`. Operator notified. `harness_tools` checked against current Claude harness tool roster; `system_tools` checked against `$PATH` + workspace `package.json` deps. |
| **Invalid frontmatter** | `validate.ts` at index time | Skill skipped, logged. Doesn't crash registry. Operator notified via `/brain skills validate` CI. |
| **Tier ↔ path mismatch** (e.g. `tier: workspace` in `03-skills/`) | `validate.ts` at index time | Skill skipped, logged. |
| **`auto_invocable: true` outside Tier 3** | `validate.ts` at index time | Skill skipped, logged with explicit error. |
| **Infinite invocation loop** (skill A invokes skill B which invokes skill A...) | `loop-guard.ts` at invocation time, max depth 3 | Invocation aborted at depth 4. `outcome: blocked`, `error: max invocation depth exceeded`. Audit trace preserved for debugging. |
| **Stale skill body / drifted frontmatter** (file edited mid-invocation) | `invocation/run.ts` re-reads + re-validates before execute | Invocation aborted if frontmatter drift detected. Operator notified. |
| **Auto-create flood** (LLM flags everything as surprising) | Rate-limit: max 5 proposals/day per §7.4 | Excess proposals dropped, logged. |
| **Promotion-to-`_system/` attempt** | `validate.ts` | Rejected. `_system/` is operator-write-only. |
| **High-cost auto-invocation** (`cost_estimate: high` + `auto_invocable: true`) | Pre-flight check | Allowed but published to `00-firm-bus/feed.md` for operator visibility. |
| **Confidence below 0.3** | Per §6.3 | Review task published. Skill **not** disabled (per CLAUDE.md). |

---

## 12. Acceptance tests

All tests live in `packages/skill-registry/tests/`. CI gates on `npm -w @cc/skill-registry test`.

| # | Test | Pass criterion |
|---|---|---|
| AT-1 | Registry discovery — full workspace | After scan: index contains 5 initial + 13 system + 1 existing `trading-knowledge` = **19 total skills**. `brain skills list` returns 19 rows. |
| AT-2 | `brain-distill-daily` end-to-end | `brain skills run brain-distill-daily date=2026-05-24` exits 0. `agent_audit` has one new row with `outcome: success`. MemoryObject count > 0 in memory-engine. |
| AT-3 | Auto-creation produces valid frontmatter | Synthesize a task with `surprising_finding: true`. After hook fires, file at `03-skills/_proposed/<name>.md` exists. `brain skills validate <path>` exits 0. |
| AT-4 | Tier conflict resolution | Create same-named skill in workspace + project tiers. `brain skills list` shows project version active, workspace shadowed. `/api/brain/skills/conflicts` returns the collision. |
| AT-5 | Loop guard | Synthesize skills A→B→A. Invoke A. Invocation aborts at depth 4. `outcome: blocked`. |
| AT-6 | System skill read-only | Attempt to modify `03-skills/_system/verify.md` programmatically via registry. Registry rejects. |
| AT-7 | Auto-invocable validation | Create Tier 1 skill with `auto_invocable: true`. Validator rejects. Skill skipped from index. |
| AT-8 | Confidence updates | Invoke `brain-distill-daily` 5 times successfully. Check frontmatter: `validation_passes: 5`, `confidence` increased by ~0.10. |
| AT-9 | Major version bump archives prior | Bump `brain-distill-daily` to v1.0.0 from v0.1.0 (breaking `inputs`). Verify `_archived/brain-distill-daily-v0.md` exists with `status: archived`. |
| AT-10 | Reject path suppresses re-proposal | Move a `_proposed/foo.md` to `_rejected/foo-YYYY-MM-DD.md`. Trigger same task again. No new proposal within 30 days (mock clock in test). |

---

## 13. Code skeleton — file tree

```
command-center/
  packages/
    skill-registry/
      package.json
      tsconfig.json
      README.md
      src/
        index.ts                      # public API barrel
        types.ts                      # SkillFrontmatter, SkillRecord, ConflictEntry, etc.
        scan.ts                       # walk three tiers (tier-1, tier-2, tier-3)
        parse.ts                      # gray-matter frontmatter + remark section extraction
        validate.ts                   # §3 schema + §10 _system rules + §11 invariants
        store.ts                      # better-sqlite3 index cache
        conflict.ts                   # project > workspace > brain resolution
        watcher.ts                    # chokidar inotify on three tiers
        api/
          routes.ts                   # mounted into apps/api/src/routes/brain.ts
        cli/
          list.ts                     # brain skills list
          show.ts                     # brain skills show <name>
          run.ts                      # brain skills run <name> <args>
          validate.ts                 # brain skills validate (CI gate)
          conflicts.ts                # brain skills conflicts
        invocation/
          run.ts                      # §6 execution path
          audit.ts                    # §6.4 audit write
          loop-guard.ts               # §11 max depth 3
          confidence.ts               # §6.3 confidence updates
          frontmatter-update.ts       # safe in-place yaml mutation
        auto-create/
          propose.ts                  # §7 Hermes-style draft
          template.ts                 # §4 body scaffold
          rate-limit.ts               # §7.4 5/day cap
          dedupe.ts                   # §7.1 existing-skill match
        versioning/
          bump.ts                     # §8 semver + archival
          archive.ts                  # write _archived/<name>-v<N>.md
      tests/
        scan.test.ts
        parse.test.ts
        validate.test.ts
        conflict.test.ts
        invocation.test.ts
        auto-create.test.ts
        versioning.test.ts
        loop-guard.test.ts
      fixtures/
        valid-workspace-skill/
          SKILL.md
        valid-project-skill/
          SKILL.md
        valid-brain-skill.md
        invalid-tier-mismatch/
          SKILL.md
        conflict-same-name/
          tier-workspace/SKILL.md
          tier-project/SKILL.md
        auto-create-task-trace.json
```

**Dependencies (binding):**
- `better-sqlite3` (index cache; already in workspace)
- `gray-matter` (frontmatter parsing)
- `remark` + `remark-parse` (section extraction)
- `chokidar` (inotify watching)
- `zod` (runtime schema validation per §3)

**TS-only constraint:** per operator directive. No Python, no Bash beyond invocation glue.

---

## 14. Cross-refs

- [[2026-05-25-brain-upgrade-plan]] — parent spec, Module D source
- [[AGENT_ORCHESTRATION_SPEC]] — task lifecycle + `agent_tasks` schema this registry rides on
- [[MEMORY_DISTILLATION_SPEC]] — `brain-distill-daily` skill's execution target
- [[OBSIDIAN_BRAIN_STRUCTURE]] — `03-skills/` folder conventions
- [[YOUTUBE_INGESTION_SPEC]] — `youtube-ingest` skill backing pipeline
- [[GITHUB_DISCOVERY_SPEC]] — `github-discover` skill backing pipeline
- [[Runbook-Multi-Agent-Dispatch]] — codified by `multi-agent-dispatch` skill
- [[git-worktree-workflow]] — codified by `worktree-spawn-cleanup` skill
- [[reference_available_tools]] — operator's tool roster (per CLAUDE.md "tool-roster habit")

---

## 15. Open questions (for operator)

1. **Tier 1 skill location** — operator's `~/.claude/skills/` is operator-machine-local. For cross-machine sync (shared instance per `reference_shared_instance.md`), should Tier 1 skills sync via `tiger-brain` repo (e.g. symlink `~/.claude/skills/` → `~/Obsidian/Brain/03-skills/_workspace/`)? Defer to operator.
2. **Confidence delta tuning** — current spec uses ±0.02 / ±0.05. Re-evaluate after 30 days of real invocations.
3. **System skill `validation_passes`** — spec says never increment. Operator may want passive tracking (count invocations without affecting confidence). Defer.
4. **Auto-proposal LLM choice** — Haiku for cost, Sonnet for quality. Default Haiku; allow per-skill override?

---

*5× verify (per §11 brain-upgrade-plan):*
1. *Schema complete + valid YAML — §3 lists all fields with types, requiredness, validation rules.*
2. *Three tiers specified — §2 paths, conflict rule, tier-boundary constraints. Discovery scans listed in §5.*
3. *Auto-creation criteria concrete — §7.1 three explicit conditions (success + surprising_finding + no-match). Pipeline §7.2 step-by-step.*
4. *Invocation protocol both paths — §6.1 manual via `/skill`, §6.2 auto via BrainOrchestrator. Single audit shape §6.4.*
5. *Acceptance tests measurable — §12 lists 10 tests with explicit pass criteria (counts, exit codes, file existence). AT-1 = 19 skills exactly.*

*Sist oppdatert: 2026-05-25 av A-6 + code-2 (v1.0.1). Awaiting operator review + OK kjør for `packages/skill-registry/` skeleton (G2-adjacent gate per brain-upgrade-plan §6).*

---

## Changelog

- 2026-05-25 v1.0.2 — frontmatter YAML fix (block-list form): converted inline `related: [[X]], [[Y]]` flow-list to block-list with quoted wikilink strings; converted inline `tags: [...]` flow-list to block-list. Body untouched.
- 2026-05-25 v1.0.1 — applied B-2 CRITICAL fixes (from INTEGRATION_NOTES_v1.1.md):
  - **CRITICAL A.3.1:** frontmatter `inputs` schema: object-of-dicts → array-of-objects to match A-9's 5 actual SKILL.md files (`brain-distill-daily`, `youtube-ingest`, `github-discover`, `multi-agent-dispatch`, `worktree-spawn-cleanup`).
  - **CRITICAL A.3.1:** same for `outputs` (array-of-single-key-objects).
  - **MEDIUM A.3.2:** `project_scope` field — added sentinel exception allowing literal `workspace` value when `tier=brain` (matches the 5 actual SKILL.md files which all use this). Validator updated.
  - **MEDIUM A.3.6:** split `tools_required` into two disambiguated fields: `harness_tools` (Claude built-ins like Bash/Read/Write) and `system_tools` (external packages/CLIs like @cc/memory-engine, yt-dlp, gh). Resolves meaning-mismatch between spec example and actual files.
  - **MEDIUM G.3:** §6.2 — added trigger-registration bridge section explaining how `auto_invocable: true` skills declare a `trigger_binding:` field (cycle-bound or event-bound) that `BrainOrchestrator` consumes via `registerSkillTriggers()` to wire into AGENT_ORCHESTRATION_SPEC §8.1.
  - **NIT A.2.3:** §1 — replaced misleading `agent_tasks(skill_invocation: <name>)` shorthand with the actual §6.1 shape `agent_tasks(role: skill-runner, payload: { skill: <name>, args, invoker })`.
  - **NIT A.3.4:** added optional `version: <semver>` field to §3 schema + field table (defaults `0.1.0`, required on new skills going forward). Auto-create pipeline §7.2 now emits `version: 0.1.0`.
  - §3 validation rules expanded with 7 new checks covering inputs/outputs array shape, duplicate arg-names, project_scope sentinel constraints, and harness_tools/system_tools presence semantics.
  - §4 body template — added human-readable inputs table mirroring the frontmatter array; TS interface block now marked optional.
  - §7.2 auto-create pipeline — updated to populate new field shapes (`harness_tools` + `system_tools` derived from audit trace; `version: 0.1.0`).
  - §11 failure-modes — updated `tools_required` row to reference the two new fields.
  - Frontmatter status: `v1.0 draft` → `v1.0.1`.

**Not in this revision** (deferred to separate spec-edit passes):
- Folder rename `06-youtube/` → `12-youtube/`, `07-github-repos/` → `13-github-repos/` (INTEGRATION_NOTES CRIT E.2 — applies to §9 default-skills table; will land in B-1-propagation pass alongside the 5 other affected specs).
- Wikilink verification for `[[Runbook-Multi-Agent-Dispatch]]`, `[[git-worktree-workflow]]`, `[[reference_available_tools]]` (NITs B.6, B.7 — out of scope for this critical fix).
