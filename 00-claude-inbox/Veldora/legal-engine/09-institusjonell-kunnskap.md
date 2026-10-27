# 09 — Institusjonell kunnskap: PRD, issues, kuraterte rettskildedokumenter, kilderegister

Kartlagt av admin-1 (ikke en agent), repo `/home/nithu/code/Veldora-frist` @ `fae0ddd`, les-only.
Dette er laget som ikke er kode: planer, beslutninger, kuratert juss og rettighetsregisteret.
**Konklusjon først: mye av «fase 2-researchen» i oppdraget er alt gjort i repoet, med dato og kilde.
Den skal gjenbrukes, ikke gjøres på nytt.**

## 1. Det finnes allerede en PRD for presis denne motoren

`prd/juridisk-assistent.md` (98 linjer, `Status: draft`, skrevet 2026-10-05, eier Nithu).
Den har 18 brukerhistorier, et modulkart, testbeslutninger og fem åpne spørsmål.

**Verifiserte kildefakta derfra (`prd/juridisk-assistent.md:64-66`), merket `FACT` med hentedato:**

| Forhold | Målt verdi |
|---|---|
| API | `https://api.lovdata.no/v1/publicData/list` — fire datasett, verifisert live 2026-10-05 |
| Nøkkel/konto | **Ingen** — gratis, åpent |
| Lisens | **NLOD 2.0** (api.lovdata.no/om-api-tjenesten) |
| Oppdatering | hver natt |
| `gjeldende-lover.tar.bz2` | 5,8 MB — inneholder `nl/nl-20160617-073.xml` (anskaffelsesloven, siste endring i kraft 2026-07-01) |
| `gjeldende-sentrale-forskrifter.tar.bz2` | 21 MB komprimert / **223 MB utpakket** — `sf/sf-20160812-0974.xml` (FOA) + `sf/sf-20160812-0975.xml` (forsyningsforskriften) |
| ID-skjema | `lov/2016-06-17-73/§4`, `forskrift/2016-08-12-974/§24-8/ledd-2`, `…/vedlegg-5`, senere `kofa/2023/123/avsnitt-4` |
| Versjon per paragraf | **`UNKNOWN`** — datasettet gir bare «ikrafttredelse av siste endring» for hele dokumentet, kopiert til hvert ledd |

**Operatørbeslutninger som alt er tatt (`prd/juridisk-assistent.md:73`, speilet i `ARCHITECTURE.md:1079`):**
privat bruk nå · **ingen kontakt med Lovdata eller KOFA** · **FOA Pro og Anbudsradar er bare
inspirasjon — skrapes aldri, innhold kopieres aldri** · det finnes en anskaffelsesjurist · ADMIN
bekrefter opplastede dokumenter · attester lagres ikke hos oss.

**De fem åpne spørsmålene (ubesvarte, operatør/jurist):** (1) hvilke lover utover
anskaffelsesregelverket, (2) KOFA fra kofa.no eller Lovdata, og om nedlasting regnes som «kontakt»,
(3) skal juristen forhåndsgodkjenne hvilke paragrafer agentene får vise til, (4) overskrive eller
beholde forrige versjon av et endret ledd, (5) skal korpuset skilles ut i eget AS ved
kommersialisering.

## 2. Backloggen for motoren finnes som issues — syv av dem

`issues/` har 14 åpne, `issues/done/` har 40 lukkede. De åpne som ER denne motoren:

| Issue | Type | Hva den dekker | Hva den venter på |
|---|---|---|---|
| `017-paragrafer-i-tilbudsarbeidet` | AFK | kontraktsflagg/forbehold skal hente FOA § 24-8 (del III) / § 9-6 (del II) fra korpuset i stedet for hardkodet tekst | juristens kuraterte paragrafliste (åpent spm. 3) |
| `018-kofa-avgjorelser` | HITL | KOFA inn i korpuset med `kind: kofa` og samme proveniens | **operatørens valg av kilde + rettighetsgrunnlag.** Inntaket er merket ferdig; kriteriet som gjenstår er beslutningen |
| `019-embeddings-hybridsok` | HITL | `EmbeddingProvider` mot OpenAI-kompatibelt endepunkt (f.eks. bge-m3), pgvector + RRF mot `ts_rank` | om Railway-Postgres tilbyr `vector` (`UNKNOWN`), operatøren slår på utvidelsen, og velger modell/vertskap |
| `020-versjonshistorikk-endringsvarsel` | AFK | historikkrad per ledd + `legal.cited.changed` med diff når et sitert ledd endres | ingenting teknisk — avhenger av svar på åpent spm. 4 |
| `021-flere-kilder` | AFK | `LEGAL_SOURCES` utvides via konfig (forvaltningsloven, offentleglova, sikkerhetsloven, personopplysningsloven) | åpent spm. 1 |
| `013-juristgjennomgang-katalog` | HITL | jurist går gjennom bevismaler, FOA-referanser og UI-tekster | juristtid |
| `011-ekte-kredittkilde` | HITL | erstatte `mock-credit` med Proff/D&B/Creditsafe | penger (Forvalt Premium 14 990 kr/år, Proff etter avtale) + ukjente vilkår |

**Dette betyr:** hybrid søk, versjonering, KOFA og flere kilder er ikke uoppdagede behov — de er
spesifiserte og **gatet på operatør/jurist, ikke på utviklingskapasitet.** Et designforslag som
«innfører» dem uten å svare på gatene flytter ingenting.

## 3. Kuratert juss som prosa — 6 867 linjer, 310 `FACT`-markører

| Fil | Linjer |
|---|---|
| `legal/procurement/qualification-requirements.md` | 1 958 |
| `procurement/qualification/financial-capacity.md` | 1 067 |
| `procurement/qualification/espd.md` | 803 |
| `procurement/qualification/supporting-entities.md` | 724 |
| `procurement/qualification/bid-gate.md` | 519 |
| `procurement/qualification/tender-readiness-checklist.md` | 423 |
| + 5 flere (`faste-vs-anbudsspesifikke-krav`, `references`, `kvalitetssystem`, `informasjonssikkerhet`, READMEs) | 580 |

Målt: `grep -ro "\`FACT\`" procurement legal | wc -l` = **310**. Disse dokumentene er
menneskekuratert, kildemerket juss — og de er **ikke** i korpuset. De lever som markdown ved siden
av `legal_chunks`. Det er to rettskildelag som ikke snakker sammen.

`financial-capacity.md:915` inneholder også den viktigste advarselen i repoet om denne motoren:
terskelverdiene revideres periodisk, «**de skal ikke kopieres inn i en mal**», og `:921` dokumenterer
et tilfelle der et automatisert hentelag leverte en **velformet og fullstendig oppdiktet** gjengivelse
av FOA §§ 16-1 til 16-10, inkludert en «§ 16-3» uten dekning.

## 4. Juristens domslag finnes — og er tomt

`data/legal/kommentar-regler.json`: **59 rader**, felt `id · ruleId* · ref · status ·
lowersSeverity · verifiedBy · verifiedAt · primarySource · note`.

Målt med python/json:
- **status: 59 av 59 = `ASSUMPTION`.** Null `FACT`, null `REJECTED`.
- **`verifiedBy`: null i alle 59.**
- **`lowersSeverity`: true i 0 av 59.**

Altså: mekanikken for at en jurist kan bekrefte en ekspertkommentar mot primærkilden er bygget, og
**ingen rad er bekreftet**. Samme bilde i `data/legal/terskelverdier.json`, som er `[]` med vilje
(venter jurist).

(*`ruleId` finnes ikke på alle rader — et `KeyError` på første uttrekk. Skjemaet er løsere enn
dokumentasjonen antyder; verdt en egen sjekk.)

## 5. Kilderegisteret er den rette formen for fase 2 — og det er utdatert

`data/sources/*.json`: **14 kilder** (amedia, arkivverket, brreg, datatilsynet, digdir, doffin,
lovdata, podcast-rss, polaris, regjeringen, robertmyhre, schibsted, stortinget, ted).

Skjemaet per kilde er presis det oppdraget ber om: `access_method · authentication · cost · latency ·
completeness · historical_access · technically_fetchable · storage_rights · analysis_rights ·
redistribution_rights · ai_processing_rights · gdpr_implications · licence_status · owner ·
next_action`.

Tilstand målt nå:
- **`redistribution_rights`: `RED` for `lovdata` og `robertmyhre`. `UNKNOWN` for de 12 andre** —
  inkludert `doffin`, `ted`, `regjeringen`, `stortinget`, `brreg`.
- `lovdata`-raden har `access_method: UNKNOWN` og «UNKNOWN whether any machine-readable interface
  exists» — **mens PRD-en to måneder senere verifiserte publicData-API-et live.** Registeret er altså
  bak PRD-en, og de to motsier hverandre i tone om ikke i substans.
- **Presisjonen som må inn:** `lovdata.no` (bruksvilkår: ingen distribusjon uten skriftlig tillatelse
  ⇒ `RED`) og `api.lovdata.no/v1/publicData` (**NLOD 2.0**) er to forskjellige rettsforhold om samme
  leverandør. En motor som blander dem, bygger på feil premiss.

## 6. ADR-ene som binder dette arbeidet

| ADR | Hva den binder |
|---|---|
| `ADR-0010` | **`DECISION` (operatør 2026-08-30): regelverksovervåking er internt verktøy, ikke noe selskapet selger.** Også: robots.txt følges av kommersielle grunner, og `redistribution_rights: RED` for Lovdata står på vilkårsteksten |
| `ADR-0011` | kvalifikasjonsporten er **rådgivende**, og tersklene der er en bevisst duplikat |
| `ADR-0018` | ingen enkeltkilde autoritativ for frist; terskeltabell = datert hurtigbuffer med FACT-krav; skillet regelberegnet mot kildelest; hver antakelse er én navngitt konstant |
| `ADR-0014` | §10 datarettigheter; `fitScore`/`winProbability` beregnes fra dag én |
| `ADR-0017` | møteflaten er hovedflaten; kalibrering gater når tall får styre utvalg |

**Den strategiske kollisjonen operatøren må løse, og den er ikke teknisk:** oppdraget sier
«funksjonalitet tilsvarende og på sikt bedre enn FOA Pro». FOA Pro er et kommersielt produkt.
`ADR-0010` sier at dette er internt verktøy og ikke noe vi selger, og `strategy/proposals/2026-10-05-anbud-plattformstrategi.md:213`
sier at FOA Pro bare er inspirasjon. Skal motoren bli et produkt, må `ADR-0010` erstattes og
rettighetsfeltene fylles — særlig `redistribution_rights`, som i dag er `RED` for Lovdata og
`UNKNOWN` for alle de andre. **Det er en operatørbeslutning, ikke en arkitekturbeslutning.**

## 7. Hull dette laget avdekker

1. **To rettskildelag uten kobling:** 6 867 linjer kuratert markdown-juss mot `legal_chunks` i
   Postgres. Ingen av dem refererer den andre maskinelt.
2. **Verifiseringslaget er tomt:** 59 av 59 kommentarregler er `ASSUMPTION`, terskeltabellen er `[]`.
   Motoren har en jurist-i-løkka som ingen jurist har brukt.
3. **Rettighetsmatrisen er 12/14 `UNKNOWN`** — og det er den som bestemmer hva som lovlig kan
   lagres, analyseres og videreformidles i et produkt.
4. **Versjon per paragraf er `UNKNOWN` fra kilden.** Datoavhengig regelverk («hva gjaldt § X den
   datoen tilbudet ble levert») kan ikke besvares av dagens datasett alene; issue 020 er svaret, og
   det er ubesvart.
5. **Presedensen for hallusinert lovtekst er dokumentert i eget repo** (`financial-capacity.md:921`).
   Enhver LLM-vei inn i rettskildelaget må måles mot den hendelsen, ikke mot en antakelse om risiko.
