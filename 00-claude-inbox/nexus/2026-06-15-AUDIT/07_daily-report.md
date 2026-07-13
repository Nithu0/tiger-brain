# Audit Stage 11 — DAILY REPORT (does the system auto-generate a report a Claude agent can work from?)

**Date:** 2026-06-15
**Verdict:** **EXISTS** (with caveats) — but it is THREE overlapping systems, not one. The strongest one (LLM daily-journal + operator-brief) is genuinely a learning/work-ready report, runs automatically, and is stored durably. The original framing ("most likely just a health snapshot") is only true of ONE of the three.

---

## TL;DR

There is no `daily_reports` table. But there ARE two LLM-backed daily artifacts persisted to `agent_artifacts(kind='journal')` — `daily-journal` (end-of-day retrospective) and `operator-brief` (next-morning forward plan) — both running daily in production, both queryable historically (back to 2026-05-12), and both concrete enough that a fresh Claude agent could open them and know what to do. A THIRD system (`DAILY_MORNING_BRIEFING` Discord embed) is a rich health/market snapshot — NOT a learning report — and is ephemeral (Discord scrollback only).

So: distinguish carefully. "Morning health briefing" = the Discord embed (snapshot, ephemeral). "Daily learning report" = the LLM journal+brief artifacts (real, stored, actionable). Both exist.

---

## The three systems

### 1. `DAILY_MORNING_BRIEFING` Discord embed — HEALTH SNAPSHOT, ephemeral
- **Code:** `apps/worker/src/firm/notifications/detector.ts` (`tryBuildDailyMorningBriefing`, ~line 975) + `formatter.ts` (`formatDailyMorningBriefing`, ~line 706).
- **Trigger:** not a cron — fires inside the orchestrator cycle, once per UTC day on first `LONDON_PREPARE`/`LONDON_ACTIVE` cycle. Gate persisted via `firm_state(last_briefing_date_iso)` (live value: `2026-06-15`). Flag `DAILY_MORNING_BRIEFING_ENABLED` default true.
- **Goes to:** Discord embed only. NOT stored as a row. Lost to scrollback.
- **Content:** market snapshot (price/RSI/ATR/ADX/MACD/EMA), macro/cross-asset + FRED, analyst signals, narrative pulse, firm plan (regime/tradeability/managers/thesis/conviction), today's + week-ahead events, foundation-gate RED/YELLOW/GREEN, memory-health, gate-impact counterfactual, direction-mix, 24h ops status (open/closed/PnL/gates/warnings), and a "Recommended next action" with a ready-to-paste norsk prompt.
- **Verdict on this one:** This is a forward-looking situational + health dashboard. It does NOT say "what we learned" or "hypotheses to test" in a retrospective sense. It's the snapshot the original audit framing predicted — but it's only 1 of 3.

### 2. `daily-journal` agent (Atlas) — END-OF-DAY LEARNING RETROSPECTIVE, stored
- **Code:** `apps/worker/src/firm/agent-bus/firm-agents/daily-journal.ts`.
- **Trigger:** once per UTC day after **22:00 UTC**, dedup via `firm_state(firm_agent:daily-journal:last_journal_date_iso)`. Flag `FIRM_AGENT_DAILY_JOURNAL_ENABLED` (default false in code, but **ON in prod** — artifacts present + `last_run_iso` 2026-06-14).
- **Inputs:** today's closed trades (`simulated_orders`) + today's `postmortems`. Calls Claude (`callClaude`).
- **Output structure (prompt-enforced):** `### One-line takeaway`, `### What happened (≤6 bullets)`, `### What worked / what didn't`, `### Tomorrow's watch-list (≤3)`.
- **Stored:** `agent_artifacts(kind='journal')` with metadata{date, trades, postmortems, total_pnl, wins}. Durable + queryable. Also publishes headline to blackboard `xauusd.journal.daily`.

### 3. `operator-brief` agent (Atlas) — NEXT-MORNING FORWARD PLAN, stored + Discord + mobile
- **Code:** `apps/worker/src/firm/agent-bus/firm-agents/operator-brief.ts`.
- **Trigger:** once per UTC day after **06:00 UTC**, advisory-lock + `firm_state` dedup. Flag `FIRM_AGENT_OPERATOR_BRIEF_ENABLED` (default false in code, **ON in prod** — `last_brief_date_iso=2026-06-15`).
- **Inputs:** yesterday's closed trades, open positions, 24h risk advisories, yesterday's daily-journal artifact, dominant narrative, macro events. Calls Claude.
- **Output structure:** `### Headline`, `### Numbers` (pnl, wins/total, biggest win/loss), `### Open positions`, `### Macro & narrative`, `### Today's three things`.
- **Stored:** `agent_artifacts(kind='journal', metadata.kind='morning-brief')`; also Discord embed via `sendMorningBriefEmbed`; also pushed to operator mobile via Syncthing outbox (firm-mirror).

There is also a legacy `apps/worker/src/agents/briefing.agent.ts` (`runBriefing`) — OpenRouter LLM, ≤200 words, writes to `agent_events`, sends Telegram/Discord/Notion. Older/parallel path; the firm-agent pair above is the live one.

---

## Live evidence (production DB, queried 2026-06-15)

- `agent_artifacts(kind='journal')`: daily cadence confirmed. daily-journal artifacts every day 2026-05-12 → 2026-06-14 (20 rows); operator-brief artifacts every morning through 2026-06-15.
- `firm_state`: `last_briefing_date_iso=2026-06-15`, `daily-journal:last_journal_date_iso=2026-06-14`, `operator-brief:last_brief_date_iso=2026-06-15`, `last_pulse_state=RED`.
- **Foundation gate is RED** (since ~2026-06-13). The reports honestly surface this.

### Actual content sample (2026-06-14 daily-journal, verbatim excerpt)
> One-line takeaway: Zero managed trades; two external broker closes leaked -$329.56 with no local lifecycle awareness.
> What didn't: Local lifecycle never registered open/close for 1584 and 1578 ... Zero strategy activity suggests signal generator or order router may also be impaired.
> Tomorrow's watch-list: Audit order router → broker handshake; Verify signal engine produced any candidates today; Add real-time broker position diff alert (<5 min).

### Actual content sample (2026-06-15 operator-brief, verbatim excerpt)
> Today's three things:
> - Fix the lifecycle gap: confirm order router persists trade IDs locally on submit; no new orders until handshake verified.
> - Check the signal engine is alive: zero candidates yesterday is suspicious — verify it's producing, not silently dead.
> - NFP playbook: size down or stand aside through the print.

This is concrete and directly actionable. A fresh Claude agent reading the 2026-06-15 brief would know exactly what to investigate (router handshake, dead signal engine, NFP posture).

---

## Required-content scorecard (against the audit's checklist)

Aggregating across daily-journal + operator-brief (the learning pair), plus the Discord briefing where relevant:

| Required item | Present? | Where |
|---|---|---|
| What happened last 24h | YES | journal "What happened" |
| How many signals generated | **WEAK** | trade counts yes; *signal/candidate* count NOT directly queried — the 2026-06-14 journal had to *infer* "signal generator may be dead" from zero trades, not from a signal count |
| How many paper trades | YES | trade counts + PnL from simulated_orders |
| Best/worst strategies | **PARTIAL** | strategy_id is in the prompt inputs, but recent days had 0 managed trades so no attribution surfaced; no explicit per-strategy win-rate rollup in the report |
| Which market conditions worked/didn't | PARTIAL | journal "What worked / didn't" + regime_at_entry in inputs; thin when 0 trades |
| Errors/bugs that occurred | YES (emergent) | lifecycle gap, orphan closes surfaced clearly |
| What the system LEARNED | YES | journal "What worked/didn't" is the learning section |
| Which hypotheses to test | YES | "watch-list" / "Today's three things" function as hypotheses |
| Concrete tasks for agents today | YES | operator-brief "Today's three things" are literal tasks |
| Strategies to keep/discard/investigate | **NO** | no explicit keep/discard/investigate verdict per strategy module |

Notable GAPS: (1) no explicit **signal/candidate generation count** — the report infers liveness from trade count, which is fragile; (2) no **per-strategy keep/discard/investigate** ledger; (3) best/worst-strategy attribution is shallow because input is raw trade rows, not a strategy-performance rollup.

---

## Answers to the 5 questions

1. **Auto-generated?** YES, three of them, all automatic. None is a true OS cron — all fire from the always-on worker orchestrator with time-gates: Discord briefing on first London cycle/day; daily-journal after 22:00 UTC; operator-brief after 06:00 UTC. Dedup via `firm_state`. Discord briefing → Discord only; the two LLM reports → DB `agent_artifacts` + Discord + mobile.

2. **Actually contains vs misses:** Contains: what happened, trade counts/PnL, what worked/didn't, learnings, watch-list/hypotheses, concrete next tasks, open positions, macro/NFP risk, honest infra-bug surfacing. Misses: explicit signal/candidate counts, per-strategy performance attribution, and an explicit keep/discard/investigate strategy verdict.

3. **Does it state learnings / hypotheses / tasks for today?** YES — this is the core strength of the LLM pair. daily-journal gives learnings + watch-list; operator-brief gives "Today's three things" (literal tasks). The Discord-only briefing does NOT (it's situational), so if you only looked at the Discord embed you'd wrongly conclude "snapshot only."

4. **Stored or ephemeral?** BOTH. The Discord `DAILY_MORNING_BRIEFING` embed is ephemeral (scrollback). The daily-journal + operator-brief are STORED durably in `agent_artifacts(kind='journal')`, queryable, trendable over time (20+ daily-journal rows since 2026-05-12). So trends ARE queryable — just not in a purpose-named `daily_reports` table.

5. **Could a fresh Claude agent work from today's report?** YES. The 2026-06-15 operator-brief alone gives three crisp, prioritized, executable tasks with rationale. A fresh agent would know to (a) verify order-router→broker trade-ID persistence, (b) check whether the signal engine is silently dead, (c) set NFP posture. That is exactly the "work directly from it" bar.

---

## VERDICT: EXISTS

A real auto-generated daily learning report exists and runs in production: the `daily-journal` (retrospective) + `operator-brief` (forward plan) LLM agents, stored durably in `agent_artifacts`. It clears the "a Claude agent can work directly from it" bar today.

Downgrade factors keeping it short of full marks:
- **No `daily_reports` table** — storage piggybacks on `agent_artifacts(kind='journal')`; works but not purpose-built, and metadata is thin (no signal counts, no per-strategy rollup).
- **Three overlapping systems** with confusing overlap (Discord briefing vs journal vs operator-brief vs legacy runBriefing) — a reviewer glancing only at the Discord embed would mis-grade this as "health snapshot only."
- **Content gaps:** signal-generation count, per-strategy best/worst attribution, and explicit keep/discard/investigate strategy verdicts are absent. Quality of the report is currently propped up by the LLM reasoning over raw trade rows rather than by a structured performance-rollup feeding it.
- Reports are only as rich as the trading activity — with ~0 managed trades the last several days (foundation gate RED), recent reports are dominated by infra/lifecycle issues rather than strategy learning. That's honest, but it means the "strategy learning" muscle is currently unexercised.

## Recommended improvements (for the firm, not auto-applied)
1. Add explicit signal/candidate counts to the journal inputs (query the signal/decision-cycle source) so "is the engine alive" is measured, not inferred.
2. Feed a per-strategy 24h/7d performance rollup into the daily-journal prompt and require a keep/discard/investigate line per active strategy module.
3. Consider a purpose-named `daily_reports` table (or a typed view over `agent_artifacts`) for cleaner trend queries.
