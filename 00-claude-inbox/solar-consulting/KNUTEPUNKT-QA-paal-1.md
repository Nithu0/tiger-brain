# Knutepunkt: QA-rapport fra paal-1

Uavhengig test 05.11 fra kl. 05:00 CET, mot command-center 86431d5, deretter a581b34 (#156) og til slutt d1e6478 (#157 og #158).

## Konklusjon

Plattformen virker, og tallene stemmer med kildene der jeg kunne kontrollere dem. Jeg fant ingen hemmeligheter. Testen fant seks feil, og alle er rettet i [#156](https://github.com/Nithu0/command-center/pull/156). To av dem var synlige for brukeren: fanen viste UTC som lokal tid, og et svar med feil form tok ned hele cockpit. To funn til ble rettet av eierne: fremmed Host og Origin ([#157](https://github.com/Nithu0/command-center/pull/157), tools-1) og alderen på Railway-versjonen ([#158](https://github.com/Nithu0/command-center/pull/158), data-1).

Kriterium 1 er bare delvis oppfylt: Google Workspace mangler brukere og 2FA, fordi innloggingen mangler et scope som bare en admin kan gi.

## Kriteriene i spec

| # | Kriterium | Resultat | Merknad |
|---|---|---|---|
| 1 | `sc status` viser ekte data fra alle fem | Delvis | GWS mangler brukere og 2FA. Lagring, delte disker og kalendere gjelder bare den innloggede kontoen |
| 2 | Fanen viser det samme, også 390 px, uten sidefeil | Ja | Headless Chromium ved 1440 og 390 px. Ikke testet på fysisk mobil eller Safari |
| 3 | Statusissuet oppdateres automatisk | Ja | Timeren kjørte 05:00 og 06:01 CET, begge uten feil. Etter rettelsene: issuet oppdatert 05:01Z, tallene de samme som i `sc`, fortsatt ett issue med labelen |
| 4 | Azure ryddet, kost målt, OIDC og `what-if` | Delvis kontrollert | Se under. Selve utrullingen er ikke gjentatt |
| 5 | `/plattform`-skillen virker | Ja | Lastes, og begge veiene gir data. Utdatert tekst rettet av admin-1 |
| 6 | Tester grønne, ingen hemmeligheter | Ja | Se tall under |

## Kontrollert mot kildene

| Kilde | `sc` sier | Kontroll | Stemmer |
|---|---|---|---|
| GitHub | 7 repoer, 2 åpne PR-er | 6 i org + `Nithu0/command-center`; nova 1 + aurora 1 | Ja |
| GitHub-seter | 4 brukte, planen oppgir 2 | 3 medlemmer + 1 ekstern samarbeidspartner | Ja |
| Azure | 2 grupper, 0 ressurser, 0 åpne varsler | `az group list`, `az resource list`, Alerts-API-et direkte | Ja |
| Railway | 9 prosjekter, 21 tjenester | 9 i Railway-API-et. Tjenestene er ikke talt mot kilden, `sc deploy-status` viser 21 | Prosjekter ja |
| Vercel | 5 prosjekter, 2 domener | `vercel project ls`, `vercel domains ls` | Ja |

## Prøvde å ødelegge

Holdt uten endring:

- **Ugyldig input til `sc`:** sti-traversering, `constructor`, `__proto__`, `$(id)` og ukjent kommando ga exit 2 og kort feilmelding.
- **Ugyldig input til API-et:** `__proto__`, `constructor`, kodet sti og `%00` ga 404. POST, PUT, DELETE og PATCH ga 404. Ingen CORS-header til fremmed origin.
- **40 samtidige `?oppfrisk=1`:** alle fikk 200 på 1 s, API-et svarte på 9 ms etterpå, og det ble én oppfriskingsrunde, ferdig på under 3 minutter uten feil i loggen.
- **Ødelagt cache:** ugyldig JSON, tom fil, `null`, `{}`, `status: null` og liste ga «ukjent, aldri hentet», aldri grønt og aldri krasj.
- **Gammel cache:** 100 min gamle data ga `ukjent` for tjenesten og samlet.
- **Uten API og uten cache:** `sc --cache` ga ukjent på alle fem på 0,4 s.
- **Fanen mot feilsvar:** 500, 404, ikke-JSON og brutt nett ga en lesbar feilmelding.
- **Fanen mot fiendtlig tekst:** HTML og `<script>` ble ikke kjørt. `javascript:`- og `data:`-lenker ble ikke lenker, og 4000 tegn lang tittel ga ikke sidelengs scroll.
- **`Oppfrisk` i fanen ved 390 px:** to raske klikk ga to kall med 200 og ingen sidefeil. Knappen er 44 px høy.
- **Fremmed Host og Origin etter #157:** 59 av 59 forsøk ga forventet svar på :3100 og :3200. Forsøkene var `127.0.0.1.evil.example`, `localhost@evil.example`, `localhost.`, `127.1`, `2130706433`, `Origin: null`, `http://localhost:3200@evil.example`, POST med `text/plain`, `/ws` med fremmed Origin, og HTTP/1.0 uten Host. Loopback slipper fortsatt inn.
- **Enhetstester:** 200 grønne på d1e6478 (`packages/platform`, visningen i fanen og Host-vernet). CI grønn på #156.

## Feil funnet og rettet i #156

1. **UTC vist som lokal tid.** «Siste døgn» sa 03:41 om noe som skjedde 04:41 norsk tid. Målt etter retting: 04:41.
2. **Svar med feil form tok ned hele cockpit.** `tid: null` eller en tjeneste uten `status` ga «Application error» på alle faner. `{}` og `null` ga «Laster …» for alltid. Målt etter retting: «Fikk et ugyldig svar», uten sidefeil. Ingen ekte API-svar har utløst dette.
3. **Hull i sladdingen.** `ya29.`, `GOCSPX-`, Azure `sig=` og `NAVN_TOKEN=verdi` overlevde. Ingen slike verdier er sett i ekte data.
4. **Kontrolltegn fra titler nådde terminalen** via `sc logg`.
5. **`@navn` i statusissuet kunne varsle folk** hver time.
6. **Labelen alene bestemte hvilket issue som ble overskrevet.**

Rettelsene er i drift: `cc-web` ble startet på nytt av meg 05:22, `sc` og timeren er bygget på nytt, og `cc-api` ble startet på nytt 05:31 av en annen pane.

## Hemmeligheter

Skannet med brede mønstre, siste gang på d1e6478: API-svar, `sc status --json`, alle `sc`-kommandoer, cachen, drift#217 (tekst, 0 kommentarer), feed-linjer om plattformen, journalen for `cc-api` og `sc-statusissue`, og teksten i fanen.

- **Hemmeligheter:** ingen funnet.
- **E-post:** bare den innloggede GWS-kontoen, i API, `--json`, `sc tilgang` og cachen. Ingen i issuet.
- **Falske treff:** e-posttreffet i journalen er systemds `user@1000.service`. Filstien i cockpit-teksten er en linje fra terminalfeeden, ikke fra Plattform-fanen.
- **Øvrig:** adapterne sender ingen token i argumenter (`--token`, `Authorization`). Cachen har rettighetene 700/600.

Dette er mønstersøk, så en hemmelighet i et format jeg ikke har mønster for, ville ikke blitt funnet.

## Åpne funn, ikke rettet av meg

| Funn | Alvor | Eier | Status |
|---|---|---|---|
| cc-api og cc-web svarer uten innlogging. Fremmed Host og Origin stoppes nå (#157), men enhver prosess på maskinen kan lese og skrive | Middels, må lukkes før Tailscale | Operatøren | `AUTH_SECRET` er operatørens beslutning og er ikke satt |
| `acceptable-adaptation/command-center` på Railway: siste vellykkede deploy er 24.05. De åtte siste feilet, og den siste jeg slo opp, feilet i HEALTHCHECK. Hver merge til command-center starter en ny | Middels | Operatøren: rette helsesjekken eller koble fra autodeploy | Teksten viser nå datoen (#158). Tjenesten er ikke rørt, og #156 til #158 har startet nye deploy-forsøk |
| GWS: innloggingen mangler `admin.reports.usage.readonly` | Hindrer kriterium 1 | Operatøren | Kjent |
| Kost er ukjent for Azure, GWS og Vercel. Azure: budsjettet viser 0 av 500 NOK, men ingen kostrader ennå | Lav | Ingen handling nå | Vises riktig som ukjent |
| GitHub-organisasjonen bruker 4 seter på en plan som oppgir 2 | Lav, bør sjekkes | Operatøren | Data er ekte |
| Når cc-api er nede, sier `sc` ikke fra. Lukkede porter på loopback svarer med tidsavbrudd på denne maskinen, så det ser ut som et tregt API, som med vilje ikke varsles. Alderen vises, og etter 90 min blir det ukjent | Lav | tools-1 | Ikke meldt særskilt |
| Tom fil `9` i delt checkout av command-center, fra 01:34 | Ingen | Ukjent | Ikke fjernet |

## Azure, det jeg kontrollerte selv

- `rg-terra-test` har 0 ressurser.
- En slettet Key Vault ligger i soft delete med planlagt sletting 11.11: `terratestkvgcpffb7vxugog`.
- Siste kjøringer av `infra` i Terra er grønne (siste 04.11 22:12Z). Jeg leste bare resultatet, ikke innholdet i `what-if`.
- Kost for testutrullingen er ikke målt av meg. Azure viser ingen kostrader ennå.

## Ikke testet

- Fysisk mobil, Safari og nettleseren på Windows.
- Selve Azure-utrullingen, OIDC-oppsettet og `what-if`-innholdet.
- Skriveoperasjoner, fordi spec bare gir lesing.

## Last under testen

Lasten nådde rundt 50 kl. ~05:08 mens jeg kjørte 11 feiltester i fanen. Prosessene som kjørte da var mest `firm-worktree-prune` og `firm-worktree-list`, men hver sidelasting i cockpit gir også et `/api/git/status`. Jeg kan ikke skille hva som kom fra hva. Lasten falt til rundt 2 kl. ~05:15.

Rydding: QA-worktreen er fjernet. Den merget grenen `fix/plattform-qa-funn` står igjen, fordi spec ikke tillater sletting av grener.
