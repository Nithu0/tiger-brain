---
title: Local test failures diagnosis — 2026-05-25
date: 2026-05-25
status: v1.0 (investigation)
purpose: Diagnose 14 local test failures not present in CI
related: [[test-summary-2026-05-25]], [[SPRINT-1-COMPLETE-2026-05-25]]
tags: [diagnosis, tests, local]
---

# Local test failures — investigation

## Symptom

Per M-7 report: ~14 tests fail locally on `npm test` but NOT in CI (CI shows
GREEN per PR runs). Affected files all live under `apps/api/src/routes/`.

Reproduced against `main` (HEAD `7cd4059`) with Node v24.15.0.

## Files affected (observed counts)

| File | Tests | Failed | Passed | Skipped |
|---|---|---|---|---|
| `apps/api/src/routes/devflow.test.ts`       | 12 | 0 (suite-level error before run) | 0 | 12 |
| `apps/api/src/routes/commands.rights.test.ts` | 11 | 11 | 0 | 0 |
| `apps/api/src/routes/orchestrator.test.ts`    | 8  | 3 (the 3 that hit DB) | 5 | 0 |

Total = **14 test-level failures** + **1 suite-level error** + **1 cascading
afterAll error** in devflow (`app.close()` on undefined because `beforeAll`
crashed). Matches the M-7 "14" figure.

## Root cause (high confidence)

**`better-sqlite3@11.10.0` native binding is missing for Node v24.15.0.**

Direct repro outside vitest:

```
$ node -e "const D = require('better-sqlite3'); new D(':memory:')"
Error: Could not locate the bindings file. Tried:
 → .../node_modules/better-sqlite3/build/Release/better_sqlite3.node
 → .../node_modules/better-sqlite3/lib/binding/node-v137-linux-x64/better_sqlite3.node
 ... (and 11 other paths)
```

- `require()` of the JS module succeeds.
- `new Database()` calls `bindings()` which looks for the compiled `.node`
  file — none exists anywhere in the tree (`find node_modules/better-sqlite3
  -name "*.node"` → empty).
- `node-v137` is Node 24's NODE_MODULE_VERSION. The package ships
  prebuilds keyed by ABI; no prebuild matched for v24.
- `npm install` completed without error but skipped the native rebuild
  silently (probably the prebuild fetch 404'd and `npm` swallowed the
  postinstall failure with `--silent` / no audit).

### Why this produces the observed failure modes

| Test file | Failure shape | Why |
|---|---|---|
| `devflow.test.ts` | Suite-level `Error: Could not locate the bindings file` thrown in `beforeAll` → all 12 tests skipped, `afterAll` then crashes on `app.close()` (app is undefined) | DB init happens synchronously in `beforeAll` via `db()` import. Native binding miss = throw. |
| `commands.rights.test.ts` | All 11 tests fail with `expected 500 to be <2xx/4xx>` and `expected undefined to be 'nithu'` | Fastify wraps the binding error from the route handler in a 500 reply. Route never gets to insert/select, so response body has no `proposedBy`. |
| `orchestrator.test.ts` | 3 DB-using tests fail with `expected 500 to be 200`; 5 pure-validation tests pass | GET `/api/terminals/roles` (filesystem only) + 400-validation tests work; only the dispatch tests that write to `commands` table hit the binding. |

## Hypotheses considered

### H1: SQLite state corruption (REJECTED)

- `data/command-center.db-wal` is 4.0 MB vs main DB 86 KB — superficially
  suspicious — but irrelevant: the failing tests use `process.env.DB_PATH =
  mkdtemp(...)` for isolated DBs. They never touch `data/`.
- A fresh tmp DB exhibits the same failure as the live DB → not state.

### H2: Concurrent test side-effects (REJECTED)

- Each test file's `beforeAll` creates its own `os.tmpdir()` subdir. No
  shared fixture between failing suites.
- Failures reproduce when run individually (`vitest run <one-file>`).

### H3: Environment difference (CONFIRMED — Node ABI mismatch)

- CI: `.github/workflows/test.yml` pins `node-version: '20'` → matches one
  of the better-sqlite3 prebuilds → works.
- Local: `node --version` → `v24.15.0`. No `.nvmrc` / `.node-version` in
  repo. No prebuild ships for v24, and the postinstall didn't rebuild.

## Why CI doesn't see it

CI checks out clean, `actions/setup-node@v4` installs Node 20, `npm ci`
downloads the prebuilt better-sqlite3 binary matching Node 20's ABI
(`node-v115-linux-x64` region), and tests run green. There is no
"accumulated cruft" — purely a host-Node-version delta.

## Fix recommendation

Auto-fixable, no operator approval needed. Two options, in order of
robustness:

1. **Rebuild against current Node** (one-time fix until next Node upgrade):

   ```
   cd /home/nithu/code/command-center
   npm rebuild better-sqlite3
   ```

   Requires `python3` + `make` + a C++ toolchain on WSL (operator likely
   already has these; if not: `sudo apt install build-essential python3`).

2. **Pin Node to 20 locally to match CI** (eliminates the drift class):

   ```
   echo "20" > .nvmrc        # commit this
   nvm use 20                # or fnm / asdf equivalent
   rm -rf node_modules package-lock.json
   npm install
   ```

   This is the preferred long-term fix because it removes a whole category
   of "works on CI, broken locally" surprises (Node 24 also affects other
   native deps the project may add later — `chokidar`'s native fsevents
   shim, `pg`'s optional native binding, web-push's crypto).

The 4 MB WAL file in `data/` is unrelated to the test failures but is also
worth a `rm -rf data/*.db data/*.db-wal data/*.db-shm` later — it's just
journal cruft from dev-server runs.

## Cleanup approach

- `npm rebuild better-sqlite3` → fixes the 14 failures immediately
- `echo 20 > .nvmrc && commit` → prevents recurrence on next Node bump
- Optionally `rm data/*.db*` → unrelated, clears 4 MB WAL cruft

## Verification commands (after fix)

```
node -e "const D = require('better-sqlite3'); new D(':memory:'); console.log('OK')"
npx vitest run apps/api/src/routes/devflow.test.ts apps/api/src/routes/commands.rights.test.ts apps/api/src/routes/orchestrator.test.ts
```

Expected: 31/31 tests pass across those three files.
