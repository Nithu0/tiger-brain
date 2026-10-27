# Feilsjekk-motoren — kartlegging (admin-1, 2026-10-15)

Repo `Veldora-frist`, gren `admin-1/legal-engine-map` = `fae0ddd`. KODE-verifisert, ikke gjettet.

## 1. Filer og ansvar (`projects/anbud/crm/src/lib/feilsjekk/`)

| Fil | Ansvar |
|---|---|
| `rules.ts` (798 l) | Pure regelmotor. 6 grupper: `fristMinimum`, `tildeling`, `kvalifikasjon`, `kontrakt`, `miljo`, `rammeavtale`. `checkTender()` (rules.ts:797) kjører alle og returnerer `RawFinding[]`. |
| `miljo.ts` (206 l) | Delt klima/miljø-logikk (klassifisering av kriterier, vekt, unntak) brukt av `rules.ts` og brief. |
| `sertifikat.ts` (90 l) | Klassifiserer sertifikatkrav (`absolute`/`exclusive`) brukt av `kvalifikasjon`. |
| `store.ts` (314 l) | Payload-adapter: `loadCheckData` (henter tender/notices/docs/brief/requirements/flags), `loadLaw`, `loadKofaCandidates`, `computeFindings` (rules→law→KOFA→finalize), `withLock`, `loadFeilsjekkClarifications`, `tenderCheck`. |
| `finalize.ts` (201 l) | `RawFinding`→`TenderFinding`: verifiserer sitat mot tenderText, slår opp lovtekst/KOFA, kjører kommentar-nedgradering, lager `key` (sha1), spørsmål, sortering. |
| `kommentar.ts` (136 l) | Leser `config/kommentar-regler.json` (speil av jurist-eid JSON), `kommentarRefsFor`, `lowersSeverityReason` (kun FACT+lowersSeverity senker `klar-feil`→`usikkert`). |
| `clarify.ts` (56 l) | Nøytrale avklaringsspørsmål pr. `RuleId` — en `TEMPLATES`-tabell, aldri modellgenerert. |
| `explain.ts` (85 l) | Valgfritt modellsteg: klassifiserer `støtter|tvilsom` + forklaring. Kan bare senke `klar-feil`→`usikkert`. |
| `citations.ts` (82 l) | Jev (`judgeCitations`, NOUL-terskel) sitatkontroll før modellsteget; `checkAndExplainFindings` er endepunktets orkestrering. |
| `*.test.ts` | 118 `it(`/`test(` totalt (rules 51, miljo 14, citations 12, finalize 13, sertifikat 8, kommentar 6, store 4, explain 5, clarify 3, kommentar-exports 2). Målt: `grep -hcE "^\s*(it|test)\(" *.test.ts \| awk '{s+=$1} END {print s}'` → 118. |

## 2. Regelinventar (fra `RuleId`-union, rules.ts:20-37, verifisert mot hver funksjon)

| regel-id | sjekker | alvorlighet (default→cap) | determ./LLM | hjemmel |
|---|---|---|---|---|
| `frist-minimum` | tilbudsfrist vs. minstefrist | klar-feil→usikkert (del ukjent/haste-tekst) / anbefaling (del II) | determ. | `FOA §20-2/3/4/5 ledd-1`, `§8-14/ledd-1` |
| `tildeling-uten-vekt` | kriterier uten vekt | klar-feil/usikkert/anbefaling | determ. | `FOA §18-1/ledd-6` (III), `§8-11/ledd-1` (II) |
| `tildeling-vekt-sum` | vekt summerer ≠100% | usikkert | determ. | samme |
| `tildeling-skjonn` | skjønnspreget kriterium | usikkert | determ. | `§18-1/ledd-5`, `§8-11/ledd-2`, `LOA §4/ledd-1` |
| `tildeling-mangler` | ingen kriterier funnet (kun modell-brief) | anbefaling | determ. | samme som uten-vekt |
| `kval-omsetning` | omsetningskrav >2×kontraktsverdi | klar-feil(III)/usikkert | determ. | `§16-3/ledd-1` (III), `§8-7/ledd-2` (II) |
| `kval-erfaring` | ≥10 års erfaringskrav | anbefaling | determ. | `§16-1/ledd-1` |
| `kval-referanser` | ≥5 referanser | anbefaling | determ. | `§16-1/ledd-1`, `§16-6/ledd-1` |
| `kval-sertifikat` | sertifikat uten "tilsvarende" | anbefaling | determ. | `§16-7/ledd-1/2`, `§8-7/ledd-4` |
| `kval-sertifikat-absolutt` | sertifikat som absolutt/eneste krav | klar-feil(exclusive+III)/usikkert | determ. | `§16-7/ledd-2/3`, `§8-7/ledd-4` |
| `kval-lokal` | lokal/norsk-foretak-krav | usikkert | determ. | `LOA §4/ledd-1`, `§16-8/ledd-1` |
| `spes-merke` | merke/fabrikat uten "tilsvarende" | usikkert | determ. | `§15-1/ledd-4`, `§8-5/ledd-3` |
| `kontrakt-ubalanse` | ubalanserte kontraktsvilkår (flagg eller regex) | anbefaling | determ. | **ingen** (`lawChunkIds: []`) |
| `miljo-vekting` | manglende/under-minimum klima&miljø-vekt | klar-feil/usikkert | determ. | `LOA §5b/ledd-2`, `/ledd-3` |
| `miljo-unntak-begrunnelse` | unntak påberopt uten/ensidig begrunnelse | usikkert | determ. | samme |
| `miljo-krav-uforpliktende` | ikke-bindende miljøkrav som unntakserstatning | usikkert | determ. | `LOA §5b/ledd-2` |
| `ramme-maksverdi` | rammeavtale uten maks/anslått verdi | usikkert | determ. | `FOA §26-1/ledd-1`, `§26-3/ledd-1` |

Alle 17 har `lawChunkIds` hentet live fra korpus, **unntatt** `kontrakt-ubalanse` som alltid har `lawChunkIds: []` (rules.ts:570) — det er en kommersiell, ikke en anskaffelsesrettslig, vurdering (koden sier dette eksplisitt). Ingen regel er LLM-basert i seg selv; "LLM/determ." over gjelder funnet, ikke et eventuelt senere steg (se §5).

## 3. Regel ↔ rettskilde-mekanisme

- Hver regel skriver `lawChunkIds: string[]` direkte i koden (konstanter som `${FOA}/§20-2/ledd-1`), ikke oppslag — se f.eks. rules.ts:150, 246, 318.
- `LawLookup = (chunkId) => string | null` (rules.ts:43) injiseres inn i regler som trenger tallet i loven selv (minstefrist-dager, miljø-minimumsprosent): `fristMinimum(input, law)` og `miljo(input, law)`. Tallet (f.eks. 30%) leses fra korpusteksten, aldri hardkodet — se `minimumDays()` rules.ts:109, `minimumPercent()` i miljo.ts.
- `store.ts:loadLaw()` slår opp `legal_chunks` i Postgres for de faktiske `lawChunkIds`; `RULE_LAW_CHUNKS` (store.ts:179) pre-laster chunks reglene kan lese FØR de kjører.
- KOFA: `loadKofaCandidates()` (store.ts:95-153) finner `brudd`-avgjørelser som enten siterer samme paragraf (`CITES_ONE_OF`) eller matcher `kofaTopics`-ordene (`TOPIC_LIKE`), filtrerer bort avgjørelser under opphevet regelverk (`isOldRules`), maks `MAX_KOFA_PER_FINDING=3` pr. funn.
- Ekspertkommentar (`kommentarRefsFor`, kommentar.ts:116): kobles på `ruleId` mot `config/kommentar-regler.json` — aldri rettskilde, kan bare SENKE en `klar-feil` når raden har `status:FACT` og `lowersSeverity:true` (kommentar.ts:128-131).
- **Når hjemmel mangler:** `finalize.ts:159-162` — hvis `severity==='klar-feil'` og ALLE lenkede chunks er `found:false` (mangler i korpus), nedgraderes til `usikkert` med `downgraded: 'paragrafen mangler i rettskildekorpuset'`. Manglende chunk vises uansett i UI som `found:false`, aldri stille droppet.

## 4. Alvorlighetslogikk — fil:linje

- `capSeverity` (rules.ts:117): `(s, cap) => rank[s] >= rank[cap] ? s : cap` — kan kun senke, aldri heve.
- `part:'ukjent'` nedgraderer eksplisitt flere steder: `frist-minimum` rules.ts:189-191 (`'det er ukjent om anskaffelsen er over EØS-terskelverdien (del III)'`, legger på `§8-14/ledd-1`); `tildeling-uten-vekt` rules.ts:262-265; `kval-omsetning` rules.ts:229-231; `kval-sertifikat-absolutt` rules.ts:388; `miljo-vekting` rules.ts:498-500. Mønsteret er likt hver gang: `klar-feil` kan ikke stå når del II/III er ukjent.
- Nedgradering fra svakt bevisgrunnlag: manglende dokumentlesning (`!docsRead`, f.eks. rules.ts:260, miljo rules.ts:489), uverifisert sitat (`finalize.ts:140-143`), manglende hjemmel (`finalize.ts:159-162`), ekspertkommentar FACT (`finalize.ts:168-171`).
- `kontrakt-ubalanse` er alltid `anbefaling` — aldri `klar-feil` (kommersiell vurdering, ikke anskaffelsesrettslig brudd) — rules.ts:560-568.

## 5. LLM vs. determinisme — grensen

Regelmotoren selv (`rules.ts`, `miljo.ts`, `sertifikat.ts`, `finalize.ts`, `clarify.ts`) er **100% ren/deterministisk** — ingen modellkall, kun regex/dato/tallregning over egne data. Grensen går eksplisitt ved `store.ts:computeFindings()` → returnerer `TenderFinding[]` uten modell. Herfra, i endepunktet (`endpoints/feilsjekk.ts:28`) kalles `checkAndExplainFindings`:
1. `citations.ts:checkFindingQuotes` — Jev (`judgeCitations`, NOUL-skår) kontrollerer bare `klar-feil`-funn med verifisert sitat; kan bare senke.
2. `explain.ts:explainFindings` — valgfritt (kun ved `?forklar=1` og `isLlmEnabled()`), ett `completeJson`-kall klassifiserer `støtter|tvilsom` og skriver forklaring; `tvilsom` på `klar-feil` senker til `usikkert` (explain.ts:40-42). Modellen kan **aldri** heve severity eller legge til et funn — koden har ingen kodesti for det.

## 6. Eksportvakt og tester

`kommentar-exports.test.ts` (2 tester) grepper kildekoden i `lib/tilbud,prising,salg,energidata,email,rapport,klage,henvendelser,documents,prompts` + `lib/qualification/docx.ts` for `kommentarRefs|sourceRefs|robertmyhre\.no` og forventer tom liste — garanterer at ekspertkommentar aldri lekker til kundeflatene (tilbud, e-post, modellprompt). Andre test: speil-filen har bare lenke+egne-ord-sammendrag (≤200 tegn, faste nøkler), ingen artikkeltekst.

## 7. Tilstand: I DRIFT

Wiret til ekte endepunkt, ikke løs kode:
- `endpoints/feilsjekk.ts`: `GET /api/anbud/opportunity/:id/feilsjekk[?forklar=1]`, `POST .../avklaring`, `GET /api/anbud/legal/feilsjekk` (oversikt).
- Registrert i `payload.config.ts:89,188` (`feilsjekkEndpoints` i `endpoints` array).
- Konsumert av dashboard: `dashboard/src/components/Feilsjekk.tsx`, `FeilsjekkClarify.tsx`, `SeOgsaa.tsx`, `app/(app)/juridisk/feilsjekk/[id]/page.tsx`, `app/(app)/juridisk/page.tsx`, `lib/feilsjekk.ts`, `types-feilsjekk.ts`, `actions-feilsjekk.ts`.

## Sammendrag (maks 10 linjer)

Feilsjekk-motoren (`crm/src/lib/feilsjekk/`) er en ren, deterministisk regelmotor: 17 regler i `rules.ts` (798 linjer) sjekker frist/tildeling/kvalifikasjon/spesifikasjon/kontrakt/miljø/rammeavtale over egne CRM-data — ingen LLM i selve regellogikken. Hver regel skriver `lawChunkIds` direkte i kode og tallverdier (minstefrist, 30%-miljøvekt) leses live fra Postgres-korpuset via en `LawLookup`-injeksjon, aldri hardkodet; KOFA-"brudd"-avgjørelser matches på sitering eller temaord med maks 3 pr. funn. `part:'ukjent'` nedgraderer systematisk hver `klar-feil`-regel til `usikkert` (5+ steder, samme mønster). LLM-grensen er skarp og kodet: `computeFindings()` er 100% ren; et Jev-sitatkontroll-steg og et valgfritt `explain`-modellkall kommer FØRST i endepunktet (`endpoints/feilsjekk.ts`) og kan bare senke severity, aldri heve eller legge til funn. 118 tester dekker mappen, inkl. en egen eksportvakt-test som grepper 10+ kundeflate-mapper for å garantere at ekspertkommentar-referanser aldri lekker til tilbud/e-post/prompts. Motoren er bekreftet I DRIFT: registrert i `payload.config.ts`, eget REST-endepunkt, og konsumert av 7+ dashboard-filer (ikke uwiret kode).

## Tre viktigste funn

1. **Grensen determinisme/LLM er skarp og verifiserbar i kode**: `store.ts:computeFindings()` er 100% ren regelmotor; LLM kommer kun i `endpoints/feilsjekk.ts` via `checkAndExplainFindings` (Jev-sitatkontroll + valgfritt `explain`), og kan utelukkende senke severity (`explain.ts:40-42`, `citations.ts`) — aldri heve eller skape funn. Ingen kodesti motsier dette.
2. **`part:'ukjent'` er en systematisk brems**, ikke et kantfall: 5 separate steder i `rules.ts` (frist, tildeling-uten-vekt, kval-omsetning, kval-sertifikat-absolutt, miljo-vekting) nedgraderer eksplisitt `klar-feil`→`usikkert` når del II/III-status er ukjent, med identisk begrunnelsestekst — bevisst konservativ design.
3. **`kontrakt-ubalanse` er den eneste regelen uten hjemmel** (`lawChunkIds: []`, rules.ts:570) — den er en kommersiell vurdering, ikke en anskaffelsesrettslig påstand, og er derfor låst til `anbefaling` for alltid, uavhengig av input.
