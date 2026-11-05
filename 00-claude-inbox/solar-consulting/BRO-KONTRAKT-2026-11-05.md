# Broen sc-bro: kontrakt (trading-1, 05.11)

PC-en sender data opp og henter handlinger. Appen har ingen GitHub-nøkler. GitHub er sannheten, og appen lagrer bare kø, snapshots og logg.
Kode kommer i `src/lib/bro/` i `Solar-Consulting/plattform` så snart repoet finnes. Bygg mot dette og fixtures imens.

## For skjermene (admin-1, data-1, learning-1)

```ts
import { lesSnapshot, broStatus, opprettHandling, handlingerFor } from "@/lib/bro";

const s = await lesSnapshot("oppgaver"); // { data, hentet, mottatt, alderSek, utdatert } eller null hvis aldri mottatt
const b = await broStatus();             // { sistSett, alderSek, nede } — nede = ingen runde på 5 min
await opprettHandling({ type: "fullfor", issue: 42, notat, lenke, av: { navn, epost }, noekkel }); // { id, status: "venter" }
await handlingerFor(42);                 // for å vise «venter», «utført» eller «feilet»
```

**Regler:** vis alltid alder. `null` eller `utdatert` er aldri grønt. `noekkel` er en UUID laget når skjemaet vises, så dobbelttrykk bare gir én handling. Sjekk rollen før `opprettHandling`: broen vet ikke hvem som har lov.

## Snapshots

| Nøkkel | Innhold |
|---|---|
| `oppgaver` | `[{ nummer, tittel, url, labels: string[], tildelt: string[], oppdatert, omrade, venterEierskifte, klar: { for, tekst, url } \| null }]`, åpne issues i drift. `klar` er siste «Klar for …»-kommentar |
| `beslutninger` | `{ url, oppdatert, punkter: [{ linje, seksjon, tekst, avgjort, refs: number[] }] }`, #126. `linje` er hele teksten og er nøkkelen ved avgjørelse |
| `plattform` | `Plattformoversikt` fra `@cc/platform` (`tilstand`, `generert`, `tjenester[]`) |
| `dokumenter` | Kommer senere. data-1 sier hvilke mapper |

## Handlinger (`opprettHandling`)

| `type` | Felter | Hva broen gjør i `drift` |
|---|---|---|
| `fullfor` | `issue`, `notat?`, `lenke?` | Kommenterer «Ferdig: …» og lukker |
| `avgjor` | `issue` + `svar`, eller `linje` + `svar` | Kommenterer svaret ordrett. Med `linje`: krysser av i #126 |
| `send-til-agent` | `issue`, `tekst` | Kommenterer og setter `agent-kan-ta` |
| `nytt-oppdrag` | `tittel`, `tekst` | Lager issue med `agent-kan-ta` |
| `kommenter` | `issue`, `tekst` | Kommenterer |
| `sett-status` | `issue`, `status` | Setter kort på boardet |

Status: `venter` → `sendt` (broen har hentet den) → `utfort` (med `url`) eller `feilet` (med `kategori`). Bare det her finnes. Ikke merge, deploy eller sletting.

## Mellom broen og appen (bare trading-1)

`POST /api/bro/runde`, `Authorization: Bearer $BRO_TOKEN`. Én forespørsel hvert minutt: `{ snapshots: [{ noekkel, hentet, data }], uendret: [noekkel], resultater: [{ id, status, url?, kategori? }] }` gir `{ handlinger: [...] }`.
**tools-1:** `/api/bro/*` må slippe Entra-innlogging, for den har eget token. Prisma-modellene `BroSnapshot`, `BroHandling` og `BroStatus` legger jeg i schema.
