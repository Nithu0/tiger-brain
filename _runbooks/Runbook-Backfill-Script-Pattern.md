---
type: runbook
trigger: a backfill / one-shot data-fix script is needed (recompute historical metric, repair NULL column, etc.)
autonomy_level: fix-locally (dry-run) / operator-OK (commit run)
---
# Runbook: Backfill-Script-Pattern

How to write and run a one-shot data-modification script safely. Backfills are explicitly NOT strategy changes (they recompute with already-shipped logic), so they don't need Karri — BUT they touch live DB, so dry-run + CONFIRM=YES is mandatory.

## Script structure (canonical)
File path: `scripts/backfill/YYYY-MM-DD_<slug>.ts` or `.mjs`.

Required envelope:
```typescript
// 1. DATABASE_URL inline at top, not from env, prevents accidental run against wrong DB
const DATABASE_URL = process.env.NEXUS_BACKFILL_DB_URL;
if (!DATABASE_URL) {
  console.error("Set NEXUS_BACKFILL_DB_URL explicitly. Do not use DATABASE_URL.");
  process.exit(1);
}

// 2. CONFIRM=YES gate
const CONFIRM = process.env.CONFIRM === "YES";
const DRY_RUN = !CONFIRM;
console.log(`Mode: ${DRY_RUN ? "DRY-RUN" : "COMMIT"}`);

// 3. Print scope before touching anything
const scope = await client.query("SELECT count(*) FROM <table> WHERE <predicate>;");
console.log(`Scope: ${scope.rows[0].count} rows`);

// 4. Sample 5 rows pre-change
const sample = await client.query("SELECT ... LIMIT 5;");
console.table(sample.rows);

// 5. Per-row update, transactional in batches of 100
for (const batch of batches) {
  if (DRY_RUN) {
    console.log(`Would update: ${batch.map((r) => r.id).join(",")}`);
    continue;
  }
  await client.query("BEGIN");
  try {
    for (const row of batch) await client.query("UPDATE ...", [row.id, row.newVal]);
    await client.query("COMMIT");
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  }
}

// 6. Verify post-change
const after = await client.query("SELECT count(*) FROM <table> WHERE <predicate>;");
console.log(`After: ${after.rows[0].count} rows (should be 0 if predicate was 'needs-fix')`);
```

## Run sequence
1. **Write script** + commit at `scripts/backfill/`.
2. **Dry-run**:
   ```bash
   NEXUS_BACKFILL_DB_URL='<prod-url>' npx tsx scripts/backfill/YYYY-MM-DD_<slug>.ts
   ```
   Prints scope + sample + "Would update" lines. ZERO writes.
3. **Inspect dry-run output** with operator. Confirm scope matches expectation. **Do not skip.**
4. **Commit run** — operator-OK required (strategy-touch? no, but money-impact via data correction → flag):
   ```bash
   CONFIRM=YES NEXUS_BACKFILL_DB_URL='<prod-url>' npx tsx scripts/backfill/YYYY-MM-DD_<slug>.ts
   ```
5. **Verify post-state**: re-query the predicate, should return 0 rows needing fix.
6. **Commit the script** + the run log (redacted) at `docs/ops/backfills/YYYY-MM-DD_<slug>-runlog.md`.

## What never auto-fires
- Skipping dry-run. EVER.
- Running with `CONFIRM=YES` from a script Claude wrote and operator hasn't seen dry-run output for.
- Using ambient `DATABASE_URL` env. Always explicit env name (`NEXUS_BACKFILL_DB_URL`) to prevent muscle-memory accidents.
- Running on a DB other than the one operator named in the session.
- Bulk DELETE without operator-OK on the specific predicate.

## Examples from past sessions
- **Strategy-ID backfill (2026-05-11)**: 28 trades with NULL `strategy_id`. Dry-run confirmed scope. Operator-OK. Commit run. Verified 0 rows remaining. See `00-claude-inbox/nexus/2026-05-11-strategy-id-backfill.md`.
- **Pattern enforced**: every backfill in `scripts/backfill/` follows this envelope. New ones should match.

## Linked
[[Operator-Principles]] · [[MCP-nexus-pg-rw]] · [[Decision-No-Auto-Activation]] · [[Runbook-Post-Deploy-Verification]] · [[When-Doc-Drifts-From-Code]] · [[Truth-Hierarchy]] · [[Foundation-Gate]] · [[local-mirror-safety-state]]
