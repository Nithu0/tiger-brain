---
tags: [system-architecture, data-1, masterarkiv, rag, design]
type: design-doc
status: draft-v1
owner: data-1
created: 2026-07-27
reviewers: [orchestrator-1, tools-1]
---

# Masterarkiv — designdoc v1 (data-1)

Kort designdoc *før* bygging, per FIRM-V2-SPEC §8 + F4. Mål: alt historisk arbeid gjenfinnbart via **agent / prosjekt / dato / kunde / beslutning / fil / nøkkelord**, med nightly ikke-PII GPU-batch som forbedrer grafen uten å omskrive beslutninger.

## 1. Hva finnes allerede (bygg videre, ikke dupliser)

- **`@cc/rag-engine hybrid()`** — BM25 + bge-m3 vektor, prosjekt-scoped (nøkler: `command-center|nexus|thesis|as|personlig|soking-fulltid`). Recall via `_bin/rag-recall.sh` med fail-safe (8s timeout, degraderer til BM25 hvis Ollama nede, lyver aldri).
- **`memory.db`** — ~13,4k verbatim + ~13,35k distillerte objekter, 100 % bge-m3-embeddet (dim 1024). FTS + vektor-lanes finnes.
- **`memory-engine`** — distill-pipeline (verbatim → distillert).
- **`agent_tasks`** (brain-orchestrator.db) — kontrollplan for batch-jobber (claim/lease/retry/dead_letter).
- **Vast NO RTX4090** (live, token-gated) — qwen3 8b/30b + bge-m3 for ikke-PII bulk.
- **`~/Obsidian/Brain/90-archive/`** — avsluttede prosjekter (thesis + søking arkivert 27.07 med avslutnings-MOC — mønsteret dette generaliserer).

**Gapet:** ingen strukturerte **fasetter**. Søk er i dag fritekst + prosjekt-scope. Kunde, beslutning, dato-range, agent og fil-type er ikke filtrerbare dimensjoner.

## 2. Fasett-skjema (det nye laget)

Sidecar-tabell i `memory.db`, én rad per minne-/dokument-objekt (join på eksisterende `id`). Ingen omskriving av eksisterende rader — additivt.

```
facets(
  object_id     TEXT PRIMARY KEY,   -- FK til memory-objektet
  agent         TEXT,               -- data-1 | trading-1 | paal-1 | ...
  project       TEXT,               -- eksisterende scope-nøkkel (+ arkiv-suffiks)
  customer      TEXT,               -- Pål | <ingen> | ...  (KUN alias, aldri PII-navn i klartekst hvis kundesensitivt)
  decision_ref  TEXT,               -- peker til _decisions/<id> hvis objektet er/refererer en beslutning
  date_iso      TEXT,               -- ISO-dato (created/archived)
  file_path     TEXT,               -- kanonisk kilde-sti (provenance)
  doc_type      TEXT,               -- moc | decision | runbook | report | note | code | chat
  keywords      TEXT,               -- normaliserte tags (fra frontmatter + distill)
  archived      INTEGER DEFAULT 0,  -- 1 = i 90-archive
  provenance    TEXT                -- {source, method, verified_by, verified_at}
)
```

Fasettene **utledes**, ikke skrives for hånd:
- Frontmatter (`tags`, `type`, `created`, `archived_by`) → agent/doc_type/keywords/date.
- Filsti → project/file_path/archived.
- `_decisions/`-lenker → decision_ref.
- Kunde: alias-tabell (samme minimeringsprinsipp som model-gateway i grossist) — **aldri rå kundenavn i en delt/embeddet index hvis sensitivt**.

## 3. Fasett-søk (API-utvidelse)

`hybrid()` får en valgfri `filters`-parameter som ANDes inn som SQL-predikat FØR ranking (billig, presis), ikke som re-ranking etterpå:

```
hybrid(query, { project?, agent?, customer?, decision_ref?,
                date_from?, date_to?, doc_type?, include_archived? })
```

- Default `include_archived=false` (arkiv er søkbart men ikke støy i daglig recall).
- `rag-recall.sh` får flagg (`--agent`, `--customer`, `--since`, `--archived`) som mapper rett på filters.
- Fail-safe-kontrakten er uendret: filter-feil → degrader, aldri lyv.

## 4. Graf: kunde ↔ prosjekt ↔ beslutning

MOC-generator (nightly, forslag-modus) bygger/oppdaterer koblings-MOC-er fra `facets`:
- `_maps/Customer-Project-Decision-MOC.md` — hver kunde → prosjekter → nøkkelbeslutninger (decision_ref-lenker).
- Avslutnings-MOC-mønsteret (thesis/søking) blir malen for prosjekt-arkivering.
- Provenance er førsteklasses: hver utledet lenke bærer `{source, method, verified}`.

## 5. Nightly ikke-PII GPU-batch (§8) — skisse

**Kjører:** systemd-timer (infra-1) → `agent_tasks`-envelope (origin=cron) → qwen3-30b på Vast NO-boks. **Kun ikke-PII-strømmer.** Kunde-PII/memory.db-innhold som er sensitivt rutes til lokal PC (våken) eller køes — aldri leid GPU (§4 BINDENDE).

**Kandidat-strømmer (input):**
1. Nye/endrede vault-noter siden forrige kjøring (mtime-diff).
2. Objekter uten fasetter (`facets`-hull).
3. Foreldreløse noter (ingen inn-/utgående lenker).
4. Stale hardkodede stier (f.eks. `02-thesis/`-refs etter arkivering).
5. Dublett-kandidater (høy vektor-likhet, ulik sti).

**Batchen produserer KUN FORSLAG (aldri direkte skriv på beslutninger):**
- Fasett-utfylling (agent/project/doc_type/keywords).
- Lenke-forslag (semantisk nære, ulinkede noter).
- Oppsummeringer / MOC-forslag.
- Arkiv-rydding-forslag (avsluttet → 90-archive).
- Dublett-flagg.

**Verifiseringsregel (BINDENDE, §8):** batchen *omskriver aldri en beslutning uten verifisering*. Konkret:
- Utdata lander i `_promote-candidates/nightly/<dato>.md` som forslag med confidence + provenance.
- **Auto-apply KUN** for additive, ikke-destruktive, ikke-beslutnings-felter (fasett-utfylling på tomme felt, tag-normalisering). Alt annet krever verifisering (regel-sjekk eller menneske/Opus-gate).
- Ingenting i `_decisions/` eller med `type: decision` røres automatisk — kun forslag.
- Hver auto-applied endring logges med `provenance={method: nightly-30b, verified_by, verified_at}` for full sporbarhet + revert.

## 6. Faser

1. **F4a** — `facets`-tabell + utleder (frontmatter/sti/decisions) over eksisterende korpus. Backfill-batch på GPU (ikke-PII: vault er ikke-PII). *Branch.*
2. **F4b** — `hybrid()` filters + `rag-recall.sh`-flagg. Tester mot arkivert thesis/søking (kjent fasit).
3. **F4c** — nightly-batch (kandidat-strømmer 1–3) i forslag-modus, output til `_promote-candidates/`. Report-only til mønsteret er verifisert.
4. **F4d** — kunde↔prosjekt↔beslutning-MOC + dublett/lenke-strømmer (4–5). Auto-apply-gate skrus på gradvis, additive felt først.

## 7. Åpne spørsmål (→ operatør/orchestrator-1)

- Kunde-alias-tabell: hvor bor mappingen (lokal, aldri i embeddet index)? Deler med grossist model-gateway sin minimering?
- Skal arkiverte prosjekt-scopes få egen nøkkel (`thesis-archived`) eller bare `archived=1`-flagg? (Foreslår flagg — enklere.)
- Backfill av ~13k objekter på GPU: én batch vs. inkrementell? (Foreslår inkrementell, mtime-drevet.)

---
*Grunnet i drift 27.07: rag-engine hybrid + bge-m3-korpus + Vast NO-boks + agent_tasks. Ingen ny sannhetskilde — additivt fasett-lag + forslag-batch.*
