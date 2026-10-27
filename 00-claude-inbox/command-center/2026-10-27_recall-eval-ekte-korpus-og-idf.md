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
