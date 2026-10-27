# Leveranseklar-sjekkliste: dokumentasjon for offentlige IT-oppdrag

Solarconsulting AS · utarbeidet 2026-10-18 (researcher-agent for admin-1, etter kompetanseintervju med Nithusan) · kilder hentet 2026-10-18 · merking: FACT / ASSUMPTION / UNKNOWN
`EXPERIMENTAL`: ikke gjennomgått av jurist.

## Topp 5 før første tilbud (i rekkefølge)

1. **Kvalifikasjonspakke**: oppdatert firmaattest etter eierskiftet (uke 43), skatteattest, siste årsregnskap, 2–3 referanseoppdrag, CV-er for de 3 konsulentene og en ferdig utfylt ESPD-mal.
2. **Databehandleravtale-mal (art. 28) og underdatabehandlerliste** (Azure, Anthropic, ev. Railway/Vercel), med DPA og overføringsgrunnlag på plass for hver av dem.
3. **Beskrivelse av kvalitetssikringssystemet** (2–4 sider). Den dekker kriteriet slc-sche-qu-cert-indep, selv uten ISO-sertifikat.
4. **Minimum internkontroll for informasjonssikkerhet** med avviksrutine (varsle kunden uten ugrunnet opphold, kunden melder innen 72 t).
5. **Ansvarsforsikring** (bindende tilbud eller bekreftelse), pluss egenerklæring om lønns- og arbeidsvilkår og HMS-internkontroll.

## Viktig regelendring 1.7.2026

FACT: Anskaffelsesforskriften §7-2 (skatteattest) og §7-9 (klima/miljø) er opphevet fra 1.7.2026. Samfunnshensynene står nå i anskaffelsesloven §§ 5a–5p. Forskrift om lønns- og arbeidsvilkår i offentlige kontrakter er også opphevet, og reglene er flyttet til loven [1][2][3]. Loven gjelder fra 500 000 kr ekskl. mva. (§2) [1]. Kunngjøringsplikt for tjenester gjelder fra 1,3 MNOK (forskriften §5-1). EØS-terskel er 1,63 MNOK for statlige og 2,5 MNOK for andre oppdragsgivere (§5-3) [2][4]. Eldre maler og veiledere som viser til §7-9 eller §7-2, er utdatert.

Status: **M** = mangler, **D** = delvis, **F** = finnes. Prioritet: **Må** = før første tilbud, **Bør**, **Kan vente**.

## A. Kvalifikasjon og ESPD-attester

| Punkt | Hva | Hjemmel / type | Pri | Innsats | Status |
|---|---|---|---|---|---|
| Firmaattest (slc-suit-reg-trade) | Utskrift fra Foretaksregisteret | Vanlig krav. Oppdragsgiver *kan* kreve registrering (forskr. §16-2) [2] FACT | Må | 0,5 t, men oppdater styre/daglig leder etter eierskiftet | D |
| Skatteattest (skatt + mva) | Fra Altinn, maks 6 mnd gammel ved tildeling | **Lovkrav**: oppdragsgiver *skal* kreve den av valgt norsk leverandør (lov §5l) [1] FACT | Må | 0,5 t | D. Hentbar. Restanser: UNKNOWN |
| Økonomisk kapasitet (slc-stand-other) | Årsregnskap, ev. kredittvurdering | Vanlig krav. Omsetningskrav maks 2× kontraktsverdi som hovedregel (forskr. §16-3, del III) [2] FACT | Må | 1 t | UNKNOWN (regnskapstall ikke oppgitt) |
| Referanser (slc-abil-ref-services) | 2–3 lignende oppdrag: kunde, verdi, år, kontaktperson | Vanlig krav (forskr. §16-5/16-6) [2] FACT | Må | 4–8 t | UNKNOWN. ASSUMPTION: konsulentenes personlige referanser i CV kan delvis kompensere |
| CV-er | Standardisert CV per konsulent | Vanlig krav | Må | 1 dag | UNKNOWN |
| Underleverandører (slc-abil-subc) | Liste over hvem som gjør hva, støtteerklæring ved behov (forskr. §16-10) | Vanlig krav [2] | Må | 1 t | M |
| ESPD / egenerklæring | Ferdig utfylt mal. Under EØS-terskel kan oppdragsgiver bruke egenerklæring (forskr. §8-10), over terskel ESPD (§17-1) [2] FACT | Lovregulert format | Må | 2 t | M |

## B. Personvern / GDPR

Selskapet blir som regel *databehandler* for kunden og *behandlingsansvarlig* for egne data.

| Punkt | Hva | Hjemmel / type | Pri | Innsats | Status |
|---|---|---|---|---|---|
| Databehandleravtale-mal | Må dekke art. 28 nr. 3 bokstav a–h (instruks, taushet, art. 32-sikkerhet, underdatabehandlere, bistand, sletting/retur, revisjon) [5][6] FACT. Bruk DFØs mal og sjekkliste [7] | **Lovkrav** når vi behandler personopplysninger for kunden | Må | 1 dag | M |
| Underdatabehandlerliste | Navn, formål, lokasjon, overføringsgrunnlag. Krever forhåndsgodkjenning fra kunden, og ved generell godkjenning varsel om endringer (art. 28 nr. 2) [5] FACT | Lovkrav | Må | 2 t | M |
| DPA med egne leverandører | Anthropic: DPA med SCC (modul 2/3) er del av Commercial Terms, med underdatabehandlerliste og varsling av brudd innen 48 t [11] FACT. Gjelder kommersielle planer, ikke forbrukerplaner [11] FACT (medium). Microsoft Azure: ASSUMPTION at Microsofts DPA gjelder automatisk (ikke verifisert). Railway/Vercel: UNKNOWN region og DPA. Anbefaling: ingen kundedata der | Lovkrav | Må | 4 t | M |
| Tredjelandsoverføring (Anthropic US) | DPF-beslutningen gjelder fortsatt, men bare for selvsertifiserte selskaper på DPF-listen [10] FACT. Anthropics DPA bygger på SCC, ikke DPF [11] FACT. Anthropic på DPF-listen: UNKNOWN. Dokumenter SCC og en kort overføringsvurdering | Lovkrav (art. 44–46) | Må | 4 t | M |
| Avviksrutine | Databehandler varsler kunden uten ugrunnet opphold (art. 33 nr. 2). Behandlingsansvarlig melder til Datatilsynet innen 72 t (art. 33 nr. 1) [9] FACT. Melding går via Altinn [12] FACT | Lovkrav | Må | 2 t | M |
| Protokoll (art. 30) | Egen protokoll som behandlingsansvarlig, og databehandlerprotokoll (art. 30 nr. 2) [8] FACT. Unntaket for under 250 ansatte gjelder ikke når behandlingen ikke er sporadisk eller innebærer risiko [8] FACT. ASSUMPTION: unntaket gjelder ikke oss | Lovkrav | Bør | 3 t | M |
| DPIA-mal (art. 35) | Mal for vurdering av personvernkonsekvenser. Det er kunden som er ansvarlig, vi bistår (art. 28 nr. 3 f) [5] FACT. Innholdskrav i art. 35: ikke verifisert i denne runden | Lovkrav for kunden ved høy risiko. Ofte etterspurt for KI | Bør | 1 dag | M |

## C. Informasjonssikkerhet (minimum internkontroll)

FACT: Det finnes ikke noe eget lovkrav om ISMS for et privat konsulentselskap. Kravene kommer via GDPR art. 32 og databehandleravtalen, og via oppdragsgivers egne plikter. Oppdragsgiver *kan* stille sikkerhetskrav i alle ledd (lov §5d) [1]. Digdirs «Internkontroll i praksis» bygger på ISO/IEC 27001 [13], og NSMs grunnprinsipper for IKT-sikkerhet v2.1 har 4 kategorier, 21 prinsipper og 118 tiltak [14].

Minimum for oss (ASSUMPTION, tilpasset 3 personer). **Må**, ca. 2–3 dager, status M:
- 1 side sikkerhetspolicy med ansvarlig person
- risikovurdering per kundeoppdrag (NSMs mal)
- tilgangsstyring med MFA, minste privilegium og offboarding
- oversikt over systemer og data (hvor kundedata ligger: Azure EU)
- logging og backup
- håndtering av hemmeligheter og nøkler
- avviks- og hendelseslogg
- årlig gjennomgang

Skriv det som et utdrag av NSMs kategorier «Identifisere og kartlegge / Beskytte og opprettholde / Oppdage / Respondere».

## D. Kvalitet («kvalitetssikringssystem»)

FACT: Oppdragsgiver kan kreve sertifikat (ISO 9001 o.l.), men *skal* godta annen dokumentasjon for tilsvarende tiltak når leverandøren ikke kan skaffe sertifikat innen fristen av grunner som ikke skyldes leverandøren selv (forskr. §16-7 (3)) [2]. ASSUMPTION: for kriteriet slc-sche-qu-cert-indep under terskel holder ofte en beskrivelse. Les hver konkurranse.

Beskrivelsen (2–4 sider, **Må**, ca. 1 dag, status M) bør dekke:
- ansvar og roller
- oppdragsprosess (oppstart → leveranse → avslutning)
- kodegjennomgang, test og CI
- dokumentasjon og overlevering
- avvik og forbedring
- kundeoppfølging og statusrapportering
- kompetansestyring
- bruk av KI-verktøy (kontroll av KI-generert kode og data)
- årlig gjennomgang

ISO 9001/27001: Kan vente.

## E. Kontrakt (Statens standardavtaler) [15][16]

| Avtale | Passer når | Relevans |
|---|---|---|
| **SSA-B / SSA-B enkel** (2026-versjon) | Konsulentbistand der *kunden* styrer arbeidet. Timesalg | Hovedavtale for oss. FACT |
| **SSA-O** | Oppdrag med spesifisert leveranse der konsulenten har selvstendig resultatansvar | Fastprisoppdrag og KI-leveranser. FACT |
| **SSA-T** | Utvikling eller tilpasning av programvare | Større utviklingsprosjekter. FACT |
| **SSA-L** | Løpende kjøp av standardiserte tjenester over internett | Bare hvis vi selger drift av egen plattform. Ikke for timesalg. FACT |

Å vite:
- DFØ anbefaler å vise til lov §5e i stedet for den opphevede lønnsforskriften inntil SSA-ene er oppdatert [16] FACT.
- DFØ advarer om at SSA-B brukt til å dekke midlertidig kapasitetsbehov kan bli ulovlig innleie [16] FACT.
- Ansvarsbegrensning og forsikringskrav i SSA-B 2026: ikke lest. UNKNOWN.

Lær SSA-B og SSA-O (**Må**, 0,5 dag).

## F. Annet

| Punkt | Hva | Hjemmel / type | Pri | Innsats | Status |
|---|---|---|---|---|---|
| Ansvarsforsikring | Profesjonsansvar. Oppdragsgiver kan kreve «relevant ansvarsforsikring» (forskr. §16-3 (1) c) [2] FACT | Vanlig krav | Må | Ekstern, 1–2 uker | M (kommer etter eierskiftet) |
| Lønns- og arbeidsvilkår | Gjelder **tjenestekontrakter** ≥ kunngjøringsplikt: allmenngjort tariff eller landsomfattende tariffavtale for bransjen (lov §5e), dokumentasjon på forespørsel [1] FACT. Hvilken tariff som gjelder IT-konsulenter: UNKNOWN. Lærlingkrav (§5h) krever bl.a. fag/svennebrev-relevans og særlig behov for læreplasser [1] FACT. Om det gjelder IT: UNKNOWN | Lovkrav i kontrakten | Må (egenerklæring) | 1 t | M |
| HMS-egenerklæring | Internkontroll etter internkontrollforskriften §5: skriftlige mål, ansvar, risikovurdering, rutine for overtredelser, gjennomgang, tilpasset størrelse [17] FACT | Lovkrav (har ansatte) + vanlig tilbudskrav | Må | 3 t | M |
| Klima/miljø | Oppdragsgiver skal vekte klima/miljø ≥ 30 % (eller topp 3 ved prioritering) i **kunngjøringspliktige** anskaffelser. Kan erstattes eller kombineres med krav i kravspesifikasjonen hvis det gir bedre effekt. Unntak: uvesentlig klimaavtrykk, vesentlige helse-/sikkerhets-/beredskapsinteresser, standardiserte minimumskrav (lov §5b, §5c) [1] FACT. ASSUMPTION: konsulenttimer blir ofte vurdert som uvesentlig avtrykk, men det varierer | Lovkrav for oppdragsgiver | Bør: 1 side om reiser, digitale møter, Azure EU-region og energi | 3 t | M |
| Åpenhetsloven | Gjelder «større virksomheter» som overstiger 2 av 3: salgsinntekt 70 MNOK, balanse 35 MNOK, 50 årsverk (§3) [18] FACT | Gjelder ikke oss | Kan vente | 0 | Ikke aktuelt |
| Miljøledelse / ISO 14001 | Kan kreves (forskr. §16-7 (2)) [2] | Sjelden under terskel (ASSUMPTION) | Kan vente | Høy | M |

## Kilder (alle hentet 2026-10-18)

1. Anskaffelsesloven, versjon i kraft 1.7.2026 (§§ 2, 5b–5e, 5h, 5l): https://lovdata.no/dokument/NL/lov/2016-06-17-73
2. Anskaffelsesforskriften (§§ 5-1, 5-3, 8-7, 8-10, 16-2, 16-3, 16-7, 16-10, 17-1; §7-2 og §7-9 opphevet): https://lovdata.no/dokument/SF/forskrift/2016-08-12-974
3. Regjeringen, «Endringer i anskaffelsesregelverket» (21.04.2026): https://www.regjeringen.no/no/aktuelt/endringer-i-anskaffelsesregelverket/id3156716/
4. Regjeringen, nye EØS-terskelverdier (2026): https://www.regjeringen.no/no/aktuelt/nye-terskelverdier-for-kunngjoring-av-anskaffelser-i-eos-er-vedtatt/id3156894/
5. GDPR art. 28: https://lovdata.no/dokument/NL/lov/2018-06-15-38/gdpr/ARTIKKEL_28
6. GDPR art. 33: https://lovdata.no/dokument/NL/lov/2018-06-15-38/gdpr/ARTIKKEL_33
7. DFØ, databehandleravtale og sjekkliste (via SSA-oversikt): https://www.anskaffelser.no/anskaffelsesregelverk/statens-standardavtaler-ssa
8. GDPR art. 30: https://lovdata.no/dokument/NL/lov/2018-06-15-38/gdpr/ARTIKKEL_30
9. Datatilsynet, melde avvik: https://www.datatilsynet.no/rettigheter-og-plikter/virksomhetenes-plikter/avvik/meld-avvik-til-datatilsynet/
10. Datatilsynet, overføringer til USA: https://www.datatilsynet.no/aktuelt/aktuelle-nyheter-2025/informasjon-om-overforinger-til-usa/ og https://www.datatilsynet.no/aktuelt/aktuelle-nyheter-2025/eu-domstolen-opprettholder-adekvansbeslutningen-for-usa/
11. Anthropic DPA: https://www.anthropic.com/legal/data-processing-addendum og https://privacy.claude.com/articles/7996862
12. Se 9 (Altinn-skjema)
13. Digdir, Internkontroll i praksis: https://www.digdir.no/informasjonssikkerhet/om-internkontroll-i-praksis-informasjonssikkerhet/3177
14. NSM, grunnprinsipper for IKT-sikkerhet 2.1: https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/ta-i-bruk-grunnprinsippene/
15. Se 7 (SSA-oversikt)
16. DFØ, SSA-B: https://www.anskaffelser.no/verktoy/mal/ssa-b-og-ssa-b-enkel-bistandsavtalene
17. Internkontrollforskriften §5: https://lovdata.no/dokument/SF/forskrift/1996-12-06-1127
18. Åpenhetsloven §3: https://lovdata.no/dokument/NL/lov/2021-06-18-99

## Åpne spørsmål (UNKNOWN)

- Står Anthropic på DPF-listen, og hvilken Anthropic-enhet er avtalepart på business-planen?
- Microsoft Azure: DPA og EU Data Boundary er ikke verifisert.
- Railway og Vercel: region og DPA.
- Hvilken landsomfattende tariffavtale gjelder IT-konsulenter etter §5e?
- Ansvarsbegrensning og forsikringskrav i SSA-B 2026.
- Holder egne referanser etter eierskiftet? Avklar om tidligere oppdrag tilhører selskapet eller personene.
