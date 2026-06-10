# Spec: conversation-capture hook (self-learning loop)

**Author:** code-1, 2026-06-10. **Status:** ready-to-build — gated on `code-1/brain-autonomy-systemd` PR landing on main (depends on memory-engine `insertVerbatim` + migrated `getDb`, which live on that branch).

## Why
The autonomy loop now learns from EXTERNAL ingest (youtube/github → `verbatim_exchanges` → distill → memory). The missing half is **self-learning**: the brain learning from our OWN work sessions. `verbatim_exchanges.source_type` already includes `"conversation"` (verified) — nothing writes those rows yet. This hook closes that gap: each session's exchanges → `verbatim_exchanges` → nightly distill (G4) → durable memory the whole firm recalls.

This is THE compounding mechanism — the firm learns from what it actually does, not just what we feed it.

## Design (env-gated, default-OFF — operator activates)

1. **Hook:** a Claude Code `Stop` (or `SessionEnd`) hook in `command-center/.claude/settings.json` (the project hook Lane 2 created; NOT operator's global `~/.claude/settings.json`). Runs `_bin/capture-exchange.sh`. Fail-safe: any error exits 0, never blocks the session.
2. **Gate:** `BRAIN_ENABLE_CONVERSATION_CAPTURE` (default OFF). Hook is a no-op until the operator flips it. Capturing conversation content is a privacy decision → operator's to activate (consistent with G4/G6 + the distiller-key pattern).
3. **Capture script** (`_bin/capture-exchange.ts` via tsx): reads the transcript path the hook provides, extracts the exchange(s), and calls memory-engine `insertVerbatim(getDb(MEMORY_DB), { source_type: "conversation", project, conversation_id, ply_start/ply_end, body, ... })`. Idempotent on `body_sha256` (already the verbatim dedup key) so re-runs don't double-insert.
4. **Scope:** tag rows with `FIRM_ROLE`/project so per-project memory stays isolated (no cross-pollution — global CLAUDE.md rule). Capture only the current pane's project.

## Privacy / safety (must-have before activation)
- **Secret redaction:** strip obvious secrets before insert — `.env`-style `KEY=value`, `sk-…`/`ghp_…`/bearer tokens, anything under the secret-handling deny rules. A redaction pass in the capture script; never persist a raw key. (The distiller also sees these rows → double-guard.)
- **Never capture** `.env*` file contents, `~/.ssh`, `.git/config` (already operator deny rules).
- Default-OFF means zero capture until the operator reviews a sample + flips the gate (mirror the G4 PII-review gate).

## Verify before declaring done
- Hook fires on session stop, writes a `conversation` verbatim row (gate ON, test session).
- Redaction: a session containing a fake `sk-ant-test…` string → the persisted row has it masked.
- G4 distillDay picks up the new `conversation` rows → produces a MemoryObject (end-to-end with the real distiller once `ANTHROPIC_API_KEY` is set).
- Gate OFF → zero rows written (no-op proven).

## Dependencies / sequencing
- Build off **clean main AFTER the `code-1/brain-autonomy-systemd` PR merges** (needs `insertVerbatim` + migrated `getDb` + the `state/` dir, all on that branch). Building it on the unmerged PR stacks branches — avoid per CHARTER §3 rule 10.
- ~Half a day of work once unblocked. Mostly new files (`_bin/capture-exchange.{ts,sh}` + a redaction util + settings hook entry + tests); low collision with code-2's apps/infra lane.

## Open operator decisions (surface before activation)
1. Capture ALL panes' conversations, or only the workspace leaders (code-1/code-2)? (Privacy + signal-to-noise.)
2. Retention on `conversation` verbatim rows (the 24/7 retention work prunes agent_tasks; verbatim should have its own TTL once it grows).
3. Activation gate flip is operator's (like G4/G6) after a redaction-sample review.
