---
tags: [career, job-search, interview, workflow]
type: workflow
status: active
created: 2026-05-14
---

# Interview-Prep-Workflow

Standard forberedelses-flyt for jobbintervju. Strukturen er T-7/T-3/T-1/T-0 + post-debrief.
Mal-versjonen som fylles ut per intervju ligger i:
`/home/nithu/code/Søking fulltid/intervju/prep-template.md`.

> Denne noten er **strategien** — hvorfor flyten er strukturert sånn. Den
> operasjonelle sjekklisten lever i prep-template-malen, som kopieres per
> intervju til `intervju/YYYY-MM-DD-<bedrift>.md`.

## Når intervju er booket

1. Kopier prep-template:
   ```bash
   cp "/home/nithu/code/Søking fulltid/intervju/prep-template.md" \
      "/home/nithu/code/Søking fulltid/intervju/YYYY-MM-DD-<bedrift>.md"
   ```
2. Sett status `Intervju 1` i `leads/stillinger.xlsx`.
3. Oppdater [[Active-Job-Search-MOC]] status-bar.

## T-7 — én uke før

**Mål**: dybdekunnskap om bedriften + folk. Mock-intervju startes.

- Bedrifts-research (60 min): "Om oss", pressemeldinger siste 6 mnd, Glassdoor,
  LinkedIn-side (vekst, postet innhold), 2 konkurrenter identifisert
- Folk-research (30 min): alle intervjueres LinkedIn, felles kontakter,
  én person i samme rolle å spørre
- Rolle-deep-dive: les annonsen 3 ganger, map krav → egne eksempler,
  identifiser 3 svakeste punkter og forbered svar
- Mock-intervju 1: thesis-pitch på 60 sek og 5 min, høyt; 5 STAR-spørsmål

**Output**: 1-siders "cheat sheet" per bedrift med 3 nøkkelmeldinger jeg vil
etterlate.

## T-3 — tre dager før

**Mål**: tekniske drills + STAR-bank klar + spørsmål til dem.

- **Tekniske spørsmål**:
  - ML-rolle: overfitting/regularization, precision/recall/F1, cross-validation,
    valg av modell for thesis-pipelinen, NER-evaluering, deep learning når-ikke
  - MLE-rolle: + system design, deployment (Docker/API/monitoring),
    drift-detection, MLOps grunnleggende
  - Materials/energi: XRD-tolkning, SEM vs. EBSD, DSC/TGA, Li-ion vs.
    solid-state, hydrogen-veier (PEM/alkalisk/SOEC)
  - Sales/applications: konkrete Verisure-eksempler, oversettelse teknisk →
    kunde, tap-eksempel
- **STAR-bank** (6 historier, hver dekker flere temaer): lederskap (Verisure
  Team Lead 150 %), konflikt, læring (thesis-pipeline), feiltagelse, initiativ
  (Nexus), press (Forsvaret/salg-uke)
- **Spørsmål TIL dem** (8–10 ferdige, bruker 3–5 in situ): første 90 dager,
  hva skiller suksess fra ikke, verktøy-stack, KPI-er, faglig utvikling, vekst
  fra graduate til senior

## T-1 — dagen før

**Mål**: praktisk + mental beredskap. Ingen ny læring.

- **Praktisk**: kalenderinvitasjon bekreftet, lenke testet (kamera/mikro
  fungerer), backup-telefonnummer, rolig sted, antrekk klart (smart casual
  default), CV + annonse i fane
- **Mentalt**: 8 t søvn, ingen koffein 4 t før, last review av 3
  nøkkelmeldinger, power pose / 5 min meditasjon

## T-0 — selve dagen

- Logget inn 5 min før
- Vann tilgjengelig
- Telefon på lydløs (men i rommet)
- CV + annonse åpen i fane
- Smil + skuldre tilbake, pust før første spørsmål
- 30-sek småprat-anker klar (vær, helg)

**Under intervju**: noter spørsmål + egen reaksjon + deres reaksjon i prep-fila.
Sjekk at jeg har: nevnt thesis konkret, nevnt 1 ferdighet fra annonsen med
eksempel, stilt 3+ spørsmål, notert neste-steg.

## Post-intervju — samme dag

**Mål**: debrief + takkemail før kveld.

1. **Debrief** (innen 1 time etter intervjuet, mens det er ferskt):
   - Hva gikk bra? Hva gikk dårlig?
   - Overraskende spørsmål → legg i banken
   - Lesning av interesse-nivå per intervjuer (1–5)
   - Min interesse-nivå (1–5)
   - Røde flagg?
2. **Takkemail** innen 24 timer, separat per intervjuer
3. **Lead-fil oppdatert** (status, dato, neste-steg)
4. **CRM oppdatert** i `leads/stillinger.xlsx`
5. **Brain**: oppdater [[Active-Job-Search-MOC]]
6. **Hvis avslag**: logg lessons learned i [[Job-Search-Status]]
7. **Hvis videre**: notér tema som ikke ble besvart godt, ting de ba meg
   forberede, folk å snakke med før neste runde

## Sjekkliste-overlevering

Etter post-debrief, sjekk at:

- [ ] Lead-fil oppdatert
- [ ] CRM xlsx oppdatert
- [ ] [[Active-Job-Search-MOC]] status-bar oppdatert
- [ ] Takkemail sendt
- [ ] Neste action satt opp (oppfølging om 7 dager hvis stille)

## Hvis tilbud

Egen flyt — se separat note: TBD (Offer-Evaluation-Workflow når relevant — noten finnes ikke ennå).

## Relaterte noter

- [[Active-Job-Search-MOC]]
- [[Job-Scrape-Strategy]]
- [[Career-MOC]]
- [[Skills-To-Develop]] — gap-list som dukker opp under intervju må logges her

## Filer i koderepo

- [Prep-mal](/home/nithu/code/Søking fulltid/intervju/prep-template.md) — kopieres per intervju
- [Workflow-dok](/home/nithu/code/Søking fulltid/docs/workflow.md) — daglig/ukentlig rutine
- Eksisterende intervju-historikk: `intervju/spørsmål fra kongsberg automotive.docx`,
  `intervju/spørsmål fra screening intervjuer.docx`

---

Sist oppdatert: 2026-05-14.
