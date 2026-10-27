# paal-1 — behovsprediksjon og dynamiske innkjøpsordninger (DPS)

Prod, read-only (SQL fra fil via `railway ssh`), målt 2026-10-18 22:13–22:45Z. Merking: **DOKUMENTERT** =
står i kunngjøringen eller hos kilden, **ETTERSPURT** = krav i anbudet, **ANTAKELSE** = vår statistikk eller tolkning.

## 1. Hva vi kan i dag (tall)

- **Datagrunnlag:** 110 059 kunngjøringer. 2021–2024 er godt dekket (~15 000 utlysninger og ~9 000 resultater per år), men **2025 mangler nesten helt (32 utlysninger)**. 2026 kommer fra løpende innhenting.
- **Radaren (SC-02) i prod:** 387 tildelinger, contractEnd 54 %, 3 IT-gjenutlysninger innen 12 mnd. Historikken kommer inn med inntil 2 000 anskaffelser per natt fra i natt. På en lokal kopi gir full historikk ~155 reelt kommende IT-kontrakter (1 382 av 1 537 har passert sluttdato).
- **Gjentatte kjøp (ANTAKELSE, statistikk):** av 688 IT-resultater fra 2021 kom ny utlysning fra samme kjøper med samme CPV-5 innen 24 mnd for 49 %, innen 36 mnd for 60 % og innen 48 mnd for 66 %. **Medianen er 16,6 mnd.** 89 kjøpere lyste ut samme IT-CPV-5 i minst 3 av 4 år (188 kjøper×CPV-par). CPV-5 er grovt, så tallet er trolig noe for høyt.
- **Sesong (ANTAKELSE, statistikk):** IT-utlysninger 2021–24 per måned. August er bunnen (300), november toppen (683), og mars og juni er høye (613/632). Det passer med budsjettåret: november er tidlig bruk av neste års midler, desember er årsslutt.
- **Tilbakeblikk på radaren: ikke mulig nå.** Historikken har varighet på 1 av 35 793 resultater, og pre-eForms-notiser (2021–22) i rå-arkivet gir varighet for bare 9 av 10 283. Det er **hull 1**.

## 2. Dynamiske innkjøpsordninger

- **DOKUMENTERT (DFØ, anskaffelser.no, lest 2026-10-18):** DPS er fullt elektronisk, nye leverandører kan tas opp *under hele varigheten*, og det er ingen grense på antall leverandører. Den er egnet for SMB-er og nyetablerte, og nevner eksplisitt «konsulentbistand under oppdragsgivers instruksjonsmyndighet». Leverandøren har ingen plikt til å gi tilbud, og fristen i minikonkurransene er minst 10 dager.
- **I dataene:** 726 DPS-kunngjøringer, 534 ordninger. Dette er en **nedre grense**, fordi 47 382 kunngjøringer har ukjent prosedyre. **210 er åpne nå** (fristen i kunngjøringen ligger fram i tid; ANTAKELSE: fristen = ordningens varighet). 42 av dem har CPV 72. De største kjøperne er Brønnøysundregistrene (19), Digdir (14), Sykehusinnkjøp, Vinmonopolet, KS og Stavanger (11 hver).
- **Åpne IT-konsulent-DPS-er nå (DOKUMENTERT, doffin.no):**
  - Sjøfartsdirektoratet, 8 kategorier til 2026-12-31: blant annet «Analytics, maskinlæring», «Utviklere og techlead», «Strategisk rådgivning».
  - Vinmonopolet, 9 kategorier til 2028-05: blant annet «Analytics, maskinlæring og dataforvaltning» og «Systemutvikling».
  - Digdir: system-, web- og test til 2027-01, testing til 2028-06.
  - Entur, IT-utvikling til 2027-02 og -03.
  - Brønnøysundregistrene, «Sammensatte team systemutvikling» til 2026-11-22.
  - Mattilsynet IKT-utvikling og Flytoget IT-utvikling, begge til 2026-12.
- **Antall kvalifikasjonskrav (ETTERSPURT, eForm):** Sjøfartsdirektoratet og Brønnøysundregistrene har 2, Vinmonopolet 34, Digdir testing 50. Hvilke krav det er, må leses per ordning.
- **Mot kompetansebanken (36 fakta):**
  - Vi *har*: KI/løsningsdesign (Nithusan), to utviklere med flere års erfaring, oppdrag opp til 4 MNOK, maler og ESPD-rutine.
  - Vi *mangler*: kundereferanser på IT-oppdrag, ansvarsforsikring (tegnes etter eierskiftet, ventet uke 43), dokumentert miljøledelse, databehandleravtaler.
  - **ANTAKELSE:** ordninger med få krav og uten referansekrav (Sjøfartsdirektoratet, Brønnøysundregistrene) er realistiske *etter uke 43*. Vinmonopolet og Digdir krever trolig referanser.

## 3. Beste mulighet

**Søk opptak i 3–5 åpne IT-DPS-er rett etter eierskiftet (uke 43–44).** Én kvalifisering gir løpende
minikonkurranser i hele varigheten (DOKUMENTERT, DFØ), uten å vente på en ny rammeavtale. Ingen av disse krever å slå en
etablert leverandør i én stor konkurranse, og 4 MNOK-taket passer størrelsen på minikonkurranser (ANTAKELSE). Start med
Sjøfartsdirektoratet «Analytics, maskinlæring» og «Utviklere og techlead» (frist 2026-12-31) og Brønnøysundregistrene
«Sammensatte team» (frist 2026-11-22, så den haster).

**Produkt, utenfor oppdraget (gjenbruk, ingen parallell løsning):** en «DPS du kan søke nå»-liste. Den er et filter på `tenders`
(procedure = dps, fristen i framtiden) der eForm-kravene (`qualificationCriteria`, finnes allerede) kjøres mot
`qualify-requirements` og kompetansebanken (finnes allerede). Den gir ja/nei/mangler per ordning. Den samme motoren fungerer for kunder.

## 4. Hull, verdi, kostnad og risiko

- **Hull:**
  1. Ingen varighet i historikken, så radaren kan ikke testes bakover før varighet er hentet fra TED (`duration-period-*`) eller fra pre-eForms-teksten.
  2. 2025 mangler i backfillen.
  3. Minikonkurranser publiseres ikke på Doffin, så volumet i DPS er **UKJENT**.
  4. Prosedyre er ukjent for 43 % av kunngjøringene.
- **Verdi:** UKJENT i kroner. Én DPS-kvalifisering gir tilgang til alle framtidige minikonkurranser hos kjøperen i kategorien. Konkurrentene der er gjerne de samme konsulenthusene som i rammeavtalene.
- **Kostnad (ANTAKELSE):** 4–8 timer per DPS-søknad med gjenbruk av ESPD og firmaattest. DPS-lista i produktet tar 1–2 dager, siden motorene finnes.
- **Risiko:**
  - Eierskiftet og forsikringen er ikke på plass, og Brønnøysundregistrene har frist 22.11.
  - Manglende referanser kan stoppe oss på referansekrav.
  - «Fristen = varighet» er en antakelse. Les kunngjøringen før søknad.
  - Kvalifikasjonskravene i en DPS kan ikke endres (DFØ), så det vi mangler nå, mangler vi i hele varigheten.
