# Audit 04 — Strategy Versioning (stage 9) & Comparison vs Previous Version (stage 10)

Date: 2026-06-15
Scope: Is Nexus a real LEARNING SYSTEM with respect to (9) versioned strategies and (10) old-vs-new comparison gating?
Method: read-only — code (`apps/worker`, `apps/api`, `packages/shared/src/db/schema.ts`), SQL schema, live DB via `nexus-pg-rw`.

## VERDICT: MISSING

There is no strategy-versioning mechanism and no old-vs-new comparison gate. Strategy parameters live in `process.env` (Railway), the `strategies` table is frozen seed metadata, and the one table that could hold versioned profiles (`calibration_profiles`) is empty and unwired. Autotune mutates a single overwritten KV row with no history. This is the biggest gap of the audit and the suspicion was correct.

---

## Q1. Is there ANY table/mechanism storing discrete strategy VERSIONS with params + performance?

**No.** Params are env vars or mutable single rows that get overwritten with zero history.

Evidence:

1. **Live trading params come from `process.env`, not from any versioned store.** TIER 3 / strategy knobs are read inline at runtime:
   - `apps/worker/src/firm/fvg-detector.ts:49` — `FVG_MIN_GAP_SIZE_USD`, `:50` `FVG_LOOKBACK_CANDLES`
   - `apps/worker/src/firm/orb/config.ts:33,37` — `ORB_CONFIRMATION_TF`, `ORB_SL_MODE`
   - `apps/worker/src/firm/managers.ts:801-802` — `VOLATILE_SL`, `VOLATILE_TP`
   - The "version" of a strategy is whatever was last typed into Railway. Railway env has no row-level history; flipping a var overwrites the previous value with no record of what it was or how it performed.

2. **The `strategies` table has a `version INTEGER DEFAULT 1` column — but it is NEVER incremented and the `config` is NEVER updated.**
   - Schema: `packages/shared/src/db/schema.ts:115-132` (col `version` at :129).
   - Seed: `:927-942` inserts `xau-orb ... version 1 ... ON CONFLICT (id) DO NOTHING` — so a re-seed can't even change it.
   - `grep -rniE "SET version|version *\+ *1|UPDATE strategies SET"` across all `.ts`/`.sql` → **zero hits**. Nothing in the codebase ever bumps the version or rewrites config.
   - Live DB (all 8 strategies): every row `version=1`, and `created_at == updated_at` (frozen at 2026-04-09 / 2026-04-16 seed time). The `config` JSONB (minConfidence, stopLossPoints, dailyLossLimitUSD…) has not changed since April. It is display/catalog metadata; the worker does not read it to drive entries.

3. **`calibration_profiles` — the one table that could version tuned param-sets — is dead.**
   - Schema: `:386-402` (per session_window/regime: thresholds + department_weights + `is_baseline`/`is_active`/`source`).
   - `grep -rniE "INSERT INTO calibration_profiles|UPDATE calibration_profiles"` → **zero hits**. Nothing writes it.
   - Live DB: **`calibration_profiles` count = 0.** Empty table.
   - `apps/worker/src/firm/calibration.ts:362-366` `getActiveProfile()` returns the hardcoded baseline and openly says: *"For now, return baseline. When SAFE_AUTO_APPLY is active, this WOULD query the calibration_profiles table…"* — i.e. unimplemented. So even live session-threshold calibration falls back to the in-code `BASELINE_PROFILES` constant (`:98-129`).

4. **The active autotune path overwrites a single KV row — no versioning.**
   - `apps/worker/src/firm/engine-attribution/multiplier-state.ts:39-50` persists engine multipliers to `firm_state` key `engine_multipliers:current` via INSERT … `ON CONFLICT DO UPDATE` (overwrite).
   - Live DB: `firm_state['engine_multipliers:current']` was updated **today 2026-06-15 18:53** to `{macro:1.031, technical:1.031, …}`. The prior multiplier values are gone — overwritten in place. There is one current row, not a v1/v2/v3 series.

## Q2. Can you later answer "what was v1's win rate vs v2's"?

**No.** With evidence:
- There is no version identifier attached to trades. `simulated_orders` / `trade_strategy_snapshots` record `strategy_id` (the strategy NAME, e.g. `xau-orb`) but never a strategy *version*. So trades cannot be bucketed by param-generation.
- When a param changes (Railway env edit, or autotune overwriting `engine_multipliers:current`), there is no recorded boundary timestamp tying "param-set X" to "the trades it produced." You cannot reconstruct "win rate under the old gap-size vs the new gap-size" because nothing stamps which gap-size was live for each trade.
- `calibration_log` (live: 1337 rows) stores `old_value`/`new_value`/`reason`/`confidence` per recommendation — but it is an append-only suggestion LOG, not a version registry. It records the *delta proposed*, never the *performance that resulted* from applying it. There is no join from a calibration_log row to the subsequent win rate. So even the data we DO capture cannot answer the question.

## Q3. Is there any A/B or old-vs-new comparison gate before a change goes live?

**No comparison gate.** Changes just ship (operator flips a Railway var, or autotune applies within bounds).
- `apps/api/src/routes/strategies-compare.ts` (`/strategies/compare`) sounds like it, but it compares DIFFERENT strategies against each other (xau-orb vs xau-fvg vs mean-reversion) on a leaderboard (win rate, PnL curve, Sharpe). It does **not** compare two versions of the SAME strategy. It is a cross-strategy dashboard, not a regression/promotion gate.
- The calibration `SHADOW_COMPARE` mode is declared as a type (`calibration.ts:24`) but has no implementation — nothing runs calibrated logic in parallel and scores it before promotion.
- Autotune guardrails exist (bounds clamp ±maxDelta, min/max; engine weights require ≥30 samples + ≤±20% deviation — `calibration.ts:78-94, 339-344`) but a guardrail is a *magnitude limiter*, not a *did-the-new-value-beat-the-old-value* test. Nothing measures the post-change outcome and rolls back if worse. The "discard if it doesn't beat the old one" requirement is entirely absent.
- Live proof autotune is shipping unvalidated: `calibration_log` has 128 `APPLY/applied=true` + 30 `SAFE_AUTO_APPLY/applied=true` rows (2026-06-07 → 06-14) and `engine_multipliers:current` is live-mutating — applied with no before/after performance comparison recorded.

## Q4. Without versioning, what specifically is impossible?

- **No attribution of outcome to a change.** You can never say "the FVG gap-size change on June 8 improved win rate from 38% to 47%." The system changes params and forgets the prior state, so it cannot learn whether a change helped or hurt.
- **No rollback-to-best.** Because no prior param-set + its performance is retained, you cannot revert to "the config that had the best Sharpe in May." Reverting means a human remembering/guessing the old env value.
- **No promotion/discard discipline.** A worse version cannot be auto-discarded because "worse than what?" is unanswerable — there is no recorded baseline to beat.
- **Autotune is open-loop.** It applies bounded deltas and logs the *suggestion*, but never closes the loop by reading back the realized performance of the applied value. It is "adjust and hope," not "adjust, measure, keep-or-revert." That is the core of a learning system and it is missing.
- **History is effectively overwritten** in the two places change actually happens (Railway env + `engine_multipliers:current` KV), violating the "history must never be overwritten" requirement.

---

## Minimal fix — `strategy_versions` table

A discrete, append-only version registry. One row per (strategy, version); never updated, only inserted.

```sql
CREATE TABLE IF NOT EXISTS strategy_versions (
  id            TEXT PRIMARY KEY,              -- uuid
  strategy_id   TEXT NOT NULL,                 -- 'xau-orb', joins simulated_orders.strategy_id
  version       INTEGER NOT NULL,              -- monotonic per strategy_id; (strategy_id,version) UNIQUE
  params        JSONB NOT NULL,                -- FULL resolved param-set live for this version
                                               --   (env knobs + multipliers snapshot, not just config)
  source        TEXT NOT NULL,                 -- 'manual' | 'autotune' | 'seed'
  reason        TEXT,                          -- why this version was created
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  superseded_at TIMESTAMPTZ,                   -- set when next version goes live (boundary marker)
  -- performance, backfilled once the version has accumulated trades:
  trades_n      INTEGER,
  win_rate      NUMERIC(5,2),
  avg_r         NUMERIC(6,3),
  total_pnl     NUMERIC(14,5),
  sharpe        NUMERIC(8,4),
  status        TEXT NOT NULL DEFAULT 'candidate', -- candidate | promoted | discarded
  UNIQUE (strategy_id, version)
);
```

Wiring (4 hooks, minimal):
1. **On any param change** (the operator env-flip path AND the autotune apply in `engine-attribution`/`calibration.ts`): INSERT a new `strategy_versions` row with `version = prev+1`, the full resolved param snapshot, and stamp `superseded_at = NOW()` on the prior row. Replace the overwrite-in-place of `engine_multipliers:current` with append-then-point-at-latest.
2. **Stamp trades**: add `strategy_version INTEGER` to `simulated_orders` (and `trade_strategy_snapshots`), set from the currently-live version at entry time. This is the join key that makes "v1 win rate vs v2 win rate" answerable.
3. **Backfill performance**: a daily job aggregates `simulated_orders` grouped by `(strategy_id, strategy_version)` into the version row's `trades_n/win_rate/avg_r/sharpe`.
4. **Promotion gate**: before a candidate version becomes the default, require `new.win_rate`/`new.sharpe ≥ old.promoted version` over a minimum sample (e.g. ≥30 trades). Otherwise mark `status='discarded'` and revert to the last `promoted` row's params. This is the missing "beat the old one or be discarded" rule.

This reuses existing infra: `strategies.version` column already exists (just dead), `calibration_log` already records the delta event (link it via FK), and `/strategies/compare` already computes per-strategy win_rate/Sharpe/drawdown (point it at `(strategy_id, version)` instead of `strategy_id` to get a real version-comparison view).

---

## Key file references
- `packages/shared/src/db/schema.ts:115-132` — `strategies` table (dead `version` col)
- `packages/shared/src/db/schema.ts:386-402` — `calibration_profiles` (empty, unwired)
- `packages/shared/src/db/schema.ts:405-418` — `calibration_log` (suggestion log, not version registry)
- `apps/worker/src/firm/calibration.ts:362-366` — `getActiveProfile()` returns hardcoded baseline; calibration_profiles read is unimplemented
- `apps/worker/src/firm/calibration.ts:78-94, 311-322` — bounds clamp + append-only logging (no outcome read-back)
- `apps/worker/src/firm/engine-attribution/multiplier-state.ts:39-50` — overwrites single `engine_multipliers:current` KV
- `apps/worker/src/firm/agent-bus/firm-agents/strategy-tuner.ts` — Atlas: LLM proposes env tweaks to firm_memory/artifacts; proposal-only, no version store
- `apps/api/src/routes/strategies-compare.ts` — cross-strategy leaderboard (NOT version comparison)
- Live DB: strategies all version=1 & frozen since seed; calibration_profiles=0; calibration_log=1337 (158 applied, none with outcome attribution); engine_multipliers:current mutating live & overwritten.
