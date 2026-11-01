# Node-migration sprint report — 3-wave execution (2026-06-03)

> **END-OF-DAY UPDATE (2026-06-03, supersedes the per-wave branch/next-step framing below):**
> - **Brain product → ONE merge candidate:** `brain-integration` and code-2's parallel PR #75 (`code-2/brain-runtime`) were deduped onto **`code-2/brain-reconcile`** (base = `brain-integration`; grafted code-2 eval-harness + `docker-compose.brain.yml` + AUTONOMY-GATES; dropped code-2's bge-m3/daemon in favour of code-1's Ollama-bge-m3 + Module A). **564 tests green, eval MRR=0.9556 → G4-precondition (≥0.6) PASS.** PR #75 closed superseded. **PENDING:** code-1 live-Docker validation (code-2 has no Docker in WSL) → then merge to `main` alongside `node-migration-exec-0603` (deploy infra, 4 commits). This is task #30.
> - **Module A (brain-orchestrator) is REAL** — built Wave 3 (heartbeat/reaper/triggers + tests), not "IN PROGRESS" as the Wave 3 table states.
> - **Ownership (deduped):** ai-1 owns Nexus (`node-migration-nexus`, pushed via SSH-443, 1108 tests). refi-doc-agent OWNED BY code-2 (OCR + per-bank profiles + bank-mail, 89 tests); code-1/as-1 stood down from refi. as-1 done #24 fiken-refresh (committed ff5d8ae, AS local, no remote).
> - **`@cc/youtube-ingest` + `@cc/github-discovery`** were EMPTY shells this morning, **being built RIGHT NOW (code-1)** — only types/queue/config scaffolds so far, NOT delivered. `@cc/rag-engine` + `@cc/memory-engine` (distill being finished, #28) are real.


**Goal:** make the whole workspace stack `docker compose up`-ready for the self-built 24/7 local AI/ops node (Tailscale-only, GPU for local LLM + bge-m3 embeddings). Binding sequence: **penger først → MVP → hardware** (~Aug 2026). This sprint did the dev-readiness work that binds no capital now so the box "just works" when bought.

**Inputs:** the 2026-06-02 dev-backlog (`2026-06-02-node-migration-dev-backlog.md`, spor A/B/C/D), promoted into shared tasks **#7–#30**. ~17 of those completed across three parallel agent waves on 2026-06-03.

> Detail lives here; durable summary lives in memory `project_node_migration.md` + `reference_brain_integration_branch.md`. Cloud-GPU bring-up and brain merge-train executable plan are owned by separate docs (`2026-06-03-cloud-gpu-bringup.md`, `2026-06-03-brain-merge-train-executable.md`) — not duplicated here.

---

## Wave 1 — infra spine + cutover (Spor A core)

| Agent | Delivered | Verification |
|---|---|---|
| CC-CUTOVER | command-center Postgres-cutover: node app-service added to CC compose (was Postgres-only), `DB_DRIVER=pg`, Redis + Qdrant added, `corenet` external net wired | App now boots under compose; pg path exercised (was sqlite-only / Railway-shaped) |
| CC-AUTH | Auth fail-fast on CC boot — refuse to start with missing/blank auth secret instead of serving open | Verified boot abort on empty secret |
| CC-ENV | Env-decouple: removed Railway-only assumptions, made app-port / listen-host configurable, portable env | CC build green off-Railway |
| CC-WEB | Web-build fix (build broke after compose/env changes) | Web build green |

## Wave 2 — Nexus + brain + embeddings (Spor A4/A5/A11 + Spor B)

| Agent | Delivered | Verification |
|---|---|---|
| NEXUS-COMPOSE | Nexus node-compose: WAN-publish removed (5432/6379/3000 → internal/Tailscale), `corenet` join, configurable listen-host (was hardcoded `0.0.0.0` at `apps/api/src/index.ts:166`) | Bindings internal-only |
| NEXUS-SECRET | H1 secret fix: hardcoded `user:password` in Nexus compose → secret-ref (no secret-in-VCS on node) | No plaintext creds in compose |
| NEXUS-LESSONS | derive-lessons fix (Nexus pipeline bug surfaced during survey) | Nexus suite stayed green (~1005 tests) |
| BGE-EMBED | **Real `embedding/bge-m3.ts` client implemented** — the GPU dependency that previously existed in NO branch. dim=1024, local-model path. Wired into brain-integration | RAG can now *produce* vectors, not just store/query stubs |
| BRAIN-MERGE | Brain merge-train consolidated onto branch `brain-integration`: **8 foundational DRAFT PRs merged** (workspace-lockfile, memory-engine skel/storage, sync-migration, package wiring), dedupe of C1/C2 collisions | Foundational packages now build/typecheck on the branch |

## Wave 3 — revenue MVP + remaining surfaces + glue (Spor C/D + new tasks)

| Agent | Delivered | Verification |
|---|---|---|
| REFI-PILOT | refi-doc-agent pilot path: customer onboarding flow + first bank-mail draft pilot, on top of prior auth + `REFI_ALLOW_REAL_DATA` gate + local-LLM default + Dockerfile/compose.node.yml | 22/22 tests; offline demo intact |
| SOKING-NODE | Søking containerized: Dockerfile + nightly cron for `daily.py` (lightweight, no CUDA) | Container builds; cron wired |
| AS-FIKEN | AS Fiken token-refresh implemented (#xx) | Refresh path exercised |
| DEPLOY-GLUE | Deploy + migration + backup glue: `deploy.sh` (corenet→data→apps ordered w/ healthchecks), pg_dump/restore migration, nightly backup (pg_dump + Qdrant snapshot). Folded in the verified **qdrant healthcheck fix** (bash `/dev/tcp` `/readyz` probe, replacing the `wget` probe that `qdrant/qdrant:latest` can't satisfy) | data compose smoke-tested on Docker 29.4.0: postgres+redis healthy, internal-only; qdrant now reaches healthy |
| MODULE-A | Brain-orchestrator (Module A — always-running heartbeat/reaper, the autonomy runtime) — **IN PROGRESS**, on `brain-integration` | Partial; not landed |

---

## Branches / commits created

- **`brain-integration`** (command-center) — merge-train consolidation: 8 PRs merged + bge-m3 wired + Module A WIP. See `reference_brain_integration_branch.md`.
- **`node-migration-exec-0603`** (command-center / workspace) — sprint deploy + infra glue: CC PG-cutover, compose, deploy/migration/backup.
- These two diverged (built in parallel) and are **NOT merged** → task #30.
- Nexus changes (compose/secret/listen-host) committed but **NOT pushed** (push gates below).

## Blockers / gates (all binding)

- **Hardware** — penger-first; node bought from cashflow (Lofoten/refi-pilot), realistically ~Aug 2026. Don't buy first.
- **Nexus push** — network-blocked: SSH:22 outbound blocked in this env, so push can't complete even with OK-kjør. Also OK-kjør-gated per CLAUDE.md.
- **Live trading-DB cutover** — gated; demo-only (`BROKER_MODE=demo`, no auto-degrade). Never auto-switch to live.
- **G4 (nightly-distill cron)** — gated on recall eval MRR ≥ 0.6 + PII review (#29).
- **G6 (queue-watcher auto-pickup)** — gated; the autonomy on-switch, opened once preconditions met.

## Prioritized next steps

1. **Finish Module A orchestrator** (heartbeat/reaper) on `brain-integration` — the always-on runtime that delivers the "no manual trigger" vision.
2. **memory-engine real distill (#28)** — replace skeleton distill with real two-tier distillation.
3. **Eval-harness (#29)** — build/run recall eval-set, prove MRR ≥ 0.6 (G4 precondition) + PII review.
4. **Branch reconcile (#30)** — merge `brain-integration` ↔ `node-migration-exec-0603` so brain stack and deploy stack agree before any node bring-up.
5. **Nexus push when networked** — land the committed compose/secret/listen-host changes once SSH:22 is reachable + OK-kjør.
6. **Cloud-GPU bring-up** — rent A100/4090 (Runpod/Vast) to deliver refi-pilot and exercise bge-m3 BEFORE the box exists; the same stack migrates unchanged to the node. See `2026-06-03-cloud-gpu-bringup.md`.

## Verification notes

- ~17/24 backlog tasks (#7–#30) completed; remainder is Module A, distill, eval, reconcile, push, cloud-GPU.
- "Built + verified" = tests green / binding confirmed / smoke-tested on live Docker, per rows above. Brain work = on `brain-integration` branch, not default branch.
- No secrets, financials, or PII in this report or in memory.
