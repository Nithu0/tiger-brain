# ai-2 adversarial sweep — "hard losses + relearns each day" (2026-06-01)

Role: ai-2 = critic / dommer. Operator complaint: hard losses overshadow good
trades; "every new trade / new day the system seems to restart and relearn from
scratch." 10 read-only adversarial agents dispatched. This is the synthesis,
with my own agents' findings stress-tested before standing. No code changed.

## TOP-LINE VERDICTS

### V1 — "Relearns each day" is the WRONG mechanism. The truth is worse: it never applies what it learns at runtime, by design.
- `orchestrator.ts:660` runs `runCalibration(db, "RECOMMEND_ONLY")`. `calibrate-weights.ts:28-30` gates apply on `mode === "APPLY"`. So computed engine weights are logged to `calibration_log` and **discarded**; runtime always uses neutral baselines + env deltas.
- The one runtime-mutable learned slot (engine perf multipliers, `conviction/config.ts:105`) is in-memory only, never re-hydrated from DB, AND never written in prod (writer unreachable under RECOMMEND_ONLY).
- `getActiveProfile` (`calibration.ts:328-332`) is dead code — always returns baseline; `calibration_profiles` is never read.
- **CRITICAL CAVEAT (my pushback on my own agent):** this is almost certainly *intentional* per operator-prinsipp 6 (no autotune before 30+ days + explicit operator approval). It is NOT obviously a bug — it's the documented safety posture. Operator can't simultaneously forbid autotune and be angry it doesn't auto-adapt. This is a DECISION, not a fix.
- One-query proof: `SELECT mode, applied, count(*) FROM calibration_log GROUP BY 1,2;` → expect all `applied=false`.
- What DOES persist (counter-evidence, not learning-dead): calibration_log, regression-predictor (count=4 post-22.5), firm_memory, gate_decisions (8464 rows). So "wholesale daily amnesia" is FALSE.

### V2 — The SL/TP architecture is SOUND. The operator's proposed fix (lower/widen SL on a loser) would CREATE the blow-up, not fix it. BLOCKED.
- Size scales inversely with stop distance: `dollarRisk = balance*risk%; size = dollarRisk/stopLossPoints` (`strategy-execution.ts:872-873`, legacy `paper-execution.service.ts:265`). A 2× wider ATR stop → half the size → **constant $ risk per trade**. Wide stops do NOT create oversized losses. Agent tried to break this and could not.
- There is **no stop-widening path anywhere** — every stop move is gated by `isBetterStop()` (`lifecycle.ts:66-72`), monotonic toward favorable only. Adding "lower SL on a loser" inverts the only safety invariant in the position manager = unbounded loss. This is martingale. Reject; use existing `re-entry/` instead.
- Minor real bugs: ORB degenerate ternary `slMode=midpoint` both branches identical (`orb-manager.ts:261`); chain-trail TP1/TP2 single-cycle gap (`lifecycle.ts:303-330`, safe direction).

### V3 — I CANNOT backtest the trades. PG tunnel is DOWN (EHOSTUNREACH 66.33.22.236). 
- Zero rows analyzed. Every claim about loss *patterns* (R-distribution, loss-tail vs win-tail, clustering by strategy/session/regime/date, expectancy) is UNVERIFIED.
- Refuse to theorize a loss-pattern story without data. The "hard losses" may be statistically real OR a few salient losses (e.g. 2026-05-12 katastrofedag) coloring an otherwise break-even read. Unknown until tunnel opens.
- Operator-fix: Railway TCP proxy host/port rotated → MCP connection string in `~/.claude.json` (nexus-pg) is stale. Operator: Railway → Postgres → Connect → TCP Proxy → copy current host:port → update nexus-pg conn string → restart Claude session. (I can't read .claude.json — DATABASE_URL secret.)

### V4 — "Too many variables" is the MOST validated complaint. The kill-switches ARE the failure surface.
- 413 distinct env names read in worker code; only 317 documented in `.env.example`; **~130 undocumented live trading knobs** (TF_/PC_/MR_/BC_/VOL_EXP_* families).
- `ORB_ONLY_MODE` banner LIES (`orchestrator.ts:182`): claims it bypasses the decision path, but `runStrategyExecution()` at `:520` runs BEFORE the bypass at `:586`. Strategies with their own `*_ENABLED=true` keep trading. Classic "works in test (all else OFF), fails hard when one flag is left on."
- `FUNNEL_DRAIN_PROPOSALS` default=false (`strategy-execution.ts:113`) re-freezes the f551c17 bug: `board.latest()` silently drops ~29% of proposals per its own comment. Default = the known bug.
- `STRATEGY_BLADE_NEW_GATES=false` while `STRATEGY_BLADE_ENABLED=true` silently buries SESSION_BLOCK + risk + ranging-conviction gates (`strategy-blade.ts:335`), only logs `master=OK`.
- THREE different boolean-parse conventions (`envBool` strict vs `!== "false"` vs `=== "true"`) — same string value flips behavior differently per flag (`bot-manager.agent.ts:112` `!== "false"` = on-unless-exactly-false, on auto-pause/restart — the operator-prinsipp-1 surface).
- Default-mismatches between `foundation-gate.ts:222-244` FLAG_EXPECTATIONS and `.env.example` for ORB_ENABLED / USE_OANDA_BALANCE / OANDA_SYNC_ENABLED — `.env.example` header promises code-accurate defaults and lies for these.

### V5 — "Talks too slowly" is RIGHT. Poller, not event-reactor.
- Entries quantized to cycle cadence (ORB-window 30s, primary 60s, slow 180-600s) + cycle duration (`session-window.ts:205`, `orchestrator.ts:213`). A signal valid just after a cycle starts waits ~60s+ before any strategy sees it.
- Head-of-line blocking BEFORE entry eval each cycle: Step 0a oanda-sync N+1 backfill (up to ~400 serial queries, `oanda-sync.ts:668-731`) + Step 0b live OANDA price fetch (8s timeout, `oanda.service.ts:79`). Heavy cycle = 5-15s before any entry is evaluated; can trip the in-flight cycle-skip (`orchestrator.ts:237`) in the 30s ORB window.
- f551c17 stale-price skip IS verifiably fixed (`latestWith`). FUNNEL_DRAIN still latent (V4).

### V6 — Pause/cap mechanisms reset at UTC midnight with no cross-day caution → a real mechanism behind the "restart" feeling.
- daily-loss-cap + daily-trade-cap recompute from `today::date` every cycle, zero at UTC midnight (`daily-loss-cap/index.ts:51`, `daily-trade-cap-gate.ts:121`). No "yesterday was bad, be cautious" carryover.
- Caps are REACTIVE (read already-closed PnL) and limit COUNT not per-trade SIZE. They never touch SL/sizing — the real lever is structurally outside them.
- Portfolio-wide + strategy-blind: a losing strat drives cumulative PnL negative → cap shuts off a WINNING strat (`strategy-execution.ts:586`). Suppresses good setups while the SL sizing that caused the loss is untouched.
- loss-streak `pausedUntilMs` in-memory (`loss-streak-pauser/index.ts:47`) → Railway redeploy mid-pause + `ageHours<2` re-arm guard can silently cancel up to ~2h of an active pause.
- ALL FOUR default OFF + fail-open on DB error. Confirm live Railway state before treating any as active.

### V7 — No trend-pause detector; counter-trend gate is OFF in prod (matches Karri hypothesis).
- `REGIME_DIRECTION_GATE_ENABLED=false` in prod (`phase-status.md:253`), narrow scope (only mean-reversion strats), and 97.7% of TRENDING msgs carry `regimeDirection=null` → near-no-op even if ON.
- No momentum-stall/trend-pause detector exists; only sign-of-slope proxies (`regime-direction.ts:132`). A stalling trend reads as full-confidence UP/DOWN.
- vol-exp direction = single H1 candle body, no trend context, no confirmation candle (`vol-exp-manager.ts:286`) — naive. Mid-candle entries at currentPrice (`:339`, `breakout-continuation:502`) = chase exposure; `VOL_EXP_NO_CHASE_ENABLED` default OFF.
- Stale regime: `strategy-blade.ts:151` reads regime with 600s window, no freshness guard; persistence layer treats >300s as stale. Gates can act on a regime that turned 6-10 min ago.

### V8 — Scariest concrete bug: one unwrapped DB call can crash the whole cycle and leave open positions unmonitored.
- `orchestrator.ts:255` `getDemoMode(db)` is the only un-`.catch()`-wrapped await early in runCycle; `demo-mode.ts:52` does `parseFloat(rows[0].daily_pnl)` with no empty/throw guard. A transient PG error → kills the cycle → `monitorPositions()` (`:349`) never runs → open live position unmonitored. Direct "fails hard" path.
- ORB `riskPerUnit=0` ungated when entry==midpoint (`orb-manager.ts:259-267`) → runaway/garbage size. orb-manager is the only strategy manager with zero tests.
- session-window.ts (gates ALL trading) has zero tests. portfolio-brain blackboard `as number` casts on untyped JSON (`:145-149`) → silent mis-routing if a fact-agent emits a string.
- 3 fixes are bug-fix/observability class (NO strategy proposal needed): wrap getDemoMode in .catch→safe NORMAL, guard rows[0], guard riskPerUnit>0.

### V9 — The agent_lessons "learning loop" is dead at 3 points but was NEVER live — off-by-default scaffolding.
- Broken: producer (`derive-lessons.mjs` crash — root cause UNCONFIRMED, needs Railway worker logs; SQL does NOT schema-mismatch, agent verified every column) + manual operator-approval gate (`client.ts:110`) + injection default-off (`injection.ts:33`). Zero lessons have ever reached a decision.
- DOC CONTRADICTION to reconcile: `known-failures.md:49` says RESOLVED (env-flag, 2026-05-21); `phase-status.md:11` reopened with a different unconfirmed root cause (deterministic exit-1). Don't trust the docs here; read the `firm_state` `:failed` marker for the actual exit code.

### V10 — Live position view: read side ~80% built; write side doesn't exist + is gated.
- Today: REST poll (~10s), no OANDA streaming. Detail page `positions/[id]/page.tsx` (654 lines) + `/positions/:id/analysis-snapshot` endpoint already surface entry-time thesis.
- Buildable now (autonomous, observability): SSE bridge API→browser (M) for smooth sub-10s price+PnL; tighten poll 10s→2-3s (S); "current vs entry thesis" live panel (S-M).
- Needs operator: true second-by-second = persistent OANDA `/pricing/stream` on worker (M-L code) + Railway deploy/flip (operator-gated).
- Karri + operator gated: exit/modify-TP-SL buttons. There is NO API endpoint that mutates a live position today; mutators (`closeOandaTrade`/`modifyOandaStopLoss`) live only in the worker loop. New write endpoint = money-impact, manual override of autonomous position-mgmt → `docs/strategy/proposals/` + OK kjør. Do NOT auto-build.

## SAFE-TO-LAND NOW (autonomous lane, no proposal)
1. Wrap `getDemoMode` (orchestrator.ts:255) in .catch→safe default; guard `rows[0]` (demo-mode.ts:52).
2. Guard `riskPerUnit > 0` before emitting ORB signal (orb-manager.ts:267) + fix degenerate midpoint ternary (:261).
3. Fail-LOUD logs for V4 silent gates: warn when FUNNEL_DRAIN_PROPOSALS=false drops proposals, and when STRATEGY_BLADE_NEW_GATES=false while BLADE_ENABLED=true.
4. Fix ORB_ONLY_MODE banner to state real scope.
5. Tests for the 3 untested hot-path modules (session-window, demo-mode, orb-manager).
6. `.env.example` reconcile: correct the 3 default-mismatches + delete 2 dead aliases.

## NEEDS OPERATOR / KARRI
- PG tunnel reopen (V3) — blocks ALL trade-data analysis.
- RECOMMEND_ONLY vs APPLY calibration (V1) — operator+Karri, prinsipp 6.
- Any cap/gate/SL behavior change (V2/V6/V7) — Karri proposal.
- Live position-mutation endpoint (V10 write side) — Karri + OK kjør + deploy.

— ai-2
