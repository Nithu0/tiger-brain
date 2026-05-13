---
date: 2026-05-13
type: performance-audit
project: nexus
status: open
---

# Agent-bus latency audit — 13.5

Read-only audit via `mcp__nexus-pg__query`. Schema note: `agent_tasks` uses `role` (not `agent_name`), `finished_at` (not `completed_at`), `model` lives on `agent_tasks`.

## TL;DR

- **LLM execution is fast.** Gemini-flash avg 19.7s / p95 55.1s; Claude-opus avg 29.4s / p95 37.0s. Both well under SLA.
- **All latency pain is queue lag, not model lag.** Review tasks (Claude-opus) sit 22,421s (~6.2h) in queue before being claimed. Research tasks (Gemini) average 532s queue lag.
- **Lessons + predictor still dormant.** `agent_lessons` and `agent_knowledge` both 0 rows in last 7d. No `regression-predictor` events in `agent_events`.
- **Gemini Tier-1 upgrade (11.5) verified working.** 429s dropped from 5-7/day pre-11.5 to 0 on 9/10/11/12.5.

## 7d throughput (role x dept)

| role | dept | n | done | failed | avg_lat_s | max_lat_s |
|---|---|---|---|---|---|---|
| research | research | 47 | 35 | 12 | 551 | 7266 |
| review | journaling | 26 | 26 | 0 | 22,451 | 87,529 |

Status taxonomy: `done`, `queued`, `failed` (no `success`/`completed` in this dataset).

## Latency split: queue vs exec (7d done tasks)

| model | role | n | avg_exec_s | p95_exec_s | avg_queue_s |
|---|---|---|---|---|---|
| gemini-flash | research | 47 | 19.7 | 55.1 | 531.5 |
| claude-opus | review | 26 | 29.4 | 37.0 | 22,421.7 |

**Total-latency percentiles** (created->finished, done only):

| role | n | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| research | 35 | 668s | 193s | 3,646s | 6,036s | 7,266s |
| review | 26 | 22,451s | 68s | 78,579s | 85,370s | 87,529s |

Review p50 of 68s is the "happy path." p95/p99 in tens-of-thousands of seconds reveals the bimodal pattern — review drainer claims promptly when running, but goes silent for hours between sweeps.

## Tokens + cost (7d, from `agent_results`)

| model | calls | tokens_in | tokens_out | cost_usd_total |
|---|---|---|---|---|
| gemini-flash | 47 | 3,511 | 9,827 | $0.0031 |
| claude-opus | 37 | 0 | 0 | $0.0000 |

**Instrumentation gap:** Claude-opus drainer not writing `tokens_in/out/cost_usd` to `agent_results`. Confirmed by 37 result rows but zero token accounting. Action: file followup to wire token reporting in the opus drainer — without it, cost forecasting is blind.

(Side note: 37 result rows on 26 done tasks = some retries / multi-result writes. Worth a separate audit if recurring.)

## Failure modes

12 research failures in 7d, all surface as `agent_results.status='error'` with verbose `summary`/`errors.message`. Sample messages:

- `429 Too Many Requests` (Gemini free tier quota)
- `503 Service Unavailable` (Gemini transient demand spike)

No silent retries observed — every failure leaves an `agent_results` row.

### 14d Gemini error timeline

| date | err_429 | err_503 | ok |
|---|---|---|---|
| 02.5 | 2 | 0 | 1 |
| 03.5 | 7 | 0 | 3 |
| 04.5 | 3 | 0 | 2 |
| 05.5 | 5 | 0 | 1 |
| 06.5 | 2 | 3 | 30 |
| 07.5 | 1 | 0 | 3 |
| 08.5 | 0 | 0 | 4 |
| 09.5 | 0 | 0 | 1 |
| 10.5 | 1 | 0 | 20 |
| 11.5 | 0 | 0 | 6 |
| 12.5 | 0 | 0 | 6 |

**Tier-1 confirmed working** (0 quota errors since 11.5).

## Queue depth right now

| role | status | n | avg_age_h | max_age_h |
|---|---|---|---|---|
| code | queued | 1 | 45.1 | 45.1 |
| review | queued | 4 | 17.4 | 18.3 |

4 review tasks queued since 11.5 still unclaimed -> review drainer either disabled or running on a coarse schedule. One stale `code` task at 45h (likely from a one-off and never picked up — drainer for `code` role may not exist).

## Memory/lesson layer status

| table | rows 7d |
|---|---|
| agent_lessons | 0 |
| agent_knowledge | 0 |
| agent_events | 1,809 |
| agent_artifacts | 130 |

Events break down: 1,054 `supervisor/check-complete`, 725 `bot-manager/portfolio-review`, 30 `trade-reviewer/review`. No `regression-predictor` events — confirms predictor dormant in production.

## Open questions / followups

1. **Why is review drainer's queue lag so high?** 22k seconds avg with bimodal distribution (p50 68s vs p95 78k s). Is the cron running, or only firing on specific triggers? 4 tasks pending since 11.5 suggests it stopped sweeping.
2. **Wire token/cost instrumentation for Claude-opus drainer.** Currently flying blind on opus spend.
3. **agent_lessons + agent_knowledge dormancy.** Tables exist, schema in place, but no writes in 7d. Confirms prior audit — promotion pipeline not running.
4. **Stale `code` task** (45h queued). One-off cleanup or unimplemented drainer? Worth a glance.

## Sources

- `agent_tasks`, `agent_results`, `agent_events`, `agent_lessons`, `agent_knowledge`, `agent_artifacts` (nexus-pg, read-only)
- Prior baseline: agent-bus audit referenced in user prompt (research healthy, review/lessons/predictions dormant)
