---
title: Medieovervåkning MOC
date: 2026-08-21
tags: [as, medieovervakning, anbud, ai, moc]
status: aktiv
---

# Medieovervåkning — Map of Content

Navigasjons-hub for satsningen: **AI-medieovervåkning for norsk offentlig sektor.**
Start her.

## Beslutning: GO

Vi bygger og byr. Referanser + teknologi tar vi selv; lisenskost dekkes av
kontrakten. Første anbud = det **varme fylkes-anbudet** (brohode) — store muligheter
straks vi har levert der. Markedsvindu åpent nå (Infomedia Norge konkurs feb-2026,
Retriever enerådende, priser stiger, anbud avlyses).

## Start her

- [[Medieovervakning-30dager-Sprint]] — **execution-planen** mot oktober-anskaffelser. Uke for uke + AS-kjøp-sjekkliste.

## Detaljgrunnlag (i kode-prosjekt, ikke rediger fra Obsidian)

| Dokument | Hva |
|---|---|
| `/home/nithu/code/AS/IT/etableringsplan-medieovervakning.md` | **Beslutningsdokumentet** — kravmatrise, supplier/licensing-stack, readiness-score, kontaktliste, ferdige leverandørspørsmål, Go/No-Go |
| `/home/nithu/code/AS/IT/plan-medieovervakning-bud.md` | Tidlig strategi/prismodell (levende) |
| `/home/nithu/code/AS/IT/analyse-medieovervakning-anbud.md` | Første kritiske analyse |
| `/home/nithu/code/AS/IT/` (13 bilder) | Kravspec-utkast (fylkes-anbudet) |

## Kjernefakta (primærkilde-forankret)

- **Lisens billig + åpen:** Klareringstjenesten = publisert, ikke-diskriminerende
  standardavtale, ~15,4k/år **per kunde** (null før kunder), ~97 % avisdekning.
- **3 signaturer = 80–95 % dekning:** Klareringstjenesten + Amedia + Polaris.
  Schibsted/DN/Dagbladet gir fulltekst til ingen (likt for alle).
- **Bygg egen crawler** (Hypefactors-malen) — ikke Opoint (Retriever-eid).
- **Arkitektur-låser (Klareringstj. §7.2):** ikke tren AI på korpus; ikke selg
  frittstående analyse/arkiv; AI-sammendrag/sentiment kun integrert; slett ved slutt.
- **AI = vinner kvalitets-scoren, ikke minstekrav-porten.** Edge: sanntids
  sak-/eskaleringsdeteksjon, semantisk søk, kommune-entitetsgraf + proaktiv briefing, UX.

## Kontakter (uke 1)

| Aktør | Kontakt | Hva |
|---|---|---|
| Klareringstjenesten | post@mediebedriftene.no / +47 22 86 12 00 | Standardavtale + AI-inferens/embeddings-bekreftelse |
| Amedia | amedia.no | Betalingsmur-fulltekst, pris per kunde |
| Polaris Media | polarismedia.no | Betalingsmur-fulltekst, pris per kunde |
| Kjøper-kontakt | (din) | O-krav vs scored, dagens Retriever-pris |
| Åpne RFI-er | Doffin 2026-111261 (NAV), 2026-107522 (Sykehusinnkjøp) | Meld interesse/markedsdialog |

## Neste beslutninger

- [ ] AS: kjøpe med IT-historikk vs. stifte nytt (operatør + Pål — kapital-gate).
- [ ] Bekreft O-krav vs scored i konkurransegrunnlaget.
- [ ] Demo-scope vs. implementerings-/SLA-plan — hvilken sparring neste.

## Tags
#as #medieovervakning #anbud #ai
