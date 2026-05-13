---
type: claude-inbox
date: 2026-05-11
subject: retention reap FK-safe filter — verified on prod
status: ✅ SUCCESS
---

# Retention reap fix verify — 2026-05-11

## Verdict: ✅ SUCCESS

The FK-safe filter (commit `711a254`) ships and works as designed. First post-deploy retention pass reaped exactly the predicted 5,965 unreferenced completed jobs with zero errors.

## Build commit on /health

```
commit: a2f1cbc8
```

`a2f1cbc8` is 4 commits past `711a254` on main — the FK-safe filter is live.

## Latest retention report

```
ranAt:    2026-05-11T14:12:37.588Z
publishedAt: 2026-05-11T14:12:42.381Z
enabled:  true
deleted:
  jobsDone:             5965     ← unreferenced cohort cleanly reaped
  jobsFailed:              0
  blackboardVolume:        0     (cohort not aged)
  blackboardAnalysis:      0     (cohort not aged)
  sentimentSnapshots:      0     (oldest 14d, threshold 30d)
  tradeStrategySnapshots:  0
errors:   []
config:   {7d done, 30d failed, 30d sentiment, 30d bb-vol, 90d bb-analysis, 90d trade-snap}
```

## Jobs before / after

| state | before | after |
|---|---|---|
| `completed` total | 21,189 (~5,965 unref + 13,500 ref + ~1,724 <7d) | 15,224 |
| `completed` >7d unref | 5,965 | **0** ✅ |
| `completed` >7d ref | 13,500 | 13,500 (unchanged — pending operator schema decision) |
| `failed` total | 38 | 38 |
| `processing` | 1 | 1 |
| `queued` | 1 | 1 |

## Prior pass evidence (pre-fix FK violations)

The three runs immediately before `a2f1cbc8` deployed all hit the FK error:

```
13:55:50Z — errors: ["jobs-done: ...foreign key constraint \"bot_runs_job_id_fkey\"..."]
13:33:00Z — errors: ["jobs-done: ...foreign key constraint \"bot_runs_job_id_fkey\"..."]
12:53:00Z — errors: []  (silently 0 — pre-FK-fix code path, no rows qualified or earlier swallow)
```

Post-deploy 14:12Z is the first clean reap. Filter behaves exactly as forensics predicted.

## Sentiment + blackboard

Sentiment: 10,378 rows total, oldest 2026-04-20 (~21d). over_14d=3,800, over_30d=0. First non-zero `sentimentSnapshots` reap expected ~2026-05-20.

Blackboard volume topics: first reap ~2026-05-15 (30d from 2026-04-15). Analysis topics: ~2026-07.

## Outstanding operator decision

The remaining 13,500 referenced `completed` jobs need a schema choice:

1. `ON DELETE CASCADE` on `bot_runs.job_id` — bot_runs rows die with the job
2. `ON DELETE SET NULL` — keeps bot_runs, severs link
3. Pre-delete pattern: retention deletes matching `bot_runs` rows first
4. Leave as-is — `jobs` table is only 7.3 MB, churn is manageable

No money-impact, so no Karri proposal needed; this is an ops/infra call. Recommendation: option 4 short-term, revisit if `bot_runs` grows past 50 MB or `jobs` past 20 MB.

## Loose ends from earlier finding

- Retention cadence verify: prior to deploy, 3 passes ran in ~1h (12:53, 13:33, 13:55) — denser than the design "once per UTC-day" `lastRetentionRunDate` guard. After 14:12Z reap, next report should appear ~2026-05-12T00:00Z+. If sooner, the guard isn't engaging properly. Track in retention-state.md follow-ups.

## Files updated

- `/home/nithu/Obsidian/Brain/01-nexus/runtime-state/retention-state.md` — status 🟡 → 🟢, last_verified 14:20Z, reap evidence + post-state cohort math
- This inbox note: `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-retention-reap-fix-verify.md`
