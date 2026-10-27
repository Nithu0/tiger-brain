# Nexus: 0 handler på 14 dager — read-only diagnose (trading-1, 2026-10-27)

**Til:** operatøren og Karri. **Status:** RAPPORT. Ingenting er endret: ingen flagg, ingen strategi, ingen risiko, ingen deploy.
Kilder: nexus-watch 09:04Z, API (`/health`, `/operator/status`, `/operator/readiness`, `/decision-funnel`, `/jarvis/why-no-trade`, `/firm/signal-rejections`) og worker-logg (`railway logs`, de siste 400 linjene, ca. 09:00–09:10Z). Rådata ligger ved siden av denne fila.

## Kort
Firmaet går, men handler ikke. Worker, broker og database er friske (77 sykluser/t, readiness `READY`). Firmaet skriver selv «Day 14 flat — no trades, no positions». **Hele LLM-laget er nede**, alle fem leverandørene, av fem ulike grunner, og én av dem er en kodefeil. Om LLM-bruddet er årsaken til null signaler, er **ikke bevist**. Se hypotesene.

## Fakta (`FACT`)
| Hva | Verdi | Kilde |
| --- | --- | --- |
| Handler 30 d / 14 d / 3 d | 2 / 0 / 0 (`tradesOpened`) | `/decision-funnel?days=30/14/3` |
| Signaler foreslått 30 d | 2 (begge passerte alle gater) | `/decision-funnel?days=30` |
| Firmaets egen tese | «Day 14 flat — no trades, no positions, no narrative» (confidence 80) | `/operator/status` |
| Readiness | `READY`: «london active — execution allowed, no current candidate» | `/operator/readiness` |
| Tese-skår mot terskel | marketThesisScore **21** mot primaryMarketThesis **42** (cold-start, baseline 55) | `/operator/readiness` |
| Regime / managere | `MIXED_NO_EDGE`, bare `scalping` aktivert, NoTrade=3, Gate=PASS_TO_BLADE | readiness, worker-logg `[firm/portfolio-brain]` |
| Konto | 83 966,90 EUR (start 100 000), 0 åpne | `/operator/status` |
| Perf (alle) | n=191, WR 38,2 %, PF 0,92, expectancy −11,09 | nexus-watch |

**LLM-ruteren, hvert kall feiler** (`[llm-router]`, de siste 400 logglinjene):
| Leverandør | Feil | Type |
| --- | --- | --- |
| lokal GPU | `fetch failed`, breaker OPEN i 900 s | GPU-verten nede eller utilgjengelig (operatør) |
| Anthropic | `400 "temperature" is deprecated for this model` | **kodefeil:** `callAnthropic` (apps/worker/src/services/llm-router.service.ts:414) sender alltid `temperature: req.temperature ?? 0.7` til `claude-sonnet-5` |
| OpenAI | `401 Incorrect API key` | nøkkel ugyldig (operatør) |
| OpenRouter | `401 User not found` | konto eller nøkkel (operatør) |
| Gemini | `gemini failed: exit=1` (narrative, macro-event) | `UNKNOWN` |
Følge: `[llm-cache] background refresh failed for news-narrative / market-pulse-clusters: All LLM providers failed`.

**Signal-avvisninger, 7 d** (`/firm/signal-rejections`, 130 rader = 26 per strategi × 5 strategier, felles tidsstempler):
`session_not_allowed` 64 (ASIA_OBSERVE 40, WEEKEND 24), `indicator_unavailable` 16, `no_breakout_in_prior_candle` 13, `ATR ratio x < threshold 1.3` ~20 (0,47–1,21), resten noen få. **Alle radene er fra 00–03 UTC eller helg. Ingen rader i London/NY (07–20 UTC) på hverdager.**

## Hypoteser (`ASSUMPTION`, ikke bevist)
1. **Tese-skåren er lav fordi LLM-laget er nede.** Narrativ- og makroagentene feiler, så tesen får lite innhold (21 mot 42), og ingen strategi kommer gjennom tesebaren. Det står «no narrative» i firmaets egen tese. Test: rett én LLM-leverandør, og se om marketThesisScore stiger og om signaler dukker opp.
2. **Volatilitetsbaren er for høy for markedet nå.** «ATR ratio < 1.3» stopper breakout-strategiene selv når sessionen er tillatt. Det er et relativt mål, så det er ikke samme drift-klasse som de absolutte $-tersklene fra juni. Men det er en strategiterskel, så det er **Karris og operatørens domene**, ikke mitt.
3. **Avvisningsloggen er ikke komplett.** Bare 26 rader per strategi på 7 dager, med 77 sykluser/t, tyder på dedupe eller logging bare når grunnen endrer seg. At det mangler London-rader, betyr derfor ikke at strategiene ikke evalueres. Jeg har ikke sjekket det i koden.

## Observabilitet (feil i watch-sjekken, ikke i firmaet)
`nexus-watch` viser `funnel(3d) cycles=0`, men `/decision-funnel` teller `COUNT(DISTINCT decision_cycle_id) FROM gate_decisions`. Det er bare sykluser der et signal nådde gatene. «cycles=0» er altså misvisende ved siden av health «77 cyc/h». Forslag: kall det `gated_cycles`, og legg inn en ALARM ved 0 handler på ≥ 5 handelsdager. Watch er HEALTHY nå, selv etter 14 dager uten handel.

## Forslag (krever operatør eller OK, ingenting er gjort)
| # | Hva | Hvem | Type |
| --- | --- | --- | --- |
| 1 | Anthropic-kallet: send ikke `temperature` til modeller som avviser det (eller bare når den er satt eksplisitt) | trading-1 kan lage PR | bugfiks (gjenoppretter tiltenkt atferd), krever ikke forslag |
| 2 | OpenAI-nøkkel, OpenRouter-konto og GPU-vert (194.14.47.19) | operatør | infra |
| 3 | Gemini exit=1: les stderr | trading-1 | diagnose |
| 4 | Watch: `gated_cycles` og alarm ved 0 handler på N handelsdager | trading-1 | observabilitet |
| 5 | ATR-ratio 1.3 og tesebar 42 i dagens marked | **Karri og operatøren** | strategi (docs/strategy/proposals/) |
Rekkefølge: 1 og 2 først. Hvis LLM-laget virker igjen og det fortsatt ikke kommer signaler, er hypotese 1 avkreftet, og spørsmålet blir punkt 5.

## Oppdatering 2026-10-27 ~09:45Z (etter fiks)
- ai-assistent #325 (f8a3acd) er i drift: **Anthropic svarer igjen**. Loggen viser «anthropic call completed { model: 'claude-sonnet-5' }» for reasoning og sentiment, uten 400 og uten fallback.
- **Viktig for operatøren og Karri:** når LLM-laget virker igjen, kan firmaet gi signaler og handle i demo igjen (tiltenkt atferd). Kontoen er DEMO (OANDA fxpractice, NORMAL_DEMO).
- Fortsatt nede: narrativ- og makroagentene (gemini CLI exit=1), lokal GPU, OpenAI-nøkkel og OpenRouter-konto. Tese-skåren er 21 og tesen er ennå ikke laget på nytt. Det følges opp.
- Watch: ALARM ved 0 handler på 7 dager (report-only) er i drift (d792620).

## Gemini: årsaken funnet (~09:55Z)
- Narrativ, makrohendelse og research-drainer bruker Gemini SDK (`callGeminiSdk`, gemini-2.5-flash). Probe fra worker-containeren (nøkkel maskert):
  - `GET models/gemini-2.5-flash` gir **200**. Nøkkelen er gyldig og modellen finnes.
  - Ett minimalt `generateContent` (5 utdata-tokens) gir **402 RESOURCE_EXHAUSTED: «Your prepayment credits are depleted.»**
- **Tiltak (operatør):** fyll på forhåndsbetalt kreditt i Google AI Studio (prosjektet bak `GEMINI_API_KEY` på nexus-worker).
- Mest sannsynlig årsak til «no narrative» i tesen. Agent-bussen har dessuten 395 åpne oppgaver og 0 i arbeid (ikke undersøkt videre).

| Leverandør | Status 2026-10-27 | Hvem |
| --- | --- | --- |
| Anthropic (ruteren) | **OK** etter #325 | — |
| Gemini (agentene) | 402: kreditten er brukt opp | operatør |
| OpenAI | 401: ugyldig nøkkel | operatør |
| OpenRouter | 401: «User not found» | operatør |
| Lokal GPU | fetch failed, breaker open | operatør |

## Agent-bussen: 395 åpne, 0 i arbeid (read-only, ~10:00Z)
**Hvem skal plukke dem:** review-oppgaver (`role=review`, `model=claude-opus`) lages av `agent-trigger.ts` (`new_postmortem`, `gate_spike`). De skal **ikke** tas av worker. Worker-drainer (`research-drainer.ts`) tar bare `role=research` og sier selv: «Other roles (code/review/journal) still need a local Ralph loop». De skal plukkes av **lokale Ralph-loops i firm-speilet** (`docs/ref/local-firm-mirror.md`): `shield` (review/risk) og `atlas` (review/journaling), i zellij-paner på operatørens maskin.
**Hvorfor de ikke blir plukket:** ingen Ralph-loop kjører (`pgrep ralph` gir ingenting, 2026-10-27). Dette er **ikke** Gemini, LLM-kø eller lease. Ingen er claimet.

| Hva | Antall | Laget av |
| --- | --- | --- |
| review / journaling: «A new postmortem was written …» | 147 | new_postmortem |
| review / risk: gate min_rr | 104 | gate_spike |
| review / risk: gate mean_revert | 94 | gate_spike |
| review / risk: gate risk_level | 47 | gate_spike |
| review / risk: gate sl_cooldown | 2 | gate_spike |
| code / orchestrator | 1 | — |

**Alder:** eldste er 2026-05-11, nyeste er 2026-10-08. Per måned: mai 100, jun 99, jul 129, aug 54, sep 11, okt 2. Ingen nye siden 08.10, fordi uten handler kommer det ingen postmortems eller gate-spikes. Køen er **historisk**, ikke et nytt brudd.
**Konsekvens:** liten for handelen (review-oppgavene er rådgivende og endrer ingen beslutninger), men læringssløyfen fra postmortems har i praksis ikke kjørt siden mai.
**Forslag (ingenting er gjort, krever OK):**
(a) Operatøren avgjør om firm-speilet (zellij + Ralph) skal kjøre igjen, eller om review-rollen skal flyttes til en server-drainer (krever kode).
(b) Merk oppgaver eldre enn SLA som `expired`. Det er en DB-skriving, så den krever OK. Det er ikke sletting.
(c) Juster `publishOnce`, så samme gate ikke lager én oppgave i timen når ingen drainer kjører.

### Agent-bussen: utført etter beslutning fra orchestrator-1 (09:49Z)
- **(b) Gjort:** 247 gate_spike-oppgaver (review/risk, ikke claimet, over SLA, 14.05–08.09) er satt til `cancelled`, med én `agent_audit`-rad hver (`task_cancelled`, reason «expired: gate_spike review task past SLA, no review drainer»). **Ingenting er slettet.** Før: risk queued 247, journaling queued 147, code 1. Etter: risk cancelled 247, journaling queued 147, code 1. Skript: `scripts/oneshot/2026-10-27_cancel-stale-gate-spike-tasks.mjs` (dry-run, så --apply i én transaksjon). Status `cancelled` ble valgt fordi `AgentTaskStatus` ikke har `expired`. Kan reverseres via audit-radene.
- **(c) PR:** gate_spike publiserer ikke når ingen review-oppgave er claimet på 7 dager. Det logges som «damped» (report-only).
- **(a) Til operatøren og Karri:** skal review-rollen (postmortem-læring, 147 i kø) drives av firm-speilet (zellij + Ralph, `shield`/`atlas`, lokalt), eller av en server-drainer som research-drainer (krever kode og en Claude-nøkkel på worker)? Læringssløyfen fra postmortems har stått siden mai.

## Status ~10:50Z
Uendret: tese-skår 21, tesen er 4,5 t gammel, 0 handler. Anthropic virker i ruteren, men narrativ, makrohendelse og markedsresearch går via `routeGemini` (lokal GPU, så Gemini), **uten Anthropic-fallback**. Begge er nede. Det som låser opp: Gemini-kreditt eller GPU-verten (operatør). Alternativ i kode (forslag): Anthropic-fallback i routeGemini bak et flagg (default av), som flytter kostnaden til Anthropic.

## AGENT_ANTHROPIC_FALLBACK: kostnadsestimat (til operatøren, som flipper)
Flagget (default **av**) gjør at narrativ, makrohendelse, markedsresearch og research-drainer faller tilbake til Anthropic når lokal GPU **og** Gemini feiler.
Rate: standard cooldown er narrativ 30 min, makro 60 min og research 60 min, altså ~**4 kall/t**. Research-drainer har 0 research-oppgaver i kø. Tokens per kall er ikke målt i DB (agentkall meteres ikke i `llm_results`), så tallene er `ASSUMPTION`. «Høy» = 50 kB prompt-tak og 4 096 max_tokens.

| Modell | Scenario | per kall | per time | per døgn | per måned |
| --- | --- | --- | --- | --- | --- |
| claude-sonnet-5 ($3/$15 per M) | typisk 2k inn / 0,5k ut | 0,0135 $ | 0,054 $ | **1,30 $** | ~39 $ |
| claude-sonnet-5 | høy 12,5k / 4k | 0,099 $ | 0,40 $ | 9,50 $ | ~285 $ |
| claude-haiku-4-5 ($1/$5 per M) | typisk | 0,0045 $ | 0,018 $ | **0,43 $** | ~13 $ |
| claude-haiku-4-5 | høy | 0,033 $ | 0,13 $ | 3,17 $ | ~95 $ |

Anbefaling (`ASSUMPTION`): fyll på Gemini-kreditten først (dagens leverandør, billigst). Flip `AGENT_ANTHROPIC_FALLBACK=true` med `AGENT_ANTHROPIC_FALLBACK_MODEL=claude-haiku-4-5` som sikkerhetsnett, og mål faktiske tokens den første dagen. Når fallbacken virker, kan tese-skåren stige og demo-handler komme (tiltenkt). Kontoen er DEMO.
