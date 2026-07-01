---
type: claude-inbox
project: nexus
date: 2026-05-11
status: applied
option: A
---

# Discord audit-trail — extend to research_note + review (NULL convention)

## Trigger

Post-deploy audit (post-c062696) showed 9 recent `agent_artifacts` rows with `discord_delivery_status = NULL`. Operator's concern: the column being NULL doesn't tell us whether Discord was "intended-but-skipped" vs "not applicable for this kind". Request: make semantics clear.

## Investigation findings

### What `discord-bridge.ts` actually does

`apps/worker/src/firm/agent-bus/firm-agents/discord-bridge.ts` exposes exactly three senders:

- `sendAdvisoryEmbed` — used by risk-advisor + agent-trigger + (unwired) macro-event
- `sendMorningBriefEmbed` — used by operator-brief (once-per-UTC-day)
- `sendTriggerEmbed` — used by agent-trigger high-priority path

Each writes `discord_delivery_status` ∈ `{sent, skipped_master_gate, skipped_legacy_gate, failed_<reason>}` via `recordDeliveryStatus()` when `(db, artifactId)` are provided. The bridge has no "is Discord intended" predicate — it's invoked-or-not by the caller.

### What kinds actually exist in `agent_artifacts`

Grepped every `INSERT INTO agent_artifacts` in `apps/worker/src/`:

| Kind | Source file | Routed through bridge? |
|---|---|---|
| `research_note` | `firm/agent-bus/research-drainer.ts:261` | no — DB-only |
| `plan` | `firm/agent-bus/firm-agents/strategy-tuner.ts:122` | no — DB-only |
| `journal` (daily-journal subtype) | `firm/agent-bus/firm-agents/daily-journal.ts:118` | no — DB-only |
| `journal` (morning-brief subtype) | `firm/agent-bus/firm-agents/operator-brief.ts:129` | yes (`sendMorningBriefEmbed`) |
| `trigger` | `firm/agent-bus/agent-trigger.ts:295` | yes (`sendTriggerEmbed` post-c062696) |
| `advisory` | `firm/agent-bus/firm-agents/risk-advisor.ts:180` | yes (`sendAdvisoryEmbed` post-c062696, `task_id IS NULL`) |

### The `review` "kind" doesn't live in agent_artifacts

`services/trade-review.service.ts:69` writes `agent_name='trade-reviewer', action='review'` into **`agent_events`**, not `agent_artifacts`. So "research_note + review" in the operator question is mixing two different tables. There is no `kind='review'` row in `agent_artifacts` to worry about.

## Decision: Option A

Document the convention. No schema/migration change.

Reasoning:
1. The artifact `kind` already encodes intent — `research_note`, `plan`, non-brief `journal` are by-design informational. Adding a `discord_intended` boolean (Option B) duplicates information the kind already carries.
2. Option B would require a migration + touching 5 INSERT call sites for a single boolean derivable from `kind`, with zero behavioural benefit.
3. The audit-query fix is one line: `WHERE discord_delivery_status IS NOT NULL`. No B-style column needed to write that query correctly.
4. Operator wording in the task explicitly says "Pick A unless operator has indicated they want more granularity" — no such indication.

## Files touched

- `packages/shared/src/db/schema.ts` (~line 1273) — extended the comment block above the `ALTER TABLE … discord_delivery_status` migration with the per-kind NULL convention table.
- `~/.claude/projects/-home-nithu-code-ai-assistent/memory/project_discord_delivery_dual_gate.md` — appended "NULL discord_delivery_status convention" section with kind-mapping table and audit-query rule.
- `Brain/01-nexus/runtime-state/discord-delivery-state.md` — added "NULL convention (2026-05-11)" section with the same table + the agent_events vs agent_artifacts clarification.

## Verification

- `cd packages/shared && npx tsc --noEmit` → clean. (Schema is pure SQL strings inside JS, comment-only change.)
- No code-path changes. No migration to apply. No tests to update.

## Commit SHA

Not committed in this session — no "OK kjør"-gate from operator yet, per operator-prinsipp 5. Changes are local + memory + Obsidian only.

## Audit-query rule to remember

When asked "how is Discord delivery doing in the last 24h?":

```sql
SELECT kind, discord_delivery_status, COUNT(*)
FROM agent_artifacts
WHERE created_at > NOW() - INTERVAL '24 hours'
  AND discord_delivery_status IS NOT NULL
GROUP BY 1, 2 ORDER BY 1, 2;
```

NULL rows are informational and should be excluded from delivery-health rollups. If a post-c062696 `advisory` / `trigger` / morning-brief `journal` row appears as NULL, that's an instrumentation gap (currently only `macro-event.ts` qualifies — tracked in the living-state doc).

## Follow-up (out of scope here)

`macro-event.ts → sendAdvisoryEmbed` still misses `(db, artifactId)` threading; living-state doc tracks it. Operator may want a follow-up two-line fix once that path fires more frequently.
