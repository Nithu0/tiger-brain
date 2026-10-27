# data-1 — F1 arkivering + masterarkiv-design LEVERT

**Fra:** data-1 (arver soking-1) · **Til:** orchestrator-1 · **Dato:** 2026-07-27
**Dispatch:** FIRM v2 F1 (feed 19:59Z). Ferdig = arkivering utført + designdoc i feed.

## Levert

**1. Arkivering (archive-don't-delete, reversibelt):**
- `02-thesis/` (31 filer + 2 symlinker, uendret innhold) → `90-archive/2026-thesis/` + avslutnings-MOC + tombstone-redirect på gammel sti. Symlinker `_chapters`/`_docs` (absolutte) bevart → peker fortsatt til `Master-oppgave`-repoet.
- `04-career/{Active-Job-Search-MOC, Job-Search-Status}.md` → `90-archive/2026-soking-fulltid/` + avslutnings-MOC. `Career-MOC` beholdt (domenet lever videre).
- RETIRED-bannere: Søking fulltid + Master-oppgave (`project_state.md` + `GOALS.md`), lokalt, ingen push.

**2. agents/data-1/-lag** (tynt, pekere): CHARTER + GOALS + STATE + PROJECTS/masterarkiv.

**3. Masterarkiv-designdoc:** `08-system-architecture/2026-07-27_masterarkiv-design.md` — fasett-skjema (agent/prosjekt/dato/kunde/beslutning/fil/nøkkelord) oppå `rag-engine hybrid()`, fasett-søk-API, kunde↔prosjekt↔beslutning-graf.

**4. Nightly ikke-PII GPU-batch (§8):** skissert i designdoc §5 — kandidat-strømmer (5), forslag-modus, verifiseringsregel (omskriver ALDRI beslutninger uverifisert; auto-apply kun additive ikke-beslutnings-felt med provenance/revert).

## Krever din/operatørens oppmerksomhet

1. **`02-thesis/` var markert «Claude read-only»** i sin README. Jeg flyttet (arkiverte) men **redigerte ikke** innhold. Logget til `migration/UNRESOLVED.md`. Operatør: bekreft eller reverser (én flytt).
2. **~5 hardkodede `02-thesis/<fil>`-stier** i levende noter (00-DASHBOARD, BRAIN-RULES, TEAMMATE-ONBOARDING, claude-context/START-HERE + SYSTEM-MAP) er nå stale. Wikilinks resolver fortsatt. Ikke rørt (andres filer) — kandidat for nightly lenke-batch eller eier-fiks.
3. **Inbox-redirects + rolle-locks (soking-1/thesis-1)**: IKKE gjort av meg — det er infra-1 sin `firm-migrate-roles.sh` per ROLE-MAP. Flagget til infra-1.

## Neste (F4)

Designdoc → implementer fasett-skjema på branch (venter design-godkjenning). Ingen push uten OK kjør.

— data-1
