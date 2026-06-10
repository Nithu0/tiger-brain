# RISK_LEVEL_HARD_GATE — is it biting on LIVE trades? (verify)

Date: 2026-06-07 (data: nexus-pg read-only MCP + 443 pull + git on `2b2d2ce` live).
Mode: READ/VERIFY ONLY. No writes, no flips.

## TL;DR

- **risk_level_at_entry non-null now: 14.1% (28/199 stored rows).** UNCHANGED from the old ~14%. The backfill did **not** move the stored column.
- **Is the gate biting on LIVE trades? NO (cannot bite yet) — but NOT for the reason the column suggests.**
  - The gate flag IS live: Railway Worker `RISK_LEVEL_HARD_GATE_ENABLED=true`.
  - The gate logic reads riskLevel **inline at decision-time** and sees it populated (only 16/2082 evals had null riskLevel). So the gate *would* hard-reject when a cycle runs.
  - But **zero gate cycles have run since the flag was flipped.** Flag flip + PR #69 merge = 2026-06-05 22:18 CET. Last `risk_level` gate row = 2026-06-05 12:54 (before the flip). Market closed for the weekend since → no post-flip evidence at all.
- **Primary blocker to declaring it live-effective:** no live cycles since flip → `hard_rejected` count is still 0 across all 2082 rows. Re-verify on the next London/NY session (Mon 2026-06-08).
- **Secondary structural flag:** the LIVE entry-stamp fix (`ecbc73a`) is **NOT in production**. That's a lineage/audit-data problem (stored column stays starved), independent of whether the gate bites.

## 1. risk_level_at_entry population (stored column)

Table is `simulated_orders` (no `trades` table). `risk_level_at_entry` lives only there.

| scope | total | non-null | pct |
|---|---|---|---|
| all-time | 199 | 28 | **14.1%** |

By id-prefix (population path):

| path | total | non-null | pct |
|---|---|---|---|
| oanda_backfill_* (import) | 84 | 0 | **0%** |
| oanda_import_* (import) | 30 | 0 | **0%** |
| UUID rows (live firm-strategy) | ~73 | ~28 | ~35-40% |

**Old baseline was 14% (150/173 null). Now 14.1% (171/199 null). No change.**

Recent days (post-merge window) still mostly 0%: 2026-06-01 0/3, 06-02 1/3, 06-03 0/3, 06-04 1/5. The live path is still intermittently null and the import paths are flat 0%.

## 2. gate_decisions — is risk_level_hard_gate producing rejecting rows?

Gate name in DB is **`risk_level`** (not `risk_level_hard_gate`).

| metric | value |
|---|---|
| total rows | 2082 |
| would_reject | 1247 (~60%) |
| **hard_rejected** | **0** (always) |
| first / last | 2026-04-19 / **2026-06-05 12:54** |

riskLevel seen at gate-eval time (from context JSON, inline read — not the stored column):

| riskLevel | would_reject | count |
|---|---|---|
| high | true | 979 |
| elevated | true | 268 |
| normal | false | 819 |
| null | false | 16 |

So at decision-time the gate DOES have the signal (16/2082 = 0.8% null). It would_rejects ~60% of cycles. `hard_rejected=0` only because every persisted row predates the flag flip — code is `hardRejected = wouldReject && boolEnv("RISK_LEVEL_HARD_GATE_ENABLED", false)`.

Rows after flip (>= 2026-06-05 20:18Z): **0**. Last gate row is normal/normal, weekend gap follows.

## 3. The two population paths

- **Import path (PR #69, `b6f3919` oanda-sync `lookupRiskLevelAtTime`)** — IS in live (`2b2d2ce`). But oanda_import_* and oanda_backfill_* rows are **0% populated**. Either the backfill UPDATE never ran against existing rows, or `lookupRiskLevelAtTime` returns null (no `xauusd.analysis.risk` blackboard msg at-or-before historical fills). Either way: import rows remain NULL.
- **Live entry-stamp path (`strategy-execution.ts:859`)** — reads `xauusd.analysis.risk` with a **300s freshness window**. This is the exact bug `ecbc73a` ("cycle-ordering read window", widen 300→600) was written to fix: risk msg is published in Step 2, so Step 1f always reads the previous cycle's msg, aged > 300s in slow sessions → null. **`ecbc73a` is on `node-migration-nexus` only, NOT in main/live.** So the live entry-stamp is still starved → explains the ~35% live-row population and the stuck 14% overall.

## 4. Flag — is it flipped but effectively no-op?

**Flipped: yes** (`RISK_LEVEL_HARD_GATE_ENABLED=true` on Worker).
**Effective no-op right now: yes, but only because no cycles have run since the flip (weekend).** This is NOT the old "starved signal" no-op — the gate's inline riskLevel read is healthy (99.2% non-null at eval time). The gate is expected to start hard-rejecting ~60% of would-reject cycles on the next live session.

The stored-column starvation (14%) is a **separate, real problem** for trade lineage / audit / learning-loop attribution, and it persists because `ecbc73a` (live fix) isn't deployed and the import backfill produced 0%. It does NOT block the gate from biting.

## Recommended next checks (not actions)

1. **Mon 2026-06-08, after London open:** re-query `gate_decisions WHERE gate_name='risk_level' AND recorded_at >= '2026-06-05T20:18Z'` → expect `hard_rejected > 0`. That is the positive confirmation the gate bites live.
2. **Deploy gap:** `ecbc73a` (live entry-stamp 300→600 window) should land on main if operator/Karri want the stored column to reflect reality. Currently stranded on `node-migration-nexus`.
3. **Import backfill audit:** confirm whether `b6f3919`'s UPDATE was meant to backfill existing oanda_import_*/oanda_backfill_* rows (still 0%) or only new imports going forward.
