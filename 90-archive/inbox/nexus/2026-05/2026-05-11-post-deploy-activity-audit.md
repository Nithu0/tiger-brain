---
type: audit
date: 2026-05-11
deploy-window: ~12:35-13:00 UTC
deployed-commit: 09dd0272 (HEAD~3 vs main HEAD 9745dee)
auditor: claude-opus-4.7-1m
status: deploy verified live; trade-side fixes UNCONFIRMED — no new trades since 10:15Z
---

# Post-deploy activity audit — round 7+8

Audit run at 2026-05-11T13:11Z, ~36 min after the deploy window. All 7 checks executed via `mcp__nexus-pg__query`.

## TL;DR

- Deploy is LIVE on prod (`build.commit = 09dd0272`, worker cycle 18, heartbeat 9 s).
- Worker is ticking — 145 blackboard rows in the current hour, lastMarketRawSec=11.
- **However**: no new trades, gate_decisions, or signals since 2026-05-11T10:15:31Z (last trade `7eebe4f7… xau-orb`). All trade-side fixes (metadata persist, gate cycleId wire-up) are deployed but **not yet exercised** by a real cycle that produced a fill.
- Quiet market window — `lastDecisionSec = 10557` (~2 h 56 m). Sunday afternoon → narrow conditions, no strategy gates passed.

## Check 1 — Build commit + cycle progression

```json
{
  "commit": "09dd0272",
  "lastCycleNo": 18,
  "lastCycleDurationMs": 3609,
  "lastHeartbeatSec": 9,
  "broker": { "ok": true, "mode": "demo", "balance": 92245.12 },
  "blackboard": { "ok": true, "lastMarketRawSec": 11, "lastDecisionSec": 10557 },
  "reconciliation": { "driftCountUnresolved": 0, "balanceDelta": 13.62 }
}
```

- `09dd0272` = `fix(retention): jobs status 'done' → 'completed'`. HEAD on main is now `9745dee` (Codex pipeline + multi-claude guide on top), but the worker container reflects what was deployed in the 12:35-13:00 window.
- `lastCycleNo: 18` after the deploy + 36 min wall clock = cold restart confirmed. Cycle cadence ~120 s.
- `lastDecisionSec: 10557` — strategies have been evaluating gates but no Blade-PASS for ~3 h. Consistent with quiet Sunday session.

## Check 2 — New trades since 13:00 UTC

```sql
SELECT id, bot_id, strategy_id, execution_source, atr_at_entry, entry_conviction_score, opened_at
FROM simulated_orders WHERE opened_at > '2026-05-11T13:00:00Z' …;
```

**0 rows.** Latest order on system is `2026-05-11T10:15:31Z` (`xau-orb`, conviction 0.80, atr_at_entry NULL).

→ Metadata-stamping fix (`0ad348f`) cannot yet be verified on live writes. Backfill confirmed all historical rows (Check 3).

## Check 3 — Backfill verification (NULL strategy_id rows)

```
execution_source | is_null | count
firm_strategy    | false   | 59
oanda_backfill   | false   |  3
```

**0 NULL strategy_id rows** in firm_strategy population (sample window since 2026-04-26 22:00Z). Distribution across strategies (since deploy reference window):

| strategy_id | count |
|---|---|
| xau-volatility-expansion | 37 |
| xau-session-breakout | 13 |
| xau-orb | 5 |
| xau-scalp-overlap | 4 |

→ **Backfill PASSED.** Foundation Rule 2 evidence chain is now complete for historical attribution.

## Check 4 — gate_decisions.decision_cycle_id post-fix

```
has_cycle_id | count (since 13:00Z)
(no rows — gate_decisions latest is 10:15:31Z)
```

Extended to last 7 d for context:

| has_cycle_id | first | last | count |
|---|---|---|---|
| false | 2026-05-11T04:16:47Z | 2026-05-11T10:15:31Z | 16 |
| true  | 2026-04-20T15:53:59Z | 2026-04-24T22:26:19Z | 7858 |

→ Pre-deploy gate writes were all NULL cycle_id (as expected — the `38921eb` wire-up was missing). **Post-deploy: no gate_decisions rows yet** — same root cause as Check 2 (no Blade evaluations writing to `gate_decisions` since deploy).

## Check 5 — agent_artifacts.discord_delivery_status (post-c062696)

```
kind         | discord_delivery_status | count (since 13:00Z)
(no rows since 13:00Z)
```

Window extended to last 4 h:

| created_at | kind | discord_delivery_status |
|---|---|---|
| 12:28:49 | research_note | NULL |
| 12:23:28 | review | NULL |
| 12:17:54 | research_note | NULL |
| 12:08:37 | research_note | NULL |
| 12:04:08 | research_note | NULL |
| 11:24:08 | review | NULL |
| 09:16:43 | review | NULL |
| 09:15:24 | review | NULL |
| 09:14:06 | review | NULL |

→ All pre-deploy. `c062696` adds `kind='advisory'` (risk-advisor, 10/hr) and `kind='trigger'` (agent-trigger) writes — neither has fired post-deploy yet. Last `kind=research_note` 12:28Z came from research-drainer, predates fix.

**Concern**: Even pre-deploy `kind IN ('research_note','review')` rows have `discord_delivery_status = NULL`. Either those code paths still don't pass `db+artifactId` to `sendEmbed()`, OR delivery is not happening at all for these kinds. Worth a separate audit — but out of scope for this deploy verification.

## Check 6 — Retention pass report

```
timestamp: 2026-05-11T12:53:00.685Z
deleted:   { jobsDone: 0, jobsFailed: 0, blackboardVolume: 0, blackboardAnalysis: 0,
             sentimentSnapshots: 0, tradeStrategySnapshots: 0 }
errors:    []
enabled:   true
```

→ Retention ran at 12:53Z (18 min after deploy window opened, before 09dd0272 likely active). `jobsDone: 0` is **inconclusive** for the fix — either the fix wasn't live yet OR there are genuinely no `status='completed'` jobs older than 7 d. Next retention pass (within ~24 h) will be the definitive check. Watch for `deleted.jobsDone >= 1` on next report.

Note: schema confirms the data column is `state` (jsonb), not `payload`. The audit playbook's `payload` reference was wrong; corrected for this run.

## Check 7 — Signals fired since deploy

```
hour | source | count (since 13:00Z)
(no rows)
```

Hourly blackboard volume (sanity check — system IS ticking):

| hour | rows |
|---|---|
| 13:00 | 145 (partial — current hour) |
| 12:00 | 756 |
| 11:00 | 756 |
| 10:00 | 746 |
| 09:00 | 741 |

→ Blackboard ingest, manager-FACTs, and analyst-INTERPRETATIONs continue at full rate. **No DECISION-type messages in last 40 min.** Strategies are evaluating and rejecting (consistent with portfolio-brain thesis "Best: trend_macro | Gate: PASS_TO_BLADE" but no follow-through), or each manager-FACT says "outside watch windows / RSI not at extreme / ATR ratio below threshold."

## Foundation Rule 2 status

**STILL 🟡** (yellow). Backfill cleared historical NULLs (59/59 stamped), but the **live persistence** of `atr_at_entry` + `entry_conviction_score` from `0ad348f` is unverified because no new trades have opened post-deploy. Flip to 🟢 the moment one new firm_strategy fill arrives with all 4 metadata columns populated.

## Top concern

None blocking. Two watch-items:

1. **`atr_at_entry` is NULL even on the latest 10:15Z trade** (`xau-orb`). That trade predates the deploy, so it's a known gap. But: if the next post-deploy fill ALSO has NULL `atr_at_entry`, the `0ad348f` fix is incomplete and we should re-inspect the INSERT path.
2. **Audit gap in `agent_artifacts`**: `kind IN ('research_note','review')` still write `discord_delivery_status = NULL`. `c062696` only fixed risk-advisor + agent-trigger paths. Either intentional (those kinds don't deliver to Discord) or another audit-trail gap. Flag for separate review.

## Verification SQL for the next time the loop fires a trade

```sql
SELECT id, opened_at, strategy_id, execution_source,
       atr_at_entry, entry_conviction_score
FROM simulated_orders
WHERE opened_at > '2026-05-11T13:00:00Z'
ORDER BY opened_at DESC LIMIT 5;

-- All four columns NOT NULL = round-7+8 verified live.
```

```sql
SELECT decision_cycle_id, COUNT(*)
FROM gate_decisions
WHERE recorded_at > '2026-05-11T13:00:00Z'
GROUP BY 1;

-- decision_cycle_id NOT NULL = 38921eb verified live.
```

## Linked

[[production-loop-state]] · [[foundation-gate-state]] · [[metadata-stamping-state]] · [[retention-state]] · [[discord-delivery-state]] · [[gate-decisions-state]]
