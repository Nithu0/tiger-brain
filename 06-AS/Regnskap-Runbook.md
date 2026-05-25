---
title: Regnskap-Runbook — månedlig rutine
type: runbook
created: 2026-05-14
tags: [runbook, as, regnskap, månedlig]
---

# Regnskap-Runbook — månedlig rutine

Kjøres første hverdag i ny måned. Estimat: 30-60 min.

## Forutsetninger

- Tilgang til Verisure-portalen (lønnsskjema, salg, installasjoner)
- Tilgang til Telia + Telenor kundeportal (fakturaer)
- Tilgang til Gasum-kort kundeside (drivstoff-kvitteringer)
- Mobil med kvitteringer fra forrige måned (mat på reise, parkering)

## Sjekkliste

### 1. Samle bilag for forrige måned

- [ ] Last ned Lønnsskjema fra Verisure → `/home/nithu/code/AS/Lønn <måned>/Lønnsskjema <måned>.xlsx`
- [ ] Last ned Salg-rapport → `Salg <måned>.xlsx`
- [ ] Last ned Installasjoner-rapport → `Installasjoner <måned>.xlsx`
- [ ] Last ned faktura → `faktura <måned>.pdf` (eller faktura_2026_xxxxx.pdf)
- [ ] Eksporter kjørebok fra forrige måned → `kjorebok <måned>.xlsx`
- [ ] Last ned Telia-faktura → `Telia/<måned>.pdf`
- [ ] Last ned Telenor-faktura → `Telenor/<måned>.pdf`
- [ ] Last ned gasum-kort-kvittering → `Drivstoff kvittering/<måned> gass.pdf`
- [ ] Samle private kvitteringer (drivstoff/mat/parkering/utstyr) → dato-prefiks i filnavn

### 2. Verifisering

- [ ] Telleliste matcher Verisure-lønnsskjema (timer/vakter)
- [ ] Kjørebok stemmer overens med faktura-perioder
- [ ] Ingen duplikater (samme bilag i to mapper)

### 3. Oppdatere regnskap

- [ ] Åpne `/home/nithu/code/AS/docs/regnskap-status.md`
- [ ] Fyll inn brutto-inntekt for måneden (fra Lønnsskjema)
- [ ] Summer utgifter (telefon + drivstoff + reise + utstyr + næringsandel husleie)
- [ ] Regn ut netto før skatt
- [ ] Sett rad-status til "komplett"

### 4. MVA-sjekk

- [ ] Beregn rullerende 12-mnd omsetning
- [ ] Hvis nær 50k: planlegg MVA-registrering (Altinn-skjema)
- [ ] Hvis over 50k og ikke registrert: registrér umiddelbart
- [ ] Hvis MVA-pliktig og terminslutt: lever MVA-melding innen 10. i andre måned etter terminslutt

### 5. Bokføring (hvis aktiv)

- [ ] Legg bilag inn i bokførings-software (Fiken/Conta/Tripletex)
- [ ] Eller manuell Excel hvis ikke abonnement
- [ ] Sjekk at fakturanummer er løpende
- [ ] Marker betalt vs. ubetalt

### 6. A-melding (kun AS med ansatte)

- [ ] Innen den 5. i måneden: send A-melding i Altinn
- [ ] Sjekk at lønn + AGA + skattetrekk stemmer

### 7. Backup

- [ ] Verifiser at `/home/nithu/code/AS/` er backup-et (OneDrive/Google Drive/lokal disk)
- [ ] Ikke commit til git

## Special cases

- **Faktura mangler fra Verisure**: ping koordinator, ikke gjett tall
- **Privat utgift med næringsandel**: noter andel (f.eks. 70 % telefon næring, 30 % privat)
- **Reise med diett**: sjekk statens satser (6-12 t, 12-24 t, >24 t)
- **Større investering (PC, telefon)**: vurdér aktivering vs. direkte fradrag

## Hvis noe er rart

- Brutto-tall avviker vesentlig fra forrige måned: dobbel-sjekk Lønnsskjema mot Telleliste
- Manglende MVA: sjekk MVA-brev i `/home/nithu/code/AS/Mva-brev som gjelder virksomheten deres..pdf`
- Skatte-spørsmål: se [[Skatt-Notater]] eller Skatteetatens chatbot

## Tags

#runbook #as #regnskap #månedlig
