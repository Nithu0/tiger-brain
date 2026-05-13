---
date: 2026-05-13
type: audit
project: nexus
status: open
---

# Blackboard AUDIT_ALLOWLIST mismatch — wiring gaps

## TL;DR

`BLACKBOARD_AUDIT_ALLOWLIST` in `apps/worker/src/firm/orchestrator.ts:72-80` whitelists 7 topics from the 14-day TTL pruning pass. Three of them have **never had a row written in production** because no publisher exists anywhere in the repo. One real-write topic (`xauusd.position.events`, 42 lifetime rows) is **NOT** on the allowlist and will be pruned by retention — that's the actual audit gap.

## Allowlist (orchestrator.ts:72-80)

```ts
const BLACKBOARD_AUDIT_ALLOWLIST = [
  "xauusd.execution.reports",
  "xauusd.execution.fills",
  "xauusd.position.opened",
  "xauusd.position.closed",
  "xauusd.event.policy",
  "xauusd.postmortem.reports",
  "xauusd.journal.daily",
] as const;
```

## Lifetime counts (prod blackboard, 2026-05-13)

| Topic | Lifetime | Last write | Publisher in code? |
|---|---:|---|---|
| `xauusd.event.policy` | 3,089 | 2026-04-24 | `managers.ts:435` (conditional) |
| `xauusd.postmortem.reports` | 210 | 2026-05-12 | `postmortem.ts:553` |
| `xauusd.execution.reports` | 176 | 2026-05-12 | `strategy-execution.ts:892`, `managers.ts:1059` |
| `xauusd.journal.daily` | 1 | 2026-05-12 | `agent-bus/firm-agents/daily-journal.ts:129` |
| `xauusd.execution.fills` | **0** | — | **none** |
| `xauusd.position.opened` | **0** | — | **none** |
| `xauusd.position.closed` | **0** | — | **none** |

Searched whole `apps/` tree — the three zero-row topics appear ONLY in:
- `orchestrator.ts` allowlist
- `retention.ts:70-72` (AUDIT_ALLOWLIST mirror)
- `retention.test.ts:145-150` (tests asserting they are skipped)

No `board.publish({ topic: "xauusd.position.opened", ... })` anywhere. Dead expectations.

## Four-category classification (allowlist members)

- **WRITING + ALLOWED (4):** `execution.reports`, `event.policy`, `postmortem.reports`, `journal.daily` — working as designed
- **NOT-WRITING + ALLOWED (3):** `execution.fills`, `position.opened`, `position.closed` — dead expectations
- **WRITING + NOT-ALLOWED (1, sampled):** `xauusd.position.events` (42 rows, last 2026-05-12) — **real audit gap**: lifecycle events (break-even, partials, trailing, stale) will be pruned at 14 days
- **NOT-WRITING + NOT-ALLOWED:** out of scope (no signal)

`event.policy` stale since 2026-04-24 despite an active publisher — code path is conditional on `computeEventPolicy` returning a publish-worthy state. Not a wiring gap, but worth a separate note.

## Doc consistency check vs `docs/ref/blackboard-topics.md`

- Doc lines 21-23 explicitly mention all three zero-row topics as "on `BLACKBOARD_AUDIT_ALLOWLIST`" — doc reflects intent, not reality
- Doc line 24 documents `xauusd.position.events` as the live intra-trade lifecycle topic but does NOT flag that it is missing from the allowlist
- Doc is internally consistent with the allowlist code but **silent about the producer gap**

## Recommendation

### REMOVE from allowlist (admit they don't fire)

Lowest-risk move. The position lifecycle is already covered by:
- `xauusd.execution.reports` (entry/exit) — 176 lifetime, actively written
- `xauusd.postmortem.reports` (closed-trade analysis) — 210 lifetime, actively written
- `positions` table (durable, indexed) — primary truth source

Remove `execution.fills`, `position.opened`, `position.closed` from both `orchestrator.ts:72-80` and `retention.ts:70-72`. Update doc lines 21-23. Trim `retention.test.ts:145-150`.

### ADD to allowlist (close real audit gap)

`xauusd.position.events` — intra-trade lifecycle (break-even / partials / trailing / stale exits). Publisher at `position-management/manager.ts:324`. 42 lifetime rows would currently be pruned at 14 days. Adding this is a one-line change with material observability value for postmortem reconstruction.

### Alternative: WIRE the missing publishers

Only worth doing if there's a downstream consumer plan (e.g., a fills-table reconciliation agent). No such consumer exists in the repo today. Defer until/unless a consumer materializes — wiring without a consumer just adds rows nobody reads.

### Suggested PR scope (single focused diff)

1. Drop `execution.fills`, `position.opened`, `position.closed` from both allowlist arrays
2. Add `xauusd.position.events` to both allowlist arrays
3. Update `docs/ref/blackboard-topics.md` lines 21-24 to reflect the new state
4. Update `retention.test.ts:145-150` assertions
5. No producer wiring (no consumer to justify it)

Net effect: retention pass becomes truthful, intra-trade lifecycle gets durable audit trail, no behaviour change in the trading loop.

## Files touched (if approved)

- `apps/worker/src/firm/orchestrator.ts:72-80`
- `apps/worker/src/firm/retention.ts:70-72`
- `apps/worker/src/firm/retention.test.ts:145-150`
- `docs/ref/blackboard-topics.md:21-24`

## Status

Open — proposal-only; no implementation. Strategy/risk review **not** required (this is observability + audit infra, not money-impact). Operator decision: remove + add (recommended), or hold for a wider consumer-planning pass.
