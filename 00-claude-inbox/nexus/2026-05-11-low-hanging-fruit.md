---
date: 2026-05-11
project: nexus
status: shipped
commit: cb5f48c
---

# 5 low-hanging fruit — round-4 sweep

Single batch commit `cb5f48c`. tsc clean across worker / api / dashboard / shared. 428 worker tests still pass. 15 files changed, +164 / -55 (net +109 LoC).

## Fix log

### 1. console.log → logger.service in `apps/worker/src/index.ts`
**Applied.** ~16 runtime call-sites converted to `logInfo` / `logWarn` / `logError` (subsystem/task/message/detail shape).
Kept as direct `console.*`:
- Line 45 `Postgres connected` + line 50 `DB migrations complete` — boot-time pre-logger per instruction.
- Line 400 `main().catch` — bootstrap-level catch (truly the last line of defense).

### 2. virtualBalance TODO at `apps/worker/src/firm/managers.ts:468`
**Applied.** Aligned with the OANDA-fallback pattern from `managers.ts:~833` (now `:850`) — fetch real balance when `USE_OANDA_BALANCE=true`, soft-fallback to `DEMO_STARTING_BALANCE_USD` on failure for the advisory portfolio-check step. The authoritative abort-on-fail still lives in the execution path (unchanged behaviour). TODO marker removed; replaced with multi-line comment explaining the divergence from the abort-path.

### 3. Magic 10_000 → shared constant
**Applied.** New `packages/shared/src/constants.ts` exports `DEMO_STARTING_BALANCE_USD = 10_000` with JSDoc. Rewired 8 production call-sites:
- `apps/worker/src/firm/managers.ts` (2x — forge portfolio check + execution path)
- `apps/worker/src/firm/strategy-execution.ts:227`
- `apps/worker/src/firm/analysis-agents.ts:526` (drawdown balance)
- `apps/worker/src/services/paper-execution.service.ts` (DEFAULT_PAPER_CONFIG)
- `apps/worker/src/services/challenge.service.ts` (DEFAULT_CHALLENGE)
- `apps/api/src/routes/factory.ts` (8 strategy template definitions — `replace_all`)
- `apps/api/src/routes/analytics.ts` (startBalance + per-bot equity init)

Test fixtures skipped per instruction. API `STARTING_BALANCE` env-based (default 100k) call-sites in `health.ts`/`operator.ts` left untouched — separate concern (real-account default, not demo-balance constant).

### 4. eslint-disable:no-console rationale
**Applied.** 4 files, 9 suppression sites — each got an inline comment explaining the why:
- `apps/worker/src/firm/cold-start-config.ts` (2x) — module-init pre-structured-logger.
- `apps/worker/src/firm/firm-epoch.ts` (1x) + `apps/api/src/lib/firm-epoch.ts` (1x) — same module-init rationale.
- `apps/worker/src/firm/notifications/delivery.ts` (4x) — circular-pipeline: the delivery layer warning about its own degradation must not re-enter the delivery layer via logger.service.
- `apps/worker/src/services/paper-execution.service.ts` (1x) — high-cardinality per-cycle diagnostic, deliberately stderr-only to avoid burning Logtail quota.

### 5. `docs/ref/incomplete-features.md` drift refresh
**Applied.** Header drift-note expanded with the verified-resolved items (metadata-strip fix `0ad348f`, 156 env-vars sync `937bd30`, gate_decisions resumed via `STRATEGY_BLADE_NEW_GATES=true`, POSITION_MANAGEMENT_ENABLED PnL-verified). Foundation-gate row upgraded from 🔴 to 🟡 with rule-by-rule status pointing at `phase-status.md` as canonical. New rows added for gate cycleId-correlation (closed) and env-sync (closed). FASE 7 Trinn A row gets metadata-strip-fix note. USE_OANDA_BALANCE rows in both "env-flags som er av" and "Åpne design-feil" tables marked RESOLVED.

## Verification

```
cd apps/worker && npx tsc --noEmit  # clean
cd apps/api    && npx tsc --noEmit  # clean
cd apps/dashboard && npx tsc --noEmit  # clean
cd packages/shared && npx tsc --noEmit  # clean

cd apps/worker && npm test
# tests 428 / pass 428 / fail 0 / duration 2.1s
```

## Constraints honoured

- No push.
- No strategy logic changes (only the demo-balance literal swap; same value, named constant).
- No env-flag flips, no Railway changes.
- Boot-time logs preserved per operator instruction.
