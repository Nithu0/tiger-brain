---
title: Nexus firm-agent activation readiness
date: 2026-05-11
type: ops-map
status: live
---

# Firm-agent activation readiness

Map of the 10 firm-agents coded in `apps/worker/src/firm/agent-bus/firm-agents/` (+ `firm/predictions/regression-predictor.ts`), what it takes to flip each ON in production, dependencies, risk class, and a recommended activation order.

## Important live-state finding (overrides "all OFF default")

The premise of this audit was "all flags OFF by default". The defaults in `.env.example` are OFF, but **production Railway has flipped most of them ON** during the 2026-05-03 Batman+Prediction batch (see memory `agentic_team_activation_state.md`). DB evidence (2026-05-11):

- `firm_state.firm_agent:*:last_run_iso` rows show **7 of 10** agents have ticked in the last 48h:
  - `risk-advisor` — last 2026-05-11 09:57 UTC (most active; 5-min cooldown)
  - `trade-critic` — last 2026-05-11 09:55 UTC
  - `regression-predictor` — last 2026-05-11 09:54 UTC
  - `narrative` — last 2026-05-11 09:35 UTC
  - `market-research` — last 2026-05-11 09:06 UTC
  - `daily-journal` — last 2026-05-09 23:29 UTC (once-per-day, expected)
  - `research-drainer` (bus-side) — last 2026-05-11 09:59 UTC
- Bus tables: 73 `agent_tasks` total (43 research + 30 review), 48 success / 25 error results, 29 review + 19 research_note artifacts.
- `firm_memory`: 199 postmortem rows + 102 regime rows in last 14d (`trade-critic` + `market-research` are writing).

**Agents NOT seen ticking** (need verification on Railway flag state):
- `macro-event`, `fill-quality`, `strategy-tuner`, `operator-brief` — no `firm_state` rows visible.

Net: activation work is mostly about (a) confirming Railway env-state matches intent for the silent four, (b) ensuring delivery (Discord) is double-gated correctly, and (c) deciding when to push beyond Phase 3 into Phase 2/4 (code-worker + trading-loop-aware proposals).

## Master switches (must be ON before any per-agent flag matters)

| Flag | Default | Purpose |
|---|---|---|
| `AGENT_BUS_ENABLED` | `false` | Master kill for bus tables, CLI, dispatchers. CLI refuses without `--force`. Required for research-drainer + any agent-task enqueue. |
| `FIRM_AGENTS_ENABLED` | `false` | Master kill for `tickFirmAgents()` in `runCycle()`. When false, every per-agent flag is silent no-op. |
| `FIRM_AGENTS_TICK_BUDGET_SEC` | `240` | Total wall-clock per cycle across all agents. |
| `GEMINI_API_KEY` / `GOOGLE_API_KEY` | unset | Required for Gemini-backed agents (market-research, narrative, macro-event) since Railway container has no `gemini` CLI. |
| `ANTHROPIC_API_KEY` | unset | Required for Claude-backed agents (the other 7). |
| `AGENT_DISCORD_DELIVERY_ENABLED` | `false` | Routes risk advisories + morning brief + high-pri triggers to Discord. **Double-gate:** also needs `DISCORD_LEGACY_ENABLED=true` (per memory `project_discord_delivery_dual_gate.md`) or pings silently no-op. |

Activation playbook for **any** agent is the same shape:
1. Verify masters above are ON on Railway.
2. Flip the per-agent flag `FIRM_AGENT_<NAME>_ENABLED=true`.
3. Redeploy (or wait for next deploy — Railway picks up env-vars on next worker restart).
4. Verify via `firm_state` row appearing within 1 cooldown-interval and `/firm-agents/overview` dashboard card flipping from "disabled" to "ok"/"cooldown".

## The 10 agents

### 1. market-research (Cipher)

- **Purpose**: Hourly XAUUSD-relevant summary from last hour of `news_headlines` + most recent `narrative_clusters`. Writes blackboard `xauusd.market_research.summary` + `firm_memory(regime)`.
- **Flag**: `FIRM_AGENT_MARKET_RESEARCH_ENABLED`
- **Cooldown var**: `FIRM_AGENT_MARKET_RESEARCH_COOLDOWN_SEC` (default 3600 / 1h)
- **Dependencies**: `AGENT_BUS_ENABLED`, `FIRM_AGENTS_ENABLED`, `GEMINI_API_KEY`, `news_headlines` table populated.
- **Risk class**: **read-only-research**. Writes only to blackboard + `firm_memory`. Never touches trades.
- **Action to activate**: flip flag + redeploy. Already ON in prod per live data.
- **Live status (11.5)**: ACTIVE, last tick 09:06 UTC.
- **Source**: `apps/worker/src/firm/agent-bus/firm-agents/market-research.ts`

### 2. narrative (Cipher)

- **Purpose**: 30-min cadence. Joins `narrative_clusters` + `cross_asset_snapshots`, asks Gemini to label dominant narrative (RISK_OFF/RISK_ON/DOLLAR_STRENGTH/.../NONE) with 1-line why. Blackboard `xauusd.narrative.dominant`.
- **Flag**: `FIRM_AGENT_NARRATIVE_ENABLED`
- **Cooldown var**: `FIRM_AGENT_NARRATIVE_COOLDOWN_SEC` (default 1800)
- **Dependencies**: masters + `GEMINI_API_KEY` + `narrative_clusters` populated.
- **Risk class**: **read-only-research**. Blackboard write only.
- **Action to activate**: flag + redeploy.
- **Live status (11.5)**: ACTIVE, last tick 09:35 UTC.
- **Source**: `apps/worker/src/firm/agent-bus/firm-agents/narrative.ts`

### 3. risk-advisor (Shield)

- **Purpose**: 5-min cadence. Reads open positions + latest `portfolio_regime` + last 20 `gate_decisions`. Claude flags misaligned trades. **ADVISORY ONLY** — no close, no block, no mutate. Blackboard `xauusd.risk.advisory` (severity OK/WATCH/ALERT).
- **Flag**: `FIRM_AGENT_RISK_ADVISOR_ENABLED`
- **Cooldown var**: `FIRM_AGENT_RISK_ADVISOR_COOLDOWN_SEC` (default 300)
- **Dependencies**: masters + `ANTHROPIC_API_KEY`. Discord delivery: `AGENT_DISCORD_DELIVERY_ENABLED=true` + `DISCORD_LEGACY_ENABLED=true` + `DISCORD_BOT_TOKEN`+`DISCORD_CHANNEL_ID` for advisory pings.
- **Risk class**: **read-only-research with side-channel** (Discord ping). Trades cannot be affected at code level (`riskAdvisorAgent` never calls `Blackboard.publish()` to trading topics, never closes orders).
- **Action to activate**: flag + redeploy.
- **Live status (11.5)**: ACTIVE, last tick 09:57 UTC (every cycle effectively).
- **Source**: `apps/worker/src/firm/agent-bus/firm-agents/risk-advisor.ts`

### 4. trade-critic (Atlas)

- **Purpose**: Hourly. Reads most recent 30 postmortems, Claude finds SYSTEMIC patterns (regime mismatches, close_reason chains, post-news exposure). Writes max 1 consolidated lesson row per tick to `firm_memory(postmortem)`.
- **Flag**: `FIRM_AGENT_TRADE_CRITIC_ENABLED`
- **Cooldown var**: `FIRM_AGENT_TRADE_CRITIC_COOLDOWN_SEC` (default 3600)
- **Dependencies**: masters + `ANTHROPIC_API_KEY` + populated `postmortems` table.
- **Risk class**: **read-only-research**. Memory writes only.
- **Action to activate**: flag + redeploy.
- **Live status (11.5)**: ACTIVE, last tick 09:55 UTC. firm_memory shows 199 postmortem rows last 14d (some are trade-critic, some are upstream postmortem-writer — both feed it).
- **Source**: `apps/worker/src/firm/agent-bus/firm-agents/trade-critic.ts`

### 5. daily-journal (Atlas)

- **Purpose**: Once per UTC day after 22:00. Synthesizes day's trades + postmortems + advisories into markdown. Writes `agent_artifacts(kind='journal')` + blackboard `xauusd.journal.daily` headline.
- **Flag**: `FIRM_AGENT_DAILY_JOURNAL_ENABLED`
- **Cooldown**: hardcoded 5-min poll, per-day uniqueness via `firm_state` key `firm_agent:daily-journal:last_journal_date_iso`.
- **Dependencies**: masters + `ANTHROPIC_API_KEY` + non-empty trade/postmortem set for the day.
- **Risk class**: **read-only-research**. Artifact + blackboard writes only.
- **Action to activate**: flag + redeploy.
- **Live status (11.5)**: ACTIVE, last journal 2026-05-09 (NB: 2026-05-10 missing — verify whether 10.5 UTC date didn't have trades, or there's a silent failure. Worth one DB query: `SELECT * FROM agent_artifacts WHERE kind='journal' ORDER BY created_at DESC LIMIT 5`).
- **Source**: `apps/worker/src/firm/agent-bus/firm-agents/daily-journal.ts`

### 6. macro-event (Cipher)

- **Purpose**: Hourly. Reads next-24h `news_events` where `impact='high'`. Gemini summarizes cluster + flags pre-event positioning risk. Blackboard `xauusd.macro.events` (severity QUIET/NORMAL/ACTIVE/HOT).
- **Flag**: `FIRM_AGENT_MACRO_EVENT_ENABLED`
- **Cooldown var**: `FIRM_AGENT_MACRO_EVENT_COOLDOWN_SEC` (default 3600)
- **Dependencies**: masters + `GEMINI_API_KEY` + `news_events` populated with high-impact rows in next 24h.
- **Risk class**: **read-only-research**. Blackboard write only; does NOT publish to event-policy (`event-policy` is the gate that actually blocks trades — macro-event is read-only into a sibling topic).
- **Action to activate**: flag + redeploy.
- **Live status (11.5)**: **SILENT** — no `firm_state` row. Either flag is `false` on Railway, or it's been enabled but `news_events` has no high-impact rows in window, so it returns `no_work` without writing state. Worth verifying both.
- **Source**: `apps/worker/src/firm/agent-bus/firm-agents/macro-event.ts`

### 7. fill-quality (Forge)

- **Purpose**: 4h cadence. Reads last ~50 closed trades, computes slippage proxies (entry vs OANDA, SL/TP vs realized close). Claude identifies systemic fill issues. Writes `firm_memory(execution)`.
- **Flag**: `FIRM_AGENT_FILL_QUALITY_ENABLED`
- **Cooldown var**: `FIRM_AGENT_FILL_QUALITY_COOLDOWN_SEC` (default 14400)
- **Dependencies**: masters + `ANTHROPIC_API_KEY` + sufficient closed-trade volume (≥10 in recent window).
- **Risk class**: **read-only-research**. Memory writes only.
- **Action to activate**: flag + redeploy.
- **Live status (11.5)**: **SILENT**. Verify flag state on Railway.
- **Source**: `apps/worker/src/firm/agent-bus/firm-agents/fill-quality.ts`

### 8. strategy-tuner (Atlas)

- **Purpose**: Once daily. Reads 30d trades + shadow_signals + postmortems per strategy, Claude proposes parameter tweaks. **PROPOSAL ONLY** — writes `firm_memory(thesis, importance=7)` + `agent_artifacts(kind='plan')`. Operator decides whether to flip env-vars.
- **Flag**: `FIRM_AGENT_STRATEGY_TUNER_ENABLED`
- **Cooldown**: hardcoded 10-min poll, per-day uniqueness via `firm_state` key `firm_agent:strategy-tuner:last_run_date_iso`.
- **Dependencies**: masters + `ANTHROPIC_API_KEY` + 30 days of trade data per strategy.
- **Risk class**: **writes-proposals**. Code never mutates env or strategy params. BUT — proposals reach memory + dashboard; operator may act on them. Per operator-prinsipp 6 ("selvfiks/autotune er langsiktig"), this is the highest-friction read-only agent. Defer until 30+ days post-TIER-3 trading data AND green foundation gate (operator-prinsipp 4).
- **Action to activate**: flag + redeploy. **Strategy/risk-change protocol**: even though it's proposal-only, surfacing tweaks to Karri is part of the protocol. Filing a proposal in `docs/strategy/proposals/` *about activating this agent* may be warranted.
- **Live status (11.5)**: **SILENT**. Likely intentional (waiting for foundation gate / 30d data).
- **Source**: `apps/worker/src/firm/agent-bus/firm-agents/strategy-tuner.ts`

### 9. operator-brief (Atlas)

- **Purpose**: Once per UTC day after 06:00 UTC. Builds 5-section morning briefing from yesterday's trades + advisories + daily-journal + open positions. Writes `agent_artifacts(kind='journal')` + `$FIRM_LOCAL_ROOT/control/outbox/morning-brief-<date>.md` (Syncthing push). Discord delivery via `sendMorningBriefEmbed`.
- **Flag**: `FIRM_AGENT_OPERATOR_BRIEF_ENABLED`
- **Cooldown**: hardcoded 5-min poll, per-day uniqueness via `firm_state` key.
- **Dependencies**: masters + `ANTHROPIC_API_KEY`. For Discord delivery: `AGENT_DISCORD_DELIVERY_ENABLED=true` + `DISCORD_LEGACY_ENABLED=true`. For local outbox: `FIRM_LOCAL_ROOT` set + Syncthing running on host (not on Railway — file-write fails silently on container).
- **Risk class**: **read-only-research with side-channel** (Discord + local file).
- **Action to activate**: flag + redeploy. Also run `scripts/firm/outbox-sync.mjs --watch` locally to pull DB-stored briefs into Syncthing (the Railway worker can't write to operator's filesystem).
- **Live status (11.5)**: **SILENT**. Verify flag state on Railway.
- **Source**: `apps/worker/src/firm/agent-bus/firm-agents/operator-brief.ts`

### 10. regression-predictor (Atlas)

- **Purpose**: Once per UTC day after 04:00 UTC. Per active strategy with ≥10 closed trades in last 60d, computes unconditional mean R + stddev + win-rate; conditional cells per (regime, session) when n≥5. Writes `firm_memory(thesis, importance=7)` with structured evidence blob. Powers `/strategies/[id]/intelligence` dashboard.
- **Flag**: `FIRM_AGENT_REGRESSION_PREDICTOR_ENABLED`
- **Cooldown**: hardcoded, per-UTC-day uniqueness via `firm_state` key `firm_agent:regression-predictor:last_run_date_iso`.
- **Dependencies**: masters + ≥10 closed trades per active strategy over 60d. No LLM call — pure SQL aggregation.
- **Risk class**: **read-only-research**. No LLM cost. Memory write only.
- **Action to activate**: flag + redeploy.
- **Live status (11.5)**: ACTIVE, last run 2026-05-11 04:04 UTC.
- **Source**: `apps/worker/src/firm/predictions/regression-predictor.ts`

## Risk-tiered activation order

### Tier 1 — read-only-research, no LLM cost (zero-friction)
1. **regression-predictor** — already ON. Pure SQL, no Gemini/Claude tokens.

### Tier 2 — read-only-research, low LLM cost (Gemini, cheap)
2. **narrative** — already ON. 30m cadence, Gemini Flash.
3. **market-research** — already ON. 1h cadence, Gemini Flash.
4. **macro-event** — SILENT. Lowest-risk of the "silent four". Activate next.

### Tier 3 — read-only-research, Claude (more expensive, still no trade impact)
5. **trade-critic** — already ON. 1h cadence, Claude.
6. **fill-quality** — SILENT. Activate after macro-event proves stable.

### Tier 4 — read-only with side-channels (Discord / Syncthing)
7. **risk-advisor** — already ON. Discord double-gate must be verified.
8. **daily-journal** — already ON (with gap on 10.5 worth investigating).
9. **operator-brief** — SILENT. Activate when Discord + Syncthing outbox-sync are both verified working.

### Tier 5 — writes-proposals (still operator-promoted, but surfaces strategy tweaks)
10. **strategy-tuner** — SILENT. **DEFER until foundation gate green + 30 days post-TIER-3 trading data + explicit "OK kjør" from operator after Karri review.**

## Beyond Phase 3 — what is NOT activatable yet

These are coded but require Phase 4 (operator-prinsipp + foundation gate):

- **Codex code-worker** (`scripts/agent-codex-runner.mjs`) — `role=code` tasks. Refuses trading-loop paths without `TRADING_LOOP_OK` marker. 0 code-tasks in `agent_tasks` ever (verified via DB). Activation requires: Phase 3 stable 30 days + foundation gate green + explicit operator-OK. **Do not enable.**
- **Claude review-runner** + **PR opener** — works alongside Codex. Same gate.
- **Trading-loop-aware Codex proposals** (Phase 4) — venter per agent-bus.md row.

## What can be activated this week (concrete recommendations)

Three candidates with minimal incremental risk:

1. **macro-event** (#1 RECOMMENDATION). Gemini-backed, read-only, blackboard topic only. Complements narrative + market-research without overlapping. Already-active sister agents prove the Gemini pipeline + cooldown infra. Adds visibility into next-24h high-impact event clusters — useful for operator awareness even before any strategy uses the topic.
2. **fill-quality**. Claude-backed but cheap (4h cadence). Adds slippage diagnostics into `firm_memory(execution)` — directly useful when operator audits OANDA fills.
3. **operator-brief**. Highest user-facing value (morning briefing to phone), but requires verifying Discord double-gate + local Syncthing outbox-sync. Activate AFTER confirming `DISCORD_LEGACY_ENABLED=true` and `risk-advisor` Discord pings are actually arriving.

## Foundation-gate-blocked

- **strategy-tuner** — operator-prinsipp 6. Even though it's proposal-only, defer until 30+ days post-TIER-3 data + green foundation gate + Karri-reviewed proposal.

## Verification commands

```sql
-- Per-agent live status
SELECT key, value, updated_at FROM firm_state WHERE key LIKE 'firm_agent:%' ORDER BY updated_at DESC;

-- Last 24h tick-counts
SELECT key, COUNT(*) FROM firm_state WHERE updated_at > NOW() - INTERVAL '24 hours' GROUP BY key;

-- Recent journal artifacts
SELECT id, kind, LEFT(content, 80) AS preview, created_at FROM agent_artifacts ORDER BY created_at DESC LIMIT 10;
```

API:
```
GET https://<railway>/firm-agents/overview   # one card per agent: status / last tick / cooldown
GET https://<railway>/firm-agents/advisories # latest risk-advisor outputs
```

Dashboard: `/firm-agents` page (auto-refreshes every 5s).

## Source-of-truth pointers

- `apps/worker/src/firm/agent-bus/firm-agents/index.ts` — registry + `tickFirmAgents()` entry, called from `runCycle()`.
- `apps/worker/src/firm/agent-bus/firm-agents/<agent>.ts` — one file per agent; header comment is canonical purpose statement.
- `apps/worker/src/firm/predictions/regression-predictor.ts` — the only firm-agent outside the firm-agents/ folder.
- `docs/ref/env-vars.md` lines 71-152 — flag inventory.
- `docs/ref/agent-bus.md` — phased rollout + air-gap rules.
- `docs/ref/local-firm-mirror.md` — local Ralph-loop + AGENT_TRIGGER + outbox-sync.
- Memory `agentic_team_activation_state.md` — prior activation context (2026-05-03 batch).
- Memory `project_discord_delivery_dual_gate.md` — the `AGENT_DISCORD_DELIVERY_ENABLED` + `DISCORD_LEGACY_ENABLED` dual-gate trap.
