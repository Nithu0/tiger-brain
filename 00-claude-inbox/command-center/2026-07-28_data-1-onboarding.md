---
tags: [firm-v2, data-1, onboarding, analyse]
type: analysis
role: data-1
date: 2026-07-28
dispatch: orchestrator-1 2026-07-28T15:03:48Z (ONBOARDING v2)
---

# data-1 onboarding v2 — lane-kartlegging 2026-07-28

Kartlagt med 3 parallelle Explore-agenter (command-center, Brain data-lane, arkiverte repoer). Kun lesing; ingenting endret utenom agents/data-1/STATE+GOALS og denne fila.

## 1. Identitet og lane

data-1 (tidl. soking-1, migrert 27.07 per `migration/ROLE-MAP.md:14`, status UTFØRT). Eier per FIRM-V2-SPEC §8 (:106-111): masterarkivet — MOC-er, kunde↔prosjekt↔beslutning-kobling, arkivering, dedup, provenance, fasett-søk (agent/prosjekt/dato/kunde/beslutning/fil/nøkkelord) oppå rag-recall+FTS, samt nightly ikke-PII 30b-batch som ALDRI omskriver beslutninger uverifisert. Fase-eierskap: F4 Minne (:141). §9: 24/7-docker er infra-1s verifikasjon, ikke min.

## 2. Status F4 (aktivt mål)

**F4a — LEVERT, i review.** Commit `047a7fc` (4 filer, +371): facets-tabell med 6 indekser (`packages/memory-engine/src/storage/migrate.ts:247-267`), deriver/upsert/backfill (`src/facets/derive.ts`), barrel-eksport. 108/108 tester grønne. Pushet under OK kjør 27.07 23:00 → **PR #83 OPEN mot main, ingen review ennå** (design-godkjenning = code-review per orchestrator-1 20:44Z). Merk: commiten ligger også på `feat/firm-v2-rollout` (0330f69 + 047a7fc — superset av facets-branchen), så #83-merge gjør rollout-branchen delvis redundant.

**F4b — veldefinert delta, klar etter #83:**
- `hybrid()` har allerede `filters` (`rag-engine/src/types.ts:88-92`: project/source_type/date_after), anvendt i begge lanes (`bm25.ts:38-53`, `vector.ts:99-113`), men source_type/date_after filtreres post-fetch fordi `queryDistilledFts` bare kan project. Ingen facets-join finnes.
- F4b = utvide filters med fasettfeltene (agent/customer/doc_type/archived/decision_ref), joine facets-tabellen i begge lanes (pre-ranking, per designdoc), `rag-recall.sh`-flagg (`--agent --customer --since --archived`), default `include_archived=false`.
- Deriver har **ingen konsument utenfor pakken** — ingest-wiring (kall ved distill/ingest) må inn i F4b/F4c, ellers blir tabellen stale fra dag én. Backfill finnes for eksisterende korpus.

**F4c — skissert i designdoc** (`08-system-architecture/2026-07-27_masterarkiv-design.md`, draft-v1): nightly qwen3-30b i suggestion-mode → `_promote-candidates/`, report-only; F4d MOC/dedup med gradvis auto-apply-gate kun for additive ikke-beslutningsfelt. Blockers: infra-1 GPU-boks + tools-1 capability-registry.

## 3. Arkiv-verifikasjon (F1-etterkontroll)

- `90-archive/2026-thesis/`: 31 filer + closing-MOC (`outcome: delivered`) + 2 absolutte symlinker inn i live-repoet `~/code/Master-oppgave/` (bevisst — repoet lever videre som kodearkiv, men verd å vite at arkivet ikke er selvstendig).
- `90-archive/2026-soking-fulltid/`: 3 filer + closing-MOC (`outcome: landed-role`, Ambita).
- `migration/UNRESOLVED.md`: begge data-1-punkter LUKKET (stale-stier fikset, 02-thesis read-only beholdt per orchestrator-beslutning).

## 4. Funn som trenger eier/beslutning

**4.1 pnpm-artefakter i command-center-rot (anomali, ukjent opphav).** Untracked `pnpm-lock.yaml` (91 KB, kun rot-importer) + `pnpm-workspace.yaml` (2 linjer, placeholder `allowBuilds: esbuild: set this to true or false`, mangler `packages:`-nøkkel). Tidsstempel 27.07 22:52 — ett minutt før F4a-commiten, altså trolig en ad-hoc `pnpm install` i F4a-økten (min egen, ikke verifiserbart). Kolliderer med npm-workspaces-oppsettet (CLAUDE.md:13, `package.json` workspaces, tracked `package-lock.json`); ingen pnpm-referanse i docs/scripts/CI. **Anbefaling: slett begge.** Sletting er operatør-gated → venter på GO. Ingen fare så lenge de ligger (untracked, ikke i .gitignore), men de kan forvirre neste agent som autodetekterer pakkemanager.

**4.2 RETIRED-bannerne er ukommittet i begge arkiverte repoer.** Søking fulltid: 28 dirty (3 M / 25 ??, inkl. CV-PDF-er og intervju-materiale = PII; repo er local-only uten remote). Master-oppgave: 32 dirty (1 M / 31 ??, inkl. hele nestede `battery-electrolyte-predictor/` og figur-backups). `project_state.md`/`GOALS.md` med bannerne er selv untracked — arkiveringsstatusen overlever altså ikke en clean checkout. Umergede branches: `feat/soknadsagent` (+3), `node-migration-soking` (+2), `backup-humanizer-72bba0a` (divergert). **Anbefaling:** kuratert commit i hver (bannere + .gitignore-oppdatering som ekskluderer PII/binærfiler; IKKE `git add -A`), branches merges eller slettes eksplisitt. Alt operatør-gated (commit-innhold berører PII-filer + branch-sletting) → beslutningspunkt, ikke utført.

**4.3 `command-center/project_state.md` er stale** (2026-06-19, pre-FIRM-v2, nevner ikke facets/masterarkiv). Per MEMORY-OS-AUDIT §5/§13 er project_state autoritativ for status — nå lyver den. `CURRENT-STATE.md` (generert 28.07) er derimot korrekt. Eier: uavklart (tools-1 eller orchestrator-1) — flagges dit, jeg rører den ikke uten avklaring.

**4.4 Stray GOALS-filer utenfor firm-bus:** `Brain/agents/learning-1/GOALS.md` + `Brain/agents/paal-1/GOALS.md` ligger i `Brain/agents/`, ikke `00-firm-bus/agents/`. Trolig feilplassert under v2-onboardingen. Flagges til orchestrator-1/de to rollene; ikke mitt bord å flytte.

## 5. Neste steg (data-1)

1. Vente på #83-review → F4b på egen branch (inkl. ingest-wiring av deriver).
2. Ved GO på 4.1: slette pnpm-artefaktene.
3. Ved GO på 4.2: kuratert arkiv-commit i de to repoene.
4. F4c-forberedelse kan starte uavhengig (kandidat-strøm-spec finnes i designdoc §F4c).

— data-1
