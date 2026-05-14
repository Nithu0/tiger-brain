---
tags: [career, job-search, strategy, scraping]
type: strategy
status: in-progress
created: 2026-05-14
---

# Job-Scrape-Strategy

Strategi for automatisert leads-innsamling for [[Active-Job-Search-MOC]]. Definerer
**hva** som skrapes, **hvor ofte**, og **med hvilke filtre**. Feasibility-rapport
per kilde leveres separat til `_decisions/` (vises av annen agent).

> **Operasjonell konfigurasjon** ligger i koderepo:
> `/home/nithu/code/Søking fulltid/agent/config.yaml` +
> `/home/nithu/code/Søking fulltid/profil/keywords.md`. Denne noten holder
> *strategien* — hvorfor, ikke hvordan.

## Kilder

| Kilde | Type | Status | Frekvens | Notater |
|---|---|---|---|---|
| **arbeidsplassen.no** (NAV) | Åpent API | Implementert | Daglig | Hovedkilde Norge; ingen auth for søk; ren JSON-respons |
| **finn.no** | HTML-scrape | Implementert | Daglig | Volumkilde Norge; CSS-selektorer kan endre seg |
| **LinkedIn Jobs** | Auth-API + scrape | Ikke implementert | Daglig (lagrede søk) | ToS-vurdering nødvendig; foreløpig manuell + lagrede søk |
| **EURES** | Åpent API | Ikke implementert | Ukentlig | EU-jobber; relevant for Irland/Norden/EU-tier |
| **indeed.com** | HTML-scrape | Ikke implementert | Lav prio | Duplikat med finn.no for Norge |
| **Bedrifts-karrieresider** | RSS/scrape | Manuell | Ukentlig | Equinor, SINTEF, Elkem, Hydro, Aker, Morrow, Beyonder, Freyr, Karbon, Cambridge Quantum, Microsoft Norge — egne scrapere per side |
| **Y Combinator Work@Startup** | Auth-API | Vurder | Månedlig | Hvis utvider til startup-EU/US |
| **AngelList / Wellfound** | Auth-API | Vurder | Månedlig | Hvis utvider til startup-EU/US |

## Frekvens og scheduling

- **Daglig (07:00 lokal tid)**: arbeidsplassen.no + finn.no via `agent/daily.py`
- **Ukentlig (søndag 18:00)**: EURES + bedrifts-karrieresider (manuell sjekk + scrape)
- **Ad-hoc**: LinkedIn (når notifikasjoner fra lagrede søk kommer)

## Keyword-strategi

Master-liste i `profil/keywords.md`. Hovedklynger:

### Cluster A — ML/AI/data science (primær, ny retning)

- ML engineer, machine learning engineer, MLE
- data scientist, applied scientist
- MLOps engineer, ML platform engineer
- research engineer (Anthropic/OpenAI-tier)
- AI engineer, AI solutions engineer
- NLP engineer
- computer vision engineer

### Cluster B — Materials informatics (bro-rolle, primær)

- materials informatics
- computational materials science
- materials genome
- high-throughput screening
- DFT (density functional theory)
- atomistic simulation
- molecular dynamics
- ML for materials
- AI for chemistry

### Cluster C — Energi-tech (primær)

- batteriingeniør, battery engineer
- hydrogen engineer, fuel cell engineer
- brenselcelle
- elektrokjemi, electrochemistry
- solcelle, PV engineer
- CCS (carbon capture)

### Cluster D — Klassisk ingeniør (sekundær)

- materialteknolog, materials engineer
- R&D engineer, utviklingsingeniør
- testingeniør, karakteriseringsingeniør
- prosessingeniør, prosjektingeniør
- QA/QC engineer
- field service engineer, felt-ingeniør
- graduate program, trainee, nyutdannet ingeniør

### Cluster E — Teknisk salg (tertiær, bygger på Verisure)

- salgsingeniør, sales engineer
- applications engineer
- solutions engineer
- product specialist
- technical sales

## Match-scoring

- **Score 0–100** per treff. Detaljer i `agent/match_score.py`.
- **Boost**: cluster A/B/C-treff + Norge-tier-1 lokasjon + graduate-signaler
- **Penalty**: 5+ år erfaring krav, PhD krav, stop-ord (`profil/keywords.md`)
- **Cutoff**: append i xlsx hvis score ≥40; auto-draft hvis ≥75

## Geografi-filter

Tier-system fra `profil/preferences.md`. Sammendrag:

1. Norge (Trondheim, Oslo, Bergen, Stavanger, Kongsberg, Drammen) — primær
2. Irland (Dublin, Cork)
3. Norden
4. UK
5. EU ellers + remote-EU
6. Resten av verden (kun eksepsjonelt)

## Dedup-strategi

Match på (tittel × bedrift × lokasjon) + URL. Eldre treff *kan* re-surface hvis
status er `Avslag` eller `Arkivert` (gjelder andre stillinger i samme bedrift).

## Risiko + ToS-vurdering

- **finn.no scraping**: ingen offisiell ToS-godkjenning. Lav volum (max_pages=3),
  rate-limit + user-agent header. Akseptabel risiko for personlig bruk.
- **LinkedIn scraping**: high-risk; bruker IKKE — kun manuell + lagrede søk-varsler.
- **NAV / arbeidsplassen.no**: åpent API, eksplisitt for offentlig bruk. OK.
- **EURES**: åpent API for EU-jobber. OK.

## Pending feasibility-rapport

> En annen agent skriver detaljert feasibility-rapport til:
> `~/Obsidian/Brain/_decisions/2026-05-14-job-scrape-feasibility.md`
> (eller tilsvarende dato). Den dekker:
>
> - Per-kilde teknisk vurdering (auth-krav, rate-limits, struktur-stabilitet)
> - ToS-vurdering per kilde
> - Anslag på treff-volum per uke
> - Anbefalt prioritering for implementering
>
> Lenkes herfra når den er på plass.

## Neste skritt

- [ ] Implementere `agent/daily.py` end-to-end (fase 2 fra `Søking fulltid/README.md`)
- [ ] Legge til EURES-scanner (`agent/scan_eures.py`)
- [ ] Sette opp scheduled task (cron / Windows Task Scheduler) for 07:00 daglig kjøring
- [ ] Implementere LinkedIn lagrede søk-mottak (email-parser?)
- [ ] Bygge `crm/app.py` Streamlit-app (fase 3)

## Relaterte noter

- [[Active-Job-Search-MOC]]
- [[Career-MOC]]
- [[Interview-Prep-Workflow]]
- [[Job-Search-Status]]

---

Sist oppdatert: 2026-05-14.
