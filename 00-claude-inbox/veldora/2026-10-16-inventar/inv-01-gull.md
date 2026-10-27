# inv-01-gull — Hva i `ai-assistent` (Nexus) er gjenbrukbart for Veldora

Read-only inventar, 2026-10-16. Kilde: `/home/nithu/code/ai-assistent` (sist commit **2026-09-01**, kun 2 commits siste 90 dager) + `~/Obsidian/Brain/`.
Metode: direkte lesing + 4 parallelle inventar-agenter. **VERIFISERT** = lest i kildefil. **INFERRED** = utledet fra navn/struktur.

---

## 0. Sammendrag + én korreksjon av premisset

Oppdraget antok «enorme mengder PDF-er, bøker og kursmateriale matet inn i gull-prosjektet». **Det stemmer ikke.** Det finnes ingen stor dokument-korpus i `ai-assistent`. Det som finnes — og som er langt mer verdt — er:

1. En **kjørende Qdrant vektor-minnetjeneste** (721 linjer, produksjon).
2. Et **kalibrert små-utvalgs ML-scoringskit** (purged CV, Brier, Platt-skalering).
3. En **gate-arkitektur med soft-log-først + kontrafaktisk gate-analyse**.
4. En **fact → analysis → challenge blackboard-arkitektur**.
5. Et **kuratert kunnskapsbibliotek + skill-rutingsmønster** som er direkte kopierbart.

Den virkelige gjenbruksverdien ligger i **mekanismene**, ikke i innholdet.

---

## 1. Dokument-korpus — hva som faktisk finnes

### 1.1 I `ai-assistent`-repoet: tilnærmet ingenting

`find` etter `*.pdf|*.epub|*.mobi|*.azw3|*.djvu` i hele repoet gir **2 treff, og begge er samme fil**:

| Fil | Størrelse | Hva det er |
|---|---|---|
| `/home/nithu/code/ai-assistent/manusscript.pdf` | 2,24 MB, 24 sider | **VERIFISERT via `pdftotext`: ikke trading.** Det er masteroppgave-manuskriptet «LiAgent: A Multi-Agentic AI-powered Foundational Platform for Lithium Electrolyte Innovation», Journal of Power Sources, POWER-D-26-03791, korresponderende forfatter Ramzi Alnubani (NTNU). Ligger feil sted — tilhører `Master-oppgave/`. |
| `/home/nithu/code/ai-assistent/.github/manusscript.pdf` | 2,24 MB | Identisk duplikat. |

De 21 GB i `ai-assistent` er **ikke korpus**: 20 GB er `.claude/worktrees/` (≈ 25 git-worktrees med hver sin `node_modules`, inkl. 130 MB `next-swc` per stk.), 817 MB rot-`node_modules`, 52 MB `.git`. Ryddekandidat, ikke kunnskapsressurs.

### 1.2 Hele hjemmekatalogen: 437 filer / 527 MB, men nesten ingenting er trading

| Katalog | Filer | Størrelse | Tema |
|---|---|---|---|
| `code/research-os/data/` | 163 | 356,4 MB | Materialvitenskap/batteri-artikler (masteroppgave) |
| `code/Søking fulltid/` (sendt+profil+maler+utkast) | 100 | 9,4 MB | Jobbsøknader, CV-er |
| `code/Master-oppgave/` (.quarantine m.m.) | 11 | 99,4 MB | Tesis |
| `code/Veldora*/` (CV, team-cv, projects, secure, kravspek) | 17 | ~7 MB | **Veldoras egne anbudsdokumenter** |
| `code/AS/`, `aslisten-crm/` | ~20 | ~4 MB | Regnskapsbilag |
| `Obsidian/Brain/14-books/_queue/` | 2 | 26,7 MB | **De eneste trading-bøkene** |

**Trading-korpus på disk = 2 filer:**
- `~/Obsidian/Brain/14-books/_queue/Advanced+Futures+Trading+Strategies+30+fully+tested+strategies+for+multiple+trad.epub` (25,7 MB — Robert Carver, 2023)
- `~/Obsidian/Brain/14-books/_queue/Successful Algorithmic Trading.pdf` (2,3 MB)

Begge ligger fortsatt i `_queue/`, `_queue/_done/` og `_queue/_failed/` er **tomme** → **bok-ingest har aldri kjørt på dem.** (`BOOK_INGEST_ENABLED` + `BRAIN_ENABLE_QUEUE_WATCHER` er default-OFF, og `14-books/_queue` står ikke i watcherens default `queueDirs` — VERIFISERT i `~/Obsidian/Brain/14-books/README.md`.)

### 1.3 Det faktiske korpuset er YouTube-transkripsjoner, ikke bøker

`~/Obsidian/Brain/_library/youtube/` — **97 `transcript.txt`, 4,5 MB, ≈ 471 000 ord** fordelt på 26 kanaler.

Trading-relevant delmengde (VERIFISERT ordtelling):

| Kanal | Ord | Innhold |
|---|---|---|
| flirting-with-models | 122 232 | Quant-intervjuer (Antti Ilmanen, Numerai/Richard Craib, trend-følging, faktor-investering) |
| better-system-trader | 77 542 | Systematisk trading-kanon: Kevin Davey, Jerry Parker, Linda Raschke, Perry Kaufman, Larry Connors, Adam Grimes |
| quantified-strategies | 10 558 | Backtestede regelsett, HMM-regimedeteksjon |
| hudson-thames | 418 | Nesten tomt |
| **Sum trading** | **≈ 211 000** | |

Resten (≈ 260 000 ord) er materialvitenskap (`taylor-sparks`, `atoms-to-materials`, `fabervaale-eng`), regnskap (`fiken`), AI-engineering og GTM/salg.

**Viktig kvalitetsforbehold (VERIFISERT):** av 138 distillerte notater i `~/Obsidian/Brain/12-youtube/` inneholder **97 teksten «covers material summarized mechanically pending LLM distillation»** — altså placeholder-notater der råtranskriptet finnes, men LLM-destillering aldri kjørte. Kun ~41 notater (hovedsakelig `fiken/`) har reelt innhold. **De 211 000 ordene med trading-transkript er i praksis udestillert råmateriale.** For Veldora betyr det: ingen ferdig destillert korpus å kopiere, men en ferdig *pipeline-form* (se §2).

### 1.4 Det kuraterte biblioteket — lite, men av høy kvalitet

`~/Obsidian/Brain/_library/trading/` — **18 notater, ≈ 16 900 ord totalt.** Dette er det håndskrevne gullet.

| Mappe | Antall | Standout-titler |
|---|---|---|
| `concepts/` | 11 | `regime_taxonomy.md` (6,7 kB), `karri_mental_model.md` (7,1 kB), `blade_gate_stack.md`, `conviction_score.md`, `position_management.md`, `foundation_gate_tier3.md` |
| `strategies/` | 5 | `mean_reversion_xau.md`, `orb_xau.md`, `session_breakout.md`, `volatility_expansion.md`, `scalp_overlap.md` |
| `lessons/` | **0** | Tom siden 2026-05-13 — den planlagte destillerings-kadensen ble aldri gjennomført |
| `sources/` | 2 | `karri_quotes_corpus.md` (20,6 kB), `2026-06-01_xauusd-systematic-sourcing.md` (13,1 kB) |

Notat-anatomien er verdt å kopiere direkte. `strategies/mean_reversion_xau.md` har: frontmatter med `relevance_to_nexus: 5` + `claude_priority: P0` + tags → «Archetype (50 ord)» → «Hvorfor instrumentet har disse vinduene (70 ord)» → **implementasjon med eksakt filsti og linjenummer** (`orchestrator.ts:430`) → tallfestede parametre → «Single biggest live risk» → «Cross-references» til bøker. Ordgrenser i overskriftene tvinger fram komprimering.

### 1.5 «Bibliografien» — en kuratert kildeliste, ikke filer

`~/Obsidian/Brain/_library/trading/sources/2026-06-01_xauusd-systematic-sourcing.md` (13,1 kB) er en **rangert kildeanalyse** med 8 bøker + 2 tillegg + 3 artikler, hver med «hva dette gir prosjektet» og ISBN/kjøpslenke. Eksplisitt policy i dokumentet: *«Buy legitimately — no piracy PDFs.»* Det forklarer hvorfor det ikke finnes noen PDF-haug: **operatøren valgte bevisst bibliografi framfor nedlastet korpus.**

Rangerte bøker: Carver *Advanced Futures Trading Strategies* (#1) og *Systematic Trading* (#2), Chan *Algorithmic Trading* (#3) og *Quantitative Trading* (#6), Fisher *The Logical Trader* (#4), Connors & Alvarez *Short Term Trading Strategies That Work* (#5), Van Tharp (#7), Crabel *Day Trading with Short-Term Price Patterns & ORB* (#8, flagget som sjelden/utsolgt). Tillegg: Kaufman *Trading Systems and Methods*, **López de Prado *Advances in Financial Machine Learning*** (den som faktisk ble implementert — se §5).

Artikler: arXiv:2107.05535 (aktivaklasse-uavhengig HMM-regimeskifte), arXiv:2310.04536 (fikser HMMs «kan ikke predikere skiftet»-svakhet), arXiv:2407.16376 (Bayesiansk online change-point), samt en regelbasert bull/bear-regime-artikkel.

**For Veldora:** selve dokumentet er en mal — «rangert kildeanalyse med eksplisitt *hva dette gir oss*-begrunnelse per kilde» er direkte overførbart til en anbuds-/offentlig-anskaffelser-bibliografi (LOA/FOA, KOFA-praksis, DFØ-veiledere).

---

## 2. Hvordan materialet ble gjort søkbart

### 2.1 Qdrant vektor-minne — LIVE, og den viktigste enkeltressursen

`/home/nithu/code/ai-assistent/apps/worker/src/services/memory.service.ts` — **721 linjer**, siste commit 2026-05-08.

> Merk: den første inventar-agenten konkluderte med «ingen vektorlager finnes». **Det er feil.** Jeg verifiserte selv ved å lese filen. Agenten søkte kun etter pgvector/Chroma/FAISS/sqlite-vec og gikk glipp av Qdrant.

VERIFISERT ved lesing. Mekanisme:
- `@qdrant/js-client-rest`, collection `nexus_memory` (overstyrbar via `QDRANT_COLLECTION` for ren dimensjonsmigrering), `VECTOR_SIZE = 1536` (`text-embedding-3-small`), cosine-distanse.
- Embedding genereres via `llm-router.service.ts`, med **fallback til nøkkelordmatching** hvis ingen embedding-modell er tilgjengelig.
- Typet minne: `narrative | signal-outcome | trade-review | regime | pattern | macro | news`, hver med `importance` (1-10), `confidence` (0-100), `tags[]`, `expiresAt` (TTL).
- **Eksplisitte payload-indekser** på `symbol`/`type`/`sentiment`/`createdAt` (keyword) og `importance` (integer) — kommentaren i koden dokumenterer at Qdrant returnerer 400 «Index required but not found» uten dem, og at nettopp det var feilen bak en tidligere stille nedkobling.
- **Selvhelbredende søkesti:** `searchMemory()` prøver først full forespørsel (filter + `score_threshold`), og ved feil en «minimal» bar sti med JS-ettersortering; hvis den minimale virker settes `useMinimalSearchPath = true` for resten av økten. Hvis også den feiler, slås en **kill-switch** på som får alle kall til å returnere umiddelbart (ingen re-enable i runtime — med vilje, «a mismatch needs operator attention, not silent retry»). One-shot loggflagg hindrer loggspam.
- API: `initMemory`, `writeMemory`, `searchMemory`, `getMemoryStatus`, `getMemoryCountsByType`, `cleanupOldMemories`, `memorizeNarrative`, `memorizeTradeReview`, `memorizeSignalOutcome`, `recallSimilar`.

**Live-wiring VERIFISERT** — importeres fra worker-entrypoint og orkestrator:
`apps/worker/src/index.ts:14` (`initMemory`), `firm/orchestrator.ts:74` (`cleanupOldMemories`), `firm/firm-memory.ts:21` (`searchMemory`), `firm/status-report.ts:22`, `firm/managers.ts:23`, `agents/briefing.agent.ts:15` (`recallSimilar`), `services/trade-review.service.ts:17`.

Dette er en ferdig produksjonshardnet RAG-lagringsmotor med feilhåndtering som bare oppstår etter reell drift.

### 2.2 Postgres fulltekst-søk over chunket eksternt innhold — LIVE

- `apps/worker/src/firm/agent-knowledge/client.ts` (247 linjer, sist 2026-06-07). `searchByText()` bruker `ts_rank_cd` + `plainto_tsquery('english', …)`, rangert `operator_rating DESC, rank DESC, reference_count DESC`, med tag-boost via array-overlapp (`&&`). **Bruksvektet gjenfinning:** hvert treff øker `reference_count` og setter `last_referenced_at` — ofte brukt kunnskap stiger.
- `apps/worker/src/firm/agent-knowledge/injection.ts` (92 linjer). `buildKnowledgeContext()` + `formatKnowledgeBlock()` rendrer markdown **med attribusjon** (tittel/forfatter/url/rating/chunk-indeks) i en kappet blokk (default 5 chunks) for prompt-injeksjon.
- Tabellen `agent_knowledge` (`packages/shared/src/db/schema.ts` ~linje 1398): `status` pending/active/archived — **menneskelig godkjenningsport før noe er søkbart** — GIN-indeks på tsvector + `topic_tags`, pluss `operator_rating`/`operator_note` som tilbakemeldingssløyfe.
- `embedding`-kolonnen er **JSONB, ikke vektortype**, og ingen cosine-SQL finnes. Dvs. Postgres-benet er ren FTS; vektorsøket skjer i Qdrant (§2.1), ikke her.

### 2.3 Ingestion og embedding — eksisterer, men dormant

- `scripts/firehose/ingest-youtube.mjs` (191 linjer, commit 2026-05-06): `yt-dlp` → auto-subs (.vtt) → strip VTT-markup/dedupe → setningsgrense-chunking (~1500 tegn, regex-split + greedy pack) → `agent_knowledge` med `status='pending'`. Gated av `AGENT_KNOWLEDGE_ENABLED`/`FIREHOSE_FORCE`.
- Samme `chunkText()` er duplisert i `agent-knowledge/client.ts` — liten, ren, portabel funksjon.
- `scripts/firehose/lib/embeddings.mjs` (89 linjer): leverandøragnostisk `embed(texts)` over rå `fetch` — OpenAI `text-embedding-3-small` eller Voyage `voyage-3`, ingen SDK-avhengighet. `cosineSim()` finnes, men **kalles kun fra sin egen test** — aldri i produksjonsgjenfinning.
- `scripts/firehose/embed-pending.mjs` (125 linjer): batch-embedding av rader der `embedding IS NULL`, bulk-skriv tilbake via `UNNEST`. Idempotent.
- `scripts/firehose/nightly-dump.mjs` (108 linjer): eneste bruk av **duckdb-async** i repoet. In-memory DuckDB attacher Postgres read-only via `postgres_scanner`, `COPY (…) TO '*.parquet'` for 8 tabeller, 90 dagers lokal retensjon. **Backup-eksportør, ikke analysemotor.**
- **Firehose-status (VERIFISERT i `docs/CONTEXT-MAP.md:50`): «firehose not yet deployed to prod.»** Ukedigesten viser alle relevante flagg som `(unset)`. Ingen cron/systemd-unit refererer skriptene. **Dormant.**

### 2.4 Prompt-caching: finnes ikke

Ingen Anthropic `cache_control`/ephemeral noe sted (de to grep-treffene på «ephemeral» i `orchestrator.ts` og `raw-data-persistence.ts` gjelder syklus-flyktige blackboard-data). Det som finnes er **kostnadsregnskap**, ikke caching: `apps/worker/src/firm/agent-bus/firm-agents/llm.ts` (356 linjer, 2026-06-03) med per-modell `PRICE_PER_1K_TOKENS`, `estimateCostUsd()`, hard `MAX_PROMPT_BYTES = 50_000` via `capPrompt()`, og automatisk Anthropic→OpenAI-fallback ved credit/quota/rate-limit-feil.

### 2.5 Brain-pakkene i command-center (ekstern, men relevant)

Ikke i `ai-assistent`, men de ferdige ingestion-/RAG-pakkene finnes i `/home/nithu/code/command-center/packages/`: `rag-engine` (`bm25.ts`, `vector.ts`, `hybrid.ts`, `fusion.ts`, `rerank/`, `metrics.ts`, `agentic/`), `memory-engine` (`distill-real.ts`, `embedding.ts`, `idf-table.ts`, `facets/`), `book-ingest` (`extract.ts`/`chunk.ts`/`distill.ts`/`note.ts`/`queue.ts`, 14 filer, alle med tester, sist rørt 2026-07-15), `youtube-ingest`, `obsidian-ingest`, `skill-registry`. **Hybrid BM25+vektor finnes altså ferdig — bare ikke i gull-prosjektet.** For Veldora er dette sannsynligvis et bedre utgangspunkt enn Nexus' halvbygde firehose.

---

## 3. `trading-knowledge`-skillen — mønsteret, ikke innholdet

`~/.claude/skills/trading-knowledge/SKILL.md` — 6 296 byte, v0.2.0, **sist endret 2026-05-13 (17 mnd uendret)**. Enkeltfil, ingen støttefiler. VERIFISERT lest i sin helhet.

### Mønsteret, i seks deler

1. **Trigger-liste framfor semantikk.** `description` i frontmatter lister ~40 konkrete domeneord («strategy», «gate», «regime», «ORB», «Karri», «XAUUSD», S1/S2/S3/S4, «foundation gate», «daily trade cap»…), inkludert operatørens *egne* idiolekt-ord («katastrofedag», «impuls/pause/fortsettelse», «post-impulse blind»). Skillen fyrer på vokabular, ikke på gjetning.
2. **Eksplisitt negativ trigger.** «Skip the skill only when the question is purely about code mechanics (TypeScript, deploy, env vars) with no strategy/risk content.» Hindrer at skillen fyrer på alt.
3. **Navngitte feilmodi.** Skillen sier rett ut hva den forhindrer: (a) å dikte svar fra treningsdata når kuratert materiale finnes, og (b) å over-hente dusinvis av notater når et målrettet tag-søk holder. Begge er reelle, målbare feil.
4. **Fem-trinns ruting, i rekkefølge:** INDEX først (map-of-content, scope til én av fire seksjoner; for tverrgående spørsmål brukes `## Topic pivot`-seksjonen) → tag-filtrert søk via Obsidian MCP (`tag:lesson trend pause`), **maks 5 treff** → les **1-2** mest relevante, aldri 5+ → **avstem mot live tilstand** (`docs/ops/phase-status.md` + `docs/ref/feature-flags.md`) → svar med sitering av notat-stien.
5. **Eksplisitt fallback.** Hvis biblioteket er tomt på temaet: *si det høyt*, ikke fabriker; fall tilbake på kode som grunnsannhet; **foreslå** et nytt bibliotek-innslag med anbefalt mappe — men skriv aldri selv inn i `_library/` uten operatørbekreftelse.
6. **Innebygd re-evalueringsutløser.** «Når `lessons/` passerer ~30 innslag, ta opp med operatøren om vi skal migrere til vektorlager (pgvector/Chroma).» Skillen vet når den selv er utvokst og peker på den forhåndsskrevne analysen.

Pluss en eksplisitt **anti-mønster-liste**: ikke les hele `_library/`; ikke svar fra treningsdata; ikke siter bibliotek-innhold som live oppførsel; ikke auto-skriv nye innslag; ikke glem reviewer-konteksten.

### Det tilhørende arkitekturnotatet

`~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/08_rag_architecture.md` (7,1 kB) — forarbeidet som *begrunner* skillen, og det mest direkte overførbare enkeltdokumentet i hele inventaret.

Tesen: **«Don't build a vector store. Build a curated index folder + skill files + a tagging discipline. 80 % av verdien til 5 % av vedlikeholdskostnaden.»** Argumentet er at gjenfinning har tre feilmodi — *discovery* (Claude vet ikke at notatet finnes), *cost* (leser 30 notater for ett avsnitt), *recall under fuzziness* (spør om «trend-pause», notatet heter «regime stickiness») — og **vektorsøk hjelper bare på den tredje**. De to første løses med indekser og konvensjoner. Hybrid (Obsidian for mennesket, vektorlager for Claude) avvises eksplisitt som *verste* alternativ fordi drift mellom de to er stille: vault redigeres → embeddings blir foreldet → Claude returnerer selvsikkert feil chunks. Terskelen settes til ~5 000 dokumenter.

Den høyest rangerte teknikken er **«memory-as-curriculum»**: etter å ha lest en bok/transkripsjon, skriv en destillert leksjon på 200-500 ord. «Det tvinger DEG til å internalisere og Claude til å lese 500 ord i stedet for 50 000.» Notatet advarer samtidig eksplisitt mot «automated YT transcript ingestion that dumps raw transcripts into the vault — that's noise, not knowledge».

**Ærlig observasjon:** nettopp det advarselen beskriver er det som faktisk skjedde (§1.3 — 97 råtranskripter, 97 placeholder-notater, 0 leksjoner). Bygg Veldora rundt rådet, ikke rundt utfallet.

### Portering til en `anbud-knowledge`-skill

Direkte kartlegging:

| trading-knowledge | anbud-knowledge |
|---|---|
| Triggere: ORB, regime, gate, XAUUSD | anbud, kravspek, tildelingskriterier, kvalifikasjonskrav, KOFA, LOA/FOA, Doffin/TED, bid/no-bid, referanseprosjekt, forbehold, avvisning |
| `concepts/` | Juridiske begreper: tildelingskriterier, forbehold, vesentlig avvik |
| `strategies/` | Vinnende anbudsarketyper per oppdragsgivertype |
| `lessons/` | **Postmortem per tapt/vunnet anbud** — det høyest verdifulle, og nøyaktig det Nexus aldri fylte |
| `sources/` | Lovtekst, KOFA-avgjørelser, DFØ-veiledere |
| «Avstem mot `phase-status.md`» | Avstem mot Solar Consultings faktiske kapasitet/sertifiseringer akkurat nå |
| Karri (strategi-reviewer) | Menneskelig anbudsansvarlig som godkjennende instans |
| «~30 leksjoner → vurder vektorlager» | Samme terskel, samme forhåndsskrevne analyse |

**Advarsel fra Nexus-erfaringen:** `lessons/` forble tom i 17 måneder fordi destillering var manuelt og aldri ble planlagt inn. For Veldora er leksjonsmappen ikke valgfri — det er der «hva vinner anbud for oss»-kunnskapen bor. Behandle «skriv postmortem» som en obligatorisk del av anbudsavslutning, ikke som opprydding.

---

## 4. Strategi- og beslutningsartefakter

Alle stier under `/home/nithu/code/ai-assistent/apps/worker/src/firm/`. VERIFISERT av inventar-agent ved lesing.

### 4.1 Gate-systemet

- **`gates/new-gates.ts`** (294 l, 2026-06-15) — det reelle gate-registeret. 5 navngitte porter (`risk_level`, `scalp_overlap_asia`, `ranging_conviction`, `entry_stack_cooldown`, `session_block`) evaluert i `evaluateNewGates()`, hver med resultatformen `{name, wouldReject, hardRejected, reason, context}`.
  **Soft-log-først-filosofien er hovedpoenget:** hver port skriver til tabellen `gate_decisions` *uansett* om env-flagget er på — den blokkerer bare når sitt eget `_ENABLED` er satt. Du samler altså bevis på hva porten *ville* gjort før du lar den gjøre det. `anyHardRejected` er en OR over uavhengige sjekker, ikke en sekvensiell veto-kjede. Kalles live fra `strategy-blade.ts:374`.
  *Begrensning:* ikke et generisk plugin-register — hver port er en hardkodet blokk i én funksjon. Mønsteret er portabelt, implementasjonen må skrives om.
- **`gate-impact.ts`** (158 l, 2026-04-22) — **kontrafaktisk analyse.** Joiner soft-loggede gate-beslutninger mot faktiske utfall og svarer «ville aktivering av denne porten spart eller kostet penger». Direkte oversettbart til «ville dette no-bid-filteret fjernet anbud vi faktisk vant?» — altså måling av falske negativer før du slår på filteret.
- **`foundation-gate.ts`** (283 l, 2026-04-22, har test) — `computeFoundationStatus()` aggregerer warnings/drift/gate-rollups/minnehelse til RED/YELLOW/GREEN med forklaringsspor `reasons[]: {severity, rule, detail}`. Ikke en per-handel-port, men en **meta-port på «er det trygt å endre oppførsel nå».**
- `gates/{regime-direction,sl-cooldown,daily-trade-cap,min-rr,mean-revert,cross-strategy-direction-flip}-gate.ts` — én fil per port, alle med `.test.ts`-søsken, 2026-06-07 til 2026-06-15.

### 4.2 Scoring og conviction

- **`conviction/`** (`types.ts` 118 l, `scoring.ts` 154 l, `config.ts` 148 l, `adapters.ts` 352 l, `index.ts` 21 l) — **den mest portable enkeltmodulen.** `StandardEngineOutput` er en normalisert per-kilde-kontrakt: `signal` (-1..1), `confidence` (0..1), `freshness`, `regime_fit`, `source_quality`. Kilder er inndelt i sjikt (`direction`/`timing`/`confirmation`/`context`). `computeTieredConviction()` gjør vektet sum per sjikt → sjiktkomposisjon → multiplikator for sesjon/regime-tilpasning → **tre uavhengige terskelporter** (retning/timing/total) med en `block_reason`-streng. **Ren funksjon, ingen DB, ingen bivirkninger** — derfor trivielt å teste og flytte.
- **`criteria-confidence.ts`** (46 l, 2026-04-27) — generisk: liste av binære bestått/ikke-bestått-kriterier → `confidence = passed/total`, formaterer «4/5 (80 %)». Gjenbrukbar **som den er** for en kvalifikasjonskrav-sjekkliste.
- **`entry-thesis.ts`** (273 l, 2026-06-12) — 0-100 vektet scorer med begrunnelsesstrenger `whyNow`/`whyNotWait`. Mekanismen (vektede delscorer + straffeledd → klem til 0-100 + genererte begrunnelser) er portabel; innholdet (ATR, RSI, sesjonsvinduer) er ikke.

### 4.3 Regimedeteksjon

- **`regimes.ts`** (131 l, 2026-05-11) — kanonisk enum-modul som skiller `MarketRegime` (hva markedet gjør) fra `RiskRegime` (hvor farlig det er), eksplisitt dokumentert som «the #1 source of gate-wiring bugs» når de blandes. Lærdommen for Veldora: skill «hva slags anbud er dette» fra «hvor risikabelt er det for oss».
- **`regime-direction.ts`** (180 l, 2026-05-11) — klassifiserer UP/DOWN fra H4-candles via to valgbare metoder (`close_move` vs `ema_slope`) og returnerer et **tagget resultat** `{direction, reason}` med **11 distinkte reason-koder**, slik at hvert null-tilfelle kan skilles nedstrøms. Notatverdig fordi en tidligere versjon kollapset alle null-tilfeller og etterlot **97,7 % uforklart**. Samme disiplin trengs for «hvorfor klarte vi ikke å klassifisere dette anbudet».

### 4.4 Kalibrering

**`calibration.ts`** (388 l, 2026-06-05, har test, kjører hver syklus via `orchestrator.ts:880`) — **ikke** sannsynlighetskalibrering, men **terskel-/vekt-autotuning fra utfallsdata.** Fire moduser: `OFF` / `RECOMMEND_ONLY` / `SAFE_AUTO_APPLY` / `SHADOW_COMPARE`. Leser postmortems + avdelingenes treffsikkerhet per sesjonsvindu, foreslår **avgrensede** parameterendringer (`clampDelta` håndhever per-parameter min/max/maxDelta), logger hver anbefaling til `calibration_log`, og auto-anvender kun i `SAFE_AUTO_APPLY` bak en eksplisitt operatørbeslutning. Separat kalibreres per-motor ytelsesmultiplikatorer i `engine-attribution/calibrate-weights.ts` med vakthold på utvalgsstørrelse (≥30) og avvik (±20 %).

Fire-modus-trappa (anbefal → skygge-sammenlign → trygt auto-anvend med klemte deltaer) er et godt mønster for å la et anbudsscoring-system justere sine egne vekter uten å drifte fritt.

### 4.5 Beslutningssyklus og blackboard — en ekte multi-agent-arkitektur

- **`blackboard.ts`** (244 l, 2026-05-07) — `Blackboard`-klasse over Postgres (tabell `blackboard`), typet `MessageType`-enum (`FACT|INTERPRETATION|PROPOSAL|CHALLENGE|SYNTHESIS|DECISION|…`), tråd-ID-er, utløp, prioritetsordnet lesing, `readChallenges(proposalId)`, resolusjonssporing.
- **`fact-agents.ts`** (363 l, 2026-06-10) — «fakta, ingen tolkning»-agenter (prisfeed, tekniske indikatorer, sesjon, nyheter, makrokalender) som publiserer til blackboard-emner. `runAllFactAgents()` live i `orchestrator.ts:446`.
- **`analysis-agents.ts`** (604 l, 2026-06-13) — tolker fakta til retningsscore. Live i `orchestrator.ts:675`.
- **`challenge-agents.ts`** (254 l, 2026-06-12) — **tre adversarielle agenter** (`no_trade`, `bear_case`, `timing`) som aktivt argumenterer *mot* forslaget, hver med en `strength`-score og `evidenceAgainst[]`, publisert tilbake til blackboardet knyttet til forslags-ID-en. Kill-switch `CHALLENGE_AGENTS_ENABLED`.
- **`decision-cycle.ts`** (372 l, 2026-04-23, **ingen test**) — `checkDecisionGates()` med 10 porter (retningsklarhet, tesekvalitet, bevisstyrke, ferskhet, uløste innvendinger, manglende input, risiko-veto, porteføljeblokk, sesjonskvalitet, motsigelsesscore) + `assessThesisQuality()` som gjør **ferskhetsdempet, kildekvalitetsvektet, regime-tilpasningsdiskontert** bevisaggregering til 0-100, med en modningstilstandsmaskin: `immature → developing → mature_for_challenge → mature_for_decision`.
- `orchestrator.ts` (1229 l, 2026-06-26, har test) — live syklusdriver fra `apps/worker/src/index.ts`.

**For Veldora:** fact → analysis → challenge er arkitekturen et anbudssystem trenger. Fakta-agenter ekstraherer kravspek-fakta; analyse-agenter scorer kapabilitetstreff; **challenge-agenter argumenterer aktivt for hvorfor vi taper dette** — en innebygd motvekt mot optimismeskjevhet i bid/no-bid. Modningstilstandsmaskinen oversettes rett til «har vi utredet dette anbudet nok til å forplikte oss».

*Risiko (INFERRED):* `decision-cycle.ts`, `blackboard.ts` og de tre `*-agents.ts` er live-wired men mangler egne testfiler. `orchestrator.test.ts` kan dekke dem indirekte — ikke verifisert.

### 4.6 Risikodimensjonering

- **`exposure/rules.ts`** (121 l, 2026-04-15) — alle magiske tall sentralisert og env-overstyrbare (maks risiko/handel %, maks total %, maks retnings-%, maks åpne handler), med **regime-multiplikatorer** (`TRENDING 1.0` → `HIGH_VOLATILITY 0.6`) og **utførelsesmodus-multiplikatorer** (`live 1.0`, `shadow_only 0.0`) komponert multiplikativt i `computeEffectiveMaxRiskPct()`. Ren mekanisme: conviction/regime → multiplikatorkjede → avgrenset ressursallokering. Veldora-analogen: hvor mange timer/hvor stort bud-team forplikter vi.
- `exposure/portfolio-check.ts` (310 l) — porteføljenivå-port, live i `strategy-blade.ts:409`.
- `exposure/drawdown.ts` (91 l, har test) — rullerende/daglig drawdown mot terskel.
- `daily-loss-cap/index.ts` (77 l, 2026-06-24, norske kommentarer) — enkel kretsbryter: kumulativ daglig PnL under −$X stopper alt. **Fail-open ved DB-feil**, default OFF. Direkte analog: «slutt å foreslå flere anbud når kapasitetsbudsjettet er brukt opp».

### 4.7 Drift og ferskhet

- `drift-monitor.ts` (231 l, 2026-06-03, har test) — **report-only** avstemming megler-mot-DB (count/orphan/ghost/SL-drift/size-drift), per-instrument-toleranser, **handler aldri automatisk**. (Samsvarer med operatørens globale «no auto-disable»-regel.)
- **`data-freshness.ts`** (407 l, 2026-06-24, har test, live) — generisk per-kilde kadensovervåker med verdiktene FRESH/STALE/DEAD/EMPTY og env-justerbare terskler. `buildSourceSpecs()` og `classifyFreshness()` er **rene og direkte gjenbrukbare** for «er Doffin-feeden eller CRM-en vår foreldet».
- `event-calendar-freshness.ts` (243 l, 2026-06-13) — samme mønster på en kalendertabell, med **dobbelt signal**: inntaks-foreldelse *og* framoverdekningsgap. Mal for «lever anbudsfrist-feeden, og dekker den langt nok fram».

---

## 5. ML- og evalueringsverktøy

### 5.1 Meta-label-kittet — det sterkeste ML-aktivumet

Ekte, liten, avhengighetsfri ML — ikke bare regler. Siste berøring 2026-06-13 til 2026-07-21, live via API-ruten `apps/api/src/routes/meta-label.ts` (`/meta-label/eval`).

| Fil | Linjer | Mekanisme |
|---|---|---|
| `packages/shared/src/meta-label/logistic.ts` | 301 | Håndskrevet **L2-regularisert logistisk regresjon + Platt-skalering**. Bevisst uten trær/boosting, etter López de Prados «n/10 parametre»-disiplin for ~150 observasjoner. |
| `packages/shared/src/meta-label/purged-cv.ts` | 207 | **Purged + embargoed k-fold CV** — ingen lekkasje mellom tren/test over overlappende holdeperioder. Dette er overtilpasningsvernet. |
| `packages/shared/src/meta-label/eval.ts` | 284 | **Brier score, log-loss, reliability-/kalibreringskurver, ECE, Brier skill score** med verdikt `signal`/`weak`/`none`. |
| `apps/worker/src/firm/meta-label/triple-barrier.ts` | 395 | Triple-barrier-merking (López de Prado). |
| `apps/worker/src/firm/meta-label/features.ts` | 343 | Feature-engineering. |
| `apps/worker/src/firm/meta-label/train-model.ts` | 330 | Treningsløkke. |
| `apps/worker/src/firm/meta-label/scorer.ts` | 254 | Inferens/scoring. |
| + `eval-cli.ts`, `eval-refresh.ts`, `trainer-schedule.ts`, `labeler-schedule.ts` | | Planlagt re-trening og evaluering. |

Ingen sklearn/torch/Python i produksjon (eneste Python er `data/pull/_recompute.py`, urelatert).

**`feat/gpu-meta-label-training`-greinen (tipp `087ce71`, 2026-08-16) er IKKE merget til main** (verifisert med `git merge-base --is-ancestor`); `scripts/gpu/` finnes ikke på main. Den la til CUDA-XGBoost via en GPU-boks-HTTP-kontrakt, flaggstyrt AV/report-only. Commit-meldingen er ærlig: *«Honest result: brierSkill -0.17 = no predictive edge at n=129 yet.»* **Parkert eksperiment, ikke levert.** Lærdommen for Veldora er viktigere enn koden: med ~130 observasjoner fantes ingen prediktiv kant, og operatøren valgte å si det høyt framfor å skipe. Veldora vil ha *færre* historiske anbud enn 130 i starten — planlegg deretter.

### 5.2 Shadow mode

**`apps/worker/src/firm/shadow-log.ts`** (605 l, live, med `shadow-log.test.ts`) — registrerer hvert strategiforslag, **både utløste og blokkerte**, med retning/entry/SL/TP, og går gjennom ventende rader hver orkestratorsyklus og sammenligner live pris mot SL/TP for å markere win/loss/expired. Altså «hva *ville* skjedd» uten å ta risiko. Kill-switch `SHADOW_LOG_ENABLED`. Eksponert via `apps/api/src/routes/shadow.ts` og dashboard-komponenten `ShadowVsActual.tsx`.

Dette er nøyaktig kandidatscorer-mot-faktisk-utfall-mønsteret Veldora trenger: kjør en ny bid/no-bid-scorer i skygge over reelle anbud i noen måneder før den får stemmerett.

### 5.3 Backtest-skriptene — ikke gjenbrukbare

VERIFISERT: **ingen felles motor.** `scripts/lib/` inneholder bare `codex-cost.mjs` (urelatert). Hver fil gjør sin egen `pg`-spørring og håndrullet løkke; ingen delt bars/trades/equity-curve-abstraksjon, ingen delte PF-/Sharpe-/DD-hjelpere. `backtest-strategies.mjs` (865 l, 2026-04-27) har **null treff** på profitFactor/sharpe/winRate/maxDrawdown. `_fvg_backtest{2,3,4,5}.mjs` (67-145 l hver, sist 2026-06-05) er nummererte oppfølgere som erstatter hverandre og aldri ble refaktorert. **Kast, ikke port.** Sweep-filene (`*-sweep.mjs`, `*-tunings.mjs`, 259-446 l) følger samme engangsmønster (INFERRED fra størrelse og navn, ikke dyplest).

### 5.4 Eksperimentsporing

Uformell. `data/pull/*.json` (~50 filer: `calibration.json`, `strategies.json`, `shadow_comparison.json`, `shadow_per_strategy.json`, `v_decision-funnel.json` m.fl.) er **øyeblikksbilder fra API/dashboard, ikke et versjonert kjøreregister**. `hle` («Historical Learning Engine», `packages/shared/src/hle{,-eval,-labels,-stats}.ts` + `apps/worker/src/firm/hle/`) er mer strukturert med egne eval-/profiltester — verdt et oppfølgingsblikk hvis Veldora vil ha et registermønster, men ikke verifisert som generell eksperimentsporer. `packages/shared/src/hle-stats.ts` (~linje 590) har Brier-dekomponering (reliability/resolution-splitt, med dokumentert begrunnelse for å unngå ECEs skjevhet ved lav n).

### 5.5 Testdekning

**34 testfiler / 10 840 linjer** i `apps/worker/src/firm/*.test.ts` (kalibrering, drift-monitor, foundation-gate, kill-switches, postmortem, quarantine-learning-filter, regime-direction, shadow-log, strategy-execution, vol-thresholds, write-contracts m.m.), pluss 7 i `meta-label/`. Purged-CV-korrektheten er selv enhetstestet (`meta-label.test.ts:402-485`: «every sample tested exactly once», «PURGE removes overlapping train samples», «EMBARGO drops forward band»). Dette er et modent testregime å kopiere disiplinen fra.

---

## 6. Øvrig

### 6.1 LLM-ruter — portabel

`apps/worker/src/services/llm-router.service.ts` (288 l, VERIFISERT lest i sin helhet av agent). Tre leverandører (Anthropic → OpenAI → OpenRouter) over rå `fetch`, **oppgavetypet ruting**: `LlmTaskType` = reasoning/classification/extraction/summarization/sentiment/trade-review/briefing/assistant/signal/general, hver med sin foretrukne leverandørkjede og automatisk fallback ved feil, med latens-/token-logging via `logger.service.ts`. Ingen SDK-innlåsing. Direkte brukbar for Veldoras anbudsanalyse-kall.

Beslektet: `apps/worker/src/jobs/llm-call.ts` (49 l), `apps/worker/src/firm/agent-bus/firm-agents/llm.ts` (356 l, kostnadstak + fallback, §2.4).

> Presisering: `apps/worker/src/engines/` (10 filer) er **trading-signalmotorer** (regime, teknisk, sentiment, makro-bias, markedsstruktur), ikke LLM-abstraksjon. Ikke forveksles med `@cc/engines` i command-center.

### 6.2 Varsling og daglig brief

`apps/worker/src/firm/notifications/` — 12 filer: dispatcher, detector, formatter, delivery, config, topic-freshness, loss-and-activation-monitor + tester. Flerkanals (Telegram + Discord med egne webhooks per kanal: alerts/briefing/decisions/executions), emne-gated, alvorlighetsbevisst. Pluss `apps/worker/src/services/alert.service.ts`.

`apps/worker/src/firm/briefing.ts` (139 l, 2026-05-07) + `apps/worker/src/agents/briefing.agent.ts` (131 l) + `scripts/daily-analysis.mjs` (464 l, 2026-06-20) genererer en LLM-skrevet daglig operatørbrief fra systemtilstand. **Mønsteret «LLM skriver daglig brief fra systemtilstand og sender over flere kanaler» er rett overførbart til en daglig Doffin-/anbudsdigest.**

### 6.3 Agentdefinisjoner

Ingen `.claude/agents/`, `.claude/commands/` eller `.claude/skills/` i repoet (VERIFISERT — kun `settings.json`, `settings.local.json`, `RESUME.md`, `worktrees/`). Agentene bor i kode: `apps/worker/src/agents/` — 5 filer, **ren async-funksjon, ingen rammeverk**: `supervisor.agent.ts` (137 l), `bot-manager.agent.ts` (228 l), `trading-manager.agent.ts` (345 l, nyest 2026-06-24), `briefing.agent.ts` (131 l), `cso.agent.ts` (118 l). Stilreferanse, ikke innholdsreferanse.

`.claude/settings.json` (5,5 kB, 2026-05-02) er en tillatelsesliste (npm/git/docker/railway/gh lese-operasjoner auto-tillatt; push/force/rm/sudo gated) — **gjenbrukbar som den er** i et Veldora-repo.

### 6.4 MCP

`.mcp.json` er 22 byte — tom stubb. `.mcp.json.example` wirer nøyaktig én: **`nexus-pg`**, read-only Postgres-scanner (`@modelcontextprotocol/server-postgres` via npx, mot `NEXUS_READONLY_PG_URL`). Tynt, men en ren mal for en read-only Veldora-anbudsdatabase-MCP.

### 6.5 Eksterne API-er

Anthropic / OpenAI / OpenRouter (LLM-ruter) · **Tavily** (web-søk — brukt i `firm/market-pulse.ts`, `fact-agents.ts`, `analysis-agents.ts`, `raw-data-persistence.ts`; relevant for Veldora som søkeleverandør) · **Qdrant** (vektorminne, §2.1) · OANDA (megler) · Finnhub / Polygon / FRED / News API / Trading Economics (markedsdata — irrelevant for Veldora) · Telegram + Discord (varsling) · Railway (deploy) · Postgres · Sentry / Logtail / PostHog / QStash.

### 6.6 Dokumentasjonsmønstre

| Sti | Filer | Verdi for Veldora |
|---|---|---|
| `docs/strategy/proposals/` | 86 | **Forslag-til-gjennomgang-arbeidsflyten** som operatørens globale CLAUDE.md allerede viser til for pengepåvirkende endringer. Sterk kandidat å klone for anbudsstrategi-beslutninger. |
| `docs/ops/` | 71 | Driftsrunbooks, `phase-status.md` |
| `docs/ref/` | 39 | **`feature-flags.md` (285 l, 2026-06-25)** — levende flaggregister, ren mal |
| `docs/memory/` | 13 | RAW→DISTILLED→PROMOTED→ARCHIVED-livssyklus. **Kun konvensjon, ingen kode** — `PROMOTE_QUEUE.md` har vært tom siden 2026-05-08. Metodikken er portabel, implementasjonen finnes ikke. |
| `docs/architecture/` | 10 | |
| `docs/CONTEXT-MAP.md` | 1 | Navigasjonskart |

Rot: `CLAUDE.md` (11,6 kB, 2026-06-05), `ARCHITECTURE-V3.md` (9,4 kB, 2026-05-03 — **foreldet** mot siste commit 2026-09-01), `project_state.md` (3 kB, 2026-06-23).

### 6.7 Obsidian `01-nexus/`

51 filer, 420 kB, 6 undermapper: `modules/` (10 — én brief per systemkomponent: Module-Agent-Bus, Module-Orchestrator, Module-Postmortem…), `operations/` (9 — Foundation-Gate, OK-Kjor-Gate, Operator-Principles, Strategy-Proposal-Workflow, Retention-Policy), `strategies/` (7), `runtime/`, `runtime-state/`, `session-summaries/` (1 fil, 21,9 kB).

Mest formatgjenbrukbare: **`Operator-Principles.md`** og **`Strategy-Proposal-Workflow.md`** (operatør-gate-filosofi, ikke trading-innhold).

**Ferskhet:** ingenting i `01-nexus/` er nyere enn **slutten av juni 2026** — foreldet mot repoets 2026-09-01. Les som historikk, ikke status.

---

## 7. SIKKERHETSFUNN — krever handling

`/home/nithu/code/ai-assistent/.env.example` er **sporet i git** (`git ls-files` bekrefter), mens `.gitignore` kun utelukker `.env` og `.env.local`.

Filen er 574 linjer, hvorav kun 48 er faktiske `KEY=value`-tilordninger (resten er dokumentasjonskommentarer — størrelsen i seg selv er altså uskyldig). Men ved å måle **kun verdilengder** (ingen verdier lest eller skrevet ut) har **19 nøkler verdier med reell legitimasjonslengde**, ikke plassholdere som `your_key_here`:

`API_KEY` (68) · `FRED_API_KEY` (67) · `ANTHROPIC_API_KEY` (62) · `OPENAI_API_KEY` (60) · `POSTHOG_KEY` (55) · `MARKET_DATA_API_KEY` (54) · `FINNHUB_API_KEY` (54) · `QSTASH_TOKEN` (54) · `POLYGON_API_KEY` (52) · `OPENROUTER_API_KEY` (52) · `TAVILY_API_KEY` (52) · `OANDA_API_TOKEN` (51) · `SENTRY_DSN` (51) · `LOGTAIL_SOURCE_TOKEN` (51) · `TRADING_ECONOMICS_API_KEY` (50) · `DATABASE_URL` (49) · `OANDA_API_URL` (48) · `QDRANT_URL` (48) · `NEWS_API_KEY` (44) · `TRADINGVIEW_WEBHOOK_SECRET` (39)

Tomme (0): alle `DISCORD_*`, `TELEGRAM_BOT_TOKEN`, `NOTION_API_KEY`, `QDRANT_API_KEY`, `DASHBOARD_URL`.

**Tolkning:** dette ser ut som en reell `.env` som er committet under navnet «example». **Anbefaling: roter nøklene og skrubb git-historikken før noe herfra kopieres mot Veldora.** Jeg har ikke lest eller gjengitt noen verdi — kun lengder. Dette er operatør-gated; jeg har ikke endret noe.

Relatert ryddefunn: `.claude/worktrees/` på 20 GB (≈ 25 worktrees à ~800 MB `node_modules`).

---

## 8. Hva som er dødt — ikke port dette

| Artefakt | Status |
|---|---|
| **Firehose** | «not yet deployed to prod» (`docs/CONTEXT-MAP.md:50`), alle flagg `(unset)`, ingen cron/systemd. Dormant. |
| `scripts/_fvg_backtest{,2,3,4,5}.mjs` | Nummererte engangsskript, erstatter hverandre, sist 2026-06-05. |
| `scripts/backtest-*.mjs` | Ingen delt motor, ad hoc-metrikker. Skriv om, ikke port. |
| `feat/gpu-meta-label-training` | Ikke merget. Egen commit: «brierSkill -0.17 = no predictive edge». |
| `_library/trading/lessons/` | Tom siden 2026-05-13. |
| `12-youtube/` destillering | 97 av 138 notater er mekaniske plassholdere. |
| `14-books/_queue/` | 2 bøker, aldri prosessert; `_done/` og `_failed/` tomme. |
| `embeddings.mjs` → `cosineSim()` | Kalles kun fra egen test. Embeddings skrives til JSONB og leses aldri tilbake for likhetssøk. |
| `docs/memory/PROMOTE_QUEUE.md` | Tom siden scaffolding 2026-05-08. |
| `ARCHITECTURE-V3.md` | 2026-05-03, foreldet. |
| `~/Obsidian/Brain/01-nexus/` | Ingenting nyere enn slutten av juni 2026. |
| `.claude/RESUME.md` | Foreldet øktmarkør (2026-08-19). |

---

## 9. De fem mest verdifulle overførbare aktivaene

1. **`/home/nithu/code/ai-assistent/apps/worker/src/services/memory.service.ts`** (721 l, live) — produksjonshardnet Qdrant-vektorminne med embedding-fallback, selvhelbredende søkesti, kill-switch og payload-indekser. Veldora får et ferdig gjenfinningslag over anbudsdokumenter og tidligere bud, inkludert feilhåndteringen man ellers først oppdager etter måneder i drift.

2. **`/home/nithu/code/ai-assistent/packages/shared/src/meta-label/{purged-cv,eval,logistic}.ts`** (792 l til sammen) — purged/embargoed CV + Brier/reliability + L2-logistisk med Platt-skalering, bevisst dimensjonert for små utvalg. Lar Veldora score bid/no-bid med *kalibrerte sannsynligheter* og bevise at scoren ikke er overtilpasset de få anbudene selskapet har historikk på.

3. **`/home/nithu/code/ai-assistent/apps/worker/src/firm/{fact,analysis,challenge}-agents.ts` + `blackboard.ts`** (1 465 l) — fakta → analyse → adversariell innvending over et typet blackboard. Challenge-agentene som aktivt argumenterer *mot* et forslag er den innebygde motvekten mot optimismeskjevhet som bid/no-bid-beslutninger trenger mest.

4. **`~/.claude/skills/trading-knowledge/SKILL.md` + `~/Obsidian/Brain/_library/trading/INDEX.md` + `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/08_rag_architecture.md`** — hele det kuraterte-bibliotek-mønsteret: trigger-vokabular, INDEX-først-ruting med topic-pivot, maks 2 notater, avstemming mot live tilstand, eksplisitt «si at du ikke vet», og den forhåndsskrevne begrunnelsen for å *ikke* bygge vektorlager før ~5 000 dokumenter. Klones direkte til en `anbud-knowledge`-skill.

5. **`/home/nithu/code/ai-assistent/apps/worker/src/firm/gates/new-gates.ts` + `gate-impact.ts` + `shadow-log.ts`** (1 057 l) — soft-log-først-portene (logg alltid, blokker bare når flagget er på), den kontrafaktiske «ville denne porten hjulpet»-analysen, og skyggemodus som scorer kandidater mot faktisk utfall uten å handle. Til sammen lar de Veldora innføre no-bid-filtre uten å risikere at systemet stille siler bort anbud selskapet faktisk ville vunnet.

**Hederlig omtale:** `conviction/` (793 l, ren funksjon, sjiktvektet multi-kriterie-scoring med terskelporter) er trolig den enkeltmodulen som krever minst arbeid å flytte — den ble kun holdt utenfor topp 5 fordi domenetilpasningen av sjiktene er mer omfattende enn de fem over.
