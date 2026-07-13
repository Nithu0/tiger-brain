# Verify-gap DELTA — re-probe vs DASHBOARD-AUDIT-REPORT.md

Dato: 2026-06-23
Av: code-1 (uavhengig PROD-sjekk, READ-ONLY)
Base: https://dashboard-production-f342.up.railway.app
Metode: curl/contract + chunk-grep + EN Playwright-hydreringssjekk (R1 er kjernen i tillitsbuggen, så jeg bekreftet hydrering selv — code-2 kjører den brede browser-verifiseringen parallelt).

## Konklusjon først

ai-2 har **lukket de to viktigste tillitsfunnene** siden forrige audit: R1/G1 (home wiret til live brief) og G2 (`api.jarvisAsk` wiret). Det som fortsatt står åpent er kosmetisk/kjent: R5 (3 døde ruter — fortsatt 404, ikke aliaset) og R3 (#418 hydreringsfeil — fortsatt der, kjent ikke-fatal).

## DELTA-tabell

| ID | Forrige funn | Nåværende status | Status |
|----|--------------|------------------|--------|
| **R1** | Home viser statisk "WATCH" mens live = -$554 / 100 % daglig tap (tillitsbug) | Etter hydrering viser home `-$554.27`, "1 trade today, P/L $-554", "100 % of daily loss limit used", "Daily loss limit hit — trading paused". SSR-HTML har fortsatt "WATCH mode / Market read pending" som pre-hydrerings-fallback med "derived"-badge, men klienten henter live. | **CLOSED** |
| **G1** | Wire briefing til live `/jarvis/brief` | Home-kortets chunk (`3cmq33_jr336z.js`) kaller `jarvisBrief()` → `s("/jarvis/brief")`. Live-tall rendres etter hydrering. | **CLOSED** |
| **G2** | Wire `api.jarvisAsk()` | `jarvisAsk:e=>s("/jarvis/ask",{method:"POST",body:JSON.stringify({text:e})})` definert (chunk `2xbs7w7tngvpw.js`) OG konsumert: `await t.api.jarvisAsk(e)` (chunk `01y5h5mvqenuy.js`). | **CLOSED** |
| **R5** | 3 døde 404: /cockpit, /correlation, /signals-live | Alle tre fortsatt **404**. Ikke aliaset, ikke redirigert. (Til sammenlikning: /risk, /strategies, /signals, /positions, /command-room = 200.) | **STILL OPEN** |
| **R3** | #418 hydreringsfeil (ai-2 kvitterte: kjent ikke-fatal) | Minified React error **#418** fortsatt i konsollen ved last av home (chunk `2h0dkzyy0vocp.js`). Siden hydrerer ferdig og viser live-data — ikke-fatal, men ikke fjernet. Sannsynlig årsak: nettopp SSR "WATCH" → klient live-brief mismatch. Også favicon.ico 404 (kosmetisk). | **STILL OPEN (kjent, ikke-fatal)** |
| **G4** | Duplikat rute-par begge 200 | Fant ingen aktive duplikat-par i probe-settet. Single-canon-ruter svarer 200 (/, /risk, /strategies, /signals, /positions, /command-room); vanlige aliaser (/home, /briefing, /boardroom, /strategy, /trades, /chat, /jarvis, /ask) = 404. Ingen tegn til at samme side serveres på to paths. | **CLOSED / ikke reproduserbar** |

## Nye ai-2-leveranser — PROD-kontraktsjekk

| Leveranse | PROD-status |
|-----------|-------------|
| **#181 3D-orb** | /command-room = 200 (orb lever på den siden; ikke browser-rendret her — code-2 verifiserer WebGL-canvas). |
| **#182 /command-room** | Ruten **200** i PROD (var ny). AI-boardroom/voice-first/2.5D — render-verifisering hos code-2. |
| **#183 /api/chief** | POST `/api/chief` = **200**. Uten ANTHROPIC_API_KEY faller den grasiøst tilbake: `{"ok":false,"source":"fallback","decision":null,"error":"empty text"}` (tom payload gir "empty text"; graceful-fallback-kontrakten holder). GET = 405 (POST-only, korrekt). |

## Live-brief referansetall (for sporbarhet)

`/api/proxy/jarvis/brief` per 2026-06-23T11:33Z:
- `isMock:false`, `source:"deterministic"`
- headline: "1 trade today, P/L $-554"
- realizedTodayUSD: **-554.27**, tradesToday: 1
- dailyLossPctOfLimit: **100**, openRiskEvents: 2
- regime: unknown, lastSignal: long @ 60

Home (etter hydrering) matcher dette 1:1 → R1 verifisert lukket mot kilden.

## Topp-gap: lukket vs åpent

**Lukket nå (de viktige):**
- R1/G1 — home wiret til live brief (tillitsbuggen er borte etter hydrering)
- G2 — `jarvisAsk` wiret ende-til-ende
- G4 — ingen reproduserbare duplikat-rutepar

**Fortsatt åpent (lav prioritet / kosmetisk):**
- R5 — /cockpit, /correlation, /signals-live er fortsatt harde 404 (3 døde lenker). Eneste reelle gjenstående funksjonsgap.
- R3 — #418 hydreringsfeil + favicon 404 i konsoll; ikke-fatal, men ikke ryddet. Sannsynlig direkte konsekvens av SSR-WATCH→live-hydrering-mismatchen.

## Anbefaling til ai-2 (ikke handlet — deres lane)
1. R5: enten implementer /cockpit, /correlation, /signals-live, eller fjern/aliasér lenkene (3 døde 404 er det eneste brukervendte gapet igjen).
2. R3: SSR-fallbacken bør matche klient-initialtilstand (f.eks. render "loading" i stedet for hardkodet "WATCH mode") for å fjerne #418. Lav prioritet.
