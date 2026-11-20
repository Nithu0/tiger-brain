# Entur: kravmatrise for delområdet systemutvikling

data-1, 20.11.2026, bestilt av orchestrator-1.

**Konkurransen:** «Rammeavtale med flere leverandører vedr. utviklingstjenester knyttet til systemutvikling, plattform og IT-drift, sikkerhet, og data». Entur AS, saksnr. 20260008, åpen anbudskonkurranse.

**Kilder:**
- Doffin: https://doffin.no/notices/2026-117461
- TED: https://ted.europa.eu/en/notice/-/detail/783798-2026 (eForms-XML lastet ned 20.11)
- Kunngjøringen slik horizon har lagret den

Konkurransegrunnlaget ligger i TendSign bak innlogging, og der har jeg ikke vært. Alt som står som «se konkurransegrunnlaget» er derfor UNKNOWN.

## Konklusjon først

**Vi oppfyller ikke omsetningskravet alene.** Det kreves en omsetning på minst **70 mill. NOK** (eks. mva.) i siste tilgjengelige regnskapsår for delområdet systemutvikling. For sikkerhet og data er kravet 40 mill., og for plattform og IT-drift 70 mill. Selskapet har tre personer og er langt unna alle fire.

Den eneste veien inn er å **støtte seg på et annet foretak**. Kunngjøringen tillater det: «Leverandøren, og eventuelle støttende foretak, skal samlet ha …». Det betyr en partner som oppfyller omsetningskravet og forplikter seg i tilbudet. Uten en slik partner bør Entur tas ut av topp 5. Da rykker Nasjonalbiblioteket opp, men der må kredittkravet også sjekkes.

## Frister

| Hva | Frist (norsk tid) | Kilde |
|---|---|---|
| Spørsmål til oppdragsgiver | **03.12.2026 kl. 00:00**, i praksis innen utgangen av 02.12 | TED: AdditionalInformationRequestPeriod, 2026-12-02 23:00 UTC |
| Tilbud | **14.12.2026 kl. 12:00** | TED: TenderSubmissionDeadlinePeriod, 11:00:58 UTC |
| Åpning av tilbud | 14.12.2026 kl. 12:01 | TED: OpenTenderEvent |
| Vedståelsesfrist | 90 dager etter tilbudsfristen | TED: TenderValidityPeriod |
| Avtaleperiode | 01.03.2027–29.02.2028, med opsjon på 1+1+1+1+1 år (opptil seks år i alt) | TED: PlannedPeriod og Renewal |

## Kvalifikasjonskrav

| # | Krav (fra kunngjøringen) | Dokumentasjon | Oppfyller vi? | Hva mangler / issue |
|---|---|---|---|---|
| K1 | Ordnede forhold for skatt og avgift, også for eventuelle støttende foretak | Attest for skatt og merverdiavgift fra Altinn, ikke eldre enn 6 måneder ved tilbudsfristen | **UNKNOWN** | Attesten ble hentet 13.11 og er gyldig 14.12 (drift#2). Men mva-situasjonen er uavklart: det har kommet brev fra Innkrevingsmyndigheten, og terminene for 2026 er ukjente (drift#353). Viser attesten restanser, må det forklares. Avklar #353 først. |
| K2 | Tilstrekkelig økonomisk og finansiell kapasitet i hele avtaleperioden (krav 1) | Utvidet kredittvurdering, ikke eldre enn 3 måneder, med karakter **A** eller bedre, basert på siste regnskap. Nystartede selskaper (rating AN) kan bruke andre dokumenter som oppdragsgiver godtar. | **UNKNOWN** | Creditsafe-rapporten venter på svar utenfra (drift#190). Selskapet er ikke nystartet, men eierskiftet skjedde i 2026, så unntaket for AN gjelder trolig ikke. |
| K3 | Minimumsomsetning i siste tilgjengelige regnskapsår (krav 2): **70 mill. NOK** for systemutvikling (40 for sikkerhet og data). Kravene legges ikke sammen ved tilbud på flere delområder. | Utdrag av siste regnskap, eventuelt via kredittrapporten | **NEI** | Bare mulig med et støttende foretak som oppfyller kravet. Vi har ingen slik partner i dag, og det finnes ingen issue for det. |
| K4 | Autorisasjon eller medlemskap i en bestemt organisasjon | «Se konkurransegrunnlaget» | **UNKNOWN** | Konkurransegrunnlaget må lastes ned fra TendSign (Nithu). |
| K5 | Tekniske og faglige krav: erfaring, referanser, nøkkelpersonell, kvalitetssikring | Står ikke i kunngjøringen | **UNKNOWN** (trolig delvis NEI) | Vi har ingen egne IT-referanser etter eierskiftet (drift#41). CV-er mangler: Nithus samtykke er nei, og Tintuns CV er ikke ferdig (drift#42). Kvalitetssystemet er i v0.95 (drift#31). |
| K6 | Avvisningsgrunner (korrupsjon, svindel, konkurs, skatt, interessekonflikt og så videre), i ESPD | Egenerklæring i ESPD | **JA**, så vidt vi vet | ESPD fylles ut i TendSign. Ingenting tyder på at noen avvisningsgrunn gjelder. |
| K7 | Registrering i foretaksregister | Firmaattest (vanlig krav i ESPD) | **JA** | Firmaattesten ble hentet 13.11 (drift#3). |

## Tildelingskriterier og vekter

| Kriterium | Vekt | Underkriterier | Status for oss |
|---|---|---|---|
| Kvalitet | **75 %** | «Se konkurransegrunnlaget» | UNKNOWN. Kvalitet veier tre ganger så mye som pris. Det betyr trolig at CV-er, oppdragsforståelse og referanser teller mest, og det er der vi er svakest (drift#41, #42). |
| Pris | **25 %** | «Se konkurransegrunnlaget» | Vi har ingen timepris (avgjort 18.10). Den må settes før tilbudet. |

Avtalen er en rammeavtale med flere leverandører og ny konkurranse ved avrop («fa-w-rc» i TED). Å komme inn på avtalen gir ikke oppdrag i seg selv. Hvert oppdrag konkurreres ut på nytt mellom dem som er med.

## Skal-krav i kunngjøringen (kontrakt og innlevering)

| Krav | Oppfyller vi? | Merknad |
|---|---|---|
| Elektronisk innlevering (i TendSign) | **JA**, med forbehold | TendSign-kontoen finnes (15.11). Passordet bør byttes, fordi det står i klartekst i velkomst-e-posten. |
| Elektronisk faktura (påkrevd) | **UNKNOWN** | Fiken kan sende EHF, men det er ukjent om det er satt opp for selskapet. |
| Elektronisk bestilling og betaling brukes | **JA** | Ingen særkrav. |
| Ingen alternative tilbud. Bare ett tilbud per leverandør. | **JA** | Vi byr på ett delområde. |
| Ingen tilbudsgaranti | **JA** | |
| Ingen sikkerhetsklarering | **JA** | |
| Ingen krav til selskapsform for sammenslutninger | **JA** | Det gjør et samarbeid med en partner enklere. |
| Lønns- og arbeidsvilkår, miljø og skatt (henvisning til regelverk) | **UNKNOWN** | Detaljene står i konkurransegrunnlaget. Lønns- og arbeidsvilkår henger sammen med lønn ja eller nei i uke 50 (drift#64). |
| Egnet for SMB | Ja, ifølge oppdragsgiver | Merket SME-suitable i TED. Omsetningskravet trekker motsatt vei. |

## Hva som må til for å by (i rekkefølge)

1. **Avgjør om vi vil ha en partner.** Uten et støttende foretak med minst 70 mill. NOK i omsetning kan vi ikke kvalifisere oss. Uten partner stopper det her.
2. **Kredittvurderingen** (drift#190). Rapporten må ha karakter A og være utstedt etter 14.09.
3. **Avklar mva** (drift#353) før skatteattesten brukes.
4. **Last ned konkurransegrunnlaget** fra TendSign (Nithu logger inn selv). Da kan K4, K5 og underkriteriene fylles inn.
5. **Spørsmålsfrist 02.12:** spør Entur om de godtar erfaring fra nøkkelpersonell (CV) i stedet for selskapsreferanser, og om de godtar kredittvurdering for et selskap med nylig eierskifte.
6. **CV-er og referanser** (drift#41, #42), og en **timepris**.

## Forbehold

- Bare kunngjøringen er lest (Doffin/TED og horizon), ikke konkurransegrunnlaget.
- Omsetningen er ikke sjekket mot regnskapstall. Svaret NEI bygger på at selskapet har tre personer og er langt fra 70 mill.
- Den engelske TED-teksten skriver «system external» for systemutvikling. Det er en oversettelsesfeil, og den norske Doffin-teksten sier «delom. systemutv.».
