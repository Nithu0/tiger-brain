# Knutepunkt QA, kladd (paal-1)

Statisk gjennomgang natt til 05.11 kl. ~02 mot command-center 557741f. Ingen kall mot tjenestene. Ende-til-ende fra 05:00, når lastrettingene er merget.

## Må testes ende til ende

- [ ] H1: `sc statusissue` kjører med `DIREKTE_FRIST_MS` = 20 s per tjeneste (`sc.ts`), selv om kommentaren sier at den «har god tid». Hypotese: en tjeneste som bruker over 20 s, gir tidsavbrudd, og resultatet skrives til den delte cachen, så cockpit viser `ukjent` i opptil 15 min. Mål tiden per adapter og se etter «Siste oppfrisking feilet» etter en timerkjøring.
- [ ] Auth: svarer `GET 127.0.0.1:3100/api/platform` uten innlogging? (`registerAuth`, sjekk at ruten ikke er unntatt.) Når svaret har e-post og 2FA per bruker, skal det ikke være åpent for hvem som helst via cockpit.
- [ ] `GET /api/platform` starter oppfrisking ved hvert kall når data er gamle. Fanen må ikke gi last.
- [ ] cc-api utilgjengelig: `CC_API_URL=http://127.0.0.1:1 sc status`. Faller den tilbake til cache med merknad? **Ikke restart cc-api** (orchestrator-1: opptil 6 min under last), og ingen `--vent` i løkke.
- [ ] Ugyldig input: `sc logg`, `sc logg ../../x`, `sc logg constructor`, ukjent kommando, `/api/platform/__proto__`.
- [ ] 390 px i fanen, ingen sidefeil, `ukjent` aldri grønt.
- [ ] `/plattform`-skillen.
- [ ] Skann svar fra API, `sc --json`, issue og feed for hemmeligheter, med brede mønstre.

## Funn så langt (kode)

1. **Hull i sladdingen** (`plattform.ts` `HEMMELIGE_MONSTRE`, lav/middels): dekker ikke Google `ya29.` og `GOCSPX-`, eller Azure SAS `sig=`. Dette er siste vern, og adapterne plukker navngitte felter, så ingen kjent lekkasje. Fiks: legg til mønstre med test.
2. **Ufiltrert tekst fra kilder** (lav): `loggTekst` skriver `h.tittel` rått til terminal (ANSI-sekvenser fra PR-titler). `cell()` i statusissuet nøytraliserer ikke `@navn`, så et navn i en delstatus kan varsle folk hver time. Fiks: fjern kontrolltegn, og sett `@` i kode.
3. **Etikett styrer hvilket issue som overskrives** (lav): `skrivStatusissue` overskriver det første åpne issuet med labelen. Label på feil issue overskriver teksten der. Fiks: sjekk tittelen også.

## Sjekket og i orden

- `execFile` uten skall, `timeout` rundt alle CLI-er, høyst 3 samtidig per prosess.
- `railwayApi` tar bare faste spørringer, GWS-kall er en lukket liste med `fields`, ingen kalendertitler. Vercel plukker felter, så `env` kommer ikke med.
- Cachen: mappe 700, filer 600. Skanning av cachen 01:50: ingen hemmeligheter, bare den innloggede GWS-kontoen.
- Ukjent/gammelt: `vis` gir `ukjent` over 60 min, `verste` lar aldri ukjent bli grønt, mislykket runde beholder data, men som `ukjent`.
- Statusissuet (drift#217): drift er privat, ingen e-post eller hemmeligheter i teksten.
- cc-api binder til 127.0.0.1.
