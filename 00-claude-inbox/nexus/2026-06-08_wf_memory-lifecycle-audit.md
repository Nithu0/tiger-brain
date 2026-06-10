# WF lane: memory-lifecycle-audit (READ-ONLY)

Date: 2026-06-08
Agent: ai-lane worker (read-only diagnosis)
Scope: memory lifecycle (docs/memory) + runtime retention/TTL (RETENTION_ENABLED=true is LIVE on Worker — verified via `railway variables --service Worker`)

## TL;DR

One real data-safety bug (P1) and several doc/test gaps. The retention DELETE-pass itself is well-built: bounded, idempotent, per-table error-isolated, never throws into the trading loop. But the **older, ungated 14d blackboard janitor is silently deleting `xauusd.manager.decisions` — the firm's most audit-critical topic (Blade PROPOSAL + final DECISION records) — after 14 days, in production, right now.** The retention module protects it; the janitor does not; and the drift test only checks the retention copy, so the divergence is invisible to CI.

DB-side confirmation of actual truncation is BLOCKED — the network firewall blocks the nexus-pg MCP (EHOSTUNREACH on :58688), and no 443 endpoint exposes per-topic row counts or table sizes. Code-level evidence is conclusive on its own; live confirmation needs either operator-run SQL or a new diagnostic endpoint (see gaps).

## Three distinct memory/retention layers (don't conflate)

1. **docs/memory/** — markdown knowledge buckets (RAW→DISTILLED→PROMOTED→DEPRECATED→ARCHIVED). The thing docs/memory/README.md describes.
2. **Qdrant vector memory** — runtime semantic recall, pruned by `cleanupOldMemories` (orchestrator Step 0a2).
3. **Postgres row retention** — `retention.ts` (Step 0a2b) + the 14d blackboard janitor `runBlackboardTtlCleanup` (Step 0a3).

---

## Layer 1: docs/memory lifecycle — documented vs enforced

- Buckets all exist on disk: `promoted/ deprecated/ archive/ daily/` + `_index.md PROMOTE_QUEUE.md DEPRECATED.md README.md`.
- **Enforcement = zero code.** No distiller/archiver runs the RAW→DISTILLED→ARCHIVED flow. The only touch-points are shell hooks (`scripts/hooks/distill.sh`, `session-start.sh`) and the README itself says "Scaffolding only as of 2026-05-08. Distillation hook is **not** activated." This matches operator-prinsipp 1 (no auto-activation) — so it's *intended* to be manual, not a bug. But the "Archive after 30 days idle" / "deprecate don't delete" rules are honor-system only; nothing enforces or even reports staleness for these buckets except the session-start hook's oldest-file list.
- **No data-safety risk here** — it's docs, append/move only, no automated delete.

Verdict: documented lifecycle is aspirational/manual. Fine per principle 1. Gap = no enforcement and no drift between doc and reality beyond "not activated."

---

## Layer 2: Qdrant TTL (`cleanupOldMemories`) — SAFE

`apps/worker/src/services/memory.service.ts:572`, wired at orchestrator.ts:306 (`minImportance:5, olderThanDays:30`), once/UTC-day, firm_state-guarded (survives restart).

- Deletes only `importance < 5 AND createdAt < 30d`. Trade-reviews/postmortems are written at importance>=5 → never touched (comment + code agree).
- Bounded: 256-page cap (~65k points/run), explicitly "janitor, not bulk wipe."
- Delete happens AFTER the full scroll completes (ids collected, then one batch delete) — no offset-shift / scroll-during-mutation hazard.
- Fails non-fatal (try/catch, returns instead of throwing). Disabled-safe (`memoryDisabled` / no client → no-op).

Verdict: bounded + safe. No action.

---

## Layer 3: Postgres retention — the bug lives here

### 3a. retention.ts (Step 0a2b) — well-built, LIVE

`apps/worker/src/firm/retention.ts`, gated `RETENTION_ENABLED===\"true\"` (CONFIRMED true on Worker), once/UTC-day via `RETENTION_STATE_KEY` firm_state guard + in-flight Set.

Strengths:
- 6 DELETEs, each own try/catch — one failing doesn't block the rest; errors collected into `errors[]`, logged, published to `xauusd.retention.report`.
- All WHERE clauses are bounded by an indexed time column (`timestamp`/`recorded_at`/`finished_at|queued_at`/`captured_at`). No full-table scan, no unbounded delete.
- jobs DELETE only targets `status IN ('completed','failed')` — never queued/pending/running. Plus FK-safety `NOT EXISTS (bot_runs)` so a referenced row can't abort the whole DELETE (lossless: ages further, next pass retries).
- blackboard DELETEs carry a defense-in-depth `topic NOT IN (permanent)` even on the volume branch.
- Config env-overridable; non-positive/non-numeric falls back to defaults.
- Never throws into runCycle (`.catch` in the wire-up + internal guards).

No data-safety risk in retention.ts as written. It correctly protects `xauusd.manager.decisions` via `BLACKBOARD_PERMANENT_TOPICS`.

### 3b. P1 BUG — 14d janitor deletes manager.decisions

`runBlackboardTtlCleanup` (orchestrator.ts:857), Step 0a3, runs **every 100 cycles with NO env gate** (always on in prod). It spares only `BLACKBOARD_AUDIT_ALLOWLIST` (orchestrator.ts:78):

```
execution.reports, position.events, event.policy,
postmortem.reports, journal.daily, signal.rejected
```

`xauusd.manager.decisions` is NOT in that list. It IS in the retention.ts list (`BLACKBOARD_PERMANENT_TOPICS`) and IS listed audit-grade in docs/ref/blackboard-topics.md ("Blade proposals + final decisions"). It has 5+ active publishers (strategy-execution.ts:801/1213/1266, managers.ts:356/628, orchestrator.ts:701) and is published with **no `expiresInSeconds`** → its only lifetime control is this janitor.

Consequence: **manager.decisions rows older than 14 days are deleted in production today.** This is the canonical record of what every trade was and why (PROPOSAL + DECISION). It is read back by postmortem.ts:96 (50 rows / 1h window — short window survives) but any retrospective/attribution analysis beyond 14 days has been losing its decision provenance. Directly contradicts docs/ref/retention.md which lists `manager.decisions` on the permanent allowlist.

Severity P1 (silent, ongoing, audit-grade data loss; not money-loss, not reversible once deleted).

### 3c. Why CI didn't catch it — test gap

`retention.test.ts:139` "audit-grade allowlist matches blackboard-topics.md set" asserts against `BLACKBOARD_PERMANENT_TOPICS` (the retention copy — which is correct). It **never imports or asserts the orchestrator's `BLACKBOARD_AUDIT_ALLOWLIST`.** The comment claims it guards "the orchestrator allowlist and retention allowlist have drifted" but it structurally cannot — it only sees one of the two lists. So the two copies silently diverged. `BLACKBOARD_AUDIT_ALLOWLIST` is not exported from orchestrator.ts, which is likely why the test author mirrored instead of imported.

### 3d. Doc drift

docs/ref/retention.md "Audit-grade allowlist" section lists `manager.decisions, execution.reports, execution.fills, position.opened, position.closed, event.policy, postmortem.reports, journal.daily`. Neither code list matches this:
- `execution.fills, position.opened, position.closed` were intentionally removed (no prod publisher — retention.test.ts:157-159 asserts their absence). Doc still lists them.
- `position.events` (the real live topic) is in both code lists but NOT in the doc's allowlist section (it appears elsewhere in the doc).
- `manager.decisions` is in the doc + retention code but missing from the orchestrator janitor (the bug).
- `signal.rejected` is in the orchestrator list + volume-topics but not the doc's allowlist section.

So docs/ref/retention.md is stale on 4 of 8 entries.

---

## Stale / unbounded growth tables

retention.ts covers blackboard, sentiment_snapshots, jobs, trade_strategy_snapshots (the 4 from the 11.5 audit). Tables I could NOT confirm are bounded (no DB access; flag for follow-up):
- `agent_lessons` (firehose) — docs say dormant/OFF; no DELETE/TTL found. Append-only learning store; verify growth once firehose is active.
- `market_snapshots`, `ohlcv_candles`, `news_headlines`, `reddit_subreddit_snapshots`, `analysis_snapshots` (raw-data-persistence, RAW_DATA_PERSIST_ENABLED default true) — all append-only, NONE have any retention policy. These are the live training-data tables and will grow unbounded. Per operator-prinsipp 2 that may be intentional (data never stopped), but there's no archival/compression plan and no size telemetry. `market_snapshots` (price + full indicator set every cycle, ~56 cycles/h) is the likely fastest grower.

Could not measure actual sizes — firewall blocks nexus-pg MCP, and no 443 endpoint returns table sizes / per-topic counts.

---

## Recommendations (no code changed — read-only lane; ai-1 owns indicator code, I touched nothing)

P1 fix (behaviour-neutral, BUILD candidate for a separate branch — NOT done here, coordinate so it doesn't collide):
1. Add `xauusd.manager.decisions` to `BLACKBOARD_AUDIT_ALLOWLIST` in orchestrator.ts. This is a pure audit-protection add (stops deleting, deletes nothing extra) — arguably a bug-fix restoring intended behaviour per docs, not a strategy change, so no Karri gate. But it touches the trading orchestrator file; do it on `fix/wf-retention-allowlist` with the existing husky/test gate.
2. Export `BLACKBOARD_AUDIT_ALLOWLIST` from orchestrator.ts and make retention.test.ts assert it equals (or is a documented superset/subset of) `BLACKBOARD_PERMANENT_TOPICS`, so the two can't silently drift again. Note they legitimately differ on `signal.rejected` (janitor-spares it; retention treats it as 30d volume) — encode that exception explicitly.
3. Sync docs/ref/retention.md allowlist section to actual code (drop execution.fills/position.opened/position.closed, add position.events, reconcile signal.rejected).

P2 / data-observability (closes the verification gap this audit hit):
4. Add a `/diagnostic/table-sizes` (or extend `/health`) endpoint returning `pg_total_relation_size` per table + per-topic blackboard counts, so retention can be verified over 443 without DB access. Without it, nobody can confirm retention is working from this network.
5. Decide a policy for the 6 raw-data-persistence tables (retention or explicit "grow forever + size alert"). At minimum a size-growth alert.

## Verification gaps (could not confirm live)
- Actual current row count / oldest timestamp of `xauusd.manager.decisions` (would prove the 14d truncation empirically). Needs operator SQL: `SELECT min(timestamp), count(*) FROM blackboard WHERE topic='xauusd.manager.decisions';` — if min is ~14d old, bug confirmed live.
- Actual table sizes vs the 11.5 audit numbers (is retention keeping blackboard/sentiment flat now that it's ON?). `xauusd.retention.report` topic carries delete counts but is not exposed over 443.
