# Activation-path bug hunt — newly-ON prod flags (2026-06-07)

Repo `ai-assistent`, branch `main` @ `2b2d2ce` (deployed). READ-ONLY review. Full worker suite green: **1148/1148 pass** (91.5s).

Skeptic's job: read the code each newly-armed flag triggers, find crash / throw / hang / mis-behave / silent no-op.

Flags reviewed (all just flipped from default-OFF):
`CALIBRATION_MODE=SAFE_AUTO_APPLY`, `RISK_LEVEL_HARD_GATE_ENABLED=true`, `INDICATOR_OANDA_FALLBACK_ENABLED=true`, `LESSON_INJECTION_ENABLED=true`, `AGENT_LESSONS_ENABLED=true`, `SHADOW_FORWARD_TEST_ENABLED=true`, `ORB_ONLY_MODE=false`.

---

## Per-flag verdict

### 1. SAFE_AUTO_APPLY — calibration apply path — **SOUND**
- `boundedNextMultiplier` (`calibrate-weights.ts:74`): per-run delta cap → `PERF_MULT_BOUNDS` [0.70,1.20] → optional ±0.20-from-neutral cap. Triple-bounded, pure, unit-tested.
- `scoreToMultiplier` clamps score to [-1,1] before mapping. No unbounded write.
- `setEnginePerformanceMultipliers` (`conviction/config.ts:107`) explicitly skips `typeof v !== "number" || Number.isNaN(v)` AND re-clamps to bounds → a NaN can never reach a live multiplier.
- NaN edge (stray `engine_name` not in 7-member `EngineName` union → `current=undefined` → `next=NaN`): handled. `applied` requires `Math.abs(next-current) > 0.005`; `Math.abs(NaN)` is falsy → not applied; setter would reject it anyway. engine_name is sourced from a closed adapter set (`conviction/adapters.ts`), so off-list names shouldn't occur regardless. Worst case = one junk calibration_log row, never a live effect.
- Conservative guardrails active: `minSamples:30`, `maxDeviationFromNeutral:0.20` (calibration.ts:339).
- firm_state persist (`multiplier-state.ts:39`) is try/catch-swallowed; observability-only, never throws into the loop.
- Engine calibrate call itself is wrapped in try/catch in `runCalibration` (calibration.ts:353).
- **Coupling note:** `runCalibration` only runs when `!orbOnlyMode` (orchestrator.ts:724). SAFE_AUTO_APPLY was therefore INERT until ORB_ONLY_MODE was also flipped to false in this same batch. These two flags are coupled — the autotune apply path goes live *because* ORB_ONLY_MODE=false, not on its own.

### 2. RISK_LEVEL_HARD_GATE — **RISK (not a bug, but over-blocks far more than "~46%")**
- Gate logic (`gates/new-gates.ts:118`) is pure + sound: lowercases `riskLevel`, blocks {elevated, high, extreme}, can't throw. `riskLevel="low"`/`"normal"`/null → pass. No DB dependency in the gate itself.
- The gate reads `riskLevel` LIVE from blackboard topic `xauusd.analysis.risk` (strategy-blade.ts:336), NOT from the `risk_level_at_entry` column. So **PR #69's backfill is irrelevant to whether the gate blocks** — backfill only feeds postmortem/calibration reads, which are null-safe (strategy-execution.ts:858-863). No throw/over-block from backfill state.
- **The real concern is the producer** (`analysis-agents.ts:508-524`):
  - L516-518: `session === "asian" || session === "off-hours"` → `riskLevel="elevated"` UNCONDITIONALLY. With the hard gate on, this **blocks every firm-path trade for the entire Asian session + all off-hours** regardless of setup quality. This is a structural time-of-day block, not a volatility block.
  - L521-522: `atr > 10` → `riskLevel="high"` → blocked. For XAUUSD on 15min, ATR>10 is common in active sessions.
  - Net: the live block rate is plausibly well above the "~46%" estimate, and is concentrated by time-of-day + volatility. Not a crash — but a much larger behavioural cut than the headline number suggests. Worth confirming with Karri that blocking the whole Asian/off-hours window is intended.
- **Compounding interaction with flag #3:** see below.

### 3. INDICATOR_OANDA_FALLBACK — **SOUND (compute path) / RISK (interaction)**
- `computeATR`/`computeADX` (`indicators.ts`) return `null` cleanly on: insufficient bars (`< period+1` / `< 2*period+1`), non-array, any non-finite OHLC value. Division guards present (`smTR===0`, `diSum===0`). No throw, no NaN leak.
- `oandaOhlcForIndicator` (market-data.service.ts:50) returns `[]` on unsupported symbol / any OANDA failure → computeATR([]) → null. Weekend / no-candles → empty → null. Clean.
- Gated by flag AND `OANDA_API_TOKEN` presence. Falls through only after Twelve Data returns null.
- **Interaction RISK (the one to watch):** before this flag, Twelve Data's /atr 404s for XAU/USD so `atr` was frequently `null` → the `atr > 10` risk branch (analysis-agents.ts:521) and ATR-driven regime logic effectively never fired. Now ATR is populated from OANDA. So enabling INDICATOR_OANDA_FALLBACK **directly increases how often riskLevel hits "high"**, which — with RISK_LEVEL_HARD_GATE also on — increases hard-blocks. The two flags amplify each other. Also intended-but-worth-noting: ADX now populates → regime can reach TRENDING for the first time, which re-activates regime-direction gates that were silent no-ops. Behaviour shift is real and by design, but it lands the same day as the hard gate.

### 4. LESSON_INJECTION + agent_role fix — **SOUND**
- Both consumers (`risk-advisor.ts:114`, `trade-critic.ts:69`) call `buildLessonContext(...).catch(() => "")` → any query error degrades to empty string, prompt drops it without branching. Cannot break the agent.
- `buildLessonContext` (injection.ts:45) double-gated, returns "" when disabled, returns "" when 0 lessons. 0-approved-lessons today → clean no-op. Confirmed.
- **agent_role fix is in place and tested.** Old bug: deriver hardcoded `agent_role="lesson-deriver-stats"` but consumers query `WHERE agent_role IN ("risk-advisor","trade-critic")` → zero overlap, nothing ever injected. Fix: `derive-lessons.mjs` now fans out one row per target role (`DEFAULT_TARGET_ROLES=["risk-advisor","trade-critic"]`, override `LESSON_TARGET_ROLES`), self-IDs via `proposer_id`, distinct fingerprint per role. Guarded by real producer→consumer integration test `deriver-injection.integration.test.ts` incl. a regression test for the old tag.
- Note: injection only does something once lessons are *approved*. With 0 approved it's inert; this is correct and also keeps the trade-altering switch behind operator/Karri approval per the learning-infra boundary.

### 5. SHADOW_FORWARD_TEST — **SOUND**
- `recordForwardTestSnapshots` (shadow-log.ts:336) entire body in try/catch → logWarn, returns `{recorded:0}`. Caller also `.catch()`s (orchestrator.ts:565). No-op + zero queries when flag off.
- `extractForwardTestRow` pure, null-safe (`num()` rejects non-finite), handles missing/odd state shapes.
- `trackForwardTestOutcomes` (shadow-log.ts:411): try/catch wrapped; fetchPrice-null → skip; resolvable-guard prevents a no-triple row flipping to anything but `expired`; writes null price/0 pnl for non-resolvable. Caller `.catch()`s too. Cannot disrupt the cycle.

### 6. ORB_ONLY_MODE=false — **RISK (largest behavioural surface, no crash found)**
- This is the big one: it re-activates the **entire dormant firm decision path** — Prism synthesis + Blade approval + challenge agents + periodic calibration — that has been bypassed since 24.4 (orchestrator.ts:641-728). Code reads structurally intact (all 1148 tests green, path is exercised in tests), but it is the least-recently-live path in production.
- It is also the enabler for flag #1 (calibration only runs when `!orbOnlyMode`) and for the new-gates hard blocks taking effect on the firm path. So 4 of the 7 flags (SAFE_AUTO_APPLY, RISK_LEVEL_HARD_GATE on firm path, lesson injection into Blade-adjacent agents, calibration) only actually *do something* because ORB_ONLY_MODE went false.
- No null/throw found in the re-activated branch on read. The exposure is behavioural/regression, not a crash: the firm path's actual live P&L behaviour hasn't been observed since April, and it now runs simultaneously with brand-new gating + autotune.

---

## Overall judgment: **GO with caveats — no crash/hang bug found, but two coupled behavioural risks**

No code path among the seven will crash, throw into the cycle, or hang. Every learning/observability write (shadow fwd-test, lesson injection, calibration persist, gate-decision persist) is try/catch-swallowed per prinsipp 2. Calibration apply is triple-bounded and NaN-proof. Indicators return null cleanly on every edge. 1148/1148 green.

The two things to flag to operator/Karri (behaviour, not bugs):

1. **RISK_LEVEL_HARD_GATE + INDICATOR_OANDA_FALLBACK compound.** The fallback now populates ATR, which pushes riskLevel to "high" more often (atr>10), AND the producer marks the *entire Asian session + off-hours* as "elevated" unconditionally. With the hard gate on, that's a structural time-of-day + volatility block that likely cuts firm-path entries well beyond the "~46%" estimate. Confirm the Asian/off-hours full-block is intended before leaving both on.

2. **ORB_ONLY_MODE=false is the master enabler** for the calibration/autotune + hard-gate-on-firm-path behaviour, and it revives the longest-dormant decision path. Recommend watching the first full Asian→London→NY rotation closely: (a) firm-path entry count vs ORB-only baseline, (b) calibration_log rows with `applied=true` + the firm_state engine-multiplier snapshot to confirm autotune is moving multipliers within bounds, (c) gate_decisions `hard_rejected=true` rate by session.

If operator wants to de-risk the amplification: the cheapest single rollback is `RISK_LEVEL_HARD_GATE_ENABLED=false` (drops it back to soft-log while keeping the data), which decouples the ATR-fallback amplification from actual blocks without touching the rest.
