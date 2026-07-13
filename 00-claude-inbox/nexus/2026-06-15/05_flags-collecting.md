# Shadow-collector flag verification — post-flip

**When:** 2026-06-15 (Sunday, market closed)
**Verified against:** deployed worker commit `51492a8` (= origin/main HEAD, PR #116). Health OK, worker cycling (cycle 695, heartbeat 143s, broker demo, db ok).
**Method:** READ/VERIFY only. Code read from `origin/main` (deployed), row counts via nexus-pg-rw (read SELECTs).

> Caveat on local checkout: my working branch (`feat/dashboard-structure-vpa-tile`) is BEHIND origin/main and is missing `min-rr-gate.ts` + `signal-postmortem/index.ts`. That is a stale local branch, NOT the deployed state. All findings below are from `origin/main`, which is what runs.

---

## Per-collector summary

| Collector | Flag | Wired in-cycle? | Writes to | Rows now | When it populates |
|---|---|---|---|---|---|
| Signal scorecard | `SIGNAL_SCORECARD_ENABLED` | YES (orchestrator, every evaluated decision) | `signal_scorecards` | **0** | **Monday cycle** (needs a live decision; none on weekend) |
| Min-R:R gate | `MIN_RR_GATE_ENABLED` (+ `MIN_RR_RATIO`, def 2.0) | YES (strategy-execution, per candidate trade) | `gate_decisions` (gate_name='min_rr') | **0** | **Monday cycle** (fires only when a trade candidate is evaluated) |
| Meta-label SCORER | `META_LABEL_SHADOW_ENABLED` | YES (orchestrator, on APPROVED candidates) | `meta_label_scores` | **0** | **Monday cycle** — NOTE: different flag than the labeler; verify it was flipped too |
| Meta-label LABELER | `META_LABEL_LABELER_ENABLED` | **NO — not wired into the cycle** | `trade_labels` | **0** | **NEEDS EXPLICIT TRIGGER** (standalone backfill script) — see below |
| Signal postmortem | `SIGNAL_POSTMORTEM_ENABLED` | YES (orchestrator, runs every cycle) | `signal_postmortem` | **0** | **Monday cycle** — BUT 402 eligible historical rows exist, so it should classify on the FIRST cycle after flip, not wait for new weekday signals |

All five tables exist with correct schema and are healthy/ready (db check ok, latency 42ms). All currently at **0 rows** (expected: just flipped + weekend).

---

## 1. Are the collectors ON live?

Cannot read worker env directly (API `/health` echoes API-service env, not worker). Inferred from code + behaviour:

- The flag wiring is present and correct on the deployed commit for **scorecard, min-rr, postmortem, and meta-label scorer**. Whether each is actually ON depends on the Railway WORKER-service env having `=true`. The operator flipped them; I could not independently confirm the worker received them today because no side-effect can fire on a closed market (no decisions → no scorecard/min-rr/scorer rows even if ON). **This is the limitation: ON-state for these four is only PROVABLE once Monday's first decision lands a row.**
- **Postmortem is the exception**: it runs every cycle and has 402 eligible historical `shadow_signals` to chew on. If it's truly ON, `signal_postmortem` should go > 0 within a cycle or two **today/tonight** even with the market closed (it re-resolves historical rejected signals against existing candles). If it's still 0 by Monday morning, the flag did NOT take effect on the worker — that's your live ON/OFF tell.

## 2. trade_labels — the specific question

**trade_labels = 0. Did NOT populate, and will NOT populate on the Monday cycle on its own.**

Reason: the triple-barrier labeler (`backfillTradeLabels` / `isMetaLabelLabelerEnabled`) is **only called from the standalone script** `apps/worker/src/firm/meta-label/backfill-labels.ts`. It is NOT invoked anywhere in `orchestrator.ts`. Flipping `META_LABEL_LABELER_ENABLED=true` does not make the cycle run it — there is no in-cycle call site. The flag only guards the standalone runner.

So trade_labels needs an **explicit one-shot trigger**, not a weekday cycle.

Good news: 199 closed trades with full SL/TP triples already exist (back to 2026-04-16), so the backfill CAN populate ~199 labels immediately, weekend or not.

### ⚠️ Gotcha before triggering the backfill
The labeler default candle timeframe is `'15m'`. The DB stores XAUUSD candles as **`'15min'`** (3463 rows) — there is NO `'15m'` timeframe. If you run the backfill with the default, it finds zero candles per trade and labels **everything `expired` (label=0)** — silently wrong, not an error.

**Run it with the timeframe override:**
```
cd apps/worker
DATABASE_URL=... META_LABEL_TIMEFRAME=15min npx tsx src/firm/meta-label/backfill-labels.ts
```
(DB write — operator-gated per CLAUDE.md. The 199 trades only have 15min candles from 2026-04-22 onward; trades before that or with a >24h holding-horizon gap may resolve `expired` legitimately.)

## 3. What to check Monday (for operator / ai-1)

**Should self-populate on the first weekday cycle (no action):**
- `signal_scorecards` > 0 (every evaluated decision)
- `gate_decisions WHERE gate_name='min_rr'` > 0 (per trade candidate; only if a candidate is actually evaluated — low-activity day may still be 0)
- `meta_label_scores` > 0 (only on APPROVED candidates — may lag if no approvals; confirm `META_LABEL_SHADOW_ENABLED` is the flag that was flipped, NOT just the labeler)

**Should already be > 0 by Monday IF the postmortem flag took effect (tell for ON/OFF):**
- `signal_postmortem` > 0 — 402 eligible historical rows; runs every cycle. If still 0 Monday AM → `SIGNAL_POSTMORTEM_ENABLED` did not reach the worker.

**Needs explicit trigger — will NEVER populate from a cycle:**
- `trade_labels` — run the backfill script with `META_LABEL_TIMEFRAME=15min` (operator-gated DB write).

---

## Flags worth double-checking on the WORKER service (not API)
`SIGNAL_SCORECARD_ENABLED`, `MIN_RR_GATE_ENABLED`, `META_LABEL_SHADOW_ENABLED` (scorer — this is the one that fills meta_label_scores; `META_LABEL_LABELER_ENABLED` only guards the offline script), `SIGNAL_POSTMORTEM_ENABLED`. Structure + VPA reportedly already on.
