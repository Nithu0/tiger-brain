# Cloud-GPU bring-up — fresh Runpod/Vast box, SAME corenet stack, Tailscale-only

> **What this is:** a concrete, copy-pasteable bridge runbook. Turns the
> existing [cloud-gpu-mvb-runbook](../../../code/command-center/docs/deploy/cloud-gpu-mvb-runbook.md)
> (the *why* + provider/cost framing) into an *execute-today* procedure for a
> brand-new Runpod / Vast.ai (or Hetzner GPU) box that runs the **same
> `corenet` compose stack** (data tier + Ollama `bge-m3` + a 7–14B chat model +
> command-center + refi) reachable **only over Tailscale**.
>
> **Why before hardware (operator's WHY, binding):** the home node is bought
> with cashflow ~Aug 2026 (penger → MVP → hardware). Until the node exists,
> Spor B (brain product) + refi-pilot run on **rented** cloud-GPU, then migrate
> **UNCHANGED** to the node — same compose, same `corenet`, same env-var names;
> only hostname + GPU-serving flags differ.
>
> **Binding gates (⚠️ GATE):** no WAN ports, ever. Tailscale-only / loopback.
> Spend-tak set before first pod. Only synthetic/anonymised data on the pod
> (it is rented hardware; the provider has physical access). State lives in
> **pg dumps + qdrant snapshots + git**, never on the ephemeral box.
>
> **Author:** agent CLOUD-GPU, 2026-06-03. Companion to (does not replace) the
> mvb-runbook. Reads also: [AS install-runbook Fase 0–7](../../../code/AS/docs/hardware/install-runbook.md)
> (the eid-node target; cloud Fase 1–5 below mirror its Fase 1–5).

---

## TL;DR — the one-screen version

1. **Provider:** Vast.ai for cheapest (`RTX 4090 24GB`, ~$0.30–0.50/hr) or Runpod
   for persistent Network Volume convenience. A **single 24GB GPU** runs
   `bge-m3` (~2–4GB) **plus** a 7–14B chat model (Q4 ~8–12GB) comfortably.
2. **Base setup (Fase 1–5):** Docker + NVIDIA Container Toolkit + Tailscale
   (`tailscale up --ssh`) + ufw default-deny. Same as the home-node install-runbook,
   on a cloud VM.
3. **Bring up the SAME stack:** `corenet` → data (Postgres+Qdrant) → Ollama →
   cc → refi. Identical compose files. **Only difference: the disk is ephemeral**,
   so volumes get backed up off-box.
4. **Models:** `ollama pull bge-m3` + `ollama pull qwen2.5:14b`; verify GPU use
   with `nvidia-smi`.
5. **Migrate home (UNCHANGED):** same compose + `pg_dump`/`pg_restore` +
   qdrant snapshot restore moves everything to the node. Only hostname changes.
6. **Cost + security checklist:** no WAN ports, Tailscale-only, spin-down
   discipline, encrypted off-box volume backups.

---

## 1. Provider choice + cheapest viable GPU (VRAM math + cost)

### 1.1 What the box must run — VRAM budget

The brain/refi stack needs **embeddings + one small chat model**, not the big
72B product model (that comes later, on A100 / the eid-node's 2×3090). For the
Spor-B-on-cloud + refi-pilot phase the working set is:

| Component | What | VRAM |
|---|---|---|
| `bge-m3` embeddings (dim **1024**) | Ollama | ~2–4 GB |
| 7B chat (Q4) — `qwen2.5:7b` / `llama3.1:8b` | Ollama | ~5–6 GB |
| **14B chat (Q4)** — `qwen2.5:14b` (recommended) | Ollama | ~9–11 GB |
| KV-cache / context headroom | — | +2–4 GB |

→ **A single 12–24GB GPU suffices.** A `RTX 4090 24GB` runs `bge-m3` **and**
`qwen2.5:14b` with room for context. A 12GB card (RTX 3060 12GB / A2000) runs
`bge-m3` + a 7B comfortably but is tight for 14B — use a 7B there. No multi-GPU,
no A100 needed at this phase.

Rule of thumb (control-core §G): Q4 size ≈ params × 0.5–0.6 GB + 2–4 GB KV.

### 1.2 Provider + cheapest viable pick

| Provider | Cheapest viable | ~$/hr | Persistent state | Notes |
|---|---|---|---|---|
| **Vast.ai** | `RTX 4090 24GB` | **$0.30–0.50** | per-instance disk (lost on *destroy*) | cheapest market; filter on reliability ≥ 0.98, disk ≥ 60GB |
| **Runpod** | `RTX 4090 24GB` Community | $0.40–0.69 | **Network Volume** (survives pod stop) | easiest model cache reuse; pick EU region |
| Runpod | `RTX 3090 24GB` (when listed) | $0.30–0.44 | Network Volume | same VRAM, cheaper, slightly slower |
| Hetzner | dedicated GPU (RTX 4000/6000) | ~€0.80–2/hr-equiv (billed hourly, monthly cap) | persistent disk | EU/GDPR-friendly, no per-second spin-down; better once usage is steady |

**Recommendation for "execute today":** **Vast.ai `RTX 4090 24GB`** for the
absolute-cheapest spin-up-when-needed pattern, OR **Runpod `RTX 4090 24GB` +
a 50–100GB Network Volume** if you want models to survive pod stop without
re-pulling. Both run `bge-m3` + a 14B unaided.

### 1.3 Cost estimate + spin-down discipline (cost discipline ⚠️)

> **You pay for every hour the box is UP, idle or not.** The only real cost
> trap is a forgotten idle box. Treat every session as **spin up → work →
> spin down**. Target < 2 h/day active in demo phase.

| Use pattern | Hrs/mo | $/hr | USD/mo | ~NOK/mo |
|---|---|---|---|---|
| Light build (4090, on-demand) | ~20 | $0.40 | ~$8 | ~90 |
| Active pilot build (4090) | ~60 | $0.45 | ~$27 | ~300 |
| + Runpod Network Volume 100GB | — | — | ~$7 | ~80 |
| Heavy demo weeks (4090, longer) | ~100 | $0.45 | ~$45 | ~500 |

→ Landing zone **~100–600 NOK/mo** at this phase (no A100 needed). A forgotten
4090 left running a week ≈ $75 ≈ blows the month. Discipline, not hardware,
is the cost lever.

- Use a **persistent/Network Volume** (Runpod) or hold the **stopped instance**
  (Vast) so you don't re-pull `qwen2.5:14b` (~9GB) + `bge-m3` each session. The
  volume costs ~$0.05–0.10/GB/mo, a fraction of the GPU hour.
- **Stop/Destroy the box in the dashboard — an SSH disconnect does NOT stop
  billing.** Set a phone/calendar alarm at every spin-up ("is the box off?").
- ⚠️ GATE: set a **spend cap / billing alert** in the provider dashboard
  *before* the first box. Prevents runaway cost.

---

## 2. Base setup on the rented box (mirrors install-runbook Fase 1–5)

You have a fresh Ubuntu box (Runpod/Vast give you `root` over SSH; Hetzner is
a normal Ubuntu 24.04 install). Run Fase 1–5 below — **identical to the
home-node [install-runbook](../../../code/AS/docs/hardware/install-runbook.md)
Fase 1–5**, just on a cloud VM.

```bash
# connect (Runpod proxy form, or direct ip:port from the dashboard)
ssh root@<pod-ip> -p <port> -i ~/.ssh/id_ed25519
# Runpod proxy alt:  ssh <pod-id>@ssh.runpod.io -i ~/.ssh/id_ed25519
```

### Fase 1 — base OS / disk
Cloud images are already Ubuntu 22.04/24.04 with a CUDA driver baked in. Just:
```bash
apt update && apt -y upgrade
# pick a persistent path for state: Runpod Network Volume mounts at /workspace.
# Put all compose volumes + model cache under /workspace so they survive a stop.
mkdir -p /workspace/stack /workspace/ollama /workspace/backup
```

### Fase 2 — grunnsikring (SSH keys, ufw default-deny)
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
# do NOT open 22 to WAN beyond what the provider already requires for its proxy.
# Tailscale (Fase 3) becomes the real access path; add its rule after:
sudo ufw allow in on tailscale0          # all Tailscale traffic, added after Fase 3
sudo ufw enable
sudo ufw status verbose
```
> ⚠️ GATE: never `ufw allow` an app port (8000/6333/5432/11434/3000) from WAN.
> They stay internal on `corenet` / loopback and are reached over Tailscale only.

### Fase 3 — Tailscale (the access path; no open WAN ports)
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --hostname refi-pod      # SSH over Tailscale identity, no WAN :22
```
Authenticate in the browser (same tailnet as laptop/phone). The box gets a
`100.x.y.z` IP + MagicDNS name `refi-pod`. This is the **exact same access
model as the eid-node** (install-runbook Fase 3) — migration only changes the
hostname. Lock down further in the Tailscale admin ACLs so only your devices
reach it.

### Fase 4 — Docker + Compose
```bash
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker run --rm hello-world      # verify
```
(On Runpod/Vast Docker is often preinstalled — skip if `docker version` works.)

### Fase 5 — NVIDIA Container Toolkit (GPU inside Docker)
The host driver is already present on cloud images (`nvidia-smi` works on the
host). You only need the **container toolkit** so Docker can pass the GPU through:
```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi   # must show the GPU
```

---

## 3. Bring up the SAME corenet stack (data + Ollama + cc + refi)

The **whole point**: the box runs the identical compose stack as the eid-node,
so migration is a state-restore, not a re-architecture. Clone the
command-center repo onto the box (build context for the node-stack composes)
and the refi repo, then bring services up in dependency order.

```bash
# on the box, in the persistent path so the checkout survives a stop:
cd /workspace/stack
git clone <command-center-repo-url> command-center
git clone <refi-doc-agent-repo-url> refi-doc-agent
cd /workspace/stack/command-center/docs/deploy/node-stack
```

The node-stack ships these files (same on cloud and node):
`docker-compose.data.yml`, `docker-compose.cc.yml`, `docker-compose.refi.yml`,
`docker-compose.brain.yml`, `docker-compose.openwebui.yml`, `00-corenet.sh`,
`deploy.sh`, `.env.node.example`, `AUTONOMY-GATES.md`.

### 3.1 Shared network + env
```bash
./00-corenet.sh                  # creates: docker network create corenet  (same name as node)
cp .env.node.example .env.node
$EDITOR .env.node
chmod 600 .env.node
```
`.env.node` values to set (NAMES only — fill real values yourself, never commit):
- `DATABASE_URL` → points at the `node-postgres` container on `corenet`
- `EMBED_BACKEND=ollama`
- `OLLAMA_BASE_URL=http://ollama:11434`  (container name on `corenet`)
- ⚠️ On cloud Fase 0/1 **leave the autonomy gates OFF**:
  `BRAIN_QUEUE_WATCHER_ENABLED=0`, `BRAIN_NIGHTLY_DISTILL_ENABLED=0`
  (per `AUTONOMY-GATES.md` — distill writes to brain; don't auto-pick `_queue/`
  on rented hardware until the eval gate passes).

### 3.2 Bring it up in order (healthcheck-gated)
```bash
./deploy.sh        # brings up corenet -> data -> ollama -> cc -> (brain) -> refi in order
```
Or stage-by-stage if you want to watch each tier:
```bash
docker compose -f docker-compose.data.yml up -d        # postgres + qdrant (internal, no WAN port)
docker compose -f docker-compose.openwebui.yml up -d   # ollama (+ optional Open WebUI)  -> §4
docker compose -f docker-compose.cc.yml up -d --build   # command-center
docker compose -f docker-compose.refi.yml up -d --build # refi-doc-agent (compose.node.yml mirror)
# optional always-on agent runtime (mvb-runbook §8):
docker compose -f docker-compose.brain.yml up -d --build
```

### 3.3 refi wiring — point it at the box's local model (no code change)
In `refi-doc-agent/.env` (names from its `.env.example`):
- `LLM_BACKEND=local-openai-compatible`
- `LOCAL_LLM_BASE_URL=http://ollama:11434/v1`  (Ollama's OpenAI-compatible layer)
- `LOCAL_LLM_API_KEY=not-needed`
- `LOCAL_LLM_MODEL=qwen2.5:14b`
- `REFI_SEED_ON_START=1`  (synthetic seed cases SAK-2026-001/002)
- `REFI_ALLOW_REAL_DATA=0`  ⚠️ GATE — keep OFF on rented hardware (§6 / mvb §5)

`services/llm.py` speaks the OpenAI protocol against the box unchanged; numbers
are still computed deterministically in `services/extraction.py` — the LLM
never touches amounts.

### 3.4 What differs from the home-node (the ONLY real differences)
- **Ephemeral disk.** The box (especially Vast on *destroy*) can be wiped. So:
  - put all named volumes' data + model cache under the **persistent path**
    (`/workspace/...`), and
  - **back up volumes OFF-box** (pg dumps + qdrant snapshots + git) — §6.
  - State of record = **pg dumps + qdrant snapshots + git**, NOT the box.
- **GPU-serving flags** scale to the smaller card (7–14B Q4, not 72B). Same
  Ollama, smaller model tag.
- **Hostname** is `refi-pod` instead of the node's hostname.
Everything else — compose files, `corenet`, container names, env-var names — is
byte-identical to the eid-node. That identity *is* the migration guarantee.

---

## 4. Pull models + verify GPU use

Ollama serves both embeddings and chat, and exposes an OpenAI-compatible layer
at `:11434/v1`. Bind it to the container network / loopback — **never 0.0.0.0
to WAN.**

```bash
# if Ollama runs in compose (container name: ollama):
docker exec -it ollama ollama pull bge-m3        # embeddings, dim 1024
docker exec -it ollama ollama pull qwen2.5:14b   # 7-14B chat (use qwen2.5:7b on a 12GB card)

# if Ollama runs as a host process instead:
OLLAMA_HOST=127.0.0.1:11434 ollama serve &
ollama pull bge-m3
ollama pull qwen2.5:14b
```

Verify the model actually uses the GPU (not CPU fallback):
```bash
# fire one chat request, then watch the GPU light up:
docker exec -it ollama ollama run qwen2.5:14b "say hi" &
nvidia-smi          # ollama process should appear under Processes, VRAM ~9-12GB used
docker exec -it ollama ollama ps    # should show qwen2.5:14b with "100% GPU" (not CPU)

# embeddings sanity (dim must be 1024):
curl -s http://localhost:11434/api/embeddings \
  -d '{"model":"bge-m3","prompt":"test"}' | python3 -c 'import sys,json;print("dim=",len(json.load(sys.stdin)["embedding"]))'
# -> dim= 1024  (matches the Qdrant collection: size 1024, distance Cosine)

# OpenAI-compatible endpoint (what refi/cc talk to):
curl -s http://localhost:11434/v1/chat/completions -H 'Content-Type: application/json' \
  -d '{"model":"qwen2.5:14b","messages":[{"role":"user","content":"hei"}]}'
```
If `ollama ps` shows `CPU` instead of `GPU`, Fase 5 (container toolkit) didn't
take — re-run `nvidia-ctk runtime configure` + restart Docker, and ensure the
Ollama compose service has `deploy.resources.reservations.devices` / `--gpus all`.

### 4.1 Reaching the box from laptop/phone (Tailscale, no WAN port)
Once `tailscale up` (Fase 3) is done, point apps at the MagicDNS name:
- command-center / Open WebUI: `http://refi-pod:3000`
- Ollama: `http://refi-pod:11434/v1`
- Qdrant: `refi-pod:6333`, Postgres: `refi-pod:5432`
This is the **same access pattern as the eid-node** — migration changes only
`refi-pod` → node hostname. (SSH `-L` tunnel is the fallback if Tailscale is
unavailable; mvb-runbook §4.2.)

---

## 5. Migration path — when the home node arrives (UNCHANGED)

When pilot-cash is confirmed (EXECUTION-DASHBOARD §5 gate) and the node is
built per [install-runbook](../../../code/AS/docs/hardware/install-runbook.md)
Fase 0–6, the stack moves home as a **state restore on identical compose** —
no re-architecture.

**Cross-linked scripts/dirs (in `command-center/docs/deploy/`):**
- `node-stack/00-corenet.sh` — creates the **same** `corenet` network on the node
- `node-stack/deploy.sh` — brings the **same** stack up in order on the node
- `migration/` — the pg/qdrant restore scripts (dump → restore pair)
- `_dumps/` — where pg_dump output lands (off-box backup target, §6)
- `backup/` — qdrant snapshot + volume backup staging
> Note (2026-06-03): the owning agent had `docs/deploy/` checked out / mid-rewrite
> when this was authored, so confirm the exact script filenames inside
> `migration/` before the run — the dir + intent are fixed; a filename may have
> been renamed in this wave.

**Migration steps (mvb-runbook §6 + install-runbook Fase 7, made concrete):**
1. Build the node: install-runbook Fase 0–6 (Ubuntu, ufw, Tailscale, Docker,
   NVIDIA toolkit, Caddy/Portainer).
2. `node-stack/00-corenet.sh` on the node — **same network name** → `data`
   compose is unchanged.
3. **Restore state from the off-box backups** (taken in §6):
   ```bash
   # Postgres: restore the dump taken from the pod into the node container
   cat /backup/pg/refi-YYYYMMDD.dump | docker exec -i node-postgres pg_restore -U postgres -d refi --clean --if-exists
   # (or psql < plain.sql if pg_dump used plain format)
   # Qdrant: restore the snapshot taken from the pod
   #   upload snapshot via Qdrant snapshot API, or drop the snapshot dir into the
   #   node's qdrantdata volume and use the recover-snapshot endpoint.
   ```
4. Pull the models locally on the node Ollama (GPU-tuned to the node's card,
   e.g. 3090; for the big product model use the A100/2×3090 path):
   ```bash
   docker exec -it node-ollama ollama pull bge-m3
   docker exec -it node-ollama ollama pull qwen2.5:14b   # or the larger product model
   ```
5. `node-stack/deploy.sh` on the node → **the same stack** comes up. Point
   `LOCAL_LLM_BASE_URL` / `DATABASE_URL` host at the **node hostname** instead
   of `refi-pod` — that hostname swap is the **only** app change.
6. Verify parity (same demo flow answers identically), then **destroy the pod +
   volume** in the provider dashboard. Confirm billing stopped.

Design guarantee: cloud-stack and node-stack share `docker-compose.*.yml` +
`corenet` + `.env.node` names + `LLM_BACKEND=local-openai-compatible`. The only
variables are **hostname** and **GPU-serving flags (model size)**.

---

## 6. Cost + security checklist (⚠️ GATE items)

### Cost discipline
- [ ] Spend cap / billing alert set in provider dashboard **before** first box. ⚠️ GATE
- [ ] Persistent/Network Volume used so models aren't re-pulled each session
      (≪ GPU-hour cost).
- [ ] **Spin down via dashboard Stop/Destroy** at end of session — *not* just an
      SSH disconnect. Phone alarm at every spin-up ("is the box off?").
- [ ] Cheapest viable GPU chosen (`RTX 4090 24GB` ~$0.30–0.50/hr; no A100 at
      this phase — `bge-m3` + 14B fit in 24GB).
- [ ] Target < 2 h/day active; landing zone ~100–600 NOK/mo.

### Security / data
- [ ] **No WAN ports.** ufw default-deny; only `tailscale0` allowed in. No
      `ufw allow` on 8000/6333/5432/11434/3000 from WAN. ⚠️ GATE
- [ ] All services bound to `corenet` / `127.0.0.1` — never `0.0.0.0`. ⚠️ GATE
- [ ] Access only over Tailscale (`tailscale up --ssh`); admin ACLs scoped to
      your devices.
- [ ] **Only synthetic / anonymised data on the box** (`REFI_ALLOW_REAL_DATA=0`,
      synthetic seed cases). The box is rented hardware — provider has physical
      access. No real personnummer / kontonummer / lønnstall. ⚠️ GATE
      (mvb-runbook §5: jurist + DPA/DPIA gate before any real data, ever.)
- [ ] State of record lives **off-box**: pg_dump + qdrant snapshot + git.
      Treat the box as disposable.
- [ ] **Encrypted off-box volume backups** — dump/snapshot, then encrypt before
      moving off the box:
      ```bash
      docker exec node-postgres pg_dump -U postgres -Fc refi > /backup/pg/refi-$(date +%F).dump
      # qdrant snapshot via API/CLI into /backup/qdrant/
      gpg --symmetric --cipher-algo AES256 /backup/pg/refi-$(date +%F).dump   # encrypt
      # then copy the .gpg off-box (your laptop / encrypted object store), NOT the raw dump.
      ```
- [ ] On Fase 0/1: autonomy gates OFF (`BRAIN_QUEUE_WATCHER_ENABLED=0`,
      `BRAIN_NIGHTLY_DISTILL_ENABLED=0`) per `AUTONOMY-GATES.md` — flip only
      after the eval gate, and re-decide deliberately on the node.
- [ ] Before destroying the box: backups confirmed restorable, then Destroy +
      confirm billing stopped.

---

Authored 2026-06-03 by agent CLOUD-GPU. Bridge companion to
`command-center/docs/deploy/cloud-gpu-mvb-runbook.md` (the why) and
`AS/docs/hardware/install-runbook.md` (the eid-node target). Fase 0/1 in the
capital sequence: penger → MVP → hardware. No git, no code edits — drop only.
