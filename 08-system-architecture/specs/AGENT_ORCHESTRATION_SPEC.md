---
title: Agent Orchestration Spec
date: 2026-05-25
status: v1.0.2
spec_for: Module A (BrainOrchestrator) + Module I (Worktree) — brain-upgrade-plan
nexus_lift_from: apps/worker/src/firm/orchestrator.ts + packages/shared/src/db/schema.ts
author: A-2 (sub-agent)
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[MEMORY_DISTILLATION_SPEC]]"
tags:
  - spec
  - orchestration
  - agents
  - conductor
  - worktree
  - hermes
---

# Agent Orchestration Spec

## 1. Overview

This spec covers **Module A (`@cc/brain-orchestrator`)** and **Module I (worktree-as-default)** from `[[2026-05-25-brain-upgrade-plan]]` (§2.A + §2.I). It is the orchestration substrate that command-center will use to coordinate workspace-wide brain agents: distillation, ingestion, dead-link sweep, stale-task pings, GitHub/YouTube discovery, and operator-dispatched tasks.

**Lift strategy (binding per `2026-05-25-brain-upgrade-plan.md` §0 + §3.1):** every pattern below is a **direct port from Nexus**, not a fresh design. Nexus already runs Conductor+Hermes for trading; we generalize. Each section cites the source `file:line`. We do **not** copy trading-specific code (XAUUSD, OANDA, blackboard topics, ORB, postmortem). We copy: cycle loop, claim-with-skip-locked, lease + zombie-reaper, idempotency-key dedup, in-process trigger sweep, firm_state heartbeat KV.

What is **out of scope here:** memory schema (see `[[MEMORY_DISTILLATION_SPEC]]`), retrieval (see `[[RAG_ENGINE_SPEC]]`), skill discovery (see `[[SKILL_REGISTRY_SPEC]]`), YouTube/GitHub ingest contracts (separate specs). This spec only covers the **task lifecycle** + **isolated execution surface (worktree)** + **CLI bridge to operator-driven panes**.

---

## 2. Generic `BrainOrchestrator` class

Lifted from `apps/worker/src/firm/orchestrator.ts:97-186` (class shell + `start()`). Generalized: no session-window, no demo-mode, no XAUUSD, no blackboard. Replaces the 16-firm-modules tick list with a configurable list of `Trigger` instances.

```typescript
// packages/brain-orchestrator/src/orchestrator.ts
import type { Pool } from "pg";                       // postgres
import type Database from "better-sqlite3";           // sqlite local-dev
import { Trigger, TriggerContext } from "./triggers/types.js";
import { reapStaleLeases } from "./sla-reaper.js";
import { writeHeartbeat } from "./state-kv.js";

export interface OrchestratorConfig {
  db: Pool | Database.Database;
  dbKind: "pg" | "sqlite";
  triggers: Trigger[];
  idleCycleMs?: number;     // default 300_000  (5 min — operator AFK)
  activeCycleMs?: number;   // default 30_000   (30 s — work in flight)
  reaperEverySec?: number;  // default 60       (lease GC tick)
  heartbeatKey?: string;    // default "brain-orchestrator:heartbeat"
}

export class BrainOrchestrator {
  private cfg: Required<OrchestratorConfig>;
  private running = false;
  private cycleCount = 0;
  private cycleTimer: ReturnType<typeof setTimeout> | null = null;
  private heartbeatEnabled = true;

  constructor(cfg: OrchestratorConfig) { this.cfg = applyDefaults(cfg); }

  start(): void {
    this.scheduleNext(5_000);
  }
  stop(): void { if (this.cycleTimer) clearTimeout(this.cycleTimer); }

  private scheduleNext(delayMs: number): void {
    // Pattern: orchestrator.ts:193-231 — independent try blocks so a single
    // throw cannot break the loop. Without this, an unhandled rejection in a
    // trigger silently halts every future cycle (Nexus observed this 2026-05-17).
    this.cycleTimer = setTimeout(async () => {
      try { await this.runCycle(); } catch (err) { logErr("runCycle:", err); }
      let next = this.cfg.idleCycleMs;
      try { next = await this.cycleCadence(); } catch (err) { logErr("cadence:", err); }
      try { this.scheduleNext(next); } catch (err) { logErr("scheduleNext:", err); }
    }, delayMs);
  }

  async runCycle(): Promise<void> {
    if (this.running) return;               // single-flight (orchestrator.ts:237-240)
    this.running = true; this.cycleCount++;
    const cycleStart = Date.now();
    let lastError: string | null = null;
    try {
      await reapStaleLeases(this.cfg.db, this.cfg.dbKind);
      const ctx: TriggerContext = { db: this.cfg.db, dbKind: this.cfg.dbKind, cycleNo: this.cycleCount };
      for (const t of this.cfg.triggers) {
        try {
          if (await t.shouldFire(ctx)) await t.publish(ctx);
        } catch (err) { lastError = String(err); logWarn(`trigger ${t.name}:`, err); }
      }
    } finally {
      if (this.heartbeatEnabled) {
        await writeHeartbeat(this.cfg.db, this.cfg.dbKind, this.cfg.heartbeatKey, {
          cycleNo: this.cycleCount,
          cycleMs: Date.now() - cycleStart,
          lastError,
        }).catch(() => { this.heartbeatEnabled = false; });
      }
      this.running = false;
    }
  }

  /** Active cadence when ≥1 task is in_progress, else idle. */
  private async cycleCadence(): Promise<number> {
    const sql = "SELECT 1 FROM agent_tasks WHERE status='in_progress' LIMIT 1";
    const hasActive = this.cfg.dbKind === "pg"
      ? (await (this.cfg.db as Pool).query(sql)).rowCount! > 0
      : !!(this.cfg.db as Database.Database).prepare(sql).get();
    return hasActive ? this.cfg.activeCycleMs : this.cfg.idleCycleMs;
  }
}
```

**Cycle cadence rationale:** mirrors Nexus' session-aware cadence (`orchestrator.ts:255-261`). We replace "trading session" with "is there work in flight" — simpler signal, same shape. `idle 5min` keeps CPU dead when operator AFK; `active 30s` keeps PR-merge latency tight.

**Single-flight guard:** `if (this.running) return;` (lifted from `orchestrator.ts:237-240`). Prevents cycle overlap if a previous trigger hangs.

**Heartbeat fail-disable:** `heartbeatEnabled = false` after one write failure (lifted from `orchestrator.ts:738-762`). Pattern: state-table missing → log once → never throw again.

---

## 3. Task lifecycle

State machine — every transition emits one `agent_audit` row (lifted from research-drainer.ts `audit()` helper at line 310-316):

```
                       ┌──────────────────────────────────────┐
                       │                                      │
   ┌────────┐  publish ┌────────┐  claim()  ┌────────────┐  done() │
   │  (∅)   │─────────▶│ queued │──────────▶│ in_progress│────────▶│ done │
   └────────┘          └────────┘           └────────────┘         └──────┘
                          │  ▲                  │      │ fail()
                          │  │ reaper-requeue   │      ▼
                          │  └──────────────────┘  ┌────────┐
                          │  (lease expired)       │ failed │
                          ▼                        └────────┘
                       ┌───────────┐
                       │ cancelled │  (operator-issued only)
                       └───────────┘
```

| Transition | Audit event | Actor | Required side-effect |
|---|---|---|---|
| `∅ → queued` | `task_created` | trigger / operator | row INSERT (idempotency-key respected) |
| `queued → in_progress` | `task_claimed` | runner-id | `claimed_at = NOW()`, `claimed_by = runner`, `lease_expires_at = NOW() + sla_seconds` |
| `in_progress → done` | `task_completed` + `result_recorded` | runner-id | one `agent_results` row, `finished_at = NOW()` |
| `in_progress → failed` | `task_failed` | runner-id | one `agent_results` row (status=error), `finished_at` set |
| `in_progress → queued` | `task_zombie_reaped` | sla-reaper | `claimed_*` nulled, `attempt_count++` |
| `* → cancelled` | `task_cancelled` | operator | `finished_at = NOW()`; non-reversible |

**All transitions append-only audited.** No update without a paired audit row. Reads `agent_audit` give the full task history forever.

**Lifted from:** research-drainer.ts `claimNext()` (235-253), `completeTask()` (272-292), `failTask()` (294-308), `audit()` (310-316), `reapZombies()` (103-122).

---

## 4. Postgres + SQLite compatible schema

Lifted from `packages/shared/src/db/schema.ts:1177-1321`. Trading-only fields (`xauusd`, `symbol`, `bot_id`, `decision_cycle_id`, `regime`) **dropped**. New fields (`lease_expires_at`, `attempt_count`, `fingerprint`) added per spec §6–§7.

### 4.1 `agent_tasks`

```sql
CREATE TABLE IF NOT EXISTS agent_tasks (
  id                TEXT PRIMARY KEY,                          -- uuidv7
  parent_task_id    TEXT REFERENCES agent_tasks(id),
  role              TEXT NOT NULL                              -- 'distill'|'ingest'|'review'|'fix'|'research'|'skill-runner'|'skill-extractor'
                    CHECK (role IN ('distill','ingest','review','fix','research','skill-runner','skill-extractor')),
  model             TEXT,                                      -- 'claude-sonnet'|'gemini-flash'|null=any
  department        TEXT NOT NULL DEFAULT 'brain',             -- brain|youtube|github|skills|...
  status            TEXT NOT NULL DEFAULT 'queued'             -- queued|in_progress|done|failed|cancelled
                    CHECK (status IN ('queued','in_progress','done','failed','cancelled')),
  prompt            TEXT NOT NULL,
  context_refs      JSONB NOT NULL DEFAULT '[]',               -- file/note/url refs
  payload           JSONB NOT NULL DEFAULT '{}',               -- arbitrary trigger-specific data
  fingerprint       TEXT NOT NULL,                             -- sha256 of canonical payload, §7
  idempotency_key   TEXT NOT NULL UNIQUE,                      -- §7
  priority          INTEGER NOT NULL DEFAULT 100,
  sla_seconds       INTEGER NOT NULL DEFAULT 900,              -- 15 min default
  attempt_count     INTEGER NOT NULL DEFAULT 0,                -- ++ on reaper-requeue
  max_attempts      INTEGER NOT NULL DEFAULT 3,
  lease_expires_at  TIMESTAMPTZ,                               -- set on claim
  deadline_at       TIMESTAMPTZ,                               -- hard wall-clock cutoff
  created_by        TEXT NOT NULL DEFAULT 'orchestrator',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  claimed_at        TIMESTAMPTZ,
  claimed_by        TEXT,
  finished_at       TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_agent_tasks_claim
  ON agent_tasks(status, priority DESC, created_at)
  WHERE status IN ('queued','in_progress');
CREATE INDEX IF NOT EXISTS idx_agent_tasks_lease
  ON agent_tasks(lease_expires_at)
  WHERE status='in_progress';
```

### 4.2 `agent_results` + `agent_audit`

Lifted unchanged in shape from `schema.ts:1206-1228` and `1310-1321`. We only drop `review_*` columns (Nexus-specific). Add `attempt_no INTEGER`.

### 4.3 SQLite parity

SQLite migration mirror — types adapted:
- `JSONB` → `TEXT` (parse on read)
- `TIMESTAMPTZ` → `TEXT` (ISO 8601 strings, UTC)
- `BIGSERIAL` → `INTEGER PRIMARY KEY AUTOINCREMENT`
- `NOW()` → `CURRENT_TIMESTAMP` (write helper wraps both)
- `INTERVAL '10 minutes'` → `datetime('now', '-10 minutes')`

A single `applyMigrations(db, kind)` helper picks the right dialect array. Both produce equivalent logical schema.

### 4.4 Per-role payload contract

The `payload JSONB` column is role-typed. Publishers (triggers, CLI, sibling specs) MUST emit a payload matching the role's TypeScript shape. Consumers MAY assert with a Zod schema at claim-time before running.

```typescript
// Per-role payload shapes (canonical contract; sibling specs link back here)

// role: 'distill' — owner: MEMORY_DISTILLATION_SPEC
type DistillPayload = { date: string /*YYYY-MM-DD*/; dry_run?: boolean };

// role: 'ingest' — owner: YOUTUBE_INGESTION_SPEC + GITHUB_DISCOVERY_SPEC
type IngestPayload =
  | { kind: 'youtube'; url: string; tags?: string[]; queue_file: string }
  | { kind: 'github'; repo: string; query?: string; topic?: string };

// role: 'research' — owner: GITHUB_DISCOVERY_SPEC §2
type ResearchPayload = { query: string; limit: number; topic?: string };

// role: 'review' — owner: this spec (stale-task trigger)
type ReviewPayload = { inbox_file: string; age_days: number };

// role: 'fix' — owner: this spec (dead-link trigger)
type FixPayload = { broken_wikilink: string; in_file: string };

// role: 'skill-runner' — owner: SKILL_REGISTRY_SPEC §6.1
// Handles skill invocations dispatched from `multi-agent-dispatch` skill and
// from CLI `/brain skills run <name>`. The skill-runner role is the bridge
// between the SKILL_REGISTRY (skill metadata + steps) and the orchestrator's
// task queue (durable, audited execution).
type SkillRunnerPayload = { skill: string; args: Record<string, unknown>; invoker: string };

// role: 'skill-extractor' — owner: SKILL_REGISTRY_SPEC §7
// Event-driven: published by the `skill-extract-from-success` trigger when a
// completed task carries `surprising_finding=true` in its agent_results row.
type SkillExtractorPayload = { source_task_id: string; outcome_summary: string };
```

Contract is advisory at the DB layer (column stays `JSONB`/`TEXT`); enforcement is per-trigger and per-claim. See sibling specs (`[[SKILL_REGISTRY_SPEC]]`, `[[YOUTUBE_INGESTION_SPEC]]`, `[[GITHUB_DISCOVERY_SPEC]]`, `[[MEMORY_DISTILLATION_SPEC]]`) for the authoritative shape per role.

---

## 5. Atomic claim — `FOR UPDATE SKIP LOCKED` (PG) / `BEGIN IMMEDIATE` (SQLite)

Lifted from `research-drainer.ts:235-253`. Two dialects, one TypeScript surface:

```typescript
// packages/brain-orchestrator/src/task-claim.ts
import { randomUUID } from "node:crypto";

export async function claimNext(
  db: Pool | Database.Database,
  kind: "pg" | "sqlite",
  runner: string,
  role?: string,                       // optional role-filter
): Promise<ClaimedTask | null> {
  if (kind === "pg") return claimNextPg(db as Pool, runner, role);
  return claimNextSqlite(db as Database.Database, runner, role);
}

async function claimNextPg(db: Pool, runner: string, role?: string): Promise<ClaimedTask | null> {
  const filter = role ? "AND role = $2" : "";
  const params: unknown[] = [runner];
  if (role) params.push(role);
  const r = await db.query<ClaimedTask>(
    `WITH next AS (
       SELECT id FROM agent_tasks
        WHERE status='queued' ${filter}
          AND (deadline_at IS NULL OR deadline_at > NOW())
        ORDER BY priority DESC, created_at
        LIMIT 1 FOR UPDATE SKIP LOCKED
     )
     UPDATE agent_tasks
        SET status='in_progress',
            claimed_at=NOW(),
            claimed_by=$1,
            lease_expires_at=NOW() + (sla_seconds || ' seconds')::INTERVAL,
            attempt_count=attempt_count+1
       FROM next WHERE agent_tasks.id = next.id
     RETURNING agent_tasks.*`,
    params,
  );
  return r.rows[0] ?? null;
}

function claimNextSqlite(db: Database.Database, runner: string, role?: string): ClaimedTask | null {
  // SQLite has no SKIP LOCKED. BEGIN IMMEDIATE acquires the reserved lock
  // up-front so concurrent claimers serialize without blocking readers.
  const tx = db.transaction(() => {
    const selSql = `SELECT * FROM agent_tasks
                     WHERE status='queued'
                       ${role ? "AND role=@role" : ""}
                       AND (deadline_at IS NULL OR deadline_at > datetime('now'))
                     ORDER BY priority DESC, created_at
                     LIMIT 1`;
    const row = db.prepare(selSql).get(role ? { role } : {}) as ClaimedTask | undefined;
    if (!row) return null;
    db.prepare(
      `UPDATE agent_tasks
          SET status='in_progress', claimed_at=datetime('now'),
              claimed_by=@runner,
              lease_expires_at=datetime('now', '+' || sla_seconds || ' seconds'),
              attempt_count=attempt_count+1
        WHERE id=@id AND status='queued'`,
    ).run({ runner, id: row.id });
    return row;
  });
  db.exec("BEGIN IMMEDIATE");
  try { return tx(); } finally { db.exec("COMMIT"); }
}
```

**Atomicity guarantee:** the CTE+UPDATE in one statement (PG) or `BEGIN IMMEDIATE` block (SQLite) ensures two runners polling concurrently cannot grab the same row. `FOR UPDATE SKIP LOCKED` keeps PG performant: contention degrades to throughput, not deadlock.

**Edge case:** if `BEGIN IMMEDIATE` fails with `SQLITE_BUSY`, the helper retries 3× with 50ms backoff before giving up (caller treats as "no work").

---

## 6. Lease + SLA reaper

Lifted from `research-drainer.ts:103-122` (`reapZombies`) and `orchestrator.ts:805-840` (firm_state helpers).

```typescript
// packages/brain-orchestrator/src/sla-reaper.ts
export async function reapStaleLeases(
  db: Pool | Database.Database, kind: "pg" | "sqlite",
): Promise<number> {
  const sql = kind === "pg"
    ? `UPDATE agent_tasks
          SET status='queued', claimed_by=NULL, claimed_at=NULL,
              lease_expires_at=NULL
        WHERE status='in_progress'
          AND lease_expires_at IS NOT NULL
          AND lease_expires_at < NOW()
          AND attempt_count < max_attempts
       RETURNING id`
    : `UPDATE agent_tasks
          SET status='queued', claimed_by=NULL, claimed_at=NULL,
              lease_expires_at=NULL
        WHERE status='in_progress'
          AND lease_expires_at IS NOT NULL
          AND lease_expires_at < datetime('now')
          AND attempt_count < max_attempts`;
  // also: any in_progress past max_attempts → status='failed' with reason
  // 'lease_exhausted'. Operator decides whether to manually requeue.
  // ... (audit each transition; details omitted for brevity)
}
```

**Lease math (timezone-safe):** all timestamps stored as `TIMESTAMPTZ` (PG) or ISO 8601 with `Z` suffix (SQLite). Reaper computes `now - lease_expires_at` in UTC. No local-tz arithmetic anywhere. SLA examples: `sla_seconds=900` → lease 15 min; 3 attempts → max ~45 min wall-clock before final failure.

**Lease is advisory** (binding per CLAUDE.md "operator-gated irreversible"). Operator can `UPDATE agent_tasks SET status='queued' WHERE id=...` at any time without breaking the system — reaper will eventually catch up.

**Reaper cadence:** runs once per `BrainOrchestrator.runCycle()`. At idle (5 min), reaper still fires every 5 min — plenty fast for human-perceived "task stuck" detection.

---

## 7. Idempotency + fingerprint dedup

Lifted from `agent-trigger.ts:244-272` (`publishOnce`).

**Two-layer dedup:**

1. **`idempotency_key UNIQUE`** — sha256 of `{trigger_name, fingerprint, role, prompt_hash}`. `ON CONFLICT DO NOTHING` collapses duplicate enqueues to a single row. Same as Nexus `agent-trigger.ts:250-265`.

2. **`fingerprint`** — sha256 of the **canonicalized payload** (JSON keys sorted, whitespace stripped, lower-case). Used by triggers to detect "same logical event" across reruns. Triggers compute `fingerprint = sha256(canonicalize(payload))` before publishing.

```typescript
// packages/brain-orchestrator/src/fingerprint.ts
import { createHash } from "node:crypto";

export function canonicalize(obj: unknown): string {
  if (obj === null || typeof obj !== "object") return JSON.stringify(obj);
  if (Array.isArray(obj)) return "[" + obj.map(canonicalize).join(",") + "]";
  const keys = Object.keys(obj as object).sort();
  return "{" + keys.map(k => JSON.stringify(k) + ":" + canonicalize((obj as Record<string, unknown>)[k])).join(",") + "}";
}

export function fingerprintOf(payload: unknown): string {
  return createHash("sha256").update(canonicalize(payload), "utf8").digest("hex");
}

export function idempotencyKeyOf(parts: { trigger: string; fingerprint: string; role: string; promptHash: string }): string {
  return createHash("sha256").update(JSON.stringify(parts), "utf8").digest("hex");
}
```

**Why both:** fingerprint = "same business event"; idempotency_key = "same enqueue intent". A trigger that re-runs every 30s with the same business state should produce the same fingerprint → same idempotency_key → single row.

---

## 8. `Trigger` interface

Lifted contract from `agent-trigger.ts:78-231` (`TriggerFn`). Generalized to a class so triggers can hold state (cooldown timers, last-seen counters).

```typescript
// packages/brain-orchestrator/src/triggers/types.ts
import type { Pool } from "pg";
import type Database from "better-sqlite3";

export interface TriggerContext {
  db: Pool | Database.Database;
  dbKind: "pg" | "sqlite";
  cycleNo: number;
}

export interface TaskPayload {
  role: string;
  model?: string;
  department?: string;
  prompt: string;
  contextRefs?: unknown[];
  payload?: unknown;
  priority?: number;
  slaSeconds?: number;
}

/** Event-driven trigger input (post-task hooks, commit hooks, file-write hooks, manual invokes). */
export type TriggerEvent =
  | { kind: 'commit'; sha: string; repo: string }
  | { kind: 'task-complete'; task_id: string; role: string; outcome: 'success' | 'failure'; result_ref?: string }
  | { kind: 'file-write'; path: string }
  | { kind: 'manual-invoke'; invoker: string; reason?: string };

export interface Trigger {
  readonly name: string;
  /**
   * Cycle-poll path. Called once per orchestrator cycle. Return true if a task
   * should be published this cycle. Optional — a trigger MAY implement only
   * `onEvent` instead (e.g. `skill-extract-from-success` is purely event-driven).
   */
  shouldFire?(ctx: TriggerContext): Promise<boolean>;
  /**
   * Event-driven path. Called by the event-bus when a matching `TriggerEvent`
   * fires (commit hook, post-task hook, file-watcher, manual invoke). Return a
   * `TaskPayload` to publish, or `null` to no-op. Optional — a trigger MAY
   * implement only `shouldFire` instead (the original cycle-poll triggers).
   *
   * Every Trigger MUST implement at least one of {`shouldFire`, `onEvent`};
   * registry-load fails fast otherwise.
   */
  onEvent?(event: TriggerEvent, ctx: TriggerContext): Promise<TaskPayload | null>;
  /** Cycle-poll publish path; called when shouldFire returns true. */
  publish(ctx: TriggerContext): Promise<TaskPayload | null>;
}
```

**Wiring:** the orchestrator's `runCycle()` iterates `shouldFire`-implementing triggers (cycle-poll path, §2). Event-driven triggers register with a separate in-process event-bus that fans `TriggerEvent`s out to all `onEvent`-implementing triggers (post-task hook called from `completeTask()` / `failTask()`; commit hook from a git post-commit script; file-write hook from `firm-inbox-watch.sh`; manual-invoke from CLI). Both paths terminate in the same `publishOnce(db, trigger, fingerprint, payload)` helper (§7) — same idempotency, same audit trail.

### 8.1 Built-in triggers (Module H from brain-upgrade-plan)

| Name | Mode | Cadence / Event | Publishes |
|---|---|---|---|
| `stale-task` | poll | `cycleNo % 120 === 0` (~daily at idle) | review task per open inbox-item > 14d old |
| `dead-link` | poll | `cycleNo % 1440 === 0` (~weekly) | fix task per broken wikilink in brain |
| `youtube-queue` | poll | every cycle | ingest task per file in `12-youtube/_queue/` |
| `github-discovery` | poll | every cycle | ingest task per `search:*` file in `13-github-repos/_queue/` |
| `nightly-memory-distill` | poll | once per UTC day @ 03:00 local | distill task with `date: YYYY-MM-DD` payload |
| `worktree-gc` | poll | `cycleNo % 1440 === 0` (~daily) | maintenance task: GC `.worktrees/*/*` > 7d clean across 6 repos (§9.2) |
| `skill-extract-from-success` | event | `onEvent({kind:'task-complete', outcome:'success', ...})` where the completed task's `agent_results.surprising_finding === true` | `skill-extractor` task with `source_task_id` + outcome summary (per `[[SKILL_REGISTRY_SPEC]]` §7) |

**Trigger mode legend:** `poll` = implements `shouldFire(ctx)` (cycle-poll path, §8); `event` = implements `onEvent(event, ctx)` (event-bus path, §8). Each implements the `Trigger` interface and uses `publishOnce(db, trigger, fingerprint, payload)` (lifted helper). All idempotent via §7.

**Naming note:** `nightly-memory-distill` (was `nightly-distill` in v1.0) — renamed for cross-spec consistency with `[[MEMORY_DISTILLATION_SPEC]]` §4.c which uses the longer form.

---

## 9. Worktree-as-default policy (Module I)

**Current state:** `firm-wt-split.sh` has `--codex` flag (`firm-wt-split.sh:30-37`) that points panes at `.worktrees/codex/<slug>/`. Worktree creation is in `firm-worktree-spawn.sh` (already idempotent — see line 67-76: `if [[ -d "$WT_PATH" ]] && git -C ... worktree list ...`).

**Target:** **new flag `--worktree-default`** on `firm-wt-split.sh`. When set, every pane gets its own worktree under `<repo>/.worktrees/<role>/<branch-slug>/`. Branch convention: `<role>/<task-id-or-slug>` (e.g. `code-1/T-2026-05-25-001`, `ai-2/fix-orb-gate`).

**Gate:** **brain-G3 (operator OK required)** per `2026-05-25-brain-upgrade-plan.md` §6 before this becomes default. Until brain-G3: `--worktree-default` is opt-in, `--codex` remains for codex-specific.

### 9.1 Edge cases

| Case | Behaviour |
|---|---|
| Branch already exists | Reuse: `git worktree add <path> <branch>` (no `-b`). `firm-worktree-spawn.sh:80-96` handles this. |
| Worktree path already exists + registered | No-op + print path (`firm-worktree-spawn.sh:69-76`). |
| Worktree path exists but NOT in `git worktree list` (dirty leftover) | **Abort + alert.** Operator must `rm -rf` or `git worktree prune` first. Never silently overwrite. |
| Repo dirty (uncommitted changes on current HEAD) | `worktree add` from current HEAD will pick up those changes in new worktree. Pre-flight: `git status --porcelain` warning if non-empty. Operator OK before proceeding. |
| Branch name conflicts with remote | Local branch wins; push fails later with operator-visible error. No silent force-push. |
| Disk full | `git worktree add` fails with ENOSPC. Surfaced as fatal — `firm-task-claim.sh` exits 1, task returns to queued. SLA reaper handles requeue. |
| Conflict on merge-back | Worktree stays. Operator resolves manually. Worktree NOT garbage-collected while uncommitted changes exist. |

### 9.2 Cleanup-job

Runs as a `BrainOrchestrator` trigger (`worktree-gc`): every 24h, list `.worktrees/*/*` across all 6 repos, compare to `git log -1 --since=7.days`. Worktrees with no commits in 7d AND clean status → `git worktree remove`. Worktrees with uncommitted changes → leave alone, log to `09-retrospectives/`.

---

## 10. `firm-task-claim.sh` + `firm-task-complete.sh`

Bash scripts that bridge pane-side operator workflow ↔ the `agent_tasks` queue. Both live in `command-center/_bin/`.

### 10.1 `firm-task-claim.sh`

```bash
#!/usr/bin/env bash
# firm-task-claim.sh — claim next open task for current pane
# Usage: firm-task-claim.sh [<task-id>]  (id optional; else claims highest-priority for $FIRM_ROLE)
#
# 1. Read $FIRM_ROLE (exported by firm-tab-init.sh).
# 2. If <task-id> supplied: lock that specific file under 10-tasks/_open/.
#    Else: pick the highest-priority match for role from 10-tasks/_open/*.md frontmatter.
# 3. Parse YAML frontmatter (see §11 schema).
# 4. Move file: 10-tasks/_open/<id>.md → 10-tasks/_in-progress/<id>.md
# 5. cd to repo from `branch:` field; create worktree via firm-worktree-spawn.sh.
# 6. Update frontmatter status: dispatched → claimed; write claimed_at, claimed_by=$FIRM_ROLE.
# 7. Print absolute worktree path + suggested next-step to stdout.
# Exit non-zero if: no matching task, branch conflict, worktree create fails.

set -euo pipefail
BRAIN=$HOME/Obsidian/Brain
TASKS=$BRAIN/10-tasks

# ... yq-based frontmatter parse, idempotent worktree create, audit-line to firm-bus/feed.md
```

### 10.2 `firm-task-complete.sh`

```bash
#!/usr/bin/env bash
# firm-task-complete.sh — commit work, push (gated), open PR, archive task
# Usage: firm-task-complete.sh [<task-id>]
#
# 1. Detect current task: parse worktree path (.worktrees/<role>/<slug>/) OR <task-id> arg.
# 2. Validate: only files_allowed glob is dirty (git diff name-only intersected with allowlist).
#    Abort if any file outside allowlist is modified.
# 3. git add (allowlist only), commit with frontmatter-derived message.
# 4. Push only if env OPERATOR_OK_PUSH=1 (binding per CLAUDE.md "OK kjør before every push").
#    Else: print "Operator OK kjør required — run: OPERATOR_OK_PUSH=1 firm-task-complete.sh ..."
# 5. gh pr create (if pushed).
# 6. Move file: 10-tasks/_in-progress/<id>.md → 10-tasks/_done/<id>.md, status: done.
# 7. Append one-line to firm-bus/feed.md: "<role> done <id> PR#<n>".
```

Both scripts are **idempotent** — re-running on an already-completed task no-ops with a "task already in _done/" message. Both write `agent_audit` rows directly via `psql`/`sqlite3` if `BRAIN_ORCHESTRATOR_DB_URL` is set; else just emit the audit-line to `feed.md`.

---

## 11. Inbox frontmatter v2

Upgrade from the §2.I template in `2026-05-25-brain-upgrade-plan.md:381-397`. Parseable by `firm-inbox-watch.sh` and the two bash CLIs above.

```yaml
---
task_id: T-2026-05-25-001       # required, must match filename
from: operator                  # operator | <role> (peer-handoff)
to: code-2                      # role-id from project registry
objective: |
  Lift FirmOrchestrator pattern into @cc/brain-orchestrator.
  See [[AGENT_ORCHESTRATION_SPEC]] §2.
branch: code-2/brain-orchestrator         # <role>/<slug>; worktree dir derived
files_allowed:                  # glob array; enforced by firm-task-complete.sh
  - packages/brain-orchestrator/**
  - 08-system-architecture/specs/**
expected_output: |              # human-readable; not validated
  TS package builds + 80% test coverage + PR opened against main
tests:                          # commands to run before complete; all must exit 0
  - npm -w @cc/brain-orchestrator test
  - npm -w @cc/brain-orchestrator run typecheck
rollback: |                     # operator-facing; what to do if it breaks prod
  Revert the PR. Worktree at .worktrees/code-2/brain-orchestrator can be
  inspected, then `git worktree remove`.
sla_seconds: 86400              # 24h; reaper requeues past this if claimed
priority: 100                   # 0-200; higher = sooner
auto_claim: false               # if true, firm-inbox-watch auto-dispatches to firm-task-claim.sh
status: dispatched              # dispatched | claimed | in_progress | done | failed | cancelled
created_at: "2026-05-25T10:00:00Z"
claimed_at: null                # filled by firm-task-claim.sh
claimed_by: null                # role-id
finished_at: null
---

# Human-readable task description follows the frontmatter.
# This section is preserved verbatim; bash scripts only touch the frontmatter.
```

**Validation:** every field except `claimed_*`/`finished_at` is required. `firm-task-claim.sh` validates with `yq` (or a small node parser fallback). Schema mirrors `agent_tasks` columns 1:1 so `firm-task-claim.sh` can `INSERT INTO agent_tasks` directly when DB is configured.

---

## 12. Merge protocol

```
                                                           ┌─────────────────┐
   ┌──────────┐  claim   ┌──────────────┐  work    PR     │                 │
   │ _open/   │─────────▶│ _in-progress │─────────────────▶  GitHub PR     │
   │  .md     │          │ + worktree   │   (gated push)  │  open           │
   └──────────┘          └──────────────┘                 └────────┬────────┘
                                                                   │
                                                          operator │ OK kjør
                                                                   ▼
                                                          ┌────────────────┐
                                                          │ merge to main  │
                                                          └────────┬───────┘
                                                                   │
                                                                   ▼
                                                          ┌────────────────┐
                                                          │ _done/  .md    │
                                                          │ status: done   │
                                                          │ + worktree     │
                                                          │   remove       │
                                                          └────────────────┘
```

1. **PR open:** `firm-task-complete.sh` opens the PR with body templated from `objective`/`expected_output`/`tests`/`rollback`. PR title `[<task_id>] <first line of objective>`.
2. **Operator OK kjør:** mandatory per CLAUDE.md. No auto-merge. PR sits until operator clicks merge.
3. **Merge to main:** standard `gh pr merge --squash` (operator choice of strategy).
4. **Worktree cleanup:** post-merge hook (or `worktree-gc` trigger next cycle): `git worktree remove .worktrees/<role>/<slug>` + `git branch -d <role>/<slug>`. Branch deletion only if `git branch --merged` includes it.
5. **Cleanup-GC:** `worktree-gc` trigger (§9.2) GCs worktrees > 7d with no commits as a safety net for forgotten branches.

---

## 13. Acceptance tests

All must pass before Module A + I promote out of `draft` per §11 of brain-upgrade-plan.

| # | Test | Threshold | Pass criterion |
|---|---|---|---|
| AT-1 | 5 synthetic tasks (`role: dummy`, prompts that touch disjoint files) enqueued, all 8 panes drain parallel | 1 calendar day | 5/5 reach status=done, 0 merge conflicts, PRs cleanly mergeable |
| AT-2 | Lease-expiry: enqueue 1 task with `sla_seconds=5`; claim, sleep 10s, no done | within 60s of expiry | `attempt_count=2`, status back to `queued`, audit shows `task_zombie_reaped` |
| AT-3 | Idempotency: same `publishOnce(trigger, fingerprint, payload)` called 3× | exactly 1 | `SELECT COUNT(*) FROM agent_tasks WHERE fingerprint = X` returns 1 |
| AT-4 | Worktree-create-idempotent: spawn same `<role>/<slug>` twice | exit 0 both times | second invocation prints "worktree finnes allerede" and exits 0 |
| AT-5 | `files_allowed` enforcement: dirty file outside allowlist | abort | `firm-task-complete.sh` exits ≥ 1 with explicit "file X not in allowlist" message |
| AT-6 | Cycle survival: trigger throws on every cycle | indefinite | `cycleNo` keeps incrementing, heartbeat fresh, other triggers still fire |
| AT-7 | Failure-mode coverage: kill runner mid-task (SIGKILL while in_progress) | reaper requeues within 1 reaper-tick after lease expiry | task back to `queued` with `attempt_count++` |
| AT-8 | SQLite ↔ PG schema parity | `applyMigrations()` runs on both fresh DBs | identical column set returned by `SELECT * FROM agent_tasks WHERE 0=1` per dialect |

---

## 14. Failure modes + operator-alert

Per `2026-05-25-brain-upgrade-plan.md` §7 and CLAUDE.md operator-prinsipp #1 (REPORT, never auto-disable):

| Failure | Detection | Operator-alert | Auto-handling |
|---|---|---|---|
| Postgres connection down | `runCycle()` heartbeat write fails repeatedly | feed.md line + Discord embed via webhook (operator wired separately) | `heartbeatEnabled=false`, cycle keeps running locally; triggers still try (will fail) |
| Worktree create fail (disk full / ENOSPC) | `git worktree add` non-zero exit | `firm-task-claim.sh` prints stderr + writes to `09-retrospectives/<date>-disk-full.md` | task returns to `queued`; reaper requeues; eventually attempt_count exceeded → status=failed |
| Worktree create fail (dirty leftover dir) | pre-flight `git worktree list` check | inline error message + manual `git worktree prune` instruction | no auto-fix; operator must clean up |
| Lease-expiry storm (many tasks zombified at once, e.g. worker OOM) | reaper batch count > 10 in one tick | Discord notification "N zombies reaped this cycle" | tasks requeued normally; operator decides if to bump SLA |
| Trigger infinite-publish-loop (bug in `shouldFire`) | same fingerprint appears > 5× in `agent_audit` for `task_created` events in 1 cycle | log warn + skip remaining cycles of that trigger for 1 hour (in-memory) | trigger paused, not disabled; operator OK kjør to restore |
| Branch protection rejected push | `gh push` non-zero | error printed + task stays in `_in-progress/` | no retry; operator handles |
| PR conflict on merge | gh pr merge fails | operator-visible on GitHub UI | task stays in `_in-progress/`; operator resolves |
| Idempotency-key collision (different payload, same key) | UNIQUE constraint violation on INSERT | log warn + skip publish | no auto-fix; sign of a fingerprint bug — file in `09-retrospectives/` |

**Binding:** none of the above ever auto-disables a trigger or a strategy. All REPORT-only per CLAUDE.md operator-prinsipp #1.

---

## 15. Code skeleton

```
command-center/
├── packages/brain-orchestrator/
│   ├── package.json
│   ├── src/
│   │   ├── orchestrator.ts          # BrainOrchestrator class (§2)
│   │   ├── task-claim.ts            # PG+SQLite claimNext (§5)
│   │   ├── sla-reaper.ts            # reapStaleLeases (§6)
│   │   ├── state-kv.ts              # heartbeat + cooldown helpers (firm_state lift)
│   │   ├── fingerprint.ts           # canonicalize + idempotencyKeyOf (§7)
│   │   ├── publish.ts               # publishOnce — INSERT ... ON CONFLICT DO NOTHING (§7)
│   │   ├── audit.ts                 # one append per state transition (§3)
│   │   ├── migrations/
│   │   │   ├── pg.ts                # full DB_MIGRATIONS array (§4.1+4.2)
│   │   │   └── sqlite.ts            # SQLite-dialect mirror (§4.3)
│   │   ├── triggers/
│   │   │   ├── types.ts             # Trigger interface (§8)
│   │   │   ├── stale-task.ts        # > 14d open inbox-items → review
│   │   │   ├── dead-link.ts         # broken wikilinks → fix
│   │   │   ├── youtube-queue.ts     # _queue/ → ingest
│   │   │   ├── github-discovery.ts  # _queue/ search:* → ingest
│   │   │   ├── nightly-memory-distill.ts # 03:00 UTC distill (§4.4 brain-plan)
│   │   │   ├── worktree-gc.ts       # daily worktree GC (§9.2)
│   │   │   └── skill-extract-from-success.ts # event-driven, post-task hook (§8)
│   │   └── index.ts                 # public surface
│   └── tests/
│       ├── claim.test.ts            # AT-1, AT-3
│       ├── lease.test.ts            # AT-2, AT-7
│       ├── fingerprint.test.ts      # canonicalize roundtrip
│       ├── triggers.test.ts         # each built-in's shouldFire/publish contract
│       └── sqlite-pg-parity.test.ts # AT-8
└── _bin/
    ├── firm-wt-split.sh             # +--worktree-default flag (§9) — modify existing
    ├── firm-worktree-spawn.sh       # already idempotent — no changes
    ├── firm-task-claim.sh           # NEW (§10.1)
    ├── firm-task-complete.sh        # NEW (§10.2)
    ├── firm-task-status.sh          # NEW — print current pane's task + worktree state
    └── firm-worktree-gc.sh          # NEW — manual GC trigger (also called by trigger)
```

**TS code:** orchestrator core, claim, reaper, triggers, fingerprint, publish, audit, migrations. All compiled, tested, exported as `@cc/brain-orchestrator`.

**Bash code:** pane-side CLIs only. Bash chosen because panes are interactive and operator already lives there. Bash scripts never touch DB directly when `BRAIN_ORCHESTRATOR_DB_URL` is unset — they fall back to filesystem-only mode (10-tasks/ folder lifecycle + feed.md audit).

---

## 16. Cross-references

- **Parent plan:** `[[2026-05-25-brain-upgrade-plan]]` §2.A (BrainOrchestrator), §2.I (Worktree-as-default), §11 (verify policy), §6 brain-G3 (worktree-default OK-gate).
- **Memory schema (what tasks produce/consume):** `[[MEMORY_DISTILLATION_SPEC]]`.
- **Retrieval consumers (what reads the artifacts):** `[[RAG_ENGINE_SPEC]]`.
- **Skill discovery (auto-promotion from task outcomes):** `[[SKILL_REGISTRY_SPEC]]`.
- **Nexus source files (lift targets, read-only):**
  - `apps/worker/src/firm/orchestrator.ts` — cycle loop (§2)
  - `apps/worker/src/firm/agent-bus/research-drainer.ts` — claim+lease+reaper (§5, §6)
  - `apps/worker/src/firm/agent-bus/agent-trigger.ts` — trigger pattern + publishOnce (§7, §8)
  - `packages/shared/src/db/schema.ts:1177-1321` — agent_tasks/results/audit DDL (§4)
- **Existing bash:** `command-center/_bin/firm-wt-split.sh`, `firm-worktree-spawn.sh`, `firm-tab-init.sh`, `firm-inbox-watch.sh`.
- **Governance:** `~/.claude/CLAUDE.md` (operator-gated actions, OK kjør gate); `/home/nithu/code/ai-assistent/CLAUDE.md` (operator-prinsipper).

---

*v1.0 draft — 2026-05-25, A-2 sub-agent. Awaiting operator OK kjør on brain-G3 (worktree-default) before implementation. Until brain-G3: spec is read-only reference for code-1/code-2 lanes (C1-1, C2-8, C2-9).*

---

## Changelog

- 2026-05-25 v1.0.2 — frontmatter YAML fix (block-list form): converted inline `related: [[X]], [[Y]]` flow-list to block-list with quoted wikilink strings; converted inline `tags: [...]` flow-list to block-list. Body untouched.
- 2026-05-25 v1.0.1 — applied B-2 CRITICAL + MEDIUM fixes per `INTEGRATION_NOTES_v1.1.md`:
  - **CRITICAL A.2.1:** Task role enum (§4.1) — added `skill-runner` and `skill-extractor`; promoted enum from comment-only to a DB `CHECK` constraint so the column enforces the contract.
  - **CRITICAL C.6:** Trigger interface (§8) — added optional `onEvent(event, ctx)` for event-driven triggers (commit / task-complete / file-write / manual-invoke) alongside the existing optional poll-based `shouldFire(ctx)`. Every trigger MUST implement at least one. Added `TriggerEvent` union type and wiring paragraph.
  - **CRITICAL E.2:** Built-in triggers table (§8.1) — fixed folder paths: `12-youtube/_queue/` (was `12-youtube/_queue/`, kept) and `13-github-repos/_queue/` (was orphan `07-github/_queue/` — typo even pre-B-1 rename).
  - **MEDIUM A.2.2:** Added §4.4 — per-role payload contract enumerating TypeScript shapes for all 7 task roles (`distill`, `ingest`, `research`, `review`, `fix`, `skill-runner`, `skill-extractor`) with cross-references to owner specs. Documents that `skill-runner` handles skill invocations from `multi-agent-dispatch` and CLI `/brain skills run <name>`.
  - **MEDIUM C.1:** Renamed `nightly-distill` → `nightly-memory-distill` to match `[[MEMORY_DISTILLATION_SPEC]]` §4.c canonical naming. Code skeleton (§15) filename updated accordingly.
  - **MEDIUM C.2:** Added `worktree-gc` trigger to §8.1 (daily poll, cycle % 1440) — previously referenced in §9.2 and §15 without a registry entry.
  - **MEDIUM C.3:** Added `skill-extract-from-success` trigger to §8.1 as the first event-driven entry, wired to the new `onEvent` path.
  - Status frontmatter: `v1.0 draft` → `v1.0.1`.
- 2026-05-25 v1.0 — initial draft (A-2 sub-agent); lift from Nexus orchestrator + research-drainer + agent-trigger + schema.
