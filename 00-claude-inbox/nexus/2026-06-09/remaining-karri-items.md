# Karri dispatch — remaining items + new finding (2026-06-09, from ai-1)

READ/ANALYSIS ONLY. Live data pulled over 443 (`data/pull/*` @ 2026-06-09 11:23). DB MCP unreachable from this network (5432/58688 firewalled — expected), so all numbers below come from the HTTPS pulls + git/code, not direct SQL.

Repo HEAD on `main` = `4ffbe52` (not `362eafa` as the dispatch said — that SHA is stale or a different deploy; nothing in the analysis depends on it).

Karri's Claude already landed: #1 (calibration decouple, #87), #2 (floor↔auto-promote align, #86), #4 (aggregate breaker, #86), #5 (archived 3 dead lessons — `archived` count = 3, confirmed in `firehose_overview2.json`). Items **#3, #6** + a **new finding** remain.

---

## #3 — MEMORY_RECALL_ENABLED — STATUS: NOT DONE (still write-only)

- No commit on `main` touches recall logic since the dispatch. `git log` grep for recall/memory = nothing new; the only references are the unchanged kill-switch in `firm-memory.ts:126` + `:249`.
- Code state: `recallSimilarSetups()` and `recallSemanticContext()` both early-return empty when `MEMORY_RECALL_ENABLED=false` (`apps/worker/src/firm/firm-memory.ts:122-136`, `:248-249`). `feature-flags.md:121` documents the flag as default-on but **set `false` in prod**.
- So `firm_memory` is written on every close (postmortem hook) but never read back into decisions. Dead weight — unchanged since 2026-04-25.

**Decision Karri owes (trade-influencing → his domain):** re-enable recall (`MEMORY_RECALL_ENABLED=true`, operator flips Railway) **OR** stop the dead writes. No third option is being executed silently; it's just sitting at `false`.

## #6 — VOL_EXP_NO_CHASE_ENABLED — STATUS: NOT VERIFIED on Worker

- No commit/flag-change. Code path unchanged: `vol-expansion/config.ts:51` reads `envBool("VOL_EXP_NO_CHASE_ENABLED", false)` (default OFF).
- Karri approved it 28.5 (`proposals/2026-05-28_volexp_no_chase_activation.md`, "ready"; backtest 34 trades +$977 @ 1.0 ATR).
- **Still needs:** confirm `VOL_EXP_NO_CHASE_ENABLED=true` is actually set on the **Worker** service (the decision-funnel doesn't surface filter flags, so we can't see it from the pulls). **NB from the operator brief:** it's inert unless `VOL_EXPANSION_ENABLED=true` too — vol-exp has been OFF since 13.5. Both flags must be live or the filter does nothing.

---

## NEW FINDING — confidence formula + thresholds are structurally mismatched to the data rate (NOT just "slow")

### What fired (live, confirmed)
- derive-lessons **succeeded 2026-06-09 04:22 UTC** (first success after the #80 path-fix; 06-06/07/08 all failed `MODULE_NOT_FOUND`). Source: `firehose_derive_status2.json`.
- It produced **2 proposed lessons** (id 4 → risk-advisor, id 5 → trade-critic), both:
  `TRENDING / unknown session / OANDA_SL_TP close: 14.3% WR over 7 trades, −$2108`. **confidence = 0.140**, sample_size cluster n=7.
- Confidence formula: `min(0.95, cluster.n / 50)` (`derive-lessons.mjs:217,235`) — pure sample-size proxy, ignores signal strength.
- Injection floor: `minConfidence` default **0.5** (`injection.ts:53`) → needs n≥25. The dispatch's proposed compromise floor of **0.40** → needs n≥20. Auto-promote needs **n≥20** AND consistency≥0.8 (`auto-promote-lessons.mjs:53-54`).
- So id 4/5 (conf 0.14) clear **neither** the 0.40 floor **nor** auto-promote n≥20. They sit `proposed`, un-injectable.

### The data rate (from `export.json`, 201 closed trades, span 2026-04-16 → 06-09)
- Overall: 3.75 trades/day (inflated by an April OANDA bulk backfill).
- **Recent live rate: ~2.1–2.2 closed trades/day** (last 7d = 2.14/day, last 14d = 2.21/day) — across ALL buckets combined.
- derive-lessons buckets by **(regime × session × close_reason)** over a **rolling 30-day window** (`closed_at > NOW() − 30d`, lookback default 30, `derive-lessons.mjs:70,179`).

### The killer detail: it's a ROLLING window, so n has a hard ceiling
Because old trades age out, a bucket's steady-state size ≈ (its trades/day) × 30. It does **not** accumulate forever. So the max n a bucket can ever show = its 30-day count:

| mass spread over | per-bucket /day | 30d n_max | conf (n/50) | clears 0.40? | reaches n≥20? |
|---|---|---|---|---|---|
| 1 bucket | 2.15 | ~64 | 0.95 | yes | yes |
| 4 buckets | 0.54 | ~16 | 0.32 | no | no |
| 8 buckets | 0.27 | ~8 | 0.16 | no | no |
| 12 buckets | 0.18 | ~5 | 0.11 | no | no |

Live evidence matches the "many buckets" row: the **largest real live cluster is n=7** (0.23/day → plateaus near 7, conf ~0.14, **forever**). The only clusters that ever hit n=18 were the one-time April OANDA backfill spikes (archived id 1,2 — conf 0.36), not steady live flow.

**Conclusion:** at the current rate, with a 30d rolling window, **no live (regime,session,close) bucket reaches n≥20** unless one combo sustains >0.67 trades/day. So under "continuous learning," lessons would inject **~nothing for the foreseeable future** — not weeks-then-fine, but a structural plateau below threshold. If someone widened the window to 60–90d to force n up, they'd dilute current-regime signal with stale trades — the opposite of "learn continuously."

### Time-to-threshold if you DON'T fix the formula (optimistic, treats window as accumulating)
Even ignoring the rolling-window ceiling, the largest current cluster (n=7 at 0.23/day) needs +13 → **~8 weeks** to reach n=20, ~11 weeks for n=25. Smaller buckets: 100+ days. So even the optimistic read says weeks-to-months per lesson.

### Options for Karri (this is his call — it changes which trade-prompts get injected)
1. **Change the confidence formula to reflect signal strength, not just volume.** e.g. confidence = consistency × a gentle volume term: `max(wr, 1−wr) × min(1, n/N0)` with small N0 (say 8–10). The live cluster (14.3% WR = 85.7% consistency, n=7) would then score ~0.6–0.7 instead of 0.14 and actually inject. This is the cleanest fix and matches the dispatch #2 framing ("stop computing confidence as n/50").
2. **Lower the thresholds to the data rate.** Drop injection floor to ~0.15–0.20 and auto-promote `LESSON_AUTO_PROMOTE_MIN_OBSERVATIONS` from 20 → ~6–8, keeping consistency≥0.8 as the real quality gate. Cheapest (env-only) but keeps a noisy volume-proxy confidence.
3. **Accept slow accrual** — explicitly decide lessons inject only after months. Defensible for a low-trade demo, but contradicts the operator's "continuous learning / don't get stuck" directive (prinsipp 6 rescinded 2026-06-03).

**ai-1 recommendation (for Karri to accept/reject):** Option 1 + the auto-promote n drop from Option 2. Volume alone is the wrong axis when the data rate caps n in the single digits; consistency is the signal that's actually available. Keep consistency≥0.8 as the guard so a high-conf-but-flukey cluster still can't auto-promote. All trade-influencing → build default-OFF, operator flips, ai-1 verifies live.

---

## #4 follow-up — aggregate breaker needs a value + a flip
- The breaker landed (#86) but `MAX_PORTFOLIO_NOTIONAL_PCT` is **"TBD by Karri" and default OFF**. It does nothing until Karri sets a value and operator flips it on Railway. The 04-21 blow-up was ~1690% aggregate notional (3 simultaneous ~12% trades); pick a cap below that with headroom (proposal stub: `proposals/2026-06-01_hard-position-size-circuit-breaker.md`). Not urgent (demo) but must be live before live-capital.

---

## TL;DR for operator
- #3 recall + #6 vol-exp: both **not done**, both awaiting a Karri decision/verification, neither is a code task right now.
- New finding is the important one: the learning loop is **alive but structurally muted** — confidence `n/50` + n≥20 thresholds vs a ~2 trade/day rolling-30d-window means live clusters plateau at n≈7 / conf 0.14 and **never inject**. Needs a Karri formula/threshold decision or "continuous learning" stays at zero injections indefinitely.
- #4 breaker needs a Karri value + operator flip before live capital.
