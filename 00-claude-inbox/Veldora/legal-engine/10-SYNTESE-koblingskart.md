# SYNTESE — hvordan Veldora faktisk er koblet sammen, og hvor en juridisk kunnskapsmotor mangler ledninger

admin-1, 2026-10-15. Grunnlag: åtte parallelle kartleggingsagenter (filene `01`–`08`) + eget
dokumentlag (`09`), alt mot `origin/main` = `fae0ddd`, les-only. Hver påstand under står med fil:linje
i delrapportene. **Dette er kartleggingen operatøren ba om først. Ingen design, ingen implementasjon.**

## 0. Konklusjonen i fem setninger

Den juridiske motoren er **ikke et tomt felt — den er omtrent tre fjerdedeler bygget**: et
rettskildekorpus fra Lovdata med stabile ledd-ID-er (nattlig cron), en KOFA-skraper, en
retrieval-motor med RRF-fusjon, en sitatvalidator som krever ordrett dekning, 17 deterministiske
regler med hjemmel, og 129 API-ruter der 30 er juridiske. Det som mangler er **ikke flere regler**,
men **fire ledninger og fem beslutninger**. Den dyreste ledningen er at korpuset ikke har noen
relasjon til en konkret anbudssak: koblingen skjer i dag gjennom 17 hardkodede regel→paragraf-lister,
ikke gjennom gjenfinning over sakens egen tekst. Den nest dyreste er at konkurransedokumentene — der
reglene faktisk brytes — aldri lastes ned. Og det som gjør hele bildet skjevt: verifiseringslaget er
bygget og tomt (59 av 59 kommentarregler er `ASSUMPTION`, terskeltabellen er `[]`), så motoren kan i
praksis ikke si `klar-feil` i de sakene det betyr mest.

## 1. Koblingskartet

```
EKSTERNE KILDER                    RAILWAY (prosjekt «anbud», EU)                 VERCEL
                                   ┌────────────────────────────────────────┐   ┌──────────────┐
api.doffin.no/public/v2/search ──┐ │ crm (Payload 3.90.2 + Next)            │   │ dashboard    │
  (DOFFIN_API_KEY, ALDRI TESTET) │ │   58 samlinger · 11 globaler           │◄──┤ Next 15      │
doffin webclient (nøkkelløs,     ├─┤   129 API-ruter (30 juridiske)         │   │ 25 navlenker │
  maks 1000 treff)               │ │   /admin, /api/*                       │   │ ~45 ruter    │
api.ted.europa.eu/v3 (nøkkelløs) ─┤ │                                        │   │ 7 faner på   │
data.brreg.no (enhet+regnskap) ──┤ │ worker (samme image, croner Oslo)      │   │  oppdraget   │
api.lovdata.no/v1/publicData ────┤ │   45 jobber · 13 kaller modell         │   └──────┬───────┘
  (NLOD 2.0, INGEN nøkkel)       │ │   ingest-doffin  */30 6-22             │          │
klagenemndssekretariatet.no ─────┘ │   ingest-ted     hver time             │  rewrite /cms/*
  (WP REST + PDF, robots-sjekket)  │   ingest-lovdata 04:30                 │  → CRM_URL/api/*
                                   │   ingest-kofa    05:00                 │  cookie payload-token
alle kall gjennom http.ts          │   brief-coverage */20 6-22             │  (401→/login, 403→/me)
ALLOWLIST (9 verter)               │ Postgres (ARCHITECTURE sier 16,        │
                                   │   CI kjører postgres:18-alpine)        │
                                   └────────────────────────────────────────┘

DEN JURIDISKE KJEDEN INNE I CRM-ET

  legal_documents ──1:n── legal_chunks ──(generert kolonne)── search_vector (tsvector 'norwegian', GIN)
        │                      │                                      │
        │                      │                                      ▼
        │                      │                            retrieve.ts: kanaler
        │                      │                            paragraph · fulltext-and · -or
        │                      │                            · -synonym · vector(DØD) → RRF
        │                      │                                      │
        │                      │                           ask.ts ──► answer.ts (ordrett sitat
        │                      │                                      per setning, ellers «usikkert»)
        │                      │                                      │
        │                      └── store.ts:loadLaw() ◄── feilsjekk/rules.ts (17 regler, hver
        │                             LawLookup gir TALLET            med hardkodede lawChunkIds)
        │                             fra lovteksten (minstefrist,     │
        │                             30 % miljøvekt)                  ▼
        │                                                     finalize.ts: sitatkontroll,
        └── kofa/: robots → WP REST → PDF → avsnitt-n          hjemmel-oppslag, KOFA-kandidater
                   citations → lov/forskrift                   (maks 3), nedgradering
                                                                       │
                                                      endpoints/feilsjekk.ts ──► Jev-sitatdom
                                                      (LLM kan BARE senke severity)

  ✗ INGEN fremmednøkkel: legal_documents/legal_chunks → opportunities/tenders/requirements
  ✗ contract-review og klage/evaluation kaller ALDRI legal/retrieve
  ✗ tender-brief bruker verify.ts, ikke korpuset
```

## 2. Hva som er bygget og i drift (ikke bygg dette på nytt)

| Lag | Tilstand | Bevis |
|---|---|---|
| Rettskildekorpus fra Lovdata | **I DRIFT** (cron 04:30), 5 kilder i `config/legal.ts`: LOA, FOA, forsyningsforskriften, offentleglova, klagenemndforskriften. NLOD 2.0, ingen nøkkel | `01` §3, `jobs/registry.ts:153` |
| Stabile ID-er per ledd | `forskrift/2016-08-12-974/§24-8/ledd-2`, `kofa/<år>/<nr>/avsnitt-n` | `01`, `prd/juridisk-assistent.md:67` |
| Vakt mot ødelagt inntak | 0 ledd eller < halvparten av lagret ⇒ skriver ingenting | `sync.ts`, `01` |
| KOFA-skraper | **KODE komplett + cron 05:00**: robots.txt-sjekk, 3 s mellom kall, WP REST, PDF→tekst, sitatoppløsning mot lov | `01` §3, `lib/legal/kofa/**` |
| Søk | Postgres full-text (`norwegian`), `ts_rank`/`ts_headline`, paragrafoppslag, OR/synonym-kanal, RRF-fusjon | `01` §4, `search.ts`, `retrieve.ts` |
| Sitatvalidator | Hver setning må sitere ordrett fra én hentet chunk, ellers `usikkert` | `answer.ts:3-6` |
| 17 deterministiske regler | frist · tildeling · kvalifikasjon · spesifikasjon · kontrakt · miljø · rammeavtale. Alle med `lawChunkIds`, unntatt `kontrakt-ubalanse` (bevisst kommersiell) | `02` §2 |
| Tall leses fra loven | minstefrist-dager og 30 %-miljøvekt hentes live fra korpusteksten via `LawLookup` — aldri hardkodet | `02` §3 |
| LLM-grensen | `computeFindings()` 100 % ren; modellsteget ligger i endepunktet og kan **bare senke** severity | `02` §5, `explain.ts:40-42` |
| Juridisk hard clamp | `legalConclusion`-oppgaver kan aldri rutes under Sonnet | `router.ts:40-45` |
| Hjemmel mangler ⇒ synlig | `lawMissing`, `MISSING_BASIS = '[Hjemmel mangler i rettskildekorpuset — juristen fyller inn]'`, og `klar-feil` nedgraderes når alle chunks er `found:false` | `03` §2, `finalize.ts:159-162` |
| ~35 juridiske domenefunksjoner | karens, forføyning, KOFA-frist, sanksjon, innsyn (+docx), salamieffekt § 28-1, avvisningsstyrke, underleverandør/konsern, ord-/sidegrenser, prisskjema-sum, miljøbesvarelse, avklaringssvar, endringsklausuler, de-minimis | `03` tabell |
| Proveniens og idempotens | `(source, externalId)`-upsert, sha256 contentHash, `provenance` per rad, én `agent-runs`-rad per kjøring | `05` §6 |
| Verts-allowlist | Kun 9 verter tillatt i `http.ts`; ukjent vert kaster | `05` §1 |
| Flater | `/juridisk`, `/juridisk/kilder`, `/juridisk/assistent`, `/juridisk/feilsjekk/[id]`, `/juridisk/kommentarer`, `/bevis` + fanene Tilbud og «Klage og innsyn» | `07` §1, §3 |
| Testmasse | CRM 255 testfiler / 2 500 tester · dashboard 47 / 615 · 28 av 30 røyktester blokkerende i CI mot PG18 | `08` §1-2 |

## 3. De fire manglende ledningene (rangert etter hva de koster oss)

### L1 — Korpuset har ingen relasjon til en sak
`legal_documents`/`legal_chunks` har **null fremmednøkkel** mot `opportunities`/`tenders`/`requirements`
(`04` §6). Hvilke bestemmelser som gjelder *denne* konkurransen avgjøres i dag av **17 hardkodede
regel→paragraf-lister** i `rules.ts` pluss tekstmatching i `klage/law.ts:97`. Det betyr:
- en konkurranse som bryter en regel vi ikke har kodet, er usynlig;
- `contract-review.ts:84` (kontraktsflagg) kjører **uten et eneste korpusoppslag** (`06` §7): den
  slår aldri opp lovtekst før modellkallet, slik `feilsjekk/explain.ts` gjør. Den har en
  sitatkontroll (`judge.citation`, `contract-review.ts:92`) som lagres på flagget og aldri forkaster
  et funn — altså kontrolleres sitatet, men ikke hjemmelen. Det er den ene veien der en modells
  juridiske vurdering ikke møter korpuset;
- `klage/evaluation.ts` kobler ikke mot `legal/` i det hele tatt.
Sømmene finnes og er navngitt: `feilsjekk/explain.ts` mater alt `law: {label, excerpt}[]` inn i
prompten før kallet. Samme mønster kan kobles på kontraktsgjennomgang og klage uten ny infrastruktur.

### L2 — Konkurransedokumentene kommer aldri inn
`documentsUrl` lagres som ren tekst (`Tenders.ts:105`), og **ingen kode laster ned filen**
(`05` §2). `documents` fylles bare av manuell opplasting; målt tilstand i prod er 0 rader og 0 av
1184 URL-er som peker på en fil. Konsekvensen er systematisk og måles i regelmotoren: `!docsRead`
nedgraderer funn flere steder (`rules.ts:260`, `:489`), og `part: 'ukjent'` nedgraderer fem
`klar-feil`-regler til `usikkert` (`02` §4). **Motoren er ikke begrenset av regler, men av input.**
Lenkene fordeler seg på seks portaler (Mercell 36,8 % · TendSign 18,2 % · hyyr 12,6 % · Artifik
11,6 % · Ivalua 10,7 % · EU-Supply 9,3 %, `eval/DOKUMENTKILDER.md`) — **null adapterkode finnes for
noen av dem**, og vilkårsavklaring per portal er en åpen gate.

### L3 — Gjenfinningen er fulltekst alene, mens en målt forbedring ligger ubrukt
`embeddingProvider()` returnerer alltid `null` og ingen migrasjon har en `embedding`-kolonne, så
vector-kanalen i `retrieve.ts` er død kode (verifisert selv, `embeddings.ts:17-19`). Samtidig har vi
alt målt alternativet: `eval-typesafe/results/summary.json` (2026-10-06) gir **baseline FTS MRR 0,63
mot 0,75–0,79 med Jev-reranking**, 860 kall, 0 feil. Altså: **+0,12–0,16 MRR er tilgjengelig uten
embeddings, uten pgvector og uten operatørgate.** Hybridplanen (issue 019) er fortsatt gatet på om
Railway-Postgres tilbyr `vector` — og det spørsmålet kan `probeVector()` besvare i dag via
`/juridisk/kilder`.

### L4 — Ingen tidsdimensjon
Korpuset har bare «gjaldt fra»-felt, ingen til-dato, og `sync.ts` **overskriver** endrede ledd uten
historikk (`01` §5). Spørsmålet «hva sa § X den dagen vi leverte tilbudet» kan ikke besvares. For et
internt verktøy er det en ulempe; for et produkt som skal konkurrere med FOA Pro er det en
revisjonssvikt. Issue 020 spesifiserer fiksen og er ubygget.

## 4. De fem beslutningene som faktisk blokkerer (ingen av dem er kode)

| # | Beslutning | Hvorfor den blokkerer | Hvem |
|---|---|---|---|
| B1 | ~~**Internt verktøy eller produkt?**~~ **BESVART 2026-10-15 av operatøren: «internt verktøy til å starte med».** `ADR-0010` står, FOA Pro-ambisjonen er en senere fase. Konsekvens for fase 2: vi trenger `storage_rights`, `analysis_rights` og `ai_processing_rights` for intern bruk — `redistribution_rights` registreres, men blokkerer ikke. Det opprinnelige spørsmålet står under for sporbarhet | — | **lukket** |
| B1-opprinnelig | **Internt verktøy eller produkt?** `ADR-0010` slår fast (operatør 2026-08-30) at regelverksovervåking er internt verktøy og *ikke noe selskapet selger*; `strategy/proposals/2026-10-05:213` sier FOA Pro er inspirasjon og aldri kopieres | Oppdraget sier «bedre enn FOA Pro». Skal det bli produkt, må ADR-0010 erstattes først — alt annet (rettigheter, lagring, visning) henger på dette | operatør |
| B2 | **Rettighetsmatrisen** — `redistribution_rights` er `RED` for lovdata og robertmyhre, `UNKNOWN` for 12 av 14 kilder. Og `lovdata.no` (vilkår: ingen distribusjon) må holdes fra `api.lovdata.no/publicData` (NLOD 2.0) | Bestemmer hva som lovlig kan lagres, analyseres og vises videre | operatør (+ jurist) |
| B3 | **KOFA-kilde og rettighetsgrunnlag** (issue 018). Skraperen er ferdig og cron-satt, men beslutningen mangler; operatøren har sagt nei til kontakt med KOFA, og det er uavklart om nedlasting av offentlige avgjørelser regnes som kontakt | Vi kjører en skraper mot en kilde vi ikke har bestemt at vi har rett til å bruke | operatør |
| B4 | **Juristens domslag** — 59 av 59 kommentarregler er `ASSUMPTION`, `verifiedBy: null`; `terskelverdier.json` er `[]`; ~20 kodesteder er merket `ASSUMPTION`/`UKJENT` (`03` §4) | Uten `FACT`-rader kan severity i praksis ikke nå `klar-feil` der det betyr mest, og terskelutledningen (`vurderPart`) er uwiret og ubrukelig | jurist |
| B5 | **Dokumenttilgang per portal** — vilkårsavklaring for Mercell/TendSign/EU-Supply/Ivalua, og om egne autentiserte økter er innenfor | L2 kan ikke løses uten dette, og L2 er det som i dag kveler regelmotoren | operatør |

## 5. Kvalitetsgapet som må lukkes før noe av dette skaleres

1. **Ingen automatisk regresjon på juridisk korrekthet.** `eval/legal-gold.json` finnes med **45
   spørsmål og forventet hjemmel**, men er koblet fra både vitest og CI (målt: `grep -rl "legal-gold" src`
   → tomt, `grep -rn "eval-legal" .github/workflows` → tomt). **Et formelt korrekt svar med feil
   hjemmel går rett gjennom.** Dette er den billigste alvorlige fiksen i hele kartet.
2. **Ingen dollargrense i kode.** `llm-usage` måler kost per kall (Haiku $1/$5, Sonnet $2/$10 per
   MTok), men ingenting stopper kjøring ved en grense (`06` §4). `generate.brief` er alene 80 % av
   målt ukeskost og ble rutet til Haiku 13.10. En motor som legger gjenfinning + reranking på hver
   analyse multipliserer kallene — og firmaet har hatt to tomme kontoer på én dag.
3. **Ingen jurist-rolle i tilgangsmodellen.** Bare `admin`/`member`/`viewer` (`04` §5); `/jurist` er
   en redirect-stub med kommentaren «there is no jurist role any more». Juristens dom kan altså ikke
   attribueres til en jurist.
4. **Dokumentasjonsdrift:** ARCHITECTURE §2 sier Postgres 16, CI kjører `postgres:18-alpine`, og
   prod er målt som PG18 tidligere i uka. Lite, men det er schema-grunnlaget for pgvector-spørsmålet.
5. **Flaten skjuler mangel i én av tre kanaler:** feilsjekk sier eksplisitt «mangler i
   rettskildekorpuset», mens `TilbudTab` dropper manglende `basis`/sitat **stille** (`07` §6).

## 6. Hva jeg anbefaler som neste steg (rekkefølge, ikke omfang)

Dette er kartleggingens anbefaling, ikke planen — planen krever at B1 og B2 er besvart.

1. **Koble gullsettet til CI** (`08` §7). Null nye avhengigheter, gjør alt videre arbeid målbart.
2. **Slå på Jev-reranking i `legal/retrieve.ts`** og kjør `eval-legal` som port. +0,12–0,16 MRR er
   alt målt, krever verken embeddings, pgvector eller operatørgate.
3. **Kjør `probeVector()` mot prod** (synlig på `/juridisk/kilder` etter deploy) og lukk den
   `UNKNOWN`-en som har holdt issue 019 i limbo siden 5. oktober.
4. **Kjør korpusoppslag inn i `contract-review`** etter mønsteret fra `feilsjekk/explain.ts` — det
   fjerner den eneste veien der en modell står alene om en juridisk vurdering (L1).
5. **Lukk B4 med juristen i én økt**: 59 kommentarrader og terskeltabellen. Det er den enkelthandlingen
   som løfter mest severity fra `usikkert` til `klar-feil`.
6. **Så, og først så, dokumenttilgang (L2) og tidsversjonering (L4)** — begge er store, begge er
   gatet, og begge er riktige å ta når beslutningene over er tatt.

**Fase 2 (API- og kildekartlegging av Lovdata, KOFA, DFØ, Doffin, TED, domstolene, regjeringen,
EUR-Lex) er ikke gjort i denne runden — den var ikke bestilt ennå.** Når den kjøres, skal den fylle
`data/sources/*.json`-skjemaet som alt finnes (15 felt per kilde, inkl. rettigheter og kostnad),
ikke et nytt format. Lovdata-raden der er utdatert: den sier `access_method: UNKNOWN` mens PRD-en
verifiserte publicData-API-et live 2026-10-05.
