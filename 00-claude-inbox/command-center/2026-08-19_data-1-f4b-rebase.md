---
tags: [firm-v2, data-1, f4b, masterarkiv, rebase]
date: 2026-08-19
role: data-1
---

# F4b rebaset på main — klar for push/PR (2026-08-19)

Branch `feat/data-1-f4b` (worktree `command-center/.claude/worktrees/f4b`), rebaset på `origin/main` fc303ea. Tre commits: `0bf5642` (F4b recall + ingest), `d32f575` (agent-proveniens), `512ec2e` (review-fikser). origin har fortsatt gammel 92ff3d1 → push må være `--force-with-lease`.

## Reconcile mot 92aeeb7 (PR #83-fiksene)

Beholdt fra main: exhaustive SourceType→doc_type-map (document→reference, youtube→video, github_repo→code), `MemoryObjectRow = Pick<>`, NOT NULL-one-shot 002, hoistet prepared statement, archived = segment-match over alle paths, in-transaction derive i insertDistilled. Lagt F4b oppå: agent fra source_ref, customer via `customer_aliases`, PII-scrub av keywords, `deriveFacetsForObject` (on-demand), `DERIVE_METHOD=derive-v2`. Dobbel write-path-wiring slått sammen (mains in-txn-variant, nå med alias-map).

**Eierskap ved re-derive (besluttet, orchestrator-1 bes bekrefte i merge-review):**
- derive-eid (overskrives alltid, også til NULL): project, date_iso, doc_type, file_path, archived, keywords, derived_at, provenance, **agent, customer**. Deriver er eneste produsent; må kunne populere 14 137 derive-v1-rader OG nulle en verdi hvis kilden forsvinner (alias fjernet ⇒ customer + keywords går tilbake sammen — ingen stale kundenøkkel overlever aliaset).
- enrichment-eid (røres ikke): decision_ref. F4b-sentinelen «inline» droppet (S1 fra review; filteret er eksakt-match og ikke eksponert i rag-recall). Ekte decision_ref = F4c.
- F4c-berikelse av agent/customer må bære egen proveniens (egen tabell eller proveniens-gatet update) — ikke stole på at deriver hopper over.

## Code-review high (10 funn) — 7 fikset i 512ec2e
over-fetch også ved date_after/source_type · `--since` ISO-validert · FIRM_PROJECT→memory.db-key-mapping i rag-recall.sh (workspace→alle, master-oppgave→thesis) · `--customer` dokumentert som kanonisk nøkkel · ALTER-race tolerert · eierskap (over) · død header-påstand om deriveFacetsForObject rettet.

**3 utsatt (design/drift, ikke blockere):**
1. **Stale dist etter merge** — rag-recall.ts/session-capture.mjs importerer kompilert dist; main-checkouten har pre-F4b dist. Uten `npm run build` etter merge ignoreres fasettflagg stille og verbatim.agent droppes. → Merge-runbook: `npm run build --workspace=packages/memory-engine --workspace=packages/rag-engine` er obligatorisk steg etter merge (før facets-backfill). Mtime-basert rebuild-sjekk i loadStorage er kandidat for oppfølging.
2. **Filter-after-top-K** (×5 over-fetch, cap 250) — selektive filtre (agent ~2 %) kan ikke fylle top-5 selv om treff finnes. Ekte fiks = facets-JOIN i queryDistilledFts (FTS-lanen). F4c.
3. **archived-semantikk** — «rørte en 90-archive-sti» ≠ «er arkivert»; samtaleminner OM arkivering kan falle ut av default-recall. Latent (0 archived-rader live). Kandidat: utled fra objektets egen lokasjon (source_ref.file_path for note/reference). F4c.

## Verifisering
257/258 tester (1 pre-eksisterende eval-fail, feiler også på main), typecheck rent (memory-engine, rag-engine, brain-worker, brain-orchestrator), begge pakker bygget, `node --check` på session-capture.mjs. Live-smoke mot prod memory.db (lesing): `--doc-type video|chat` skiller korrekt; `--since yesterday` gir varsel + resultater; `FIRM_PROJECT=workspace` flag-first → «all projects».

Live-DB-status: 14 289 objekter / 14 137 fasettrader (152 uten rad — ingest siden backfill; runtime-checkout mangler wiring), alle derive-v1, agent=0, customer=0, customer_aliases tom. **Etter merge + build:** `npx tsx _bin/facets-backfill.ts` (derive-v2) + operatør fyller `customer_aliases`.

## Neste
Venter OK kjør for `git push --force-with-lease origin feat/data-1-f4b` → PR → orchestrator-1 merge-review.
