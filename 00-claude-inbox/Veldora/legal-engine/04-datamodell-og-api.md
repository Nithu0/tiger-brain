# Datamodell og API-flate — Veldora anbud/crm

Scope: `/home/nithu/code/Veldora-frist/projects/anbud/crm`. Les-only, bevis = `fil:linje`. KODE = finnes i src, verifisert her. Ingen DB-tilkobling gjort (ingen rad-tall målt i denne runden utover det brief nevner).

## 1. Samlingsinventar

`ls src/collections | wc -l` → **76** filer, men det inkluderer 18 `*.test.ts`. Reelle samlinger (`.ts` ekskl. test) = **58**, og det stemmer med antall oppføringer i `collections:`-arrayen i `src/payload.config.ts:127-186` (58 entries, telt manuelt). Payload legger i tillegg til interne tabeller (`payload-jobs`, `payload-preferences`, `payload-migrations`) som ikke står i arrayen.

Samling (slug) · db-tabell (hvis overstyrt, ellers = slug m/underscore) · nøkkelrelasjoner (`relationTo` i filen) · juridisk innhold:

| Slug | dbName override | Nøkkelrelasjoner | Juridisk? |
|---|---|---|---|
| legal-documents | — | — (rot i juss-kjeden) | **JA** — rettskildekorpus (lov/forskrift/KOFA), `src/collections/LegalDocuments.ts:1-9` |
| legal-chunks | — | legal-documents | **JA** — ett ledd pr. rad, ordrett tekst, `LegalChunks.ts:1-13` |
| legal-flags | — | bid-drafts, documents, opportunities, users | **JA** — jurist-flagg på tilbudsutkast, `LegalFlags.ts:18-19` |
| legal-questions | `legal_questions` | opportunities, users | **JA** — spørsmål stilt til juss-assistenten, `LegalQuestions.ts:20-21` |
| klage-cases | — | opportunities, users | **JA** — klage/innsyn-saker, «sendes aldri automatisk», `KlageCases.ts:40,49` |
| klage-documents | — | klage-cases, opportunities | **JA** — vedlegg til klagesak |
| kommentar-vurderinger | — | users | **JA** — jurist-dom pr. kommentarregel (data frøet fra `data/legal/kommentar-regler.json`, ARCHITECTURE.md:2668) |
| qualification-assessments | `qual_assessments` | evidence, opportunities, qualification-assessments (selv-ref `reviewOf`), requirements, users | delvis — kvalifikasjonskrav, ikke rettskilde selv |
| evidence | — | documents, evidence (selv-ref `supersedes`), users | delvis — bevis for kvalifikasjon, ikke rettskilde |
| requirements | `req_qual_ers` (nested) | documents, opportunities, qualification-assessments | delvis — kravutsnitt fra konkurransedokument |
| reservations | — | bid-drafts, legal-flags, opportunities, requirements, users | delvis — forbehold/avvik koblet til legal-flags |
| bid-sections / bid-drafts / bid-approvals / bid-comments | — | se linje ovenfor | nei (tilbudsproduksjon, men `legal-step` i tilbud.ts rører dem) |
| tenders | — | buyers, tenders (selv-ref?) | nei — selve kunngjøringen |
| opportunities | — | suppliers, tenders, users | nei — vår vurdering av en tender |
| briefs | — | opportunities | nei |
| documents | — | opportunities | nei — opplastede filer (tender- ELLER bevis-dokument, styrt av `purpose`) |
| + 35 andre CRM-interne samlinger (Activities, AgentRuns, Approvals, Awards, Buyers, CapabilityFacts, ChatChannels/Imports/Messages/Reads, Customers, Cvs, EmailSends, Energidata, Fakturaer, HelperConversations, InterviewQuestions, KsSjekklister, LlmUsage, MarketSnapshots, NewsDigests/Items, Notes, Oppdrag, People, Predictions, Prospekter, PushSubscriptions, References, Salgstilbud, Signals, Suppliers, TenderDecisions, Timer, Ukesrapporter, Users, WatchItems, WorkspaceItems) | — | se `src/collections/*.ts` | nei — drift/salg/HR/kommunikasjon, ingen juridisk innhold funnet (grep `jurist|legal|klage` ga ingen treff i disse filene) |

## 2. Globaler (`src/globals/*.ts`, 11 stk, alle i `payload.config.ts:187`)

| Global | Styrer |
|---|---|
| bid-settings | Standard godkjennere for nye tilbud (anbudsansvarlig/anskaffelsesrådgiver/jurist/faggruppe) |
| data-policy | Datapolicy-gate som `lib/llm.ts` spør før hvert modellkall (`payload.config.ts:213-215`) |
| decision-profile | Lært beslutningsprofil (json, read-only, agent-skrevet) |
| inbox-settings | Hovedbryter for utsending fra innboks — av som standard |
| kofa-ingest-state | Inkrementell inntaks-tilstand for KOFA-henting |
| okonomi-settings | Hvilket regnskapssystem (mock/fiken) fakturakladder lages i |
| sales-settings | § 8-avklaring må registreres før pakke B/C/D kan tilbys |
| supplier-profile | Vår leverandørprofil/kredittratinger — kun admin kan endre |
| worker-heartbeat | Puls fra bakgrunnsworker |
| workspace-sync | Gmail/kalender/Drive/Tasks-synk-tilstand |
| calibration-backtest | Tilbakeskuende kalibreringsmål (n, metrics) |

## 3. Endepunktinventar (`src/endpoints/*.ts`, 27 filer eks. tester, i `payload.config.ts:188-189`)

Alle API-ruter er under Payload sin `/api` (Next.js). Tilgang: **P**=ingen auth-sjekk funnet, **L**=krever innlogget (`req.user`), **M**=krever member\|admin (`isEditorRole`/`roleOf`), **A**=krever admin. Verifisert pr. fil via grep på `roleOf(req)`/`isAdmin`/`req.user`.

**Juridiske ruter (markert etter oppdrag):**

| Metode+sti | fil:linje | Hva | Tilgang |
|---|---|---|---|
| POST /anbud/legal/ask | legal.ts:160 | RAG-spørsmål mot lovdata/KOFA-korpus | L |
| GET /anbud/legal/questions | legal.ts:161 | Liste over stilte spørsmål | **A** (`legal.ts:136-138`) |
| GET /anbud/legal/sources | legal.ts:162 | Liste rettskilder | L |
| GET /anbud/legal/search | legal.ts:163 | Fulltekstsøk i legal-chunks | L |
| GET /anbud/legal/document | legal.ts:164 | Hent én rettskilde | L |
| GET /anbud/legal/paragraph | legal.ts:165 | Hent én paragraf/ledd | L |
| GET /anbud/legal/kofa | legal.ts:166 | KOFA-avgjørelser | L |
| GET /anbud/opportunity/:id/feilsjekk | feilsjekk.ts:107 | Regelbasert feilsjekk av en mulighet | L |
| POST /anbud/opportunity/:id/feilsjekk/avklaring | feilsjekk.ts:108 | Registrer avklaring på feilsjekk-punkt | M (`feilsjekk.ts:36-38`) |
| GET /anbud/legal/feilsjekk | feilsjekk.ts:109 | Oversikt feilsjekk tvers av muligheter | L |
| GET /anbud/opportunity/:id/klage | klage.ts:159 | Hent klagesak | L |
| POST /anbud/opportunity/:id/klage | klage.ts:160 | Opprett/oppdater klageutkast | M (`klage.ts:31-32`) |
| POST /anbud/opportunity/:id/klage/les | klage.ts:161 | Marker lest | L |
| GET /anbud/opportunity/:id/klage/innsyn.docx | klage.ts:162 | Generer innsynsbegjæring (docx) | L |
| GET /anbud/legal/klage | klage.ts:163 | Oversikt klagesaker | L |
| GET /anbud/kommentar | kommentar.ts:101 | Liste kommentarregler m/jurist-dom | L |
| POST /anbud/kommentar/:rowId/vurder | kommentar.ts:102 | Jurist setter dom på kommentarregel | M (`kommentar.ts:21-22`) |
| POST /anbud/bid/:id/legal-step | tilbud.ts:800 | Trigger jurist-steg i tilbudsflyt | M (fil-mønster, ikke enkelt-verifisert) |
| POST /anbud/bid/:id/contract-review | tilbud.ts:803 | Kø agent-jobb kontraktsgjennomgang | M |
| POST /anbud/legal-flag/:id/review | tilbud.ts:808 | Jurist avgjør et legal-flag | M |
| GET /anbud/legal/queue | tilbud.ts:810 | Jurist-kø tvers av tilbud | M |
| GET /anbud/opportunity/:id/qualification | qualification.ts:217 | Kvalifikasjonsvurdering for mulighet | L |
| GET /anbud/opportunity/:id/qualification/docx | qualification.ts:218 | Samme som docx | L |
| POST /anbud/assessment/:id/review | qualification.ts:219 | Menneskelig overstyring av vurdering | M (`qualification.ts:152-154`) |
| GET /anbud/evidence-vault | evidence.ts:136 | Bevisarkiv-oversikt | L |
| POST /anbud/evidence/reference | evidence.ts:137 | Registrer referanse-bevis | M (`evidence.ts:43-45`) |
| POST /anbud/evidence/brreg-refresh | evidence.ts:138 | Oppdater fra Brreg | L (ingen rolle-sjekk funnet utover user) |
| POST /anbud/evidence/:id/confirm | evidence.ts:139 | Bekreft bevis | L |
| POST /anbud/evidence/:id/reject | evidence.ts:140 | Avvis bevis | **A** (`evidence.ts:68-69`) |

**Alle andre ruter** (104 til, ikke-juridiske — salg, triage, tilbud-produksjon, levering, økonomi, chat, varsler osv.), gruppert pr. fil, finnes i: `anbud.ts:463-466` (4), `aiUsage.ts:53` (1), `henvendelser.ts:200-205` (6, M for skriv), `insight.ts:102-104` (3), `kontaktskjema.ts:48` (1, **P** — ingen `req.user`-sjekk funnet, ekstern kontaktskjema), `prospekter.ts:84-87` (4, M for skriv), `salg.ts:318-323` (6, M for skriv), `tilbud.ts:793-810` minus de juridiske over (14), `triage.ts:420-425` (6, M for decide), `avvik.ts:120-121` (2, M), `rapport.ts:77-80` (4, M for skriv), `chat.ts:508-514` (7), `helper.ts:188-191` (4), `leveranse.ts:220-226` (7, M for skriv), `okonomi.ts:157-162` (6, M for skriv), `rammeavtale.ts:205-207` (3, M for skriv), `godkjenning.ts:86-88` (3, M), `push.ts:93-96` (4), `kompetanse.ts:175-181` (7, M for skriv), `energidata.ts:180-185` (6, A for sletting), `whatsapp.ts:56-57` (2, **P** — ekstern webhook, ingen `req.user`-sjekk). Totalt **129 ruter** i `endpoints:`-arrayen, `payload.config.ts:188-189`.

## 4. Migrasjoner

`ls src/migrations | grep -v '\.ts$\|\.json$' ` → mappen har **102** filer (`.ts`+`.json`-par pr. migrasjon + `index.ts`), dvs. ca. 50 reelle migrasjoner. Nyeste: `20261012_210000_scope_backfill_enum.ts`. Kjørekommando: `"migrate": "payload migrate"` i `package.json:16`. `payload.config.ts:191-196` har kommentar: *«Schema changes go through migrations only (src/migrations), in dev too»* og `push: false` — altså ingen auto-push av schema, migrasjon må køres eksplisitt. **FINNES IKKE i repo** (målt: `grep -rn "vercel-build\|postinstall" package.json` → ingen treff) en automatisk `migrate`-kjøring ved Vercel-deploy fra selve repoet; om Vercel-prosjektets build-command overstyrer dette er ikke synlig i koden.

## 5. Tilgangskontroll

`src/access/index.ts:1-31`: tre roller (`Role = 'admin' | 'member' | 'viewer'`, `Users.ts:40-46`). Ingen egen jurist-rolle — kommentar i `LegalFlags.ts`/`Users.ts:46` bekrefter at `member`/`admin` gjør juridisk gjennomgang. Helpers: `isLoggedIn`, `isAdmin`, `isMemberOrAdmin`, `nobody`, felt-variantene `fieldIsAdmin`/`fieldIsMemberOrAdmin`/`fieldNobody`, og `readOnlyForHumans` (read=innlogget, write=admin — brukt av `legal-documents` og `legal-chunks`, dvs. **kun agent-ingest skriver rettskildekorpuset, ingen mennesker**).

Lese/skrive juridiske samlinger (collection-access, verifisert pr. fil):
| Samling | read | create | update | delete |
|---|---|---|---|---|
| legal-documents / legal-chunks | isLoggedIn | **isAdmin** (readOnlyForHumans — reelt kun agent via overrideAccess) | isAdmin | isAdmin |
| legal-flags | isLoggedIn | isAdmin | isAdmin | isAdmin |
| legal-questions | `readOwnOrAdmin` (egen-definert) | isAdmin | isAdmin | isAdmin |
| klage-cases / klage-documents | isLoggedIn | isMemberOrAdmin | isMemberOrAdmin | isAdmin |
| kommentar-vurderinger | isLoggedIn | isMemberOrAdmin | isMemberOrAdmin | isAdmin |
| qualification-assessments / evidence | isLoggedIn | **nobody** (kun agent, overrideAccess) | nobody | isAdmin |

## 6. Relasjonskjeden mot juridisk innhold

```
tenders ──(required,unique)── opportunities ──(required)── requirements ──(relationTo)── documents
                                   │                              │
                                   │                              └── qualification-assessments ── evidence
                                   ├──(required,unique)── briefs
                                   ├──(required)── legal-flags ──(required)── bid-drafts
                                   │                    └── document (optional)
                                   ├──(required,unique)── klage-cases ── klage-documents
                                   └──(index)── legal-questions

legal-documents ── legal-chunks            (EGEN korpus-kjede, IKKE koblet til opportunities/tenders)
kommentar-vurderinger                       (fristående — ingen FK til opportunities/requirements)
```
Fremmednøkler er hentet fra `relationTo:` i hver fil (§1-tabellen). **Viktig avvik:** `legal-documents`/`legal-chunks` (rettskildekorpuset) har ingen relasjon til `opportunities`/`tenders`/`requirements` i koden — koblingen til en konkret anbudssak går via `legal-flags.document`/`legal-flags.opportunity` og via `legal.ts:89` sitt `CONTEXT_COLLECTION`-oppslag (henter kontekst-dokument på `refId`, ikke en FK-kolonne).

## 7. Hva er tomt / ikke målt

- **Ikke målt i denne runden**: radtall i `documents` (brief nevner 0 rader i prod) og `documentsUrl`-dekning (`Tenders.ts:105`) — ingen DB-tilkobling er gjort her per regel 1. Måleskriptet som finnes i repoet for dette er `scripts/dokumentdekning.ts:1-13` (kjøres med `npm run dokumentdekning`, leser `queueWhere` fra `src/lib/triage`, teller kun `purpose === 'tender'`-dokumenter).
- **`deleteJobOnComplete`**: FINNES IKKE i kode (målt: `grep -rn "deleteJobOnComplete" .` i crm → ingen treff, og `payload.config.ts:199-203` sin `jobs:`-blokk setter ikke dette). Brief-påstanden om at vellykkede jobber slettes er altså ikke eksplisitt konfigurert i denne appen — enten er det Payload sin standardverdi (ikke verifisert her), eller påstanden gjelder noe annet sted.
- **Rettskildekorpus uten saksbinding**: `legal-documents`/`legal-chunks` har 0 FK-felt mot `opportunities`/`tenders` (§6) — strukturelt «tomt» for sakskobling, bevis = feltlisting i `LegalDocuments.ts`/`LegalChunks.ts`.
