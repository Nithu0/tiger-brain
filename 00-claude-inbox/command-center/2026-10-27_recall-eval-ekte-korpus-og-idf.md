# Recall mot det ekte korpuset, og corpus-IDF (2026-10-27, data-1)

**Kort:** MRR=0.9556 var et lekeresultat. Det ble målt på en syntetisk fixture med 20 notater og falske embeddings. På hele live-korpuset med ekte bge-m3 får hybrid **MRR@10 0,33 globalt og 0,37 prosjektavgrenset**, og **BM25 alene er like god som hybrid, eller bedre**. Corpus-IDF i rangeringen er verifisert riktig. En tokenizer-feil i distillens vokabularsjekk er rettet (command-center#119).

Ingen betalte kall. memory.db er lest bare via en read-only `backup()`-snapshot. Bare bge-m3 lokalt i Ollama.

## 1. Recall-eval mot det ekte korpuset

**Korpus (`FACT`):** 20 720 verbatim-rader og 19 888 destillerte objekter, alle bge-m3 med dim 1024. Korpuset er større enn CLAUDE.md sa (~13k). Stikkprøve: 5 lagrede vektorer mot ferske bge-m3-embeddinger ga cosinus 1,0000.

**Hvorfor 0,9556 ikke kan brukes:** tallet er fra fixture-evalen (`packages/rag-engine/eval`, 20 syntetiske notater). Den gir i dag 0,9306 med falske og 0,9667 med ekte embeddings. Det operatørkuraterte settet (`08-system-architecture/eval/recall-eval-2026-05-25.md`) kan heller ikke brukes: ingen av de 22 gull-notatene finnes i memory.db. «MRR 1.0»-kjøringen 03.06 var en stub som fikk fasiten servert.

**Metode (known-item, seed 42, ingen LLM):** et utsnitt på 16 eller 6 ord fra verbatim-teksten er spørringen. Gull er objektet som ble destillert fra den raden (1:1). Bare destillert tekst er indeksert, så i snitt 38 % av spørringens ord finnes i gull. Utsnitt som forekommer i flere rader, er fjernet (126). n = 574 (300 samtale, 25 YouTube og 25 notater, med to lengder). k_per_lane = 20 som i `_bin/rag-recall.ts`.

| Modus / omfang | MRR@10 | R@1 | R@5 | R@10 |
|---|---|---|---|---|
| BM25 / globalt | 0,338 | 0,277 | 0,416 | 0,474 |
| vektor / globalt | 0,234 | 0,178 | 0,314 | 0,354 |
| hybrid / globalt | 0,329 | 0,263 | 0,415 | 0,483 |
| BM25 / prosjekt | 0,384 | 0,315 | 0,474 | 0,523 |
| vektor / prosjekt | 0,276 | 0,216 | 0,355 | 0,404 |
| **hybrid / prosjekt** | **0,368** | 0,289 | 0,467 | **0,533** |

- **Lange og korte spørringer:** hybrid/prosjekt gir 0,493 på 16 ord og 0,259 på 6 ord. Notater gir 0,793.
- **Latens:** embedding av én spørring tar 280 ms (p50) og 466 ms (p95). Ett helt `hybrid()`-kall med prosjektavgrensning tar 391 og 524 ms.
- **Feil:** 95 bom på lange utsnitt (hybrid/globalt). I 31 av dem var topptreffet fra samme samtale, altså en nabotur. Generisk tekst uten anker («built. Let me verify…») bommer.

**Begrensninger:** et verbatim-utsnitt er ikke en ekte spørring. Strengt gull med ett objekt teller nær-duplikate naboturer som bom. Tallene er derfor et **pessimistisk gulv** og kan ikke sammenlignes direkte med 0,9556. Parafraserte spørringer fra en LLM er ikke kjørt: qwen på denne CPU-maskinen kunne presset session-start-hooken over 10 s.

**Lesning (`ASSUMPTION`):** vektorlaget løfter ikke resultatet. CombMNZ-fusjonen gir omtrent det samme som BM25. Det trekker mot å tune fusjonen eller legge til en reranker. Det er en egen beslutning, og ingenting er endret.

**Bifunn:** memory-engine kaller `db.prepare()` på hvert oppslag. Etter ~90k kastede statements krasjet better-sqlite3 11.10 på Node 24 (`RemoveEnvironmentCleanupHook: env != nullptr`) i evalen. Ingen slik krasj står i brain-worker-journalen de siste 14 dagene, så effekten i prod er ikke bekreftet.

**Reproduser:** runner `packages/rag-engine/eval/run-live-eval.ts` (command-center-PR). Lag en snapshot med `db.backup()`, og kjør `LIVE_EVAL_DB=<snapshot> OLLAMA_BASE_URL=http://127.0.0.1:11434 npx tsx packages/rag-engine/eval/run-live-eval.ts 300 42`.

## 2. Corpus-IDF

- **Rangering (BM25):** SQLites `bm25()` over FTS5 (`storage/verbatim.ts:141`, `storage/distilled.ts:256`, `porter unicode61`). IDF regnes fra hele indeksen ved hver spørring, så det finnes ingen cache og ingen foreldelse. N i FTS5 er lik antall rader (20 721 og 19 888). df stemmer nøyaktig med direkte telling (sqlite 368/200, litestream 72/25, brain 2621/1341). Integrity-check er OK. **Verifisert.**
- Porter-stemmeren folder norsk («ikke» blir «ikk», «må» blir «ma»), men spørringen går gjennom samme tokenizer. Det begrenser presisjonen, men er ikke en feil.
- **Vokabularsjekken i distill:** tokenizeren delte æøå-ord («første» ble «rste»). Rettet i **#119**. Rader flagget for lavt vokabular gikk fra 7 649 til 7 021 av 19 888.
- **Ikke koblet inn:** korpus-IDF-tabellen (`idf-table.ts`, spec §3.3 «refreshed nightly») brukes ikke i prod-distill. Å koble den inn endrer dommen på 2 588 rader. Det er en egen beslutning.

## 3. Fusjon og reranker (eksperiment, ingen prod-endring)

Kjørt på en ny snapshot kl. 13:27. Det ga n=496, fordi korpuset har endret seg, og BM25/prosjekt 0,372. Alle deltaer er mot BM25 på samme snapshot og samme spørringer.

| Variant (prosjekt) | MRR@10 | ΔMRR mot BM25 | R@10 | Latens p50 |
|---|---|---|---|---|
| BM25 | 0,372 | 0 | 0,508 | 10 ms |
| CombMNZ (dagens hybrid) | 0,357 | −0,015 | 0,526 | 22 ms |
| vektet 0,7/0,3 | 0,379 | +0,007 [−0,003, +0,017] | 0,528 | 22 ms |
| RRF k=10/30/60 | 0,348–0,354 | −0,019 til −0,024 | ~0,53 | 22 ms |
| hybrid topp-20 + bge-reranker-v2-m3 (n=150) | 0,349 | +0,026 [−0,013, +0,069] | – | **14,5 s** |

**Ingen variant oppfyller regelen** (> 0,05 MRR og < 1 s). Rerankeren på CPU tar rundt 14 s per spørring. Topp-50 ville tatt ~19 t for hele settet.

**Flaskehalsen er kandidatsteget, ikke rekkefølgen.** Gull er i BM25s topp-20 i bare 52,7 % av tilfellene, og de fleste bom når aldri kandidatlisten. Det som trolig hjelper mest, er å indeksere verbatim-teksten i tillegg til den destillerte (`ASSUMPTION`, ikke målt). Spørringene i denne evalen er hentet fra verbatim, så evalen favoriserer det. Effekten på ekte spørsmål må måles separat. Det er en indeks- og skjemaendring og en egen beslutning.

## 4. Ekte spørsmål

**Kort:** På 50 ekte spørsmål snur bildet fra known-item-evalen. Vektor er sterkere enn BM25, og dagens hybrid (CombMNZ) er best: **MRR@10 0,335 og R@10 0,56 prosjektavgrenset**, mot 0,235 og 0,38 for BM25. ΔMRR mot BM25 er +0,100 [+0,027, +0,174]. Vektet 0,7/0,3, som var best i seksjon 3, taper her mot CombMNZ med −0,050 [−0,100, −0,010]. Spørsmål som operatøren selv har skrevet, nesten aldri treffes av BM25 (MRR 0,03).

**Settet (`FACT`):** `08-system-architecture/eval/recall-ekte-sporsmal-2026-10-27.jsonl`, 50 spørsmål. Det ligger ikke i repoet, fordi det inneholder prosjektinnhold. Fordeling: command-center 25, nexus 16, thesis 6 og aslisten-crm 3. Spørsmålene er av fire slag:
- operatørspørsmål (12), for eksempel «er star live nå kan jeg se hun og bruke hun?» og «trodde jeg hadde lagt til MCP playwright og MCP github allerede?»
- spørsmål mellom paner i firm-bus-innboksene (18), for eksempel «hvilken sti har ML-oversikten fra tidligere arbeid?»
- spørsmål inne i briefer til agenter (19), for eksempel «engine_scores: why did writes stop 2026-04-24?»
- ett eksplisitt `rag-recall.sh`-kall fra en transkripsjon

**Kilder:** Transkripsjonene under `~/.claude/projects` går bare tilbake til 07.10, fordi eldre slettes. Eldre samtaler finnes bare som verbatim-rader i memory.db, og USER-turene der er også lest. I tillegg er innboksene i `00-firm-bus` lest. Private domener (AS, Personlig, Søking og helse/familie/økonomi) er filtrert bort med vilje.

**Hvor få ekte recall-spørsmål det finnes (`FACT`):** Regex-søk etter «hva bestemte vi», «husker du», «forrige gang», «hvor ligger» osv. ga 6 treff i ~6 400 USER-turer og 40 treff i transkripsjonene, nesten bare agentbriefer. Operatøren spør sjelden direkte om tidligere beslutninger. Han skriver «kjør inbox» og lar panene finne fram. Derfor er settet bredere enn «hva bestemte vi»: det dekker spørsmål der svaret allerede finnes i minnet fra før, eller ble gitt i neste tur og ligger der nå. Mer enn ~50 med god merking finnes neppe i dagens kilder.

**Merkemetode:** For hvert spørsmål leste jeg svaret som ble gitt den gangen, enten i transkripsjonen, i neste rad i samme samtale eller i svaret i innboksen. Deretter søkte jeg i snapshoten (FTS på destillert og verbatim tekst) etter objektet som inneholder svaret. Gull er 1 til 3 objekter, og hver rad har én linje med belegg. Gull er aldri objektet fra raden spørsmålet står i. Spørsmålsteksten er ordrett i 40 av 50. I ti tilfeller er den tilpasset lett så den står alene: et substantiv fra samme melding er lagt til, to setninger er slått sammen, eller én setning er omskrevet. Det står i `source`. `project` er gull-objektets prosjekt i memory.db. Fem Veldora-spørsmål ligger under `nexus`, fordi de ble fanget fra den katalogen. **Lekkasjesjekk:** jeg sjekket om spørsmålsteksten står i gull-radens verbatim. Det gjør den i ett tilfelle (ekte-041, en kommentar i gull-radens egen tex). Uten det tilfellet flytter MRR seg under 0,01 og R@10 rundt 0,01.

**Kjøring:** Runneren er `packages/rag-engine/eval/run-real-questions-eval.ts` (lokal commit på `data-1/ekte-spormaal`, ikke pushet). Den bruker samme lanekall og k_per_lane = 20 som `_bin/rag-recall.ts`, ekte bge-m3 via lokal Ollama og en read-only `backup()`-snapshot fra 27.10. To kjøringer ga identiske rangeringer.

| Modus / omfang | n | MRR@10 | R@1 | R@5 | R@10 |
|---|---|---|---|---|---|
| BM25 / globalt | 50 | 0,190 | 0,16 | 0,22 | 0,34 |
| vektor / globalt | 50 | 0,271 | 0,14 | 0,44 | 0,52 |
| CombMNZ / globalt | 50 | 0,280 | 0,20 | 0,44 | 0,52 |
| vektet 0,7/0,3 / globalt | 50 | 0,236 | 0,16 | 0,30 | 0,50 |
| BM25 / prosjekt | 50 | 0,235 | 0,20 | 0,26 | 0,38 |
| vektor / prosjekt | 50 | 0,304 | 0,14 | 0,56 | 0,60 |
| **CombMNZ / prosjekt** | 50 | **0,335** | **0,26** | 0,46 | 0,56 |
| vektet 0,7/0,3 / prosjekt | 50 | 0,285 | 0,20 | 0,36 | 0,54 |

ΔMRR mot BM25 med parret bootstrap og 95 % KI (n = 50, så intervallene er brede). *Rettet 27.10: sto først som 90 %, men koden tar 2,5- og 97,5-persentilen.*

| Variant | globalt | prosjekt |
|---|---|---|
| vektor | +0,081 [−0,039, +0,197] | +0,070 [−0,048, +0,187] |
| CombMNZ | +0,089 [+0,024, +0,157] | +0,100 [+0,027, +0,174] |
| vektet 0,7/0,3 | +0,045 [−0,001, +0,093] | +0,050 [+0,003, +0,098] |

CombMNZ mot vektet: +0,044 [+0,014, +0,084] globalt og +0,050 [+0,010, +0,100] prosjekt. Mot BM25 vinner CombMNZ 17 spørsmål og taper 4.

Etter type (CombMNZ / prosjekt, MRR@10): operatørspørsmål 0,24 (BM25 0,03, vektor 0,33), spørsmål mellom paner 0,35 og briefspørsmål 0,39.

**Feilanalyse (CombMNZ / prosjekt, 22 bom):**
- **Rangert for lavt, 8:** gull er i kandidatlisten på plass 11–27. Det er et rekkefølgeproblem.
- **Utenfor kandidatlisten, 10:** gull er ikke i noen lanes topp-20, men dukker opp i en lanes topp-200 (BM25 plass 29–165, vektor plass 24–114).
- **Fraværende, 4:** gull er ikke i topp-200 i noen av lanene. Spørsmålet deler nesten ingen ord eller mening med svaret, for eksempel «Hva hang, og hvorfor ble ingenting meldt?».

To mønstre går igjen i topptreffene ved bom:
- **Bestillingsobjekter fortrenger svarobjekter.** Minst fem ganger er topptreffet objektet som destillerte selve spørsmålet eller briefen («User requests comprehensive audit of …»). Det ligner spørsmålet mest, men inneholder ikke svaret.
- **Strengt gull teller riktige svar som bom.** I minst tre tilfeller (ekte-025, -047 og -050) svarer et av topp-3-objektene også på spørsmålet, men det er ikke merket som gull. Gull er ikke utvidet i ettertid, fordi det ville gitt systemet fordel. R@10 er derfor et gulv. Med de tre ville CombMNZ / prosjekt ha fått R@10 ≈ 0,62.

**Begrensninger:**
- n = 50, og alle er merket av én person (meg) uten en uavhengig ny merking.
- 19 briefspørsmål er skrevet av agenter, ikke av mennesker.
- Svaret står ofte i neste tur i samme samtale. Det måler om svaret kan finnes igjen nå, ikke om det fantes før spørsmålet ble stilt.
- Spørsmål som handler om tilstand («er X fortsatt Y?»), har gull som var sant den gangen og kan være utdatert nå.
- Korpuset er snapshoten fra 27.10. Rader som ennå ikke er destillert, kan ikke være gull. Derfor falt blant annet doffin-nøkkel- og Superset-spørsmålene ut.

**Lesning (`ASSUMPTION`):** Known-item-evalen i seksjon 1 og 3 favoriserer leksikalsk overlapp, så der ser BM25 best ut, og vektet 0,7/0,3 vinner. På ekte spørsmål er det vektorlaget som bærer, særlig for operatørens korte norske spørsmål. Det taler mot å flytte fusjonen mot BM25 på grunnlag av seksjon 3 alene. Det taler også for å måle verbatim-indeksering mot dette settet før det besluttes. En verbatim-indeks vil trolig gi flere bestillingstreff av typen over, fordi spørsmålets egen rad blir søkbar ordrett. Den kan også løfte de 14 tilfellene der gull er dypt eller fraværende. Begge deler er umålt. Det billigste som kan prøves først, er å nedvekte objekter som bare er en bestilling. Ingenting i prod er endret.
