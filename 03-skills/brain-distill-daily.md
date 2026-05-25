---
name: brain-distill-daily
description: Nightly distillation of yesterday's command-center actions + Claude conversations into MemoryObjects written to the brain
tier: brain
project_scope: workspace
when_to_use: triggered nightly at 03:00 local OR on-demand for any past date; keywords "distill yesterday", "process audit_log", "build MemoryObjects", "catch up brain memory"
inputs:
  - name: date
    type: string
    required: false
    default: yesterday-in-operator-tz
  - name: dry_run
    type: bool
    required: false
    default: false
outputs:
  - count_new_objects: number
  - count_promoted_to_brain: number
  - skipped_low_signal: number
  - errors: array
tools_required: [Bash, Read, Write, Edit]
cost_estimate: medium
cache_strategy: persistent
auto_invocable: false
created: 2026-05-25
created_by: operator
confidence: 0.7
validation_passes: 0
related: ["[[SKILL_REGISTRY_SPEC]]", "[[2026-05-25-brain-upgrade-plan]]", "[[MEMORY_DISTILLATION_SPEC]]"]
tags: [skill, brain, distillation, nightly, memory]
---

## Purpose

Convert raw exchange history (yesterday's command-center `audit_log` rows + new Claude conversation files) into structured MemoryObjects following the four-field paper-tro schema (`exchange_core`, `specific_context`, `room_assignments`, plus metadata). Each MemoryObject back-references its verbatim source so operator can always click through to the full record. This is the heartbeat of the closed-loop brain — without nightly distillation, memory stays as raw logs and retrieval quality collapses.

## When to use

- Nightly scheduled run (03:00 local) once cron is approved by operator (gate brain-G4)
- Manual catch-up after operator returns from a multi-day absence
- Re-distillation of a specific date when distill-LLM has been upgraded
- **Anti-patterns:** never run on `00-firm-bus/feed.md` (low-signal, noisy); never overwrite an existing MemoryObject (append-only); never distill secrets or `.env*` contents

## Inputs

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `date` | string (YYYY-MM-DD) | no | yesterday | Operator timezone Europe/Oslo |
| `dry_run` | bool | no | false | When true, count + list would-be writes without persisting |

## Steps

1. Resolve target date in operator TZ (default = yesterday)
2. Query command-center API: `GET /api/audit/dump?date=<date>` to fetch `audit_log` rows
3. Scan `~/.claude/projects/-home-nithu-code/` for new conversation files with `mtime` matching target date
4. For each candidate exchange, call memory-engine distill endpoint: `POST /api/memory/distill` with `{source_type, source_ref, raw_text}`
5. Validate returned MemoryObject against schema (4 paper fields + back-ref + confidence)
6. Skip exchanges with `confidence < 0.3` (low-signal) and increment `skipped_low_signal`
7. Write MemoryObject to brain via `POST /api/memory/objects` (persists to SQLite + emits to relevant `12-youtube/`, `13-github-repos/`, or `10-tasks/` folder when room_assignments warrant)
8. Append back-reference wikilink to source note (if source is a brain markdown file)
9. Emit completion event to `00-firm-bus/feed.md` with counts

## Tools / commands

```bash
# Manual invocation
curl -sS "http://localhost:3001/api/audit/dump?date=${DATE}" \
  | jq -c '.rows[]' \
  | while read row; do
      curl -sS -X POST http://localhost:3001/api/memory/distill \
        -H 'content-type: application/json' \
        -d "$row"
    done

# Dry-run variant
DRY=1 ./command-center/_bin/brain-distill-daily.sh --date 2026-05-24
```

## Pitfalls

- Distill-LLM cost spike if a day has > 500 audit rows (mitigate via batch + Haiku-tier model)
- Idempotency: re-running same date must not double-write — enforce via `idempotency_key = sha256(source_ref)`
- Operator-only paths: never distill `.env*`, `~/.ssh/**`, `.git/config`
- Conversation files mid-write — skip files with mtime < 5 min ago
- Low-signal noise: `00-firm-bus/feed.md`, `PRESENCE.md`, ephemeral inbox-acks all excluded

## Validation checks

1. Count of MemoryObjects written matches count of non-skipped exchanges
2. Every written object has a valid `source_ref` that resolves to an extant file/row
3. No object lacks the 4 paper-tro fields
4. `confidence` distribution is sane (no degenerate all-1.0 or all-0.0)
5. Weekly random-sample 5 objects and verify `exchange_core` matches operator's mental model

## Example usage

```
/skill brain-distill-daily date=2026-05-24
```

Or as scheduled cron (post gate brain-G4):

```
0 3 * * * /home/nithu/code/command-center/_bin/brain-distill-daily.sh
```

## Related

- [[SKILL_REGISTRY_SPEC]]
- [[MEMORY_DISTILLATION_SPEC]]
- [[2026-05-25-brain-upgrade-plan]]
- [[AGENT_ORCHESTRATION_SPEC]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
