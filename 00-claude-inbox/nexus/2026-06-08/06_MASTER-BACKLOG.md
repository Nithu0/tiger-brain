# Nexus — Master Backlog (consolidated + deduped)

**Written:** 2026-06-08 (ai-1, READ/ANALYSIS only). **Live HEAD:** `4e25db6` (main). **Channel:** repo + 06-07 10-agent sweep + 06-04 sweep + ops docs + ai-1 firm-bus inbox + 06-08 autonomous-watch.

Themed by operator's three focus areas (LEARNING, MEMORY MGMT, AUTOMATION) + RISK/SAFETY + OBSERVABILITY. Each row: title · why · effort(S/M/L) · lane · status · ref. Lanes: **C**=Claude-infra (run freely), **K**=Karri-strategy (gated), **O**=operator-action (Railway/push/decision).

> **Top-line truth (unchanged since 06-07):** "alt er flippa" is largely cosmetic. The learning loop does not flow to any live trade decision. Of the protective flags, the circuit-breaker + risk-level gate are the only ones with teeth, and as of 06-08 autotune (SAFE_AUTO_APPLY) is confirmed *applying* (multNeutral=false) — the first learning knob to actually bite. ADX/ATR fallback is flipped but NOT biting → all regime gates blind.

---

## CRITICAL PATH — close the learning loop end-to-end

The loop is broken at every weld. Fix in this exact order; each is a hard prerequisite for the next being meaningful:

```
DERIVE (crashes nightly, exit-1, 17d)  →  PROPOSE  →  AUTO-PROMOTE (PR#73 merged, flag OFF)  →  APPROVE  →  INJECT (wired+live, 0 approved → "")  →  TRADE
   ^ CP-1 (C, now)                                       ^ CP-2 (O merge done? + K-flip)        ^ CP-3 (K)   ^ no work needed              ^ CP-4 measure
```

- **CP-1 [C, ready NOW]** Fix derive-lessons.mjs nightly exit-1 (17 days dead, 2026-05-22→06-07). PR #76 (`b59f39a`) now captures redacted stderr into the `:failed` marker → pull `firehose:derive_lessons:<date>:failed` after next 04:00 UTC run, read `stderrTail`, fix root cause (suspect: `client.connect()`/TLS/`DATABASE_URL` in subprocess env, OR embeddings/INSERT path — fetch query is verified-good). **Without this, 0 new lessons exist → everything downstream is starved.** Pure infra, no Karri gate.
- **CP-2 [O + K]** Auto-promotion: PR #73 **merged** (`d991310` via `03bda72`) → code now on main, `LESSON_AUTO_PROMOTE_ENABLED` no longer placebo. Flipping it true = trade-altering → **Karri-gate**. Promotes only sample≥20 AND sign-consistency≥0.8, capped 3/day, default OFF.
- **CP-3 [K]** Open the approval weld. Either auto (CP-2 flag) or manual `!lesson approve <id>`. The 3 stale rows (id 1-3, conf 0.22-0.36, tag `lesson-deriver-stats`) are a **dead end** — wrong tag + sub-0.5 conf. Only NEW post-CP-1 rows (tagged risk-advisor/trade-critic via `3a37500`) are inject-eligible. Trade-altering → Karri.
- **CP-4 [C, measure]** Injection itself needs **no work** — wired (risk-advisor.ts:112, trade-critic.ts:67), live (`3a37500` in HEAD), flagged on. It fires the moment one approved, correctly-tagged, ≥0.5-conf, ≤30-day lesson exists. Then: do NOT approve any lesson for 48h after autotune is characterised (attribution confound — both move conviction).

**Parallel hard-blocker to the loop being useful: ADX fallback not biting (see RISK/AUTOMATION P0 below)** — even a perfect lesson loop can't help if regime is always null and regime-gated entries never evaluate.

---

## THEME 1 — LEARNING

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| L1 | **Fix derive-lessons nightly crash** (CP-1) | 0 lessons produced in 17d → loop starved at source | M | C | **ready** (pull stderr after next 04:00 UTC via PR#76) | 05_lessons-pipeline §4 |
| L2 | Land `RecoverableFetchError`→exit-0 guard in derive-lessons.mjs | transient fetch error currently → exit-1 + self-retry-tomorrow; guard makes it resilient | S | C | ready (not on main; coordinate w/ #73's derive edit + stranded `9006592`) | learning-ledger REOPENED |
| L3 | Flip `LESSON_AUTO_PROMOTE_ENABLED=true` (CP-2) | makes injection self-feeding, no human-in-loop | S | K→O | **blocked-on-Karri** (code landed #73) | 01_flip-matrix |
| L4 | Approve first lessons / open approval weld (CP-3) | 0 approved → injection emits "" | S | K | blocked-on-CP-1 (need fresh correctly-tagged rows first) | 05_lessons-pipeline §2 |
| L5 | **Wire `getActiveProfile()`/`calibration_profiles` read-back** | session-threshold autotune is a stub w/ 0 consumers — SAFE_AUTO_APPLY can't move session thresholds even when firing | M | C(infra)/K(activate) | open | 01_flip-matrix CALIBRATION row |
| L6 | ORB_ONLY_MODE blocks ALL calibration (`orchestrator.ts:724`) | autotune skipped entirely under ORB_ONLY → SAFE_AUTO_APPLY half-inert | S(decision) | K | **blocked-on-Karri decision** (is ORB_ONLY still intended?) | REST-KLAR §3 |
| L7 | Engine_scores volume (≥30/engine post-epoch) for autotune | minSamples gate never met → most engine multipliers pinned 1.0 | M | C(observe)/data | open (data-thin; partially biting 06-08) | 06-07 monitoring §1B |
| L8 | Backtest Phase-0: `backtest_xauusd_m1` table + M1 backfill OR repoint→ohlcv_candles | runner throws (table absent); kills operator's "live backtest every trade" want | S-M | C | **partial** — `42062e8` repointed to ohlcv_candles on main; stranded `c6a6b03` adds runnable+runbook+tests | 07_build-deploy §STRANDED |
| L9 | Backtest Phase-1: extract pure `decide(bars,indicators,params,state)` cores | only ORB replayable; ~10 strategies have zero replay | L | C | open (8-12d; shadow-mode is the cheaper interim) | 06-04 inbox #05 |
| L10 | Regression-predictor produces non-zero predictions | predictor degenerate (predicted_r=0, hit_rate=0) — VERIFY-BY overdue | S | C | open/overdue | learning-ledger VERIFIED(join)/✗(predictor) |
| L11 | Lessons-deriver DRY_RUN proof + countByStatus observability panel | make loop demonstrably ready before activation | S | C | open | 06-04 inbox active-learning |

## THEME 2 — MEMORY MANAGEMENT (data persistence, attribution, retention)

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| M1 | **`risk_level_at_entry` NULL on ~150/173 trades** | RISK_LEVEL_HARD_GATE is flipped-but-inert no-op until populated | M | C | **partial** — `b6f3919` (#69) backfills imports; verify live populate rate Monday | 06-07 monitoring §4.3 |
| M2 | `size=0` persisted on newest import/sync trades | sizing analytics + breaker scaling corrupted | S | C | **partial** — `95b9096` backfills size=0 from OANDA units; verify | 06-04 sweep Lane3 |
| M3 | `regimeAtEntry` NULL on all import-trades | regime attribution + regime-gate evaluation broken on side-channel trades | M | C | open | 06-04 sweep Lane3 |
| M4 | Side-channel order source: trades open via `oanda_import:*:blade_match`, firm-funnel emits 0 decisions | trades happen OUTSIDE the firm loop → learning never sees them | M(audit)/K(arch) | C+K | open (confirm intended architecture) | 06-04 sweep Lane3 |
| M5 | Drop `simulated_orders.strategy_id`/`desk` dead columns (Phase-2 migration) | 142/145 NULL; analytics mis-attribution; needs DB migration (operator-gated) | S | O | proposed | known-failures; proposal 2026-05-08_deprecate |
| M6 | Backfill SQL for 138 NULL-metadata rows (postmortem degraded) | postmortem hook degrades on these rows | S | O | ready-to-paste | phase-status; scripts/oneshot/2026-05-13_backfills.sql |
| M7 | Confirm `STRATEGY_BLADE_ENABLED` prod value | several "dead path" claims hang on it; 06-02 blade write implies on | S | O | blocked-on-operator | known-failures §risk_events |
| M8 | Decide keep/DELETE 3 stray agent_lessons rows (id 1-3) | stale pre-fix rows pollute the table; will never inject | S | O | blocked-on-operator | learning-ledger BLOCKED |
| M9 | `event.policy` topic 43d stale while NEWS_BLACKOUT fired 06-02 | publish-path gap; observability only | S | C | open (eyeball next blackout) | known-failures §risk_events |
| M10 | reddit_posts last write 2026-05-27 (10d) | standing foundation-yellow, pre-existing, unrelated to flip | S | C | open/low | 06-07 health §1 |

## THEME 3 — AUTOMATION (make the loop self-driving + data feeding)

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| A1 | **ADX/ATR OANDA-fallback not biting in live market** | `INDICATOR_OANDA_FALLBACK_ENABLED=true` but `strategy_states.market.adx=null` in LONDON_ACTIVE → regime never TRENDING → ALL regime gates blind (no-ops). **Highest-leverage infra item.** | M | C | **P0 open** (trace blackboard `market.adx` source vs fallback branch / insufficient-bars guard) | 06-08 ADX escalation |
| A2 | Cherry-pick stranded observability fixes → main (`2bf96ba`) | dashboard STILL lies live ("no bots running / signal 2862min old"); expectancy clamp absent | M | C | **ready** (cherry-pick 3 pieces onto fresh branch off main; +tests exist) | 09_observability + 07_build-deploy |
| A3 | Cherry-pick `c6a6b03` (runnable backtest+runbook) + `a9e54f3` (oanda N+1 perf) → main | Tier-A stranded fixes; then close PR #60 + archive node-migration-nexus | M | C | ready | 07_build-deploy §3 |
| A4 | envBool unification across ~45 master-flags + boot-time "resolved flags" log line | "I flipped, nothing happened" foot-gun; lenient parse + visible boot state | M | C | **DONE** (`08b74f6` D1 unify; verify boot log) | 06-04 sweep Lane6 D1 |
| A5 | Discord→orchestrator mobile control (`!firm`) — confirm live | self-driven firm wake from phone | S | C | exists (verify) | memory discord_orchestrator_listener |
| A6 | Re-arm READ-ONLY autonomous watch cron each session | operator wants self-driven data/analysis + ping while away | S | C | recurring | memory project_autonomous_watch |
| A7 | Books/YouTube ingestion → knowledge-feeding workstream | next knowledge-feeding lane after watch | M | C | open/next | memory project_autonomous_watch |
| A8 | Verify learning flags actually SET on **Worker** service (not API) | `/calibration/status` echoes API env; loop may be inert if not on worker | S | O | partial-confirmed (autotune biting 06-08 ⇒ at least SAFE_AUTO_APPLY is on worker) | 06-07 monitoring §4.5 |
| A9 | Set `CALIBRATION_MODE=SAFE_AUTO_APPLY` on **API** service too | panel honesty — shows RECOMMEND_ONLY despite worker auto-applying | S | O | open | 06-08 ADX escalation §cosmetic |

## THEME 4 — RISK / SAFETY

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| R1 | **Aggregate/portfolio notional circuit-breaker** | current breaker per-trade only; 04-21 blowup was a CLUSTER of ~6×100u, per-trade clamp wouldn't cap aggregate. Real remaining blowup vector before live capital. | M | K | **blocked-on-Karri** (proposal filed `2026-06-04_hard-position-size-circuit-breaker.md`) | 02_circuit-breaker §4.3 |
| R2 | Breaker silently coupled to `USE_OANDA_BALANCE=true` | if flipped off, cap mis-scales hard (300%≈6-7u) → over-clamps everything to 0; add guard/alert | S | C | open | 02_circuit-breaker §4.1 |
| R3 | Verify RISK_LEVEL_HARD_GATE bites Monday | flipped, real call-site, unverified (weekend); expect ~60% would_reject | S | C | **VERIFY-BY 06-08** (query gate_decisions hard_rejected>0 post-London) | 01_flip-matrix; REST-KLAR §monday |
| R4 | vol-exp no-chase activation (Karri-approved 28.5, "ready") | vol-exp bleeds −$4.1k/26%WR; highest-value un-flipped item | S | O | **ready-to-flip** (confirm `VOL_EXP_NO_CHASE_ENABLED=true` on Worker) | 08_batch2 §1 |
| R5 | FVG bleeding −$1.2k/11 trades, dominant live driver | Karri WIP, NOT in flip batch — should FVG even run? | — | K | blocked-on-Karri | 06-07 health §2 |
| R6 | Currency mismatch in breaker (USD notional vs EUR equity) | ~10% unmodeled cap skew (conservative direction) | S | C | open/minor | 02_circuit-breaker §4.2 |
| R7 | ~16 unreviewed Karri strategy proposals | large backlog; incl cross_strategy_flip (needs-scope-down), null_direction_block (needs-pivot), TF_ADX 22→20, 5×H14 configs, funnel_drain | — | K | blocked-on-Karri | learning-ledger; 08_batch2 |
| R8 | `scalp_overlap_asia` gate wired to wrong path (hardcoded strategyId) | gate never fires on actual scalp-overlap trades | M | C/K | open | known-failures §silent-fails |

## THEME 5 — OBSERVABILITY

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| O1 | Honest `/explorer/weaknesses` (covered by A2 cherry-pick) | dashboard falsely reports "no bots running / stale signals" every load | M | C | ready (= A2) | 09_observability §1 |
| O2 | `degenerateExcluded` expectancy clamp (in A2) | +6.49R-class blowup can recur w/o the guard; current sane value is incidental | S | C | ready (= A2) | 09_observability §2 |
| O3 | Circuit-breaker aggregate surface (`/risk/circuit-breaker` or fold into risk_snapshot) | clamps only log-grep-able now; no count of trades clamped / notional saved | S | C | open | 06-07 monitoring §4.4 |
| O4 | Worker engine-multipliers exposed to API (`/learning` truth) | API can't see worker multipliers | S | C | **DONE** (`d4c2506` persists to firm_state) | 06-04 sweep Lane6 |
| O5 | API-route tests + wire apps/api into husky pre-push | apps/api was untested in CI | S | C | **DONE** (`8e49c7f`) | 06-04 sweep Lane9 |
| O6 | Cloud-side anomaly alerts (hard-loss + loss-cap/streak + activation-health) | REPORT-only health alerts | M | C | **DONE** (`fab56f3`) | git log |
| O7 | Doc-reconcile sweep (known-failures vs phase-status drift, §57 flag name) | docs contradict each other (agent_lessons RESOLVED vs reopened, ORB status) | S | C | partial (16cecbb reconciled risk_events) | 06-04 sweep Lane10 |
| O8 | 0 trades / 0 wouldFire investigation | distinguish over-gating vs known-dormant-strategies (5/6 fire ~never) via gate_decisions hard-reject-rate | S | C | open | 06-08 ADX escalation §3 |
| O9 | Dashboard charts render in browser (VERIFY-BY overdue) | data layer verified, client JS untested | S | C | open/overdue | learning-ledger OPEN |

---

## TOP-5 HIGHEST-LEVERAGE NEXT ACTIONS

1. **[C, P0] Fix ADX/ATR fallback not biting (A1).** It's flipped but `market.adx=null` in active market → every regime gate is a no-op and regime-dependent entries can't evaluate. This silently neuters ~half the gate machinery AND blocks meaningful learning (no regime attribution). Trace blackboard `market.adx` source vs the `INDICATOR_OANDA_FALLBACK` branch / insufficient-bars guard.
2. **[C, P0] Fix derive-lessons nightly crash (L1 / CP-1).** 17 days of zero lessons. PR#76 now leaks the stderr into the `:failed` marker — pull it after the next 04:00 UTC run and fix the root throw. Nothing in the learning half matters until the supply side is alive.
3. **[C, ready] Cherry-pick stranded observability + backtest fixes → main (A2+A3).** The live dashboard still lies ("no bots running"), the +6.49R expectancy guard is absent, and a runnable backtest is stranded — all on a 65-behind branch. Pure REPORT-only, no Karri gate, "OK kjør"-gated push only. Then close PR #60.
4. **[O/K] Decide ORB_ONLY_MODE + flip the two ready protective items (L6 + R4).** ORB_ONLY blocks all calibration (autotune half-inert); vol-exp no-chase is Karri-approved and targets the −$4.1k bleed but may never have been flipped. Both are one-line Railway/decision actions with disproportionate effect.
5. **[C, VERIFY-BY today] Monday re-verification sweep (R3 + O8 + M1/M2).** First live session since the flip — confirm RISK_LEVEL_HARD_GATE bites (~60% would_reject), risk_level/size populate on new trades, and disentangle 0-trades (over-gate vs dormant). This is the only window where the flip's real behaviour becomes observable.

---

## Notes
- **Net DONE since 06-04 (don't re-list):** PR#72 config-hardening (envBool unify A4), PR#73 auto-promote code landed, PR#74 (#65-sibling, though core honesty fixes still stranded — see A2), PR#76 derive stderr capture, `fab56f3` cloud anomaly alerts (O6), `d4c2506` multiplier observability (O4), `8e49c7f` api route tests (O5), `b6f3919` risk_level backfill (M1 partial), `95b9096` size=0 backfill (M2 partial), `3a37500` lesson TARGET-role tagging.
- **Confirmed BITING as of 06-08:** autotune SAFE_AUTO_APPLY (multNeutral=false), circuit-breaker (code, untested on live oversized signal), sl_cooldown + mean_revert gates (rejecting on live data).
- **Confirmed INERT despite flipped:** lesson injection (0 approved), lesson derivation (crashing), risk_level gate (unverified weekend), ADX fallback (null in live market).
