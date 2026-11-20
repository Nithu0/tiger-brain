# Logging-oversikt, Solar Consulting (forslag til Alper)

Dato: 2026-11-20. Laget av infra-1s hjelper. Kun lesing: ingen link i delte kataloger, ingen variabler lest, ingen endringer.

Merking: **MÅLT** = lest fra systemet i dag. **DOK** = fra leverandørens dokumentasjon (hentet i dag). **ASSUMPTION** = antakelse. **UNKNOWN** = kunne ikke måles.

## Tabell

| Tjeneste | Hvor loggen ligger | Hvordan lese den | Oppbevaring | Kilde |
|---|---|---|---|---|
| Railway `anbud` (crm, worker, Postgres) | Railway, deploy-/build-/runtime-logger per tjeneste | Dashbord, eller `railway logs` i en katalog som er linket til prosjektet (ikke i delt katalog) | Etter plan: Free 3 d, Trial 7 d, Hobby 7 d, Pro 30 d, Enterprise opptil 90 d. Hvilken plan workspace «Solar Consulting» har: UNKNOWN (CLI viser det ikke) | DOK docs.railway.com/reference/logging; MÅLT `railway list` |
| Railway `plattform` (web, preview-web, preview-idp, 2 x Postgres, miljøer preview + production) | Som over | Som over | Som over | MÅLT `railway list --json` |
| Railway `solarlabs` (motor) | Som over | Som over | Som over | MÅLT |
| Railway `aurora` (aurora, Postgres), `lovmotor-vurdering` (vurdering) | Som over | Som over | Som over | MÅLT |
| Railway-prosjekter som trolig ikke er SC: `test`, `motivated-strength`, `pretty-perfection`, `acceptable-adaptation`, `empowering-wonder`, `laudable-communication` | Som over | Som over | Som over. ASSUMPTION: flere er personlige/eksperimenter (navn tyder på det). Alper bør avgjøre om de skal med eller ryddes | MÅLT `railway list` |
| Vercel (team `solar-consulting-as`): veldora-web, solarlabs, solarlabs-forslag, anbud-veldora, renseri, fellesfat, lavera-site | Vercel, runtime-logger per prosjekt og deployment. Build-logger hører til deploymenten | Dashbord (Logs), `vercel logs <url>` | Runtime-logger: Pro 1 dag, Pro med Observability Plus 30 dager (14 sammenhengende dager synlig). Teamet er på **Pro** (MÅLT). Om Observability Plus er slått på: UNKNOWN. Build-logger: UNKNOWN | DOK vercel.com/docs/runtime-logs; MÅLT `vercel project ls`, `vercel api /v2/teams` |
| GitHub Actions, org Solar-Consulting (plan Team): drift, nova, solarlabs, Terra, plattform, horizon, aurora, polaris (alle private, ingen arkivert) | GitHub, per workflow-kjøring. Artefakter lagres samme sted | Actions-fanen, `gh run view --log`, `gh run download` | **90 dager** i alle 8 repoer (MÅLT, `maximum_allowed_days` = 90). Privat repo kan i følge dokumentasjonen settes til opptil 400 dager, men API-et tillater 90 nå. Org-nivå: UNKNOWN (krever org-admin / `admin:org`, fikk 403) | MÅLT `gh api repos/Solar-Consulting/<repo>/actions/permissions/artifact-and-log-retention`; DOK docs.github.com (retention) |
| GitHub self-hosted runner (`github-runner.service`, PC-en) | `~/actions-runner/_diag/` (Worker_*.log, SelfUpdate_*) + journald | `ls ~/actions-runner/_diag`, `journalctl --user -u github-runner` | Runneren rydder selv i `_diag`. Tid: UNKNOWN. Eldste Worker-logg i dag er 14.10 | MÅLT filliste |
| Azure / Entra ID (tenant SolarConsulting854) | Entra: Sign-in logs og Audit logs i Entra-portalen | Portal: Entra ID > Monitoring. Graph-API for sign-ins gir 403 (krever premium) | Tenanten har **ikke premium-lisens** (MÅLT, Graph-feil `NonPremiumTenant`). Da er innloggings- og revisjonslogger **7 dager** (DOK). Ingen diagnostikkinnstilling mot Log Analytics funnet på abonnementet (ingen treff ved liste) | MÅLT `az rest`; DOK learn.microsoft.com Entra data retention |
| `anbud-vakt.service` (PC) | `~/.local/state/anbud-vakt/vakt.log` (121 KB), `state.json`, `vercel-follow.log`. Også journald | `tail -n 100 ~/.local/state/anbud-vakt/vakt.log`; `systemctl --user status anbud-vakt` | Ingen rotasjon: filen vokser til disken er full. Ingen logrotate-regel for brukerfiler (MÅLT: bare systemregler i `/etc/logrotate.d`) | MÅLT unit-fil og filstørrelse |
| `anbud-modell-vakt.service` (PC) | `~/.local/state/anbud-modell-vakt/vakt.log` (268 KB), `state.json` | Som over | Ingen rotasjon | MÅLT |
| `drift-vakt.service` + timer (hvert 5. min) | journald (ingen egen loggfil). I tillegg én linje til `~/Obsidian/Brain/00-firm-bus/feed.md` ved treff | `journalctl --user -u drift-vakt --since today` | journald, se neste rad. feed.md er append-only og synkes via Obsidian Git | MÅLT unit-fil og skript |
| `sc-bro`, `sc-statusissue`, `sc-dagsrapport`, `scopevakt` (oneshot + timer) | journald (ingen `StandardOutput`-linje i unit) | `journalctl --user -u sc-bro --since "1 hour ago"` | journald, se neste rad | MÅLT unit-filer |
| `litestream.service` (SQLite-replikering) | journald, identifikator `litestream` | `journalctl --user -t litestream` | journald | MÅLT unit-fil |
| `aslisten-crm-backup*` (backup + alder + varsel) | journald | `journalctl --user -u aslisten-crm-backup` | journald. **Alle tre enhetene står som `failed` akkurat nå** (MÅLT). Ikke undersøkt videre, ligger utenfor oppdraget | MÅLT `systemctl --user list-units` |
| journald på PC-en (gjelder alt over som ikke har egen fil) | `/var/log/journal/` (persistent) | `journalctl --user ...` | Ingen egen konfig (`/etc/systemd/journald.conf` har ingen verdier, ingen `.d`-katalog). Standard: størrelsesgrense, ingen tidsgrense. Bruk i dag 204 MB. **Eldste boot i journalen er 15.11, altså ca. 5 dager bakover** (MÅLT). Hvorfor ikke lenger: UNKNOWN. ASSUMPTION: WSL tømmer/rullerer ved omstart eller størrelse | MÅLT `journalctl --disk-usage`, `--list-boots` |

Merk: PC-en kjører også ikke-SC-tjenester (brain-*, cc-*, firm-remote-*, hermes, omniroute). De er utelatt.

## Forslag

1. **Sett journald til eksplisitt oppbevaring** (`SystemMaxUse` og `MaxRetentionSec=30day` i en drop-in under `/etc/systemd/journald.conf.d/`). I dag er det ca. 5 dager og tilfeldig. Kjører som root og er operatør-gated, derfor bare forslag. Tilbakerulling: fjern drop-in-filen og restart `systemd-journald`.
2. **Rotasjon for `vakt.log`** i begge vakt-katalogene (logrotate-regel i brukerkatalog eller `StandardOutput=journal`). Nå vokser de uten grense, og 268 KB er allerede mye for noe som bare melder avvik.
3. **Eksporter Railway- og Vercel-logger før de forsvinner.** Railway og Vercel (uten Observability Plus) holder fra 1 dag til 30 dager. For hendelser som oppdages etter en helg er 1 dag Vercel-logg for lite. Sjekk først hvilken Railway-plan workspacet har (UNKNOWN her), og om Vercel Observability Plus er på. Vurder en log drain til én felles mottaker.
4. **Entra: 7 dagers innloggingslogg uten premium.** For revisjon av tilganger (scopevakt, Azure-tilganger) er det kort. Alternativer: P1-lisens, eller månedlig manuell eksport. Alper bør avgjøre behov før kostnad vurderes.
5. **Sett GitHub-oppbevaring bevisst.** 90 dager er standard og stemmer i alle 8 repoer, men private repoer kan i følge dokumentasjonen gå opp til 400. Org-nivået kunne ikke leses (krever org-admin). Alper (eller en org-admin) bør sjekke org-innstillingen og velge tall som passer ønsket revisjonsspor.

Bonus, ikke et tall: de seks Railway-prosjektene som trolig ikke er SC (se tabell) bør enten få eier eller ryddes, ellers vet ingen hvem som eier loggene deres. Sletting er operatørens avgjørelse.

## Hva som ikke ble gjort

- Ingen `railway link` i delte kataloger, ingen `railway variable`. Kun `railway list --json` (navn på prosjekter, miljøer, tjenester).
- Railway-plan: ikke tilgjengelig via CLI. Tallene i tabellen er plan-grenser, ikke målt faktisk oppbevaring.
- Faktisk eldste logglinje per Railway/Vercel-tjeneste er ikke målt.
