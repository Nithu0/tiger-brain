# Nexus — Master Backlog (consolidated + deduped) — 2026-06-10

**Written:** 2026-06-10 (ai-1, READ/ANALYSIS only). **origin/main HEAD:** `f4bfadf` (local clone was 13 behind at `676c222` — verified against origin/main, not local). **Channel:** repo (origin/main) + 06-08 backlog (`06_MASTER-BACKLOG.md`) + 06-09 reports (remaining-karri-items, verify-live-loop, verify-86, verify-87) + Karri dispatch #2 (`KARRI-DISPATCH-2026-06-09.md`, commit `f3068ac`) + ops docs + 06-10 watch feed.

Themed: LEARNING / MEMORY / AUTOMATION / RISK / VALIDATION. Lanes: **C**=Claude-infra (run freely), **K**=Karri-strategy (gated), **O**=operator-action (Railway/push/decision).

> **Top-line truth (shifted since 06-08):** The learning loop is now **mechanically complete AND structurally unblocked in code** — the two welds the 06-08/09 reports flagged as broken are fixed on main: (1) injection IS wired (06-09 report grepped the wrong symbol `buildLessonInjection`; the real fn is `buildLessonContext`, called from risk-advisor.ts:114 + trade-critic.ts:69), and (2) dispatch #2's confidence-formula rewrite + auto-promote n→8 (commit `b0cbee8`, PR #91) killed the structural-mute that capped live lessons at conf~0.14 forever. **What remains is ACTIVATION (Karri/operator flips), not infra.** The loop has never yet injected a lesson into a live decision — but the only thing standing between "now" and "first injection" is a fresh derive run producing an n≥8 / consistency≥0.8 lesson + the two enable flags being ON on the Worker.

---

## DONE SINCE 06-08 (do NOT re-list as open)

- **derive-lessons 17-day nightly crash — FIXED** (#80 `676c222`, path-resolution across cwd). First green run 2026-06-09 04:22 UTC; 06-10 also green (`latestSuccess=2026-06-10`, `failedToday=False`). CP-1 CLOSED.
- **Karri #86** (`b2723eb`): aggregate exposure breaker (#4) + injection floor 0.50→0.40 align (#2). Both verified correct by adversarial judge.
- **Karri #87** (`6d8813b`): calibration decoupled from ORB_ONLY_MODE. Verified LIVE — calibration_log fresh today, engine multipliers non-neutral, session + engine calibration both computing (RECOMMEND_ONLY, not applying).
- **3 dead lessons archived** (#5) — `archived=3` confirmed in live counts.
- **Dispatch #2 follow-ups — LANDED** (#91 `b0cbee8`):
  - (A) aggregate breaker now **fail-CONSERVATIVE** (skips trade on exposure-query error, was fail-open).
  - **Learning structural-unblock**: confidence = `consistency × min(1, n/8)` (was `min(0.95, n/50)`); auto-promote `MIN_OBSERVATIONS` default 20→8. An 86%-WR n=7 cluster now scores ~0.75 → injectable. **This is the single most important change since 06-08 — it dissolves the "structurally muted forever" finding.**
  - (B) loud startup WARN if `ORB_ONLY_MODE=true` + `SAFE_AUTO_APPLY` (engine-weight calibration starve guard). orchestrator:205-208.
- **risk-gate narrowed** (#92 `63d5e8a`): `RISK_LEVEL_HARD_GATE` block-set reduced from [elevated,high,extreme] → [high,extreme] (was hard-rejecting ~46% of cycles → foundation RED + blocked a confirmed winner). Env-tunable via `RISK_LEVEL_BLOCK_LIST`. Evidence backed only 'high' loss-prone.
- **24/7 autonomous-watch scaffolding** (#89 `d44d3d6`, inert).
- Earlier (pre-06-08, already in 06-08 notes): config-hardening envBool unify (#72), auto-promote code (#73), cloud anomaly alerts (`fab56f3`), multiplier observability (`d4c2506`), api route tests (`8e49c7f`), lesson TARGET-role tagging (`3a37500`).

**Correction to the 06-09 verify-live-loop report:** it claimed "`buildLessonInjection` has no caller → injection unwired." That symbol does not exist; the function is `buildLessonContext`, which **is** called from both agents. Injection is wired. The report's structural-stop #2 was a false alarm (wrong grep target). The real (and only) blocker was lesson strength, now fixed by #91.

---

## CRITICAL PATH — "a lesson actually injects into a live decision"

```
DERIVE ✓        →  STRONG-ENOUGH LESSON      →  AUTO-PROMOTE       →  APPROVED         →  INJECT ✓ (wired)   →  TRADE
(green 06-09/10)   (formula fixed #91,          (n≥8 + consist≥0.8,   (auto OR manual     (buildLessonContext   (measure
                    needs a fresh derive run     flag default-OFF)      !lesson approve)     in 2 agents)          attribution)
                    that lands n≥8/cons≥0.8)
   CP-1 DONE        CP-2 (code✓, needs data+     CP-3 (K-flip          CP-4 (no work)       CP-5 (no work)        CP-6 (C measure)
                    Karri sign-off on formula)    LESSON_AUTO_PROMOTE)
```

**Current state of each weld:**
- **CP-1 DERIVE — DONE.** Green 2 days running. Produces proposed lessons (currently id 4/5, but those were derived under the OLD n/50 formula → conf 0.14; **next** derive run under #91's new formula will re-score the same cluster ~0.6-0.75).
- **CP-2 STRONG-ENOUGH LESSON — code DONE, awaiting (a) one fresh derive run post-#91 deploy to re-score, (b) Karri's explicit OK on the new confidence formula.** The formula change is trade-influencing → Karri owns the sign-off even though Claude wrote it default-safe. Once a derive run lands a cluster at n≥8/consistency≥0.8, it's promote-eligible.
- **CP-3 AUTO-PROMOTE — blocked on `LESSON_AUTO_PROMOTE_ENABLED=true` (Karri-flip via operator).** Code landed (#73), threshold lowered (#91). OR manual `!lesson approve <id>`.
- **CP-4 APPROVED — no work** (auto via CP-3, or manual).
- **CP-5 INJECT — wired + no work.** `buildLessonContext` live in risk-advisor + trade-critic; double-gated by `AGENT_LESSONS_ENABLED` + `LESSON_INJECTION_ENABLED` (both default-OFF → **operator must flip both on Worker**). Floor 0.40.
- **CP-6 MEASURE — C, after first injection.** Confound warning: don't approve a lesson within ~48h of any autotune characterisation (both move agent conviction).

**Net:** the critical path is no longer broken at any weld in *code*. It is gated at CP-3 (Karri flip auto-promote) and CP-5 (operator flips the two injection enable-flags on Worker). After a single fresh derive run produces an eligible lesson, **two flag flips = first live injection.** That is the closest this loop has ever been.

---

## THEME 1 — LEARNING

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| L1 | **Karri sign-off on new confidence formula** (`consistency×min(1,n/8)`) | trade-influencing; Claude built default-safe but activation is Karri's call (dispatch #2 recommendation = his to accept) | S | K | **open — awaiting Karri** | dispatch #2 §learning-blocker; #91 |
| L2 | **Flip `LESSON_AUTO_PROMOTE_ENABLED=true`** (CP-3) | makes promotion self-feeding; code+threshold both landed | S | K→O | **blocked-on-Karri** | 06-08 L3; #73/#91 |
| L3 | **Flip `AGENT_LESSONS_ENABLED`+`LESSON_INJECTION_ENABLED`=true on Worker** (CP-5) | injection wired+floor-aligned; inert until both ON | S | O (Karri-gated) | **blocked-on-operator** (needs Karri OK first) | injection.ts:37-38 |
| L4 | Verify first derive run post-#91 re-scores cluster ≥0.6 | confirms the unblock actually works on live data, not just unit test | S | C | **VERIFY-BY 2026-06-11** (pull `/firehose/derive-status` + lessons after next 04:00 UTC) | dispatch #2 |
| L5 | `MEMORY_RECALL_ENABLED=false` — firm_memory written, never read | dead writes since 04-25; either re-enable recall (trade-influencing) or stop writing | S(decision) | K | **open — Karri owes decision** (dispatch #1 #3, still not done) | remaining-karri-items §3 |
| L6 | Wire `getActiveProfile()`/`calibration_profiles` read-back | session-threshold autotune is a stub w/ 0 consumers | M | C(infra)/K(activate) | open | 06-08 L5 |
| L7 | engine_scores↔ORB_ONLY full decouple (wire TIER-3 → `recordCycleSnapshot`) | #87 only half-fixes; if ORB_ONLY ever re-flips, engine-weight calibration dies silently in 7d. Now guarded by WARN (#91) but not structurally fixed | M | C+K | **partial** — WARN guard landed (#91-B); full wire deferred (Karri call: engine_scores are Prism artifacts, TIER-3 doesn't use those engines) | verify-87 §caveat; dispatch #2 §B |
| L8 | Regression-predictor produces non-zero predictions | predictor degenerate (predicted_r=0, hit_rate=0) | S | C | open/overdue | learning-ledger ✗(predictor) |
| L9 | Backtest Phase-1: extract pure `decide()` cores (~10 strategies unreplay-able) | only ORB replayable; shadow-mode cheaper interim | L | C | open (8-12d) | 06-08 L9 |

## THEME 2 — MEMORY MANAGEMENT (persistence / attribution / retention)

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| M1 | `risk_level_at_entry` live-populate rate | gate inert on rows where NULL; import backfill landed (`b6f3919`), live rate unverified | S | C | **VERIFY** (query new trades post-London) | 06-08 M1 |
| M2 | `regimeAtEntry` NULL on import-trades | regime attribution + regime-gate eval broken on side-channel trades | M | C | open | 06-08 M3 |
| M3 | Side-channel order source (`oanda_import:*:blade_match`, firm-funnel emits 0 decisions) | trades open OUTSIDE the firm loop → learning never sees them; funnel signals=0 every watch | M | C+K | open (confirm intended arch) | 06-08 M4; watch feed |
| M4 | Duplicate-row from oanda-sync backfill (ticket 548: 2 rows same trade) | analytics/postmortem/lesson-loop double-counts; real sync-bug (missing UUID↔oanda_trade_id link) | M | C | open | phase-status §Åpne |
| M5 | Firm-path entry/SL/TP drift vs OANDA fill (never writes back actual fill price) | r-multiple + analytics imprecise (PnL is truth, so not urgent) | M | C | open | phase-status §Åpne |
| M6 | Backfill 138 NULL-metadata rows (postmortem degrades) | postmortem hook degrades; SQL ready-to-paste | S | O | ready | phase-status §Metadata-strip |
| M7 | Retention FK violation blocks 19,465 stranded `jobs` rows reap | TTL can't reap; filter-only fix landing | M | C | partial | phase-status §Retention |
| M8 | Drop `simulated_orders.strategy_id`/`desk` dead cols (Phase-2 migration) | premise now partly stale (strategy_id populated post-`0ad348f`); needs DB migration | S | O | **proposal premise stale — re-confirm** | phase-status §3 stale proposals |
| M9 | Decide keep/DELETE 3 stray agent_lessons (id 1-3) | now MOOT — those 3 are the archived ones (`archived=3`). Likely CLOSED | S | O | **likely DONE** (archived via #5) | remaining-karri-items §intro |

## THEME 3 — AUTOMATION (self-driving loop + data feeding)

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| A1 | ~~ADX/ATR fallback "all regime gates blind"~~ — **RE-SCOPE/likely overstated** | 06-08 backlog claimed `market.adx=null` → all regime gates no-op. But 06-08 monday-flip shows mean-reversion gate evaluating `adx_too_high 45.5 > 25` — ADX had a real value (45.5) there. So not blanket-null; at most intermittent/session-specific or cold-start. Downgrade from P0 until re-measured on a confirmed-null live snapshot | S(re-measure) | C | **re-scope** (confirm whether adx is ever actually null in active session before treating as P0) | 06-08 A1 vs 01_monday-flip §49 |
| A2 | Cherry-pick stranded observability fixes → main (`2bf96ba`) | dashboard honesty (no-bots-running / stale-signal lies); expectancy clamp | M | C | **likely SUPERSEDED** — `809f5fd`/#74 landed honest `/explorer/weaknesses` + sane expectancy already on main; re-confirm nothing still stranded | git log; 06-08 A2 |
| A3 | Cherry-pick `c6a6b03` runnable backtest + runbook → main | runner stranded; operator's "live backtest every trade" want | S-M | C | open (re-confirm vs `42062e8` repoint already on main) | 06-08 A3/L8 |
| A4 | Verify learning flags SET on **Worker** (not API) | `/calibration/status` echoes API env; loop inert if not on worker. Autotune biting ⇒ SAFE_AUTO_APPLY at least is on worker | S | O | **partial-confirmed** | 06-08 A8 |
| A5 | `CALIBRATION_MODE=SAFE_AUTO_APPLY` on **API** service too | panel honesty (shows RECOMMEND_ONLY while worker auto-applies) | S | O | open/cosmetic | 06-08 A9 |
| A6 | 2 unaudited Discord paths (risk-advisor + macro-event → no delivery-status rows) | delivery unconfirmed for high-freq embeds; 2-line fix needs proposal | S | C | open | phase-status §Discord-paths |
| A7 | Re-arm READ-ONLY autonomous watch cron each session | operator wants self-driven data + ping while away | S | C | recurring (running — watch feed live through 12:30Z 06-10) | memory project_autonomous_watch |
| A8 | Books/YouTube ingestion → knowledge-feeding workstream | next knowledge-feeding lane | M | C | open/next | memory project_autonomous_watch |

## THEME 4 — RISK / SAFETY

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| R1 | **Set `MAX_PORTFOLIO_NOTIONAL_PCT` value + flip `PORTFOLIO_EXPOSURE_BREAKER_ENABLED`** | aggregate breaker landed (#86) + fail-conservative fix (#91); does NOTHING until Karri picks a value (04-21 was ~1690% aggregate) + operator flips. Must be live before live-capital | S | K→O | **blocked-on-Karri value + operator flip** (not urgent in demo) | verify-86; remaining-karri §4 |
| R2 | Breaker silently coupled to `USE_OANDA_BALANCE=true` | if flipped off, cap mis-scales → over-clamps to 0; add guard/alert | S | C | open | 06-08 R2 |
| R3 | Verify `RISK_LEVEL_HARD_GATE` post-narrow (#92) behaviour | block-set narrowed to high+extreme; confirm foundation-RED clears + still rejects 'high' | S | C | **VERIFY-BY 2026-06-11** (gate_decisions hard-reject rate post-London) | #92; verify-live-loop §2 |
| R4 | vol-exp no-chase activation (Karri-approved 28.5) | targets −$4.1k/26%WR bleed; inert unless `VOL_EXP_NO_CHASE_ENABLED`+`VOL_EXPANSION_ENABLED` BOTH on Worker (vol-exp OFF since 13.5) | S | O | **ready-to-flip (both flags)** | remaining-karri §6 |
| R5 | FVG bleeding (Karri WIP) — should FVG even run? | dominant live driver; not in flip batch | — | K | blocked-on-Karri | 06-08 R5 |
| R6 | Currency mismatch in breaker (USD notional vs EUR equity) | ~8-10% conservative cap skew; demo is USD so no live impact | S | C | open/minor | verify-86 §currency |
| R7 | ~16 unreviewed Karri strategy proposals | large backlog (incl tf_adx 22→20, 5×H14, cross_strategy_flip, null_direction_block, funnel_drain) | — | K | blocked-on-Karri | learning-ledger; proposals/ |
| R8 | `scalp_overlap_asia` gate wired to wrong path (hardcoded strategyId) | never fires on actual scalp-overlap trades | M | C/K | open | known-failures §silent-fails |

## THEME 5 — VALIDATION / OBSERVABILITY

| # | Task | Why | Eff | Lane | Status | Ref |
|---|---|---|---|---|---|---|
| V1 | Dashboard charts render in browser (VERIFY-BY 2026-05-22 overdue) | data layer verified; client JS untested | S | C | open/overdue | learning-ledger OPEN |
| V2 | Circuit-breaker aggregate surface (`/risk/circuit-breaker` or risk_snapshot fold) | clamps only log-grep-able; no count of trades clamped / notional saved | S | C | open | 06-08 O3 |
| V3 | 0 firm-trades / 0 wouldFire investigation | every watch shows funnel signals=0 (only oanda_import trades fire). Over-gate vs known-dormant? | S | C | open | watch feed; 06-08 O8 |
| V4 | calibration_log column-name bug verify (`563cfbc`) | INSERT used current/recommended vs schema old/new; fix landed, verify post-run | S | C | partial | phase-status §calibration_log |
| V5 | postmortem-hook catch-up verify | hook moved to orchestrator; 7d backlog @ 5/cycle | S | C | open/overdue | phase-status §postmortem |
| V6 | derive `DRY_RUN` proof + countByStatus panel | demonstrate loop ready before activation | S | C | open | 06-08 L11 |

---

## TOP-5 HIGHEST-LEVERAGE NEXT ACTIONS (split by lane)

**MINE (Claude-infra, run freely):**
1. **[C, VERIFY-BY 06-11] Confirm the learning-unblock actually fires on live data (L4 + R3).** Pull `/firehose/derive-status` + lessons + gate_decisions after the next 04:00 UTC run. Two things to confirm: (a) the same cluster that scored conf 0.14 under the old formula now re-derives at ~0.6-0.75 under #91's `consistency×min(1,n/8)` — this is the proof the structural-mute is gone; (b) the narrowed risk-gate (#92) cleared foundation-RED without going inert. This is the highest-leverage Claude item because it's the gate between "we believe the loop is unblocked" and "we've measured it." Everything Karri/operator does downstream rides on this being true.
2. **[C, re-scope] Re-measure the ADX claim (A1) before anyone spends P0 effort on it.** The 06-08 backlog promoted "ADX null → all regime gates blind" to the #1 P0. But the same day's monday-flip shows a regime gate evaluating a real ADX=45.5. Pull a live `strategy_states.market.adx` in active LONDON session; if it's non-null, A1 is a phantom and should be dropped from the critical list — freeing focus for the real loop work.
3. **[C, cleanup] Reconcile the two stale "open" claims (A2/A3 + M9).** Honest observability (#74) and the archived-3-lessons (#5) already landed — confirm nothing's still stranded so the backlog stops carrying closed items. Low effort, keeps the backlog honest.

**KARRI (strategy — gated, I've built the code default-safe):**
4. **[K] Three decisions that unlock the loop, in priority order:** (a) **sign off on the confidence formula** (#91, L1) — it's the keystone; without his OK the unblock stays theoretical; (b) **OK the `LESSON_AUTO_PROMOTE_ENABLED` flip** (L2/CP-3); (c) decide **`MEMORY_RECALL_ENABLED`** (L5) — re-enable recall or stop the dead writes. Also pick `MAX_PORTFOLIO_NOTIONAL_PCT` (R1) — not urgent in demo but the last guard before live-capital. All four are queued in dispatch #2; he just needs to say "kjør."

**OPERATOR (Railway flips — gated, ready when Karri OKs):**
5. **[O] Two flag-flip clusters on the Worker service:** (a) **the injection enable pair** `AGENT_LESSONS_ENABLED=true` + `LESSON_INJECTION_ENABLED=true` (CP-5/L3) — after Karri OKs, this + an eligible lesson = the first-ever live lesson injection; (b) **vol-exp no-chase** `VOL_EXP_NO_CHASE_ENABLED=true` + `VOL_EXPANSION_ENABLED=true` (R4) — Karri-approved since 28.5, targets the −$4.1k bleed, but inert unless BOTH are set. Both are 30-second reversible Railway flips.

---

## Notes / invariants
- **Confirmed BITING (live):** autotune SAFE_AUTO_APPLY (engine multipliers non-neutral, computing — but RECOMMEND_ONLY so not applying to trades), `risk_level` gate (now narrowed high+extreme), `mean_revert` gate (lightly).
- **Confirmed INERT despite flagged/landed:** lesson injection (no eligible lesson yet + enable-flags OFF), aggregate breaker (default-OFF, no value), recall (OFF), vol-exp no-chase (flags unset + vol-exp OFF).
- **Loop status:** derive ✓ live → formula ✓ fixed (needs Karri OK + 1 fresh run to prove) → promote (Karri flip) → inject ✓ wired (operator flips 2). **Closest the loop has ever been to first injection.**
- Local clone is 13 behind origin/main — `git pull` before any code work. All analysis above is against origin/main `f4bfadf`.
