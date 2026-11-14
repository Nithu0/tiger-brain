# Backend ferdig i dag (14.11), frontend til Alper og Tintun etterpå

Nithu 14.11: «vi får igjennom all backend i dag så kjører gutta på med frontend når alt infra er klart».
Regel: backend = broen, API-et i plattform, vakter og målinger. Ingen ny UI utover det som trengs for å teste. Frontend gjør Alper og Tintun.
Gates: eierens trykk i plattformen er godkjenningen for handlingen. Ingen sletting, ingen env-endring fra appen, ingen hemmeligheter, ingen betaling. Code-review før merge.

| # | Leveranse | Eier | Ferdig når |
|---|---|---|---|
| B1 | Broen: redeploy/restart for Railway og Vercel på eierens trykk. Fast liste med tjenester, revisjonslogg, ingen sletting eller variabler | trading-1 | handling i kø → utført → logget, test på én ufarlig tjeneste |
| B2 | Railway- og Vercel-deploylogg for en feilet deploy, som API-endepunkt | data-1 | endepunktet gir de siste 200 linjene, sladdet |
| B3 | Azure-kost i snapshot (Cost Management, bare lesing) | data-1 | kost eller «ukjent» med årsak |
| B4 | Måling med `bare-godkjenning` | data-1 | ny andel for uke 46 i statusissuet |
| B5 | Statusfunnene ryddet, og alt infra er klart for frontend: preview-deploy per PR, miljøer, CI grønn | infra-1 | sc status er sann, sjekkliste for infra i drift |
| B6 | API-kontrakt for frontend: alle endepunkter i plattform (OpenAPI eller md), auth, eksempelsvar, lokalt oppsett på 5 min | tools-1 | `docs/API.md` i plattform + issue «Frontend: start her» til Alper og Tintun |
| B7 | c→b-sakene og merking med `bare-godkjenning` | learning-1 | andel a+b ≥ 79 % |
| B8 | Abonnementslisten og frist-oppgaver merket | admin-1 | issue klar-for-nithu |
| B9 | QA av B1–B6 ende til ende fra mobil og curl | paal-1 | funn til eier, 0 åpne blokkere |
B10 | DPS Brreg #136 klar til innlevering (admin-1)

## Status 2026-11-14T17:02:49Z (orchestrator-1)
B1–B10 er levert og merget. Det som gjenstår:
- B1: ett eier-trykk på /drift (renseri) for ende-til-ende.
- B5: branch protection når GitHub Team er kjøpt (kommando i drift#265).
- Alper og Tintun inn i Railway (Nithu).
Frontend: drift#265.
