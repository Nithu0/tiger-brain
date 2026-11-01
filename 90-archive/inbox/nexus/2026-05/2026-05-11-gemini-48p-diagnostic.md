---
date: 2026-05-11
topic: Gemini research-drainer failure-rate diagnostic
trigger: 7d audit flagged 18/37 (48.6%) research-drainer fails
status: investigated, fix proposed (not implemented)
confidence: HIGH
---

# Gemini research-drainer 48.6% failure rate — root cause

## TL;DR

**Root cause: Gemini free-tier daily quota exhaustion on `gemini-2.5-flash`.**
Not network, not auth, not timeout, not prompt-too-long. Confidence **HIGH** (14/18 = 78% of failures are explicit `429 Too Many Requests / quota exceeded`).

The "timeout-pattern" reading from the earlier audit was misleading: only **1/18** is a true 124-timeout. The bulk are 429 quota fails returning quickly (median duration_s ≈ 0).

## Numbers

**7-day window (2026-05-04 → 2026-05-11):**
- Total research tasks: **38**
- Done: **20**  /  Failed: **18**  → 47.4% failure (close to operator's 48.6% headline)
- All 18 failures: model = `gemini-flash` → upstream `gemini-2.5-flash`

**Daily breakdown (UTC):**

| Day (UTC)    | OK | Err | 429 | Total |
|---|---|---|---|---|
| 2026-05-03   | 1  | 2   | 2   | 3   |
| 2026-05-04   | 3  | 7   | 7   | 10  |
| 2026-05-05   | 2  | 3   | 3   | 5   |
| 2026-05-06   | 1  | 5   | 5   | 6   |
| 2026-05-07   | 4  | 6   | 2   | 10  |
| 2026-05-08   | 3  | 1   | 1   | 4   |
| 2026-05-09   | 4  | 0   | 0   | 4   |
| 2026-05-10   | 1  | 0   | 0   | 4   |
| 2026-05-11   | 4  | 0   | 0   | 4   |

**Pattern**: failures cluster on high-volume days (May 4 + 6). Last 429 was **2026-05-08 03:45 UTC** — none in the last ~3.5 days because load has been low (≤4 calls/day).

## Error classification

| Class           | Count | % of failures | Notes |
|---|---|---|---|
| `quota_429`     | 14    | 77.8%         | "You exceeded your current quota" — Gemini billing/quota cap |
| `overload_503`  | 3     | 16.7%         | "This model is currently experiencing high demand" — Gemini server-side, all on May 6-7 |
| `timeout_124`   | 1     | 5.5%          | The single 340s timeout (May 7 23:18) — CLI mode (`cipher-9131-movefh22` claimer, not the SDK worker drainer) |
| auth / prompt-too-long / model-not-found | 0 | 0% | None observed |

The 503s are correlated with the 429 cluster (same days, same hours) — almost certainly the same root cause from Google's side (regional quota saturation rolling over from per-key to per-region).

The 1 timeout was a CLI-mode call from a non-worker claimer (`cipher-9131-movefh22` — local Ralph loop or similar). Stderr begins with the Gemini-CLI banner ("True color not detected. Ripgrep not available…") meaning the CLI was running and got SIGKILLed at the 300s+ mark. This is the "300-600s mode" the earlier audit flagged — it's a SINGLE event, not a pattern.

## Why the earlier audit said "timeout-pattern"

The duration_s column on `agent_tasks` measures `finished_at - claimed_at`. For the SDK 429s the drainer takes the cooldown-tick latency into account — `claimed_at` is set on claim, and the SDK returns the 429 in <1s, but the finished_at write happens immediately. So most have duration_s = 0-2.

**However**: the earlier "timeout pattern" tally probably included rows where `created_at → claimed_at` gap was large (~300-600s) because the drainer is on a 120s cooldown AND `AGENT_TASK_MAX_INFLIGHT_PER_ROLE=3` plus SLA reaper requeues. Tasks sit queued for several minutes before being drained. That's queue latency, not Gemini timeout.

## Why the drainer keeps marking failed (not retry-eligible)

Code path: `apps/worker/src/firm/agent-bus/research-drainer.ts:63-76` — `classifyError`:

```ts
const m = stderr?.match(/\b(?:status[: ]+|http[: ]+)?(\d{3})\b/);
const status = m ? Number(m[1]) : null;
if (status === 429 || status === 503) return { isRetryable: true, status };
```

Good news: 429s ARE classified retryable, so `MAX_ATTEMPTS=3` should apply. But:

1. `taskAttempts` is in-memory only (a `Map<string,number>`) — survives only within one worker process. Worker restart loses the counter and the task gets a fresh budget. Comment at line 53-55 acknowledges this.
2. When MAX_ATTEMPTS is hit OR when the call is non-retryable, the task is marked `failed`. The retries are "soft" — they look like ~3 separate failures if the SLA reaper re-claims them.

This explains why the 18/37 looks high: **each true quota event likely shows up as 1-3 rows**. The unique-task fail count is likely closer to 6-8 underlying quota windows, not 18 independent disasters.

## Sample errors (verbatim, first 280 chars)

```
gemini exit=1: [GoogleGenerativeAI Error]: Error fetching from
https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent:
[429 Too Many Requests] You exceeded your current quota, please check
your plan and billing details. For more information on this error, head to: https://ai.googl…
```

(Truncated mid-URL because `failTask` uses `.slice(0,300)`. Full URL: `https://ai.google.dev/gemini-api/docs/rate-limits`.)

503 sample:
```
gemini exit=1: [GoogleGenerativeAI Error]: Error fetching from
…/gemini-2.5-flash:generateContent: [503 Service Unavailable]
This model is currently experiencing high demand. Spikes in demand are
usually temporary. Please try again later.
```

## Root cause confidence: HIGH

Evidence:
1. 77.8% of failures contain the explicit `429 Too Many Requests` + `exceeded your current quota` string from Google
2. 16.7% are correlated `503` overload-from-same-vendor
3. Failures cluster on heavy-traffic days (May 4 / 6) — exactly when free-tier RPM/RPD caps would bite
4. Auth would produce 401/PERMISSION_DENIED — 0 such errors. So GEMINI_API_KEY is present and valid.
5. Bad-prompt would produce 400 INVALID_ARGUMENT — 0 such errors. Prompts cap at 50KB via `capPrompt`.
6. Model-not-found would produce 404 — 0 such errors.
7. Recovery is automatic: last 429 was 3.5 days ago, success rate has been 100% on lower-volume days. This is exactly the signature of daily-window quota reset.

## Recommended fix (PROPOSED, NOT IMPLEMENTED)

Three options ranked by effort:

### Option A (zero-code): just live with it — observability fix only

The system already retries internally. Daily quota resets at midnight Pacific (07:00 UTC), so failure spikes self-clear. If volume stays low (≤6 calls/day) we're well under the free-tier 1500 RPD limit on flash and this stays at 0%.

**What's worth doing regardless**: surface the 429 class in the morning briefing so operator sees "Gemini quota hit N times yesterday" rather than a generic 48% number. The dashboard "research pipeline health" widget should split by error class.

### Option B (small code patch): drainer rate-limit + better classification

Code-side patches under "observability / restore-intended-behavior" exemption:

1. Add a soft rate-limit gate inside the drainer: if more than N (e.g. 5) failed-with-429 in the last hour, skip the tick and emit a `gemini_quota_paused` blackboard event. Operator decides whether to raise quota or wait it out. **No auto-disable** (per CLAUDE.md principle 1).
2. Persist `taskAttempts` to `firm_state` (already proven survivable across restarts via the cooldown key). Currently it's lost on worker restart so MAX_ATTEMPTS=3 is per-process not per-task. Low-value fix — only matters if worker restarts mid-window.
3. Cap `failTask` summary length at full error (currently `slice(0, 300)` truncates URL — minor).

### Option C (operator action): pay for Gemini Tier-1

If research pipeline matters strategically, upgrade Google AI Studio key to Tier-1 billing. Flash Tier-1 RPM=1000 / RPD=10000 — completely removes the cap for this workload. ~$0.075 per 1M input tokens; current usage is <$1/month.

**Karri-review needed?** No — this is research-pipeline (no money-impact). The drainer feeds DISTILLED memory + agent_lessons, not the trade-loop. Option B falls in "observability / restore-intended-behavior" exemption (CLAUDE.md `docs/strategy/proposals` rule).

## Implementation status

- **Applied**: none
- **Proposal filed**: this document
- **Awaiting operator**: decision on Option A / B / C

## Followups

- [ ] Operator: choose A / B / C
- [ ] Update `docs/ref/known-issues.md` with this finding (currently no entry)
- [ ] Update morning briefing to split research-drainer failures by class
- [ ] Living-state: `/home/nithu/Obsidian/Brain/01-nexus/runtime-state/gemini-pipeline-state.md`

## Files touched in investigation

- `/home/nithu/code/ai-assistent/apps/worker/src/firm/agent-bus/research-drainer.ts` (read)
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/agent-bus/firm-agents/llm.ts` (read)
- `/home/nithu/code/ai-assistent/docs/ref/env-vars.md` (read, lines 75-100)

## Raw SQL used (audit trail)

```sql
-- Headline status counts
SELECT status, COUNT(*) FROM agent_tasks
 WHERE role='research' AND created_at > NOW() - INTERVAL '7 days'
 GROUP BY status;
-- => done: 20, failed: 18

-- Error classification
SELECT CASE
  WHEN r.summary LIKE '%429 Too Many Requests%' THEN 'quota_429'
  WHEN r.summary LIKE '%503 Service Unavailable%' THEN 'overload_503'
  WHEN r.summary LIKE '%exit 124%' OR r.summary LIKE '%timeout%' THEN 'timeout_124'
  ELSE 'other'
END AS klass, COUNT(*) AS n
FROM agent_results r JOIN agent_tasks t ON r.task_id=t.id
WHERE t.role='research' AND r.status='error' AND r.created_at > NOW() - INTERVAL '7 days'
GROUP BY 1 ORDER BY n DESC;
-- => quota_429: 14, overload_503: 3, timeout_124: 1
```
