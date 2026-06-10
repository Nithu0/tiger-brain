---
title: Node-Migration MOC
type: moc
created: 2026-06-03
updated: 2026-06-04
purpose: Canonical Map-of-Content for the workspace-wide node-migration sprint — the WHY (product framing), hardware spec + install-runbook, deploy glue (node-stack/migration/backup), the brain merge-train, the cloud-GPU-first→node bridge, and the open operator autonomy gates
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[System-Architecture-MOC]]"
  - "[[Memory-MOC]]"
  - "[[RAG-MOC]]"
tags: [moc, node-migration, hardware, on-prem, brain-orchestrator, bge-m3, autonomy, refi-pilot]
---

# Node-Migration MOC

Curated index for the workspace-wide **node-migration** — moving the whole stack (command-center, Nexus, refi-doc-agent, Ollama/Open WebUI, brain-orchestrator + memory-engine + RAG) onto a self-built **24/7 local Ubuntu AI/ops node**, Tailscale-only, GPU for local LLM + bge-m3 embeddings. This MOC only points; binding truth lives in the linked specs, runbooks, and the node-migration memory object. Where a claim here and a source doc disagree, the source doc wins.

> **One-line frame:** the hardware is not the endpoint — it is the *foundation* for the product (always-on autonomous agents + co-located learning + local LLM). The brain (Spor B) is the product; it runs on cloud-GPU first, then migrates unchanged to the node.

---

## 1. The WHY — product framing (binding)

Authoritative framing in the workspace memory `project_node_migration.md` (2026-06-03, corrects the earlier "hardware is just a consequence" framing). Summarised, not duplicated:

- **Hardware = FOUNDATION, not nice-to-have.** Operator wants (1) an efficient local LLM for specific use; (2) everything run locally AND securely with **memory + results co-located in one place** so the LLM learns faster/more efficiently; (3) **real always-on agents working 24/7** — NOT agents that must be manually triggered/activated each time. The current firm-pane + cron + gated-queue-watcher model is exactly the pain being rejected.
- **The architecture that delivers the vision:** brain-orchestrator ([[2026-05-25-brain-upgrade-plan|Module A]], always-running heartbeat + lease reaper) + memory-engine ([[Memory-MOC|Module B]], two-tier distill = co-located fast learning) + RAG with **local bge-m3 embeddings** (the GPU-bound piece) + local LLM.
- **Refi-pilot funds the box.** It is the simpler, partner-co-built revenue piece (speed up regnskapsfører's flow: customer onboarding + first bank-mail). It FUNDS the box but is not the end.
- **Spor B (brain) is the product** — runnable first on cloud-GPU, then migrated unchanged to the node. This is what makes the cloud→node bridge (§5) a true bridge and not a rewrite.

Related decision context: [[Decision-No-Auto-Activation]] (the no-auto-activation rule the autonomy gates respect), [[Truth-Hierarchy]].

---

## 2. Hardware — spec + install-runbook

Authoritative specs live in the **AS repo** (not the brain). Linked here as out-of-vault references:

- `AS/docs/hardware/build-spec.md` — ~26–28k NOK build: Ryzen 9 9950X + ProArt X870E + Define 7 XL + used RTX 3060 → 3090 upgrade path. The GPU is the bge-m3 / local-LLM dependency.
- `AS/docs/hardware/install-runbook.md` — Ubuntu 24.04 → Docker → shared **corenet** (Postgres / Redis / Qdrant) → apps bound to the Tailscale IP → backup.
- `AS/docs/EXECUTION-DASHBOARD.md` — binding sequence: **penger først → MVP → hardware**. Box bought with cashflow (Lofoten / refi-pilot), realistically **~August 2026**. Do NOT buy hardware first; deliver refi-pilot on rented cloud-GPU first.

---

## 3. Deploy glue — node-stack / migration / backup

Lives in the **command-center repo** (`command-center/docs/deploy/`). Built 2026-06-02 by the code-1/code-2 lane; **landed on `main`** 2026-06-04 via PR #77. Out-of-vault references:

### node-stack (`command-center/docs/deploy/node-stack/`)
- `00-corenet.sh` — creates the shared `corenet` Docker network.
- `docker-compose.data.yml` — Postgres + Redis + Qdrant, **internal-only binding** (no `0.0.0.0` publish).
- `docker-compose.cc.yml` · `docker-compose.refi.yml` · `docker-compose.brain.yml` · `docker-compose.openwebui.yml` — per-app stacks bound to the Tailscale IP.
- `deploy.sh` — orchestrates corenet → data → apps with `wait_healthy` gating.
- `scripts/check-bindings.sh` — asserts no service is exposed beyond Tailscale.
- `secrets-strategy.md` · `tailscale-acl.example.json` — secrets layout + ACL template.
- `AUTONOMY-GATES.md` — the G4/G6 on-switch reference (see §6).

### migration (`command-center/docs/deploy/migration/`)
- `pg-migrate.sh` · `redis-copy.sh` · `sqlite-copy.sh` · `qdrant-migrate.sh` — data carriers cloud → node.
- `ollama-models.md` — model pull/restore list for the local LLM + embedder.

### backup (`command-center/docs/deploy/backup/`)
- `pg-backup.{sh,service,timer}` · `qdrant-snapshot.{sh,service,timer}` · `restic-volumes.{sh,service,timer}` + `crontab.sample` — systemd-timer backup set for the node.

### cloud-GPU bridge
- `command-center/docs/deploy/cloud-gpu-mvb-runbook.md` — Runpod / Vast pre-hardware path (see §5).

> **Verified 2026-06-03 (live Docker 29.4.0):** postgres + redis come up healthy with internal-only binding confirmed. **Known break:** the Qdrant healthcheck uses `wget`, which `qdrant/qdrant:latest` lacks (only bash/sh) — it never goes healthy and `deploy.sh wait_healthy qdrant` aborts the whole deploy before apps start. Verified fix = bash `/dev/tcp` probe to `/readyz` (200 OK); handed to code-2. Confirm fix landed before any node deploy.

---

## 4. Brain merge-train — the product code

> **2026-06-04 — LANDED ON UNIFIED `main`.** The brain merge-train, the reconcile branch, and the deploy infra have all merged to **`main`** via **PR #77 (merge `eb8286f`)**; **PR #76 absorbed**; **reconcile task #30 is DONE**. `main` is now the single unified mainline: Module A always-on daemon (G4/G6 default-OFF + boot-verified), rag-engine + bge-m3 Ollama client, memory-engine distill-real, `@cc/youtube-ingest` + `@cc/github-discovery` now REAL (not shells), eval MRR=0.9556 — **plus** the node deploy infra (`docs/deploy/node-stack` incl. `docker-compose.brain.yml` + `AUTONOMY-GATES`, `backup/`, `migration/`). Follow-up `da81d97` fixed a rag-engine↔memory-engine build cycle → main typecheck clean. Branch off `main` now; `brain-integration`/`code-2/brain-reconcile` are history. The 2026-06-03 / DRAFT-PR notes below are kept for the dedup/ordering rationale only.
>
> **2026-06-03 end-of-day (superseded by the line above):** the scattered DRAFT-PR picture below is now superseded by a single merge candidate. code-1 (`brain-integration`) and code-2 (PR #75) both built the merge-train + bge-m3 + daemon in parallel; deduped onto ONE branch **`code-2/brain-reconcile`** (base = `brain-integration`). **564 tests green, eval MRR=0.9556 → G4-precondition (≥0.6) PASS.** PR #75 closed superseded. Module A orchestrator is REAL (built Wave 3 — heartbeat/reaper/triggers + tests), not WIP. The historical DRAFT-PR plan below is kept for the dedup/ordering rationale.

The product code (Module A orchestrator + Module B memory-engine + Module K RAG + the bge-m3 embedding client) originated as **~65 open DRAFT PRs** on `command-center`. The executable landing plan:

- [[2026-06-03-brain-merge-train-executable]] — the canonical, deduped, numbered merge order (supersedes the 2026-06-02 triage and the older PR_MERGE_ORDER / MASTER_BRIEF docs). Key points:
  - **Dedup first, then order.** Close 7 duplicate PRs (#56, #60, #51, #52, #53, #63, #50); one cherry-pick (rag eval-runner → `code-1/rag-eval-runner-port`).
  - **bge-m3 embedding client slots at STEP 4** — after memory-engine storage (#12, which defines the `sqlite-vec` vector surface + 1024-dim contract) and before the rag-engine chain (STEP 7a, whose `vector.ts` returns `[]` for every recall until a real embedder exists). Must export `embed(text): Promise<Float32Array>` (dim **1024**, bge-m3 via Ollama), satisfy `assertValidEmbedding` / `BGE_M3_DIM` from `@cc/memory-engine`, and NOT re-declare the dimension constant.
  - **Sharpest conflict:** migration-id-003 collision (#3 vs #14) — renumber #14 → 004 before merge.
- [[2026-06-02-brain-merge-train-triage]] — the prior 2026-06-02 triage (superseded; kept for the per-PR notes).
- Per-PR push remains operator-gated (`brain-G5` / "OK kjør") per [[2026-05-25-brain-upgrade-plan]] §6.

The package-level architecture these PRs implement is indexed by [[System-Architecture-MOC]] (specs) + [[Memory-MOC]] (Module B) + [[RAG-MOC]] (Module K).

---

## 5. The cloud-GPU-first → node bridge

The product must ship before the box exists (penger-first). The bridge makes that a migration, not a rewrite:

1. **Now → MVP:** brain-orchestrator + memory-engine + RAG run on **rented cloud-GPU** (Runpod / Vast) per `command-center/docs/deploy/cloud-gpu-mvb-runbook.md`. bge-m3 embeddings + local LLM run on the rented GPU; same Docker compose topology as the node (`corenet` + data + apps).
2. **Refi-pilot delivered on cloud-GPU** → generates cashflow → funds the box (~Aug 2026).
3. **Migrate unchanged to the node:** the `migration/` carriers (pg / redis / sqlite / qdrant + ollama models) move state; the same compose files run on the local Ubuntu node, now Tailscale-only. Because Spor B was built compose-native and storage-portable (sqlite-vec default), the cutover is data-move + DNS/Tailscale, not re-architecture.

The piece that *forces* the node for production is **privacy**: sensitive data (refi-docs, regnskap, helse, trading strategy) must never go to an external embedding/LLM API — so ingestion/embedding/rerank run **local-first** (per [[RAG-MOC]] / `RAG_ENGINE_SPEC` §1.3), which is exactly the GPU-bound dependency the box satisfies.

---

## 6. Open operator gates

These are the explicit go/no-go decisions still pending. Per [[Decision-No-Auto-Activation]] and `CLAUDE.md`: health-checks REPORT, operator decides. The framing (per `project_node_migration.md`): **G4/G6 are the autonomy on-switch** — the difference between "an agent that waits to be triggered" and "an agent on the job 24/7" — gated for *safety* (autonomous writes to a brain holding sensitive data), not bureaucracy.

| Gate | What it switches on | Precondition before flip | Source |
|---|---|---|---|
| **brain-G4** — nightly-distill cron | Daemon distills yesterday's actions → MemoryObjects → writes to vault on a schedule (`BRAIN_NIGHTLY_DISTILL_ENABLED=1`). Ships OFF. | recall **MRR ≥ 0.6** on eval-set + PII/secrets review of what gets written | `node-stack/AUTONOMY-GATES.md`, plan §6 |
| **brain-G6** — queue-watcher auto-pickup | Daemon auto-picks operator drops from `12-youtube/_queue/` + `13-github-repos/_queue/` with no human in the loop. Ships OFF. | ≥1 week of manual-on-presence verification first | `node-stack/AUTONOMY-GATES.md`, plan §6 |
| **penger → MVP → hardware** | Buying the box. | refi-pilot delivered on cloud-GPU + cashflow present (~Aug 2026) | `AS/docs/EXECUTION-DASHBOARD.md` |
| **Nexus live-DB cutover** | Pointing Nexus at node Postgres / flipping live-capital. | foundation gate green + Nexus compose hardened (no `0.0.0.0` publish, no hardcoded creds — ai-pane owns) | [[2026-05-25-brain-upgrade-plan]] §6, [[Foundation-Gate]] |
| **brain-G5** — per-PR push | Any push of a merge-train PR to a protected ref. | "OK kjør" per PR | plan §6, `CLAUDE.md` |

The always-on baseline (heartbeat + lease reaper) runs at **G4=0 / G6=0** and takes no autonomous write or pickup — it just keeps the loop alive and the queue clean. Flipping G4/G6 is opting into autonomy.

---

## 7. Current status (2026-06-04 — unified mainline)

`main` is now the **single unified mainline** carrying both the brain product and the node deploy infra (PR #77, merge `eb8286f`; PR #76 absorbed; reconcile #30 DONE). Supersedes the 2026-06-03 end-of-3-wave-sprint status.

### Built + landed on `main`
- **`main` = SINGLE UNIFIED MAINLINE.** Brain product + node deploy infra both live on `main`; no more divergent `brain-integration` / `node-migration-exec-0603` branches.
- **Module A (brain-orchestrator) always-on daemon** — heartbeat + lease reaper + trigger-registry + daemon, with **G4/G6 gates default-OFF + boot-verified**. The always-on autonomy runtime.
- **`@cc/rag-engine`** (hybrid BM25+vector, fusion, agentic loop) + the **bge-m3 Ollama embedding client** (dim **1024**, `sqlite-vec` storage side — the previously-missing GPU dependency, now on `main`).
- **`@cc/memory-engine` distill-real** — the real distill (formerly scaffold / #28) is landed.
- **`@cc/youtube-ingest` + `@cc/github-discovery` are REAL on `main`** — no longer empty shells.
- **eval-harness MRR=0.9556** (seam/harness number → G4-precond ≥0.6 PASS on the seam).
- **Node deploy infra on `main`** — `docs/deploy/node-stack/` incl. `docker-compose.brain.yml` + `AUTONOMY-GATES.md`, plus `backup/` and `migration/`. (Data layer smoke-tested live Docker 29.4.0; qdrant `/dev/tcp` `/readyz` healthcheck fix folded into `deploy.sh`.)
- **Build cycle fixed** (follow-up `da81d97`) — rag-engine↔memory-engine dynamic-import specifier assembled at runtime → **main typecheck clean**.
- **refi-doc-agent (OWNED BY code-2)** — OCR + per-bank profiles + bank-mail, 89 tests (pilot-safe). **Nexus (ai-1)** — `node-migration-nexus`, 1108 tests. **AS Fiken (as-1)** — #24 token-refresh (ff5d8ae, AS local). **Hardware specs + cloud-GPU bridge runbook** authoritative.

### In progress NOW (code-1, 2026-06-04 — NOT done)
- **C1-9 task-persistence layer** — `agent_tasks` + `firm_state` tables + `TaskStore` + **real heartbeat/reaper** + **trigger→enqueue wiring**. This is what makes brain autonomy **END-TO-END**: before C1-9, triggers published a `TaskPayload` to *nowhere*. The missing link, not cosmetic.
- **memory-engine corpus-IDF** — real IDF over the corpus, replacing scaffold weighting.
- **apps node-wiring** — wiring apps to the node-stack compose topology.
- **Real-embedding eval re-confirm** — standing up **Ollama bge-m3 in Docker** to re-run eval against real embeddings (not the test-seam). **PENDING.** Closes the **last G4 precondition** (real-embedding recall); the MRR=0.9556 above is the seam number, this is the real confirm.

### Gated (waiting on operator)
- **Hardware purchase** — penger-first, ~Aug 2026.
- **brain-G4 / brain-G6** — autonomy on-switch; ship OFF. G4 seam-precondition (MRR ≥ 0.6) PASSES (0.9556); **real-embedding confirm + PII/secrets review still PENDING** before flip.
- **Nexus live-DB cutover** — foundation gate + Nexus compose hardening (no `0.0.0.0` / no hardcoded creds; ai-pane owns).
- **All pushes** — brain-G5 per-PR OK-kjør.

### Next product-critical build
- **Land C1-9 (end-to-end autonomy wiring)** + **memory-engine corpus-IDF** + **apps node-wiring**, then **re-confirm eval against real Dockerized bge-m3** to close the last G4 precondition.

---

## Related

- [[2026-05-25-brain-upgrade-plan]] — the 10-module brain-OS plan (A=orchestrator, B=memory, K=RAG) this migration runs on; §6 holds the brain-G* gate family.
- [[System-Architecture-MOC]] — index of the per-module specs.
- [[Memory-MOC]] — Module B (two-tier distill = co-located learning).
- [[RAG-MOC]] — Module K (local bge-m3 retrieval, the GPU dependency).
- [[Decision-No-Auto-Activation]] — the rule the autonomy gates respect.
- [[Foundation-Gate]] — the Nexus precondition for the live-DB cutover gate.
- `project_node_migration.md` (workspace memory) — binding WHY + gap list + shared task backlog #7–#30 + 2026-06-03 end-of-day ground truth.

---

*Out-of-vault source paths (`AS/docs/hardware/`, `command-center/docs/deploy/`) are referenced as plain paths, not wikilinks, since they live in code repos. Brain-internal docs use wikilinks. Binding truth lives in the source docs; this MOC points.*
