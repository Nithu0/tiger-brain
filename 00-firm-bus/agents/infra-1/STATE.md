# infra-1 — STATE

_Peker: autoritativ prosjektstatus = `<repo>/project_state.md` (PATH-MAP.md)._

Oppdatert: 2026-07-28T17:15Z (onboarding v2, tidl. code-1).

## Domene
Infra/ops: systemd-units, launchers (`_bin/firm-*`), Vast-GPU, deploy (`docs/deploy/`), WSL-dockerd, Hermes-sandbox-infra.

## Driftsbilde (verifisert 2026-07-28 ~17:05)
- **GRØNT.** 0 failed units, Linger=yes. brain-orchestrator (18t oppe) + brain-worker (18t) + 8/8 `firm-remote-executor@*` (siden 15:04, 0 restarts) + verdict-watch + hermes-gateway (6 d) + ollama-keepwarm-timer.
- Jobb-kø tom (queue/active = 0). Session-id-heartbeats ferske for alle 8 v2-roller.
- Launcher v3 + rollemigrering v1→v2: LEVERT av orchestrator-1 (commit `0330f69` på `feat/firm-v2-rollout`, 2 commits foran main — venter OK kjør).

## Åpne infra-1-punkter
1. **F1-rest: Hermes-sandbox → WSL-dockerd** (spec §9). Delvis oppfylt: default docker-context ER WSL-dockerd (`unix:///var/run/docker.sock`), docker.service enabled+active, `systemd=true` i wsl.conf. Gjenstår: (a) Hermes-sandbox-container opp under WSL-dockerd (0 containere kjører nå), (b) formell boot-persistens-test, (c) beslutning om Docker Desktop-rester (`/mnt/wsl/docker-desktop*`).
2. **F3: GPU-ROI-collector** (spec §7 — min eneste F3-leveranse). Byggeklosser: `gpu-usage-report.sh`, `cost-guard-api.sh`. Gap: `~/.firm/api-usage.jsonl` finnes ikke (token-meter aldri wiret); `command-center.db` stale siden 23.06 → dashboard-flaten krever at API vekkes. Motivasjon: 950 worker-kall lekket lydløst til betalt OpenAI da forrige GPU-boks døde 21.07.
3. **migration/UNRESOLVED.md:9**: inbox-redirect-headers + rolle-locks for soking-1/thesis-1 (migreringsartefakt, flagget av data-1).
4. Doc-drift: `FIRM-OPERATING-MODE.md` bruker fortsatt v1-rollenavn.

## Avvik observert (report-only)
- brain-worker distill: gjentakende «LLM did not return valid JSON (Unterminated string)» — 2/85 rader 27.07. Selvhelbredende via retry, men mønsteret gjentar seg. Engine-lane.
- hermes-gateway: verktøysti `ai-assistent/_bin/brain-doctor.sh` finnes ikke (exit 127); CLAUDE.md blokkert av exfil_curl-filter → Hermes kjører uten den kontekstfilen.
- Fase-navn-avvik: strategisk plan kaller GPU-ROI «F2», spec/inbox sier F3 — avklares med orchestrator-1.

## GPU-boks
Vast `46026731`, RTX 4090, ~$270/mnd, Ollama på `81.166.173.12:11602` (qwen3:8b, qwen3:30b-a3b, bge-m3). Kun SSH (Tailscale er reservert on-prem-noden). Hermes/Codex-config kan peke på gammel (død) boks-URL — verifiser ved repek.
