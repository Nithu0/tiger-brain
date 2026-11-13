# Etter eierskiftet: Altinn, attester og alt som ventet

Oppdrag fra operatøren 13.11: «vi må kjøre videre nå som bedriften Solar Consulting er på plass. Vi kan få opp Altinn osv!!»

## Fakta (Brreg, åpent API, hentet 13.11 kl. 13)

- Solarconsulting AS, org.nr. 931949837, MVA-registrert, i Foretaksregisteret. Adresse: Osterhaus' gate 10, 0183 Oslo. Næringskode 71.129 (#208 vil endre den).
- **Roller endret 11.11:** daglig leder og styrets leder er Nithusan Kukaraja. Styremedlemmer er Alper Adiyaman og Tin Tun Naing. Regnskapsfører er Ecora Regnskap AS.
- **Reelle rettighetshavere:** ikke synlig i det åpne API-et, så status er UNKNOWN. Nithu sjekker det i Altinn eller på brreg.no.
- 31 åpne issues i drift har `venter:eierskifte`. Se listen i drift.

## Mål

Nithu kan gjøre hele Altinn-runden fra telefonen med BankID, i riktig rekkefølge og med én lenke per steg. Alt agentene kan gjøre uten BankID, er gjort før han begynner.

## Fordeling

| Pane | Oppgave |
|---|---|
| admin-1 | **Altinn-runden for Nithu:** ett issue i drift (`klar-for-nithu`, mobilvennlig), med stegene i rekkefølge og lenker hentet og sjekket i dag. Steg: logg inn og velg Solarconsulting AS, sjekk at Nithu er hovedadministrator, skatteattest (#2), firmaattest (#3), reelle rettighetshavere (#4), næringskode (#208), gi Alper og Tintun tilgang med riktige tilgangspakker (Altinn 3: Altinn II-roller fases ut 31.12.2026), delegering for Maskinporten (#11), Digdir-vilkår (#9, #10). Hvert steg sier hva som er ferdig, og hvilket issue som lukkes. Oppdater `tilganger/digdir-ksfiks.md` der eierskiftet var en forutsetning. |
| data-1 | **Anbudspakken:** fyll felt merket ⏳ eierskifte i `anbud/espd.md`, `anbud/tilbudsmaler/tilbudsbrev.md` og `juridisk/` (signaturrett, daglig leder, behandlingsansvarlig) med det Brreg viser. Ingen fødselsnummer. Legg en utskrift av Enhetsregisteret (offentlige data fra API-et, dato på) i `anbud/attester/`, og merk at firmaattest og skatteattest fra Nithu kommer i tillegg. |
| trading-1 | **Labels og beskjeder i drift:** fjern `venter:eierskifte` fra issues som nå er låst opp, og la den stå der noe fortsatt mangler (for eksempel skatteattest), med en kommentar som sier hva. Gi Alper beskjed på DPS-issuene. **#136 Brønnøysundregistrene har frist 22.11.2026**, og DPS-ene trenger skatteattest og firmaattest. Gi juristen beskjed på #19 (DPA) om hvem som er signaturberettiget. Logg i drift#198 at Tintun nå er styremedlem. |
| learning-1 | **Maskinporten-test, klar til bruk:** forbered testklienten (#12) så den kan lages med en gang delegeringen (#11) er gjort: generering av JWK-nøkkelpar lokalt (privat nøkkel bare i Key Vault eller i en lokal fil med 600-tilgang, aldri i git), stegene i selvbetjeningen og en test som henter token. Ikke send noe til Digdir. |
| tools-1 | **Plattformen:** en kort «Selskap»-boks i Oversikt med org.nr., roller og MVA-status fra Brreg (åpne data, hentet av broen eller direkte, cachet), og lenker til Altinn og brreg. Ingen persondata utover navn og rolle. |
| paal-1 | **QA av Altinn-runden:** åpne hver lenke i issuet fra admin-1 på mobilbredde, og sjekk at den går dit teksten sier, og at rekkefølgen holder. Meld feil til admin-1. |
| infra-1 | Fortsetter med sitt. |

## Grenser

- **Agenter logger ikke inn i Altinn, ID-porten eller Ansattporten, og sender ikke inn noe.** Det gjør Nithu med BankID.
- Ingen e-post eller invitasjoner til eksterne. Kommentarer i drift er greit.
- Ingen fødselsnummer, personnummer eller adresser til privatpersoner i repo eller issues. Navn og rolle fra Brreg er greit.
- Lenker og fremgangsmåter hentes i dag fra kilden (altinn.no, brreg.no, skatteetaten.no, digdir), med dato. Ikke fra hukommelsen. Marker FACT, ASSUMPTION eller UNKNOWN.
- Små PR-er i drift, og merge selv. STATUS til orchestrator-1 ved levert eller blokkert.

## Ferdig når

Nithu har ett issue med Altinn-runden. paal-1 har sjekket alle lenkene. Låste issues har riktige labels, og Alper og juristen har fått beskjed.
