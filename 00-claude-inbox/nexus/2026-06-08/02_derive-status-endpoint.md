# derive-status endpoint + derive-lessons crash hypotheses

Date: 2026-06-08
Branch: main (no commit/push — operator handles git/PR)
Verify: `cd apps/api && npx tsc --noEmit` → exit 0; `npm test` → 32 pass / 0 fail (4 new firehose tests).

## What I built

New read-only route `GET /firehose/derive-status` in
`apps/api/src/routes/firehose.ts`. Surfaces the nightly derive-lessons run
markers from `firm_state` so a crash becomes pullable over 443 without DB or
Railway-log access (nexus-pg MCP is dead / EHOSTUNREACH).

### Query

```sql
SELECT key, value, updated_at
  FROM firm_state
 WHERE key LIKE 'firehose:derive_lessons:%'
 ORDER BY updated_at DESC
 LIMIT $1            -- default 7, clamped 1..30 via ?limit=
```

Returns BOTH success markers (`firehose:derive_lessons:<date>`) and failure
markers (`firehose:derive_lessons:<date>:failed`, whose `value.stderrTail`
holds the redacted crash tail written by PR #76).

### Response shape

```jsonc
{
  "ok": true,                       // false on DB error (fail-safe, never 500)
  "rows": [ { "key", "value", "updated_at" }, ... ],   // newest first
  "failures":  [ ...rows ending in :failed ],          // incl value.stderrTail
  "successes": [ ...success rows ],
  "latestSuccessDate": "2026-05-21" | null,            // parsed from key
  "latestSuccessAt":   "<iso ts>"   | null,
  "failureCount": 1,
  "successCount": 1
}
```

`value` is the raw JSONB from the marker. For a failure that is
`{ at, exitCode, stderrTail }` (subprocess non-zero exit) or
`{ at, spawnError }` (spawn-level error) — see
`apps/worker/src/index.ts:285-310`.

Mirrors the existing firehose.ts handler style + the `/calibration/status`
fail-safe (try/catch → neutral payload, `req.log.warn`, never 500). Auth is
the global Bearer hook (verified: unauthenticated → 401).

### Test

`apps/api/src/routes/firehose.test.ts` — 4 tests, registered in
`apps/api/package.json` test script:
- unauthenticated → 401
- firm_state absent (thrower) → 200 neutral, ok:false, never 500
- **failed marker WITH stderrTail returned + latest-success date parsed** (the
  key assertion — asserts `failures[0].value.stderrTail` survives intact and
  `latestSuccessDate === "2026-05-21"`)
- no rows → ok:true, latestSuccessDate null

## No new secret exposure (confirmed)

The `stderrTail` is redacted at WRITE time by `sanitizeStderrTail`
(`apps/worker/src/firm/firehose-error-capture.ts`) — strips DSNs / user:pass /
bearer tokens / rlwy hosts / `*_PASSWORD|SECRET|TOKEN|API_KEY|DATABASE_URL=`
assignments — BEFORE it lands in firm_state. The endpoint returns exactly what
was persisted; it adds NO new fields and NO un-redacted source. `value` is the
already-sanitized JSONB. Net new exposure: none.

## Top-3 crash hypotheses (from code alone)

Context that reframes the priors:
- **There is NO `RecoverableFetchError` anywhere in `scripts/firehose/`.** The
  deriver has no resilient-retry / recoverable-error layer at all. Any
  unhandled throw in `main()` falls straight through to
  `derive-lessons.mjs:294-297` → `process.exit(1)`.
- **The embeddings/Ollama hypothesis is ruled out** — the derive path imports
  only `pg`, `node:crypto`, `./lib/fingerprint.mjs`, `./lib/canonicalize.mjs`,
  `./auto-promote-lessons.mjs`. No `fetch`, no Ollama, no `embeddings.mjs`.
  Embeddings live in a *separate* script (`embed-pending.mjs`), never called
  here.
- **Not a recent-PR regression.** Last lesson = 2026-05-21, but the per-role
  fingerprint (`3a37500`) and auto-promotion (`d991310`) landed 06-06/06-07 —
  AFTER crashes began. And `a47800b` (2026-05-21) explicitly says "Diagnosing
  why agent_lessons stayed 0 rows took a full investigation" → the deriver was
  ALREADY failing on/before 05-21. This is a long-standing unguarded runtime
  throw, not a code change.
- The import chain has no top-level side effects that throw, so the crash is a
  RUNTIME throw inside `main()`, on one of the THREE unguarded await surfaces.

### #1 — DB connect failure (most likely): `client.connect()`
`scripts/firehose/derive-lessons.mjs:230-231`
```js
const client = new Client({ connectionString: url });
await client.connect();      // UNGUARDED — outside the try/finally below
```
`connect()` is awaited *before* the `try {` on line 232, so any auth / TLS /
host-unreachable / role error throws straight to the top-level
`.catch → exit(1)`. The subprocess inherits the worker's env
(`apps/worker/src/index.ts:257` `env: { ...process.env }`), so it uses the
worker's `DATABASE_URL`. If the deployed deriver runs as a lower-privilege role
(the grants.sql narrative provisions `claude_readonly` with INSERT/UPDATE on
agent_lessons), a `pg_hba` / `password authentication failed` / SSL-required
mismatch here is the single most plausible non-recoverable exit-1. The redacted
stderrTail from this endpoint will show the pg error code (e.g. `28P01`,
`28000`, `08006`) and confirm.

### #2 — `fetchClusters()` SQL throw: the cluster SELECT
`scripts/firehose/derive-lessons.mjs:78-100`, called unguarded at
`derive-lessons.mjs:233` (inside try/finally, but the catch only does
`client.end()` then re-throws → exit-1).
All selected columns DO exist in
`packages/shared/src/db/schema.ts` (`simulated_orders.pnl` L82,
`portfolio_regime_at_entry` L683, `session_at_entry` L490, `close_reason`
L470, `closed_at`, `market`, `status`). So it's NOT a missing-column typo.
The remaining SQL-side failures that throw here: insufficient SELECT privilege
on `simulated_orders` for the deriver's role (grants.sql only GRANTs SELECT if
the table already existed at grant time), or a `numeric` cast error from
`COALESCE(SUM(pnl),0)::float` on poisoned/overflow pnl rows. stderrTail will
carry the SQLSTATE.

### #3 — INSERT constraint / privilege throw on the FIRST proposed row
`proposeLesson()` `scripts/firehose/derive-lessons.mjs:181-209`.
NOTE: the per-row call IS wrapped (`try/catch` at
`derive-lessons.mjs:252-260`) and the catch only logs `err.message` — so a
*single* bad INSERT would NOT exit-1. BUT this is the #3 candidate because:
(a) if the deriver role lacks INSERT on `agent_lessons` / USAGE on
`agent_lessons_id_seq` (grants.sql:31-54 skip silently when the table/seq
didn't exist at grant time), every INSERT throws → 0 rows written but exit 0
(would look like "ran clean, no lessons"), which does NOT match an exit-1; so
the exit-1 must come from #1/#2, and #3 explains the *secondary* symptom
(agent_lessons frozen even on a clean run). The CHECK constraints
(`lesson_type_chk`, `lesson_status_chk`, `outcome_score NUMERIC(5,3)` range
±99.999 vs computed [-1,1], `confidence NUMERIC(4,3)` vs ≤0.95) all pass for
derived values — not the cause.

**Ranking:** #1 (connect, unguarded, pre-`try`) is the prime suspect for the
literal exit-1; #2 is the next unguarded surface; #3 explains the "agent_lessons
stays 0" symptom even when no exit-1. The pulled `stderrTail` (now exposable via
this endpoint) will disambiguate via the pg error code/line — the top-level
catch logs `"[derive-lessons] fatal:", err` (full stack at
`derive-lessons.mjs:295`), so the tail should pinpoint connect vs query vs
insert.

## Operator next step

After merge + deploy: `curl -H "Authorization: Bearer $API_KEY"
https://api-production-b660.../firehose/derive-status` → read
`failures[0].value.stderrTail`. The first `at /app/scripts/firehose/...:<line>`
frame + the pg `code` will tell us which of the three it is. Then fix the
actual cause (likely a role/grant or DSN-mismatch fix, NOT a code change).
