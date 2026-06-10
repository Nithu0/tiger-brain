# LANE 8 — Security sweep (2026-06-04)

Scope: code shipped this session (commits 7ec793c..8ddb445) + new data-access tooling.
Read-only audit. Branch: node-migration-nexus.

## Verdict

No HIGH findings in the audited surface. Auth, SQL parameterization, and error-leak
hygiene on the new routes are all correct. One MEDIUM (untracked live-data dir not
gitignored) and a few LOW/notes below.

---

## (a) New API routes — auth + leakage + SQLi

`apps/api/src/routes/calibration.ts` (`/calibration`, `/calibration/status`)
`apps/api/src/routes/shadow.ts` (`/shadow/per-strategy`, `/comparison`, `/forward-test`, `/recent`)

- **Auth: PASS.** Global `onRequest` hook in `apps/api/src/plugins/auth.ts:15` gates
  everything except `PUBLIC_PREFIXES` = `/health` + `/diagnostic/backfill-original-risk-points`.
  Both new route prefixes are NOT public → bearer-token required (when `API_KEY` set).
  Caveat (pre-existing, not this session): no `API_KEY` set = open (`auth.ts:22` dev-mode).
  Prod has `API_KEY` per boot log at `index.ts:189`. Not a regression.
- **SQLi: PASS.** Every query in both files is parameterized.
  - shadow.ts `days` → `clamp(parseInt(...),1,365)` (shadow.ts:24,127,195,310) then bound
    as `$1::interval`, never string-interpolated. `strategy`/`limit` in `/recent` bound
    as `$N` (shadow.ts:267-285). `limit` clamped 1..500.
  - calibration.ts: all literal SQL, no user input interpolated. `CALIBRATION_MODE`
    validated against an allow-list (calibration.ts:110-112).
- **Secret/error leakage: PASS.** No `err.message` returned to client.
  - shadow.ts:260 bare `catch {}` → empty payload (never 500, never error text).
  - calibration.ts uses `.catch(() => emptyRows)` on every optional query.
  - Responses contain only aggregate trade/calibration data — no creds/env values.
    `lessonsFlagEnabled` etc. (calibration.ts:152-154) echo boolean flag STATE, not values.

## (b) backtest runner.ts — table-name interpolation

`apps/api/src/backtest/runner.ts:41-47`

- **PASS.** `BACKTEST_CANDLE_TABLE` is interpolated into SQL (runner.ts:161), but guarded
  by `SAFE_IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/` with fallback to default `ohlcv_candles`.
  Regex is anchored both ends, rejects whitespace/quotes/semicolons/dots → no injection.
  Value is operator-controlled env (not request input) anyway. Symbol/timeframe are
  bound params (`$1`/`$2`), not interpolated. Double-safe.
- **LOW note:** `runBacktest` throws an Error whose `.message` includes the table+symbol
  names, and the backtest route returns it to the client (`backtest.ts:353`,
  `error: message`). Names are non-secret env defaults; pg errors don't carry the
  DATABASE_URL/password in `.message`. Behind auth. Low risk; flag only for awareness.
  (This return-path predates this session — not introduced in the audited commits.)

## (c) Helper scripts — secret handling

`pull-nexus-data.sh`, `scripts/mcp/nexus-pg.sh`, `setup-nexus-pg-mcp.sh`, `setup-railway-ssh.sh`

- **PASS on secret printing.** None echo `.env`/`DATABASE_URL`/`API_KEY` values:
  - pull-nexus-data.sh reads token into a subshell var, prints only "found in $f"
    (the filename, not the value) and HTTP code + byte count, never the body.
  - nexus-pg.sh greps ONLY the `NEXUS_PG_PUBLIC_URL` line (deliberately not
    `DATABASE_URL`, with an in-file comment explaining the sandbox-vs-prod split),
    does not `source` the .env, and passes the URL straight to `exec npx` — never echoes it.
  - setup-railway-ssh.sh generates a passphrase-less ed25519 key and registers only the
    `.pub` half; comment notes the private half never leaves the machine. It does
    create a non-interactive SSH key — acceptable for `railway ssh` automation, operator-run.
  - setup-nexus-pg-mcp.sh only wires the MCP wrapper path; no secrets touched.

## (d) Prod rlwy.net URL — committed where it shouldn't be?

- **PASS (no password leak).** `git grep rlwy.net` returns only:
  hostname/port references in docs + scripts (e.g. `trolley.proxy.rlwy.net:58688`) always
  with `<password>` / `...` placeholders, plus guard-rail patterns in
  `scripts/firm/ralph.mjs:65` and `scripts/agent-codex-runner.mjs:109` that REFUSE prod
  hosts. No connection string with an actual password is committed.
- **LOW note:** the prod TCP-proxy host:port is committed in cleartext across several
  docs/scripts. Not a secret on its own (port is firewalled to the public proxy and
  rotates), but it does disclose the prod DB endpoint. Acceptable per existing repo
  convention; flag only.

## (e) err.message regression check (intelligence.ts:225 was the prior bug)

- **PASS.** `intelligence.ts:220-233` confirmed fixed — catch returns a generic
  "AI analysis failed" payload, no `err.message`. New routes (shadow, calibration) do
  not repeat the pattern. Dashboard `apps/dashboard/src/lib/api.ts` routes through a
  server-side proxy and no longer uses `NEXT_PUBLIC_API_KEY` (api.ts:12-13) → API key
  never reaches the browser bundle. Worker `shadow-log.ts` logs no secrets/URLs.

---

## MEDIUM finding

**M1 — `data/` (live API pull output) is untracked but NOT gitignored.**
`pull-nexus-data.sh` writes live broker/account/trade/readiness JSON to `data/pull/`.
`.gitignore` only lists `.env` + `.env.local`. A `git add -A` would stage live trading
data (`data/pull/broker_account.json`, `broker_trades.json`, etc.). The files checked
contain no tokens (token never lands in responses — good), but committing live
account/position data to a repo is a data-exposure risk, especially pre-live-capital.
The new helper scripts themselves (`pull-nexus-data.sh`, `setup-*.sh`, `scripts/mcp/`)
are also untracked and unignored — committing nexus-pg.sh is fine, but `data/` is not.

Fix: add to `.gitignore`:
```
data/
```
(Keep the scripts trackable if desired; only `data/` holds live output.)

---

## NEW TASKS

- **[infra]** Add `data/` to `.gitignore` (M1). One-line change; prevents accidental
  commit of live broker/account JSON. Operator-gated only because it touches a tracked
  file — trivial, no behaviour impact.
- **[infra]** (LOW, optional) Wrap the backtest route's client-facing `error: message`
  (`apps/api/src/routes/backtest.ts:353`) to a generic string + log detail server-side,
  matching the intelligence.ts hardening pattern. Defence-in-depth; not exploitable today.
- **[operator]** Confirm `API_KEY` is set on BOTH api-service and dashboard-service in
  Railway (auth.ts:22 means a missing key silently opens all routes). Likely already set
  per boot log; just verify — cheap and high-value given the open-on-missing default.
- **[Karri]** None. No strategy/risk-logic change in the audited surface; all new routes
  are read-only observability.

---
Audited files: apps/api/src/routes/{calibration,shadow,backtest,intelligence}.ts,
apps/api/src/backtest/runner.ts, apps/api/src/plugins/auth.ts, apps/api/src/index.ts,
apps/dashboard/src/lib/api.ts, apps/worker/src/firm/shadow-log.ts,
pull-nexus-data.sh, scripts/mcp/nexus-pg.sh, setup-nexus-pg-mcp.sh, setup-railway-ssh.sh,
.gitignore.
