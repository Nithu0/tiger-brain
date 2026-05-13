---
date: 2026-05-13
type: audit
project: research-os
---

# research-os CLAUDE.md audit

## Decision: YES — write a minimal CLAUDE.md

## Reasoning

`/home/nithu/code/research-os/` is a real, actively-used Python project, not a throwaway:

- **Purpose**: API-first literature workflow for operator's master's thesis (battery electrolyte ML). Discovers papers (OpenAlex/Crossref/S2/Unpaywall), syncs Zotero, ingests PDFs, extracts structured data, audits citations on the thesis chapters at `../Master-oppgave/chapters`.
- **Scope**: 11 source modules under `src/research_os/` (cli, discovery, export, extraction, ingestion, storage, verification, zotero, config), 11 scripts, 7 test files, 3 architecture docs.
- **Recent activity**: 6 commits, latest 2026-05-07 ("Add LLM-based claim verifier + Zotero dedup tools"). Not dormant.
- **Cross-project link**: directly coupled to `Master-oppgave/` (thesis) — see workspace `CLAUDE.md` table. A Claude session entering here cold should know that link.
- **CLI surface**: installs `research-os` + `ros` entry points; non-trivial command set (search/show/download/ingest/extract/export/audit/zotero-add/pull-pdfs/fetch-elsevier).
- **No CLAUDE.md today** — confirmed absent.

## What the CLAUDE.md should cover (kept minimal)

1. One-liner: what this is + thesis link.
2. Scaffold pattern: `src/research_os/<module>/` + `scripts/` + CLI.
3. Setup recap (pointer to README, not duplicate).
4. Firm-bus awareness: this project is OUTSIDE the Nexus firm; `FIRM_ROLE` does not map here.
5. Common workflows pointer (README + `docs/workflow.md`).
6. Operator-baseline rules still apply (no emojis, terse, etc.).

Under 50 lines, no duplication of README.

## Files written

- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13_research-os-audit.md` (this file)
- `/home/nithu/code/research-os/CLAUDE.md` (new, minimal)
