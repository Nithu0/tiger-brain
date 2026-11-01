# 2026-05-11 — Doc-drift sweep, commit `f8ff485`

Per audit-2026-05-11. Pure docs, no behaviour change. tsc clean. Not pushed.

## Files touched (6)

- `docs/ref/env-vars.md`
- `docs/ops/runtime-map.md`
- `docs/ref/firm-modules.md`
- `docs/ref/feature-flags.md`
- `docs/ref/blackboard-topics.md`
- `docs/ref/known-issues.md`

## Fix-by-fix

### env-vars.md (+ runtime-map.md)
- `TWELVE_DATA_KEY` → `MARKET_DATA_API_KEY` (code already uses new name everywhere in `apps/worker/src/services/market-data.service.ts` and tests).
- `NEWSAPI_KEY` → `NEWS_API_KEY` (code: `apps/worker/src/services/news.service.ts:15`, `apps/api/src/services/providers.ts:38`, `apps/api/src/routes/intelligence.ts:43,339`, `apps/api/src/routes/news.ts:5`).
- Removed the duplicate `MARKET_DATA_API_KEY=...` block lower in the file (single source higher up).
- runtime-map.md worker env-var list: dropped legacy `TWELVE_DATA_KEY` reference.

### firm-modules.md
- Dropped "ten" — title is now plain "Firm modules"; doc explicitly states 16 sub-dirs + ~30 top-level files (as of `ls apps/worker/src/firm/` 2026-05-11).
- New module entries added:
  - `scalp-overlap/`, `session-breakout/`, `vol-expansion/` — TIER 3 strategy modules.
  - `gates/` — hard-gate registry (Shield + Blade).
  - `predictions/` — Atlas regression-predictor (env-gated `FIRM_AGENT_REGRESSION_PREDICTOR_ENABLED`).
  - `agent-knowledge/`, `agent-lessons/` — memory surfaces (latter activated by firehose Phase A+B 06.5).
- Added top-level file table listing `strategy-blade.ts`, `strategy-execution.ts`, `oanda-sync.ts`, `drift-monitor.ts`, `foundation-gate.ts`, `fvg-detector.ts`, `postmortem-hook.ts`, `shadow-log.ts`, etc.
- Decision-path block now mentions parallel strategy modules publish on `*.signal`, routed via `strategy-execution.ts`.

### feature-flags.md — new "Strategy modules (TIER 3) — flags" section
Five tables added:
- `STRATEGY_BLADE_ENABLED` + 4 per-gate switches (`FORGE_CHECK`, `RISK_VETO`, `EVENT_POLICY`, `NEW_GATES`). Master default `false`; per-gate default `true` when master ON.
- `SCALP_OVERLAP_*` — 11 flags including window UTC hours, RSI/ATR knobs, daily cap, TF.
- `SESSION_BREAKOUT_*` — 7 flags including `TP_R=1.5`, min/max range, one-trade-per-window.
- `VOL_EXPANSION_ENABLED` master + `VOL_EXP_*` tuning knobs (8 total). Note: prefix mismatch is real in code — master uses full word, tuning uses abbreviation.
- `FVG_*` — `FVG_FILTER_ENABLED`, `FVG_MIN_GAP_SIZE_USD=1.5`, `FVG_LOOKBACK_CANDLES=30`.

### blackboard-topics.md
- Removed the duplicate `xauusd.macro.fred` bullet (was listed at both line 10 and line 23). Single entry remains at line 10.
- Added three lifecycle topics now on `BLACKBOARD_AUDIT_ALLOWLIST` (verified at `firm/orchestrator.ts:64-66`):
  - `xauusd.execution.fills`
  - `xauusd.position.opened`
  - `xauusd.position.closed`

### known-issues.md
- Postmortem hook → **Resolved**. `apps/worker/src/firm/postmortem-hook.ts` is wired into `runCycle()` post-sync + post-PM; `POSTMORTEM_HOOK_ENABLED` defaults `true`. Backlog warning surfaces in `status-report.warnings`. Followup `verify-postmortem-hook-catchup` can be closed.
- New **HIGH/open**: "Metadata-strip on `simulated_orders` for live firm-blade trades". 28/28 last-week trades NULL on `strategy_id`, `execution_source`, `portfolio_regime_at_entry`, `atr_at_entry`, `entry_conviction_score`. Breaks position-management regime-aware paths + analytics attribution. Fix path: extend firm-path INSERT in `firm/strategy-execution.ts` / execution-manager to carry decision-cycle context. Backfill via `decision_cycle_id` → `manager_decisions` feasible for recent rows.

## Verification

- `grep -rn "TWELVE_DATA_KEY\|NEWSAPI_KEY" docs/` returns only:
  - Two lines in `docs/ops/firehose-plan-06may.md:303-304` — intentional, they are the redaction-regex test fixture.
  - Two lines in `docs/ref/env-vars.md:21,23` — intentional, the rename-explanation comments.
- `cd apps/worker && npx tsc --noEmit` — clean (no output).

## Working-tree note

`apps/api/src/routes/health.ts`, `apps/api/src/routes/operator.ts`, and `apps/dashboard/src/components/balance-reconciliation-widget.tsx` had unstaged modifications from a prior session — they were **not** part of this commit and remain unstaged. Operator may want to inspect / commit / discard separately.

## Commit + push state

- SHA: `f8ff485`
- Branch: `main` (now 4 ahead of `origin/main`)
- Not pushed (per task instructions). Operator triggers push.
