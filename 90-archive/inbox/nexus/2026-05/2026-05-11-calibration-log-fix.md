# 2026-05-11 — calibration_log column-name fix

**Commit**: `563cfbc8bfb4f8cff6cfd1587958ff146df5598e`
**Branch**: main (not pushed — operator-gated)
**Origin**: engine-resurrection agent bonus finding, audit-2026-05-11

## Problem

Two INSERT statements wrote into `calibration_log` using column names that don't exist in the actual schema:

- `apps/worker/src/firm/engine-attribution/calibrate-weights.ts:130`
- `apps/worker/src/firm/cio/dispatcher.ts:142`

Both used `current_value` / `recommended_value`. Real schema (verified via `mcp__nexus-pg__query` against `information_schema.columns`) has `old_value` / `new_value` (both `numeric`).

Both call sites were wrapped in `try { ... } catch { /* optional */ }` so the bug was silent. They are also unreachable under `ORB_ONLY_MODE=true` and `NEXUS_CIO_ENABLED=false`. The moment either flag flips, every calibration write would throw and be swallowed → zero rows in `calibration_log` → operator visibility broken for the CIO + engine-attribution paths.

## Verified schema (canonical)

```
id              text
session_window  text
regime          text
parameter       text
old_value       numeric
new_value       numeric
reason          text
evidence        jsonb
confidence      numeric
applied         boolean
mode            text
created_at      timestamptz
```

## Change

Renamed `current_value` → `old_value` and `recommended_value` → `new_value` in both INSERT column lists. No other logic touched. Kept the try/catch wrappers as defense-in-depth (operator-spec said "keep it").

Note: `calibrate-weights.ts` passes `.toFixed(4)` strings into the `numeric` columns — PG coerces text → numeric implicitly, so this is fine. Not touching it (out of scope).

## Verification

- `npx tsc --noEmit` in `apps/worker` → clean (no output)
- `npm test` → 443 / 443 pass, 0 fail, 0 skip
- Schema cross-checked live via nexus-pg MCP against prod DB

## Activation impact

This unblocks two flag flips that were silently broken:

1. `ORB_ONLY_MODE=false` — `calibrate-weights.ts` becomes reachable; will now actually log to `calibration_log` instead of swallowing PG `column does not exist` errors.
2. `NEXUS_CIO_ENABLED=true` — `dispatcher.ts` will log every CIO recommendation to `calibration_log` for operator review.

No behavior change while flags stay at their current values (ORB_ONLY_MODE=true, NEXUS_CIO_ENABLED=false).

## Not pushed

Per operator protocol: stop after commit. Push gated on "OK kjør" from operator after this report.
