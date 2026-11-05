# Plattformen: nettappen teamet jobber i

Oppdrag fra operatøren 05.11 kl. 07:11: «jeg vil gjerne faktisk ha en plattform å jobbe på, ikke bare en kommando». `sc` og cockpit-fanen var ikke nok. Han må kunne åpne den på mobilen, og teamet må kunne jobbe der.

**Mål i dag:** en ekte adresse med ekte innlogging der Nithu kan åpne oppgavene sine på telefonen og fullføre én. Bygg det tynt fra ende til ende først, og utvid etterpå.

## Beslutninger (ikke diskuter)

- **Repo:** nytt privat `Solar-Consulting/plattform`, opprettet fra `templates/app` i Terra, og lagt inn i `.meta`.
- **Hosting:** Railway nå (europe-west4), som **eget nytt prosjekt**. Flyttes til Azure Container Apps senere.
- **Flyttbarhet er et krav.** Appen er ett container-image, bygd i GitHub Actions og lagt i GHCR, standard Postgres, all konfig via env, ingenting Railway-spesifikt i koden. Railway trenger ikke lesetilgang til pakkene hvis CI bygger imaget. Finn ut av hvordan Railway henter et privat image. Går det ikke, er alternativet å bygge med byggehemmelighet. Skriv en kort `docs/flytt-til-azure.md`.
- **Stack:** ADR-0024 og Terra: Next.js, Prisma, Postgres, `@solar-consulting/tilgang`, `@solar-consulting/ui`. Bruk `revisjon` for logg. Dette er første app på basen utenom Nova: finn du feil i basen, rett dem der med PR, ikke rundt dem.
- **Innlogging:** Entra (tenant `53139d9a-443d-4918-82cd-4bc4e5e734e1`). Egen app-registrering `plattform`. Bare brukere i tenanten. Juristen (`veldora-anbud`) har ikke Entra-bruker ennå: se åpne spørsmål.
- **Roller:** eier (Nithu), utvikler (Tintun, Alper), jurist. Juristen ser bare sine oppgaver og juridiske dokumenter, ikke kost, kontoer eller kode.
- **Broen:** hemmeligheter og CLI-er blir på PC-en. En tjeneste her (`sc-bro`, systemd-timer hvert minutt) **sender** data opp til appen (plattformstatus fra `@cc/platform`, issues, board, PR-er) og **henter** handlinger brukerne har gjort i appen (fullfør, avgjør, nytt oppdrag), og utfører dem med `gh`. Autentisert med et delt token. Appen har ingen GitHub-, Azure- eller Railway-nøkler. Appen viser alltid hvor gamle dataene er, og handlinger står som «venter» til broen har utført dem. PC-en av = gamle data vist tydelig, aldri feil vist som ok. En GitHub App kan erstatte broen senere.
- **GitHub er fortsatt sannheten** for oppgaver. Appen lagrer bare kø, snapshots og revisjonslogg.

## Skjermer, i rekkefølge

1. **Mine oppgaver** (mobil først): oppgavene mine i dag, sortert. Åpne en, se stegene («Klar for …»), trykk **Fullfør** (med lenke/notat), **Avgjør** (svar) eller **Send til agent**.
2. **Beslutninger:** #126 som kort, med «blokkerer» og knapper, ikke avkrysning. Gruppert. Svaret går tilbake til issuet.
3. **Oppdrag til agent:** skriv hva du vil ha. Blir issue med `agent-kan-ta`, som drift-vakt sender til en pane. Svar og PR-er vises i tråden.
4. **Oversikt:** status for de fem tjenestene, kost, åpne PR-er, deploy, hendelser. Ukjent er aldri grønt.
5. **Dokumenter:** avtaler, personvern, anbud og søknader fra `drift`, lesbart. Rolleinndelt.
6. **Team:** hvem jobber med hva, hva venter på hvem.

## Fordeling

| Pane | Lane |
|---|---|
| tools-1 | Repo, CI, image, Railway-prosjekt, Postgres, Entra-registrering, innlogging, roller, layout, `docs/flytt-til-azure.md`. **Først ute: innlogging på ekte adresse.** |
| trading-1 | Broen: `sc-bro`, API-et den snakker med, snapshots, køen, idempotens, feilhåndtering |
| admin-1 | Skjerm 1 og 2 (Mine oppgaver, Beslutninger) |
| data-1 | Skjerm 4 og 5 (Oversikt, Dokumenter) |
| learning-1 | Skjerm 3 (Oppdrag) og sikkerhet: rolletilgang testet per rute, CSRF, rate limit, ingen hemmeligheter i klient, revisjonslogg |
| paal-1 | QA: mobil først, som en ekte bruker, hver gang en skjerm er merget. Prøv å komme til det rollen ikke skal se. |
| infra-1 | Fortsetter med sitt. |

## Rekkefølge

1. **Innlogging på adressen** (tools-1) og **broen med én rad** (trading-1). Andre bygger mot lokale fixtures imens.
2. Skjerm 1 kobles på ekte data. **Da melder orchestrator-1 adressen til Nithu.**
3. Skjerm 2–6, én PR av gangen.

## Arbeidsform

- 90 % bygging. Små PR-er. Merge selv når CI er grønn. Spar med hverandre i innboksene.
- **Maks 2 subagenter per pane**, og kjør målrettede tester, ikke hele suiter. I natt kom load over 50 av oss selv. Ikke start `tsc` i løkke.
- Jobb i egen worktree. Delte checkouter står på `main`. Kjør `bin/tintun-sjekk` før du rører Terra. Logg i drift#198.
- Bruk REST mot GitHub. STATUS til orchestrator-1 bare ved merget leveranse eller blokkering.
- **Hvis du ser en API-feil: fortsett, og start innboks-monitoren igjen.**

## Grenser

- **Hemmeligheter:** nye hemmeligheter *for denne appen alene* (Entra-klient, sesjonsnøkkel, brotoken, database) kan genereres og pipes rett inn i Railway/lokal fil med 600-rettigheter, og skal aldri skrives ut, committes eller legges i issues. Eksisterende hemmeligheter røres ikke og kopieres ikke.
- **Andre tjenester:** anbud, solarlabs, aslisten og Vercel røres ikke. Nytt Railway-prosjekt er det eneste som opprettes.
- **Penger:** én liten tjeneste + Postgres. Over ca. 20 USD/mnd: meld først.
- **Ingen e-post eller invitasjoner til noen** uten at Nithu ber om det. Ingen ny bruker i Entra uten å melde.
- **Broen utfører bare** de handlingene appen tilbyr: kommentere, lukke og lage issues i `drift`, krysse av i #126, og sette kort på boardet. Ikke merge, deploy eller sletting.
- **Ingen persondata** utover navn, e-post og rolle. Ikke kopier AS, Søking, innhold fra Gmail/Drive eller kundedata.
- **Tintun:** ikke overskriv arbeidet hans. Review er ikke nødvendig for å merge i `plattform`. Endringer i Terra-basen: små PR-er, og han får beskjed i #198.

## Åpne spørsmål (gå videre med antakelsen)

- Juristen: antakelse: han får gjesteinvitasjon i Entra når alt er klart. Ikke send den.
- Navn og domene: antakelse: Railway-adresse nå, `plattform.solarconsulting.no` senere (DNS er operatørens).

## Ferdig for første versjon

Nithu åpner adressen på telefonen, logger inn med Microsoft, ser oppgavene sine, fullfører én, og den lukkes i `drift` innen ett–to minutter. Bevist av paal-1 ende til ende, med ekte data.
