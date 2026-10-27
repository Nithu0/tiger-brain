---
tags: [firm-v2, data-1, f4b, masterarkiv, rapport]
type: delivery-report
role: data-1
date: 2026-08-16
branch: feat/data-1-f4b
commit: 92ff3d1
---

# F4b levert — fasett-filtrert hybrid-recall + ingest-wiring

Operatør-GO («OK kjøør» 14.08) for F4b-start uten å vente på #83-review. Bygget i
egen git-worktree (`.claude/worktrees/f4b`), branch **`feat/data-1-f4b`** fra
`feat/data-1-facets` (F4a/047a7fc). Commit `92ff3d1`, 17 filer, +882/−31.
**IKKE pushet** (OK kjør-gaten).

## Hva som er bygget (masterarkiv-design §3)

1. **`hybrid()`-filtre:** `filters` utvidet med `agent`/`customer`/`doc_type`/
   `decision_ref`/`include_archived`. Default `include_archived=false`.
   Semantikk: positive filtre KREVER facet-rad; arkiv-gaten er LEFT-JOIN
   (manglende rad = ikke arkivert) så u-backfillede DB-er ikke mister recall.
2. **`facet-filter.ts`** (rag-engine): én indeksert SQL-pass per kandidat-batch
   i begge lanes, før hydrering. Over-fetch ×5 (cap 250) under positive filtre
   så selektive fasetter ikke sulter top-K. DB uten facets-tabell: arkiv-gate
   no-op'er, positive filtre kaster ærlig feil.
3. **Ingest-wiring:** `insertDistilled` → `deriveFacetsForObject` (never-throw,
   stderr ved feil) — tabellen holder seg synkron fra dag én.
   **`_bin/facets-backfill.ts`** er operasjonelt entrypoint for eksisterende DB.
4. **Agent-fasett:** `SourceRef`/`DistillInput` har nå valgfritt `agent`-felt;
   deriver leser agent/role/firm_role. **Kunde-fasett:** `customer_aliases`-
   tabell (lokal; kun kanonisk nøkkel i delt indeks; alias-treff skrubbes også
   ut av `keywords`, ordgrense-bevisst for flerords-navn som «Ambita AS»).
5. **`rag-recall`**: `--agent --customer --doc-type --since --archived`.
   Med innsnevrende filtre aktve er den ufiltrerte BM25-fallbacken DEAKTIVERT
   (ærlig 0 slår feil svar). Flagg-først-kall faller tilbake til FIRM_PROJECT.
6. **doc_type-mapping fikset** for reelle SourceTypes: conversation→chat,
   document→report, terminal_log→log, *note→note.

## Kvalitet

- **Vitest:** 247/248 grønne (memory-engine + rag-engine). Den ene failen er
  pre-eksisterende eval-gate (`pAt1 0.45 < 0.5`) — verifisert IDENTISK på
  baseline uten F4b. Typecheck (hele repoet) rent.
- **`/code-review high`:** 10 funn — alle adressert (ufiltrert fallback,
  ikke-invokerbar backfill, død agent-kilde, doc_type-kontrakt, top-K-sult,
  prototype-crash i flaggparser, flerords-alias-PII-lekk, stille catch,
  flagg-spiser-flagg, flagg-først-kall).
- **E2E-smoke** på temp-DB: seed (2 objekter, source_ref.agent data-1/
  trading-1, entitet «Ambita AS», alias ambita→kunde-a) → backfill-CLI
  (derive-v2, 2 rader) → recall `--agent data-1` og `--agent trading-1` gir
  riktig separert treff; `--customer kunde-a` treffer begge; `--agent no-such`
  gir ærlig 0.

## Operasjonelt ved merge (viktig)

1. `DERIVE_METHOD` er bumpet til **derive-v2** → kjør
   `MEMORY_DB=<live> tsx _bin/facets-backfill.ts` etter merge (fyller også
   live-DB-ens facets-tabell første gang — den finnes ikke der ennå, så
   arkiv-gaten no-op'er trygt frem til da).
2. `customer_aliases` er operatør-populert (ingen auto-insert). Uten rader er
   customer-fasetten null overalt.
3. ~~Agent-fasetten fylles kun når produsenten sender `input.agent`~~ —
   **LUKKET 17.08 (`879f98e`):** agent-proveniens går nå ende-til-ende:
   Stop-hook-capture stamper panens `FIRM_ROLE` → ny `agent`-kolonne på
   `verbatim_exchanges` (guardet ALTER for eksisterende DB) →
   `distillAndInsert` tråkler til `source_ref.agent` → `facets.agent`.
   Historiske rader (bare UUID-proveniens) forblir null — kan ikke
   rekonstrueres ærlig. 250/251 tester, typecheck rent.

## Avhengigheter

Branchen bygger på `feat/data-1-facets` (PR #83, fortsatt uten review).
Naturlig vei: #83 merges → PR for `feat/data-1-f4b` mot main. Alternativt kan
#83 oppdateres til å peke på f4b-branchen (superset). orchestrator-1 velger.

— data-1
