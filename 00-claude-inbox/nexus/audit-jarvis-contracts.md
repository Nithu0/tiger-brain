# Audit: LIVE /jarvis backend-contracter vs redesign-brief

> READ-ONLY live-verifisering (curl mot prod). Ingen kode endret, ingen git, ingen secrets.
> Base: `https://dashboard-production-f342.up.railway.app/api/proxy/jarvis/*`
> Kjørt 2026-06-23 ~03:04Z av code-1. Bygger på code-2s browser-verify (home+ask clean, tts 200, health-pill RED = worker-heartbeat 5m stale).

## TL;DR
**Alle endepunkter og alle 6 intents PASSER.** HTTP 200 over hele linja, `isMock:false` overalt, hver intent grunnet i ekte firm-state. Ingen UNKNOWN på reelle intents, ingen tomme svar, ingen manglende kontraktsfelt. `source` = `deterministic` på alt — IKKE LLM, IKKE mock. Brief-shapen avviker noe fra det dokumenterte i brief'en (additive felt + nested evidence), men det er supersett, ikke mangel. Én semantisk bug verdt å flagge til ai-2 (se §Gaps).

---

## POST /jarvis/ask — per-intent

Dokumentert kontrakt (brief): `{action: JarvisAction, answer, evidence?, asOf, source}`. `evidence` er optional per `?`.

| Intent | HTTP | action.type | source | evidence | answer grunnet? | Verdict |
|---|---|---|---|---|---|---|
| "why no trade" | 200 | SHOW_EVIDENCE (topic no-trade) | deterministic | ja (2 refs) | GROUNDED | **PASS** |
| "best strategy" | 200 | NAVIGATE /strategies | deterministic | ja (1 ref) | GROUNDED | **PASS** |
| "show positions" | 200 | NAVIGATE /positions | deterministic | utelatt (optional) | GROUNDED | **PASS** |
| "show risk" | 200 | OPEN_DRAWER risk | deterministic | ja (risk-snapshot) | GROUNDED | **PASS** |
| "market pulse" | 200 | OPEN_DRAWER market-pulse | deterministic | utelatt (optional) | GROUNDED | **PASS** |
| "briefing" | 200 | RUN_BRIEFING | deterministic | ja (/jarvis/brief) | GROUNDED | **PASS** |

`/ask`-responsen har ikke et top-level `isMock`-felt (kontrakten krever det ikke); `source:"deterministic"` er ekvivalent grunn-stempelet, og `/brief` + `/why-no-trade` har eksplisitt `isMock:false`.

Kontrakt-match: alle 4 påkrevde felt (`action`, `answer`, `asOf`, `source`) til stede på ALLE svar. `evidence` dukker opp når relevant og utelates ellers — korrekt optional-oppførsel per spec. `action` er alltid en typet `JarvisAction` (SHOW_EVIDENCE / NAVIGATE / OPEN_DRAWER / RUN_BRIEFING), ingen UNKNOWN.

### Edge-cases (robusthet, ikke i oppdraget men verdt å vite)
- Gibberish ("zxqwer foobar…") → 200, `action.type: UNKNOWN`, hjelpsom fallback-answer. Korrekt — UNKNOWN er forbeholdt ekte uklare requests, ingen av de 6 reelle intents traff den.
- Tom body `{}` → 200, UNKNOWN med "I didn't get a question." Graceful.
- "show gold chart" (orb-chip) → 200, NAVIGATE `/charts` ("Live Charts"). PASS.

---

## GET /jarvis/brief

HTTP **200**, `isMock:false`, `source:"deterministic"` (i nested evidence).

Dokumentert kontrakt (brief): `{headline, summary, spoken, bullets, evidence, activeGate}`.

| Felt (spec) | Til stede? | Verdi (live) |
|---|---|---|
| headline | JA | "1 trade today, P/L $-554" |
| summary | JA | "Gold is in an unclear regime. 1 trade closed for $-554. Daily loss limit 100% used." |
| spoken | JA (TTS-klar) | "1 trade today for $-554, gold in an unclear regime…" |
| bullets | JA (5 stk) | regime / trades / risk / top-strategy / gate-blocks |
| evidence | JA (rikt objekt) | regime, lastSignal*, tradesToday, realizedTodayUSD -554.27, dailyLossPctOfLimit 100, openRiskEvents 1, topStrategy, noTradeReason, activeGate, source |
| activeGate | JA — **nested under `evidence`**, ikke top-level | `{name:null, rejects24h:0}` |

**Avvik mot spec (ufarlig):** `activeGate` ligger inne i `evidence` (ikke top-level slik brief'en lister det), og responsen har additive felt brief'en ikke nevner: `isMock`, `asOf`, `suggestedActions[]`. Dette er et SUPERSETT av kontrakten — alle dokumenterte felt finnes, pluss mer. ai-2 må bare lese `activeGate` via `evidence.activeGate`. Verdict: **PASS** (flagg path-detaljen til ai-2).

---

## GET /jarvis/why-no-trade

HTTP **200**, `available:true`, alle cycles `isMock:false`.

Dokumentert som "DecisionThread-shape". Faktisk: en wrapper `{days, limit, available, asOf, noTradeCycles[], biasSummary, totals}` der hvert element i `noTradeCycles` er en full decision-thread (`id`, `cycleId`, `at`, `outcome`, `headline`, `steps[]`, `blockingGates[]`, `conflictNotes[]`, `bias`).

- 5 no-trade-cycles returnert, 7 traded-cycles ekskludert, 204 gate-rows totalt — alt ekte firm-historikk (18.-22. juni).
- Blokkerende gates er reelle: `regime_direction_gate` (counter-trend), `mean_revert`. Bias-skew: long 4 / short 1.
- Verdict: **PASS**. Rikere enn en flat DecisionThread (det er en liste av dem + aggregater), men matcher intensjonen og er fullt grunnet.

---

## Gaps / flagg til ai-2

1. **Semantisk bug i "why no trade"-svaret (LOW, men synlig for bruker).** `/ask` på "why no trade" returnerer `answer: "We did trade — 1 trade today for $-554."` mens `action.type` er `SHOW_EVIDENCE topic:no-trade` med evidence som peker på `regime_direction_gate`. Svaret motsier handlingen: brukeren spør hvorfor ingen trade, får "vi tradet faktisk". Logikken kommer av at det ER 1 trade i dag, men `/jarvis/why-no-trade` har 5 reelle no-trade-cycles å snakke om. Den deterministiske answer-grenen burde, når det finnes no-trade-cycles, forklare gate-blokkene heller enn å avvise premisset. Ikke et kontraktsbrudd (200, typet action, grunnet), men en UX-inkonsistens ai-2 bør se på når de wirer `api.jarvisAsk()`.
2. **`activeGate` path:** ligger under `brief.evidence.activeGate`, ikke top-level. Brief-dokumentet lister det top-level. Konsumer riktig.
3. **`source` er `deterministic` overalt** — bekrefter at LLM-seam (`LOCAL_LLM_BASE_URL` / code-1 GPU) ennå ikke er koblet på. Som forventet; ingen action.

## Grounded vs degraded
- **GROUNDED (ekte firm-state):** alle 6 intents + brief + why-no-trade. Tall stemmer på tvers (1 trade, -$554, 100% daily-loss, regime unknown, top-strategy auto-managed går igjen i ask/brief/evidence).
- **DEGRADED:** ingen. Null mock, null tomme svar, null UNKNOWN på reelle intents.

## Caveat
Health-pill er RED fordi worker-heartbeat er 5m stale (code-2s funn) — dvs. dataene er ekte men ferskheten på live-cycle er stale. `asOf`-stemplene på /ask og /brief er sanntid (03:04Z), men `why-no-trade` sin nyeste cycle er 2026-06-22 (ingen nye no-trade-cycles siste døgn), konsistent med en pauset/stale worker. Kontraktene er sunne uavhengig av worker-liveness.
