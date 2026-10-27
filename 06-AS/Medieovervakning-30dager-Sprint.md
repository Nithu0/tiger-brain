---
title: Medieovervåkning — 30-dagers etableringssprint
date: 2026-08-21
tags: [as, medieovervakning, anbud, sprint, ai]
status: aktiv
---

# Medieovervåkning — 30-dagers etableringssprint

**Mål:** tilbudsklar plattform + selskap på plass innen ~21. september, klar for
anskaffelser som kommer ut i oktober. Første anbud = det varme fylkes-anbudet
(brohode). Team: operatør + utvikler (bygger kjernen), + 2 på støtte/forretning/compliance.

**Beslutning: GO.** Ikke lenger en vurdering. Referanser + teknologi tar vi selv;
lisenskost dekkes av kontrakten. Dette er ren execution.

Detaljgrunnlag (kilde, ikke rediger her): `/home/nithu/code/AS/IT/etableringsplan-medieovervakning.md`

---

## Uke 1 (dag 1–7) — Selskap + rettigheter + krav-avklaring

**Selskap (parallelt spor — operatør):**
- [ ] Finn/kjøp et **AS med IT-konsulent-historikk** (aksjekjøp, ikke innmat — da følger
  historikk + ev. referanser med). Sjekkliste under.
- [ ] Alternativt: stift nytt AS hvis ingen god target raskt (kredibilitet svakere, men going).

**Rettigheter (operatør):**
- [ ] Ring/mail **Klareringstjenesten** (post@mediebedriftene.no, +47 22 86 12 00):
  be om standardavtale + intake-prosess. Bekreft: (a) ekstern LLM-inferens innenfor
  §4.2? (b) vektor-embeddings = tillatt «indeks» (§4.1) eller forbudt «utvikling» (§7.2a)?
- [ ] Send tilbudsforespørsel til **Amedia** + **Polaris** (betalingsmur-fulltekst,
  pris per kunde, oppstarts-minimum). Spørsmål ferdig i etableringsplan §15.

**Krav-avklaring (operatør + kontakt):**
- [ ] Åpne konkurransegrunnlaget → klassifiser **O-krav vs scored**. Bekreft at
  full bredde (betalingsmur/kringkasting) er *scored*, ikke absolutt. ← avgjør de-scope.
- [ ] Spør kontakten: hva betaler fylkene Retriever i dag? (prisreferanse)

**Compliance (støtte):**
- [ ] DBA-mal (SSA-L bilag). No-training/zero-retention-DPA med LLM-leverandør (Azure OpenAI el. Anthropic).

## Uke 2 (dag 8–14) — Kjerne-ingestion

- [ ] Crawler + ingestion + dedup på Klareringstjeneste-kilder (åpen web + papir).
- [ ] Podkast: RSS-ingest + Whisper/Groq STT (billig, ~$0,04–0,11/time).
- [ ] Sosialt: X (pay-per-use, scoped norsk) + YouTube + Bluesky.
- [ ] Søk/indeks + vektor-DB for semantisk søk. (Ingen trening på korpus — §7.2a.)

## Uke 3 (dag 15–21) — Portal + AI-lag

- [ ] Portal-MVP: boolsk + lagrede søk + varsling (e-post/push/web) + arkiv +
  kilde-/geo-filter + bruker-/tenant-admin. Responsiv/mobil.
- [ ] AI-lag: sammendrag + sentiment (ekstern LLM m/ DPA), semantisk/NL-søk,
  **eskaleringsdeteksjon**, per-kommune **morgenbriefing**, kommune-entitetsgraf.
- [ ] Tenant-isolert lagring + slett-ved-slutt fra dag én (§12.1) + supervisor-konto (§13).

## Uke 4 (dag 22–30) — Demo + tilbudsklar

- [ ] Demo med **3 brukertilganger** (typisk A-krav A2).
- [ ] WCAG-gjennomgang + DBA ferdig + sikkerhetsgrunnlag.
- [ ] Tilbudsdokument-mal + kvalifikasjonsdokumentasjon.
- [ ] Lever demo til varm kontakt. Meld interesse på åpne RFI-er: **NAV** (Doffin
  2026-111261) + **Sykehusinnkjøp** (2026-107522).
- [ ] Signér Klareringstjenesten. Amedia/Polaris i havn hvis pris OK.

---

## Sjekkliste: kjøpe et AS med IT-konsulent-historikk

Mål: kredibilitet + track record + ev. referanser umiddelbart (løser «ny AS»-svakheten).

- **Aksjekjøp, ikke innmatskjøp** — historikk, org.nr, ev. referanser og MVA-historikk følger med.
- **Riktig NACE/bransjekode:** 62.010 (programmering), 62.020 (IT-konsulent), 63.110 (databehandling).
- **Ren økonomi:** positiv egenkapital, ingen skattegjeld/heftelser/tvister. Sjekk
  Brønnøysund + siste årsregnskap + `heftelser`/`utleggstrekk`.
- **MVA-registrert** + noe reell drift (gir historikk).
- **Ideelt:** tidligere offentlige/IT-leveranser = ekte referanser til «tilsvarende oppdrag».
- **Pris + due diligence:** revisor/regnskapsfører sjekker bøker før kjøp. Se etter
  skjulte forpliktelser, garantier, pågående saker.
- **Hvor:** Finn.no «selskap til salgs», bedriftsmeglere, eget nettverk, ev. hvilende AS dere kjenner.
- **Operatør-gate:** kjøp = irreversibel kapitalbeslutning → Pål/partner-godkjenning.

## Åpne punkter (avklares uke 1)
- O-krav vs scored i konkurransegrunnlaget (avgjør de-scope-lovlighet).
- Klareringstjenesten: AI-inferens + embeddings-tolkning (skriftlig).
- Amedia/Polaris-pris (per kunde).
- AS-target funnet vs. stift nytt.

Se [[Medieovervakning-MOC]] for oversikt.
