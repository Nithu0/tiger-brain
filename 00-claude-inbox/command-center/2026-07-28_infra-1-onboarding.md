# infra-1 onboarding v2 — full analyse

Dato: 2026-07-28 · Rolle: infra-1 (tidl. code-1) · Dispatch: orchestrator-1 15:03Z
Kartlagt med 4 parallelle Explore-agenter (read-only). Ingen endringer i drift, ingen push.

## 1. Domene og eierskap

infra-1 eier: systemd-units (brain + executors), launchers (`command-center/_bin/firm-*`), Vast-GPU-tooling, deploy-docs (`docs/deploy/`), WSL-dockerd/Hermes-sandbox-infra, Railway-infra-siden.

Viktig kontekst lest før noe annet (per dispatch): `migration/ROLE-MAP.md` (alle 8 v1→v2-rader UTFØRT; codex-1..8 utsatt til F3) og `docs/ops/REMOTE-AUTONOMY.md` (8 Claude v2-executors + verdict-watch AKTIVERT 28.07 som systemd user-units; codex-executors ikke enablet).

**Launcher v3 og rollemigreringen er allerede levert av orchestrator-1** (operatør ba om alt i én sesjon 27.07). Verifisert i kode: `_bin/firm-wt-split.sh:4-12` (v2-grid per spec §1), `:223-243` (INIT-linjer for alle 8 v2-roller), `:132-133`/`:265-266` (stopper både v1- og v2-locks), `_bin/firm-roles.sh:23-30` (legacy-resolver code-1→infra-1 osv.). Min F1-launcher-oppgave er altså DONE av andre — rest er §9-punktet (se §4).

## 2. Driftsbilde (verifisert live ~17:05)

**GRØNT.** 0 failed units, `Linger=yes`.

| Unit | Status |
|---|---|
| brain-orchestrator.service | active, 18t oppe |
| brain-worker.service | active, 18t |
| firm-remote-executor@{orchestrator,infra,trading,learning,tools,paal,data,admin}-1 | 8/8 active siden 15:04, 0 restarts |
| firm-remote-verdict-watch.service | active |
| hermes-gateway.service | active, 6 dager |
| ollama-keepwarm.timer | aktiv, 10-min-syklus, siste kjøring OK |

Jobb-kø: queue/active = 0 filer, done = 4 (nyeste 15:04). Session-id-heartbeats ferske (17:01) for alle 8 roller.

**Avvik notert (report-only, per no-auto-disable-regelen):**
1. brain-worker distill 14:57: 2/85 rader feilet med «haiku-distiller: LLM did not return valid JSON (Unterminated string)». Task ble completed; retry tar kun feilede rader. Gjentakende mønster — engine-lane (ikke min), verdt en truncation-fiks i distilleren.
2. hermes-gateway: verktøykall mot `ai-assistent/_bin/brain-doctor.sh` → exit 127 (filen finnes ikke; riktig sti er command-center/_bin). Ødelagt sti i Hermes-skill/oppskrift.
3. hermes-gateway: «Context file CLAUDE.md blocked: exfil_curl» — Hermes kjører uten CLAUDE.md-kontekst pga. curl-mønster i filen.
4. ~~`agents/data-1/` hang etter~~ — avklart: data-1 kvitterte onboarding på feed 15:09Z. Ikke et avvik.

## 3. Repo-tilstand (delt checkout — kun lest)

- Står på `feat/firm-v2-rollout`, 2 commits foran main: `0330f69` (F1-leveransen) + `047a7fc` (F4a facets, memory-engine). **Venter operatør OK kjør.**
- Working tree rent bortsett fra 2 untracked: `pnpm-lock.yaml` + `pnpm-workspace.yaml` — uventet i et npm-repo; noen har kjørt pnpm. Bør avklares/slettes før de committes ved et uhell.
- Branch-støy: 40+ gamle `code-1/*`-brancher fra mai-fanouten, ikke merget. Én med worktree i `~/.cache/cc-recovery/brain-autonomy`. Ryddejobb — operatør-gated (branch-sletting).
- Ingen TODO/FIXME i `_bin/*.sh`; åpne punkter ligger i `docs/ops/HARDENING-REPORT.md` + `migration/UNRESOLVED.md`.

## 4. F1-rest: Hermes-sandbox → WSL-dockerd (spec §9:113-129)

Faktisk tilstand er bedre enn spec-en antar:
- `docker context ls` → `default *` = `unix:///var/run/docker.sock`; `docker info` → Ubuntu 24.04, native WSL-dockerd (ikke Desktop-motoren); `which dockerd` → `/usr/bin/dockerd`; docker.service enabled+active; `systemd=true` i /etc/wsl.conf.
- MEN: `/mnt/wsl/docker-desktop*` finnes fortsatt (Desktop installert), og **0 containere kjører** — Hermes-sandboxen er ikke oppe under noen motor akkurat nå.

**Gjenstår (= mitt aktive mål, satt i GOALS.md):**
(a) Hermes-sandbox-container opp under WSL-dockerd; (b) formell boot-persistens-test (WSL-restart uten Desktop-GUI, verifiser at sandbox + docker.service kommer opp); (c) beslutning om Docker Desktop skal avinstalleres/ryddes (operatør-gated).

## 5. F3: GPU-ROI-collector (min eneste F3-leveranse)

Spec ferdig skrevet: `FIRM-V2-SPEC.md` §7 (:99-104) + strategisk plan §4 — systemd-timer → caddy/ollama-logs → `gpu_requests`-tabell i command-center.db → dashboard-side + morgenbrief + report-only varsel ved 7d-ROI < 0.5× break-even.

- GPU-boks i dag: Vast `46026731`, RTX 4090, ~$270/mnd, Ollama `81.166.173.12:11602` (qwen3:8b, qwen3:30b-a3b-thinking, bge-m3). Kun SSH; Tailscale er reservert on-prem-noden.
- Byggeklosser som finnes: `_bin/gpu-usage-report.sh` (parser ollama-log + nvidia-smi → BUSY/IDLE-verdikt), `_bin/cost-guard{,-api}.sh`, `_bin/cost-log.sh`.
- Gap: `~/.firm/api-usage.jsonl` finnes ikke (token-meteret ved distiller-callsite ble aldri wiret — gammel dispatch fra code-2 19.06, fortsatt åpen); `command-center.db` sist skrevet 23.06 og apps/api kjører ikke → dashboard-flaten forutsetter at API-en vekkes.
- Hvorfor det haster: learning-1s målerapport viste **950 worker-kall lekket lydløst til betalt OpenAI i 6 dager** da forrige GPU-boks (`42212247`) døde 21.07. Collectoren + «local-share < X%»-varsel er fangsten for akkurat dette.
- NB: Hermes (`~/.hermes/config.yaml`) og Codex (`~/.codex/config.toml`) kan fortsatt peke på den døde boksens URL — verifiseres/repekes som del av F3-arbeidet.
- Fase-navn-avvik: strategisk plan kaller GPU-ROI «F2», spec §10 + inbox-dispatch sier F3. Antar spec/inbox vinner — **orchestrator-1: bekreft.**

## 6. Andre åpne punkter på min pult

1. `migration/UNRESOLVED.md:9` (fra data-1): inbox-redirect-headers + rolle-locks for soking-1/thesis-1 — migreringsartefakt fra `firm-migrate-roles.sh`. Liten ryddejobb.
2. `docs/ops/FIRM-OPERATING-MODE.md` lister fortsatt v1-rollenavn i ingressen — doc-fiks, kan gå på main.
3. Gamle inbox-dispatches til code-1 (skill-registry schema, distill-stabilisering, grossist domain-pakke fra as-1 21.07) er nå **lane-foreldreløse etter v2-remappingen** — skill/engine-lane hører trolig hjemme hos tools-1/data-1, grossist-domain hos paal-1/codex. Flagges til orchestrator-1 for re-dispatch; jeg tar dem ikke inn i infra-domenet.

## 7. Anbefalt rekkefølge (min plan)

1. Hermes-sandbox → WSL-dockerd + boot-persistens-test (aktivt mål, F1-rest).
2. UNRESOLVED.md:9-rydding + FIRM-OPERATING-MODE v2-navn (små, kan ri sammen).
3. F3 GPU-ROI-collector: først log-collector + `gpu_requests` (uavhengig av API), deretter dashboard/morgenbrief når API vekkes.

Ingen push — OK kjør-gaten står. `feat/firm-v2-rollout` venter allerede på operatør.

— infra-1
