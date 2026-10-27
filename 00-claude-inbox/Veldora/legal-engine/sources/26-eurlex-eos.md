# EU/EØS-rettskildene bak FOA — kildekartlegging fase 2

Hentedato for alle funn: 2026-10-15. Alle kall gjort uten innlogging/nøkkel, fra read-only miljø.

## 1. Maskinlesbare kanaler — faktisk testet

| Kanal | URL | Nøkkel? | Testet kall | Status | Format |
|---|---|---|---|---|---|
| Cellar SPARQL | `http://publications.europa.eu/webapi/rdf/sparql` | Nei | `?query=SELECT...&format=json` | **200 OK**, gyldig JSON-SPARQL-resultat | RDF/JSON |
| Cellar REST (content negotiation) | `http://publications.europa.eu/resource/celex/32014L0024` | Nei | `Accept: application/xml;notice=branch` + `Accept-Language: eng` | **303 → 200**, 2,27 MB | Formex4 XML (NOTICE-metadata + lenker til fulltekst per språk) |
| Cellar REST, konsolidert tekst | `http://publications.europa.eu/resource/consolidation/2014L0024%2F20200101_...ENG.fmx4` | Nei | direkte GET | **200 OK**, 4 KB RDF-indeks (peker videre til DOC_2-ressurs) | Formex4 / RDF |
| EUR-Lex SOAP webservice (`EURLexWebService`) | `https://eur-lex.europa.eu/EURLexWebService?wsdl` | **Ja** | hentet WSDL | **200 OK** for WSDL selv, men WS-Policy inni krever `UsernameToken`/`WssUsernameToken11` for `doQuery`-operasjonen | SOAP/XML — krever gratis EU Login (ECAS), ikke testet med konto (read-only-regel) |
| EUR-Lex HTML-frontend | `https://eur-lex.europa.eu/legal-content/...` | Nei, men blokkert | ethvert GET, inkl. `/robots.txt` | **202 Accepted, 0 byte**, header `x-amzn-waf-action: challenge` (AWS WAF JS-challenge) | **Ikke fetchbar** med curl/plain HTTP — robots.txt selv kan ikke leses fordi WAF stopper før det |
| CJEU-dom via samme kanal | `http://publications.europa.eu/resource/celex/62015CJ0006` | Nei | `Accept-Language: eng` | **303 OK**, samme Cellar-redirect-mønster som direktiv | Formex4/RDF |
| CURIA (curia.europa.eu) | `/robots.txt` | Nei | GET robots.txt | **200 OK**, men disallow-liste sperrer en rekke navngitte `docid=`/`num=`-dokumenter spesifikt | HTML, delvis sperret per dokument |

**Konklusjon kanal:** EUR-Lex' egen HTML-side er WAF-blokkert for ikke-nettlesere (ingen omgåelse prøvd, jf. regel 2). Cellar/SPARQL og Cellar/REST (content negotiation på `publications.europa.eu`) er den reelle, åpne, nøkkelfrie maskinkanalen — både for direktiver og for EU-domstolens avgjørelser (samme CELEX→Cellar-mønster). SOAP-webservicen krever gratis EU Login; ikke testet videre (ville krevd registrering, mot regel 2).

**UNKNOWN:** bulk-ZIP/dump-nedlasting av hele EUR-Lex-korpuset (ikke funnet/testet i denne runden — kun enkeltdokument-henting).

## 2. Konsolidering og tidsdimensjon

**Delvis bekreftet.** NOTICE-metadata for 32014L0024 lister konsoliderte utgaver per språk med dato-kodet ressurs-ID, f.eks.:
`.../consolidation/2014L0024%2F20200101_0030010.ENG.fmx4` og `.../20220101_0040030.DEU.fmx4` — dvs. hele rettsakten publiseres på nytt per ikrafttredelsesdato for endringer, med eget identifikator per dato og språk. Det er nøyaktig det mønsteret vi mangler i FOA-korpuset (hele-dokument-versjon per dato).

**UNKNOWN / ikke verifisert innen budsjett:** om Formex-skjemaet også tagger gyldig-fra/gyldig-til **per artikkel** inne i dokumentet, eller bare per hel-dokument-utgave. Fikk ikke hentet selve fulltekst-DOC-ressursen (kun RDF-indeksen som peker til den) i tid.

## 3. Lisens/gjenbruk — ordrett

Fra `https://commission.europa.eu/legal-notice_en` (hentet 2026-10-15, status 200):

> "The Commission's reuse policy is implemented by the Commission Decision of 12 December 2011 on the reuse of Commission documents. [...] content owned by the EU on this website is licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0) licence. This means that reuse is allowed, provided appropriate credit is given and changes are indicated."

Unntak (samme side, ordrett): *"Software or documents covered by industrial property rights, such as patents, trade marks, registered designs, logos and names, are excluded from the Commission's reuse policy and are not licensed to you."*

CC BY 4.0 dekker lagring, analyse og AI-bruk uten videre betingelse enn kreditering — vesentlig mer permissivt enn Lovdatas regime for norsk tekst. **Dette er samme rettsgrunnlag (2011/833/EU) som TED allerede har dokumentert** (`data/sources/ted.json`, hentet 2026-08-30) — bekreftet konsistent på tvers av to EU-kilder.

## 4. Norsk språk

- **Ikke funnet maskinlesbart.** Formex-notice for 32014L0024 lister 23 EU-språkkoder (ENG, DAN, SWE, DEU, FRA... ) — **NOR finnes ikke**, fordi Norge ikke er EU-medlem og EUR-Lex kun dekker de offisielle EU-språkene.
- **EFTA/EEA-Lex** (`https://www.efta.int/eea-lex/32014L0024`) — forsøkt, **403 Forbidden** (bot-blokkert), ikke verifiserbart uten nettleser. EØS-tillegget til EØS-avtalen (der en norsk oversettelse normalt publiseres) kunne derfor ikke bekreftes maskinlesbart i denne runden.
- **Lovdata** (FOA-siden, `https://lovdata.no/dokument/SF/forskrift/2016-08-12-974`, hentet 2026-10-15, 200 OK): har **én** forekomst av `EØS-henvisninger:` i hele dokumentet — en hjemmelsnote i front-matter som lenker `/avtale/avt-1992-05-02-1-v16` (EØS-avtalen vedlegg XVI) og `/eu/32014l0024`. Dette er en **henvisning/lenke**, ikke en norsk oversettelse av direktivteksten.

## 5. EU-domstolens praksis

Samme Cellar/CELEX-kanal som direktivene (se tabell §1) — testet med C-6/15 (`62015CJ0006`), fikk 303-redirect inn i samme Cellar-ressursstruktur. **Dekning/format ikke dypere verifisert** (ville krevd å følge redirect-kjeden til fulltekst-Formex, tidsboksert bort). CURIA sitt eget `/juris/`-grensesnitt har en robots.txt som sperrer spesifikke dokument-ID-er, ikke et generelt forbud — men er ikke testet som primær maskinkanal siden Cellar/CELEX dekker samme innhold uten kjente blokkeringer.

## 6. Norsk ↔ EU paragrafkart

**Negativt bekreftet: finnes ikke per-paragraf.** Lovdatas FOA-side har kun **én** EØS-henvisning for *hele* forskriften (front-matter), ingen tilsvarende note er funnet per `§`. Ikke undersøkt: EØS-notatbasen (europaportalen.no) eller regjeringen.no sin Prop. 51 L (2015–2016) — et forsøk på direkte URL ga 404, ikke fulgt videre innen budsjett.

**Minste manuelle jobb (anbefaling, ikke verifisert fakta):** for de 17 reglene som peker på bestemte FOA-paragrafer, slå opp hver paragrafs opprinnelige forarbeid (Prop. 51 L (2015–2016), Nærings- og fiskeridepartementet) manuelt — norske forskriftsforarbeider til direktiv-gjennomføring oppgir som regel kildeartikkelen i merknadene til hver paragraf. Dette er ca. 17 oppslag, ikke et generelt kart — ingen maskinell kilde funnet som gjør det for oss.

## Slik ville vi koblet den

Cellar REST (content-negotiation) er samme shape som dagens Lovdata-kilde: GET + headers → XML. Ny host `publications.europa.eu` må inn i allowlisten (`crm/src/lib/http.ts:4`, i dag 9 verter). Formex4 er et annet skjema enn det `crm/src/lib/legal/parse.ts` og `tar.ts` håndterer i dag (Lovdata-XML) — krever egen parser-gren, ikke gjenbruk. ID-skjemaet `lov/<dato>-<nr>/§X/ledd-n` har ingen direkte CELEX-motpart (CELEX er `3`+år+type+nummer); forslag: eget felt `celex_ref` på regelen i stedet for å tvinge CELEX inn i FOA-ID-formatet.

---

**Tre viktigste funn:**
1. EUR-Lex' HTML-frontend er WAF-blokkert for maskinklienter (202/0-byte, `x-amzn-waf-action: challenge`, selv `/robots.txt`) — men Cellar (`publications.europa.eu`, SPARQL + REST content-negotiation) er en reell, nøkkelfri maskinkanal for samme innhold, verifisert med 200/303-svar for både direktiv og CJEU-dom.
2. Reuse-vilkårene (2011/833/EU, ordrett sitert fra commission.europa.eu) gir CC BY 4.0 — lagring/analyse/AI-bruk fritt mot kreditering. Vesentlig mer permissivt enn Lovdatas RED-status for norsk tekst, og samme grunnlag som TED allerede har dokumentert.
3. Det finnes **ikke** noe maskinlesbart FOA-paragraf↔direktiv-artikkel-kart: Lovdatas FOA-side har kun én EØS-henvisning for hele forskriften, ikke per §. Norsk oversettelse av selve direktivteksten kunne ikke bekreftes maskinlesbart (EEA-Lex ga 403; EØS-tillegget ikke undersøkt i denne runden).
