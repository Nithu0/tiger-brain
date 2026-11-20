# Låste kopier og egne token: plan per tjeneste

infra-1, 20.11.2026. Bygger på `timer-revisjon-2026-11-20.md`. Rekkefølgen er satt av orchestrator-1.

## Mønsteret, likt for alle

- `git archive <sha>` pakkes ut i `~/.local/lib/<tjeneste>/<sha>/`, uten `.git`. Kopien endres ikke av en pull eller merge, bare av at noen kjører installeren med en ny sha.
- Installeren skriver drop-ins (`zz-laast-kopi.conf`) som peker enhetene dit, og avslutter med exit 1 hvis systemd viser en annen sti.
- Tilbakerulling er å kjøre installeren med forrige sha. Gamle versjoner blir liggende, og ingenting slettes.
- Data som endres ofte (plan, json-lister) kan leses fra den vanlige checkouten via en egen variabel, men aldri kode.
- Tokenene byttes ikke før Nithu har laget de nye. Det gjøres i en egen PR per tjeneste, med `EnvironmentFile=` i drop-in-en (verdien lagres i `~/.config/firm/<tjeneste>.env`, mode 600).

## PR-er i rekkefølge

| # | Tjeneste(r) | Repo | Status | Merknad |
|---|---|---|---|---|
| 1 | drift-vakt og scopevakt | Solar-Consulting/drift | **Utkast: drift#365**, venter på QA fra paal-1 | Måltavla leser planen fra `DRIFT_DATA_ROT`. |
| 2 | aslisten-crm-backup og aldersvakten | Nithu0/aslisten-crm | Ikke startet | Fjerner `git fetch` og `checkout origin/main` før hver kjøring. `installer.sh` fra #75 utvides med sha. |
| 3 | sc-bro | Nithu0/command-center | **Utkast: cc#210**, venter på QA fra paal-1 | `_bin/laast-kopi-install.sh` bygger platform i kopien med typescript fra checkouten. Platform har ingen kjøretidsavhengigheter, så kopien har ingen node_modules. Dist er byte-likt med den delte checkouten. |
| 4 | sc-dagsrapport og sc-statusissue | Nithu0/command-center | Ikke startet | Samme kopi og samme bygg som sc-bro. Kan gå i samme PR som #3 hvis det er enklere å QA-e. |
| 5 | slack-vakt | Nithu0/command-center | Ikke startet | Samme kopi. |
| 6 | brain-sync | Nithu0/command-center | Ikke startet | Bare et skript, ingen bygg. |
| 7 | firm-remote-verdict-watch | Nithu0/command-center | Ikke startet | Push-porten. Kopien må ikke kunne endres av det den slipper gjennom. |
| 8 | anbud-modell-vakt | Nithu0/command-center | Ikke startet | Bare et skript. Har egen installer (`_bin/anbud-modell-vakt-install.sh`), som utvides. |

De seks i command-center er rad 3–8. sc-dagsrapport og sc-statusissue teller som én tjeneste i planen fordi de er samme binær. Til sammen blir det 6 PR-er i command-center, eller 5 hvis rad 3 og 4 slås sammen.

## Token Nithu må lage (alle samtidig)

GitHub fine-grained personal access token, eier Nithu0 med mindre noe annet står. Én per tjeneste, så et lekket token bare gir det tjenesten trenger. Utløp: 90 dager, med påminnelse i drift.

| Tjeneste | Type | Repo | Minste rettighet | Hvorfor |
|---|---|---|---|---|
| drift-vakt | Fine-grained, org Solar-Consulting | drift, plattform, Terra, nova | Issues: read/write. Metadata: read. Actions: read/write (bare drift) | Labels og kommentarer på bestillinger (`agent:tatt`). Reserven starter `registervakt.yml` og `frist-oppgaver.yml` med `gh workflow run`. Søket etter Tintuns PR-er trenger Pull requests: read. |
| scopevakt | Ingen GitHub-token, eller fine-grained med Issues: read/write på drift | drift | Avhenger av kallene, som ikke er lest i detalj (UNKNOWN) | Sjekker Maskinporten-scopene. Bruker `gh` til å melde i drift. |
| aslisten-crm-backup | Railway **prosjekt-token** (ikke GitHub) | Railway-prosjektet aslisten-crm, production | Prosjekt-token for ett miljø | Erstatter kontoinnloggingen, som når alle prosjektene. Med en låst kopi trengs ingen git fetch, og dermed ikke noe GitHub-token. |
| sc-bro | Fine-grained, org Solar-Consulting, pluss Railway- og Vercel-token for de prosjektene den deployer | drift (issues), plattform (contents: read) | Issues: read/write på drift. Contents: read på de repoene den leser. Railway-prosjekt-token for plattform og web. Vercel-token med scope til teamet | Fullføringer og kommentarer, og `deploy` av plattform og web. Dette er tjenesten med mest makt. Tokenet bør bare dekke det broen faktisk gjør. |
| sc-dagsrapport og sc-statusissue | Fine-grained, org Solar-Consulting | drift (og søk i org-en) | Issues: read/write på drift. Pull requests og Metadata: read på org-repoene | Kommentar i dagsrapport-issuet og statusissuet. **Valgt 20.11 (infra-1, etter avtale med orchestrator-1):** søket mot Nithu0/command-center tas ut av dagsrapporten. Det er Nithus eget verktøyrepo, og rapporten går til teamet. Ett token holder. Endringen kommer i PR-en for rad 4. |
| slack-vakt | Ingen GitHub-token (fant ingen gh-kall) | – | Slack-boten slik den er | Ingen endring. |
| brain-sync | **Deploy key** med skrivetilgang på Nithu0/tiger-brain (ikke et token) | tiger-brain | Skrive bare til det ene repoet. Branch protection hindrer `main` | Erstatter gh credential helper for push av `sync/<host>`. |
| firm-remote-verdict-watch | Fine-grained | Repoene jobbene pusher til (UNKNOWN, liste trengs fra executor-oppsettet) | Contents: read/write, bare på de repoene | Push-porten pusher jobbens gren. |
| anbud-modell-vakt | Railway **prosjekt-token** | Railway-prosjektet anbud, production | Prosjekt-token for ett miljø | `railway ssh` mot prod-Postgres for lesing. |

## Det Nithu må gjøre (samlet)

1. Ja eller nei til å stoppe og avregistrere `github-runner.service`.
2. Lage tokenene i tabellen over. Når de er laget, setter infra-1 dem inn uten å skrive ut verdiene (nano eller `--stdin`).
3. Ikke noe annet før det. PR-ene for låste kopier kan merges uten nye token.

## Usikkert

- Hvilke repoer verdict-watch pusher til.
- Hvilke gh-kall scopevakt gjør.
- Avklart: et fine-grained token har én eier. Derfor er søket mot Nithu0/command-center tatt ut av dagsrapporten (se tabellen).
