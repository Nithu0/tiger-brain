---
date: 2026-05-11
type: audit-result
scope: Discord delivery pipeline
verdict: healthy-on-instrumented-path / silent-skip-on-other-kinds
---

# Discord delivery audit — final (2026-05-11)

## Verdict

**Pipeline healthy on the one code path that fires.** No failures, no skipped, sub-second latency on the single delivered artifact. But **only `trigger` kind carries any `discord_delivery_status` instrumentation** — `review` and `research_note` (57 rows over 7d) all have `discord_delivery_status = NULL`. Either by design (only triggers ping Discord) or silent skip (emitter doesn't invoke publisher for these kinds). Operator should confirm intent.

## Numbers (last 24h)

- Artifacts created: **14**
- With `discord_delivery_status` set: **1** (kind=trigger, status=sent, latency 0.278s)
- `failed_*`: **0**
- `skipped_*`: **0**
- `null`: **13** (8 review + 5 research_note)

All-time same pattern — only ever 1 row with status set, and it's the trigger.

## Per-kind breakdown (7d)

| kind | total | sent | failed | skipped | null |
|---|---|---|---|---|---|
| review | 34 | 0 | 0 | 0 | 34 |
| research_note | 23 | 0 | 0 | 0 | 23 |
| trigger | 1 | 1 | 0 | 0 | 0 |

## The `sent` artifact

- `id` 07a6b689-... — `trigger` for `loss_streak` on `xau-scalp-overlap`, created 13:42:54.055Z, Discord-delivered 13:42:54.333Z (280ms latency). Linked to a research-drainer task that itself later failed — but the trigger ping went out fine.

## Latency

- n=1, sample = 0.278s. Too sparse for meaningful p50/p99.

## Failures

- None recorded. Either webhook is 100% reliable, or failure path isn't writing `failed_*` back. Worth a quick code audit if a real failure ever appears suspicious.

## Action items

1. Confirm in code which kinds are meant to ping Discord. If only `trigger`, document expected coverage in `docs/ref/agent-bus.md` so this isn't re-flagged on next audit.
2. If `review` / `research_note` should also ping but currently don't: that's the silent skip and warrants a fix. Otherwise leave as-is.
3. Force-fire a second test trigger when next opportunity arises, so n>1 on the latency curve.

## Detailed state file

Live state mirror at `01-nexus/runtime-state/discord-delivery-state.md` — updated this run.
