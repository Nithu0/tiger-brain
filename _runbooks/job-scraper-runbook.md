---
title: Job-scraper runbook (NAV pam-stilling-feed)
date: 2026-05-14
author: claude (verify subagent)
status: live-verified
tags: [runbook, job-scraper, soking-fulltid]
domain: career
project: jobsoking-pipeline
related:
  - "[[2026-05-14-job-scrape-feasibility]]"
  - "[[04-career]]"
---

# Formaal

Operatoer-runbook for daglig drift av job-scraperen i `/home/nithu/code/Søking fulltid/agent/`. Dekker forhaandskrav, drift (manuell / cron / systemd-user), tokens, troubleshooting og eskalering.

NB: filer som er BUILD-1 (agent-kode) og BUILD-4 (config.yaml) eies av andre subagenter. Denne runbooken antar at de filene finnes paa rett sted.

---

# Live-verifikasjon (2026-05-14)

Faktiske endpoints og responser, slik de er per i dag.

## Test 1: feilaktig endpoint i opprinnelig config

```
$ curl -sI "https://arbeidsplassen.no/public-feed/api/v1/ads?size=1" \
    -H "Accept: application/json"
HTTP/1.0 301 Moved Permanently
Location: https://arbeidsplassen.nav.no/public-feed/api/v1/ads?size=1
```

```
$ curl -sI "https://arbeidsplassen.nav.no/public-feed/api/v1/ads?size=1" \
    -H "Accept: application/json"
HTTP/2 404
```

Konklusjon: stien `arbeidsplassen(.no|.nav.no)/public-feed/api/v1/ads` finnes ikke i 2026. Det gamle `pam-public-feed` ble avviklet 1. mai 2025 (jf. feasibility-rapport).

## Test 2: korrekt endpoint

```
$ curl -sI "https://pam-stilling-feed.nav.no/api/v1/feed?size=1" \
    -H "Accept: application/json"
HTTP/2 200
content-type: application/json
content-length: 0
```

200 men tom body — fordi auth mangler. GET uten token returnerer 401:

```
$ curl -s "https://pam-stilling-feed.nav.no/api/v1/feed?size=1" \
    -H "Accept: application/json"
{
  "title": "Unauthorized",
  "status": 401,
  "type": "https://javalin.io/documentation#unauthorizedresponse",
  "details": {}
}
```

## Test 3: public token

```
$ curl -s "https://pam-stilling-feed.nav.no/api/publicToken"
Current public token for Nav Job Vacancy Feed:
<JWT-token>
```

(Token-strengen er en JWT signert av NAV. Den lekkes ikke i denne runbooken — hent den selv via kommandoen over.)

## Test 4: authentisert GET — struktur

Top-level keys i JSON-respons:

```
[
  "description",
  "feed_url",
  "home_page_url",
  "id",
  "items",
  "next_id",
  "next_url",
  "title",
  "version"
]
```

Top-level metadata (uten `items`):

```
{
  "version": "1.0",
  "title": "Stillingsfeeden fra arbeidsplassen.no",
  "home_page_url": "https://arbeidsplassen.nav.no",
  "feed_url": "/api/v1/feed/<uuid>",
  "description": "Feed med stillinger fra arbeidsplassen.no - En av Norges største oversikter over utlyste stillinger",
  "next_url": "/api/v1/feed/<uuid>",
  "id": "<uuid>",
  "next_id": "<uuid>"
}
```

Felt per stilling (`items[].`):

```
[
  "_feed_entry",
  "content_text",
  "date_modified",
  "id",
  "title",
  "url"
]
```

Hvor `_feed_entry` inneholder:

```
[
  "businessName",
  "municipal",
  "sistEndret",
  "status",
  "title",
  "uuid"
]
```

Body-innhold av en konkret stilling er ikke gjengitt her (kan inneholde kontaktdata / personopplysninger). Strukturen over er det BUILD-1 trenger for parsing.

Konklusjon: **public bearer-token kreves**. Endpoint i config.yaml maa rettes fra `arbeidsplassen.no/public-feed/api/v1/ads` til `pam-stilling-feed.nav.no/api/v1/feed` (BUILD-4 sin oppgave).

---

# 1. Forhaandskrav

Sjekkliste foer foerste kjoering:

1. [ ] Python 3.11+ tilgjengelig: `python3 --version`
2. [ ] Venv opprettet i agent-mappa: `cd "/home/nithu/code/Søking fulltid/agent" && python3 -m venv .venv`
3. [ ] Venv aktivert: `source "/home/nithu/code/Søking fulltid/agent/.venv/bin/activate"`
4. [ ] Avhengigheter installert: `pip install -r "/home/nithu/code/Søking fulltid/agent/requirements.txt"`
5. [ ] `config.yaml` har Linux-stier og korrekt NAV-endpoint (BUILD-4 sin oppgave — verifiser at `scanners.arbeidsplassen.feed_url` peker paa `https://pam-stilling-feed.nav.no/api/v1/feed`)
6. [ ] `run.sh` er executable: `chmod +x "/home/nithu/code/Søking fulltid/agent/run.sh"`
7. [ ] Output-mappa `/home/nithu/code/Søking fulltid/leads/` finnes
8. [ ] (Valgfritt for V1) NAV public-token caches; (anbefalt for V2) privat token mottatt fra nav.team.arbeidsplassen@nav.no

---

# 2. Daglig drift

## 2a. Manuell kjoering (anbefalt for kalibrering — uke 1-2)

1. Aapne terminal
2. Kjor:
   ```bash
   cd "/home/nithu/code/Søking fulltid/agent" && bash run.sh
   ```
3. Forventet output paa stdout:
   - `[arbeidsplassen] henter feed...`
   - `[arbeidsplassen] X nye annonser`
   - `[match_score] Y annonser over terskel`
   - `[daily] skrev rapport: /home/nithu/code/Søking fulltid/leads/raw/YYYY-MM-DD.md`
4. Sjekk at fila finnes: `ls -la "/home/nithu/code/Søking fulltid/leads/raw/$(date +%F).md"`
5. Aapne fila i Obsidian eller `less` for triage

## 2b. Cron-versjon (enkleste automatisering, men IKKE anbefalt)

Cron er enkel men har naa-kjente svakheter: ingen logg-rotasjon, ingen retry, tester avhengig av $PATH og locale, krever at maskin er paa kl 07.

`crontab -e` og legg til:

```
0 7 * * * cd "/home/nithu/code/Søking fulltid/agent" && /usr/bin/bash run.sh >> /home/nithu/code/Søking\ fulltid/agent/cron.log 2>&1
```

Merk: krever at maskin er paa kl 07. Hvis maskinen er av, hopper kjoeringen over uten retry.

Anbefaling: **bruk systemd-user (2c) i stedet**.

## 2c. Systemd-user (anbefalt automatisering)

Forutsetninger: BUILD-1 har lagd `conductor.service` og `conductor.timer` (sjekket: ligger i `/home/nithu/code/Søking fulltid/agent/`).

1. Opprett systemd-user-mappa hvis den mangler:
   ```bash
   mkdir -p "$HOME/.config/systemd/user"
   ```
2. Symlink unit-filene inn (gir auto-oppdatering naar BUILD-1 endrer dem):
   ```bash
   ln -sf "/home/nithu/code/Søking fulltid/agent/conductor.service" \
          "$HOME/.config/systemd/user/conductor.service"
   ln -sf "/home/nithu/code/Søking fulltid/agent/conductor.timer" \
          "$HOME/.config/systemd/user/conductor.timer"
   ```
3. Reload systemd-user:
   ```bash
   systemctl --user daemon-reload
   ```
4. Enable + start timeren:
   ```bash
   systemctl --user enable --now conductor.timer
   ```
5. Verifiser at timeren er aktiv:
   ```bash
   systemctl --user list-timers conductor.timer
   ```
6. Aktiver lingering slik at timeren kjoerer ogsaa naar du ikke er innlogget:
   ```bash
   loginctl enable-linger nithu
   ```
7. Test ad-hoc kjoering:
   ```bash
   systemctl --user start conductor.service
   journalctl --user -u conductor.service -n 50 --no-pager
   ```

---

# 3. Tokens

## 3a. NAV pam-stilling-feed (eneste kjente kilde som krever token)

Live-test viser at endpointet **krever** bearer-token. Det finnes to alternativer.

### Public token (raskest, godt nok for V1)

Roterer paa irregulaere intervaller — fanges av kode i BUILD-1 via 401-retry + ny token-hent.

Hent token manuelt for verifikasjon:

```bash
curl -s "https://pam-stilling-feed.nav.no/api/publicToken"
```

Hvor operatoer legger token inn (HVIS BUILD-1 ikke henter automatisk fra endpointet):

- **Eksakt fil**: `/home/nithu/code/Søking fulltid/agent/config.yaml`
- **Eksakt key**: `scanners.arbeidsplassen.api_token`
- Eksempel:
  ```yaml
  scanners:
    arbeidsplassen:
      feed_url: "https://pam-stilling-feed.nav.no/api/v1/feed"
      api_token: "eyJhbGciOiJIUzI1NiIs..."  # JWT fra publicToken
  ```

Sikkerhet:
- `config.yaml` skal **ikke** committes til git med levende token. `/home/nithu/code/Søking fulltid/` er allerede git-ignored paa workspace-nivaa (sjekk med `git check-ignore -v ".../Søking fulltid/agent/config.yaml"` hvis git-init senere).
- Public-token er offentlig publisert av NAV, men foelg likevel hygiene-regelen.

### Privat token (anbefalt for produksjon)

Stabil (roterer ikke), eier-spesifikk.

Steg-for-steg:

1. Send e-post til `nav.team.arbeidsplassen@nav.no` med foelgende:
   - Navn + kontakt-e-post
   - Formaal med tilgang ("personlig job-soking-pipeline, ikke kommersielt")
   - Bekreftelse paa at ToS er lest (https://navikt.github.io/pam-stilling-feed/)
   - Forpliktelse til aa fjerne inaktive annonser fra lokalt system
2. Vent paa svar (typisk 3-10 arbeidsdager basert paa NAVs response-tid)
3. Naar token ankommer: legg den i samme key som over (`scanners.arbeidsplassen.api_token`) i `config.yaml`
4. Kommenter ut public-token-fallbacken hvis BUILD-1 har en

## 3b. Andre tokens (LinkedIn, finn.no, Adzuna)

### LinkedIn — ikke aktuelt

LinkedIn Jobs API krever Partner-status (akseptrate <5%, ventetid 6+ mnd). Scraping er ToS-brudd og kan foere til kontosperring. Jf. Proxycurl-saken (juli 2026) hvor LinkedIn vant. **Ingen LinkedIn-token skal legges inn i config.yaml.**

LinkedIn dekkes manuelt via:
- LinkedIn Job Alerts (offisielle e-postvarsler)
- Manuell soeking i nettleser

### finn.no — ikke aktuelt for API

finn.no API krever forretningsforhold privatpersoner ikke har. Lagrede soek + e-postvarsling settes opp **manuelt** i finn.no-portalen — ingen token i config.yaml.

### Adzuna — valgfritt tillegg (V2)

Hvis Adzuna blir lagt til av BUILD-1 senere:

1. Registrer paa https://developer.adzuna.com
2. Hent `app_id` + `app_key`
3. Legg inn i `config.yaml`:
   ```yaml
   scanners:
     adzuna:
       app_id: "<app_id>"
       app_key: "<app_key>"
   ```

---

# 4. Troubleshooting

| # | Symptom | Sannsynlig aarsak | Fix |
|---|---|---|---|
| 1 | 401 Unauthorized fra pam-stilling-feed | Token mangler eller utloept (public-token roterer) | Kjoer `curl -s https://pam-stilling-feed.nav.no/api/publicToken` paa nytt, oppdater `scanners.arbeidsplassen.api_token` i `config.yaml` |
| 2 | 404 Not Found | Feil endpoint (gammelt `pam-public-feed` eller `arbeidsplassen.no/public-feed`) | Rett feed_url til `https://pam-stilling-feed.nav.no/api/v1/feed` |
| 3 | 301 Moved Permanently | Klient foelger ikke redirect (`arbeidsplassen.no` -> `arbeidsplassen.nav.no`) | Sett `allow_redirects=True` i requests, ELLER bytt domene i config |
| 4 | Tom `items[]` i respons | Ingen nye annonser siden forrige polling, eller feil paginering | Sjekk `next_url` — hent neste side. Hvis foerste kall: kanskje feeden er tom i oeyeblikket (sjelden, ~1000/dag) |
| 5 | `pip install` feiler paa Linux med utf-8 i mappenavn | "Søking fulltid" har norsk tegn — paavirker noen verktoey | Bytt cwd til mappa foer `pip install`, eller installer i venv som allerede er aktivert |
| 6 | `run.sh: command not found` eller permission denied | `run.sh` ikke executable, eller WSL-Windows linje-endinger | `chmod +x run.sh && dos2unix run.sh` |
| 7 | `systemctl --user` feiler med "Failed to connect to bus" | Bruker-systemd ikke aktiv (vanlig paa WSL) | Sjekk `pgrep -u $USER systemd`. Paa WSL: aktiver `systemd=true` i `/etc/wsl.conf` og restart WSL. Fallback: bruk cron |
| 8 | Timer kjoerer ikke ved 07:00 | Maskin var av; lingering ikke aktivert | `loginctl enable-linger nithu` for at user-units skal kjoere uten innlogging. Sjekk `systemctl --user list-timers` |
| 9 | XLSX-output kan ikke aapnes / locked | Excel hadde fila aapen sist kjoering | Lukk Excel, slett `~$jobb leads.xlsx` lockfile hvis den finnes |
| 10 | Match-score gir 0 leads daglig | Terskel for hoey, eller keyword-tabell for smal | Senk terskel i `match_score.py` (BUILD-1), eller legg til keywords i config |

---

# 5. Eskaleringsmatrise

| Varighet | Status | Handling |
|---|---|---|
| 1 dag uten output | Mulig token-rotasjon eller transient NAV-feil | Kjoer manuell test (steg 2a). Hvis 401: oppdater public-token. Hvis annet: sjekk journalctl. |
| 2 dager uten output | Indikerer reelt problem | Kjoer `curl -s "https://pam-stilling-feed.nav.no/api/publicToken"` for aa verifisere at NAV-tjenesten er oppe. Aapne `journalctl --user -u conductor.service -n 200 --no-pager`. Logg funn i `~/Obsidian/Brain/04-career/inbox/<dato>-scraper-incident.md` |
| 3+ dager uten output | Eskaler | 1) Send e-post til `nav.team.arbeidsplassen@nav.no` med subject "Public token / feed availability check". 2) Falltilbake til manuell finn.no-soek + LinkedIn Job Alerts. 3) Vurder Apify `finn-no-scraper` som midlertidig kilde. 4) Lag postmortem i `~/Obsidian/Brain/_decisions/<dato>-scraper-outage.md` |
| 7+ dager | Stoerre brudd | NAV-tjenesten kan ha endret seg uten varsel (de avviklet `pam-public-feed` 1. mai 2025). Sjekk https://navikt.github.io/pam-stilling-feed/ for kunngjoeringer. Maa muligens skrive om BUILD-1. |

---

# 6. Daglig review-flyt (etter scraper kjoert)

1. Sjekk inbox-fila for dagen:
   - Primaer: `/home/nithu/code/Søking fulltid/leads/raw/$(date +%F).md`
   - Aapne i Obsidian (vault: `~/Obsidian/Brain`?) eller direkte i VS Code
2. Sortér paa score (hoeyest foerst). Standardtersker:
   - **>= 20**: les noeye, vurder soeknad samme dag
   - **10-19**: kjapp gjennomgang, flytt til triage hvis interessant
   - **< 10**: arkiver (skal egentlig vaere under terskel; hvis det dukker opp her -> juster vekter)
3. For lovende leads:
   - Flytt fil til `/home/nithu/code/Søking fulltid/leads/triage/`
   - Marker checkbox-er i markdown (Les hele, Vurder fit, Generer utkast, Send)
4. For sendte soeknader:
   - Flytt fil til `/home/nithu/code/Søking fulltid/sendt/`
   - Oppdater `jobb leads.xlsx` hvis du foretrekker tabular tracking
5. Arkiver avslag:
   - Flytt fil til `/home/nithu/code/Søking fulltid/leads/archive/`
6. Per uke (foreslaatt fredag):
   - Sjekk om noen keywords gir konsekvent irrelevant treff -> juster `match_score.py` (BUILD-1 sin fil) eller config-keywords
   - Sammenlikne NAV-output med ditt manuelle finn.no/LinkedIn-funn — er det stillinger NAV bommer paa?

---

# 7. Referanser

- Feasibility-rapport: `~/Obsidian/Brain/_decisions/2026-05-14-job-scrape-feasibility.md`
- NAV pam-stilling-feed docs: https://navikt.github.io/pam-stilling-feed/
- Public token endpoint: https://pam-stilling-feed.nav.no/api/publicToken
- Feed endpoint: https://pam-stilling-feed.nav.no/api/v1/feed
- Kontakt NAV-team: nav.team.arbeidsplassen@nav.no
- Agent-kode (BUILD-1): `/home/nithu/code/Søking fulltid/agent/`
- Config (BUILD-4): `/home/nithu/code/Søking fulltid/agent/config.yaml`

---

Sist verifisert: 2026-05-14 (live-curl-test bekreftet endpoint og auth-modell).
