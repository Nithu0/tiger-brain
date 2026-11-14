# Plattformen mot målet: gapliste 14.11.2026

Mål (Nithu 14.11): én plattform (<https://web-production-cd4b4.up.railway.app>) som styrer GitHub, Google Workspace, Azure, Railway, Vercel, Fiken og Altinn, og der 80 % av arbeidet er automatisert.
Laget av data-1 (agent). Bare lest: kode på `main`, `sc status`, plattformbasen (lesing) og issues i drift, alt 14.11 rundt kl. 15.

## Kort svar

- **I dag viser plattformen mye og gjør lite.** Den kan bare handle i to tjenester: issues i `drift` og opplasting til Drive. Azure, Railway og Vercel er bare til å se på. Fiken er bygget, men slått av. Altinn mangler helt, og agentene skal ikke logge inn der.
- **Kode og dokumenter er allerede mest automatisert** (målt: 115 av 119 commits siden 1.11 er laget av agenter). **Arbeidet som helhet er det ikke:** 50 av 121 åpne saker i drift venter på et menneske, og alt som krever BankID, signatur eller betaling er manuelt med vilje.
- **Plattformen er ennå ikke stedet arbeidet gjøres.** Den har én bruker og tre handlinger totalt.

## Hva plattformen kan i dag (`FACT`, kode på main)

| Skjerm | Viser | Gjør (via broen på PC-en) |
|---|---|---|
| Oppgaver | Åpne issues i drift med steg («Klar for …») | Fullfør, Avgjør, Kommenter, Send til agent |
| Beslutninger | drift#126 som kort | Avgjør (krysser av i #126) |
| Oppdrag | Oppdrag til agenter og svar | Nytt oppdrag (issue med `agent-kan-ta`) |
| Oversikt | Fem tjenester, kost, PR-er, deploy, hendelser, Selskap-boks fra Brreg, neste frister | Ingenting |
| Dokumenter | Juridisk, anbud og finansiering fra drift, rolleinndelt | Ingenting |
| Last opp | Siste opplastinger med status og Drive-lenke | Opplasting til riktig mappe i Drive. Kvitteringer i Økonomi til Fiken-innboksen (av) |
| Varsler | Push-abonnement | Push ved ny beslutning, svar i oppdrag, dokument arkivert, oppgave lukket, broen borte |

Køtyper: `fullfor`, `avgjor`, `kommenter`, `send-til-agent`, `nytt-oppdrag`, `arkiver-dokument`, `til-fiken`. Broen skriver bare til `Solar-Consulting/drift`.

## Per tjeneste

| Tjeneste | Vises i dag | Gjøres i dag | Mangler for å «styre» | Status nå (`sc status`) |
|---|---|---|---|---|
| **GitHub** | Issues og #126 i drift, PR-er og CI i alle repoer, Actions-minutter | Kommentere, lukke og lage issues i drift | Handlinger i andre repoer (plattform, Terra, nova, solarlabs), review-kø. Merge og deploy er utelatt med vilje | ADVARSEL: plattform-CI har «deploy advarsel» (`UNKNOWN` hvorfor, ikke undersøkt her) |
| **Google Workspace** | Konto-status. Brukere og 2FA er ukjent | Arkivere filer i den delte disken | Brukere og 2FA (innloggingen mangler `admin.reports.usage.readonly`). Teamet er ikke medlem av den delte disken. E-post og deling er forbudt for agentene | ukjent |
| **Azure** | Ressursgrupper, budsjett, varsler | Ingenting | Kost (Azure har ingen kostrader ennå). Handlinger er ikke planlagt | ok, kost ukjent |
| **Railway** | Prosjekter, tjenester, deploy, kost og estimat | Ingenting | Å se loggen for en feilet deploy i appen. Omstart og deploy er utelatt med vilje (operatør) | ADVARSEL: `test/aslisten-crm` FAILED (kjører kode fra 27.10), `acceptable-adaptation/command-center` FAILED (kjører kode fra 24.05) |
| **Vercel** | Prosjekter, domener, deploy | Ingenting | `veldora2` gir `ikke-funnet` (slettet, flyttet eller manglende tilgang, `UNKNOWN`) | ukjent (siste oppfrisking feilet) |
| **Fiken** | Status per kvittering | Kvittering til innboksen (trinn A, bygget) | Fiken-konto, testselskap og nøkkel. Deretter `FIKEN_AKTIV=1`. Trinn B (utkast til kjøp) er ikke bestemt | av til nøkkelen finnes |
| **Altinn** | Frister (frister.json) og lenker i Selskap-boksen | Ingenting | Alt. Agentene logger ikke inn med BankID, og det skal de ikke. Maskinporten (#11, #12) kan gi lesetilgang senere | — |

## Hvor mye er automatisert?

| Hva | Tall | Merke |
|---|---|---|
| Commits på main siden 1.11 laget av agenter (Claude-merke) | plattform 32/32, command-center 35/35, drift 29/29, Terra 7/7, horizon 4/8. Til sammen **115 av 119 (97 %)** | `FACT` (git log, 14.11) |
| Åpne issues i drift som venter på et menneske | `klar-for-nithu` 33, `klar-for-jurist` 8, `klar-for-alper` 5, `klar-for-tintun` 4: **50 av 121 (41 %)** | `FACT` (GitHub, 14.11) |
| Issues agentene kan ta eller har tatt | `agent-kan-ta` 15, `agent:tatt` 15 | `FACT` |
| Bruk av plattformen | 1 bruker, 3 handlinger totalt (2 Fullfør, 1 arkivering), 1 opplasting, 13 sesjonshendelser siste 14 dager | `FACT` (plattformbasen, lesing) |
| Andel av alt arbeid som er automatisert | **ca. 55–65 %** | `ASSUMPTION`: kode og dokumenter ~95 %, men 41 % av sakene står hos et menneske. Innlogging, signatur, innsending og betaling er manuelt per regel |

**Forslag til definisjon av «80 %»** (`ASSUMPTION`, må avgjøres): en sak teller som automatisert når et menneske bare godkjenner med ett trykk eller ikke gjør noe. Da er signatur og betaling innenfor, hvis agentene har forberedt alt. Uten en slik definisjon kan målet ikke nås, fordi BankID-steg aldri blir automatiske.

## Topp 5 neste leveranser (hver under én dag)

1. **Måle automatiseringsandelen i Oversikt.**
   - Broen teller hver uke saker som er lukket i drift, fordelt på hvem som gjorde arbeidet (agent eller menneske, ut fra etiketter og Claude-merke).
   - Oversikt viser tallet og trenden mot 80 %.
   - Uten måling vet ingen om vi nærmer oss. (data-1 og trading-1)
2. **Nithus kø med ett trykk.**
   - De 33 sakene merket `klar-for-nithu` vises samlet i Oppgaver, med stegene, lenken, og Fullfør eller Avgjør.
   - Det flytter arbeid fra GitHub inn i plattformen. (admin-1)
   - `UNKNOWN`: om Mine oppgaver allerede tar med saker som ikke er tildelt ham.
3. **Rydde statusfunnene, så Oversikt er grønn eller sann.**
   - Undersøke deploy-advarselen i plattform-CI.
   - Avgjøre Vercel `veldora2`: fjerne den fra listen eller gi tilgang.
   - Lage ett issue per Railway-tjeneste som har FAILED, med det eieren må avgjøre.
   - Legge GWS-scopet inn som ett steg for Nithu (`gws auth login` med `admin.reports.usage.readonly`).
   - Agentene kan forberede alt. Sletting og ny innlogging er operatørens. (data-1)
4. **Handlinger i flere repoer.**
   - Broen kan kommentere, lukke og sette `agent-kan-ta` i plattform, Terra og nova, ikke bare i drift.
   - Da kan Oppdrag gå til riktig repo.
   - Endringer i Terra og nova følger regelen for Tintun (tintun-sjekk, drift#198). (trading-1)
5. **Fiken ende til ende.**
   - Nithu lager et testselskap og en nøkkel (15 min).
   - Operatøren legger nøkkelen i broen og setter `FIKEN_AKTIV=1`.
   - Én kvittering prøves hele veien.
   - Det er første gang en regnskapsjobb går uten at noen taster. (Nithu og operatøren, så trading-1 og data-1)

## Ikke undersøkt her

- Hvorfor deploy-steget i plattform-CI gir advarsel.
- Om GWS-scopet kan legges til uten at andre tilganger faller bort.
- Hvor mye tid sakene som venter på et menneske faktisk tar.
