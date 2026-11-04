# Knutepunkt: én plattform over GitHub, GWS, Azure, Railway og Vercel

Oppdrag fra operatøren 04.11 kl. 21:57. **Frist: ferdig, verifisert og rapportert innen 05.11 kl. 08:00 CET.** Operatøren spør etter sluttrapport da.

## Mål

Én plass med full oversikt og styring over alle kontoene våre, bygget på CLI-ene som allerede er innlogget på denne maskinen (`gh`, `gws`, `az`, `railway`, `vercel`).

Tre flater:
1. **Cockpit-fanen «Plattform»** (:3200), bygget videre på «Hoved».
2. **CLI-en `sc`**, til terminal, agenter og Claude-mobil: `sc status`, `sc kost`, `sc deploy-status`, `sc logg <tjeneste>`, `sc tilgang`.
3. **Statusissue i drift**, oppdatert hver time, så hele teamet ser det fra mobil uten VPN.

## Arkitektur (bestemt, ikke diskuter)

- Ny pakke `packages/platform` i `Nithu0/command-center`.
- Én adapter per tjeneste bak samme grensesnitt: `status()`, `kost()`, `ressurser()`, `hendelser(siden)`. Adaptere kaller CLI-en som underprosess, med timeout, cache og tydelig `ukjent`/`feil`. Ukjent vises aldri som grønt.
- API-rute `/api/platform` leser pakken. `sc` og statusissuet bruker samme pakke, så det finnes én sannhet.
- Skriveoperasjoner går gjennom den eksisterende godkjenningsgaten i cockpit. I første omgang: bare lesing, pluss handlinger som allerede finnes.

## Fordeling

| Pane | Lane | Leveranse |
|---|---|---|
| tools-1 | Kjerne + cockpit | `packages/platform` (grensesnitt, cache, feilmodell), `/api/platform`, fanen «Plattform» (390 px OK). Eier integrasjonen. **Lag grensesnittet først, innen 30 min, og meld det til de andre.** |
| data-1 | Azure + Railway | Adaptere. Azure: ressurser, kost mot budsjett, varsler. Railway: tjenester, deploy-status, bruk/kost for anbud, solarlabs, aslisten, nexus. |
| trading-1 | GitHub + Vercel | Adaptere. GitHub: org og repoer, åpne PR-er, CI-status, Actions-minutter, kvoter (bare REST). Vercel: prosjekter, deploy-status, domener, regioner. |
| admin-1 | GWS + `sc` | GWS-adapter: brukere, 2FA-status, delte disker, lagring, kalender for teamet. Bare metadata. CLI-en `sc`, skill `/plattform` (virker på mobil), statusissue i drift via timer. |
| learning-1 | Azure-infra | Testutrulling (se under), OIDC GitHub→Azure og `what-if` i CI for Terra, region-policy, budsjett. |
| paal-1 | Uavhengig QA | Fra kl. 05:00: test alt ende til ende som en bruker, prøv å ødelegge, sjekk at ingen hemmeligheter vises. Fiks funn eller meld dem til eier. |

## Arbeidsform

- **90 % ren produksjon.** Kort plan, så bygg. Ingen nye rapporter eller utredninger utenom det som trengs for å bygge.
- Lag en todo-liste, og spawn subagenter med `isolation: worktree` for uavhengige deler. **Maks 3 samtidige subagenter per pane** (11 GB RAM deles av alle).
- Jobb i egen worktree. Delte checkouter (`~/code/command-center`, `~/code/drift`) skal stå på `main`.
- Små PR-er, merge selv når CI er grønn. Ikke vent på review. Spar med hverandre i innboksene, ikke via orchestrator-1.
- STATUS til orchestrator-1 bare ved merget leveranse eller blokkering. Ved blokkering: gå videre med noe annet og meld.
- Etter merge i command-center: `git pull` i delt checkout og restart `cc-api` (og `cc-web` ved frontendendring).
- Bruk REST mot GitHub, ikke GraphQL-løkker.

## Absolutte grenser

Operatøren har gitt go på tempo, ikke på dette:

- **Ingen hemmeligheter** i kode, logg, API-svar, feed eller issues. Adaptere leser aldri variabelverdier, bare navn.
- **GWS: bare metadata.** Ingen lesing av e-postinnhold eller dokumentinnhold. Ingen sending av e-post eller meldinger til noen.
- **Ikke rør produksjon utover lesing:** ingen endring av env, deploy, migrering, DNS eller sletting på anbud, solarlabs, aslisten eller Vercel-prosjektene. Unntaket er `rg-terra-test` (se under).
- **Ingen sletting** av brukere, repoer, grener, data eller ressurser utenfor `rg-terra-test`. Ingen force push.
- **Tintun:** ikke overskriv arbeidet hans. Ikke push på grenene hans, ikke lukk PR-ene hans, kjør `bin/tintun-sjekk` først. Review fra ham er ikke nødvendig for å merge eget arbeid. Regelen om `hold`-label i Terra er opphevet for denne natten, men PR-er som rører hans åpne filer venter eller rebases rent. Logg i drift#198.
- Nexus er på is.

## Azure og budsjett (learning-1)

- Testutrulling av `infra/main.bicep` til `rg-terra-test` er godkjent av operatøren, kun der. Passord genereres per kjøring og lagres bare i Key Vault.
- **Budsjett for natten: maks 5 USD totalt.** Mål faktisk kost. Nærmer det seg, stopp og slett.
- Etter verifisering: slett ressursene i `rg-terra-test` så det ikke går kost, og noter hva som eventuelt henger igjen (soft delete). Rør ikke `rg-solar-dev`.
- Ikke endre `Solar-Test-Budget`. Foreslå et lavere tall i rapporten.

## Ferdig når (kl. 07:30, så orchestrator-1 rekker rapporten)

1. `sc status` viser ekte data fra alle fem tjenestene.
2. Fanen «Plattform» viser det samme på :3200, også ved 390 px, uten sidefeil.
3. Statusissuet i drift oppdateres automatisk, og er sjekket minst én gang.
4. Azure: testutrulling kjørt og ryddet, faktisk kost målt, OIDC og `what-if` i CI virker.
5. `/plattform`-skillen virker.
6. Tester grønne, QA-rapport fra paal-1, og ingen hemmeligheter funnet.

Hver pane skriver innen 07:30 i sin innboksmelding til orchestrator-1: hva som er levert (PR-lenker), hva som faktisk er verifisert, og hva som ikke ble ferdig. Ærlig. Ufullstendig er bedre enn pyntet.
