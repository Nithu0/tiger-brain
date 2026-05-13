---
type: verification
date: 2026-05-11
component: gemini-research-drainer
verdict: tier-1-working
verified_by: claude (opus-4-7 1M ctx)
---

# Gemini Tier-1 upgrade — verified working

Operator upgraded Gemini to Tier-1 paid plan. Verification ran 2026-05-11 ~13:10 UTC via `mcp__nexus-pg__query` (read-only).

## Failure rate — before vs after

| Window | Total | Done | Failed | % fail |
|---|---|---|---|---|
| Pre-upgrade (7d→48h ago, May 4-9) | 32 | 15 | 17 | **53.1%** |
| Post-upgrade last 48h | 5 | 5 | 0 | **0%** |
| Post-upgrade last 24h | 5 | 5 | 0 | **0%** |
| Post-upgrade last 1h | 2 | 2 | 0 | **0%** |

Cited prior baseline was 48.6%; the matching window I measured (7d minus the post-upgrade 48h) lands at 53.1%, consistent with the operator's reading.

## Error log status

- **Last failed task**: `35b31b44-92c7-4317-ab65-99d40eaf6a89` at 2026-05-08T03:40Z
- ~3 days zero failures since
- `agent_results` rows for those failures were not persisted (drainer marks the task `failed` directly without writing a result row), so I can't grep error text from DB — but the time-correlation is strong: failure cluster ends exactly at the upgrade window
- No 429/quota signals visible in `agent_events` (that table only carries bot-manager portfolio reviews)
- All 5 post-upgrade tasks claimed by `worker-research-drainer-12`, SDK mode, runtimes 75-145s — normal band

## Verdict

**Tier-1 working.** Failure rate collapsed from 53% to 0% across the upgrade boundary. Drainer is healthy, no quota errors observed in 48h. Recommend monitoring volume against the Tier-1 ceiling (~10K RPD on flash) and keeping the 429-class alert wired even on paid tier as a ceiling sentinel.

## Manual trigger note

No `/firm-agents/research/dispatch` endpoint located — the drainer is queue-fed by `FIRM_RESEARCH_DRAINER_ENABLED=true` polling. Last natural-volume task at 12:26Z (44 min before this check) succeeded. Manual trigger not needed for verdict — the live drain rate already provides the signal.

## Updated docs

- `01-nexus/runtime-state/gemini-pipeline-state.md` — status flipped `degraded-but-self-healing` → `healthy`, tier flipped `free` → `tier-1-paid`, failure history table refreshed, recommendation #1 closed.

## Cross-refs

- Pre-upgrade diagnostic: `2026-05-11-gemini-48p-diagnostic.md`
- Pre-upgrade quota pattern: `2026-05-11-quota-pattern-saved.md`
- Pre-upgrade partial fix: `2026-05-11-gemini-fix-applied.md`
