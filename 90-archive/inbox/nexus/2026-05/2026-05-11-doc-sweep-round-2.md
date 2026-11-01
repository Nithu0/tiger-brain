# Doc-sweep round 2 — 2026-05-11

Final doc-drift pass over `/home/nithu/code/ai-assistent/docs/` after round-1
(`f8ff485`) and the parallel CONTEXT-MAP refresh series (`07eeef5`, `3f4e47b`).

## Scope

- Doc-only, `.md` in `docs/`.
- 92 doc files scanned; 15 most-recent files reviewed in depth, older docs
  spot-checked by keyword sweep.
- No code changes. No behavior changes.

## Verification probes run

```
grep -rn "TWELVE_DATA_KEY|NEWSAPI_KEY|nexus-production|STRATEGY_BLADE_ENABLED.*default true" docs/
grep -rn "10 modules|ten modules|10 firm modules" docs/
grep -rn "TODO|\[draft\]|\[DRAFT\]" docs/
grep -rn "As of 2026-04-2[0-5]|Last updated.*2026-04-2[0-5]" docs/
grep -rln "Last updated" docs/
```

After fixes, the only remaining `TWELVE_DATA_KEY` / `NEWSAPI_KEY` hits are
the historical-rename note in `env-vars.md` and the test-code string literals
in `firehose-plan-06may.md` (`sanitizeForCommit` test fixtures). Both legitimate.

## Files touched

| File | Change | Lines |
|---|---|---|
| `docs/CONTEXT-MAP.md` | "10 modules" → "16 firm modules + 10 firm-agents" (intro); "10 modules + decision path" → "16 firm sub-modules + decision path" (read-first item 3). Aligns with `firm-modules.md` count corrected in round 1. | 2 edits, ~2 lines |
| `docs/ops/agent-roster.md` | Added production-state note clarifying that the "OFF default" column is the code default — not the Railway-active state (6/10 agents on since 2026-05-03 per `CONTEXT-MAP`). | +2 |
| `docs/ref/incomplete-features.md` | Drift-note banner at top + inline status on `POSITION_MANAGEMENT_ENABLED` line (flagged stale by both `audit-nexus-2026-05-08.md` action item and `CONTEXT-MAP` "what's likely stale" list). | +4, -1 net |

Total lines changed across the two final commits: **CONTEXT-MAP 5 (+3,-2)** in `3f4e47b` (auto-committed mid-session by parallel agent), **agent-roster + incomplete-features 6 (+5,-1)** in `763247a`.

## Commit

`763247ad57f484b03f433e75f3178c1030b27021`

```
docs(sweep): round-2 drift cleanup — production-state notes on stale docs
```

## What was NOT touched (intentional, in-scope)

- `docs/architecture/audit-nexus-2026-05-08.md`, `audit-thesis-2026-05-08.md` — historical audit documents; references to "10 firm modules" / scattered architecture files are correct as of audit date.
- `docs/ops/operator-decisions.md` (line 70 "10 firm-agents") — count is current.
- `docs/ops/firehose-plan-06may.md` — `TWELVE_DATA_KEY` references are inside test-code examples demonstrating env-key sanitization. Not drift.
- `docs/ref/env-vars.md` line 21/23 — explicit historical-rename notes (`renamed from legacy TWELVE_DATA_KEY` / `NEWSAPI_KEY`). Intentional.
- All `docs/ops/orb-*`, `tier3-*`, `pickup-22apr.md`, `session-23apr.md`, `week1-sprint.md` — dated historical reports; archive-eligible but rewrite is out of scope per round-2 brief.

## Out-of-scope drift (intentionally not touched — `.md` outside `docs/`)

- `/home/nithu/code/ai-assistent/CLAUDE.md:13` still says "10 modules" — same string drift as `CONTEXT-MAP`, but `CLAUDE.md` is at project root, not in `docs/`. Per sweep scope-discipline, left alone. Flag for operator to fix in next CLAUDE.md refresh.

## Top candidates for full rewrite (flagged, not done)

1. **`docs/ref/incomplete-features.md`** — dated 2026-04-22; ~50% of the inline content (foundation gate red, OHLCV unverified, position-mgmt "flipping 22.4 morning", FASE-5 open) is resolved. The catalog of env-gated-complete modules + FASE 6/7/8 deferrals still applies, but every timeline line is stale. Banner now warns the reader; full rewrite needed when operator has 30 min.

2. **`docs/ops/orb-deploy-report-25april.md`, `orb-weekend-26-27-april.md`, `tier3-deploy-26april.md`, `tier3-day1-status-27april.md`, `pickup-22apr.md`, `pickup-23apr.md`, `session-23apr.md`, `week1-sprint.md`** — all dated 2026-04-22 to 2026-04-27, all historical. `audit-nexus-2026-05-08.md` line 87 already recommends moving them to `docs/ops/archive/`. Pure organizational move + index update in `CLAUDE.md` "Where to find details" table. Not done here because (a) rewrite-flagged per round-2 brief and (b) it's a 5-file move + 1-table edit that benefits from operator confirmation on which to keep visible.

3. **`docs/FASE-5-duplicate-sync-diagnose.md`** — root-level (not under `docs/ref` or `docs/ops`). Issue resolved (closed in `incomplete-features.md`). Same audit recommendation: move to `docs/ops/archive/`. Out-of-scope as a move op.

## Cross-cutting observations

- The round-1 fixes (firm-modules count, env-var renames, feature-flags TIER 3, blackboard topics) compose cleanly with round-2 (downstream consistency in CONTEXT-MAP intro). No regressions detected.
- `phase-status.md`, `feature-flags.md`, `blackboard-topics.md`, `env-vars.md`, `firm-modules.md`, `known-issues.md`, `runtime-map.md`, `agent-roster.md`, `tool-roster.md`, `critical-rules.md`, `regimes.md` all internally consistent on the current production state.
- The "Last updated 2026-05-08" stamps on docs `runtime-map.md`, `tool-roster.md`, `known-failures.md`, `agent-roster.md`, `claude-code-capabilities.md` accurately reflect their mtime — refresh-on-change discipline is holding.
