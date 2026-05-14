---
title: NAV feed verifikasjon — endpoint og auth-modell
date: 2026-05-14
author: claude (verify subagent)
status: verified
tags: [decision, job-scraper, nav, verification]
domain: career
project: jobsoking-pipeline
related:
  - "[[2026-05-14-job-scrape-feasibility]]"
  - "[[job-scraper-runbook]]"
---

# TL;DR

Eksisterende `config.yaml` peker paa **feil endpoint**. Korrekt endpoint krever **bearer-token** (i motsetning til hva config-kommentaren paastod om "ingen auth"). Public-token er gratis tilgjengelig.

---

# Funn

## 1. Feil endpoint i opprinnelig config

```
config.yaml: https://arbeidsplassen.no/public-feed/api/v1/ads
  -> 301 Moved Permanently
  -> https://arbeidsplassen.nav.no/public-feed/api/v1/ads
  -> 404 Not Found
```

`/public-feed/`-stien finnes ikke i 2026. Den korresponderer med gamle `pam-public-feed` som ble avviklet 1. mai 2025.

## 2. Korrekt endpoint krever bearer-token

```
GET https://pam-stilling-feed.nav.no/api/v1/feed?size=1
  uten Authorization:                 -> 401 Unauthorized
  med  Authorization: Bearer <token>: -> 200 OK + JSON-Feed
```

Config-kommentaren "ingen auth" var altsaa feil — token er obligatorisk.

## 3. Public-token er gratis og selvbetjent

```
GET https://pam-stilling-feed.nav.no/api/publicToken
  -> text/plain body med "Current public token for Nav Job Vacancy Feed:" + JWT
```

Token er en HS256-JWT med `exp`-claim. Roterer paa irregulaere intervaller — koden maa haandtere 401 ved aa hente ny token.

## 4. Respons-format er JSON Feed v1.0

Top-level keys: `version, title, home_page_url, description, feed_url, id, next_url, next_id, items`.

Per stilling i `items[]`: `id, url, title, content_text, date_modified, _feed_entry`.

`_feed_entry` inneholder NAV-spesifikk metadata: `businessName, municipal, sistEndret, status, title, uuid`.

---

# Konsekvenser

1. **BUILD-4** maa rette `config.yaml`:
   - Endre `scanners.arbeidsplassen.feed_url` fra `arbeidsplassen.no/public-feed/api/v1/ads` til `pam-stilling-feed.nav.no/api/v1/feed`
   - Fjern feilaktig "ingen auth"-kommentar
   - Legg til key `scanners.arbeidsplassen.api_token` (initialt tom; fylles av operatoer eller automatisk public-token-hent)

2. **BUILD-1** (agent-kode) maa:
   - Sende `Authorization: Bearer <token>` paa alle kall
   - Implementere 401-retry: ved 401, hent ny public-token fra `/api/publicToken`, og retry én gang
   - Parse JSON Feed v1.0 (ikke generisk JSON med "ads"-key)
   - Pagination via `next_url` i responsen

3. **Runbook** dokumenterer manuell token-hent + privat-token-prosedyre.

---

# Verifikasjons-curl-loggen

Komplett curl-output ligger i `~/Obsidian/Brain/_runbooks/job-scraper-runbook.md` seksjon "Live-verifikasjon (2026-05-14)".
