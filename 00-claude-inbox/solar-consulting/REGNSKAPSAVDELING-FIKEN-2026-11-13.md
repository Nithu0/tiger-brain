# Egen regnskapsavdeling: Fiken fra 1.1.2027, agenter gjør jobben

Oppdrag fra operatøren 13.11: «Ønsker egentlig å bytte regnskapsfører. Kan vi ikke gjøre det meste selv … egen Fiken? Målet vårt er å automatisere hele bedriften med AI-agenter, så vi må uansett ha en regnskapsavdeling, markedsføring, salg osv.» Go: «ja kjør».

## Beslutning (operatøren, 13.11)

- Solarconsulting AS fører regnskapet selv i **Fiken**, fra **1.1.2027**. Ecora Regnskap AS sies opp.
- En regnskapsfører dere kjenner, kontrollerer årsoppgjøret og skattemeldingen per time. Først årsoppgjøret for 2026.
- Agentene er regnskapsavdelingen. Et menneske godkjenner, sender inn og betaler.

Dette endrer anbefalingen i `drift/anbud/regnskap.md` (27.10: bli i DNB Regnskap på grunn av EHF og pris). Fiken koster mer (219 kr/mnd mot 129 kr/mnd i oktober), men har API, og Horizon har alt en Fiken-integrasjon (`lib/regnskap/fiken.ts`). Skriv det inn som en ny seksjon i `regnskap.md`. Ikke slett den gamle.

## Fakta fra drift (sjekk på nytt mot kilden)

- I dag føres regnskapet i DNB Regnskap (Uni Micro). Ecora står som regnskapsfører i Brreg.
- Vi er EHF-mottaker i ELMA via aksesspunktet til Uni Micro. **Registreringen må flyttes til Fiken samtidig**, ellers kommer ikke fakturaer fra det offentlige frem.
- Fra 1.1.2027 skal bokføringspliktige sende e-faktura til hverandre (bokføringsloven, Prop. 44 L). Dermed er årsskiftet et naturlig tidspunkt.
- Fiken-koden i Horizon lager bare fakturautkast.

## Fordeling

| Pane | Oppgave |
|---|---|
| admin-1 | **Sjekkliste for byttet, for Nithu (ett issue, `klar-for-nithu`, mobilvennlig):** opprett Fiken-konto og velg plan (pris hentet i dag), si opp Ecora (utkast i issuet, Nithu sender; finn oppsigelsestid som UNKNOWN hvis avtalen ikke ligger i drift), be om overlevering (bilag, saldobalanse, reskontro, MVA-meldinger, lønn hvis det finnes), fjern eller bytt regnskapsfører i Brreg (Samordnet registermelding), flytt EHF-mottaket i ELMA fra Uni Micro til Fiken, inngående balanse per 1.1.2027 og avtal årsoppgjøret for 2026. Hvert steg: lenke, frist og hvem som gjør det. |
| data-1 | **Regnskapsavdelingen som dokument** `drift/okonomi/regnskapsavdeling.md`: hva agentene gjør (bilag fra kvittering og faktura, bankavstemming, utkast til MVA-melding, purring, månedsrapport) og hva et menneske gjør (godkjenne, sende inn, betale, signere). Pluss en **fristkalender for 2027** for et AS uten ansatte (MVA-terminer, aksjonærregisteroppgaven, årsregnskap, skattemelding, a-melding hvis det blir lønn), hentet fra skatteetaten.no og brreg.no i dag, med dato. Pluss en ny seksjon i `anbud/regnskap.md` om beslutningen. |
| trading-1 | **Fiken-integrasjonen:** les (ikke endre) `horizon/lib/regnskap/fiken.ts` og det som finnes for økonomi i plattform og cc. Hent fra fiken.no i dag: vilkår for API-tilgang (pris, token eller OAuth, testselskap/sandkasse), og hvilke endepunkter vi trenger (kjøp, salg, kontakter, bank, bilag med vedlegg). Skriv en plan i `drift/okonomi/fiken-integrasjon.md`: kvittering lastet opp i plattformen under 03 Økonomi → broen lager **utkast** til bilag i Fiken med vedlegget → et menneske godkjenner. Mock først. Ingen nøkler før operatøren setter dem. |
| learning-1 | **Regler og sikkerhet:** et kort notat i `drift/okonomi/kontroll-og-ansvar.md`. Bokføringsloven og -forskriften: dokumentasjon, oppbevaring, hvem som har ansvaret (daglig leder og styret), hva kontrollen fra regnskapsføreren dekker, og at dere nå kan velge bort revisjon (terskler hentet i dag). Pluss agentregler: bare utkast i Fiken, aldri betaling, aldri innsending, revisjonsspor per bilag. Merk det `klar-for-jurist` hvis noe er uklart. |
| tools-1 | Fortsetter med Selskap-boksen. Legg deretter fristene fra data-1 inn i Oversikt («neste frist»), når kalenderen er merget. |
| paal-1 | QA av lenkene i sjekklisten fra admin-1 på mobilbredde. |
| infra-1 | Fortsetter med sitt. |

Etterpå: samme mønster for markedsføring og salg (eget dokument senere, ikke nå).

## Grenser

- **Ingen e-post til Ecora, Fiken eller andre.** Utkast i issuet. Nithu sender.
- Agentene oppretter ikke konto, logger ikke inn i Fiken, Altinn eller banken, sender ikke inn noe og flytter ikke penger.
- Ingen regnskapsdata, bilag, kontoutskrifter eller persondata i repo eller issues. Tall og bilag hører hjemme i Fiken og Drive.
- Lenker, priser og frister hentes i dag fra kilden, med dato, og merkes FACT, ASSUMPTION eller UNKNOWN.
- Små PR-er i drift, og merge selv når CI er grønn. STATUS til orchestrator-1 ved levert eller blokkert.

## Ferdig når

Nithu har ett issue med byttet steg for steg. Regnskapsavdelingen, fristkalenderen, Fiken-planen og kontrollnotatet er merget i drift. paal-1 har sjekket lenkene.
