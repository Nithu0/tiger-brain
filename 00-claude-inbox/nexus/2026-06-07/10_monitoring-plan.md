# Nexus — post-"alt flippet samtidig" monitoring + attribution plan

**Written:** 2026-06-07 (ai, READ/ANALYSIS ONLY). **Live commit:** 2b2d2ce. **Data:** `data/pull/*.json` (pulled 2026-06-07T12:33Z).

Operator flipped ALL learning + risk activation flags at once (against the batched-attribution advice in memory `feedback_batched_activation_over_blind.md`). The cost of that choice is paid here: we cannot cleanly attribute outcome changes to a single flag, so this doc maps (1) what observability exists to disentangle effects, (2) the attribution gaps that remain, (3) a 24-48h checklist with healthy/alarm thresholds + rollback triggers, (4) new tasks the activation surfaced.

> Caveat that colours everything below: **env values are NOT readable from code or the 443 channel.** "Flipped" = operator's claim. The dashboards below are how we *confirm each flag is actually doing something*, not just set. Several flags are known to be silently inert unless a second condition holds (see §1 + §4).

---

## 0. What "all flipped" means concretely

The trade-altering switches that were gated and are now claimed on (per `docs/strategy/proposals/2026-06-03_activate-learning-loop.md`, Karri-approved 2026-06-05):

| Flag | Effect on trades | Second condition to actually fire |
|---|---|---|
| `LESSON_INJECTION_ENABLED` (+`AGENT_LESSONS_ENABLED`) | Injects approved lessons into risk-advisor + trade-critic prompts → biases vetoes/sizing | **Needs ≥1 `approved` lesson.** Live: 3 lessons exist, all `proposed`, 0 approved (per proposal) → currently INERT even if flag is true. |
| `CALIBRATION_MODE=SAFE_AUTO_APPLY` | Engine perf multipliers self-adjust → changes which setups fire + conviction | Bounds (PR #68): ≥30 samples/engine AND ≤±20% deviation. Until an engine has 30 post-epoch samples, multiplier stays 1.0 (neutral) → INERT for that engine. |
| `LESSON_DERIVATION_ENABLED` | Producer writes `proposed` lessons (pure infra, no trade change) | Needs `AGENT_LESSONS_ENABLED` too; runs 04:00 UTC; data-thin. |
| `POSITION_SIZE_CIRCUIT_BREAKER_ENABLED` (default true) | Clamps oversized trades to cap (`MAX_NOTIONAL_PCT=300`, `MAX_UNITS_PER_TRADE=80`) | Clamps (not rejects) since Karri 2026-06-05. Always-on by default. |
| `RISK_LEVEL_HARD_GATE_ENABLED` | Hard-reject elevated/high/extreme risk | **Near no-op**: `risk_level_at_entry` NULL on 150/173 trades (per handoff 2026-06-04). Even if flipped, gates ~0. |

Plus the always-on infra: shadow forward-test, `/learning` panel, `/calibration/status`, `/shadow/*`, `gate_decisions`, postmortems.

---

## 1. Observability inventory — per flag, the metric + the signal

### A. Lesson injection (`LESSON_INJECTION_ENABLED`)
- **Where to look:** `GET /calibration/status` → `lessons.countByStatus` + `lessons.injectionFlagEnabled`; `/learning` dashboard panel (`apps/dashboard/src/app/learning/page.tsx`, the lessons block + flag badges line 136-138).
- **Working signal:** `injection` badge ON **and** `lessons.countByStatus.approved ≥ 1`. Only then does anything actually inject (`agent-lessons/injection.ts` returns `""` with 0 approved). Effect shows downstream as changed veto/sizing language in risk-advisor / trade-critic threads.
- **Misbehaving signal:** approved count climbs but win-rate/expectancy drops, OR risk-advisor starts vetoing setups that were previously fine (over-fit lesson). Watch `risk_snapshot.rDistribution.winRate` + the trade-critic veto rate.
- **Inert-despite-flipped (current reality):** 0 approved → injection is on-paper-only. **No trade effect yet.** This is the cleanest flag right now precisely because it can't bite until someone runs `!lesson approve`.

### B. Autotune (`CALIBRATION_MODE=SAFE_AUTO_APPLY`)
- **Where:** `GET /calibration/status` → `calibrationMode`, `autoApplyActive`, `engineMultipliers`, `multipliersNeutral`, `multipliersSource`, `recentCalibrationLog`. `/learning` panel shows the multiplier list with a `◆` marker on any diverged engine (page.tsx:160-165) and the "LEARNING ACTIVE (multipliers diverged)" badge (page.tsx:19-25).
- **Working signal:** `calibrationMode = "SAFE_AUTO_APPLY"`, `multipliersSource` non-null with a recent `computedAtIso`, and at least one engine multiplier diverged within ±20% (i.e. 0.80-1.20, not 1.0). `recentCalibrationLog` rows flip `applied=true`.
- **Misbehaving signal:** a multiplier pinned at a bound (0.80 or 1.20) on a thin sample → chasing noise; or multipliers oscillating cycle-to-cycle. Cross-check the engine it's down-weighting actually underperforms in `strategies.json` / `performance.json`.
- **Inert-despite-flipped:** if no engine has ≥30 post-epoch samples, every multiplier stays 1.0 → `multipliersNeutral=true`, badge says DORMANT even though mode is SAFE_AUTO_APPLY. That's expected on thin data, NOT a bug — but it means autotune is currently doing nothing observable. `multipliersSource=null` ⇒ calibration has literally never run (e.g. ORB_ONLY_MODE, or worker not cycling).

### C. Circuit breaker (`POSITION_SIZE_CIRCUIT_BREAKER_ENABLED`)
- **Where:** worker logs `logWarn("firm","circuit-breaker", "<strat> CLAMPED — <reason>")` (`strategy-execution.ts:992`); the clamp reason is also shadow-logged. No dedicated dashboard tile — **gap (see §4)**.
- **Working signal:** when an oversized signal appears, a `circuit-breaker: clamped Nu → Mu (notional X% vs caps…)` line fires and the trade opens at the capped units. Verify open positions' notional %-of-equity ≤ 300% in `positions_open.json` / `risk_snapshot.exposure`.
- **Misbehaving signal:** clamped to 0 units repeatedly (`equity/price unavailable`) → strategies silently not trading; OR no clamp lines ever despite large signals (flag actually off / not on worker). Note it CLAMPS now, not rejects (Karri 2026-06-05) — a "rejected" line would be the old behaviour / stale build.

### D. Risk-level hard gate (`RISK_LEVEL_HARD_GATE_ENABLED`)
- **Where:** `decision_funnel.json` → `gates[].gateName="risk_level"` (evaluated / hardRejected / passed); `gate_decisions` table (8464+ rows, healthy).
- **Working signal:** `risk_level.hardRejected > 0` on actually-high-risk setups.
- **Misbehaving / inert:** current funnel shows `risk_level: evaluated 7, hardRejected 0` — consistent with the NULL-starved signal. **This gate is effectively a no-op until `risk_level_at_entry` is populated** (handoff 2026-06-04). Don't trust it as protection.

### E. Cross-cutting attribution surfaces
- **Shadow forward-test** (`/shadow/per-strategy`, `/shadow/comparison`, `shadow_signals` table): "what we passed on" vs "what we took". `missed_r` = shadow R − actual R. This is the **counterfactual baseline** — the single most useful surface for separating "filters got stricter" from "market changed".
- **Decision funnel** (`decision_funnel.json`, 3d window): per-gate evaluated/rejected. Shows where signals die. Current: 26 cycles, 1 signal proposed, 5 trades opened, 0 decisions emitted (weekend, market closed).
- **Postmortems** (`firm_memory memory_type='postmortem'`, surfaced via `/calibration` failurePatterns + `POSTMORTEM_BACKLOG_WARN_THRESHOLD`): per-trade failure class attribution.
- **R-distribution** (`risk_snapshot.rDistribution`): current 25 trades, avgR −0.443, winRate 0.16, expectancy −0.443 — **this is the pre-activation baseline. Freeze it.**

---

## 2. Attribution gaps — what we CANNOT separate

**TOP GAP — conviction is moved by two knobs at once.** Both **lesson injection** (changes risk-advisor/trade-critic conviction language) and **autotune SAFE_AUTO_APPLY** (changes engine multipliers in `scoring.ts`) alter *which setups fire and at what conviction*. If trade selection shifts over the next days, `/learning` + funnel cannot tell you whether injection or autotune caused it — both feed the same downstream (conviction → blade → fire). **Isolation:** they're currently *naturally* separated because injection is inert (0 approved lessons). Keep it that way until autotune's effect is characterised: **do NOT approve any lesson for the first 48h.** That gives a clean window where any conviction/selection change is attributable to autotune alone. The moment a lesson is approved, the two confound.

Other gaps:
- **Circuit-breaker vs sizing changes:** the breaker clamps size; cold-start + risk-pct also affect size. A drop in avg trade size could be either. Isolation: the breaker emits an explicit `CLAMPED` log line — count those; size drops without clamp lines are not the breaker.
- **Autotune vs regime shift:** a multiplier diverging AND win-rate moving could both just reflect a regime change, not that autotune helped. Isolation: shadow forward-test (`missed_r`) is regime-neutral-ish because it scores taken vs passed in the same market.
- **"Flipped but inert" masquerading as "working":** injection (0 approved), autotune (<30 samples → neutral), risk-level gate (NULL signal). All three can read as "on" while changing nothing. Don't conclude "learning is safe" from quiet metrics — confirm the *second condition* per §1.

**If something goes wrong, the controlled toggle-off order** (cheapest-to-isolate first):
1. `CALIBRATION_MODE` → `RECOMMEND_ONLY` (freezes multipliers at neutral; isolates autotune). 30s, no code.
2. `LESSON_INJECTION_ENABLED` → false (stops prompt injection; isolates lessons). Only matters once a lesson is approved.
3. `POSITION_SIZE_CIRCUIT_BREAKER_ENABLED` → false ONLY if it's clamping legit trades to 0 (otherwise leave on — it's protective).

---

## 3. 24-48h monitoring checklist (compact)

Pull each via API (Bearer $API_KEY) or the `data/pull/*.json` refresh. Cadence: every 4-6h during market hours (memory `feedback_periodic_verification.md`).

| # | Pull | Healthy | Alarm → action |
|---|---|---|---|
| 1 | `/health` → `worker.cyclesPerHour`, `worker.ok` | ok=true, cyclesPerHour ≥ ~6 | **NOW: ok=false, cyclesPerHour=1, status=fail.** Worker barely cycling → ALL flags inert regardless of setting. Investigate worker first; nothing else is meaningful until cycles resume. |
| 2 | `/calibration/status` → `multipliersSource`, `engineMultipliers` | source non-null, multipliers in [0.80,1.20] | any multiplier pinned at 0.80/1.20 on <40 samples, OR oscillating each run → set `CALIBRATION_MODE=RECOMMEND_ONLY` |
| 3 | `/calibration/status` → `lessons.countByStatus.approved` | stays 0 for first 48h (clean autotune window) | approved >0 before autotune characterised → attribution confound; pause approvals |
| 4 | `risk_snapshot.rDistribution` (winRate, expectancy, avgR) | ≥ baseline (winRate 0.16, exp −0.443); ideally improving | expectancy drops >0.2R below baseline over ≥15 new trades → roll back autotune first (§2 order) |
| 5 | `/shadow/per-strategy` → `missed_r` per strategy | near 0 or negative (we took the good ones) | large positive `missed_r` growing → filters too strict (injection/gates eating edge) |
| 6 | worker logs `[firm.*] circuit-breaker … CLAMPED` | clamps only on genuinely oversized signals; never clamp-to-0 spam | repeated `clamped … → 0u (equity/price unavailable)` → breaker starving trades; check equity feed, consider disable |
| 7 | `decision_funnel.json` → per-gate hardRejected | rejects concentrated on real risk; tradesOpened > 0 in active session | tradesOpened=0 across a full primary window while signals proposed → over-gating; diff which gate spiked |
| 8 | `risk_snapshot.dailyLoss` (limit 500) + `killSwitches` | status=ok, no kill switches | dailyLoss status≠ok or any kill switch → operator decides (prinsipp 1: report, don't auto-disable) |
| 9 | `/calibration/status` → `recentCalibrationLog` applied flag | rows appear with `applied=true` once ≥30 samples | applied=true with confidence <0.5 or absurd new_value → autotune chasing noise → RECOMMEND_ONLY |
| 10 | postmortem backlog (`status-report.warnings`) | < `POSTMORTEM_BACKLOG_WARN_THRESHOLD` (20) | backlog warning → LLM/hook broken → attribution data goes stale |

**Rollback decision rules (which flag, when):**
- Expectancy/winRate degrades + multipliers diverged → roll back **autotune** (`RECOMMEND_ONLY`) first; it's the higher-variance lever and currently the only *active* learning knob.
- Veto/over-gating spike *after* a lesson is approved → roll back **injection**.
- Trades clamped to 0 / not opening → check **circuit breaker** (but only disable if it's clamping legit trades; the cap itself is data-justified and protective).
- Account-level: dailyLoss breach is operator's call, not auto (prinsipp 1).

---

## 4. New tasks surfaced by the activation (prioritized)

1. **[P0] Worker is barely cycling — everything else is moot.** `health.json`: `worker.ok=false`, `cyclesPerHour=1`, `lastCycleNo=4`, top-level `status=fail`; `weaknesses.json` flags "last signal 2860 min old" + "no bots running". With ~1 cycle/hr, calibration (every 20 cycles) effectively never runs and autotune can't accumulate samples. **Confirm whether this is just the weekend (market closed) or a stuck worker before trusting any learning metric.** Operator/Railway check.

2. **[P0] Lesson auto-promotion (#73 / handoff task 3) is undecided AND unbuilt.** `proposed→approved` is manual via `!lesson approve` (Discord). Operator never supplied the threshold (the `2026-06-03` doc was never committed — verified missing on main). Until decided, injection stays inert (0 approved) — which is *fine for attribution* but means the learning loop's lesson half is dead end-to-end. **Decision needed from operator: occurrence + confidence threshold + daily auto-approve cap.** Then small build in `agent-lessons/client.ts`.

3. **[P1] `risk_level_at_entry` NULL on 150/173 trades makes `RISK_LEVEL_HARD_GATE` a flipped-but-inert no-op.** Re-enabling it is illusory protection. Fix the populating write-path FIRST (handoff 2026-06-04 task), then flip. Until then, document it as "on but blocking ~0".

4. **[P1] Circuit-breaker has no aggregate/dashboard surface — only per-trade log lines.** Per-trade clamp is logged at `strategy-execution.ts:992`, but there's no count of "trades clamped today / total notional saved / clamp-to-0 incidents." Add a `/risk/circuit-breaker` aggregate (or fold into `/calibration/status` / risk_snapshot) so clamps are countable, not log-grep-only. This is the "per-trade-only circuit-breaker aggregate gap." Pure observability — Claude can build (no Karri).

5. **[P1] Confirm the two trade-altering flags are actually SET on the worker (not just believed).** Memory + phase-status repeatedly show flags claimed-true but never flipped on the prod worker (4 dormant firm-agents 2026-05-21; agent_lessons 0-rows for 8 days). `/calibration/status` echoes only the *API* process env, not the worker's. **Verify via worker behaviour:** `multipliersSource` non-null (proves worker ran SAFE_AUTO_APPLY) and a derived lesson appearing after 04:00 UTC (proves derivation on worker). If neither moves in 48h, the flags didn't take on the worker.

Runner-up: shadow forward-test `event.policy`/topic staleness + confirm `STRATEGY_BLADE_ENABLED` prod intent (learning-ledger residual). Lower priority — observability, not money-near.
