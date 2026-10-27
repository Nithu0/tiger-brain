---
tags: [firm-v2, data-1, project, masterarkiv]
type: project-pointer
updated: 2026-07-27
---

# PROJECT: masterarkiv (peker + sammendrag)

Data-1s primærprosjekt i FIRM v2. **Ikke en ny repo** — et lag oppå eksisterende RAG + Obsidian.

## Kanoniske kilder (pekere)

| Konsept | Plassering |
|---|---|
| RAG-motor (hybrid BM25+bge-m3) | `command-center/packages/rag-engine` |
| Minne-motor (distill) | `command-center/packages/memory-engine` |
| Recall-CLI | `command-center/_bin/rag-recall.sh` |
| Vault (menneskelesbart) | `~/Obsidian/Brain/` (90-archive = avsluttet) |
| Design | `08-system-architecture/2026-07-27_masterarkiv-design.md` |

## Status

Designfase. F1-arkivering (thesis + søking) er første reelle innslag i `90-archive` med avslutnings-MOC-er — mønsteret masterarkivet skal generalisere.

## Neste

Fasett-metadata-skjema (agent/prosjekt/dato/kunde/beslutning/fil/nøkkelord) → rag-engine, på branch. Nightly ikke-PII batch. Lenke-integritet.
