# Nexus bleed — root-cause diagnosis + prioritized fix plan (for ai-1 + Karri)

_thesis-2 (acting researcher, operator-directed), 2026-07-01. Read-only forensic; touched no flag, no nexus code. Evidence = fresh `data/pull/*.json` (Jul 1 12:30 pulls) + git history + a full code-trace of the learning loop. Live-DB not reachable from this pane (egress-FW) — per-trade autopsy of the last 7d is owed by ai-1 (has DB)._

## TL;DR
The demo firm is bleeding for **three stacked reasons, only one of which is new**:
1. **No edge (old, primary):** Sharpe **0.04**, WR **38.5%**, PF **1.12** on 109 trades. The −43% drawdown was **May**. Strategies are structurally kant-løse. GPU/flip-all did not cause this.
2. **The learning loop is observability-only (architectural):** lessons, calibrated thresholds, meta-label P(win) are all computed and **read by nothing that gates/sizes a trade**. "Lærer ingenting" is literally true.
3. **The one live learning wire is the broken one (new, 06-24 flip-all):** `CALIBRATION_MODE=SAFE_AUTO_APPLY` perturbs engine weights on a known-broken signal (`engineBlindOpen` + accuracy-not-P&L objective). The firm + ai-2 both warned against flipping it; operator overrode.

**Account is DEMO (OANDA practice, 100k→87.9k EUR). No real money. But the machine is genuinely broken.**

---

## Evidence (fresh, Jul 1)
- `performance.json`: totalTrades 109, winRate 38.5, PF 1.12, **sharpe 0.04**, maxDD 43.65%, 35 trades < −200. bySession: **NY −592** (36.8% WR), London +1749, Asian +398, Overlap +231. `imported` (real OANDA hist): 132 trades, **−13,940**, avg −105.
- `operator_status.json`: broker demo/connected, dailyPnl **−428** today; regime **MIXED_NO_EDGE**; latestDecision **WAIT_FOR_MORE_DATA (Contradictions 100/100)** — the "brain" is correctly cautious *this instant*.
- `risk_snapshot.json`: realizedToday −384.55 vs limit 500 = **76.9% of daily-loss limit, status warn**; 3× `DAILY_LOSS_LIMIT` criticals on **2026-06-23**. config: `dailyTradeCapEnabled:false`, `slCooldownEnabled:false`.
- `firehose_overview.json`: **lessons_last_7d 0; 6 proposed / 0 approved** ever. The system's own anti-pattern: *"TRENDING regime, counter-trend, OANDA_SL_TP: 14.3% WR / 7 trades / **−2108**"* — detected, never acted on.
- Equity late-June→Jul1: 12.5k → 11.7k chop; **−456 overnight into Jul 1**. Acute bad days cluster around lever-flip dates (Jun 23–24) and Jul 1.

## Code-trace: why learning doesn't reach trades (the core finding)
Full trace in this session; key file:lines:
- **Lesson → gate/sizing = DEAD WIRE.** Approved lessons are read ONLY by `agent-lessons/injection.ts:46` → `risk-advisor.ts:114` / `trade-critic.ts:74`, both **"ADVISORY ONLY — does not block, close, or mutate."** No gate/sizing/threshold module reads `agent_lessons`. `agent-lessons/client.ts:8-9`: *"The trading loop (runCycle) does NOT import this module yet."*
- **Calibrated session thresholds = DEAD WIRE.** `calibration.ts` computes marketThesis/entryThesis/etc.; `getActiveProfile()` (calibration.ts:362) is **never called in the trading loop**. Observability garbage.
- **Meta-label → trade gate = DEAD WIRE.** No code reads `meta_label_scores`/`meta_label_models` for a live decision. `meta_label_models=0` anyway (trainer was manual-CLI until 06-24 `0708c13`).
- **The ONE closed wire:** `SAFE_AUTO_APPLY` → `calibrate-weights.ts` → engine multipliers (bounds 0.70–1.20, ±20%, ≥30 samples, every 20 cycles) → **used** in `conviction/scoring.ts:53`. This is the only live learning feedback — and it's the broken one (below).
- Lesson-stack flags default-OFF (`AGENT_LESSONS_ENABLED`, `LESSON_*_ENABLED`, `META_LABEL_*`), all flipped ON by 06-24 flip-all → now ON but **dead-wired** (harmless), while `SAFE_AUTO_APPLY` is ON and live.

## Why the one live wire is broken (from `operator-decisions.md` 2026-06-24, operator-accepted caveats)
- `engineBlindOpen`: the engine scorecard is fed by the Prism/Blade cycle, **disjoint from the TIER-3 path that opens actual trades** — prod-verified 3/3 recent TIER-3 opens had **0 engine_scores**. So autotune tunes weights off a scorecard that doesn't see real trades.
- Objective weights **directional accuracy (~1.6) over P&L (0.4, saturated ±$500)** — `engine-attribution/aggregates.ts:85-96`. Optimizes being-right-on-direction, not making money.
- Mitigant: multipliers reset to 1.0 on every worker restart (frequent) → churns near-neutral, never converges. Limits damage but also means autotune "learns" nothing durable.

## Why "lærns nothing" even when the loop runs (sample-size)
Even if the lesson→gate wire existed: promotion needs `MIN_OBSERVATIONS` (8, per auto-promote-lessons.mjs:57) / consistency ≥0.8; derived anti-patterns have **sample_size 1–2** (5–7 trades). Same N-wall as the meta-label gate (86 labels). Lowering thresholds = the overfit trap flagged in `meta-label-validation-gate-2026-06-24.md`. Do NOT naively lower them.

---

## Fix plan (by governance gate — I recommend, I do not execute)

### P0 — stop the one harmful live wire (OPERATOR FLIP, ~30s, rollback already documented)
- `CALIBRATION_MODE=RECOMMEND_ONLY` (from SAFE_AUTO_APPLY). It's the only live "learning" wire and it steers on `engineBlindOpen` + accuracy-not-P&L. ai-2 + firm both warned against the flip. Rollback recipe already in `operator-decisions.md` (2026-06-24). Also reset `firm_state engine_multipliers:current` → 1.0 (or restart worker) for a hard revert.
- **ai-1 must first CONFIRM current mode** — I couldn't (route 404s; local snapshot is Jun-9-stale). Check `calibration_log` for recent `applied=true` rows + `firm_state engine_multipliers:current ≠ 1.0`. If already RECOMMEND_ONLY, skip.

### P0.5 — execute the 7-week-old Karri-approved emergency flip (OPERATOR FLIP)
- `SCALP_OVERLAP_ENABLED=false` + `ORB_ENABLED=false`. **Approved by Karri 2026-05-11, never executed.** ORB 0/3 WR, MFE=$0 (structurally unprofitable); scalp-overlap 25% WR, −$1058 on one 19-min session. Both already gated by `isOrbEnabled()`/`isScalpOverlapEnabled()`. Pure flip, no code. See `docs/strategy/proposals/2026-05-11_{orb,scalp_overlap}_observe_only.md`.

### P1 — bug-fixes ai-1 OWNS, no Karri gate (must land before autotune is trusted again)
- Fix `engineBlindOpen`: write `engine_scores` on the TIER-3 open path so the scorecard reflects trades actually opened.
- Fix the attribution objective to weight realized P&L, not just directional accuracy (`engine-attribution/aggregates.ts:85-96`; unsaturate the ±$500 P&L term).
- Only AFTER both land, reconsider SAFE_AUTO_APPLY — and then phase it (original `2026-06-23_go-live` plan: one lever / 48–72h, watch deflated-Sharpe).

### P1.5 — the dead learning wire ("lærer ingenting" root) — KARRI PROPOSAL
Decide whether the firm should *act* on its analysis at all, and how:
- Option A: wire approved lessons into ≥1 gate (anti-pattern → reject/size-down in matching regime×session).
- Option B: wire the computed session thresholds into conviction/gate reads.
- Either way: solve the N=1–2 sample problem with shrinkage / coarser pooling / longer windows — NOT threshold-lowering. This is exactly the DSR/PBO/sample-uniqueness discipline from the 06-24 validation-gate brief. Ship behind a flag, shadow-first, with a graduation rule.

### P2 — the actual edge (KARRI, long game)
Sharpe 0.04 is the disease; everything above is triage. The firm's own signals point at the bleeders: counter-trend entries in trending regimes (the −2108 anti-pattern) + NY session (−592). Real work = regime-direction gating for mean-reversion/scalp in trending + an NY-session review. Backtest honestly (purged-CV, deflated-Sharpe) — at this N, expect most "improvements" to fail the gate; that's the point.

## Data autopsy owed (ai-1, has DB)
Pull last-7d **closed** trades → per row: strategyId, regimeAtEntry, sessionAtEntry, closeReason, resultR, `engine_scores` present?, any engine_multiplier ≠ 1.0 applied at entry?, meta-label P(win) if shadow-scored. Confirms whether SAFE_AUTO_APPLY actually moved sizing on the losers, and which strategy×regime is doing the recent bleeding.

## Honest boundaries
- Could NOT confirm current `CALIBRATION_MODE` live (route 404 + stale snapshot). ai-1 confirms.
- Could NOT confirm whether any MONEY agent (risk-advisor/trade-critic/strategy-tuner) got added to `FIRM_LOCAL_AGENTS` (GPU) in Railway — code-2's note says they're untouched on Claude, but Railway env isn't readable here. ai-1 verify.
- Per-trade detail for the last 7d is aggregate-only from this pane. The autopsy above closes that.
- Governance: prinsipp 1 (ingen auto-disable) + prinsipp 5 (OK kjør før flipp) + money→Karri all bind. Every P0/P0.5 item is an operator flip; P1.5/P2 are Karri proposals. Nothing here was executed.
