---
tags: [06-AS, inntekt, strategi, research, sidegig]
date: 2026-05-14
status: research-output
owner: operator
review-cadence: kvartalsvis
related: [AS-MOC, Regnskap-Runbook]
---

# Inntekt-Strategier — Research-output

## TL;DR

Operatøren har et begrenset tidsbudsjett (5–10 t/uke ved siden av Verisure-vakter + master-studier på NTNU) og to reelle aktiva-klasser: **(i) anvendt ML/data-engineering-kompetanse** og **(ii) Nexus trading-system-internalia**. Av seks vurderte spor anbefales **Spor A — AI-/ML-konsulent for norske SMB-er** som primær, med **Spor E — Innholds-økonomi (teknisk blogg/Substack)** som sekundær compounding-motor som genererer leads inn i A. Spor B (Nexus-produktisering) parkeres pga. regulatorisk friksjon. Spor C (regnskaps-automation) er attraktivt på sikt, men har lengre tid-til-første-krone. Spor D (Verisure-crossover) frarådes pga. arbeidsgiver-konflikt. Spor F (Toptal o.l.) er fall-back hvis A ikke gir traction innen 8 uker.

---

## Strategi-katalog

### Spor A — AI-/ML-konsulent for SMB

**Markedshypotese**: Norske små/mellomstore bedrifter (10–100 ansatte) ser at "AI" er obligatorisk, men kan ikke ansette en data scientist (lønn 850k–1.1M + arbeidsgiveravgift). Det åpner et marked for kort-prosjekt-basert konsulentbistand: PoC-er, intern automatisering, prompt-engineering for sak-/dok-flyt, RAG-løsninger på interne dokumenter, Excel-/data-rydding med ML-touch.

**Verdiforslag for kunden**:
- Konkret leveranse på 2–6 uker, fast pris eller hourly cap
- Norsk-talende, kan møte fysisk i Trondheim/Oslo
- Lavere terskel enn Bouvet/Sopra Steria

**Lead-kilder (konkrete)**:
- LinkedIn outreach mot CTO/COO i Trondheim-baserte SMB-er (NTNU-alumni-nett)
- Norsk Industri-medlemslister (offentlig liste)
- Lokale næringsforeninger (Næringsforeningen i Trondheimsregionen)
- Innovasjon Norge-finansierte bedrifter (offentlig database) — disse har ofte tilskuddsmidler som må brukes
- Warm intros fra Verisure-nettverk (uten konflikt — andre bransjer)

**Pricing**:
- Junior-medio (master ikke fullført): 800–1100 kr/t fakturert
- Etter levert thesis + 2 referanser: 1200–1500 kr/t
- Fast-pris-PoC: 25k–60k for 2-ukers leveranse

**Tids-investering**: 5–10 t/uke effektivt leveranse-arbeid + 1–2 t/uke salg/oppfølging.

**Risiko**:
- Salg er ferskvare og krever vedlikehold
- Master-studier kan kollidere med deadlines → krever solid scope-disiplin
- Manglende ENK/AS-modenhet på fakturering — løses via Spor C-verktøy eller Fiken

**Tid-til-første-krone**: 4–10 uker realistisk fra dag 1.

---

### Spor B — Produktisering av Nexus-deler

**Hypotese**: Deler av Nexus (backtester-rammeverk, regime-detektor, risk-sizing-bibliotek) er generaliserbare og kan abstraheres til open-core + paid features.

**Mulige produkter**:
- **Backtest-as-a-library** (Python pip-pakke, MIT-lisens) → leads inn til konsulent-spor, ikke direkte inntekt
- **Strategi-research-rapporter** (Substack paid tier, 99 kr/mnd) — lovlig så lenge det er research, ikke signaler
- **Signal-feed / kopi-trading**: REGULATORISK HODEPINE. Finanstilsynet-konsesjon eller MiFID II-omfattet. **Frarådes** uten advokat.
- **White-label backtester** for prop-firms / fond — krever salgsnettverk operatøren ikke har

**Realisme**: Lav på 0–12 mnd-horisont. Høy om 18–36 mnd hvis Nexus får live track record + tredjeparts-verifikasjon.

**Beslutning**: Parker direkte monetisering. Bruk Nexus som **autoritetsfundament** for Spor E (blogg om kvant-research uten signal-distribusjon).

---

### Spor C — AI-tjenester for selvstendig næringsdrivende / regnskap

**Hypotese**: 350k+ norske ENK-er, mange uten ressurser til Tripletex/PowerOffice. Fiken er nærmest, men koster og krever fortsatt manuelt arbeid på kvittering-input.

**Mulige produkter**:
- Kvittering-OCR-bot (Telegram/SMS-input → strukturert JSON → CSV-eksport til Fiken)
- MVA-rapport-assistent (les Altinn-data, foreslå postering)
- Automatisert fakturering med påminnelse-flow

**Marked**: Stor, men priselastisk — folk forventer "billig eller gratis". Vanskelig å ta 199 kr/mnd uten merkevare.

**Inngang**: Bygg ett gratis lavterskel-verktøy (kvittering-OCR via webapp) → e-postliste → premium-funksjoner senere. Dette er en **18-måneders bygg**, ikke en sidegig-inntekt på kort sikt.

**Beslutning**: Backlog. Vurder på nytt etter at Spor A gir første kunder + AS-infrastruktur er på plass.

---

### Spor D — Verisure-relaterte sidespor

**Hypotese**: Sensor-data + vakthold-data + tellelister kan analyseres på en måte ingen i sikkerhetsbransjen gjør i dag.

**Vurdering**:
- Konflikt med arbeidsgiver-avtale. Verisure har sannsynligvis klausuler om bi-stilling i samme bransje.
- Selv "nabolaget", som Securitas/Nokas, er off-limits.
- Cyber/fysisk crossover-konsulent er teoretisk mulig, men krever sertifiseringer (CISSP o.l.) operatøren ikke har.

**Beslutning**: **Frarådes**. Hold Verisure-jobben ren som stabil base. Eventuelt sjekk ansettelseskontrakt for "tillatt bi-virksomhet"-klausul før noe gjøres.

---

### Spor E — Innholds-økonomi

**Hypotese**: Operatøren har to nisjer få i Norge kombinerer: **ML for batteri-materialer** (thesis-domene) og **kvant-trading-research** (Nexus). Lavfrekvent kvalitets-output bygger autoritet → leads inn i Spor A.

**Format**:
- Substack på engelsk: 1 post / 2. uke. Tema: "applied ML for solid-state electrolytes" + "lessons from building a XAUUSD quant system as a solo operator"
- Norsk LinkedIn-poster (kortere, hyppigere) — kanal for konsulent-leads
- GitHub-portefølje med 2–3 rene repos (backtest-bibliotek, electrolyte-feature-extractor)

**Inntekt-forventning direkte**:
- Substack paid tier: 0–500 kr/mnd første 12 mnd, deretter compounding hvis konsekvent
- Direkte inntekt er **ikke** poenget — poenget er CAC (customer acquisition cost) lik null for Spor A

**Tids-investering**: 2–4 t/uke. Krever disiplin.

**Risiko**: Lav. Hovedrisiko er at det blir prokrastinering forkledd som "investering".

---

### Spor F — Skill-leie via Toptal/Arc/Braintrust

**Hypotese**: Operatøren har nok ML/Python/TS-erfaring til å passere senior-screen hos plattformer som tar internasjonale kunder.

**Vurdering**:
- Toptal: streng screen (~3 % accept rate), men $80–150/t for ML-roller. Krever ofte 20 t/uke commitment → kollisjon med studier.
- Arc.dev / Braintrust: lavere terskel, mer fleksibel timing, men også lavere rate.
- Fordel: ingen salg-arbeid. Plattformen tar 20–30 % kutt.

**Beslutning**: **Fallback hvis Spor A ikke gir første kontrakt innen 8 uker**. Søk Toptal-screen som passiv pipeline parallelt.

---

## Norsk skatt-context (allmenn, ikke regnskapsfaglig råd)

> **Disclaimer**: Dette er en strategi-sammenstilling, ikke skatte-rådgivning. Vurder å sjekke konkrete forhold med regnskapsfører eller Altinn-veileder før beslutning.

### ENK vs AS — kort komparativ

| Tema | ENK | AS |
|---|---|---|
| Overskudd-beskatning | Personinntekt (trinnvis, opptil ~47.4 % marginalskatt) | 22 % selskapsskatt + utbytteskatt ved uttak |
| Utbytteskatt 2026 | N/A | Anslagsvis ~37.84 % (sjekk Skatteetaten) |
| MVA-plikt | Fra 50 000 kr omsetning siste 12 mnd | Samme grense |
| Arbeidsgiveravgift | Nei (på eget overskudd) | Ja, hvis du tar lønn til deg selv |
| Personlig risiko | Ubegrenset ansvar | Begrenset til aksjekapital (min. 30 000 kr) |
| Admin-byrde | Lav (Næringsoppgave 1) | Høyere (årsregnskap, generalforsamling, revisjonsplikt-grenser) |
| Egnet ved | Sideinntekt < 300k, lav risiko-eksponering | Større aktivitet, planlagt vekst, eksternt eierskap, kapital-buffer |

### Tommelfingerregel for operatørens situasjon

- Hvis første-års-inntekt fra konsulent < 200k: **ENK** sannsynligvis enklere
- Hvis > 300k og forventet videre vekst: **AS** gir bedre fleksibilitet (utsette utbytte, bygge bufferkapital, lettere å ta inn kunde-prepay uten å beskattes personlig samme år)
- Operatøren har allerede et AS antydet i prompten → bruk eksisterende struktur hvis den finnes; ikke opprett ENK parallelt

### Fradrag operatøren bør være obs på

- Hjemmekontor (forholdsmessig andel av husleie/strøm — krav om dedikert rom)
- Utstyr: laptop, skjerm, abonnement (Claude, GitHub Copilot, cloud-compute)
- Faglitteratur, kurs, konferanser
- Reise i tjeneste
- Telefon (delvis)
- Programvare-abonnementer brukt til inntektsbringende arbeid

### Bokføringskrav

- 5 års oppbevaringsplikt på bilag (digitalt OK hvis lesbart format)
- Kvitteringer i 06-AS er korrekt praksis — fortsett samme rutine
- Vurder Fiken / Conta / DNB Regnskap fra dag 1 hvis omsetning > 50k forventet

---

## Prioriterings-matrise

| Spor | Tids-investering (t/uke) | Forventet inntekt år 1 | Risiko | Tid-til-første-krone | Score (1-10) |
|---|---|---|---|---|---|
| **A — ML-konsulent SMB** | 6–10 | 80k–250k | Medium (salg-avhengig) | 4–10 uker | **8.5** |
| B — Nexus-produktisering | 8–15 | 0–20k | Høy (regulatorisk) | 9–18 mnd | 3 |
| C — Regnskap-AI for ENK | 10–15 | 0–30k | Medium-høy | 12–18 mnd | 4 |
| D — Verisure-crossover | N/A | N/A | Kritisk (arbeidsgiver) | N/A | 1 |
| **E — Innhold/Substack** | 2–4 | 0–10k direkte; støtter A | Lav | 0 uker (skrive); 6 mnd (leads) | **7** (som forsterker) |
| F — Toptal/Arc fallback | 10–20 hvis aktiv | 100k–300k | Lav-medium | 6–12 uker (screen) | 6 |

---

## Anbefaling

**Primær: Spor A (ML-konsulent SMB)** — best ratio av tid-til-første-krone, kontroll, og kompetanse-bygging. Krever ubekvem salgs-aktivitet men har lavest entry-barrier gitt operatørens posisjon (NTNU-nettverk, programmerings-bakgrunn, lokalt forankret).

**Sekundær: Spor E (Innhold)** — kjør parallelt fra dag 1. Lavt tidsforbruk, høy compounding-effekt på Spor A-leads.

**Beredskap: Spor F (Toptal-screen)** — søk i uke 1–2 som passiv pipeline. Hvis Spor A ikke gir signert kontrakt innen 8 uker, aktiver F som hovedspor.

**Parkert: B, C, D** — re-vurder Q3/Q4 2026.

---

## Konkrete neste-skritt

### Denne uka (uke 20, 2026)

**Spor A**:
1. Skriv 1-siders "tjeneste-blurb" (PDF) — hva tilbys, til hvilken pris, eksempel-leveranser. Norsk + engelsk versjon.
2. Oppdater LinkedIn-profil med tjenesteorientert headline ("ML/data-konsulent for SMB | NTNU master").
3. Lag liste med 30 målbedrifter i Trondheim-regionen (CTO/COO-navn, e-post om mulig).

**Spor E**:
1. Reserver Substack-domene + opprett konto.
2. Skriv første post (utkast) — anbefalt tema: "Why I'm building my own quant system as a master's student" eller "Feature engineering for solid-state electrolyte datasets".

**Spor F**:
1. Send Toptal-søknad. Screen-prosess tar 2–4 uker, så start nå.

### Denne måneden (uke 20–24)

**Spor A**:
- Send 15 personlige outreach-meldinger på LinkedIn (5/uke). Mål: 3 møter, 1 signert PoC.
- Sett opp fakturering i eksisterende AS (Fiken eller tilsv.). Test med en dummy-faktura.
- Definer 2–3 standardiserte tjeneste-pakker (PoC-pakke 25k, automation-sprint 40k, RAG-bygg 60k).

**Spor E**:
- 2 Substack-poster publisert.
- 4 LinkedIn-poster (norsk, kortere).

### Q3 2026 (juni–august)

**Spor A**:
- Mål: 2 signerte kunder, 60k–100k fakturert.
- Få 1 skriftlig referanse/testimonial.
- Vurder rate-hike etter første leveranse hvis kunde er fornøyd.

**Spor E**:
- 6–8 Substack-poster totalt.
- Start måling: hvor mange Spor-A-leads kommer fra innhold?

### "Lansert"-definisjon per spor

- **Spor A lansert** = 1 signert kontrakt, 1 fullført leveranse, 1 referanse skrevet.
- **Spor E lansert** = 4 publiserte poster, 50+ subscribers, første lead som nevner innholdet.
- **Spor F lansert** = passert Toptal-screen ELLER fått første gig via Arc.

---

## Risikoer

1. **Studie-kollisjon**: Master-thesis-deadline i juni 2026 (?) — konsulent-leveranser i samme periode = brann. **Mitigering**: ikke ta kunder med deadline før august, kommuniser tilgjengelighet ærlig.
2. **Verisure-konflikt**: Sjekk ansettelseskontrakt for bi-virksomhets-klausuler. Sannsynligvis ingen konflikt med ML-konsulent i annen bransje, men verifiser.
3. **Underpricing**: Ferske konsulenter dumper rater. Hold 800 kr/t som gulv, ikke gå under selv ved første kunde.
4. **Scope creep**: PoC blir 3-mnd-prosjekt uten ekstra fakturering. **Mitigering**: skriftlig scope-doc, change-request-prosess.
5. **Skatte-blindsoner**: MVA-pliktig fra 50k → unngå å bli MVA-pliktig midt i året uten å være registrert. Vurder forhåndsregistrering hvis 50k er sannsynlig.
6. **Burnout**: 30 t/uke Verisure + master + 10 t/uke konsulent + innhold = bratt. Innfør "ingen ny aktivitet etter kl 21" som regel.

---

## Åpne spørsmål for operatør

1. **AS-status**: Er AS-et allerede operativt med org.nr., bankkonto, og regnskapsfører? Eller er det "papir-AS"? — påvirker hvor fort Spor A kan fakturere.
2. **Verisure-kontrakt**: Finnes klausul mot bi-virksomhet / konkurranse? Hvis ja, hvilken ordlyd?
3. **Tids-tak**: Hva er faktisk realistisk t/uke gjennom thesis-innspurten (juni)? 5? 10?
4. **Geografisk preferanse**: Trondheim-only, eller åpen for Oslo-pendling / 100 % remote?
5. **Pricing-gulv**: Komfortabel med å si "1200 kr/t" til en kunde i andre møte? Eller trengs en mental ramp-up (først 800, så opp)?
6. **Substack-språk**: Engelsk (større publikum, lavere norsk-lead-konvertering) eller norsk (omvendt)? Eller begge?
7. **Nexus-IP**: Hvor mye av Nexus-koden er operatørs eiendom vs. delt med andre (f.eks. Karri-samarbeid)? Påvirker hva som kan brukes i Spor B/E.
8. **Toptal-screen**: Tid å investere i screen-prosess (10–15 t over 2–3 uker) — verdt det som beredskap?

---

*Generert som research-output, ikke vedtak. Operatør beslutter prioritering.*
