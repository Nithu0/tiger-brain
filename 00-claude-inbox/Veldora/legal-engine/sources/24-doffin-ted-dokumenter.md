# 24 — Doffin og TED: kildekartlegging, med vekt på konkurransedokumentene

Live-verifisert 2026-10-15, les-only (ingen innlogging, ingen nøkkel brukt). Oppdrag: Doffin/TED +
seks dokumentportaler. Eksisterende registerrader `data/sources/doffin.json` og `data/sources/ted.json`
er **ikke** erstattet her — se "diff" nederst.

## 1. Doffin-API i dag

- `GET https://api.doffin.no/public/v2/search` → **FACT**: `HTTP 401 {"message":"Access denied due to
  missing subscription key..."}`. Azure APIM-mønster, bekrefter `auth_header: Ocp-Apim-Subscription-Key`
  i registeret stemmer fortsatt.
- Utviklerportal `https://dof-notices-prod-api.developer.azure-api.net/`: **FACT** (hentet 2026-10-15)
  krever «sign up» + «create a subscription». Pris, ratelimit og gjenbruksvilkår for «Public»-produktet
  **ikke synlig uten innlogging → UNKNOWN**, uforandret fra 2026-08-30-funnet.
- Nøkkelløs webclient-sti: **FACT, bekreftet live** — `POST https://api.doffin.no/webclient/api/v2/search-api/search`
  med body `{numHitsPerPage,page,searchString,sortBy,facets}` gir samme treff-form, `numHitsAccessible: 1000`
  (hardt tak, bekreftet). `GET .../notices-api/notices/{id}` gir full detalj inkl. `competitionDocsUrl`.
  **Ikke dokumentert noe sted** — dette er den samme APIen Doffins eget nettsted bruker (devtools-sti), ikke
  et publisert API. `api.doffin.no/robots.txt` → 404 (ingen robots-fil, altså ingen uttalt policy verken vei).
  Konklusjon: **utilsiktet/udokumentert, ikke en vilkårsgodkjent integrasjon.**

## 2. Leverer Doffin/TED selve dokumentet?

**Nei, bekreftet.** Hentet en reell, aktiv kunngjøring (`2026-116025`, Halden kommune) via webclienten:
`competitionDocsUrl` = `https://permalink.mercell.com/290679180.aspx` → redirect til
`www.mercell.com/.../tender.aspx`, siden viser "Login"/"Sign in" (4+3 treff). **Lenke til portal, ikke fil.**
TED eForms har samme mønster: **FACT** — BT-15/BT-615 "Documents URL" er en URL-type felt i eForms-skjemaet
(docs.ted.europa.eu/eforms/latest/reference/business-terms), ikke et dokumentfelt. Ingen av de to leverer
konkurransegrunnlaget maskinelt.

## 3. TED v3

- `POST https://api.ted.europa.eu/v3/notices/search` → **FACT, HTTP 200 uten nøkkel**, levert nå.
  Dokumentasjon (docs.ted.europa.eu/api/latest) sier ordrett: Search API «does not require a key» / «allows
  anonymous access to all services ... retrieving notices already published». Ratelimit **ikke funnet i
  hoveddokumentasjonen** — sekundærkilde (uverifisert av meg mot primærtekst) nevner 700 req/min, 600
  nedlastinger/6 min, 3 samtidige pakker; merk denne som **UNKNOWN (sekundærkilde)**.
- **Bulk uten innlogging finnes**: `https://ted.europa.eu/packages/notice/daily/{OJS-nr}` — testet live med
  gjettet nummer, fikk 404 (feil nummer, ikke feil mekanisme; endepunktet eksisterer under
  `/orchestrator/packaging/...`). Sekundærkilde beskriver daglige/månedlige XML-pakker + historisk FTP
  (ftp://ted.europa.eu, guest/guest). **Ikke selv verifisert med korrekt OJS-nummer → merk UNKNOWN til
  bekreftet med gyldig ID.**
- Lisens: `ted.europa.eu/en/help/data-reuse` nevner **ingen** eksplisitt lisenstekst i selve siden (kun
  hvordan, ikke vilkår). Den tidligere verifiserte teksten i `data/sources/ted.json` (SIMAP legal-notice,
  EU-beslutning 12.12.2011, CC BY 4.0 / CC0) er en **annen side** og står fortsatt uendret av meg.
- eForms felt for tildelingskriterier: **FACT** — BT-539 (type), BT-540 (beskrivelse), BT-541/BT-5421-5423
  (vekt/fast beløp/terskel, kodet), BT-734 (navn). Dette er reelle strukturerte felt som **kan** erstatte
  LLM-utrekk av tildelingskriterier — forutsatt at avsender har fylt dem (ofte tomt i praksis, ikke målt her).

## 4. Portalene — dokumenttilgang uten innlogging

| Portal | Status | Kilde |
|---|---|---|
| **Mercell** | Krever innlogging for dokument; permalink → tender.aspx viser Login/Sign in | FACT, live test |
| **TendSign** | **Eid av Mercell siden nov. 2020** (Visma divest, kildebekreftet) — samme konsern, ikke uavhengig vilkårsregime | FACT (pressemelding) |
| **EU-Supply** | **Også Mercell-merkevare** (`eu.eu-supply.com`, "EU-Supply Support Norway" på Mercells Confluence). Vilkår: "register ... to get access to all tender documents" | FACT (brukerhåndbok/wiki-treff) |
| **Ivalua** | Sykehusinnkjøp-portal; "public portal" nevnes i markedsføring, men supplier-login kreves for dokumenter i praksis | sekundærkilde, ikke egen-testet (ingen offentlig norsk instans funnet å teste mot) |
| **Artifik** | **Nei uten login** — live test: `app.artifik.no/procurements/4301` viser `Konkurransegrunnlag.pdf`-lenke i HTML, men siden har LOGIN/Logg inn-elementer; selve PDF-en ikke hentet (ville krevd å følge en lenke som sannsynligvis gater på auth — ikke testet videre for å unngå omgåelse) | FACT (delvis) + UNKNOWN (selve filen) |
| **hyyr** | **Åpent, nøkkelløst endepunkt funnet**: `GET https://www.hyyr.no/api/public/procurement/{id}/konkurransegrunnlag` → **HTTP 200, reell PDF (17 sider), ingen auth**. `/public/` i stien tyder på tilsiktet offentlig design, ikke lekkasje. Ingen robots.txt publisert (404) | **FACT, live test** |

**Merk:** 36,8+18,2+9,3 = **64,3 % av de 1184 lenkene (Mercell+TendSign+EU-Supply) er samme konsern.** Én
juridisk/kommersiell avtale med Mercell dekker i prinsippet to tredjedeler av dokumentvolumet.

## 5. eForms i Norge

eForms er obligatorisk i EU/TED siden 25.10.2023 (Implementing Regulation (EU) 2019/1780). Norsk variant:
`github.com/anskaffelser/eforms-sdk-nor` — norsk oversettelse/validering + skjema under nasjonal terskel.
SDK-versjon i TED-dokumentasjonen nå: **1.15.x** (sett i søk, ikke selv lest changelog linje for linje →
merk versjonstall som sekundærkilde). Strukturerte felt for tildelingskriterier finnes (se §3) — relevant
for å redusere LLM-avhengighet, **men avhenger av at avsender fyller dem**, ikke verifisert i praksis her.

## 6. Konklusjon — rangering, lovlig dokumenttilgang

1. **hyyr** — åpent `/api/public/...`-endepunkt, ingen auth, PDF levert direkte. Mest realistisk i dag.
2. **TED bulk-pakker** — ingen login, HTTP-nedlasting (sekundærkilde; egen verifisering med gyldig
   OJS-nummer gjenstår), men gir kun **TED-metadata/eForms-XML**, ikke selve konkurransegrunnlaget (se §2).
3. **Artifik** — dokumentlenke synlig uten login, selve filen sannsynligvis gatet; ikke avklart.
4. **Mercell / TendSign / EU-Supply** (ett konsern, 64 % av volumet) — vilkår krever registrering for
   dokumenttilgang; ingen åpen API funnet. Én forhandling her dekker mest volum, men er ikke "gratis lovlig".
5. **Ivalua** — ingen uavhengig, ikke-innlogget tilgang funnet; for tynt datagrunnlag til å si mer enn UNKNOWN.

## Diff mot eksisterende register
`data/sources/doffin.json` og `ted.json` sine `next_action`-felt er fortsatt korrekte og ikke motsagt.
Nytt siden 2026-08-30: webclient-taket (1000) er nå tallbekreftet; TED-nøkkelfrihet re-bekreftet med live
200; hyyr-funnet er helt nytt og bør inn som egen rad eller `next_action`-tillegg på `doffin.json`
(`documentsUrl`-oppløsning per portal). Ingen JSON-filer er endret av meg (regel 4).
