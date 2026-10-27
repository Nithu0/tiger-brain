# GPU-verten til Nexus: hva den er, og hva som trengs (infra-1, 2026-10-27)

Read-only. Ingenting er leid, startet eller endret.

## Hva verten er (FACT, målt i dag)
- Nexus på Railway (prosjekt `empowering-wonder`) peker til **Vast.ai-instansen 46026731** (RTX 4090, standing-boksen fra 27.07):
  - **Worker** og **API** bruker `LOCAL_LLM_BASE_URL=http://81.166.173.12:11602`.
  - **Dashboard** bruker samme adresse, pluss `GPU_ANALYTICS_URL=http://81.166.173.12:11691`.
  - Modeller: `qwen3:8b` (rask) og `qwen3:30b-a3b-thinking-2507-q4_K_M` (dyp). `FIRM_LOCAL_AGENTS=daily-journal,operator-brief,fill-quality`.
  - Det er ikke en lokal node og ikke Tailscale. Det er en offentlig Vast-port med Caddy-token foran.
- **Instansen finnes ikke lenger.** `vastai show instances-v1`: `total_instances: 0`. Begge endepunktene (`81.166.173.12:11602` og den gamle `194.14.47.19:22631`) gir ingen tilkobling.
- **Kontoen:** kreditt $6,10, saldo 0.
- **Når den døde:** GPU-ROI-collectoren (`~/.local/state/gpu-roi-collect.log`) var siste gang `ok` **2026-08-23 23:01Z**. Etter det kom «Connection refused» på SSH-port 11647 frem til 30.08, da collector-timeren ble slått av. Verten har altså vært nede i **~2 måneder**.
- **Hvorfor:** `UNKNOWN`. ASSUMPTION: kreditten gikk tom, så instansen stoppet, og en stoppet instans med ubetalt lagring blir slettet av Vast. Det samme skjedde med auto-stoppen 21.–23.07.
- **Rettelse til diagnosen 27.10** (`diagnose-0-handler-14-dager.md`): verten Nexus peker på er `81.166.173.12`, ikke `194.14.47.19`. Den gamle boksen ble stoppet i juli.

## Konsekvens i Nexus
- `llm-router.service.ts` hopper over `local` når breakeren er åpen, og går videre til neste leverandør i prioritetslisten. GPU-en alene stopper derfor ikke noe. Hver halvåpne probe koster likevel en timeout (`LOCAL_LLM_TIMEOUT_MS`).
- I dag er også de eksterne leverandørene nede (diagnosen 27.10: temperature-feil hos Anthropic, 401 fra OpenAI og OpenRouter). Ingen fallback virker da, og GPU-en er bare én av flere feil.
- Dashboardets GPU-paneler (`GPU_ANALYTICS_URL`) og gpu-analytics-modulen (CUDA-xgboost, learning-1s PR #281) har ingen vert. Koden ligger på main, men det som var installert på boksen, er borte sammen med disken.

## Hva som trengs for å få den opp igjen

| Valg | Hva | Pris (Vast-søk i dag, verified, rel > 0,98, ≥ 60 GB disk) | Tid |
| --- | --- | --- | --- |
| **A. Ny standing 4090** | Lei en boks og bygg stacken som 27.07: supervisord, ollama og Caddy-token-gate. Pull de fire modellene (~25 GB). Deploy gpu-analytics på nytt. Sett ny URL og nytt token på Worker, API og Dashboard. | Billigst: **$0,375/t** (Polen) → **~$274/mnd** døgnet rundt. Ellers $0,39–0,46/t (US, TR, KR, CA), som er ~$285–335/mnd. Pluss lagring. Krever påfyll av kreditt, fordi $6,10 rekker ~16 t. | ~1 t for infra-1 etter påfyll |
| **B. Ikke lei nå** (anbefalt) | Fjern `LOCAL_LLM_BASE_URL` (og `GPU_ANALYTICS_URL`) på de tre tjenestene, eller sett `FIRM_LOCAL_AGENTS` tom. Da prøver ikke routeren `local` i det hele tatt: ingen breaker-sykling og ingen timeouts. De tre agentene som ikke handler, går på ekstern leverandør, når den virker. | $0 | 5 min, operatør på Railway |
| C. Leie per jobb | `vast-job.sh` (auto-destroy) for batch-trening og embedding, ikke døgnet rundt | ~$0,40/t bare mens jobben kjører | per jobb |

**Hvorfor B:**
- Boksen ble nesten ikke brukt da den levde. Dyp-analysen 13.07 målte 261 kall på 3 uker og 0 % utnyttelse, mot ~$289/mnd.
- Nexus har ikke handlet på 14 dager av andre grunner.
- Å leie nå betyr ~$274/mnd for et lag som ikke er flaskehalsen.
- Først må de eksterne leverandørene virke igjen (Anthropic-temperature, nøkler). Så kan operatøren avgjøre A eller C ut fra faktisk behov.

## Trenger beslutning (operatør, penger)
1. A, B eller C. Ved A: påfyll av Vast-kreditt og hvilken region (EU: Polen).
2. Ved B: hvem som fjerner variablene på Railway. Det er en prod-endring, så den er operatørgated.
3. `gpu-roi-collect.timer` er slått av og står igjen. Den kan fjernes ved B.
