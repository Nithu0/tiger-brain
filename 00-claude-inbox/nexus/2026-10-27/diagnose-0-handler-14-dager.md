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
