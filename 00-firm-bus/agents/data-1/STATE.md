---
tags: [firm-v2, agent, data-1, state]
type: state
role: data-1
updated: 2026-08-19
---

# STATE — data-1

## Nå

Migrert fra `soking-1` 2026-07-27 (FIRM v2 F1). Jobbsøket er ferdig (Ambita sikret), søking-prosjektet arkivert. **F1-leveranse fullført** samme kveld:

- Arkivert `02-thesis/` (31 filer + 2 symlinker) → `90-archive/2026-thesis/` + avslutnings-MOC + tombstone. Innhold uendret (mappa var *read-only*).
- Arkivert søking-notatene → `90-archive/2026-soking-fulltid/` + avslutnings-MOC.
- RETIRED-bannere på Søking fulltid + Master-oppgave (project_state + GOALS), lokalt.
- agents/data-1/-lag + masterarkiv-designdoc opprettet.
- Migreringsavveiinger → `migration/UNRESOLVED.md`; handlinger → `MIGRATION-LOG.md`.

## F4a levert (2026-07-27)

Masterarkiv fasett-lag i `@cc/memory-engine` (facets-tabell + deriver + backfill, 108/108 grønt) — **PR #83** åpen, venter code-review = design-godkjenning. Stale `02-thesis`-stier fikset. Migrerings-docs på main (`0ecc47c`).

## Onboarding v2 (2026-07-28)

Dispatch 15:03Z kvittert og utført. Kartlegging (3 parallelle Explore-agenter) bekrefter:

- **PR #83** (F4a, `feat/data-1-facets`, pushet under OK kjør 27.07 23:00) er OPEN, ingen review ennå. Commit `047a7fc` ligger også på `feat/firm-v2-rollout` (superset).
- F4a-koden er ren: facets-tabell (`migrate.ts:247`) + deriver/backfill eksportert, men **ingen konsument utenfor pakken ennå** — ingest-wiring er F4b/F4c-scope, som designet.
- `hybrid()` har allerede `filters` (project/source_type/date_after), men ingen facets-join → F4b-delta er veldefinert.
- Arkivene står: `90-archive/2026-thesis/` (31 filer + closing-MOC) og `2026-soking-fulltid/` (3 filer + closing-MOC). `migration/UNRESOLVED.md`: begge data-1-punkter lukket.
- **Funn** (detaljer i onboarding-analysen): (1) pnpm-artefakter i command-center-rot — **RYDDET 28.07 (OK kjør)**, slettet; (2) ukommitterte RETIRED-bannere + skitne arkiv-repoer — **RYDDET 28.07 (OK kjør)**: kuraterte commits `3764bb6` (Søking, 13 filer, PII/binær gitignorert) + `cd2e6ec` (Master-oppgave, 8 filer, nested predictor-repo + binærfiler gitignorert), begge repoer rene, IKKE pushet; (3) `command-center/project_state.md` er stale (2026-06-19, pre-FIRM-v2) — åpen, eier tools-1/orchestrator-1; (4) stray GOALS-filer i `Brain/agents/{learning-1,paal-1}` utenfor firm-bus — åpen, flagget.

Full analyse: `00-claude-inbox/command-center/2026-07-28_data-1-onboarding.md`.

## F4b levert (2026-08-16, operatør-GO 14.08 uten å vente på #83)

Fasett-filtrert hybrid-recall KODE-KOMPLETT: `hybrid()`-filtre (agent/customer/doc_type/decision_ref/include_archived, default arkiv-ekskludering), facet-filter i begge lanes m/over-fetch, ingest-wiring (`insertDistilled`→deriver), `customer_aliases` (aldri rå PII i delt indeks), `rag-recall`-flagg, `_bin/facets-backfill.ts`. Commit `92ff3d1` på **`feat/data-1-f4b`** (bygget i worktree, base = facets-branchen). 247/248 tester (1 pre-eksisterende eval-fail), typecheck rent, code-review high: 10 funn alle fikset, E2E-smoket. **IKKE pushet.** Rapport: `00-claude-inbox/command-center/2026-08-16_data-1-f4b-facet-recall.md`.

Agent-proveniens LUKKET 17.08 (`879f98e`): capture stamper FIRM_ROLE → verbatim.agent (guardet ALTER) → source_ref.agent → facets.agent. Ved merge gjenstår: `facets-backfill.ts` på live-DB (derive-v2) + populer `customer_aliases` (operatør).

## F4b rebaset på main (2026-08-19)

`feat/data-1-f4b` rebaset på `origin/main` (fc303ea, inkl. PR #83-fiksene 92aeeb7) → `0bf5642` + `d32f575` (lokalt i worktree `.claude/worktrees/f4b`). Semantisk reconcile av derive.ts: beholdt mains exhaustive SourceType→doc_type-map (document→reference, youtube→video), `MemoryObjectRow=Pick<>`, NOT NULL-one-shot, hoistet statement; lagt F4b oppå (agent fra source_ref, customer via alias-tabell, PII-scrub av keywords, `deriveFacetsForObject`, `DERIVE_METHOD=derive-v2`). **Eierskap ved re-derive (besluttet etter code-review):** `agent`/`customer` = derive-EID (`= excluded.x`) — backfill populerer 14 137 derive-v1-rader og kan nulle en verdi hvis kilden forsvinner (alias fjernet ⇒ customer + keywords reverterer sammen); F4c-berikelse må bære egen proveniens. `decision_ref` = enrichment-eid (null fra deriver, S1-fiks fra review; F4b-sentinelen «inline» droppet — filteret er eksakt-match og ikke eksponert i rag-recall). Dobbel write-path-wiring (mains in-txn derive + F4b post-txn) slått sammen til mains in-txn-variant med alias-map. Code-review high: 10 funn, 7 fikset (`512ec2e`), 3 utsatt til F4c/runbook (stale dist etter merge, filter-after-top-K, archived-semantikk). 3 nye tester. 257/258 grønt (1 pre-eksisterende eval-fail, feiler også på main), typecheck rent, live-smoke: `--doc-type video|chat` skiller korrekt på prod-DB. Live-DB: 14 289 objekter / 14 137 fasetter (152 uten rad — ingest siden backfill), alle derive-v1, agent=0 → `facets-backfill.ts` må kjøres etter merge.

## Neste

Rapport: `00-claude-inbox/command-center/2026-08-19_data-1-f4b-rebase.md`.

(1) Push av rebaset `feat/data-1-f4b` (force-with-lease — historikk omskrevet) når operatør sier OK kjør → PR → orchestrator-1 merge-review. Etter merge: `facets-backfill.ts` på live-DB + `customer_aliases` populert (operatør). (2) Trading-1 forensics-ingest-pilot når trade-forensics.md lander (avtalt 14.08). (3) F4c nightly ikke-PII 30b-batch (blockers: GPU-boks-kadens + agent-wiring i worker).

## Pekere

- Designdoc: `08-system-architecture/2026-07-27_masterarkiv-design.md`
- RAG: `command-center/packages/rag-engine` (`hybrid()` BM25+bge-m3), `_bin/rag-recall.sh`
- Kø: `command-center/data/brain-orchestrator.db :: agent_tasks`
- Åpne punkter: `command-center/migration/UNRESOLVED.md`

## Oppdatert 2026-10-15 — f4b er IKKE lenger upushet

Teksten over sier «IKKE pushet» om `feat/data-1-f4b`. Det stemmer ikke lenger. Under
operatørens «push alt ut» 14.10 ble **begge** lokale stakker sikret på origin, uten force:

| origin-gren | SHA | hva |
|---|---|---|
| `feat/data-1-f4b-reviewed` | `512ec2e` | stakken denne fila dokumenterer (10 review-funn, 7 fikset) |
| `feat/data-1-f4b-reconcile` | `ec10e37` | udokumentert parallell rekonsilering, lå bare i `~/.cache/cc-wt-f4b` |

Begge er 3 commits over base `fc303ea` og **34 bak origin/main**, og de divergerer fra
hverandre (9 filer, 91+/156−). `feat/data-1-f4b` (`92ff3d1`, 16.08-hodet) og
`feat/data-1-facets` (`92aeeb7`) står urørt — **force-push ble ikke gjort og krever operatøren.**
Ingen PR åpnet: en stakk må velges og rebases på dagens main først.

Fortsatt usikret: `feat/data-1-trade-forensics-ingest` (`bf1301e`) i `~/.cache/cc-wt-tfingest`.

**Destilleringsloopen:** 53 rader udestillert over 10 dager (3 dødbrev med kjent årsak +
50 rader der årsaken er prunet bort). Fire kodefikser spesifisert, ingen startet, eierskap
overført til orchestrator-1 15.10. Se `handoffs/2026-10-14-data-1.md` + §4 i
`handoffs/2026-10-15-orchestrator-1-OVERTAKELSE.md`.
