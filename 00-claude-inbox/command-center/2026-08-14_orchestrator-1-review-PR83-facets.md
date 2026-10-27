# Design-review PR #83 (F4a masterarkiv fasett-lag) — ENDRINGER KREVES før merge

_Fra orchestrator-1, 2026-08-14. High-effort review: 8 uavhengige finder-vinkler + kryssverifisering mot live prod-db (`memory.db`, 14 137 memory_objects) og typesystemet. Konvensjons-vinkelen var helt ren (migrasjonsmønster, PII-håndtering, append-only — alt OK). Arkitekturen (fasett-tabell + deriver, additivt) er GODKJENT — funnene under er implementasjonsfikser, ingen omkamp._

## Blockere (må fikses før merge)

**B1. `normaliseDocType` matcher ALDRI den dominerende reelle source_type-verdien.**
`derive.ts:167-173` sniffer `includes("session")`/`includes("chat")`, men `SourceType`-unionen (`types.ts:23-31`) har ingen «session» — live-verdien er `"conversation"` (13 870 av 14 137 rader i prod). Alt faller gjennom til rå-strengen → etter backfill får ~98 % `doc_type='conversation'` og `'chat'`-bucketen er tom; enhver konsument som filtrerer på `'chat'` får stille null treff.
**Testen maskerer feilen:** fixture bruker `source_type: "session"` (`derive.test.ts:17`) — en verdi ingen produsent skriver. Fix: eksplisitt exhaustive `Record<SourceType, string>`-map, og typ `MemoryObjectRow.source_type` som `SourceType` (da hadde kompilatoren fanget begge).

**B2. `INSERT OR REPLACE` nullstiller F4b-berikelse ved re-derive.**
`upsertFacet` REPLACE-er hele raden mens `deriveFacets` hardkoder `agent: null`/`customer: null` og resetter provenance. Når F4b-enricheren har satt agent/customer, vil neste `backfillFacets`-kjøring (dokumentert «idempotent — safe to re-derive») wipe alt tilbake til null på 13k+ rader. Fix: `ON CONFLICT(object_id) DO UPDATE` som kun rører derive-eide kolonner (evt. hopp over rader med provenance-metode ≠ `derive-v1`). Bonus: DO UPDATE fjerner også REPLACE-ens delete+reinsert-churn på alle 6 indeksene.

**B3. Wiring-gap: fasett-laget gjør ingenting i prod og forfaller fra dag én.**
`backfillFacets` har null callere utenfor egne tester (grep-verifisert), og det finnes ingen write-path-kobling/trigger (kontrast: `distilled_ai` FTS-triggeren på samme tabell, `migrate.ts:235`). Verifisert i prod: `facets`-tabellen finnes allerede (0 rader vs 14 137 objekter). Brain-workeren distillerer 24/7 → selv etter én backfill mangler alle nye objekter fasetter. Aksept: hvis F4a bevisst er «skjema + deriver, wiring i F4b», må det stå eksplisitt i PR-beskrivelsen + wiring (insert-path i `distilled.ts` ELLER nightly `WHERE f.object_id IS NULL`-re-derive) være første punkt i F4b. Ellers blokkerende mot spec §8-klaimen.

**B4. `archived`-fasetten er død kode — begge heuristikkene matcher null reelle data-shapes.**
(a) `ARCHIVE_MARKER = "/90-archive/"` krever LEDENDE slash; `extractFilesTouched` produserer relative tokens (`90-archive/2026-thesis/x.md` bommer). (b) `-archived`-prosjektsuffikset finnes ikke — F1-arkiveringen flyttet mapper, aldri prosjektnavn (din egen UNRESOLVED.md i samme PR bekrefter RETIRED-bannere, ikke renaming). (c) Kun FØRSTE path sjekkes. Fix: segment-regex `/(^|\/)90-archive\//` over ALLE paths; varig løsning er en autoritativ archived-kolonne satt ved arkivering, ikke string-sniffing i projeksjonslaget.

## Bør fikses (samme PR, billig nå)

- **S1.** `decision_ref = "inline"`-sentinel er en boolean forkledd som referanse — inkonsistent med agent/customer-null+F4b-mønsteret; og spec §8-søkeaksen «beslutning» fikk ingen index mens boolean `idx_facets_archived` fikk en. Bruk null + F4b-deferral, eller en ekte ref; juster indeksvalget (dropp archived-indexen eller gjør den partial `WHERE archived=1`).
- **S2.** `prepare()` per rad inne i backfill-transaksjonen (13k re-parse) — hoist statementet én gang.
- **S3.** Test-fixturen hand-ruller 17-kolonne INSERT i stedet for `insertVerbatim`/`insertDistilled` → tredje kopi av insert-SQL-en som drifter stille ved neste skjemaendring.
- **S4.** `NOT NULL` mangler på `project`/`doc_type` i DDL mens TS-kontrakten sier non-null — stram inn NÅ før rader lander (prod-tabellen finnes alt, så det trengs en schema_migrations-one-shot — enda et argument for å ta det i denne PR-en).
- **S5.** Dødvekt: `MemoryObjectRow` duplikerer `RawMemoryObjectRow` (bruk `Pick<>`); `firstString`/`entityToken` håndterer `{path}`/`{name}`-shapes ingen produsent skriver; `pickRefPath` prober `"path"` som ikke finnes i `SourceRef`; `DERIVE_METHOD`-eksporten har ingen konsument.

## Verifiserte ikke-funn (ikke bruk tid på)
DDL-ordering OK (FACETS etter DISTILLED, FK-target finnes); `foreign_keys=ON` aktiv; named-param-binding eksakt; inline `CREATE IF NOT EXISTS` i `migrate()` følger filens egen konvensjon (schema_migrations er for destruktive one-shots); ingen PII skrives (customer=null med riktig alias-tabell-kommentar); prod-tabellens shape er byte-identisk så IF NOT EXISTS er ekte no-op.

## Verdikt
**Ikke merge ennå.** B1+B2 er reelle korrekthetsfeil (B1 rammer 98 % av korpuset og testen er konstruert så den ikke ser det), B3/B4 gjør at featuren som shippet ikke leverer spec §8. Alt er fiksbart i samme PR uten arkitekturendring. Ny runde hos meg etter fix — da er merge-OK sannsynligvis rask.
