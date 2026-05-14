---
tags: [playbook, AS, spor-A, inntekt]
date: 2026-05-14
status: aktiv
owner: operator
review-cadence: ukentlig
related: [AS-MOC, Inntekt-Strategier-Research, Regnskap-Runbook]
---

# Spor A — Konsulent-playbook

## TL;DR

Spor A (ML/AI-konsulent for norske SMB) er primær inntektsstrategi mai-september 2026. Mål for 12-ukers vindu (uke 20-32): signere første kunde innen uke 28, levere første oppdrag før AS-launch-fokus i september, og ha 1 skriftlig case-study før Q4. KPI-fokus: outreach-volum og reply-rate uke 1-4, deretter close-rate og månedsinntekt.

Artefakter ligger i `/home/nithu/code/AS/inntekt-spor-A/`. Operasjonell utførelse går via denne playbooken; statiske maler (pitch, e-post, prising) leves der.

---

## Uke 1 (uke 20, 2026 — denne uka)

**Mål: alle go-to-market-artefakter finalisert og synlige.**

- [ ] Les `pitch.md` høyt. Hvis noe rasler, finpuss. Print 1 A4.
- [ ] Velg LinkedIn-headline-variant (anbefaling: Variant 2 business-tung fra `linkedin-headline.md`). Oppdater LinkedIn-profil samme dag.
- [ ] Oppdater LinkedIn "About"-seksjon med 3-tjeneste-beskrivelse fra `pitch.md`.
- [ ] Lag tom Google Sheet eller behold lokal CSV — kopier struktur fra `lead-list-template.csv`. Header-rad + 5 rader klar.
- [ ] Identifiser og kvalifiser 30 målbedrifter:
  - 10 fra NTNU-alumninett (LinkedIn-søk: "NTNU" + "Trondheim" + "CTO/COO/teknisk")
  - 10 fra Næringsforeningen i Trondheimsregionen (offentlig medlemsliste)
  - 5 fra Innovasjon Norge-mottakere (offentlig database, 2023-2025)
  - 5 fra Norsk Industri-medlemslisten
- [ ] Sjekk om Toptal-screen (Spor F-beredskap) bør startes parallelt. Hvis ja, send søknad denne uka.
- [ ] Bestem: bruker du `pitch.md` som PDF-vedlegg, eller embedded i e-post? Sannsynligvis embedded uke 1-4, PDF når du har signatur-graff.

---

## Uke 2-4 (uke 21-23)

**Mål: 15 outreach sendt, 5 svar, 2 intro-samtaler, første audit-tilbud ute.**

### Ukentlig rytme
- **Mandag**: send 5 nye outreach (veksle Variant 2/3 fra `email-template.md`)
- **Tirsdag-torsdag**: ta intro-samtaler ettersom de bookes
- **Onsdag**: følg opp uke-1-utsendelser uten svar
- **Fredag**: oppdater lead-CSV, logg ukens KPI-er nederst i denne playbooken

### Konkrete deliverables uke 2-4
- [ ] 15 outreach sendt totalt (5/uke)
- [ ] 3 warm intro-samtaler gjennomført (krever lavere outreach-volum hvis intros kommer fra eksisterende nettverk)
- [ ] Første AI-audit-tilbud sendt skriftlig til prospect (bruk `services.md` + `pricing.md`)
- [ ] Posisjons-blogg-post #1 publisert på Substack (engelsk eller norsk). Anbefalt tema: "What I wish Norwegian SMBs asked before buying their first AI tool"
- [ ] Sett opp Fiken (eller alternativ) — test med en dummy-faktura så systemet er klar når første kunde signerer

### Sjekkpunkt slutt uke 4
Reply-rate < 10 %? Revurder subject lines og personlig tilpasning. Reply-rate > 25 %? Hold kursen.

---

## Uke 5-8 (uke 24-27)

**Mål: signere første kunde, starte levering, holde tempo i outreach.**

- [ ] Første kontrakt signert (mål: uke 6-7)
- [ ] 20 nye outreach sendt (5/uke uke 5-8)
- [ ] Levere første oppdrag (mest sannsynlig audit eller liten dashboard-jobb)
- [ ] Skrive case-study fra første leveranse (anonymisert hvis kunde krever). Lagre i `/home/nithu/code/AS/inntekt-spor-A/case-studies/` (opprett mappe da).
- [ ] Be om skriftlig testimonial fra første kunde
- [ ] Vurder prisøkning: hvis close-rate > 50 % på første 4 tilbud, juster timepris-bånd opp 100-200 kr
- [ ] Substack-post #2 publisert

### Master-thesis-kollisjon
Thesis-deadline juni 2026 — uke 24-25 er rødt vindu. Ikke book leveranse-deadlines i den perioden. Kommuniser ærlig at "leveranse starter uke 26".

---

## Uke 9-12 (uke 28-31, sommerprep)

**Mål: brand-bygging, andre engagement, refleksjon.**

- [ ] Andre kunde signert (mål: uke 10)
- [ ] Substack-post #3-4 publisert
- [ ] Norsk LinkedIn-poster: 1 post/uke med faglig vinkel (totalt 4)
- [ ] Refleksjon-notat: hva fungerer / hva fungerer ikke? Bør pricing endres? Bør tjeneste-katalogen smalnes inn?
- [ ] Justere artefakter (pitch, headlines, e-post) basert på 12-ukers data
- [ ] Forberede AS-launch september 2026 (admin-detaljer i `AS-MOC.md`)

### Beslutnings-punkt uke 12
- 0 signerte: aktiver Spor F (Toptal) som hovedspor, behold Spor A som sekundær
- 1 signert: hold kursen, fortsett samme cadence
- 2+ signerte: vurder rate-økning og smalere posisjonering

---

## KPI-er

Logg hver fredag. Bruk strukturert tabell nedenfor (eller migrer til Sheet hvis nyttig).

| Uke | Outreach sendt | Svar (alle) | Intro-samtaler | Tilbud sendt | Signert | Måneds-inntekt (kr eks. MVA) |
|---|---|---|---|---|---|---|
| 20 | | | | | | |
| 21 | | | | | | |
| 22 | | | | | | |
| 23 | | | | | | |
| 24 | | | | | | |
| 25 | | | | | | |
| 26 | | | | | | |
| 27 | | | | | | |
| 28 | | | | | | |
| 29 | | | | | | |
| 30 | | | | | | |
| 31 | | | | | | |

### Avledede KPI-er
- **Reply-rate** = svar / outreach sendt. Mål > 15 %.
- **Intro-rate** = intro-samtaler / outreach sendt. Mål > 8 %.
- **Close-rate** = signert / tilbud sendt. Mål > 30 %.
- **Avg deal-size** = signert verdi / antall signerte. Mål > 40k.

---

## Risikoer og mitigeringer

| Risiko | Sannsynlighet | Impact | Mitigering |
|---|---|---|---|
| Thesis-deadline-kollisjon juni 2026 | Høy | Høy | Ikke book leveranse uke 24-25. Kommuniser kapasitet ærlig. Hard 5 t/uke-tak i thesis-vinduet. |
| Salg-fatigue (5 outreach/uke føles som strafffearbeid) | Medium | Medium | Tids-box til 1 time mandag formiddag. Ikke send på dårlige dager — bygg da heller maler. Bytt format hver 4. uke (e-post → DM → telefon). |
| Underprising på første oppdrag ("bare for å få det første") | Høy | Høy | Hard regel: aldri under 800 kr/t. Heller mindre scope enn lavere rate. Discount kun mot motytelse (referanse/case-study/volum). |
| Scope creep — PoC blir 3-mnd-prosjekt | Høy | Høy | Skriftlig scope-doc før hvert oppdrag. Change-request-prosess kommunisert ved oppstart. |
| Ingen response på outreach uke 1-4 | Medium | Medium | Etter 15 utsendelser uten svar: revurder subject lines, personlig tilpasning, og målgruppe. Hvis fortsatt 0 etter 30: pivoter melding eller målgruppe. |
| MVA-blindsone (passer 50k uten å være registrert) | Lav | Medium | Forhåndsregistrer MVA hvis 50k omsetning er sannsynlig innen 12 mnd. Sjekk med regnskapsfører. |
| Burnout (Verisure + thesis + konsulent + innhold) | Høy | Høy | Regel: ingen ny aktivitet etter kl 21. Faste hviledager (søndag full off). Ukentlig sjekk-inn med seg selv: "hvordan ligger jeg an?" |
| Verisure-konflikt med konsulent-virksomhet | Lav | Kritisk | Sjekk ansettelseskontrakt for bi-virksomhets-klausul før første kunde. Hvis tvil — spør HR diskret. |

---

## Lenker

- Artefakter (lokal kode-mappe): `/home/nithu/code/AS/inntekt-spor-A/`
  - `pitch.md` — 1-siders blurb
  - `linkedin-headline.md` — 5 headline-varianter
  - `email-template.md` — 3 cold outreach-maler
  - `lead-list-template.csv` — CSV-mal m. 5 eksempel-rader
  - `services.md` — tjeneste-katalog (4 tjenester)
  - `pricing.md` — rate-kort + faktureringsrytme
  - `README.md` — hvordan bruke
- Research: `[[Inntekt-Strategier-Research]]`
- AS-administrasjon: `[[AS-MOC]]`
- Regnskap: `[[Regnskap-Runbook]]`
- Skatt: `[[Skatt-Notater]]`

---

## Logg

- **2026-05-14**: Playbook opprettet. Spor A formelt aktivert som primær inntektsstrategi. Artefakter levert til `/home/nithu/code/AS/inntekt-spor-A/`.
