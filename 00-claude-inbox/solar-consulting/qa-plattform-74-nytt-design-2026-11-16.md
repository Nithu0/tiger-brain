# QA: plattform#74 (nytt design), 16.11.2026

paal-1. Lokal stack på main (bdd4260) med falsk IdP og falsk bro, oppdiktede data, 390 px. De gamle E2E-suitene er kjørt på nytt, sammen med et nytt sveip over alle sider for eier, utvikler og jurist. Ingen ekte deploy og ingenting mot GitHub eller Drive.

## Kort

Designet holder. Det er ingen vannrett rulling og ingen sidefeil på noen side for noen rolle. Rollene ser det samme som før: kost følger `kost.les`, og køen og sorteringen vises bare for eieren. Prisma, broen, ruter og server actions er ikke endret, og forfalskede kategorier i opplasting avvises fortsatt på serveren. Ett funn bør rettes, to er små.

## Funn

1. **Dobbelttrykk på Redeploy i /drift kan treffe neste tjeneste** (middels). Med 150 ms mellom trykkene svarer siden før trykk nr. 2. Meldingen øverst skyver radene ned, så det andre trykket treffer knappen til tjenesten under: `vercel:renseri` og så `vercel:fellesfat`. Nøklene er ulike, så serveren ser to ekte bestillinger. Med 400 ms mellom trykkene ble det én. Meldingen fantes før #74 også, så feilen er trolig ikke ny, men den er ikke målt på det gamle bygget. Kommentaren i `drift/page.tsx` sier at dobbelttrykk bare gir én handling, og det stemmer ikke når siden svarer raskt. Forslag: sett knappene til `disabled` mens skjemaet sendes (`useFormStatus`), eller la meldingen ikke skyve radene.
2. **Ja og Nei står 8 px fra hverandre** (lavt), i Beslutninger og i eierens kø. Begge er 44 px høye. Kravet fra QA av #34 var 16 px mellom, fordi et feiltrykk der er et svar.
3. **«#N i drift» på oppgavesiden er 24 px høy** (lavt). Den oppfyller WCAG AA (24 px), men ikke appens 44 px. Det er en frittstående lenke, ikke en lenke i løpende tekst.

## Kjent fra før, ikke fra #74

- Fullfør-notatet sender `![x](https://…)` videre til GitHub som bilde. GitHub viser bilder via en proxy, så risikoen er lav. Notatrensingen er uendret siden 0cd9bb1.
- POST mot /api/drift/deploy uten innlogging gir 401, ikke omdirigering. Ingen handling lages, så det er riktig. Testen forventet omdirigering.

## Det som var testene mine, ikke appen

- Listene er nå `div[role=list]` med `[role=listitem]`, ikke `li`. Semantikken er riktig.
- «Skriv et annet svar» og stegene er Radix Collapsible, som fjerner innholdet når det er lukket. Med alt åpnet består Beslutninger (11/11) og Fullfør per repo.
- Kategorivalget i opplasting styres av React-state, så å sette DOM-verdien sendte ikke den forfalskede kategorien. Med change-hendelse avvises alle sju forfalskninger med `feil=kategori`.
- Ukjent-raden for Google Workspace er ikke grønn. Testen traff en større beholder.
- Automatiseringskortet hopper over uker uten kjent andel og sier det i tekst. Det er bevisst.

## Resultater

| Suite | Resultat |
|---|---|
| sortering (#73) | 21/21 |
| opplasting, roller og forfalskning | 42/44 (2 = rate limit fordi jeg kjørte to ganger) |
| beslutning | 11/11 |
| repo-fullfor | grønn etter at «Fullfør» trykkes først |
| sveip, 3 roller × 8 sider | 45/47 (2 = feil forventning i testen min: utvikler har `kost.les`) |
| drift-deploy | 18/20 (funn 1, og 401 over) |
