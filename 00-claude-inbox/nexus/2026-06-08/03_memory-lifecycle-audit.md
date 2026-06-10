# Nexus memory subsystem — end-to-end lifecycle audit

Date: 2026-06-08
Mode: READ/ANALYSIS only. Source: `data/pull/*.json` + Railway CLI env + live curl + repo code.
Deployed build (per `/health`): API commit `5fd39f9b` (NOT in local `main` history; HEAD is `4e25db6`). This gap matters — see Risk #2.

---

## TL;DR

There are **two parallel "memory" systems** in Nexus, often conflated:

1. **`firm_memory` + `department_scores`** — the original structured trade-memory + recall layer (`firm-memory.ts`, written by the postmortem hook, read by `recallSimilarSetups`). This is the RAW→recall path for trade decisions.
2. **`agent_lessons` + `agent_knowledge`** — the newer "firehose" learning layer (Phase B/C). Lessons = self-derived statistical patterns from closed trades. Knowledge = external RAG content (YouTube/GitHub). This is the closer match to the `docs/memory/README.md` lifecycle (proposed→approved→archived/drifted).

The `docs/memory/README.md` RAW→DISTILLED→PROMOTED→DEPRECATED→ARCHIVED lifecycle is actually about **Obsidian/markdown buckets** (`daily/`, `promoted/`, `deprecated/`, `archive/`) — it's a *documentation/notes* lifecycle, explicitly "scaffolding only, distillation hook not activated" (line 86). It does NOT describe the DB tables. Don't conflate the two. The DB lifecycle is the `agent_lessons` status machine.

**Headline:** the learning *infrastructure* is wired and the env flags are flipped ON in prod — but the loop is **frozen**. Lessons are static since 2026-05-21 (3 rows, all `sample_size=1`, all `proposed`, 0 approved, 0 in last 7d). Knowledge store is **completely empty** (0/0/0). Despite continuous closing trades through 2026-06-05.

---

## 1. Lifecycle stages: code + RUN vs DORMANT

### A. `firm_memory` (structured trade memory + recall)
- **Code:** `apps/worker/src/firm/firm-memory.ts` — `writeFirmMemory`, `writePostmortem`, `writeSilentWin`, `recallSimilarSetups`, `recallSemanticContext`, `scoreDepartment`, `getDepartmentReliability`.
- **Write path:** `postmortem-hook.ts` (`runPostmortemForNewlyClosedTrades`) runs once per orchestrator cycle after close-capable steps, picks up closed-but-not-postmortem'd trades (7-day window, batch limit 5). `POSTMORTEM_HOOK_ENABLED=true` in prod → **WRITE PATH RUNS.**
- **Read/recall path:** `recallSimilarSetups` + `recallSemanticContext` (Qdrant). Gated by `MEMORY_RECALL_ENABLED`. **Prod = `MEMORY_RECALL_ENABLED=false` → recall is DORMANT.** firm_memory is being *written* but never *read back into decisions*. (This is the ORB-only-era kill-switch; never re-enabled.)
- **Retention/curation of firm_memory:** none. No TTL, no dedup, no archival of firm_memory rows. Unbounded (but low-volume: ~1 row per closed trade).
- **Net:** WRITE = RUNS, RECALL = DORMANT. Write-only memory = a log nobody reads.

### B. `agent_lessons` (self-derived statistical lessons)
- **Producer:** `scripts/firehose/derive-lessons.mjs` — pure stats, no LLM. Reads `simulated_orders` (status=closed, XAUUSD, 30d lookback), clusters by (regime, session, close_reason), `HAVING COUNT(*) >= 5`. anti_pattern when WR≤0.40, pattern when WR≥0.60, mid-range → no proposal. Fans out one row per target role (`risk-advisor`, `trade-critic`). Dedup/voting via `ON CONFLICT (fingerprint) → sample_size += 1`.
- **Scheduler:** `index.ts` setInterval (hourly check, fires only at 04:00 UTC, idempotent via `firm_state` key `firehose:derive_lessons:<date>`, spawns subprocess, captures redacted stderr into `:failed` marker). Gated by `AGENT_LESSONS_ENABLED=true` AND `LESSON_DERIVATION_ENABLED=true`. **Both ON in prod.**
- **Promotion (proposed→approved):**
  - Manual: Discord `!lesson approve <id>`.
  - Auto: `scripts/firehose/auto-promote-lessons.mjs` (`autoPromoteEligibleLessons`, called inside derive-lessons.mjs after derive). Karri's conservative spec: requires `sample_size >= 20` AND consistency `>= 0.8`, daily cap 3. Gated by `LESSON_AUTO_PROMOTE_ENABLED`. **Prod: flag ABSENT → auto-promote DORMANT.**
- **Injection (approved → agent prompts):** `agent-lessons/injection.ts` `buildLessonContext`, wired into risk-advisor + trade-critic. Gated by `AGENT_LESSONS_ENABLED` AND `LESSON_INJECTION_ENABLED`. **Both ON in prod — but reads ONLY `status='approved'`, and there are 0 approved lessons → injection fires but injects nothing.**
- **Drift / deprecation:** `drifted` status exists in the schema + counts (0). Drift-detection code referenced as "Phase C" but not observed running.
- **Net:** derivation gated-ON, injection gated-ON, but the loop is broken in the middle: **producer is frozen + nothing is approved → injection has nothing to inject.**

### C. `agent_knowledge` (external RAG — YouTube/GitHub)
- **Code:** `agent-knowledge/client.ts` (ingestChunks, setSourceStatus, rateChunk, searchByText FTS, countByStatus) + `injection.ts`. Lifecycle: pending → active → archived, operator-gated.
- **Gate:** `AGENT_KNOWLEDGE_ENABLED`. **Prod: flag ABSENT → entire subsystem DORMANT.**
- **Producer (ingester):** YouTube ingester landed (`9abd7ad`). No live ingest pipeline observed feeding prod. `/firehose/knowledge` = `{"rows":[]}`, counts 0/0/0.
- **Net:** fully DORMANT + empty. Note: this is Nexus's *own* agent_knowledge table — distinct from the workspace-level Brain `@cc/youtube-ingest`/`@cc/github-discovery` packages in command-center (different repo, different store). The CLAUDE.md "YouTube/GitHub ingestion" refers to the Brain packages, not this Nexus table.

### D. Retention / TTL (curation of the high-volume tables)
- **Code:** `apps/worker/src/firm/retention.ts`, wired into orchestrator once-per-UTC-day.
- **Gate:** `RETENTION_ENABLED=true` in prod → **RUNS.**
- Trims: `blackboard` (30d volume / 90d analysis, audit allowlist permanent), `sentiment_snapshots` 30d, `jobs` (7d done / 30d failed), `trade_strategy_snapshots` 90d.
- Does NOT touch `firm_memory`, `agent_lessons`, or `agent_knowledge`. Those have no retention.

### Stage summary table

| Stage | Mechanism | Prod gate | Status |
|---|---|---|---|
| firm_memory WRITE | postmortem-hook | POSTMORTEM_HOOK_ENABLED=true | **RUNS** |
| firm_memory RECALL | recallSimilarSetups/Qdrant | MEMORY_RECALL_ENABLED=**false** | **DORMANT** |
| lessons DERIVE | derive-lessons.mjs @04:00 | AGENT_LESSONS + LESSON_DERIVATION =true | gated-ON but **FROZEN** (no new rows since 21.5) |
| lessons APPROVE (manual) | Discord !lesson approve | n/a | unused (0 approved) |
| lessons APPROVE (auto) | auto-promote-lessons.mjs | LESSON_AUTO_PROMOTE_ENABLED=**absent** | **DORMANT** |
| lessons INJECT | buildLessonContext → risk/critic | LESSON_INJECTION=true | gated-ON but **inert** (nothing approved) |
| lessons DRIFT/deprecate | Phase C drift | — | not running |
| knowledge INGEST/active/inject | agent-knowledge | AGENT_KNOWLEDGE_ENABLED=**absent** | **DORMANT + empty** |
| retention/TTL | retention.ts daily | RETENTION_ENABLED=true | **RUNS** |
| Obsidian notes lifecycle | docs/memory README | manual | scaffolding only (per README L86) |

---

## 2. Live memory inventory + growth

- **agent_lessons:** 3 rows, all `proposed`, all `sample_size=1`, `created_at = 2026-05-21T05:33Z`. `lessons_last_7d = 0`. Frozen ~18 days.
  - id 2: UNKNOWN/UNKNOWN/OANDA_BACKFILL — 22.2% WR / 18 trades / -10841 PnL (this is the backfill cluster, not live signal — noise).
  - id 1: TRENDING/unknown/OANDA_SL_TP — 33.3% / 18 / -1937.
  - id 3: UNKNOWN/unknown/OANDA_SL_TP — 36.4% / 11 / -163.
  - All `anti_pattern`, all below the 0.40 WR cut. No `pattern` (profitable) lessons exist.
- **agent_knowledge:** 0/0/0. Empty.
- **firm_memory:** not directly countable over 443 (no endpoint; nexus-pg MCP dead). Inferred WRITTEN continuously via postmortem hook (POSTMORTEM_HOOK_ENABLED=true + trades closing daily), but unread (recall off).
- **Closed-trade volume (journal):** 57 trades over ~3 weeks, closing steadily through 2026-06-05 (3-5/day recently). So the *input* to derivation is flowing; the *output* is not.

**Why frozen:** `sample_size=1` is the smoking gun. If the 04:00 derive cron had run successfully on subsequent days and re-found the same clusters, `ON CONFLICT → sample_size += 1` would have pushed these well past 1. sample_size stuck at 1 means **the derive job has not successfully completed a single run since 2026-05-21**. Most likely cause: the job is crashing (recent commit `b59f39a` exists specifically to "capture redacted derive-lessons stderr into :failed marker" — i.e. derive WAS failing silently and they added crash-capture). The `:failed` markers would confirm, but the `/firehose/derive-status` endpoint that surfaces them returns 404 in prod (Risk #2).

---

## 3. Retention / TTL / dedup + growth risk

- `RETENTION_ENABLED=true` → daily TTL pass runs on blackboard / sentiment / jobs / trade_strategy_snapshots. This is the only active curation.
- **Dedup:** only inside agent_lessons (fingerprint ON CONFLICT). No dedup on firm_memory.
- **Unbounded-growth risk:** firm_memory has NO retention (write-only, no read, no TTL) — but volume is tiny (~1/trade), so low urgency. The high-volume tables ARE covered by retention now.
- **Stale-memory risk (the real one):** the 3 frozen lessons include the OANDA_BACKFILL cluster (-10841 PnL over 18 trades) — that is *backfill artifact data*, not a live trading pattern. If injection ever gets these approved, agents would be primed on a meaningless "lesson" derived from historical backfill rows. The derivation should exclude `close_reason='OANDA_BACKFILL'`.

---

## 4. agent_knowledge (YouTube/GitHub) status

- Nexus's own `agent_knowledge` table: wired, gated `AGENT_KNOWLEDGE_ENABLED` (absent in prod), **empty + dormant**. YouTube ingester code exists (`9abd7ad`) but no live ingest feeds it.
- The workspace CLAUDE.md "YouTube + GitHub ingestion" is the **Brain command-center packages** (`@cc/youtube-ingest`, `@cc/github-discovery`), a separate repo/store — not this Nexus table. Don't expect Nexus agent_knowledge to be populated by the Brain pipeline; they're disconnected.

---

## 5. Prioritized memory-management work list

Themed for the operator's automation push (make memory curate itself). Lane tags: [infra]=Claude can run freely per prinsipp-6; [Karri]=trade-influencing, gate via Karri.

**P0 — unfreeze the producer (the whole loop is dead without this)**
1. **[infra] Diagnose why derive-lessons hasn't run since 21.5.** Deploy current `main` (prod is on stale `5fd39f9b`, predates derive-status route + role-tagging fix `3a37500` + auto-promote `d991310`). Then read `/firehose/derive-status` `:failed` markers. Likely a crash or a schema mismatch (`simulated_orders` clustering). Until this runs, every downstream stage is inert. **This is the single highest-leverage fix.**
2. **[infra] Exclude backfill noise from derivation.** Add `AND close_reason <> 'OANDA_BACKFILL'` (and `regime/session <> 'UNKNOWN'` filter, or at least flag them) to `fetchClusters`. The current top "lesson" is a -10841 backfill artifact. Garbage-in poisons any future approval.

**P1 — close the loop (so memory acts, not just accumulates)**
3. **[Karri] Decide the approval path.** Right now 0 lessons are approved and injection (ON) has nothing to inject. Either (a) operator/Karri manually approve via Discord, or (b) flip `LESSON_AUTO_PROMOTE_ENABLED=true` (Karri's spec already caps it: sample_size≥20, consistency≥0.8, 3/day). Without a working producer (P0) this is moot — but it's the next gate. This is money-near → Karri.
4. **[infra] Re-evaluate `MEMORY_RECALL_ENABLED=false`.** firm_memory is being written every close but never read. Either turn recall back on (it's the original purpose) or stop writing it (dead-weight). Recall feeding back into decisions is arguably trade-influencing → confirm with Karri before re-enabling; but the *decision to stop wasting writes* is infra.

**P2 — observability + hygiene**
5. **[infra] Add memory-health to the morning briefing / a pull endpoint.** Surface: last successful derive run, lessons by status, knowledge count, firm_memory write count, retention last-run. The frozen-since-21.5 state went unnoticed for 18 days — exactly the class of silent failure the learning-ledger exists to catch. Add `/firehose/derive-status` to `pull-nexus-data.sh` once prod is redeployed.
6. **[infra] firm_memory retention/dedup** — low urgency (tiny volume) but if recall is re-enabled, add a similarity-key dedup + importance-decay so recall returns signal not noise.

---

## Bottom line for operator

- **Stages that RUN in prod:** firm_memory WRITE (postmortem hook), retention/TTL. That's it that's actually *working*.
- **Gated-ON but inert/frozen:** lesson derivation (frozen since 21.5, sample_size=1 = zero successful runs since), lesson injection (nothing approved to inject).
- **DORMANT (flag off/absent):** firm_memory recall (MEMORY_RECALL_ENABLED=false), lesson auto-promote, agent_knowledge entirely.
- **Top risk:** the learning loop has been silently dead for ~18 days while flags read "ON" — and prod is running a stale build that even lacks the endpoint to diagnose it. Self-curating memory is currently a façade.
- **Top-3 tasks:** (1) redeploy + diagnose/unfreeze derive-lessons [infra]; (2) exclude OANDA_BACKFILL/UNKNOWN noise from derivation [infra]; (3) Karri-gate the approval path (manual or LESSON_AUTO_PROMOTE) so approved lessons actually reach injection [Karri].
