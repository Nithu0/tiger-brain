# Triage-datavarighet — revisjon 2026-10-11 (bane L7)

Status: `FACT` for kodefunn (lest direkte), `UNKNOWN` der jeg ikke fikk verifisert kjøring pga. tidsbegrensning (se bunn).

## De tre alvorligste risikoene

1. **Admin-slett av en `opportunity` tar `tender-decisions` og `briefs` med seg.**
   `crm/src/collections/Opportunities.ts` har en `beforeDelete`-hook (linje 55-61) som
   cascade-sletter `klage-documents, klage-cases, qualification-assessments,
   clarification-questions, bid-drafts, activities, requirements, documents, predictions,
   tender-decisions, briefs` for den opportunityen. `tender-decisions` er ellers append-only
   (`update: nobody`, `delete: isAdmin`), men denne cascaden omgår det — en admin som trykker
   "delete" på én mulighet i Payload-admin **sletter hele beslutningshistorikken og briefen**
   for den, permanent, ingen søppelbøtte/trash. Dette er den eneste reelle slette-veien jeg fant
   til de tabellene operatøren ba meg sjekke.
   → Operatør-gated: ikke noe jeg kan/skal fikse uten OK, men bør vurderes (f.eks. kreve en
   bekreftelsestekst, eller fjerne `tender-decisions`/`briefs` fra cascaden og la dem henge igjen
   med en foreldreløs referanse i stedet).

2. **`requirements` kan slettes direkte av et vanlig medlem, ikke bare admin.**
   `crm/src/collections/Requirements.ts` linje 69: `delete: isMemberOrAdmin`. Alle andre
   kjernetabeller (`tender-decisions`, `briefs`, `opportunities`) krever admin for slett;
   `requirements` krever bare innlogget medlem. En feilklikk fra et medlem fjerner uttrukne krav
   permanent (cascade sletter også `qualification-assessments` for det kravet). Ikke en bug i
   striks mening — det kan være tilsiktet (medlemmer skal kunne fjerne feilutvinta krav) — men
   det er mer åpent enn de andre tabellene operatøren er bekymret for.

3. **Fant en kjent, ennå ikke committet fiks for "LLM-feil overskriver god brief", liggende i
   denne worktreen akkurat nå.** `crm/src/jobs/tasks/tender-brief.ts` på HEAD (det som er
   deployet) skriver en ny brief over den gamle uten å sjekke om LLM-kallet ga noe reelt innhold.
   Jeg fant `git diff` (uncommitted, "Not Committed Yet") i denne worktreen som legger inn akkurat
   denne sjekken: `llmGaveNothing(llm) && prevHadLlmSubstance(prev)` → kaster en feil i stedet for
   å lagre, så jobben prøver igjen og den gamle briefen blir stående. **Dette er ikke mitt arbeid
   og jeg har ikke rørt det** — det ser ut som en annen pane/sesjon jobber med nøyaktig dette
   akkurat nå i samme worktree. Flagg til operatør: la den sesjonen fullføre og committe selv;
   ikke la to sesjoner overskrive hverandre her.

## Resten av revisjonen (trygt i dag)

- **Beslutninger er append-only i praksis.** `TenderDecisions` har `create: <sjekket>, update:
  nobody, delete: isAdmin`. `decide`-handleren i `crm/src/endpoints/triage.ts` lager alltid en
  **ny rad** (aldri update) og oppdaterer kun et denormalisert `opportunities.decision`-felt for
  "siste status". Historikken ligger fullstendig i `tender-decisions`.
- **"Angre" sletter ikke.** Å sette `UNDECIDED` går gjennom samme `decide`-endepunkt →
  ny rad med `decision: 'UNDECIDED'`, ingen rad slettes. Samme gjelder hvis et menneske endrer
  `decision` direkte på opportunity-siden — `recordDecision`-hooken logger det som en ny rad
  (`source: 'opportunity-page'`), ingen dobbel-logging når triage-endepunktet allerede har gjort det.
- **Samtidige skrivinger fra to paner:** begge vil lykkes med å lage sin egen `tender-decisions`-rad
  (ingen rader tapes — historikken får to rader, ikke én overskrevet). Den eneste racen er på det
  denormaliserte `opportunities.decision`-feltet (siste commit vinner) — det er en visningsting,
  ikke datatap, og kan alltid rekonstrueres fra `tender-decisions` sortert på `decidedAt`/`id`.
- **Migrasjoner:** gikk gjennom alle 40 filene i `crm/src/migrations/`. Alle destruktive
  SQL-setninger (`DROP TABLE`/`DROP COLUMN`) ligger kun i `down()` (rollback), ikke i `up()`.
  Ingen ventende migrasjon sletter data når den kjøres fremover. Deploy (`src/migrate-or-die.ts`)
  kjører kun forover (`payload.db.migrate`), aldri `migrate:down` — bekreftet i koden, ikke gjettet.
- **LLM-skriving som kan overskrive med tomt:** se risiko #3 — på HEAD (deployet versjon) er dette
  fortsatt et hull; fiksen finnes men er uncommitted i denne worktreen.
- **Andre delete-kall i kodebasen** (`BidDrafts`, `BidSections`, `KlageCases`, push-subscriptions,
  `legal-chunks`-pruning i `ingest-lovdata.ts`) er alle cascades for sine egne barnerader eller
  pruning av forbigående data (push-subscriptions uten bruker, utløpte legal-chunks) — ingen av dem
  rører `tender-decisions`, `briefs`, `requirements` eller `opportunities` direkte.

## Tiltak levert (lavrisiko, ikke kjørt mot produksjon)

- `crm/scripts/export-triage-data.ts` — ren lese-only backup-script. Dumper `tender-decisions`,
  `briefs`, `requirements` til JSON (+ manifest.json med antall/tidspunkt). To moduser: lokal
  (`DATABASE_URL`, Payload Local API) eller `--remote <crm-url>` (Payload REST som innlogget
  medlem/admin, `IMPORT_EMAIL`/`IMPORT_PASSWORD`). Null `create`/`update`/`delete`-kall i filen.
  Lagt til i `package.json` som `npm run export:triage -- [--out <mappe>] [--remote <url>]`.
  Default-output `_backups/<tidsstempel>/`, lagt til `.gitignore` (ekte anbudsdata skal aldri commites).
- **Verifisering: delvis, IKKE fullført.** Jeg fikk rettet en reell bug under test (manglet
  `process.exit(0)`/`process.exit(1)` etter `payload.destroy()` — samme mønster alle andre scripts
  i `scripts/` bruker, fordi Postgres-adapteren ikke alltid stenger connection pool-en, så
  prosessen hang uten explicit exit). Selve kjøringen mot en ren database klarte jeg ikke å
  bekrefte før jeg ble bedt om å stoppe — maskinen har flere samtidige agent-sesjoner som delte
  samme scratch-Postgres (`anbud-pg-smoke`, port 5439) og kjørte `migrate`/`migrate:down` samtidig,
  som gjorde testen ustabil. Jeg startet en isolert engangscontainer for en ren test, men rev den
  ned uten å fullføre da jeg ble bedt om å avslutte nå. **Kjør selv før du stoler på scriptet:**
  `cd crm && DATABASE_URL=<lokal-test-db> PAYLOAD_SECRET=<32+ tegn> npm run export:triage -- --out /tmp/test`
- **Docs: ikke skrevet.** Dokumentasjonen i `projects/anbud/docs/` (hvor ofte kjøre + Railway-backup-
  sjekk) ble ikke skrevet — stoppet på operatørens beskjed før jeg kom dit. Det jeg har fra
  revisjonen: Railway-prosjekt `anbud`, region EU West, prosjekt-ID
  `2675f463-91bf-4a31-94b9-e9978e73de4c`, tjenester `Postgres`, `crm` (volum `/data`), `worker`
  (fra `projects/anbud/README.md` / `crm/README.md`). Om automatisk backup er på, og hvor man
  gjenoppretter, må bekreftes i Railway-dashbordet av operatør selv (Postgres-tjeneste → "Backups"-
  fane) — jeg har ikke endret og ikke sjekket Railway-innstillinger, og gjetter ikke på status.

## Operatør må gjøre selv (operatør-gatet)

- Bekreft/avgjør om admin-slett av `opportunities` fortsatt skal cascade-slette
  `tender-decisions`/`briefs` (risiko #1), eller om de skal unntas cascaden.
- Vurder om `requirements`-slett fortsatt skal være åpent for medlemmer, ikke bare admin (risiko #2).
- Sjekk Railway → Postgres → Backups-fanen for prosjekt `anbud` (restore-sti derfra), og bekreft
  retention selv — jeg har ikke rørt Railway-konfigurasjon.
- Se gjennom og evt. committ den uncommitted fiksen i `tender-brief.ts` i denne worktreen (ikke min
  — skrevet av en annen sesjon, "Not Committed Yet" i `git blame`) før den går tapt.
- Kjør `npm run export:triage` selv mot en skikkelig DATABASE_URL for å bekrefte scriptet oppfører
  seg som ventet før du stoler på det som backup-rutine; jeg rakk ikke en fullstendig grønn kjøring.

Filer:
- `/home/nithu/code/Veldora-triage-c/projects/anbud/crm/scripts/export-triage-data.ts` (ny)
- `/home/nithu/code/Veldora-triage-c/projects/anbud/crm/package.json` (nytt script `export:triage`)
- `/home/nithu/code/Veldora-triage-c/projects/anbud/crm/.gitignore` (`_backups/` lagt til)
