---
title: Runbook — Autonomy Gates G4/G6 (the on-switch)
type: runbook
created: 2026-06-03
audience: operator
purpose: Objective, mechanical on-switch procedure for the two autonomy gates — brain-G4 (nightly-distill cron) + brain-G6 (queue-watcher auto-pickup). Per gate — what it turns on, exact env flag(s), preconditions to open, verification, 30-second rollback. Pairs with the PII-review checklist for the G4 distill gate.
related:
  - "[[Runbook-Brain-Preflight-Checklist]]"
  - "[[Checklist-PII-Review-Distillation]]"
  - "[[2026-06-03-node-migration-MOC]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[Decision-No-Auto-Activation]]"
  - "[[recall-eval-2026-05-25]]"
tags: [runbook, operator-gates, autonomy, brain-gates, safety, brain-G4, brain-G6]
---

# Runbook — Autonomy Gates G4/G6

> **The WHY (binding).** brain-G4 + brain-G6 are the **autonomy on-switch** for the brain product — the difference between an agent that waits to be triggered each time and an agent on the job 24/7. They ship **OFF**. They are gated for *safety* (autonomous writes to / pickups into a brain that holds sensitive data), **not bureaucracy**. The always-on baseline (heartbeat + lease reaper) runs at `G4=0 / G6=0` and takes **no autonomous write or pickup** — it just keeps the loop alive and the queue clean. Flipping G4/G6 is opting into autonomy. See [[2026-06-03-node-migration-MOC]] §1 + §6 for product framing.

> **Disambiguation.** These are the `brain-G*` gates (Obsidian-Brain workflow toggles), not the `infra-G*` family (Litestream / LAN-exposure / coverage). The `brain-` prefix is the source of truth. See [[Runbook-Brain-Preflight-Checklist]] for the full gate family + the brain-G3 (worktree-default) procedure not repeated here.

This runbook makes the on-switch **mechanical, not stressful**: objective preconditions, copy-paste verification, and a 30-second revert per gate. Default order: **brain-G4 → brain-G6** (distill before pickup — you want the distill layer trustworthy and PII-clean before you also let the brain ingest operator drops unattended). Each gate is independent; stop after either.

> **WHO decides (binding).** Both gates are **operator-gated** per `~/.claude/CLAUDE.md` + [[Decision-No-Auto-Activation]]: **no skill, agent, cron, or health-check may flip them ON or OFF.** Only the operator does, by hand, on the node. **This runbook REPORTS readiness and gives the exact procedure; it does not flip anything.**

> **Readiness summary (2026-06-03).** Harness-side preconditions are green (recall **MRR = 0.9556**, offline fake-vector). **One precondition is PENDING:** re-confirm `MRR > 0.6 AND P@1 > 0.5` with **`RAG_EMBED_REAL=1`** against the real **bge-m3/Ollama** embedder on the node (dim 1024), which first requires Ollama to be up + reachable. Plus: run the [[Checklist-PII-Review-Distillation]] on a real batch. **Verdict: NOT yet ready to flip brain-G4 ON for live autonomy** — the offline MRR proves the harness, not live retrieval. brain-G6 has its own ≥1-week manual-presence precondition (below).

---

## The binding principle (read before flipping anything)

Per `~/.claude/CLAUDE.md` and [[Decision-No-Auto-Activation]]:

1. **Health-checks REPORT; the operator decides.** Failures + anomalies land as a line in `00-firm-bus/feed.md` (and the morning briefing). They do **not** trigger any action.
2. **No auto-disable.** No skill, orchestrator, or health-check may flip a gate OFF based on anomaly detection. That is a slippery slope to silent degradation. Only the operator flips a gate — in either direction.
3. **Flip ONE gate at a time**, observe for the stated window, then the next.
4. **Rollback is operator-invoked, fast, and reversible** — flip the flag OFF, restart, done (≤ 30s). It is not a punishment; it is a normal control.
5. If an activated gate misbehaves but isn't outright broken, prefer leaving it ON and filing a `10-tasks/_open/` ticket over yo-yoing the activation. Yo-yoing erodes confidence in the gate-system itself.

---

## brain-G4 — Nightly-distill cron

### What it turns on
- A daemon/cron job runs nightly (~03:00 local) and distills **yesterday's** captured actions (the `audit_log` / verbatim rows) into MemoryObjects, **writing them into the brain on a schedule** with no operator present.
- A distill report lands in `08-system-architecture/distill-report-<date>.md`.
- This is the "co-located fast learning" loop — the brain self-updates daily instead of waiting for a manual `/skill brain-distill-daily`.

### Exact env flag(s)
- **`BRAIN_ENABLE_NIGHTLY_DISTILL`** — `0`/unset = OFF (**ships OFF**); `1` = ON. This is the single gate flag; it arms the BrainOrchestrator `nightly-memory-distill` trigger → the memory-engine **two-tier distill** (verbatim audit rows → MemoryObjects) **runs nightly** with no operator present (the gated trigger; see [[AGENT_ORCHESTRATION_SPEC]] §9 + `MEMORY_DISTILLATION_SPEC` §6). The cron line is the scheduler; the flag is the safety gate. Both must be present for nightly writes to occur.
- **Where to set it** (the node, not your laptop): `command-center/docs/deploy/node-stack/.env` on the node — add/flip `BRAIN_ENABLE_NIGHTLY_DISTILL=1`. The compose service reads it as an `environment:` / `env_file:` entry, so the running container/process must be **recreated** (`docker compose up -d brain-orchestrator` or the equivalent restart) to pick up the change — an `export` in your shell does NOT reach the daemon.
- Authoritative flag location: `command-center/docs/deploy/node-stack/AUTONOMY-GATES.md` (out-of-vault; the on-switch reference) + [[2026-05-25-brain-upgrade-plan]] §6.
- **Flag-name note:** canonical name is `BRAIN_ENABLE_NIGHTLY_DISTILL`. An earlier draft + some spec cross-refs used `BRAIN_NIGHTLY_DISTILL_ENABLED` — same gate; the `BRAIN_ENABLE_*` form is the source of truth here. If both appear in the orchestrator env, reconcile to the `ENABLE` form before flipping.

> Flag-name discipline: this runbook names the flag and cross-refs the orchestrator's gated trigger. It does **not** restate the trigger's internal logic — `MEMORY_DISTILLATION_SPEC` §6 (the `nightly-memory-distill` contract + 500-distill/night backpressure cap) is the binding source.

### Preconditions to OPEN (status as of 2026-06-03)
- [x] **Recall MRR ≥ 0.6** — **STATUS: PASS** (eval **MRR = 0.9556** on the gold eval-set, 2026-06-03). ⚠️ **Caveat:** this run was on the **offline fake-vector** embedder (deterministic stub, not real semantics). It clears the *harness* gate but does **not** yet prove live retrieval quality. **Must be re-confirmed with `RAG_EMBED_REAL=1` against the real bge-m3/Ollama embedder on the node** (dim 1024) before this precondition counts as truly met for *live* autonomy. ← **this is the one remaining PENDING precondition** (see below). Acceptance gate is `MRR > 0.6 AND P@1 > 0.5`; capture the real-embedding result path (`08-system-architecture/eval/results-*.md`) in the sign-off.
- [ ] **bge-m3 actually reachable** — Ollama service up on the node, `bge-m3` model pulled, embedding endpoint returns a **1024-dim** vector. This is the prerequisite for the `RAG_EMBED_REAL=1` re-confirm above; verify it first (`curl` the Ollama embeddings endpoint, assert vector length 1024). **STATUS: must verify on the node.**
- [ ] **PII / secrets review of distilled content passed** — run [[Checklist-PII-Review-Distillation]] against a sample distilled batch; zero Category-A leaks, every Category-B item correctly `sensitive:`-flagged. This is the binding precondition the operator must not skip. **STATUS: run before flip** (the checklist is the procedure).
- [ ] memory-engine package landed + tested (merge-train STEP 4/STEP 7 dependencies; bge-m3 embedder present, dim 1024).
- [ ] `brain-distill-daily` skill run manually 3+ times with no errors.
- [ ] sqlite-vec storage < 1GB initially (`du -sh ~/code/command-center/data/`).
- [ ] Operator-alert path tested: a forced failure produces a line in `00-firm-bus/feed.md`.
- [ ] Logrotate / retention configured for `distill-report-*.md`.

> **The one PENDING precondition, stated plainly:** everything the harness can prove offline is green (MRR 0.9556). What is **not yet proven** is that retrieval works against *real* bge-m3 embeddings on the node. Until a `RAG_EMBED_REAL=1` eval over real bge-m3/Ollama re-confirms `MRR > 0.6 AND P@1 > 0.5`, treat live retrieval as **unverified** and do **not** trust it for autonomous nightly writes. This is the single blocker between "harness-green" and "operator-confident G4-on".

### Activation (operator only)
```bash
# 1. Arm the safety gate — edit the node-stack env file ON THE NODE (not your shell):
#    command-center/docs/deploy/node-stack/.env
#      BRAIN_ENABLE_NIGHTLY_DISTILL=1
# 2. Register the scheduler (cron on the node):
crontab -e
# Add: 0 3 * * * /home/nithu/code/command-center/_bin/run-skill.sh brain-distill-daily date=$(date -u -d yesterday +\%Y-\%m-\%d)
# 3. Recreate the brain-orchestrator service so it re-reads .env:
#    docker compose -f command-center/docs/deploy/node-stack/compose.yml up -d brain-orchestrator
#    (a bare restart that does NOT re-read env_file will not pick up the flag).
```

### Verification (after first scheduled run)
- [ ] A `distill-report-<date>.md` appeared in `08-system-architecture/` overnight.
- [ ] MemoryObject count grew roughly as projected (~30/day estimate; not 0, not a runaway).
- [ ] The morning `feed.md` carries a cron-result line (success or failure — both prove the alert path works).
- [ ] Spot-check 3–5 distilled MemoryObjects against [[Checklist-PII-Review-Distillation]] — zero category-A content.
- [ ] An operator-recall query returns relevant results (sanity that distill + index are coherent).

### Rollback (30-second revert)
```bash
# 1. Disarm the gate in the node-stack .env:
#      BRAIN_ENABLE_NIGHTLY_DISTILL=0
# 2. Remove the cron line (belt-and-suspenders):
crontab -e                                  # delete the 0 3 * * * brain-distill-daily line
# 3. Recreate the service so it re-reads .env:
#    docker compose -f command-center/docs/deploy/node-stack/compose.yml up -d brain-orchestrator
# Manual /skill brain-distill-daily still works on demand.
```
Flipping the flag OFF is sufficient even without touching cron: at `=0` the gated trigger takes no write. Removing the cron line is belt-and-suspenders.

**Confirm the daemon went quiet:**
- [ ] No new `distill-report-<date>.md` appears in `08-system-architecture/` after the next ~03:00 window.
- [ ] MemoryObject count is flat overnight (no autonomous growth): compare `count(*)` before/after.
- [ ] `feed.md` shows no `nightly-memory-distill` run line after the flip.
- [ ] (If containerized) `docker compose ... logs brain-orchestrator` shows the trigger reporting **disabled/gated** at startup, not firing.

### Observe (1 week) + sign-off
- 7 successful runs, MRR ≥ 0.6 sustained, no PII leak found in any spot-check, no silent failures.

---

## brain-G6 — Queue-watcher auto-pickup

### What it turns on
- The BrainOrchestrator `youtube-queue` + `github-discovery` triggers **actively pick up** files the operator drops into `12-youtube/_queue/` and `13-github-repos/_queue/` — **no human in the loop**.
- Picked-up file → task dispatched → ingestion runs (yt-dlp / `gh` API) → distilled note in `12-youtube/` or `13-github-repos/`.
- The operator stops needing to manually invoke `/skill youtube-ingest` or `/skill github-discover`.

### Exact env flag(s)
- **`BRAIN_ENABLE_QUEUE_WATCHER`** — `0`/`false`/unset = OFF (**ships OFF**); `1`/`true` = ON. Arms the queue-watcher **daemon** so it **auto-drains** the `youtube` + `github` queues — the orchestrator's `youtube-queue` + `github-discovery` queue-watch triggers actively pick up drops with no human in the loop (the gated triggers; see [[AGENT_ORCHESTRATION_SPEC]] §9, with rate-limits per [[YOUTUBE_INGESTION_SPEC]] §9 + [[GITHUB_DISCOVERY_SPEC]] §9).
- **Where to set it** (the node): `command-center/docs/deploy/node-stack/.env` → `BRAIN_ENABLE_QUEUE_WATCHER=1`, then recreate the orchestrator service (`docker compose ... up -d brain-orchestrator`) so it re-reads `env_file`. A shell `export` does NOT reach the daemon.
- Authoritative flag location: `command-center/docs/deploy/node-stack/AUTONOMY-GATES.md` + [[2026-05-25-brain-upgrade-plan]] §6.
- **Flag-name note:** canonical name is `BRAIN_ENABLE_QUEUE_WATCHER`; an earlier draft used `BRAIN_QUEUE_WATCHER_ENABLED` — same gate, `BRAIN_ENABLE_*` is the source of truth.

### Preconditions to OPEN (all must be true)
- [ ] **≥ 1 week of manual-on-presence verification** — the watcher has been run in manual/observe mode and the operator has confirmed it picks up + processes drops correctly without auto-execution. (Per node-migration MOC §6, this is G6's stated precondition.)
- [ ] `youtube-ingest` + `github-discovery` packages tested (D-2 + D-3 acceptance complete).
- [ ] Manual `/skill youtube-ingest url=<X>` on 5 test URLs → all produce sensible notes.
- [ ] Manual `/skill github-discover query=<X>` on 3 test queries → all produce sensible repo notes.
- [ ] Rate-limit tracking confirmed (daily cap 50 search + 20 extract per plan §7 risk-10); no blow-ups.
- [ ] License-guard verified on a real GPL repo (per [[LICENSE_GUARD_SPEC]]).
- [ ] Anti-hype-filter tested on 3 known-junk YouTube URLs → all filtered out.
- [ ] `_queue/README.md` drop-instructions tested by the operator (drop one file each).

> **Note on G6 + PII:** the queue-watcher ingests *external* content (YouTube / public GitHub), so the category-A leak surface is lower than G4. But ingested notes still land in the brain and become distill candidates — so the [[Checklist-PII-Review-Distillation]] spot-check still applies to a sample of auto-ingested notes before sign-off.

### Activation (operator only)
```bash
# Edit the node-stack .env ON THE NODE:
#   command-center/docs/deploy/node-stack/.env
#     BRAIN_ENABLE_QUEUE_WATCHER=1
# Recreate the service so it re-reads .env:
#   docker compose -f command-center/docs/deploy/node-stack/compose.yml up -d brain-orchestrator
```

### Verification (after first auto-pickup)
- [ ] A file dropped in `12-youtube/_queue/` (or `13-github-repos/_queue/`) is processed within ~1h.
- [ ] The resulting note lands in `12-youtube/` / `13-github-repos/` and reads sensibly (confidence > 0.7).
- [ ] No rate-limit error in `feed.md`.
- [ ] License-guard did not propose any incompatible repo as an implementation-task.
- [ ] No junk slipped through the anti-hype-filter.

### Rollback (30-second revert)
```bash
# Disarm in the node-stack .env:
#   BRAIN_ENABLE_QUEUE_WATCHER=0
# Recreate the service:
#   docker compose -f command-center/docs/deploy/node-stack/compose.yml up -d brain-orchestrator
# OR, for an instant halt without a restart: simply empty the _queue/ folders.
# Manual /skill youtube-ingest + /skill github-discover still work on demand.
```

**Confirm the daemon went quiet:**
- [ ] Drop a test file in `12-youtube/_queue/` — after the flip it is **NOT** picked up (still present after >1h; no resulting note).
- [ ] `feed.md` shows no `youtube-queue` / `github-discovery` pickup lines after the flip.
- [ ] (If containerized) `docker compose ... logs brain-orchestrator` shows the queue-watch triggers reporting **disabled/gated** at startup.
- [ ] Remove the test file from `_queue/` once confirmed.

### Observe (1 week) + sign-off
- 7 days clean, avg distilled-note confidence > 0.7, no operator-flagged false-positive ingestion, license-guard caught ≥1 incompatible repo (or zero false-positives if none dropped).

---

## All-autonomy-on state (the target)

With brain-G4 + brain-G6 both ON + stable (and brain-G3 worktree-default per the preflight checklist):
- Brain self-updates nightly (G4) and self-ingests operator drops within ~1h (G6).
- This is the "always-on autonomous agent" the node-migration is the foundation for ([[2026-06-03-node-migration-MOC]] §1) — runnable first on cloud-GPU, then migrated unchanged to the local node.
- Sensitive-data safety is held by: the `sensitive:` source-type routing (local-only embedding/LLM, never external — `MEMORY_DISTILLATION_SPEC` §line-57 / `RAG_ENGINE_SPEC` §5.4/§6.3), the distill EXCLUDE rules (§8.1), and the operator's PII spot-checks. Autonomy does **not** relax any of these.

---

## Related

- [[Runbook-Brain-Preflight-Checklist]] — the full brain-G* gate family + brain-G3 (worktree-default), shares the per-gate observe/sign-off pattern this runbook tightens for G4/G6.
- [[Checklist-PII-Review-Distillation]] — the G4 precondition: what must never be distilled + how to spot-check a batch.
- [[2026-06-03-node-migration-MOC]] — §1 product WHY, §6 open operator gates (the autonomy on-switch framing).
- [[2026-05-25-brain-upgrade-plan]] — §6 operator-gates, §13 status; the 10-module brain-OS plan.
- [[recall-eval-2026-05-25]] — the bge-m3 eval-harness gold-set + MRR ≥ 0.6 acceptance gate (G4 precondition).
- [[Decision-No-Auto-Activation]] — the no-auto-activation / no-auto-disable rule the gates respect.
- [[MEMORY_DISTILLATION_SPEC]] — the nightly-distill contract behind G4 (§6 trigger, §8.1 include/exclude).
- [[AGENT_ORCHESTRATION_SPEC]] — §9, the orchestrator's gated triggers G4/G6 arm.
- `command-center/docs/deploy/node-stack/AUTONOMY-GATES.md` — out-of-vault on-switch reference (authoritative flag locations).

---

Sist oppdatert: 2026-06-03 — v1.1. Finalized the on-switch: canonical flag names `BRAIN_ENABLE_NIGHTLY_DISTILL` (G4) + `BRAIN_ENABLE_QUEUE_WATCHER` (G6, both default OFF); node-stack `.env` + compose-recreate as the flip location; per-gate precondition STATUS (recall MRR=0.9556 PASS on offline fake-vector — **PENDING** real `RAG_EMBED_REAL=1` re-confirm against bge-m3/Ollama + bge-m3 reachability); "confirm-the-daemon-went-quiet" rollback checks; explicit operator-gated / reports-not-flips ownership + readiness summary. v1.0 was first issue alongside the node-migration MOC.
