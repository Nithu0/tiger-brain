# Nexus Learning-Loop Closure Audit — does the loop actually CLOSE?

Date: 2026-06-15
Scope: trace the operator's required 13-stage learning loop link-by-link and find where output of stage N does NOT feed stage N+1.
Method: read orchestrator.ts runCycle(), index.ts schedules, calibration.ts, session-window.ts, agent-lessons/injection.ts, firehose/derive-lessons.mjs + auto-promote-lessons.mjs, engine-attribution/*, shadow-log.ts, backtest runner/route, agent-bus/agent-trigger.ts + drainers, status-report.ts, daily-journal.ts. Three parallel sub-agents traced the engine-weight, agent-task, and backtest/versioning sub-loops.

## VERDICT: The loop does NOT close. It is open in at least 5 places, and ~4 stages are dormant behind default-OFF flags.

The first half (market data → paper trade → result logging → evaluation) is genuinely WIRED and runs live every cycle. Everything from **hypothesis generation onward is either default-OFF, untested, or has no consumer**. The system's "learning" today is: derive WR-clusters from live trades → (if flags flipped) inject as text into LLM agent prompts. That is "agents think harder," not "measured feedback changes behaviour."

---

## Link-by-link

| # | Link | Verdict | Evidence |
|---|------|---------|----------|
| 1 | market data → signal generation | **WIRED** | orchestrator Step 1 `runAllFactAgents` (422), Step 1b-1j strategy evals; price from board/OANDA. |
| 2 | signal → paper trade | **WIRED** | Step 1f `runStrategyExecution` (611) → tryOpenPosition; or Prism/Blade → `executionManager` (722). |
| 3 | paper trade → result logging | **WIRED** | `simulated_orders` + `syncOandaPositions` (306) reconciles closes; `checkAndClosePositions`. |
| 4 | result → evaluation (postmortem) | **WIRED** | Step 0c `runPostmortemForNewlyClosedTrades` (417) → `firm_memory` postmortems; `reviewClosedTrade`. |
| 5 | evaluation → hypothesis (lessons) | **PARTIAL/disconnected** | Two separate eval systems that don't talk. `runCalibration` (777) reads `firm_memory` postmortems → `calibration_log`. `derive-lessons.mjs` (cron 04:00, index.ts:232-344) reads **live `simulated_orders` WR-clusters**, NOT postmortem failureClass output. Hypotheses are generated, but from raw WR, not from the evaluation/failure-classification stage. Gated default-OFF (`AGENT_LESSONS_ENABLED`+`LESSON_DERIVATION_ENABLED`). |
| 6 | hypothesis → backtest | **DEAD** | `derive-lessons` + `auto-promote-lessons.mjs` promote on **live sample-size+consistency only** (auto-promote `evaluateEligibility` n>=8, consistency>=0.8). No backtest call anywhere in the path. `runBacktest` (apps/api/src/backtest/runner.ts:419) is invoked **only** by `POST /backtest` (human HTTP). No cron/orchestrator/derive caller. |
| 7 | backtest → strategy version | **DEAD** | No `strategy_version`/champion-challenger object exists anywhere in firm/ or docs/strategy/. A passing backtest creates nothing. |
| 8 | version → comparison vs previous | **DEAD** | No version object → nothing to compare. `new-strategy-gate.md` 5 rules are ops-health, none require a backtest or comparison. |
| 9 | comparison → live (validated gate) | **DEAD/manual** | Strategies ship by manual env-flag flip (`*_ENABLED`). Lessons reach live via prompt injection **untested**. The only real gate is human Karri review of hand-written proposal docs. |
| 10 | evaluation/lessons → daily report | **PARTIAL** | `status-report.ts` produces a structured `recommendedAction` + checkpoint prompt (for a HUMAN session). `daily-journal.ts` (Atlas, default-OFF) writes narrative "what worked / tomorrow's watch-list" to `agent_artifacts`. Reports exist; they carry narrative + an operator instruction, not queued tasks. |
| 11 | report → concrete agent tasks | **PARTIAL, default-OFF** | `agent-trigger.ts` publishes `agent_tasks` on loss-streak/postmortem/regime-flip/gate-spike — but the payload is an **LLM prompt asking for a diagnosis**, not a structured change. Gated `AGENT_TRIGGER_PUBLISH_ENABLED` default-OFF. Daily-journal watch-list items are never converted to tasks. |
| 12 | agent task → implementation | **PARTIAL, default-OFF** | `research-drainer.ts` (default-OFF) just calls Gemini → writes a `research_note` text artifact. The ONLY real-code path is `agent-codex-runner.mjs` → diff → review → `agent-pr-opener.mjs` → **open PR (never auto-merge)** requiring human merge. None of the trigger conditions route to that code path (they're role=research/review). |
| 13 | implementation → new test cycle (verification) | **DEAD** | No code anywhere compares before/after metrics tied to a task id or re-checks a hypothesis after its observation window. Loss-streak prompt asks for "one falsifiable hypothesis + observation window" — nothing ever re-reads it. `parent_task_id` links only codex→review threading. Pure fire-and-forget. |

Plus a 14th hidden dead link inside the calibration sub-system:

| 14 | calibration recommendation → live thresholds | **DEAD (session) / PARTIAL-but-STARVED (engine)** | SESSION: `runCalibration` writes `calibration_log` with `applied=true` under SAFE_AUTO_APPLY, but **nothing reads it back**. The live consumer `getSessionThresholds` (session-window.ts:299) returns baseline+cold-start delta only; `getActiveProfile` (calibration.ts:362-366) is an admitted stub that "would query calibration_profiles" but returns baseline. So even autotune-apply on session thresholds is a no-op on live behaviour. ENGINE: `calibrateEngineWeights`→`setEnginePerformanceMultipliers`→ read in conviction/scoring.ts:53 IS a closed code loop, BUT the only `engine_scores` writer (`recordCycleSnapshot`, managers.ts:693) lives inside the Prism/Blade path which `ORB_ONLY_MODE=true` (current prod) bypasses → input starves within ~7d, multipliers freeze at 1.0 (and reset to 1.0 on every restart, config.ts:103). The conviction reader is ALSO bypassed under ORB_ONLY. Loop connected in code, broken at write+read in prod. |

---

## Shortest set of broken links to actually close the loop (critical path)

The loop is so open that "fix the 3 worst links" understates it, but the minimum spanning set that converts this from "agents think harder" to "measured feedback changes behaviour":

1. **Link 14 (calibration→live) FIRST.** This is the cheapest real win and it is silently dead. Make `getSessionThresholds`/`getActiveProfile` actually read applied `calibration_log`/`calibration_profiles` rows. Without this, the one fully-built statistical learning engine (postmortem→calibration) changes nothing. And relocate `recordCycleSnapshot` out of the ORB_ONLY-bypassed path (or accept engine-weight learning is dead while ORB_ONLY=true). Today autotune is structurally a no-op even when enabled.
2. **Link 6 (hypothesis→backtest).** Insert a backtest/forward-test pass between lesson `proposed` and `approved`. Currently lessons go live-WR → approved → prompt with zero historical validation. This is the operator's core fear made concrete.
3. **Link 13 (implementation→verification).** Add a `parent_task_id`-keyed before/after metric check that re-reads the falsifiable hypothesis after its observation window. Without this the loop physically cannot tell whether any change helped — it can never "learn" in the closed-loop sense, only accumulate untested text.

Links 7/8/9 (versioning + comparison gate) are the bigger architectural build, but they are downstream of 6 and verification 13; do those first.

---

## Operator's core fear: "the system learns by agents thinking more, not by measured feedback." JUSTIFIED.

Where measured feedback degrades into just-think-harder:
- **Lessons are text injected into LLM prompts** (injection.ts:46 `buildLessonContext` → risk-advisor/trade-critic system prompts). The "learning" is: a statistic becomes a sentence an LLM reads. No closed-loop measurement that the injected lesson improved outcomes.
- **The one true statistical feedback engine (calibration) writes to a log nothing reads back** (link 14 session-side). So measured feedback exists, is computed, is logged — and is then dropped on the floor before it can touch a threshold.
- **The only engine-weight loop that IS code-complete is starved** by ORB_ONLY_MODE — measured feedback with no input.
- **No backtest gate** anywhere between hypothesis and acceptance (link 6) — so even the hypotheses that do flow are accepted on small live samples, not validated.
- **No verification arm** (link 13) — the system never measures whether a change it made helped. That is the definition of an open loop.

The half that's measured (data→trade→postmortem→WR-cluster) is real and good. Everything that would let a measurement *change the system and then confirm the change worked* is either dead, starved, stubbed, or default-OFF.

## Flag-dependency summary (stages that are DEAD-in-practice because their flag is OFF)
- Link 5/6 hypothesis: `AGENT_LESSONS_ENABLED`=OFF, `LESSON_DERIVATION_ENABLED`=OFF, `LESSON_AUTO_PROMOTE_ENABLED`=OFF
- Link 9 lesson→live: `LESSON_INJECTION_ENABLED`=OFF
- Link 10 daily report: `FIRM_AGENT_DAILY_JOURNAL_ENABLED`=OFF
- Link 11 tasks: `AGENT_TRIGGER_PUBLISH_ENABLED`=OFF
- Link 12 drain/implement: `FIRM_RESEARCH_DRAINER_ENABLED`=OFF, `AGENT_BUS_ENABLED`=OFF
- Link 14 engine: `CALIBRATION_MODE` defaults RECOMMEND_ONLY (no apply); and ORB_ONLY_MODE=ON starves input regardless.

Note the deliberate human-merge gate (codex→PR never auto-merges) and RECOMMEND_ONLY default are BY DESIGN per operator-prinsipp #1 / strategy-review protocol — not bugs. The genuine bugs/gaps are: link 14 dead read-back, link 6 absent backtest gate, link 13 absent verification.
