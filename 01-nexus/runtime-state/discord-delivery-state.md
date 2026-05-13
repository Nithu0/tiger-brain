---
generated: 2026-05-11
source: mcp__nexus-pg__query against agent_artifacts
window: last 24h (extended cross-check across all-time)
---

# Discord delivery state — 2026-05-11

## TL;DR

Pipeline is **wired but barely exercised**. Only **1 artifact** (kind=`trigger`) carries any `discord_delivery_status` ever — status `sent`, latency 0.28s. All other artifacts (`review`, `research_note`) have `discord_delivery_status = NULL`, meaning the Discord publish path is **not invoked** for those kinds. Zero `failed_*`, zero `skipped_*`.

Verdict: **healthy on the one path that fires; silent skip on advisory/review/research_note kinds** (no instrumentation, possibly by design — only triggers ping Discord).

## Status mix — last 24h

| status | count |
|---|---|
| `null` | 13 |
| `sent` | 1 |
| `skipped_*` | 0 |
| `failed_*` | 0 |

`notified_at` column is also null on all 14 rows last 24h — separate fact, but reinforces that only triggers get instrumented.

## Per-kind breakdown — last 7d (24h is identical save for review counts)

| kind | total 7d | sent | skipped | failed | null |
|---|---|---|---|---|---|
| `review` | 34 | 0 | 0 | 0 | 34 |
| `research_note` | 23 | 0 | 0 | 0 | 23 |
| `trigger` | 1 | 1 | 0 | 0 | 0 |

All-time check: same shape. **Only `trigger` kind has ever set `discord_delivery_status`.**

## Latency

- Single sample: 0.278s (kind=trigger).
- p99/p50 not meaningful with n=1.

## Failures

None. No `failed_*` rows anywhere in the table.

## The one `sent` artifact (audit trail)

- `id`: `07a6b689-0b60-4f5c-a334-6b68408b1c84`
- `kind`: `trigger`
- `task_id`: `d8a1bc63-b69a-46b8-bb81-deacc1bb40b2`
- `created_at`: 2026-05-11T13:42:54.055Z
- `discord_delivered_at`: 2026-05-11T13:42:54.333Z
- `metadata`: `{agent: agent-trigger, trigger: loss_streak, fingerprint: xau-scalp-overlap:6h}`
- Linked task: research drainer task (`role=research`, `created_by=agent-trigger:loss_streak`), claimed by `worker-research-drainer-12`, status `failed` (drainer failed downstream, but the Discord ping for the trigger itself did go out).

Trigger fired and was delivered within ~280ms. Confirmed wired end-to-end on this code path.

## Open question (not a failure, but worth flagging)

`review` and `research_note` artifacts (57 rows in 7d) leave `discord_delivery_status = NULL`. Two possibilities:

1. **By design** — only `trigger` kind is meant to ping Discord (advisories ride along the task itself, not a separate ping). If so, status quo is healthy.
2. **Silent skip** — emitter doesn't call the Discord publisher for these kinds, so they never get tagged. Could mean operator sees zero downstream notifications about review/research output unless they read the dashboard.

Recommend checking emitter code path (`AGENT_DISCORD_DELIVERY_ENABLED`-gated function) to confirm which kinds it covers. **Not blocking** — pipeline is healthy on the path it currently serves.

## Sanity checks

- `DISCORD_LEGACY_ENABLED=true` confirmed live (operator note).
- `AGENT_DISCORD_DELIVERY_ENABLED=true` assumed (no DB way to verify env from MCP).
- No `failed_*` over the entire history — meaning either Discord webhook is reliable, or the failure path doesn't write the failed state back (possible silent-on-error pattern; worth a code audit if a failure ever appears suspicious).

## Recommendation

1. Confirm in code: which kinds should set `discord_delivery_status`? Document expected coverage in `docs/ref/agent-bus.md`.
2. If `review`/`research_note` are intentionally silent: add a comment in `agent_artifacts` insert path so the next auditor doesn't flag this as a regression.
3. Generate one more test trigger to bump n>1 on latency and confirm consistency.
