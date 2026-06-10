---
title: Refi-Partnerskap Forretningsplan
date: 2026-06-03
tags: [business, refi, partnerskap, onprem-ai]
status: draft
---

# Refi-Partnerskap — Forretningsplan

Konsolidert lesbar plan for partnerskapet rundt privat, lokal AI for økonomisk
rådgivning (refi-vertikalen). Syntese av AS/docs-arbeidet per juni 2026. Ærlig og
kompakt: dette er retning + nåværende beslutninger, ikke et løfte. Tall er estimat
til de er målt i pilot.

> **Masterplan-referanse (ikke duplisert her):**
> `03-business/2026-05-24-onprem-ai-strategi.md` (~909 l) dekker teknisk arkitektur,
> sikkerhet, hardware-tiers, refi-jus, produktpakker og 30/60/90. Denne fila
> oppsummerer *partnerskaps-vinkelen* og lenker videre.

---

## 1. Beslutning: regnskapsfører inn som partner

Kjernebeslutningen er at den varme refi-kontakten (en regnskapsfører/rådgiver med
~40 års bransjeerfaring) ikke skal være *kunde*, men **partner og medeier**. Han
bidrar med det operatøren ikke har: domeneekspertise, kundeportefølje, bankkontakter
og — kritisk — det faglige/regulatoriske ansvaret som autorisert rådgiver for
refinansiering. Operatøren bidrar med å bygge og drifte maskinen, dokumentflyt,
automatisering og sikkerhet.

Eierstrukturen tenkes som operatør + Karri + partner. Selve juridiske struktur-valget
(eierandeler, vehikkel, vesting) er en **åpen beslutning** — se §8. Partnerinvitasjonen
og rollefordelingen er beskrevet i `AS/docs/refi-business/PITCH-DECK.md`
("Partnerinvitasjon — din rolle").

## 2. Produkt: privat lokal AI-server per kunde

En fysisk boks som står hos kunden. **All AI og alle data kjører lokalt — ingenting
forlater huset.** Det er ikke en feature, det er hele eksistensgrunnlaget: sky-AI
(ChatGPT/Copilot) er teknisk fristende men juridisk stengt for sensitive
regnskaps-/lønns-/gjeldsdata under taushetsplikt + GDPR. Lokal kjøring fjerner
underdatabehandler-problemet og gir DPA-grunnlag.

- **v1 = effektivitet.** Inn: en haug PDF-er. Ut: en strukturert sak å kvalitetssikre.
  Dokumentinnsamling → klassifisering + sjekkliste → mangelliste → deterministisk
  talluttrekk (Python regner, LLM forklarer) → utkast (e-post/saksnotat, partner
  sender og signerer) → saksoversikt. Mennesket er fortsatt fagpersonen.
- **v2 = mulighetsmotor.** Når effektiviteten sitter, snus maskinen fra å spare tid
  til å *finne penger*: skanner hele porteføljen og flagger refi-kandidater,
  finansieringsbehov, skatteoptimalisering (privat) og salgsmodne selskaper / refi /
  strukturgrep (firma) — som **forslag til partner**, aldri råd til sluttkunde.

v2 loves aldri før v1 leverer og er betalt.

## 3. Forretningsmodell

- **Pilot hos partner først.** Manuell levering → cloud-MVP → lokal boks. Validerer
  betalingsvilje før produksjonskode.
- **Videresalg av private servere** til andre regnskapsførere/rådgivere/advokater med
  samme problem (sensitive data, kan ikke bruke sky, drukner i dokumenter):
  - **Engangs setup** (oppsett av boks hos kunde).
  - **Månedsabonnement** for support + oppdatering + service.
- **Lite cut av ekstraarbeidet** v2 genererer (mulighetsmotoren skaper fakturerbare
  oppdrag hos partner — selskapet tar en liten andel av den nye inntekten).
- **Hardware-salg** (boksen selv) som egen post.

Partneren er ikke bare leverandør av valideringen — han er **døråpneren** til
videresalget. Bransjen kjenner og stoler på ham; det er distribusjonskanalen.

## 4. Inntektslogikk

To kilder, holdt fra hverandre:

1. **Partnerens payback** kommer fra **frigjort kapasitet**. v1 sparer estimert
   ~10–18 t/uke (måles i pilot, ikke garantert). Illustrativt: ~12 t/uke × ~45 uker
   ≈ ~540 t/år; hvis halvparten fylles med rådgivning à ~1 500 kr/t ≈ ~405k/år ny
   fakturerbar tid → payback < 1 år *forutsatt at den frigjorte tiden faktisk fylles
   med nytt arbeid*. v2 er nettopp det som leverer sakene å fylle den med. Alle tall
   er eksempler — reell effekt avhenger av timepris og hva v2 avdekker.
2. **Selskapsinntekt** kommer fra videresalg: setup-engangssum + månedsabo +
   hardware + cut av ekstraarbeid. Dette er der oppsiden skalerer ut over partner #1.

## 5. Veikart (cashflow-først)

Den harde regelen: **penger først, hardware som konsekvens — aldri gå i minus før
cashen er inne.** Detaljert sekvens i tre-spor-planen og control-core-planen.

1. **Cashflow nå (~0 kr):** Verisure/Lofoten-tur (rask cash, base case ~60k netto) +
   manuell refi-levering for partnerens 2–3 første saker (betalt per sak,
   1 500–3 000 kr) + ML/AI-konsulent-outreach parallelt. Jurist-møte før ekte data.
2. **Cloud-MVP:** refi-doc-agenten kjøres på cloud-GPU/API mot *anonymiserte*
   testdok mens manuell levering fortsetter. Sortering + sjekkliste + mangelliste
   inn i app.
3. **Lokal boks (~august, cashflow-gated):** når Lofoten-/pilot-cash er på konto,
   settes lokal node opp (CPU-node + brukt RTX 3060 12GB ~26k; oppgraderbar til
   3090/dual-3090 senere). Data lokalt → DPA-grunnlag. Talluttrekk live i prod.
4. **v1 ferdig:** e-postutkast, saksdashboard, status-per-bank, oppfølging. Overgang
   fra per-sak til månedsavgift (3–8k/mnd).
5. **Mulighetsmotor v2:** etter jurist-runde 2, deterministisk regelmotor flagger
   muligheter til partner.
6. **Produktisering mot kunde #2:** multi-tenant-isolasjon, oppsett-runbook, DPA-mal.
   Partner #1 = referansecase.

NB (fra tre-spor-planen): NAV-dagpenger-under-etablering kan i praksis **ikke**
kombineres med aktiv Verisure-cash uten svindelrisiko. Velg ett spor eller
sekvensér; avklar skriftlig med NAV før noe bygges på dagpenge-inntekt.

## 6. Regulatoriske grenser (kort)

Full gjennomgang i `AS/docs/refi/compliance.md`. Kjernen:

- **Partner er fagansvarlig** autorisert rådgiver for refinansiering og beslutningstaker.
  Operatør leverer teknisk/administrativ dokumentflyt — **ikke låneråd**. Dette holder
  operatøren utenfor låneformidlingsloven/finansforetaksloven (arbeidshypotese —
  må bekreftes skriftlig av jurist).
- **Ikke tren på PII / ingen ekstern LLM-API på ekte kundedata.** Bygging/demo på
  anonymiserte data; ekte data kun lokalt. Ingen gjenbruk av kundedata til egne formål.
- **DPA per kunde** (operatør = databehandler, partner = behandlingsansvarlig, GDPR
  art. 28) signeres før ekte data. DPIA vurderes. Tall regnes deterministisk i Python,
  aldri av LLM. AML-flagg overflates, aldri filtreres bort. Menneske godkjenner alt
  utgående.

## 7. Lenker

**AS/docs (kilder):**
- `AS/docs/2026-06-01-tre-spor-cashflow-plan.md` — cashflow-først, Lofoten-strategi,
  provisjonsregnestykke, MVP-omfang, NAV-risiko.
- `AS/docs/2026-06-01-control-core-plan.md` — hardware-liste, fase-modell, repo-gjenbruk,
  business-MVP rangert på time-to-cash.
- `AS/docs/refi/compliance.md` — juridisk posisjonering, jurist-spørsmål, DPA/DPIA,
  datasikkerhet-minimum.
- `AS/docs/refi/manuell-mvp/` — maler: dokumentsjekkliste, mangelliste, e-postmaler,
  saksoversikt, leveranse-og-pris (M0–M1 manuell levering).
- `AS/docs/refi-business/PITCH-DECK.md` (+ `.pptx`) — partnerinvitasjon (denne planens
  partnerskaps-pitch).
- `AS/docs/refi-business/byggeplan-aarsplan.md` — M0–M12 oversatt til partnerens
  opplevde gevinst.

**Brain:**
- `03-business/2026-05-24-onprem-ai-strategi.md` — masterplan (referer, ikke rediger).
- [[Refi-Partnerskap-MOC]] — navigasjons-hub.

## 8. Åpne beslutninger / neste steg

- **Møte med partner:** kjøre pitch (PITCH-DECK), be om interesse + tidstyver + 2–3
  reelle (anonymiserte) testsaker. Ikke be om beslutning, be om åpning.
- **Jurist (før ekte data, ufravikelig):** de to kjernespørsmålene i compliance §4 —
  (1) utenfor låneformidlingsloven? (2) high-risk under EU AI Act? Skriftlig svar.
- **Struktur-valg (uavklart):** eierandeler operatør/Karri/partner, juridisk vehikkel
  (eget AS for produktet vs operatørens ENK?), vesting, hva partneren får (eierandel
  vs revenue-share vs begge), IP-eierskap til boks/kode. Krever jurist + samtale med
  Karri.
- **Cashflow-gate:** ingen hardware-kjøp før Lofoten-/pilot-cash er på konto + MVA satt
  av på egen konto + forfalt MVA ryddet.
- **PC-eierskap:** boksen eid av operatør + Karri + partner-struktur (følger struktur-
  valget over).
