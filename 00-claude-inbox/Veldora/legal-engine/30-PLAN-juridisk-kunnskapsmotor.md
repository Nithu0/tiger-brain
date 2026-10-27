# PLAN — juridisk kunnskapsmotor for Veldora (internt verktøy, fase 1)

admin-1, 2026-10-15. Premiss: **operatørens beslutning «internt verktøy til å starte med»**, så
`ADR-0010` står og FOA Pro-paritet er en senere fase. Grunnlag: kartleggingen `01`–`10` (hva vi har)
og kildeundersøkelsen `sources/21`–`26` (hva verden tilbyr), alt live-verifisert 2026-10-15 med
kommandoer og hentedatoer i delrapportene.

Rettighetsterskelen for fase 1 er dermed: **lagring + analyse + modellbruk for intern bruk.**
Videreformidlingsrett registreres, men blokkerer ingenting nå.

---

## 1. Kildematrisen — hva som faktisk er tilgjengelig

| Kilde | Teknisk tilgang | Rettigheter (intern bruk) | Juristnytte | Dom |
|---|---|---|---|---|
| **Lovdata publicData** (`api.lovdata.no/v1/publicData`) | **GRØNN** — 200, ingen nøkkel, nattlig. Fire datasett: `gjeldende-lover` (5,8 MB), `gjeldende-sentrale-forskrifter` (21 MB), **`lovtidend-avd1-2026` (1,5 MB) og `lovtidend-avd1-2001-2025` (69 MB)** | **GRØNN** — NLOD 2.0, og metabeskrivelsen inviterer eksplisitt: «Benytt datagrunnlaget fritt for eksperimentering og forskning med KI» | Bærebjelken | **I DRIFT — utvid** |
| **EU/EØS via Cellar** (`publications.europa.eu`, SPARQL + REST) | **GRØNN** — 200/303 uten nøkkel, både direktiv 2014/24/EU og CJEU-dom (C-6/15). NB: EUR-Lex' egen HTML-frontend er WAF-blokkert (202, 0 byte) — Cellar er veien | **GRØNN** — CC BY 4.0 (beslutning 2011/833/EU, sitert ordrett). Lagring, analyse og KI-bruk mot kreditering | Høy ved tolkningstvil | **TA INN (fase 1)** |
| **KOFA** (KNSE `wp-json/wp/v2/sak`) | **GRØNN** — 200, ingen nøkkel, **5 022 saker**, nyeste samme døgn, robots tillater. Utfall må leses fra sakssiden (REST-`acf` er tomt) | **GUL** — ingen lisenserklæring finnes. Vår § 14-begrunnelse er en antakelse. Ingen anonymisering: fulle navn på leverandør og oppdragsgiver | Nest høyest — praksis er det juristen slår opp | **KODEN ER FERDIG — venter B3** |
| **DFØ-veiledning** (anskaffelser.no) | **GUL** — ingen API; HTML + sitemap (888 URL-er med `lastmod`) + RSS. Robots tillater | **GUL** — ingen lisenserklæring funnet ⇒ behandles som vernet, ikke åpent | Middels — og **kildens egen klassifisering er gull**: «av rådgivende karakter», «domstolene som har det avgjørende ordet» | **FASE 2, merkes som veiledning** |
| **Doffin-kunngjøringer (CSV via FDK)** | **GRØNN** — åpent datasett | **GRØNN — CC BY 4.0 (verifisert)** | Lav for juss, nyttig for marked | Lav prioritet |
| **Doffin API v2** | **GUL** — 401 uten nøkkel; utviklerportal krever registrering, pris/ratelimit ikke synlig | UKJENT | — | Status quo (vi bruker webclienten) |
| **Doffin webclient** (i drift hos oss) | **GUL** — virker, 1 000-treffstak, **udokumentert devtools-sti**, ingen robots-fil | UKJENT — ingen uttalt policy noen vei | — | **Risiko å dokumentere, ikke å utvide** |
| **TED v3 search** | **GRØNN** — 200 uten nøkkel; dokumentasjonen sier «does not require a key». eForms har strukturerte felt for tildelingskriterier (BT-539/540/541/5421-5423) | **GRØNN** — samme 2011/833-grunnlag | Middels (kryssjekk + kriterier) | **I DRIFT — utnytt eForms-feltene** |
| **Rettspraksis (norsk)** | **RØD** — ingen gratis maskinlesbar kanal. Lovdatas robots sperrer avgjørelsessidene; de fire åpne datasettene har verken dommer eller forarbeider | RØD/UKJENT. Lovdata Pro koster **6 500 kr/år (1 bruker) til 179 900 kr/år (101-120)**; vilkår for API-uttrekk til en LLM **UKJENT**. Rettsdata: pris «etter avtale» | Høyest i teorien | **UTSETT — krever avtale, ikke kode** |
| **Forarbeider** (Stortinget/regjeringen) | **GUL** — delvis maskinlesbart (`data.stortinget.no`); NOU-dekning ikke bekreftet | Antatt NLOD-aktig, ikke verifisert | Lavest av de tre | Fase 2-3 |
| **Dokumentportalene** | Se §3 | Se §3 | Avgjørende for analyse | **Eget spor** |

---

## 2. Tidsdimensjonen: EU viser mønsteret, Lovtidend gir råstoffet

Dette er funnet jeg ikke forventet, og det endrer planen for L4 (ingen versjonshistorikk).

- **EU gjør det riktig:** Cellar publiserer hele rettsakten på nytt **per ikrafttredelsesdato**, med
  egen ressurs-ID per dato og språk (`.../consolidation/2014L0024/20200101_0030010.ENG.fmx4`,
  `.../20220101_...DEU.fmx4`). Altså hel-dokument-versjon per dato — presis det vi mangler. Om
  Formex også tagger gyldig-fra per artikkel er `UKJENT`.
- **Lovdata gir ikke konsoliderte historiske snapshots,** men **Lovtidend avd. I-arkivene (2001–2025
  + løpende 2026) er kunngjøringsarkivet**: én fil per endringsakt, med `Kunngjort`, `I kraft fra` og
  en `Endrer`-liste. Det er teoretisk råstoff for å rekonstruere «hva sa § 24-8 på dato Y», men
  **datasettet gjør ikke rekonstruksjonen for oss** — det krever en egen diff-/applikasjonsmotor.
  `/v1/documentHistory` ga 404 uten konto og er del av det betalte tilbudet.

**Anbefaling:** bygg issue 020 (historikkrad per ledd ved endring) **nå**, framover i tid. Det koster
lite, og det løser spørsmålet for alle tilbud vi leverer fra i dag. Historisk rekonstruksjon bakover
via Lovtidend er et eget, større prosjekt — ikke fase 1.

---

## 3. Dokumenttilgang: fire rettsforhold, ikke seks portaler

Målt fordeling av 1 184 `documentsUrl`-lenker: Mercell 36,8 % · TendSign 18,2 % · hyyr 12,6 % ·
Artifik 11,6 % · Ivalua 10,7 % · EU-Supply 9,3 %.

**Det strukturelle funnet:** Mercell eide TendSign siden 2020, og EU-Supply driftes som
Mercell-merkevare. **De tre er samme konsern og utgjør 64,3 % av volumet.** «Seks portaler» er i
praksis fire rettsforhold, og **én kommersiell avtale med Mercell dekker to tredjedeler** — det er en
forhandling, ikke et integrasjonsprosjekt.

**hyyr (12,6 %) er teknisk åpen, og rettslig ubeskrevet.** `GET https://www.hyyr.no/api/public/procurement/{id}/konkurransegrunnlag`
gir 200 med en reell PDF, uten autentisering, og `/public/` i stien tyder på tilsiktet design. **Men
jeg sjekket selv:** det finnes ingen `robots.txt` (404), ingen vilkårs- eller personvernside på de
vanlige stiene (`/vilkar`, `/brukervilkar`, `/terms`, `/personvern`, `/om` — alle 404), og sidene er
`noindex`. Fravær av robots er ikke tillatelse.

**Min anbefaling, og den er bevisst konservativ:** hent per sak vi faktisk jobber med — samme
handling et menneske gjør ved å klikke — og **ikke bulk-høsting**, før noen har svart. Ett e-postspørsmål
til hyyr er den billigste veien til et ekte svar, og det er operatørens å sende. Begrunnelsen er
kommersiell så vel som juridisk: vi selger forsiktig informasjonshåndtering til offentlige organer.

**Verdt mer enn alle portalene til sammen:** eForms-feltene BT-539/540/541 gir **strukturerte
tildelingskriterier med vekt** fra TED. Der de er fylt, erstatter de LLM-utrekk med data — og de
dekker nøyaktig de reglene våre (`tildeling-uten-vekt`, `tildeling-vekt-sum`) som i dag må nedgradere
til `usikkert` fordi dokumentet ikke er lest. Hvor ofte de faktisk er fylt, er **ikke målt** — det er
første måling jeg vil gjøre.

---

## 4. Rekkefølgen

### Bølge 0 — ingen gater, dager, ren gevinst

| # | Tiltak | Hvorfor nå | Kobles til |
|---|---|---|---|
| 0.1 | **Koble `eval/legal-gold.json` (45 spørsmål med forventet hjemmel) til CI som blokkerende port** | I dag går et formelt korrekt svar med **feil hjemmel** rett gjennom. Alt annet arbeid blir målbart av dette | `.github/workflows/anbud.yml`, `scripts/eval-legal.ts` |
| 0.2 | **Slå på Jev-reranking i `legal/retrieve.ts`** | Målt: FTS MRR 0,63 → **0,75–0,79**, 860 kall, 0 feil (`eval-typesafe`, 06.10). Ingen embeddings, ingen pgvector, ingen gate | `lib/legal/retrieve.ts`, `citationJudge`-mønsteret |
| 0.3 | **Kjør `probeVector()` mot prod** og lukk `UNKNOWN`-en som har holdt issue 019 i limbo siden 5. oktober | Ett kall. Svaret avgjør om hybridsøk er en reell opsjon | `/juridisk/kilder` viser den alt |
| 0.4 | **Mål eForms-dekningen** for BT-539/540/541 i de kunngjøringene vi har | Avgjør om strukturerte tildelingskriterier kan erstatte LLM-utrekk. Ren spørring, ingen ny integrasjon | `lib/sources/ted.ts` |
| 0.5 | **Verifiser at offentleglova og klagenemndforskriften faktisk har tekst i korpuset** | Filnavnene er nå bekreftet korrekte, så hvis teksten mangler ligger feilen i sync/parse — og da mangler hjemmelen for innsyn og KOFA-frister | `legal/sync.ts`, `legal.corpus.guard` |

### Bølge 1 — én beslutning hver, uker

| # | Tiltak | Gate | Verdi |
|---|---|---|---|
| 1.1 | **KOFA inn i korpuset** (koden er ferdig og cron-satt) | **B3**: operatørens valg av rettighetsgrunnlag + juristens § 14-vurdering + behandlingsgrunnlag for personopplysninger i ARCHITECTURE §10 | 5 022 avgjørelser; feilsjekken kobler alt KOFA-kandidater per funn |
| 1.2 | **Juristens domslag: 59 kommentarrader + terskeltabellen** | **B4**: juristtid, én økt | Den enkelthandlingen som løfter mest severity fra `usikkert` til `klar-feil` |
| 1.3 | **Jurist-rolle i tilgangsmodellen** (i dag bare `admin`/`member`/`viewer`; `/jurist` er en redirect-stub) | ingen | Uten den kan ikke en dom attribueres til en jurist — og det er hele premisset for 1.2 |
| 1.4 | **Korpusoppslag inn i `contract-review`** etter mønsteret fra `feilsjekk/explain.ts` | ingen | Fjerner den eneste veien der en modells juridiske vurdering ikke møter korpuset |
| 1.5 | **Historikkrad per ledd (issue 020), framover i tid** | ingen | Gjør «hva sa § X da vi leverte» besvarbart for alle tilbud fra i dag |
| 1.6 | **Direktivtekst fra Cellar for de 17 reglenes paragrafer** | ingen (CC BY 4.0) | Tolkningsgrunnlag ved tvil. **Omfanget er lite: 27 distinkte paragraf-ledd**, ikke tusenvis |

### Bølge 2 — større, og delvis avhengig av penger

- **Dokumentpipen (L2).** Per-sak-henting for hyyr (etter rettighetsavklaring), manuell opplasting
  for Mercell-konsernet inntil en avtale finnes, og eForms-felt der de er fylt. **Dette er den
  ledningen som løfter hele regelmotoren**, fordi `!docsRead` i dag systematisk nedgraderer funn.
- **Mercell-avtale** — kommersielt spor, dekker 64,3 % av dokumentvolumet. Operatørens bord.
- **Veiledningslaget fra DFØ** som egen `kind` med egen ID-form og datostempel per utdrag, merket
  «rådgivende» med kildens eget sitat.
- **Hybridsøk (issue 019)** hvis `probeVector` sier ja.

### Bølge 3 — venter på at B1 snus

Alt som forutsetter videreformidling: kundevendt visning, salg av rettskildetilgang,
FOA Pro-paritet. Krever at `ADR-0010` erstattes og at `redistribution_rights` fylles for hver kilde
(i dag `RED` for Lovdata, `UNKNOWN` for 12 av 14).

---

## 5. Arkitekturanbefalinger (konkret, og de respekterer det som finnes)

1. **Rettskildeklasse som eksplisitt enum, ikke en antagelse:** `bindende` (lov/forskrift) ·
   `praksis` (KOFA, dommer) · `veiledning` (DFØ) · `eu-kilde` (direktiv, CJEU) · `sekundær`
   (ekspertkommentar). DFØs eget sitat gir oss klassifiseringen gratis. Dette er den ene
   datamodellendringen jeg mener er nødvendig før flere kilder tas inn.
2. **Ikke tving nye kilder inn i Lovdata-ID-skjemaet.** `lov/<dato>-<nr>/§X/ledd-n` passer ikke CELEX
   eller en veilederside. Legg `celex_ref` som eget felt på regelen, og gi veiledning sin egen `kind`
   + ID-form. Ellers forurenses korpuset.
3. **Én parser per format, delt synkplan.** `parse.ts` tar Lovdata-XML. Formex4 (EU) og HTML (DFØ) er
   egne grener. **Vakten i `sync.ts` (stopper ved tom eller halvert parse) og diffen på
   `chunkId`+`contentHash` gjenbrukes for alle** — den er kildeagnostisk og er motorens beste
   sikring.
4. **Allowlisten er riktig kontrollpunkt.** `crm/src/lib/http.ts` har 9 verter. Hver ny kilde er én
   bevisst linje der, og det er der rettighetsgaten hører hjemme: en kilde med
   `licence_status: UNKNOWN` skal logges som uavklart, ikke passere stille.
5. **Korpus→sak-koblingen bygges som gjenfinning, ikke som flere hardkodede lister.** De 17 reglene
   beholder sine `lawChunkIds` (de er presise og testet). Det nye laget er: hent relevante chunks for
   *sakens egen tekst* og vis dem som kontekst — aldri som et funn uten regel bak. Det respekterer at
   LLM-en i dag bare kan **senke** severity, aldri heve.
6. **Fristen beholder flere kilder** (`ADR-0018`): ingen enkeltkilde gjøres autoritativ, og
   modellkandidaten blir stående som uavhengig kryssjekk.

## 6. Kostnadsbildet

| Post | Beløp |
|---|---|
| Lovdata publicData, TED, Cellar/EUR-Lex, KOFA, DFØ-HTML, Doffin-CSV | **0 kr** |
| Lovdata Pro (hvis rettspraksis skal inn) | **6 500 kr/år** (1 bruker) → 12 500 (1-3) → 19 900 (4-6) → 25 900 (7-10) … 179 900 (101-120), eks. mva. **Og vilkårene for maskinelt uttrekk til en LLM er `UKJENT`** — pengene alene løser det ikke |
| Rettsdata / Juridika | «etter avtale», ikke publisert |
| Mercell-avtale (64 % av dokumentvolumet) | ikke undersøkt — kommersielt spor |
| LLM-drift | målt 17,58 → 4,16 USD/uke etter Haiku-rutingen 13.10. **Ingen dollargrense finnes i kode** — en motor som legger gjenfinning + reranking på hver analyse multipliserer kallene |

**Anbefaling:** legg inn et kostnadstak før bølge 1, ikke etter. Firmaet har hatt to tomme kontoer på
én dag, begge oppdaget ved flaks.

## 7. Dette skal vi ikke gjøre

- **Ikke bygg retrieval på nytt.** `lib/legal/` er en fullverdig motor med RRF-fusjon og
  sitatvalidator. Den skal utvides, ikke erstattes.
- **Ikke skrap FOA Pro eller Anbudsradar.** Stående operatørbeslutning, og den står selv om vi en dag
  konkurrerer med dem.
- **Ikke bulk-høst hyyr** før rettighetene er avklart, selv om endepunktet svarer.
- **Ikke utvid bruken av Doffins udokumenterte webclient-sti.** Den virker, men den er en devtools-sti
  uten uttalt policy. Dokumenter avhengigheten som en risiko; ikke bygg mer på den.
- **Ikke fyll terskeltabellen fra en skrapet HTML-tabell.** DFØ har ingen stabil maskinlesbar adresse,
  og repoet har en dokumentert hendelse med oppdiktet FOA-tekst. Juristen fyller den, med `FACT`, dato
  og primærkilde.

## 8. Beslutninger jeg trenger fra operatøren

1. **B3 — KOFA:** hent fra KNSE på vår egen § 14-vurdering, eller la KOFA ligge? Koden er ferdig, og
   det finnes ikke et tredje rent alternativ. Juristen bør bekrefte § 14 og behandlingsgrunnlaget for
   navngitte parter.
2. **B4 — juristtid:** én økt på 59 kommentarrader + terskeltabellen. Størst severity-løft per time.
3. **hyyr:** skal jeg foreslå en e-post som spør om maskinell bruk av `/api/public/...`? Du sender.
4. **Mercell:** skal jeg utrede en avtale (64 % av dokumentvolumet), eller holder vi oss til manuell
   opplasting i fase 1?
5. **Kostnadstak for modellkall** — tall og hva som skjer når det nås (stopp, eller varsle og fortsette).
