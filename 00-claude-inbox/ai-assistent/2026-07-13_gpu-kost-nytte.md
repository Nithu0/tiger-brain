# GPU-LLM kost/nytte — live-analyse 2026-07-13

READ-ONLY analyse (prod-DB SELECT + kodelesing på `origin/main`). GPU: 194.14.47.19:22631, qwen3:8b (deep: qwen3:30b-a3b-thinking).

## Hovedfunn (les dette først)

1. **GPU-en er bekreftet LIVE på worker**: trade-review 2026-07-13 14:12 UTC kjørte på `qwen3:8b` (agent_events, trade-reviewer). Første harde beviset i DB.
2. **Den erstattet ikke Sonnet — den erstattet gpt-4o-mini.** Modell-historikk i agent_events: Sonnet frem til 14.06 → `gpt-4o-mini` 15.06–09.07 → `qwen3:8b` fra 13.07. Anthropic på worker var altså død/tom i ~4 uker og alt falt stille til OpenAI-fallback. Ingen så det, fordi ingenting logges til DB.
3. **Dagens faktisk erstattede volum er mikroskopisk**: ~2–4 LLM-kall/dag på worker-siden. De store volum-driverne (sentiment-narrative per cycle, market-pulse clustering, legacy sentiment-engine) er ALLE inaktive i prod akkurat nå.
4. **Kost-caset står ikke på dagens volum.** Verdien er (a) uavhengighet (bevist av juni-utfallet), (b) at man GRATIS kan reaktivere news-feltene (~$100/mnd Sonnet-ekv. hvis de skrus på), (c) fri command-room/jarvis-bruk uten regning, (d) privacy.

## Målt volum (prod-DB, siste 7 dager)

| Kilde | Måling |
|---|---|
| Firm-cycles (blackboard, DISTINCT decision_cycle_id) | ~690–710/handelsdag; helg ~30–50 |
| Lukkede trades (postmortems) | 10 på 14 dager ≈ 0,7/dag (2–6 på aktive dager) |
| trade-review (agent_events trade-reviewer) | 9/7d ≈ 1,3/dag |
| daily-journal artifact | ~1/handelsdag (22:06 UTC) |
| operator-brief artifact | 1/dag (06:00) |
| risk-advisor artifacts | 44/7d ≈ 6/dag |
| strategy-tuner | 1/dag |
| narrative (Gemini) | ~45/handelsdag (30-min) |
| market-research (Gemini) | ~21/dag |
| xauusd.analysis.news (sentiment-narrative + market-pulse) | **0 rader på 7 dager** — feltet er av |
| narrative_clusters (market-pulse LLM) | **0 rader på 7 dager** |
| bot_runs (legacy sentiment.engine) | **0 siden 22.04** — død |
| llm_results-tabellen | 1 rad (april) — død |

## Tabell per felt

Priser: Sonnet $3/$15 per MTok, Opus 4.7 $5/$25 per MTok (gjeldende liste — koden i `firm-agents/llm.ts` har utdatert $15/$75), gpt-4o-mini $0.15/$0.60. Kurs ~10,5 kr/USD.

| Felt | Kall/dag (målt) | maxTokens / est. input | Kost unngått/mnd (Sonnet/Opus-ekv.) | Kvalitet på qwen3:8b | Verdikt |
|---|---|---|---|---|---|
| trade-review (per lukket trade) | 1,3 | 200 / ~300 | ~$0.16 | OK — kort strukturert review, sample-output koherent. Mild nedgradering vs Sonnet, par med gpt-4o-mini | **Flytt (allerede flyttet, bevist)** |
| postmortem aiReview | 0,7 | 150 / ~350 | ~$0.07 | Samme klasse som over | **Flytt** |
| sentiment-narrative (analysis-agents:347, per cycle) | **0 nå** (potensial 690) | 200 / ~350 | $0 nå; **~$61/mnd hvis reaktivert** | Strengt lite JSON-skjema — 8b takler dette; 512-token-gulvet håndterer `<think>` | **Flytt — og GPU-en gjør reaktivering gratis** |
| market-pulse clustering (per 3.-5. cycle) | **0 nå** (potensial ~170) | 600 / ~500 | $0 nå; ~$39/mnd hvis aktiv | Grensetilfelle — nyansert multi-cluster-JSON; risiko for grunne/generiske clusters. Test før tillit | Flytt med forbehold |
| pre-open briefing (firm/briefing.ts) | ~0 (dedupes mot per-cycle synthesis + ORB_ONLY skip) | 350 | ~$0 | — | Irrelevant i praksis |
| sentiment.engine (legacy bot) | 0 (bots døde siden april) | 150 | $0 | — | Irrelevant |
| daily-journal (routeLLM, GPU-eligible) | ~1 | 4096 / ~2–3k | ~$0.9 (Opus-ekv.) | Faktuell oppsummering — OK, men merkbart svakere prosa enn Opus. Operator leser denne daglig | Flytt; vurder 30b-modellen (latens irrelevant, 1 kall/dag) |
| operator-brief (routeLLM, GPU-eligible) | 1 | 4096 / ~1–2k | ~$1.2 (Opus-ekv.) | Samme som journal | Samme |
| fill-quality (routeLLM, hver 4. time by design) | 0 observert (ingen artifacts 7d — trolig inaktiv) | ~1k | $0 nå (~$5/mnd hvis aktiv) | Tallbasert oppsummering — trygt | Flytt hvis aktivert |
| risk-advisor | 6 | ~2–3k in | — (går IKKE på GPU) | — | **Ikke flytt — og koden håndhever det**: bruker `callClaude` direkte, ikke `routeLLM`. FIRM_LOCAL_AGENTS kan ikke fange den. Riktig design (money-adjacent) |
| trade-critic / strategy-tuner | 0 / 1 | — | — | — | Samme — callClaude direkte, bevisst på Claude |
| narrative / market-research / macro-event | ~68 tot | — | ~$0.4/mnd (Gemini flash) | — | Ikke verdt å flytte — allerede nesten gratis |
| API routeChat (jarvis/command-room/hle/intelligence) | umålt (ad-hoc) | 800 default, hle mer | $5–100/mnd avhengig av bruk (Sonnet remote-default) | Referensielle svar OK på 8b. **hle deep-answer og dybdeanalyse er en reell nedgradering på 8b** — routeChat er local-FIRST ubetinget | Flytt korte svar; dybde bør rutes til 30b-thinking (~21s) eller beholde Sonnet |
| Dashboard Chief | ad-hoc | 2048/4000 | inkludert i punktet over | Allerede på GPU siden 25.06, fungerer | Ferdig flyttet |

## Totaler

- **Faktisk unngått i dag:** < $0.5/mnd Sonnet-ekvivalent på worker-mikrofeltene + ~$2/mnd Opus-ekvivalent på journal/brief (hvis de er i FIRM_LOCAL_AGENTS) + umålt API-chat. Realistisk spenn i dag: **$2–30/mnd (~20–320 kr)**. Og siden Anthropic-nøkkelen uansett var død i juni, var den reelle before-kosten gpt-4o-mini-pennies.
- **Potensial hvis news-feltene reaktiveres + aktiv command-room-bruk:** **~$100–160/mnd (~1000–1700 kr) Sonnet-ekvivalent.**

## Break-even (GPU = X kr/mnd, marginal-kost per kall = 0)

Sonnet-mikrokall (~350 in / 200 out) ≈ $0.004 ≈ 0,042 kr.

- Break-even = **X / 0,042 Sonnet-kall per måned** ≈ X × 24 kall/mnd per krone.
- X = 500 kr → ~12 000 kall/mnd (~550/handelsdag). X = 1000 kr → ~24 000. X = 2000 kr → ~48 000.
- Dagens erstattede volum: ~2–4 kall/dag → **kost-caset feiler med ~2 størrelsesordener på dagens drift**.
- MED sentiment-narrative reaktivert (690/dag ≈ 15 000/mnd) + market-pulse (~3 700/mnd) er man på break-even rundt X ≈ 650–800 kr/mnd — da bærer GPU-en seg selv i ren API-kost.

Ærlig konklusjon: GPU-en er i dag en **uavhengighets/kapasitets-investering**, ikke en sparepost. Den blir en sparepost først når volum-feltene skrus på — og den gjør det gratis å skru dem på.

## Kvalitet/latens/uavhengighet — ærlig

- **Latens:** qwen3:8b ~4s ≈ par med Sonnet (2–9s), litt tregere enn gpt-4o-mini (1–3s). Worker har 10s lokal-timeout + fallback, så cycle-loopen kan ikke henge på GPU-en.
- **Kvalitet ned:** 8b er svakere enn Sonnet på nyansert analyse. Feltene som er flyttet (strukturert JSON, korte reviews, faktuelle oppsummeringer) tåler det. Feltene som IKKE tåler det (hle deep-answer, dyp jarvis-analyse, market-pulse clustering) er delvis eksponert fordi API-routeChat er local-first ubetinget — dette er den reelle kvalitetsrisikoen i dag. Mitigering: rut deep-tasks til 30b-thinking eller la dem falle til Sonnet.
- **Uavhengighet (den store gevinsten):** juni-hendelsen beviser poenget — Anthropic på worker var død 15.06–09.07 uten at noen merket det. GPU-en fjerner både Anthropic-kreditt og OpenAI som single points of failure for disse feltene, og holder markeds/trade-data lokalt (privacy).
- **Fallback-kjeden er riktig bygget:** local → anthropic → openai → openrouter, med tom-output-vakt og gjenværende-tid-budsjett (7d5e8e3). Money-agents kan ikke havne på GPU.

## Målehull + minimal fix

`logLlm` (worker `logger.service.ts:89`) skriver kun til console — tokens/kost når aldri DB. Samtidig finnes en **død tabell som passer perfekt**: `llm_results (job_id, model, prompt, content, prompt_tokens, completion_tokens, meta jsonb, created_at)` — 1 rad siden april.

Minimal fix (observability, ingen atferdsendring — fritt frem per prinsipp 6):

1. **Worker `routeLlm`** (llm-router.service.ts, suksess-grenen ved logLlm-kallet): INSERT INTO llm_results med `model`, `prompt` = task-navn, `prompt_tokens`, `completion_tokens`, `meta = {provider, task, latency_ms, cost_usd_est}`. Kost-estimat fra en pristabell à la `estimateCostUsd` i firm-agents/llm.ts (som først må pris-korrigeres: Opus 4.7 er $5/$25, ikke $15/$75).
2. **Firm-agents `llm.ts`**: `LLMCallResult` har allerede `tokensIn/tokensOut/costUsd/modelUsed` — persister samme rad fra `routeLLM`-dispatcheren.
3. **API `routeChat`**: returner tokens fra provider-svaret (finnes i responsen, kastes i dag) og logg fra callerne (som har pg-pool).
4. Dashboard-metrikk: kall/dag + kost/dag gruppert på provider × task → da blir denne analysen en levende graf i stedet for et estimat, og neste "Anthropic er død"-hendelse synes samme dag.

Alternativ hvis man vil ha kolonner i stedet for meta-jsonb: `ALTER TABLE llm_results ADD COLUMN provider text, task text, latency_ms int, cost_usd numeric` — men meta-jsonb krever ingen migrasjon (migrasjoner er operator-gated).

## Verifikasjon av hva som faktisk går på GPU nå

| Spor | Status |
|---|---|
| trade-review → qwen3:8b | **BEKREFTET** (agent_events 2026-07-13 14:12 UTC) |
| daily-journal `model_used` i artifact-metadata | Skipper fra commit 7d5e8e3 (11.07); første provbare rad = i kveld 22:06 UTC hvis deployet OG daily-journal står i FIRM_LOCAL_AGENTS. Rader t.o.m. 10.07 mangler feltet |
| operator-brief / fill-quality | Skriver IKKE model_used — lite observability-hull |
| FIRM_LOCAL_AGENTS-verdien | Railway-env, ikke lesbar herfra — hvilke firm-agents som er GPU-listet er uverifisert |
| risk-advisor/trade-critic/strategy-tuner | Kan ikke gå på GPU uansett (callClaude direkte) — verifisert i kode |
| Chief (dashboard) | På GPU siden 25.06 per tidligere verifisering; ingen DB-spor (kun in-memory diag) |
| Modell-tidslinje worker | Sonnet → 14.06 · gpt-4o-mini 15.06–09.07 (Anthropic død/tom) · qwen3:8b fra 13.07 |

## Anbefalinger (prioritert)

1. **Fix målehullet** (llm_results-persist) — 1 times jobb, gjør alt annet målbart. Fritt frem (observability).
2. **Korriger pristabellen** i firm-agents/llm.ts ($5/$25 for Opus 4.7) — costUsd-estimatene den produserer er 3x for høye.
3. **Avklar hvorfor Anthropic var død på worker 15.06–09.07** (kreditt? nøkkel?) — hvis nøkkelen fortsatt er tom er Claude-fallbacken bak GPU-en fiktiv, og risk-advisor/strategy-tuner kjører i praksis på gpt-4o-mini, ikke Opus.
4. **Rut deep-tasks (hle deep-answer) til 30b-thinking eller Sonnet** — 8b-first på dybdeanalyse er dagens reelle kvalitetsnedgradering.
5. **Vurder å reaktivere sentiment-narrative** nå som marginal-kosten er 0 — det er den eneste endringen som flytter GPU-en fra "uavhengighetsforsikring" til "betaler seg selv". (Data-verdi-spørsmålet er Karri/operator-beslutning; kost-argumentet er borte.)
