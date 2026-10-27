# Pre-push code-review: feat/firm-v2-rollout (8375d31 + 574060c + 443666d)

_Fra orchestrator-1, 2026-08-14. High-effort review (8 finder-vinkler + adversariell verify) av de 3 upushede commitene: F3 GPU-ROI-collector, gpu-analytics-service, registry-docs. 10 funn under er verifisert (kjørt/reprodusert der mulig), 2 kandidater ble REFUTERT og droppet. Ingen blockere for verden, men flere av disse gjør at tallene/HELSE-signalene lyver stille — fiks før push anbefales for 1–5._

## Topp-funn (ranket)

1. **start.sh:5 (gpu-analytics) — token-uttrekk kan abortere scriptet stille ELLER trunkere tokenet til ett tegn; feilguarden er død kode.** Verifisert empirisk: under `set -euo pipefail` aborterer manglende Caddyfile/no-match linje 5 FØR «fant ikke token»-guarden kan kjøre. Verre: `grep -oE 'Bearer [a-f0-9]+'` matcher prefikset av et ikke-hex-token (f.eks. `aB3xYz9QQ==` → `a`), passerer `-n`-sjekken, og uvicorn starter med 1-tegns credential mens scriptet melder suksess — alt 401-er. Fiks: `grep -m1 -oE` med riktig charset + `|| true` + reell guard.

2. **gpu-roi-collect.sh:42 — exit-status fra SSH-en er `cat access.log`; midlertidig fraværende loggfil rapporteres som «boksen nede» (exit 3).** Frisk boks + nettopp rullet logg → collector feiler med feil rotårsak, og det finnes ikke lenger noe distinkt signal for ekte boks-nede. Guard filene med `[ -f ]` slik gpu-usage-report.sh:51 gjør.

3. **gpu-roi-report.sh:42 — read-only-connect kan ikke skape tabellen; krasjer med rå traceback til collectoren har kjørt minst én gang.** Fersk checkout har ingen db (gitignored), og kun collectoren skaper `gpu_requests`. Via morgenbrief degraderer det til «GPU-ROI: ?» — byte-identisk med boks-nede, stikk i strid med loud-failure-intensjonen.

4. **gpu-roi-collect.sh:19 — `GPU_SSH_HOST/PORT` kolliderer med gpu-usage-report.sh sine identiske var-navn men MOTSTRIDENDE defaults** (root@81.166.173.12:11647 vs root@ssh7.vast.ai:12247) — runbooken ber operatøren eksportere akkurat disse ved re-lease, så å konfigurere den ene repointer den andre feil. I tillegg mangler ssh-kallet `StrictHostKeyChecking=accept-new` som ALLE søsterscriptene har → ny host-key ved re-lease hardfeiler hver time, ser ut som boks-nede.

5. **gpu-roi-report.sh:26 — `command -v vastai` feiler ALLTID i cron-miljøet som kjører morgenbriefen** (cron-PATH mangler ~/.local/bin) → live-pris-grenen kjører aldri; hardkodet $0.364/t brukes alltid, og `--oneline` skjuler hvilken rate som ble brukt. Boks re-leid til $0.80/t rapporterer halv kost og kan flippe warn-flagget til «ok» usynlig.

6. **start.sh:15 — suksess-sjekken `pgrep -f 'uvicorn app:app'` matcher den GAMLE uvicorn-en som overlever SIGTERM** → mislykket restart melder «oppe på :1111», exit 0, gammel kode fortsetter å serve. Fang ny PID og sjekk den.

7. **app.py:123 — `async def run_module` gjør blocking arbeid rett på event-loopen (1 worker)** → én CUDA-fit/plot fryser /health og alt annet så lenge den kjører (overvåkning leser boksen som død akkurat når den er travel). `async def run` i en modul returnerer dessuten en uawaited coroutine → 500. Wrap i `run_in_threadpool` eller gjør handleren sync.

8. **app.py:79 — /train/bench uten bounds på rows/cols/rounds** → én request (rows=50M) ber om ~10 GB → OOM-kill av hele tjenesten. Sett Query-grenser.

9. **gpu-roi-collect.sh:38 — rotert-logg-globben `$ACCESS_LOG.*` kan aldri matche lumberjack-navngivingen** (`caddy-ollama-access-<timestamp>.log[.gz]` — timestamp FØR extension) → rotasjonshåndteringen er dokumentert men død; bursts >10 MB mellom kjøringer tapes stille.

10. **app.py:136 — per-request `exec_module` gjenoppbygger modulen hver gang** → «tunge modeller kan caches i modulen selv»-kontrakten i GPU-LIVE-ANALYTICS.md:55 kan ikke holde (2 GB modell re-lastes per request, paneler stabler kopier til CUDA-OOM). Cache på (name, mtime_ns).

## Øvrige verifiserte (under topp-10)
- Tre divergerende rate-konstanter for samme boks: 0.364 / 0.401 / 0.40 (GPU_DPH / GPU_HOURLY_RATE / VAST_USD_PER_HR) — ~10 % sprik i tall som skal sammenlignes.
- `warn` undertrykkes til `[ok]` når `gpu_requests` er tom; GPU-timer antar ubrutt 24/7-billing fra global MIN(ts); `float()` over nvidia-smi uten guard (`[N/A]`/multi-GPU → 500); pyplot global state fra threadpool + figur-lekkasje ved savefig-feil; systemd-unit mangler `EnvironmentFile`/PATH som søster-units setter; SkyPilot-registry-raden mistet operatør-gate-forbeholdet.

## Refutert (ikke reelle)
- Ollama-port 11433 i app.py er korrekt (uautentisert upstream bak caddy, samme som watchdog.sh).
- `0.0.0.0`-bind bryter ikke ADR-001 loopback-grensen (Vast port-mapping krever det; bearer-auth håndheves).
