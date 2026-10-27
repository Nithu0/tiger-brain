# Veldora som intelligensplattform: strategisk vurdering

orchestrator-1, 2026-10-19. Bygger på fire målinger mot prod (read-only, 18.–19.10) fra paal-1 (DPS og prediksjon), data-1 (kunnskapsgraf), trading-1 (teknologikart) og admin-1 (offisielle API-er). Kildefilene ligger i samme mappe.
Merking: **D** = dokumentert i kunngjøringen eller kilden, **E** = etterspurt i et anbud, **A** = antakelse eller statistikk.

## 1. Hva vi allerede kan

| Område | I dag (målt) | Merknad |
|---|---|---|
| Kunngjøringer | 110 059, med full rå-eForm for 108 000 | 2021–24 og fra sept. 2026. **Hull: jan. 2025–sept. 2026 (~62 000)**, og det tettes nå (infra-1). |
| Kjøpere | 1 500 med org.nr. (500 kommuner, 301 stat) | God identitet. |
| Vinnere per delkontrakt | 30 315 rader, 10 582 leverandører | **Bare 44 % har org.nr.** Det største hullet for markedskart. |
| Tildelinger med verdi og sluttdato | 387 (2026) | Historikken åpnes med inntil 2 000 per natt fra 19.10. |
| Krav med sitat (kravagent) | 892 rader på 169 muligheter | E-bevis på teknologi og kompetanse. |
| Teknologi i tekst | 1 274 kunngjøringer hos 256 kjøpere (ordliste, presisjon 98 %) | ~5× med eForm-tekst fra rå-arkivet, gratis. |
| Agenter | krav, konkurranse, tilbud, pris (av), kjøperresearch (av), overvåker B (skygge), læringsløkke | Hendelseskjeden er lukket (#256). |

**Det vi ikke kan**, og som ingen offentlig API gir: levere tilbud, kommunisere med kjøpere eller se hvilken kommune som bruker hvilket fagsystem. Tilbud går via KGV. Fiks og Dialogporten er bare for tjenesteeiere (D, admin-1). Verdien vår ligger i innhenting og tolkning.

## 2. De fem mest verdifulle mulighetene

Skala 1–5 (5 er best). Kostnad: 5 = billig.

| # | Mulighet | Kommersielt | Datagrunnlag | Kostnad | Gjennomførbar | Fortrinn | Sum |
|---|---|---|---|---|---|---|---|
| 1 | **DPS-motor: «ordninger vi kan kvalifisere oss til nå»** | 5 | 4 | 5 | 4 | 3 | **21** |
| 2 | **Leverandøridentitet → markedskart, sittende leverandør, partnerkandidater** | 4 | 4 | 5 | 5 | 4 | **22** |
| 3 | **Teknologi- og systemskifte-radar (kommunale forvaltningssystemer)** | 4 | 3 | 4 | 4 | 5 | **20** |
| 4 | **Partner- og underleverandørspor** (inn via store rammeavtalevinnere) | 4 | 4 | 4 | 4 | 3 | **19** |
| 5 | **Gjenkjøpsprediksjon i radar og brief** (49 % kjøper samme IT-CPV-5 igjen innen 24 mnd, median 16,6 mnd; november er toppen) | 3 | 4 | 5 | 5 | 3 | **20** |

**1. DPS-motor.** 210 åpne dynamiske innkjøpsordninger nå, 42 innen IT (D). Én kvalifisering gir løpende minikonkurranser i hele varigheten, uten referanse fra én stor konkurranse (D, DFØ). Konkrete ordninger: Brønnøysundregistrene «Sammensatte team» (frist 22.11), Sjøfartsdirektoratet «Analytics/ML» og «Utviklere/techlead» (31.12), Vinmonopolet, Digdir, Entur, Mattilsynet og Flytoget. Dette er den raskeste realistiske veien til første kontrakt i år. Blokkere: ansvarsforsikring (uke 43) og IT-referanser (A: noen ordninger har bare 2 krav).

**2. Leverandøridentitet.** Koble de 30 315 vinnerne til org.nr. via den eksisterende `supplier-brreg-match`. Det gir riktige markedsandeler per segment og fylke, **sittende leverandør** på hver mulighet i spill (`opportunities.incumbent_id` finnes, men er tom), og grunnlaget for 3 og 4. Ingen modell. Billigst, og løfter alt annet.

**3. Teknologi- og systemskifte-radar.** Dokumentert «dagens installasjon» («bruker i dag ePhorte», «Visma Profil fases ut», «erstatte Oracle») fra eForm-teksten, koblet til hvem som leverte og når avtalen går ut. Det gir varsel 6–18 mnd før et bytte og treffer den eneste klyngen med gjentatte ja fra teamet: kommunale forvaltningssystemer (TRE-SCOPES). Kan på sikt selges som innsikt til leverandører, men lisensen for Doffin-data må avklares med DFØ først. Varig fortrinn: ingen andre bygger dette registeret fra kildene.

**4. Partner- og underleverandørspor.** Leverandører som vinner sammen (Asplan Viak+Norconsult 28, Sweco+COWI 20 …) og vinnerne av IT-rammeavtaler er naturlige oppdragsgivere for et lite team uten egne referanser. En liste per mulighet, «hvem kan vi gå inn under», gir referanser raskere enn å vinne alene. Bygger på 2.

**5. Gjenkjøpsprediksjon.** Statistikken finnes (A, paal-1). Legg den inn som et andre signal i radaren og morgenbriefen («Sykehusinnkjøp lyser trolig ut DIPS-relatert i Q1»), og prioriter salgsarbeid før toppen i november.

Vurdert og nedprioritert:
- **Kunnskapsgraf som egen database:** grafen finnes som relasjoner. En view og én samling holder (data-1).
- **KS Fiks, Maskinporten og Dialogporten:** gir ingen markedsinnsikt eller kjøperkanal nå.
- **Kommunal Rapports leverandørdatabase:** betalt, pris ukjent. Vurderes etter 3.

## 3. Raske forbedringer (bygges nå, ingen migrering, kan reverseres)

| Hva | Eier | Merknad |
|---|---|---|
| Tette 2025–26-hullet (~62 000 kunngjøringer) + TED-rettelse (78 % → ~100 %) | infra-1 | Pågår, godkjent. |
| Heve awards-taket 2 000 → ~8 000 per natt etter at natt 1 er målt | orchestrator-1 | Env, kan reverseres. |
| DPS-liste med kvalifiseringsvurdering per ordning (filter på `tenders` + `qualify-requirements` mot kompetansebanken), signal og panel | paal-1 + tools-1 | Mulighet 1. |
| Leverandøridentitet: fyll `suppliers` fra vinnerne, la Brreg-matchingen løpe, fyll `incumbent` på mulighetene | data-1 | Mulighet 2. |
| Teknologi-ordliste på eForm-tekst inn i kjøperprofilen (signal, ingen tabell) | trading-1 | Grunnlag for 3. Eval: presisjon ≥ 0,9 på 100 treff som et menneske merker. |
| Gjenkjøpssignal i radar og brief | paal-1 (etter DPS) | Mulighet 5. |

## 4. Langsiktige investeringer (venter på godkjenning)

1. **Kunnskapsgraf-migrering:** view `graf_kanter` + samling `teknologi_omtaler` (D/E/A, sitat, dato). Én migrering.
2. **Flytte Doffin-innhentingen** fra det udokumenterte webclient-API-et til Public API (nøkkel, `/download`). **E-post til DFØ om vilkår og lisens** sendes av operatøren (ekstern melding).
3. **Microsoft Graph mot egen anbudsinnboks:** korrespondanse kobles til muligheten. Krever app-registrering i egen tenant (operatør).
4. **Salg av innsikt (mulighet 3) til leverandører:** forutsetter lisensavklaring og en egen kundeportal.
5. **Haiku-klassifisering av teknologitreff** (~20 USD én gang): skiller dokumentert bruk fra etterspørsel og omtale.

## 5. Arkitektur for høyest prioriterte mulighet: DPS-motor (1)

Gjenbruk alt. Ingen ny database og ingen migrering i første versjon.

1. **Utvalg (kode):** `tenders` der prosedyren er DPS, ordningen er åpen (fristen er i framtiden, A: frist = varighet, sjekkes mot kunngjøringen) og CPV eller kategori er innenfor scope. Delkontrakter = kategorier.
2. **Krav:** eForm-kvalifikasjonskriteriene (reparert 18.10, nå med navn og beskrivelse) + kravagenten på kunngjøringen. Når operatøren laster opp DPS-dokumenter (`dokumenter:last-opp`), leses de av kravagenten.
3. **Vurdering:** `qualify-requirements` mot kompetansebanken per kategori. Resultatet er **kan søke / mangler X / kan ikke**, med sitat og bevis-id. Det vi mangler (forsikring, referanser, miljø), samles på tvers av ordninger, så vi ser hva som låser opp flest.
4. **Visning:** signal `dps.qualifiable` → innboks, morgenbrief («3 IT-ordninger du kan søke nå, Brønnøysundregistrene stenger 22.11») og et panel «Ordninger vi kan søke» i dashbordet.
5. **Hendelser:** ny DPS-kunngjøring → vurdering. Endring i kompetansebanken (intervju, forsikring) → ny vurdering av alle åpne ordninger.
6. **Måling:** et menneske sjekker vurderingen på 10 ordninger mot kunngjøringen (presisjon på «kan søke» ≥ 0,9). Læringsløkka registrerer søkt, tatt opp og minikonkurranser vunnet.
7. **Senere:** én migrering hvis vi vil lagre opptaksstatus per ordning (søkt, tatt opp, avvist).

## 6. Hva operatøren må ta stilling til

- **Søk opptak** i Brønnøysundregistrene «Sammensatte team» (frist 22.11) og Sjøfartsdirektoratet (31.12) når forsikringen er på plass i uke 43.
- **Godkjenne** kunnskapsgraf-migreringen (4.1) og retningen «systemskifte-radar» (3).
- **Sende** e-post til DFØ om vilkårene for Doffin-API-et (4.2).
