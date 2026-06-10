---
title: Nexus — Capability Evolution Log
tags: [nexus, capability, self-improvement, learning, automation, retrospective]
type: capability-log
status: living
updated: 2026-06-08
---

# Nexus — Capability Evolution Log

> **Purpose (for the brain):** a durable record of HOW Nexus has become better — the tools
> it gained, the strategies it adopted, the reusable ideas it proved, and the concrete
> improvements shipped. The brain reads this to understand its own trajectory so it can
> drive its own future improvement. Append new gains here; don't let improvements go
> unrecorded — un-recorded gains can't compound. See [[feedback_automate_and_brain_self_improvement]].

## How to read this
Each section accumulates over time. The **Improvement log** is dated and append-only.
The **Tools / Strategies / Patterns** sections are living catalogs of current capability.

---

## 🛠 Tools the system gained

| Tool | What it does | Where | Why it mattered |
|---|---|---|---|
| **443 self-diagnose pipeline** | Crashing subprocess captures redacted stderr → firm_state `:failed` marker → `GET /firehose/derive-status` exposes it over HTTPS/443 | `firehose-error-capture.ts` (#76), `firehose.ts` derive-status (#79) | DB ports + SSH are firewalled on this network; this is how the system diagnoses its OWN failures without Railway log access. **Found the 17-day crash.** |
| **nexus-watch** | Read-only client watch: health, daily-loss, kill-switches, gate-100%-reject, expectancy/PF drift, lesson growth, **derive-failure alarm**. Cron'd (UTC), pings Discord on ALARM, REPORT-only | `scripts/ops/nexus-watch.sh`, `~/.nexus-ops/`, crontab | Automated external watchdog — a dead worker can't page about its own death; this can. |
| **Cloud-side anomaly alerts** | Worker-side hard-loss / loss-cap / loss-streak / activation-health Discord alerts | `loss-and-activation-monitor.ts` (fab56f3), default-OFF | In-loop, fires even when the operator's machine is off. Complements nexus-watch (client-side). |
| **Lesson auto-promotion** | proposed→approved without manual `!lesson approve`, gated: N≥20 obs + consistency≥0.8 + daily cap 3, default-OFF | `scripts/firehose/auto-promote-lessons.mjs` (#73) | Closes the learning-loop weld point — without it, injection is inert (0 approved ever reaches a decision). |
| **Position-size circuit breaker** | Clamps trade to max(80u / 300% notional), data-calibrated from 173 real trades, default-ON | `strategy-execution.ts` (#61/#67, Karri) | The actual blowup guard — would have clamped the Apr-21 106-unit kill to ~56u. |
| **Honest observability** | `/explorer/weaknesses` reads the firm heartbeat (not dead legacy tables); expectancy clamps degenerate result_r | `explorer.ts` + `weaknesses-firm-activity.ts` + `risk-snapshot.ts` (#74) | The trust dashboard had been LYING ("no bots running"); now it reflects reality. |

## 📈 Strategies / risk posture adopted
- **Sizing is the dominant loss lever, not stops.** Forensics on 194 real trades: strip the one Apr-21/22 blowup and the book is break-even (PF 1.03). The hard losses were ONE oversizing event, not a structural edge problem or tight stops. → fix = a hard size cap, not stop-tuning. [[feedback_sl_widening_is_martingale]]
- **Tighten-only invariant** in position management (`isBetterStop()`); widening a stop = martingale, refused in the auto-loop. Manual operator widening is hard-gated + audited.
- **Regime/risk gates** (regime-direction, daily-trade-cap, sl-cooldown, mean-revert-block) — bite live; depend on `INDICATOR_OANDA_FALLBACK_ENABLED` for non-null regime.
- **Continuous learning** (prinsipp 6 rescinded 2026-06-03): derive→promote→inject + SAFE_AUTO_APPLY autotune (±20%/min30 bounds, Karri). Trade-altering switches still gate via Karri.

## 💡 Reusable ideas / patterns proven
- **Attributable batched activation > blind flip.** Flipping every dormant flag at once makes failures unattributable → destroys the learn-loop. Activate in isolated batches with 24-48h observation. [[feedback_batched_activation_over_blind]]
- **Self-diagnose when the network is closed.** When DB/SSH are firewalled (443-only), build the diagnosis INTO the system (capture→persist→expose-over-443) instead of needing log access. This single pattern cracked the 17-day outage.
- **Fail-loud over silent-die.** Subprocesses/gates that fail should write a visible marker + LOUD log, never exit silently. The derive crash hid for 17 days precisely because it was silent.
- **Build default-OFF, activate gated.** Claude builds the mechanism behaviour-neutral; operator flips Railway; strategy/risk values go through Karri. Lets infra land fast without money-impact.
- **Automate the recurring.** Anything I'd re-do by hand (post-deploy checks, watches) becomes a cron/routine. [[feedback_automate_and_brain_self_improvement]]

## 📅 Improvement log (append-only)

### 2026-06-09 — derive fix VERIFIED + learning loop's real ceiling found
- **17-day crash confirmed dead:** derive-lessons succeeded 2026-06-09 04:22 UTC (first success since 2026-05-13); 2 correctly-tagged proposed lessons produced. The #80 path fix worked. nexus-watch ran overnight, correctly HEALTHY (no false alarm).
- **Karri's Claude executed the paste-ready dispatch** (#86/#87): calibration decoupled from ORB_ONLY (now runs + engine_scores flow, RECOMMEND_ONLY), injection floor aligned 0.50→0.40, aggregate breaker added (default-OFF), 3 dead lessons archived. "Paste into your Claude and run" worked end-to-end across two operators.
- **Adversarial verification (judge) found 3 things — all now batched back to Karri:** (a) the aggregate breaker FAILS-OPEN on a DB error (wrong direction for a safety brake guarding exactly a query-burst cluster); (b) engine_scores still coupled to ORB_ONLY via recordCycleSnapshot; (c) **the real learning ceiling** — derived `confidence = n/50` + auto-promote `n≥20` are STRUCTURALLY unreachable at the live ~2 trades/day rate (buckets plateau n≈5–8 in a rolling 30d window), so continuous learning injects ~nothing. Mechanically complete + correctly wired (`buildLessonContext` IS called from risk-advisor + trade-critic), but thresholds don't match the data rate. Fix proposed to Karri: confidence on signal-strength × gentle-volume, lower MIN_OBSERVATIONS, keep consistency≥0.8 as the guard.
- **Meta-lesson:** "the loop is wired" ≠ "the loop will learn." Thresholds must be calibrated to the actual data rate, or a correct loop is silently muted. Verify capability against real volume, not just code paths.

### 2026-06-08 — the 17-day learning-loop outage, root-caused + fixed
- **Symptom:** lesson-derivation exited code=1 every night since 2026-05-22; 0 new lessons; "learning" was a façade despite flags reading ON.
- **Diagnosis path (the meta-win):** built stderr-capture (#76) + derive-status endpoint (#79) → pulled the crash over 443 → `MODULE_NOT_FOUND: /app/apps/worker/scripts/firehose/derive-lessons.mjs`.
- **Root cause:** trivial — worker spawned the script with `cwd=/app/apps/worker` but the Dockerfile copies scripts to `/app/scripts/firehose` (WORKDIR /app). A path mismatch, not DB/schema (which everyone had assumed).
- **Fix (#80):** `resolveFirehoseScript()` candidate-path resolution + fail-loud. Proof expected on the next 04:00 UTC run.
- **Lesson:** firehose subprocess paths are cwd-fragile; the self-diagnose pipeline is what made a silent 17-day failure visible. [[project_fvg_karri_wip]]

### 2026-06-03 → 06-08 — activation arc
- Operator flipped all learning/risk flags ("alt er flippa") — verification showed it was largely **cosmetic**: stale prod build + flags unset on the worker + 4 independent loop breaks. Made it real: merged the code (#73/#74/#76/#79/#80), got the flags actually set + ORB_ONLY=false (calibration unblocked), redeployed.
- Shipped: honest dashboard, sane expectancy, circuit breaker live, risk_level populated, anomaly alerts, auto-promo, self-diagnose, nexus-watch automation.

## 🔭 Open frontier (next self-improvement) — as of 2026-06-09
- **#1 blocker — confidence formula vs data rate** (Karri): `n/50` + `n≥20` unreachable at ~2 trades/day → learning injects nothing. Recalibrate to signal-strength. THIS is what gates the loop now, not wiring.
- **Aggregate breaker fail-open direction** (Karri): make it fail-conservative + set `MAX_PORTFOLIO_NOTIONAL_PCT` before enabling.
- **engine_scores↔ORB_ONLY coupling** (Karri): wire TIER-3 through `recordCycleSnapshot` so calibration survives the flag.
- Autotune computes correctly now (RECOMMEND_ONLY) → activating `SAFE_AUTO_APPLY` is the next trade-altering step (Karri).
- `MEMORY_RECALL_ENABLED=false` — firm_memory written but never read (Karri decision: recall vs stop writes).
- `VOL_EXP_NO_CHASE_ENABLED` unverified on Worker (+ needs `VOL_EXPANSION_ENABLED=true`).
- Real validation signal: `shadow_signals` works; shadow forward-test + ORB backtest need fixes.
- risk_level gate saturating (3/6 cycles hard-reject → foundation RED) — is it too aggressive? (Karri).
