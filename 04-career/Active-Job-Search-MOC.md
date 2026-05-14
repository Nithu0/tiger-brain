---
tags: [moc, career, job-search, active]
type: moc
status: active
created: 2026-05-14
---

# Active-Job-Search-MOC

Map of Content for **aktiv fulltids jobbsøking** (2026 → september 2026 oppstart).
Hub som lenker det daglige operasjonelle (kode-repo) til det strategiske (brain).

> **Status**: active (flippet fra `not-searching` 2026-05-14). Master ferdig juni 2026,
> tilgjengelig fulltid september 2026.

## Status-bar

| Metrikk | Verdi | Sist oppdatert |
|---|---|---|
| Leads åpne | 0 | 2026-05-14 |
| Søknader sendt totalt | 70 (historisk, før active-flipp) | 2026-05-14 |
| Søknader sendt siste 30 dager | 0 | 2026-05-14 |
| Response rate (siste 30 dager) | n/a | 2026-05-14 |
| I intervju-fase | 0 | 2026-05-14 |
| Tilbud | 0 | 2026-05-14 |

> Oppdater status-bar ukentlig (søndag-rutine).

## Kode-repo + arbeidsmappe

- **Hovedrepo**: `/home/nithu/code/Søking fulltid/`
- **CLAUDE.md**: `/home/nithu/code/Søking fulltid/CLAUDE.md` — prosjekt-kontekst for agent
- **Workflow-dokumentasjon**: `/home/nithu/code/Søking fulltid/docs/workflow.md`
- **CRM**: `leads/stillinger.xlsx` (Excel med dropdowns); Streamlit-app planlagt i `crm/`
- **Scanner-kode**: `agent/` (arbeidsplassen.no + finn.no)

## Maler

- [Søknadsmal](/home/nithu/code/Søking fulltid/maler/soknad-template.md)
- [CV-master](/home/nithu/code/Søking fulltid/maler/cv-template.md)
- [Lead-mal](/home/nithu/code/Søking fulltid/leads/templates/lead-template.md)
- [Intervju-prep-mal](/home/nithu/code/Søking fulltid/intervju/prep-template.md)

## Profil-anker

- [Profil-fil](/home/nithu/code/Søking fulltid/profil/profile.md) — AI-lesbar masterprofil
- [Preferanser](/home/nithu/code/Søking fulltid/profil/preferences.md) — geo, rolle, deal-breakers
- [Keywords](/home/nithu/code/Søking fulltid/profil/keywords.md) — søkeord agenten bruker

## Strategi-noter (denne mappen)

- [[Job-Scrape-Strategy]] — hvilke kilder skrapes, hvor ofte, med hva
- [[Interview-Prep-Workflow]] — T-7/T-3/T-1/T-0 + post-debrief
- [[Career-MOC]] — overordnet karriere-hub
- [[Job-Search-Status]] — status-flagg (skal flippes til `active` når aktiv start)
- [[Resume-Updates]] — hva som er stale i CV-en
- [[Network]] — folk å holde varme
- [[Skills-To-Develop]] — gap-list som mapper til [[Learning-MOC]]
- [[Long-Term-Vision]] — 5–10 år horisont

## Pågående søknader (lever-status)

> Oppdateres når aktive saker eksisterer. Lenke til `utkast/` og `sendt/` per sak.

| Bedrift | Rolle | Status | Sendt | Neste-steg | Lead-fil |
|---|---|---|---|---|---|
| _(ingen pågående pr 2026-05-14)_ | | | | | |

## Pipeline-stadier

| Stadium | Antall | Mål |
|---|---|---|
| Lead (Ny) | 0 | — |
| Vurderer | 0 | — |
| Utkast | 0 | — |
| Søknad sendt | 0 | 20/mnd |
| Intervju 1 | 0 | 2/mnd |
| Intervju 2 / case | 0 | 1/mnd |
| Tilbud | 0 | 1 før august 2026 |
| Avslag | 0 | (logg lessons) |

## Daglig / ukentlig rutine

- **Daglig (30 min, morgen)**: kjør scanner, les dagsrapport, vurder Ny-rader,
  finpuss og send utkast. Detaljer i `docs/workflow.md`.
- **Ukentlig (60 min, søndag)**: status-review, lessons learned, pipeline-hygiene,
  keyword-tuning, oppdater denne MOC-en sin status-bar.

## Cross-domain

- [[Career-MOC]] — karriere-hub (passive vs. active modus)
- [[Resume-Updates]] — hva må oppdateres
- [[Thesis-MOC]] — masterprosjekt = primær portfolio-asset
- [[Skills-To-Develop]] — gap-list for å bli mer attraktiv
- [[Network]] — folk som kan åpne dører
- [[Learning-MOC]] — kurs/sertifiseringer som dekker gap

## Konvensjoner

- Aldri lim inn personnummer, adresse eller lønnstall i brain-vault (delt repo)
- Bedriftsnavn + stillingstittel er OK i brain — søknader er semi-offentlige
- Per-søknad-utkast og CV-versjoner lever i `/home/nithu/code/Søking fulltid/utkast/`,
  **ikke** i brain
- Brain holder strategi, oversikt, status — ikke operasjonelle dokumenter

## Mål for runden

- **Antall søknader**: 20+ relevante/mnd (mai–august 2026)
- **Response rate**: ≥30 % (bench fra historikken)
- **Intervjuer**: 2+/mnd steady-state
- **Tilbud**: minst ett konkret tilbud før utløp av august 2026
- **Start**: september 2026

---

Sist oppdatert: 2026-05-14.
