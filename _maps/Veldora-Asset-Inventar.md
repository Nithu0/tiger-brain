---
type: kanonisk-inventar
prosjekt: Veldora / Solar Consulting AS
opprettet: 2026-10-16
metode: 6 parallelle inventaragenter + manuell verifisering av to påstander
---

# Veldora — kanonisk aktivainventar

> **Les dette ved oppstart av enhver Veldora-sesjon.**
> Spørsmålet som utløste rapporten: *hva har vi allerede av verktøy, MCP-er, APIer,
> strategier, treningsdata, PDF-er og bøker på tvers av alle prosjekter som kan
> brukes til å gjøre anbudsplattformen god på vår egen bedrift?*
>
> Svaret, kort: **maskineriet finnes, innholdet mangler, og tre av premissene
> for spørsmålet var feil.** Les §0 og §1 før du foreslår noe.

**Gyldighet.** Alt under er målt 2026-10-16. Tall om `memory.db`, AUC-baseline,
matriserader og systemd-status råtner raskt — verifiser før du bygger på dem.
Epistemisk tagging følger `Veldora/CLAUDE.md` §1: FACT / ASSUMPTION / UNKNOWN.

**Dype delrapporter** (full detalj, filstier, kommandoer):
`~/Obsidian/Brain/00-claude-inbox/veldora/2026-10-16-inventar/`

| Fil | Dekker |
|---|---|
| `inv-01-gull.md` (385 l) | `ai-assistent` / Nexus — korpus, vektorminne, meta-label-kalibrering, gates, firm-agenter |
| `inv-02-brain.md` (554 l) | Obsidian Brain — korpus målt, memory.db målt, ingestion-pipelines, skill-registry |
| `inv-03-thesis.md` (180 l) | Master-oppgave, research-os, thesis-evaluator — ML-metodikk som porterer |
| `inv-04-veldora.md` (888 l) | Veldora selv — produktet, CRM-motoren, bedriftskunnskapsgapet, alle lanes |
| `inv-05-tools.md` (291 l) | Verktøy/MCP/API/skills/daemoner + dokumentparsing-kapasitet |
| `inv-06-adjacent.md` (630 l) | Resten av `code/` — refi-doc-agent, CRM, leadgen, AS, CV-er |
| `vedlegg-alle-pdfer-paa-maskinen.txt` | Rå liste over alle 437 PDF-er funnet i hjemmekatalogen |

---

Delrapporter: `/tmp/claude-1000/-home-nithu-code-command-center/2d555854-c731-4516-9070-e0fcff3433eb/scratchpad/inv-0{1..6}-*.md`

## 0. Sammendrag i én setning

Maskineriet for å kjenne bedriften er bygget, testet og i produksjon; beholderen er
nesten tom; og vinnmodellen måler på sjansenivå fordi den aldri har sett et utfall.
Flaskehalsen er **bedriftsfakta og utfallsdata**, ikke modeller, RAG eller verktøy.

## 1. Tre premisser som ikke holdt

**P1 — "gull-prosjektet er matet med mange PDF-er om algoritmetrading og ML".**
FALSK. `ai-assistent` har nøyaktig 2 PDF-er, begge kopier av batterimasterens manuskript.
De 21 GB er 20 GB duplisert `node_modules` over ~25 worktrees. Hjemmekatalogen har
437 PDF-er / 527 MB, men 356 MB er batteripapers og resten er jobbsøknader og regnskap.

**P2 — "vi har et bokkorpus i Brain".** NESTEN FALSK. `14-books/` er 27 MB og
inneholder to bøker, begge uprosessert siden juni: Carver, *Advanced Futures Trading
Strategies*; Halls-Moore, *Successful Algorithmic Trading*. `_library/books/` og
`_library/raw/` er tomme. `_queue/_done` og `_queue/_failed` er tomme.

**P3 — "CRM-en har bedriftshistorikken vår".** FALSK for `aslisten-crm`: søk på både
"solar consulting" og orgnr 931949837 gir null treff. Det er et annet kundeprosjekt
med 143 KB dev-data.

Det reelle kunnskapskorpuset er **97 YouTube-transkripsjoner** (~471k ord, ~211k
tradingrelevant). MEN: 97 av 138 destillerte notater er mekaniske plassholdere som
sier "pending LLM distillation" — råteksten finnes, destilleringen kjørte aldri.
Det kuraterte biblioteket er 18 notater / ~17k ord, av høy kvalitet.

**Konsekvens:** verdien fra de gamle prosjektene ligger i *kode og mekanismer*,
ikke i dokumenter. Det endrer hva "trene på" kan bety her.

## 2. Hva Veldora faktisk er i dag

| Påstand | Status |
|---|---|
| `bid-engine/` er motoren | FALSK — 5-fils dokumentskall |
| Ekte motor | `projects/anbud/crm` — Payload 3 + Next 15 + Postgres 18 på Railway, live siden 2026-09-30, ~58 agentoppgaver, godt testet |
| Fit-scoring | `lib/scoring/fit.ts` reell; vinnmodell `wp-2` i `config/model.ts`, hver vekt merket `ASSUMPTION — tune` |
| Doffin-inntak | LIVE (`DOFFIN_API_KEY` finnes) |
| Retrieval | Kun leksikalsk: idf-vektet token-overlapp (`lib/bank.ts`) + Postgres fulltekst. `embeddingProvider()` returnerer hardkodet null, pgvector ikke i prod, `issues/019` åpen |
| To systemd-vakter | `anbud-vakt` + `anbud-modell-vakt`, 24/7, report-only til firm-bus |

**Produksjonsbaseline 2026-10-13, n=30 beslutninger:**
fitScore AUC **0,577** · priorityScore **0,549** · winProbability **0,575**.
Alt innenfor støy. Eneste signalbærer: `scope_score` 0,678.

To konkrete feil som er billige å rette:
- **59 kalibreringsetiketter finnes som ingen kode leser.**
- **13 *besluttede* muligheter har ingen brief**, fordi `queueWhere` krever `UNDECIDED`.
  Anbudene dere sa ja til er de eneste uten bakgrunnsdata. Det er omvendt av det man vil.

## 3. Bedriftskunnskapen — selve gapet

Finnes i git, komplett:
- Orgnr 931 949 837; fire signatarer (`crm/src/lib/tilbud/signatories.ts`)
- Tre samtykkede bios (`website/content/team.ts`)
- `website/content/solarconsulting-inventory.md` — 310 linjer skrapet fra gammelt
  nettsted 2026-09-24. Rikeste bedriftsfil som finnes. Fire tjenester i full prosa,
  fire verdier, **fem kundesitater**: El 24 Ensiko, Norway Solar, Suncel, Sastech,
  **Sauda kommune** (eneste offentlige referanse — teknisk spesifikasjon og
  tilbudsevaluering for kommunale solcelleanlegg)

Mangler:
- **Ingen prosjektliste.** Operatør svarte "ingen prosjektliste" 24.09. De fem
  sitatene har verken år, verdi eller omfang — nøyaktig de tre tingene FOA § 16-6 ber om.
  `reference-cases.template.yaml` har null oppføringer; målkatalogen `sales/cases/` finnes ikke.
- **Ingen CV-er.** `crm/kompetanse-mappe.example/` peker på `~/Solar-Consulting-kompetanse/`
  utenfor git. **Den katalogen finnes ikke på maskinen.** Importøren
  (`npm run import:kompetanse`) er ekte, idempotent og samtykkebevisst — og har aldri hatt input.
- **Null sertifiseringer** (inventory §7). Veikart finnes i
  `research/energikartlegging/data/sertifiseringer.json`.
- **Ingen prising.** Hvert bedriftsspesifikt felt i `bid-engine/pricing/prismodell.json`
  er `UNKNOWN`/`TODO` — lønn, fakturerbare timer, fortjeneste, forsikring.
  Selskapet kan ikke regne ut sin egen timekost.
- **Ingen vinn/tap-historikk.** `FACT` B1: ingen på teamet har noensinne levert et offentlig anbud.
- `qualification-matrix.yaml`: 69 rader — **5 GRØNN**, 21 RØD, 23 GUL. ADR-0015 byttet
  tilbyder til Solarconsulting AS 03.10, men rørte bare noen få rader; de fleste
  `gap:`-tekstene beskriver fortsatt Veldora-som-startup.

**Dette er det `/grill-me` skal fylle.** Ikke en generell bli-kjent-samtale: en målrettet
utfylling av 44 GUL+RØD-rader i kvalifikasjonsmatrisen, fem referansecaser med år/verdi/
omfang, og prismodellens fire UNKNOWN-felt.

## 4. Eksterne kilder som finnes i huset

`Søking fulltid/profil/` — V1–V5 CV-er i DOCX (V5 oppdatert 03.10), tre PDF-CV-er,
fem arbeidsattester, fire karakterutskrifter, `profile.md` og `keywords.md` som
strukturert kompetansedata. Dette er personellbeviset som gjør UNKNOWN-rader besvarbare.
Kompetansekrav til nøkkelpersonell er standard i norske anbud.

`AS/IT/analyse-medieovervakning-anbud.md` — ekte fylkeskommune-kravspek brutt ned i
A-krav A1–A15 og vektede E-krav med ærlig kan-vi-vinne-dom. Beste gullstandard-testcase
i workspacet. (`AS/` er ellers Kukaraja Sikkerhet ENK, ikke Solar Consulting.)

`Veldora/Generell_kravspesifikasjon_-_Solcelleanlegg_kommunale_boliger_Sauda_kommune.pdf`
— ekte kravspek, allerede røyktestet: ren tekstekstraksjon, æøå intakt, ingen OCR nødvendig.

## 5. Mekanismer verdt å portere (rangert)

1. `ai-assistent/packages/shared/src/meta-label/{purged-cv,eval,logistic}.ts` (792 l) —
   purged/embargoed kryssvalidering + Brier/reliability + Platt-skalert logistisk regresjon,
   dimensjonert for små utvalg. Dette er kalibreringsmaskineriet som trengs for å kunne
   si "73 % vinnsannsynlighet" uten å lyve. Masteroppgaven har konformal prediksjon med
   verifisert dekning, men ingenting for klassifisering.
2. `Master-oppgave/battery-electrolyte-predictor/src/splitting.py` (231 l) — tre
   splittefunksjoner som kaster `RuntimeError` på gruppeoverlapp. Bytt DOI → oppdragsgiver/
   anbudsfamilie. Følger med en casestudie: samme data ga R²=0,971 tilfeldig splittet og
   R²=0,144 gruppert. Veldora reproduserer den illusjonen hvis anbudsvarsler splittes
   tilfeldig med oppdragsgiver/CPV som features.
3. `thesis-evaluator/src/teval/verify/claims.py` (439 l) — påstand → finn belegg i PDF →
   LLM dømmer. pdfplumber med bbox → glidende vindu → MiniLM top-5 → rapidfuzz → kort
   passasje til Claude, svar med sitat + sidetall + bbox, `no_evidence` når belegg mangler.
   Nærmeste eksisterende match til sporbar kravuttrekking fra norske anbudsdokumenter.
   (NB: repoet er ikke et git-repo. ARCHITECTURE.md kaller verify/grade "planned" mens
   koden faktisk kjører — ekte kjøring i `.validate.log`.)
4. `ai-assistent/apps/worker/src/firm/gates/{new-gates,gate-impact,shadow-log}.ts` (1057 l) —
   gates som alltid logger og blokkerer bare når flagget, kontrafaktisk "ville denne gaten
   hjulpet", skyggescoring mot faktiske utfall. Lar en legge på no-bid-filtre uten å
   stille screene bort vinnbare anbud. Direkte relevant gitt AUC 0,577.
5. `ai-assistent/apps/worker/src/firm/{fact,analysis,challenge}-agents.ts` + `blackboard.ts`
   (1465 l) — fakta → analyse → adversarisk utfordring over typet blackboard.
   Challenge-agentene som argumenterer *mot* et forslag er motvekten bid/no-bid trenger.
6. `refi-doc-agent/app/services/extraction.py` + `ingest.py` — norsk beløpsregex som
   håndterer NBSP/smal-NBSP, dokumenttype-skopede regler, `field_status_for_sak()` som
   rapporterer hva som *ikke* lot seg parse. Kaskade pypdf → pdfplumber → Tesseract `nor+eng`.
7. `aslisten-crm/src/lib/brreg.ts` — Brønnøysund: tvangsavvikling, fratrådte/avdøde roller,
   regnskapstall, MOD11-orgnr-validering.
8. `call-center-ai-demo/app/routers/eval.py` + `redaction.py` — gullmerket nøyaktighetsharness
   og deterministisk norsk PII-maskering som returnerer funn uten å inneholde PII-en.
9. `~/.claude/skills/trading-knowledge/SKILL.md` + `_library/trading/INDEX.md` — hele det
   kuraterte rutingmønsteret, klonbart til en `anbud-knowledge`-skill. Inkluderer et
   ferdigskrevet argument for å IKKE bygge vektorlager under ~5 000 dokumenter.

## 6. Infrastruktur: hva som er oppe, nede og mangler

**Oppe:** 23 systemd user-services, null feilet. cc-api `:3100` (db/firmBus/brain/workspace ok),
cockpit `:3200`, omnigent `:6767`, Ollama `:11434` med bge-m3. Åtte headless firm-executors,
verdict-watch, hermes-gateway, litestream (kun lokale replikaer), selvhostet GH Actions-runner.

**Brain-motoren, målt:** `memory.db` på `~/.claude/projects/-home-nithu-code/state/` (296 MB
+ 92 MB WAL — ikke der CLAUDE.md antyder). 16 072 verbatim / 16 008 destillert / 16 008
embeddet = 100 %, bge-m3 dim 1024, FTS5 og vec0 enige, null åpne dødbrev. CLAUDE.md sier
«~13,4k» — utdatert lavt. Full capture→distill→embed-loop lukket 06:28 i dag.
`getDb(path)` tar sti som parameter → Veldora kan åpne sin egen DB og dele kun Ollama
over loopback. ADR-001-rent.

**Nede / ødelagt:**
- `fetch`, `filesystem`, `playwright` MCP: ikke ødelagt, bare trege. Kaldstart via
  `uvx`/`npx -y`/`@latest` over nett, forverret av åtte samtidige panestarter.
  Fiks: forhåndsinstaller og pin bort `-y`/`@latest`.
- `fetch-docker`: laster 10 123 servere fra to fjernkataloger, tomme lokale kataloger.
  Redundant — anbefaler fjerning.
- `obsidian` MCP: eneste ekte nedetid — Obsidian-appen kjører ikke, og REST-plugin-en
  bor i appen. API-nøkkelen ligger i klartekst i `~/.claude.json`.
- `ollama-keepwarm.service` lå nede → `rag-recall` falt tilbake til ren BM25 på kaldt kall.

**Mangler, operatør-gatet (apt/pip):**
- `tesseract-ocr-nor` — tesseract har kun `eng` + `osd`. Skannede anbud går gjennom
  engelsk modell i dag. `refi-doc-agent` kaller allerede `nor+eng` og feiler derfor.
- `pdfplumber` — anbuds-PDF-ene er `Tagged: no`, så tabellstruktur må utledes.
- `pymupdf`, `pandoc`.

**Ingestionen kan ikke ta PDF-er i dag:** `book-ingest` avviser alt som ikke er epub/txt,
er gatet av (`BOOK_INGEST_ENABLED` ikke satt i kjørende daemon), står ikke i watcherens
køkataloger, og hard-feiler enhver output som deler >10 sammenhengende ord med kilden.
Den copyright-vakten er stikk motsatt av hva en kravspesifikasjon trenger, der ordrett
sitat er hele poenget. `obsidian-ingest` har kjørt én gang (19.06), indekserte 86 av
2 093 filer (4,1 %); 98,3 % av indeksen er operatørens egen sesjonshistorikk.

## 7. Korrigerte påstander underveis (for sporbarhet)

- `.env.example` i ai-assistent ble rapportert å inneholde 19–23 ekte nøkler. Verifisert
  falskt: 22 av 23 "lange verdier" er linjer med inline-kommentar. Null treff på
  `sk-ant-`, `sk-proj-`, `sk-or-v1-`, `tvly-`, `phc_`, Sentry-DSN eller OANDA-kontoformat.
  `DATABASE_URL` er `postgresql://<bruker>:<ordbokord>@localhost:5432/agentdb`. **Ingen rotering nødvendig.**
- `SC-rename` ble rapportert å ligge foran main med anbudskorpuset. Verifisert falskt:
  123 commits *bak* main, procurement-filene byte-identiske.
- "Anbudsinntak er greenfield" — falskt, `DOFFIN_API_KEY` finnes og inntaket er live.
- `Veldora-frist`s `legal-engine-map`-branch er identisk med main; arbeidet gikk til Brain.
- `research-os` er dødt: siste commit 03.06, 39 papers i DB men `sections=0`, `extracted_facts=0`.
- Masteroppgavens `chapters/Methodology.tex:255` påstår hyperparametersøk; null treff på
  GridSearch/Optuna/skopt i noe repo.
- `packages/shared/src/projects.ts` i command-center lister ikke Veldora.

## 8. Operatør-gatede beslutninger (ingen av disse er utført)

| # | Beslutning | Konsekvens av å utsette |
|---|---|---|
| G1 | `sudo apt install tesseract-ocr-nor` | Skannede anbud OCR-es med engelsk modell. `refi-doc-agent` kaller allerede `nor+eng` og feiler derfor i dag |
| G2 | `pip install pdfplumber pymupdf` + `apt install pandoc` | Anbuds-PDF-ene er `Tagged: no`; tabellstruktur kan ikke utledes uten pdfplumber. Kravtabeller er der kravene bor |
| G3 | Fjern `fetch-docker`-MCP fra config | Den laster 10 123 servere fra to fjernkataloger ved hver oppstart. `fetch` dekker behovet |
| G4 | Pin `fetch`/`filesystem`/`playwright` bort fra `-y`/`@latest`, forhåndsinstaller | De tre timer ut ved kaldstart når åtte paner starter samtidig. Ikke ødelagte — trege |
| G5 | Start Obsidian-appen (REST-plugin bor i appen) | `obsidian`-MCP er eneste ekte nedetid |
| G6 | Flytt Obsidian-MCP-ens API-nøkkel ut av klartekst i `~/.claude.json` | Sikkerhet |
| G7 | Opprett `~/Solar-Consulting-kompetanse/` med ekte CV-er | `npm run import:kompetanse` er ekte, idempotent, samtykkebevisst — og har aldri hatt input |
| G8 | Start `ollama-keepwarm.service` | Uten den faller `rag-recall` til ren BM25 på kaldt kall (4 s timeout) |

## 9. Hva neste prompt bør be om — tre spor, ikke ett

"Tren plattformen på bedriften" dekker tre ulike jobber. Hold dem adskilt.

**Spor A — fyll beholderen (gir mest, raskest).**
Ikke en generell bli-kjent-samtale. Målrettet utfylling av:
- 44 GUL+RØD-rader i `qualification-matrix.yaml` (69 totalt, 5 GRØNN i dag)
- Fem referansecaser med år, verdi og omfang → `sales/cases/` (katalogen må opprettes;
  `reference-cases.template.yaml` har null oppføringer)
- Fire UNKNOWN-felt i `bid-engine/pricing/prismodell.json`: lønn, fakturerbare timer,
  fortjeneste, forsikring. Uten dem kan selskapet ikke regne ut egen timekost.

Tre kilder finnes allerede i huset og bør leses FØR operatøren grilles, så spørsmålene
blir til bekreftelser i stedet for utfylling fra null:
1. `Veldora/website/content/solarconsulting-inventory.md` — 310 linjer, rikeste
   bedriftsfil. Fire tjenester i full prosa, fire verdier, fem kundesitater.
2. `Søking fulltid/profil/` — V1–V5 CV-er (DOCX, V5 oppdatert 2026-10-03), tre PDF-CV-er,
   fem arbeidsattester, fire karakterutskrifter, `profile.md`, `keywords.md`.
3. Sauda kommune — eneste offentlige referanse, og kravspeken ligger i repoet som PDF.

Verktøy: `/grill-me`-skillet. ASSUMPTION: 44 rader er for mange for én økt; del opp.

**Spor B — gjør retrieval ekte.**
`embeddingProvider()` returnerer hardkodet null; pgvector er ikke i prod; `issues/019` åpen.
Brain-motoren er målt 100 % embeddet over 16 008 objekter, og `getDb(path)` tar stien som
parameter — Veldora kan åpne sin egen DB og dele bare Ollama over loopback. ADR-001-rent
(HTTP + fil, ingen delt DB, ingen delte importer). Ikke npm-link inn i command-center.
Motargument som bør vurderes først: `00-claude-inbox/nexus/2026-05-13/08_rag_architecture.md`
har et ferdigskrevet argument for å IKKE bygge vektorlager under ~5 000 dokumenter.

**Spor C — kalibrering og gates før modeller.**
En trent vinnmodell er ikke på bordet i år: `FACT B1` sier ingen på teamet har levert et
offentlig anbud, så det finnes ingen vinn/tap-historikk. Det som derimot kan gjøres nå:
- Les de 59 kalibreringsetikettene som ingen kode leser i dag
- Fiks `queueWhere`-feilen: 13 besluttede muligheter mangler brief fordi filteret krever
  `UNDECIDED`. Anbudene dere sa ja til er de eneste uten bakgrunnsdata
- Porter `meta-label/{purged-cv,eval,logistic}.ts` (Brier, reliability, Platt-skalering)
- Porter `splitting.py`s gruppesplitt med `RuntimeError` på overlapp
- Porter shadow-log-mønsteret: gates som alltid logger og blokkerer bare når flagget

## 10. Faresignal å ha i bakhodet

Masteroppgavens casestudie: samme datasett ga **R² = 0,971** med tilfeldig 80/20-splitt og
**R² = 0,144** med gruppert splitt. Årsaken var at måletemperatur som feature plasserte
samme forbindelse på begge sider av splitten.

Veldora vil reprodusere nøyaktig den illusjonen hvis anbudsvarsler splittes tilfeldig
med oppdragsgiver eller CPV-kode som features. Flere varsler fra samme oppdragsgiver er
ikke uavhengige observasjoner. Gruppér på oppdragsgiver/anbudsfamilie, eller rapportér
et tall som ikke betyr noe.

Dagens baseline til sammenligning (2026-10-13, n=30): fitScore AUC 0,577,
priorityScore 0,549, winProbability 0,575. Eneste signalbærer `scope_score` 0,678.
