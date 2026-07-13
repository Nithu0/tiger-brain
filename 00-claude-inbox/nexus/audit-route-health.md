# SSR-health re-sweep — live dashboard rute-audit (2026-06-23)

> READ-ONLY sweep av prod-dashboardet. curl/SSR-grunnet (ingen browser, ingen kodeendring — nexus/ai-assistent er ai-2s lane). Bygger på code-2s tidligere browser-verify av home+ask (ren hydration, ask→200+tts→200, health-pill RED = worker-heartbeat 5m stale). Base: `https://dashboard-production-f342.up.railway.app`.

## Sammendrag

- **46 ruter probet. 43 returnerer HTTP 200, 3 returnerer ekte 404.**
- **Null ekte Next.js-feilmarkører på noen rute** — ingen `__next_error__`, `nextjs-portal`, `"digest":"<n>"`, minified React #185/#310/#31/#161, eller `Application error`. SSR-passet er rent på alle 200-ruter.
- **3 ekte 404 (ruter finnes ikke i bygget):** `/cockpit`, `/correlation`, `/signals-live`. Alle tre er byte-identiske (41419 B), `<title>404: This page could not be found.</title>`, og inneholder `This page could not be found` 6 ganger (vs. 2 på ekte sider). Disse er navn fra brief-/audit-tekst som IKKE er live-ruter — sannsynlig forveksling i tidligere notater, ikke en regresjon.
- **Ingen 500, ingen tom-krasj, ingen render-error** på noen 200-rute.
- **Falske positiver bekreftet (per briefens tidligere note):** `This page could not be found` ligger i shellen/RSC-payloaden på ALLE sider (notFound-branch), ikke en rendret feil. Skillet er vanntett: ekte side = strengen 2x + ekte `<title>`; ekte 404 = strengen 6x + 404-`<title>`. `green-500` o.l. Tailwind-klasser er ikke feil.

## Jarvis-backend proxy (alle 200, ekte payload)

| Endpoint | Metode | HTTP | Bytes | Innhold |
|---|---|---|---|---|
| `/api/proxy/jarvis/brief` | GET | 200 | 959 | ekte JarvisBriefing: `isMock, asOf, headline, summary, spoken, bullets, suggestedActions, evidence` |
| `/api/proxy/jarvis/why-no-trade` | GET | 200 | 3811 | DecisionThread-shape, fullt utfylt |
| `/api/proxy/jarvis/ask` (`{"text":"why no trade"}`) | POST | 200 | 336 | `{action: SHOW_EVIDENCE, answer:"We did trade — 1 trade today for $-554.", evidence:[...], source:"deterministic"}` |

Merk: `ask`-svaret er `source:"deterministic"` (lokal/regel-basert grounding, ikke LLM) — konsistent med at `api.jarvisAsk()` swap-punktet ennå peker på deterministisk path. brief rapporterer 1 trade i dag, PnL −$554 (live-data flyter gjennom).

## Per-rute statustabell

TEXTLEN = synlig HTML-tekst etter at `<script>`/`<style>`/tags er strippet. Lav TEXTLEN betyr lite SSR-rendret tekst (klient-fetch etter hydration), IKKE nødvendigvis tom side — hele RSC-payloaden (39–75 KB) er til stede på alle 200-ruter. "THIN" = first-paint er nesten tom og fylles klient-side.

| Rute | HTTP | Bytes | TEXTLEN | Vurdering |
|---|---|---|---|---|
| `/` | 200 | 55479 | 1064 | medium SSR (Mission Control) |
| `/talk` | 200 | 49600 | 991 | THIN — orb-cockpit, klient-fetch |
| `/analytics` | 200 | 39724 | 460 | THIN — klient-fetch shell |
| `/live-reasoning` | 200 | 74771 | 2424 | rik SSR (mest innholdsrike rute) |
| `/system` | 200 | 57910 | 1878 | medium SSR (settings) |
| `/positions` | 200 | 39675 | 477 | THIN — klient-fetch shell |
| `/backtest` | 200 | 43115 | 514 | THIN |
| `/bots` | 200 | 41643 | 512 | THIN |
| `/broker` | 200 | 39483 | 472 | THIN |
| `/calibration` | 200 | 44577 | 580 | THIN |
| `/console` | 200 | 47534 | 780 | THIN |
| `/eod` | 200 | 39169 | 480 | THIN |
| `/explorer` | 200 | 43341 | 800 | THIN |
| `/firm-agents` | 200 | 41892 | 511 | THIN |
| `/fusion` | 200 | 44195 | 579 | THIN |
| `/hour-stats` | 200 | 47404 | 697 | THIN |
| `/journal` | 200 | 47279 | 824 | THIN |
| `/managers` | 200 | 44201 | 581 | THIN |
| `/memory` | 200 | 44328 | 556 | THIN |
| `/memory-trend` | 200 | 49162 | 1032 | medium SSR |
| `/morning` | 200 | 48434 | 901 | THIN |
| `/notifications` | 200 | 46271 | 580 | THIN |
| `/providers` | 200 | 44237 | 553 | THIN |
| `/pulse` | 200 | 43455 | 525 | THIN |
| `/readiness` | 200 | 39498 | 471 | THIN |
| `/registry` | 200 | 42047 | 626 | THIN |
| `/reviews` | 200 | 45690 | 723 | THIN |
| `/risk` | 200 | 43090 | 854 | THIN |
| `/signals` | 200 | 50171 | 1632 | medium SSR |
| `/strategies` | 200 | 44446 | 565 | THIN |
| `/strategies-live` | 200 | 59966 | 2463 | rik SSR |
| `/team` | 200 | 46069 | 621 | THIN |
| `/threads` | 200 | 41982 | 646 | THIN |
| `/validation` | 200 | 55639 | 2247 | medium SSR |
| `/weaknesses` | 200 | 47286 | 692 | THIN |
| `/audit` | 200 | 47999 | 700 | THIN |
| `/jobs` | 200 | 46431 | 612 | THIN |
| `/cockpit` | **404** | 41419 | — | **EKTE 404 — finnes ikke** |
| `/firm-timeline` | 200 | 45109 | 759 | THIN |
| `/replay` | 200 | 39184 | 479 | THIN |
| `/map` | 200 | 43209 | 540 | THIN |
| `/integrations` | 200 | 39193 | 475 | THIN |
| `/workflows` | 200 | 41396 | 550 | THIN |
| `/correlation` | **404** | 41419 | — | **EKTE 404 — finnes ikke** |
| `/signals-live` | **404** | 41419 | — | **EKTE 404 — finnes ikke** |
| `/agents` | 200 | 45926 | 921 | THIN |

## Broken / tom — flagget

**Ekte 404 (3):**
- `/cockpit` — IA-mismatch-notatet i tidligere audit listet `/cockpit` blant landingsside-kandidater; ruten eksisterer ikke i live-bygget. ai-2: enten alias til `/` eller fjern referansen.
- `/correlation` — nevnt i UX-pattern-noten som long-tail-rute; ikke live.
- `/signals-live` — sannsynlig forveksling med `/strategies-live` + `/signals` (begge live 200); `/signals-live` finnes ikke.

**THIN first-paint (klient-fetch, ikke ødelagt, men tom på first paint):**
De fleste 200-ruter (~32 av 43) SSR-rendrer <1000 tegn synlig tekst og fyller innhold etter hydration. Bekrefter briefens punkt: `/analytics` og `/positions` er de tynneste (460/477 tegn). Funksjonelt OK, men first paint føles død — kandidat for SSR/streaming + skeletons i redesign. De mest innholdsrike SSR-rutene (best baseline) er `/live-reasoning` (74 KB / 2424 tegn), `/strategies-live`, `/validation`, `/signals`.

**Ingen 500, ingen render-error, ingen krasj-markører på noen rute.**

## Forbehold

- curl/SSR-grunnet. Hydration-tids-konsoll-feil og klient-side-only widgets vises IKKE i SSR-HTML — kun ekte browser bekrefter de. code-2 har allerede browser-verifisert home+ask som rene; resten av THIN-rutene er ikke browser-verifisert i denne sweepen.
- TEXTLEN er en grov proxy for first-paint-tetthet, ikke for total funksjonalitet. RSC-payloaden er full på alle 200-ruter.
- Rutesettet (46) er bygget fra alle rutenavn nevnt på tvers av brief + tidligere audit. Hvis bygget har flere ruter som verken sidebar-SSR eller brief navnga, kan de mangle her — men de 3 ekte 404-ene bekrefter at probe-settet treffer ekte rutegrenser.
