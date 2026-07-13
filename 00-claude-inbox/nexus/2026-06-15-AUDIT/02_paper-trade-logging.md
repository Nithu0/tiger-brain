# Nexus Learning-Loop Audit — Stages 3 (Paper-Trade Execution) + 4 (Result Logging)

Date: 2026-06-15
Auditor scope: how a decision becomes a (paper/demo) order and how its result is recorded.
Method: code read (apps/worker/src/firm + services) + live DB query via nexus-pg-rw.
Mode: demo against OANDA practice (so "paper trade" = real OANDA-practice fill mirrored into `simulated_orders`).

---

## TL;DR verdict

| Stage | Verdict | One-line |
|---|---|---|
| (3) Paper-trade execution | **EXISTS** | Orders get placed at OANDA + a `simulated_orders` row is created on every path. |
| (4) Result logging | **WEAK** | PnL + close_price + close_reason are ~100% reliable, but the **evaluation-grade metadata (R-multiple, ATR, regime, session, SL/TP)** is missing on ~83% of recent trades because most trades are *reconstructed* by oanda-sync rather than logged by the firm's own open path. |

The system **records that trades happened and whether they made/lost money.** It largely **cannot tell you, per trade, the conditions it entered under** — which is exactly what a learning loop needs to attribute outcomes to context. So: real ledger, weak feature-store.

---

## Live data snapshot (`simulated_orders`, queried 2026-06-15)

- Total rows: **209**, all `status='closed'`, 0 currently open.
- Date range: 2026-04-16 → 2026-06-15.
- NULL `pnl` (closed): **0** ✓
- NULL `close_price` (closed): **1** (negligible)
- NULL `entry_price`: **0** ✓
- NULL `close_reason` (closed): **0** ✓ (always set)
- NULL `bot_id`: **11** (5.3%)
- NULL `strategy_id`: **86 (41%)**
- NULL `regime_at_entry`: **189 (90%)**
- NULL `atr_at_entry`: **184 (88%)**
- NULL `entry_conviction_score`: **83 (40%)**
- NULL `result_r` (closed): **134 (64%)**
- NULL `session_at_entry`: **124 (59%)**

### Last 30 days only (48 trades) — current behaviour, not legacy
| Field | % populated |
|---|---|
| strategy_id | 100% |
| entry_conviction_score | 100% |
| bot_id | 83% |
| stop_loss / take_profit | 85% |
| **regime_at_entry** | **15%** |
| **atr_at_entry** | **17%** |
| **result_r** | **17%** |
| **session_at_entry** | **17%** |

Metadata health is **not** just a legacy-data problem; it is still broken today.

---

## ROOT CAUSE — two execution paths, only one logs full metadata

Split by `execution_source` for last-30-day trades:

- **`firm_strategy`** — 8 trades — atr **100%**, result_r **100%**, conviction **100%**, bot **100%**. The firm's own internal open path logs everything correctly.
- **`oanda_import:*` and `oanda_backfill:*`** — 40 trades — atr **0%**, result_r **0%**, regime ~0%, session ~0%. Strategy + conviction are recovered (blade-match + a conviction-defaults table), but ATR/regime/session/R/SL/TP are **structurally unrecoverable** because they were never captured at decision time.

So **40 of 48 (83%) recent trades never went through the firm's own logging path.** They open AND close at OANDA faster than the firm's open-import cycle observes them, and oanda-sync reconstructs them after the fact.

### Why the metadata is thin even on the good path
Logging is **two-phase**:
1. `apps/worker/src/services/paper-execution.service.ts:291` — INSERT writes only 13 cols (id, bot, signal, market, direction, entry, SL, TP, size, trust_label, session, provider, strategy). No ATR/regime/conviction/risk_points.
2. `apps/worker/src/firm/managers.ts:1011` — a follow-up UPDATE fills atr_at_entry, regime_at_entry, conviction, original_risk_points, etc., with `regime_at_entry = COALESCE(regime_at_entry, $6)` and `atr_at_entry = $2` (where $2 may be NULL).

If the trade round-trips before phase 2 runs (or phase 2 passes NULLs because ATR/regime weren't resolved that cycle), the row is permanently thin. The oanda-sync reconstruction path cannot backfill ATR/regime/R because that data isn't in the broker feed.

---

## #117 / commit 8299c9b verification (bot_id=NULL + OANDA_EXTERNAL misattribution)

- **The fix IS real and IS merged to `origin/main`** (`8299c9b`, PR #117 merge `01912d6`, dated 2026-06-15).
- Pre-fix: `backfillClosedTrades()` in oanda-sync.ts hard-wrote `bot_id=NULL` + `close_reason='OANDA_EXTERNAL'` for EVERY backfilled row → fast stop-outs (the firm's own gated trades) were mislabeled as external. Commit message cites ~$1.9k of firm losses made invisible to attribution + sl_cooldown accounting.
- Post-fix (verified in `origin/main:apps/worker/src/firm/oanda-sync.ts` ~line 851): when `lookupBladeAttribution` matches a firm strategy (±2s blade_decision), the row now gets the firm bot_id + `close_reason='OANDA_SL_TP'`. Only genuinely-unattributable trades keep NULL/`OANDA_EXTERNAL`. Tests added.

### Caveats (still real gaps)
1. **The fix is NOT in the current working branch** (`feat/dashboard-structure-vpa-tile`); it lives in `origin/main`. Confirm the deployed worker is on a commit that includes 8299c9b before trusting new backfills.
2. **Historical rows are NOT retroactively repaired.** Live DB still shows:
   - 11 rows `close_reason='OANDA_EXTERNAL'` with NULL bot, **-$2,637** PnL.
   - **79 rows `close_reason='OANDA_BACKFILL'`** (uppercase — a separate/legacy ingest sentinel, distinct from the code's current `OANDA_EXTERNAL`), ALL with no real strategy, **-$10,797** PnL. This is the single largest pool of un-attributable loss and is unaddressed by #117.
   - A backfill migration would be needed to re-attribute these (blade-match is time-bounded; many may be genuinely unrecoverable now).
3. The fix relies on `lookupBladeAttribution` (blade_decision within −2s/+0.5s of OANDA openTime). Clock skew or a missing blade row → trade silently falls back to external/NULL again. Robust for now, fragile by design.

---

## Per-question answers

**1. Is every paper trade logged with enough to evaluate it later?**
- PRESENT & reliable: entry_price, close_price, opened_at, closed_at, pnl ($), close_reason, direction, size. Strategy + conviction reliable on recent trades.
- MISSING / mostly-NULL: **result_r (R-multiple)** 64% NULL overall / 83% NULL last-30d; **atr_at_entry** 88% NULL; **regime_at_entry** 90% NULL; **session_at_entry** 59% NULL; stop_loss/TP 15% NULL recently (so R can't even be derived for those).
- NEVER captured (no column exists): **spread** and **slippage**. There is no `spread`/`slippage` column in `simulated_orders` at all. (`signal_price` + `entry_price` + `fill_latency_ms` exist on the firm path and could proxy slippage, but no explicit field, and they're NULL on the reconstructed-trade majority.)

**2. What fraction of trades are un-attributable?**
- By strategy_id: **41% overall** (86/209) have NULL strategy_id; effectively ~45% if you also count `strategy_id='oanda_backfill'` sentinels. Last-30d strategy attribution is 100%, so this is improving — but the historical 41% (−$8,540 PnL) directly breaks any per-strategy backtest/eval over the full history.
- By bot_id: 5.3% overall NULL; 17% NULL in last-30d (the `oanda_backfill:*` rows).

**3. Are sub-cycle round-trips captured correctly?**
- **Captured: YES (existence + PnL). Correctly-attributed: PARTIALLY, post-#117.** They are reconstructed by oanda-sync, get strategy+conviction+bot+close_reason via blade-match, and after #117 are no longer mislabeled external. BUT they **permanently lose ATR/regime/session/result_r/SL-TP** because those are decision-time values the broker feed doesn't carry. 83% of recent trades are this path — so "captured correctly" is true for accounting, false for learning-feature completeness.

---

## Gaps that block per-strategy evaluation (priority order)

1. **result_r NULL on 64% of trades (83% recent).** R-multiple is the canonical normalized outcome; without it cross-strategy comparison is unsound. Worsened recently because the round-trip path can't compute it.
2. **ATR / regime / session NULL on ~85–90%.** No way to ask "does strategy X win in volatile regime / London session" — the conditioning variables are absent.
3. **The two-phase logging design is the structural defect.** Decision-time context must be written in the SAME insert as the order (or captured to a side table keyed by cycle_id at decision time), not in a follow-up UPDATE that loses to fast round-trips.
4. **41% historical NULL strategy_id (−$8.5k) + 79 OANDA_BACKFILL rows (−$10.8k) un-attributable.** Largest realized losses are invisible to per-strategy P&L. #117 fixes new trades only; a historical re-attribution backfill is still owed.
5. **No spread/slippage columns.** Execution-quality learning (a real edge for XAUUSD) is not capturable in the current schema.
6. **Confirm deploy is on a commit ≥ 8299c9b** before trusting that new fast stop-outs are attributed correctly.

---

## Files of record
- `packages/shared/src/db/schema.ts:68` — `simulated_orders` base table (no spread/slippage col).
- `apps/worker/src/services/paper-execution.service.ts:291` — phase-1 insert (13 cols).
- `apps/worker/src/firm/managers.ts:1011` — phase-2 metadata UPDATE (atr/regime/conviction).
- `apps/worker/src/firm/oanda-sync.ts:743` (`backfillClosedTrades`) + `:191` (`lookupBladeAttribution`) — reconstruction + #117 fix (fix in origin/main, not current branch).
