# 2026-05-11 — Retention / TTL design + implementation

**Status:** Code + tests + docs landed locally. **Default OFF** (`RETENTION_ENABLED=false`). NO push.

## What it does

Postgres-side once-per-UTC-day TTL pass for 4 unbounded-growth tables identified by the 2026-05-11 full-state audit:

| Table | Audit size | Policy |
|---|---|---|
| `blackboard` | ~342 MB | 30d volume topics, 90d analysis/other, permanent on audit allowlist |
| `sentiment_snapshots` | ~142 MB | 30d hot |
| `jobs` | ~21k rows | 7d done, 30d failed, pending/queued/running kept forever |
| `trade_strategy_snapshots` | ~17k rows | 90d |

Permanent blackboard topics: `xauusd.manager.decisions`, `xauusd.execution.reports`, `xauusd.execution.fills`, `xauusd.position.opened`, `xauusd.position.closed`, `xauusd.event.policy`, `xauusd.postmortem.reports`, `xauusd.journal.daily`.

## Implementation path

**Orchestrator self-check** (chosen over new firm-agent or Railway cron). Mirrors the existing `lastMemoryCleanupDate` Qdrant-cleanup pattern in `FirmOrchestrator`:

- New field `lastRetentionRunDate: string | null` on `FirmOrchestrator`.
- New step `0a2b` in `runCycle` (between Qdrant cleanup and the legacy 14d blackboard janitor): if `RETENTION_ENABLED=true` and `lastRetentionRunDate !== todayUtcIso`, fire `runRetentionAndReport(db, board)` (fire-and-forget — `catch` logs the error). Worker restart = at most one extra pass per day.

Why not a new firm-agent: firm-agents are budgeted (`FIRM_AGENTS_TICK_BUDGET_SEC`) and gated by LLM availability — overkill for 6 bounded DELETEs. Why not Railway cron: lives outside repo, hard to test, drift risk.

## Artifacts

- Module: `/home/nithu/code/ai-assistent/apps/worker/src/firm/retention.ts`
- Tests (15, all green): `/home/nithu/code/ai-assistent/apps/worker/src/firm/retention.test.ts`
- Wire-up: `/home/nithu/code/ai-assistent/apps/worker/src/firm/orchestrator.ts` (Step 0a2b)
- Env example: `/home/nithu/code/ai-assistent/.env.example` (lines under "Retention / TTL pass")
- Reference doc: `/home/nithu/code/ai-assistent/docs/ref/retention.md`
- Feature-flags row: `/home/nithu/code/ai-assistent/docs/ref/feature-flags.md`
- Topic registry: `/home/nithu/code/ai-assistent/docs/ref/blackboard-topics.md` (added `xauusd.retention.report`)
- CLAUDE.md pointer: added retention row in docs/ref table
- Canonical Obsidian doc: [[Retention-Policy]] (under `01-nexus/operations/`)

## Verification

- `cd apps/worker && npx tsc --noEmit` → clean.
- `npm test` (worker) → 443 tests pass, 0 fail (was 428; +15 from retention.test.ts).
- Isolated test run: `node --test --import tsx src/firm/retention.test.ts` → 15/15 green.

## Default state

- `RETENTION_ENABLED` defaults to `false` everywhere. The orchestrator self-check short-circuits without touching the DB.
- All 6 per-table TTL knobs default to the policy values (30/90/30/7/30/90) and accept env overrides.
- Per-table errors isolated — one failing DELETE does not block the others.
- Report published to `xauusd.retention.report` (advisory-only; operator-visible).

## Operator action

When ready to free storage (~200 MB blackboard, ~50 MB sentiment in steady state):

1. Read `docs/ref/retention.md` end-to-end.
2. Decide if any policy needs tuning (env knobs above).
3. Set `RETENTION_ENABLED=true` on the **Worker** service in Railway (the orchestrator runs in worker, not API).
4. First pass fires next cycle after activation. Look for `[firm/retention]` log line + `xauusd.retention.report` topic.
5. To roll back: set `RETENTION_ENABLED=false`. No redeploy needed.

## Commit

NOT yet committed locally (per instruction: code lands + report, operator gates push).

Suggested message:

```
feat(retention): TTL on blackboard / sentiment_snapshots / jobs / trade_strategy_snapshots

Default OFF (RETENTION_ENABLED=false). Operator flips on Railway when
comfortable.

Retention policy per table:
- blackboard: 30d on volume topics, 90d on analysis, permanent on decisions
- sentiment_snapshots: 30d
- jobs: 7d for done, 30d for failed, pending kept
- trade_strategy_snapshots: 90d

Runs once per UTC day via orchestrator self-check. Emits blackboard
'retention.report' with row counts.

Per operator-prinsipp #2 (data aldri stoppes — only old data trimmed)
and #3 (small cleanup adjustments can be automatic).
```

## Operator-prinsipper compliance

- **#2 (data skal aldri stoppes):** TTL is a row-level trim, not a feature disable. Fact-agents, analysis-agents, persistence layers continue writing — only old data is removed.
- **#3 (små ryddende justeringer kan være automatiske):** Once-per-day TTL is in this bucket. No money-impact change.
- **#5 (OK kjør-gate):** No push yet. Operator must say "OK kjør" before push. Activation on Railway is a separate operator decision.
