# Audit 08 — Stages (12) Concrete Tasks for Agents + (13) Implementation

**Date:** 2026-06-15
**Scope:** Does Nexus turn evaluation findings into *structured, data-driven tasks*, or do the Claude agents work from assumptions / free-text coordination?
**Method:** read-only code + schema + live DB (nexus-pg-rw).

## VERDICT: WEAK (real data-driven generator exists, but it produces research-grade prompts, not engineering tasks, and the closed loop is half-wired)

There IS a genuine data-driven task generator in the Nexus repo. It is not vibes — tasks are minted from live trading state with idempotency and audit. But: (a) generated tasks carry only `prompt + context_refs + priority + deadline`, NOT the required engineering fields (acceptance criteria, test command, rollback condition, files affected); (b) only the `research` lane drains autonomously in prod — `review/risk` and `journaling` tasks pile up unconsumed; (c) the actual code/strategy changes are driven by **hand-written Claude prose** (firm-bus inbox markdown + KARRI-DISPATCH docs), not by the task table.

---

## Q1 — Is there a structured agent_tasks generator with the required fields?

**Partly.** The table and the generator are real:

- **Schema:** `packages/shared/src/db/schema.ts:1177` — `agent_tasks` (id, parent_task_id, role, model, department, status, prompt, context_refs JSONB, idempotency_key UNIQUE, priority, sla_seconds, deadline_at, created_by, claimed_by, claimed_at, finished_at). Plus `agent_results`, `agent_artifacts`, `agent_audit`. This is Nexus's OWN table (created by Worker/API DB_MIGRATIONS), distinct from command-center's C1-9 TaskStore. Grants in `scripts/firehose/grants.sql:8`.

- **The generator:** `apps/worker/src/firm/agent-bus/agent-trigger.ts` — `runAgentTriggers(db)`, called from the worker cycle, default-OFF via `AGENT_TRIGGER_PUBLISH_ENABLED`. Four data-driven triggers, each querying live tables and minting a task:
  - `LOSS_STREAK` — 3 consecutive losses on a strategy in 6h (`simulated_orders`) → research task.
  - `NEW_POSTMORTEM` — postmortem written in last 30min (`postmortems`) → review/journaling.
  - `REGIME_FLIP` — portfolio regime change (`blackboard xauusd.portfolio.context`) → research.
  - `GATE_SPIKE` — >5 `would_reject=true` on one gate in 1h (`gate_decisions`) → review/risk.
  - Idempotency = sha256(trigger+fingerprint+role+prompt); per-trigger cooldown via `firm_state`. Audit row on every create. High-priority (≥105) also writes an `agent_artifacts` Discord-audit row.

**Required-field gap (this is the WEAK part).** Each generated task has: title (implicit in prompt), context (prompt), data evidence (`context_refs` = SQL/topic/note pointers — GOOD), expected output (the prompt explicitly asks for "5-bullet diagnosis" / "3-bullet review" — GOOD), priority (GOOD), deadline/status (`deadline_at` + `status` — GOOD). It does **NOT** have: files/modules affected, acceptance criteria, **test command**, **rollback condition**. These are diagnosis/research envelopes, not engineering-change tickets. There is no generator that emits "change file X, make tsc green, behind env flag Y, revert by Z."

The `scripts/agent-task.mjs` CLI is an *operator/Phase-0* tool (writes the same table by hand), explicitly "does NOT call any LLM"; 0 of 471 live rows came from it.

## Q2 — How do ai-1 / ai-2 actually decide what to do each session?

**From hand-curated free-text markdown, not from the agent_tasks queue.** Evidence:

- `~/Obsidian/Brain/00-firm-bus/inbox/ai-1.md` and `ai-2.md` are prose handoffs: "OPEN — pick from here (ordered by impact): 1. portfolio-regime-backfill-sql.md … 2. … coordinate which item you each take." These are written by *other Claude panes* (code-2, ai-1) after audits — a human/Claude triage layer, not the DB generator.
- `~/Obsidian/Brain/00-firm-bus/feed.md` (122 KB) is the running manual coordination log.
- `docs/strategy/KARRI-DISPATCH-2026-06-{08,09,13}.md` are authored by ai-1 ("fra ai-1"), committed as docs (`afe8170 docs(strategy): Karri dispatch #4`). They cite file:line + n-counts + Wilson CIs, so they are *evidence-grounded*, but they are **Claude prose hand-written from analysis**, not machine-generated task envelopes. The data→decision step here is a Claude agent improvising structure, then a human (Karri) reviewing.

So the two trading panes decide work from: operator chat ("kjør full analyse"), peer inbox markdown, and the OPEN-items lists — **not** by claiming rows from `agent_tasks`. The DB queue and the markdown coordination are two parallel systems; the agents live in the markdown one.

## Q3 — Tasks tied to data evidence + acceptance criteria + rollback, or vibes?

**Mixed.** The DB-generated tasks are tied to data evidence (embedded SQL `context_refs` + the trigger fired off a real threshold) and have an *expected output spec* — not vibes. But they have **no acceptance criteria, no test command, no rollback** — because they ask for analysis, not code. The KARRI-DISPATCH/proposal docs DO carry rollback discipline (every change "default-OFF, behind env flag, operator flips Railway") and acceptance reasoning (CI floors, n-counts) — but that rigor is *authored by Claude per the proposal template*, not generated, and applies to strategy proposals, not to a task record.

## Q4 — Closed link evaluation → task → implementation → verification?

**Half-closed, and the implementation arm is human/Claude.**

Live DB (471 tasks, 470 from agent-trigger, last 2026-06-15 — generator IS firing in prod):

| created_by | tasks | results | success | status |
|---|---|---|---|---|
| agent-trigger:regime_flip | 266 | 266 | 242 | mostly done — drained |
| agent-trigger:gate_spike (review/risk) | 111 | 0 | 0 | **all queued, no consumer** |
| agent-trigger:new_postmortem (journaling) | 92 | 37 | 36 | partial |
| agent-trigger:loss_streak | 1 | 1 | 0 | 1 result |
| claude-e2e-verify | 1 | 0 | 0 | manual test row |

- **research lane closes autonomously:** `research-drainer.ts` runs in the prod worker, claims `role='research'` only (`:240`), calls the LLM, writes `agent_results` + `agent_artifacts`, marks done. evaluation→task→result is closed for research.
- **review/risk + journaling lanes do NOT close autonomously:** their consumers are *operator-launched local scripts* — `scripts/agent-review-runner.mjs` (role=review) and `scripts/firm/ralph.mjs` shield/atlas/prism panes — which only run when the operator starts the zellij firm-mirror. That's why 111 gate_spike + 55 journaling tasks sit **queued indefinitely**. The worker has no always-on review drainer.
- **task → implementation → verification is NOT in the loop at all.** No generated task produces a code change. No `role='code'` task came from a trigger (the 1 code row is `claude-e2e-verify`). Implementation happens entirely via the markdown/Karri path: Claude reads the analysis, writes a proposal, Karri approves, Claude implements, husky/tsc/tests verify. The "task" step for *changes* is a human improvising from the analysis output — the structured queue feeds diagnosis, not change-execution.

---

## Bottom line

- **Generator: EXISTS and is real** (data-driven, idempotent, audited, firing today). Not random, not assumption-based for the diagnosis layer.
- **Engineering-task fields: MISSING** (no acceptance criteria / test command / rollback / files-affected on generated tasks).
- **Closed loop: WEAK** — research arm closes; review/risk/journaling arms generate-then-stall (no prod consumer); the implementation+verification arm is entirely human/Claude via firm-bus markdown + KARRI-DISPATCH prose.
- The distinction the audit asked for: the **DB agent_tasks generator is genuine data-driven task generation** for *analysis*; the **firm-bus inbox + KARRI-DISPATCH docs are manual markdown coordination** that is what actually drives code/strategy changes. The two are not connected — a generated gate_spike task has never become a committed gate change through the queue.

## Cheapest fixes to raise WEAK→EXISTS

1. Add an always-on review/risk drainer in the worker (mirror research-drainer for `role IN ('review')`) so 166 queued tasks stop rotting.
2. Add an engineering-task trigger/template that emits `code`-role tasks carrying files-affected + test command + rollback (env flag) + acceptance criteria, so evaluation can mint *change* tickets, not just diagnoses.
3. Bridge agent_results → firm-bus inbox (or vice-versa) so the markdown layer the agents actually read is fed by the generated tasks instead of by hand.
