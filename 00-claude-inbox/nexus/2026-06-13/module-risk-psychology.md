---
title: Module — Risk / Psychology (Trading in the Zone → Nexus rules)
date: 2026-06-13
author: Claude (Opus 4.8)
module: risk-psychology
source_book: "Trading in the Zone — Mark Douglas"
tags: [nexus, risk, psychology, audit, spec, claude-inbox]
status: analysis-and-spec
---

# Risk / Psychology module — audit + gap spec

**Mandate:** convert Mark Douglas's *Trading in the Zone* principles into enforceable
rules — max risk/trade, max daily loss, R:R, probabilistic thinking. Nexus already
has substantial risk infra; this is mostly **audit + close gaps**, not greenfield.

**Bottom line up front:** Nexus mechanically encodes most of the book already. The
machine *cannot* revenge-trade, *cannot* martingale, *cannot* move a stop emotionally
— those are structural invariants, which is exactly Douglas's ideal ("a trader who
operates from a carefree state of mind because the risk is genuinely defined and
accepted"). The **one principle with no enforcement at all is minimum R:R** — the
execution path accepts any `takeProfitPoints > 0`, so a 0.5:1 reward trade passes the
same as a 3:1. That is the #1 rule to add.

---

## 1. Principle → mechanism map (covered vs gap)

Douglas's framework reduces to a handful of operational commitments. Mapping each to
the live Nexus mechanism:

| Douglas principle | Operational meaning | Nexus mechanism | Status |
|---|---|---|---|
| **"Define your risk before the trade"** | Every position has a pre-set, bounded loss | Per-trade risk-at-stop capped at `EXPOSURE_MAX_RISK_PER_TRADE_PCT` (0.75% default, prod 0.15%); SL is mandatory — `strategy-execution.ts` rejects on `stopLossPoints <= 0` | **COVERED** — `exposure/rules.ts` + `portfolio-check.ts` |
| **"Accept the risk fully" (no catastrophic single loss)** | Hard ceiling on any one trade's size | Position-size circuit breaker: clamp at `MAX_UNITS_PER_TRADE=80` **and** `MAX_NOTIONAL_PCT=300%` of equity (LIVE, PR #61, data-calibrated on 173 real trades) | **COVERED** — `strategy-execution.ts:positionSizeCircuitBreaker()` |
| **Aggregate exposure discipline** | Total + directional book risk bounded | `maxTotalExposurePct=3%`, `maxDirectionExposurePct=2%`, `maxOpenTrades=3`; resize-before-reject semantics | **COVERED** — `portfolio-check.ts` |
| **"A losing day is just a sample, not a verdict" → stop digging** | Daily loss floor halts all strategies | `checkDailyLossCap` — portfolio PnL ≤ −`DAILY_LOSS_CAP_USD` (200 default) halts new entries, UTC-midnight reset | **COVERED (default OFF)** — `daily-loss-cap/index.ts` |
| **Overtrading kills the edge** | Cap trades per day | `evaluateDailyTradeCap` — cross-strategy cap=6/UTC-day (Karri's 152-trade evidence: ≥8/day = catastrophe band) | **COVERED (default OFF)** — `gates/daily-trade-cap-gate.ts` |
| **"Don't trade to get even" (anti-revenge / anti-tilt)** | Cool off after losses | `loss-streak-pauser` (pause N hours after X consecutive SL) + `sl-cooldown-gate` (block same strategy N min after an SL hit, cleared by next win) | **COVERED (default OFF)** — `loss-streak-pauser/`, `gates/sl-cooldown-gate.ts` |
| **"Never widen a stop" (no hoping a loser back)** | Stops only move in your favour | Tighten-only invariant: trailing/BE only ever *tighten*; SL-widening explicitly refused as martingale (memory `feedback_sl_widening_is_martingale`) | **COVERED** — `position-management/lifecycle.ts` |
| **Probabilistic thinking — consistent sizing** | Same process every trade, outcome-independent | Sizing is a deterministic function of balance × regime-mult × mode-mult; no "conviction → bigger after a win" loop in the live path | **COVERED (structurally)** — `exposure/rules.ts` |
| **Probabilistic thinking — favourable expectancy per trade** | Reward must justify risk → **min R:R** | **None.** Execution validates only `takeProfitPoints > 0`. Each strategy sets its own TP; nothing rejects a sub-1:1 trade | **GAP — the core one** |
| **"The 5 fundamental truths" self-honesty** | System should self-audit consistency vs its own rules | Rich observability (gate_decisions, v146-decision-log, shadow-log) but **no consistency-drift report** that flags "sizing/R:R deviated from policy" | **PARTIAL — observability exists, no consistency self-audit** |
| **No trading into known uncertainty (high-impact news)** | Stand aside around scheduled events | News-router (Finnhub calendar skip) + event-policy size multiplier (PRE_EVENT_CAUTION / BLACKOUT → mult 0) + spread-gate | **COVERED (default OFF)** — `strategy-execution.ts` news-router + event multiplier in `portfolio-check.ts` |

### Gate stack (live order, for reference)
`strategy-blade.ts` + `strategy-execution.ts` chain, in evaluation order:
sl_cooldown → regime_direction → daily_trade_cap → mean_revert_gate → spread_gate →
news_router → daily_loss_cap → loss_streak_pauser → portfolio_check (sizing/exposure)
→ position_size_circuit_breaker (final, pre-broker).

**Almost everything is default-OFF and env-gated** with 30-second Railway rollback.
The circuit breaker is the notable exception — it ships `ENABLED=true` (operator's
"egentlige sikkerhet mot blowup-gjentakelse").

---

## 2. Does Nexus think probabilistically?

Yes, structurally — and this is the strongest part of the audit. Douglas's whole thesis
is that the edge plays out over a *series*, so the trader must (a) size consistently,
(b) not revenge-trade, (c) not move stops emotionally. Nexus encodes all three as
**invariants the code physically cannot violate**, not as discipline it has to
remember:

- **Consistent sizing** — size is a pure function of `balance × regimeMult × modeMult`,
  capped per-trade. There is no path where "we just won, bet bigger" inflates the next
  position. Size scales *inversely* with stop distance (wider stop → smaller size), so
  $-risk stays roughly constant regardless of setup. This is textbook fixed-fractional.
- **No revenge-trading** — sl-cooldown + loss-streak-pauser actively *remove* the
  strategy from the market after losses, which is the opposite of tilt.
- **No emotional stop moves** — tighten-only invariant. The system has no lever to
  "give a loser room", and SL-widening is hard-refused as martingale.

**What's missing on the probabilistic side:** the per-trade *expectancy* check. Douglas
says any single trade is random but you only have an edge if **reward > risk × win-rate
break-even**. Nexus controls the *risk* leg tightly but never checks the *reward* leg.
A strategy can fire a 0.7:1 trade and the firm will happily size and execute it. Over a
series, sub-1:1 R:R with a <60% win rate is negative expectancy — exactly the leak
Douglas warns about. The master prompt's "R:R ≥ 2" is the explicit fix.

---

## 3. Concrete gaps to close (as rules)

Ordered by value. Each tagged **Claude-infra** (observability/gates I can build +
ship default-OFF freely per the learning-infra boundary) vs **Karri-gated** (changes
trade behaviour → proposal first).

### GAP 1 — Minimum R:R gate *(the #1 rule — see §4)*
- **Rule:** reject any signal whose `takeProfitPoints / stopLossPoints < MIN_RR`
  (default target 2.0 per master prompt).
- **Where:** new gate `gates/min-rr-gate.ts`, called in `strategy-execution.ts` right
  after the existing `stopLossPoints/takeProfitPoints` distance validation (~line 541),
  before sizing.
- **Classification:** building it default-OFF in **shadow/observe** mode (log what
  *would* be rejected, never block) is **Claude-infra**. Flipping it to actually block
  trades is **Karri-gated** (it changes which trades execute).

### GAP 2 — Consistency / sizing-drift self-audit ("5 fundamentals" report)
- **Rule:** a daily report flagging when realised behaviour deviated from policy —
  e.g. executed risk% > intended, R:R distribution, trades/day vs cap, any
  stop-widening (should always be zero). Surfaces tilt/process-drift to the morning
  briefing; does **not** alter trades.
- **Where:** extend `notifications/loss-and-activation-monitor.ts` or a new
  `risk-consistency-report`. Reads `simulated_orders` + `gate_decisions`.
- **Classification:** **Claude-infra** (pure observability, reports only — aligns with
  principle 1 "health-check REPORTS, operator decides").

### GAP 3 — Hard news-blackout as an *invariant*, not an opt-in
- **Rule:** Douglas's "don't trade into known uncertainty" → make the high-impact
  news blackout a default-ON guardrail rather than a default-OFF flag. Currently the
  news-router exists but is off; mean-reversion's news-block is flagged "unresolved" in
  the library.
- **Classification:** **Karri-gated** — turning a guardrail on changes trade behaviour
  and the mean-rev news-block is explicitly his open question. Propose, don't flip.

### GAP 4 — Make `RISK_LEVEL_HARD_GATE` real
- **Rule:** the elevated/high/extreme risk-level reject is near-inert because
  `risk_level_at_entry` is NULL on 150/173 trades. Fix the signal population, *then*
  the gate becomes a meaningful "don't take high-risk setups" rule.
- **Classification:** fixing the signal population is **Claude-infra** (bug/observability
  — restores intended behaviour). Re-enabling the gate afterwards is **Karri-gated**.

### Already covered — explicitly NOT gaps (do not rebuild)
Per-trade risk %, position-size circuit breaker, aggregate/directional exposure caps,
daily-loss-cap, daily-trade-cap, loss-streak-pause, sl-cooldown, tighten-only SL. The
work there is **activation discipline** (most are default-OFF), not new code — and
activation is operator/Karri's call, not mine.

---

## 4. Phasing — the #1 highest-value rule to add

**#1: Minimum R:R gate (`MIN_RR`, default 2.0).** Directly from the master prompt's
"R:R ≥ 2" and it closes the single uncovered Douglas principle (favourable expectancy
per trade). It's the highest-leverage addition because every other risk mechanism
controls the *downside* leg; this is the only one that guarantees the *upside* leg
justifies the risk — the actual definition of an edge.

**Phase plan:**

1. **Phase 0 (Claude-infra, ship now, OFF):** build `gates/min-rr-gate.ts` +
   `MIN_RR_GATE_ENABLED` (default false) + `MIN_RR` (default 2.0, bounded e.g.
   [1.0, 5.0]). Wire it in shadow mode — compute `tpPoints/slPoints`, log to
   `gate_decisions` what *would* be rejected, **never block**. Add tests. This is pure
   observability → no proposal needed, fits the learning-infra-vs-strategy boundary.
2. **Phase 1 (measure):** run shadow for a window. Report: how many live trades had
   R:R < 2, what their realised PnL was. This gives Karri the evidence bar he demands
   (he rejected "made-up risk numbers" before — same discipline applies here).
3. **Phase 2 (Karri-gated):** file `docs/strategy/proposals/2026-06-13_min_rr_gate.md`
   with the shadow evidence. On Karri-OK, flip `MIN_RR_GATE_ENABLED=true` to actually
   block sub-2.0 R:R signals. 30-second rollback via the env flag.

**Phase 2+ (lower priority):** GAP 2 consistency-report (Claude-infra, anytime), then
GAP 4 risk_level signal fix, then GAP 3 news-blackout-as-default (Karri).

---

## Source files (ground truth)
- `apps/worker/src/firm/exposure/rules.ts` — all hard caps + regime/mode multipliers
- `apps/worker/src/firm/exposure/portfolio-check.ts` — authoritative sizing + exposure gate
- `apps/worker/src/firm/strategy-execution.ts` — `positionSizeCircuitBreaker()` (~L117),
  distance validation (~L541, **where min-RR gate would go**), gate chain
- `apps/worker/src/firm/daily-loss-cap/index.ts`
- `apps/worker/src/firm/loss-streak-pauser/index.ts`
- `apps/worker/src/firm/gates/daily-trade-cap-gate.ts`
- `apps/worker/src/firm/gates/sl-cooldown-gate.ts`
- `apps/worker/src/firm/position-management/lifecycle.ts` — tighten-only trailing/BE
- `docs/ops/handoff-nithu-3-risk-tasks-2026-06-04.md` — circuit-breaker context + open items
- Library: `_library/trading/sources/karri_quotes_corpus` (#sl #sizing), `karri_mental_model`
- Memory: `feedback_sl_widening_is_martingale`, `feedback_learning_infra_vs_strategy`
