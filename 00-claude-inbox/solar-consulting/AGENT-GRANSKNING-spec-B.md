# Spec B: strategi mot implementasjon i anbudsplattformen

Repo (les, ikke endre): /home/nithu/code/Veldora-sc04-agenter (worktree av origin/main 1f8d131).

## Regler
- Bare lesing. Ingen filendringer i repoet, ingen nettverkskall, ingen prod-tilgang, ingen `npx`.
- Hver påstand skal ha fil:linje eller dokument:avsnitt. Er noe ukjent, skriv UNKNOWN.
- Skriv resultatet til /tmp/claude-1000/-home-nithu-code-command-center/7c13bcf7-5023-4133-a8ac-8980f6dfe1d0/scratchpad/granskning/B-strategi.md

## Kilder som skal leses
strategy/ (alt, også proposals), prd/ (særlig kvalifikasjonslag og bedriftsautomatisering, og alle anbudsrelaterte PRD-er), decisions/ADR/ (alle), projects/anbud/docs/, projects/anbud/ARCHITECTURE.md, projects/anbud/README.md, issues/ (status-feltene), automation/ (agentdefinisjoner).

## Leveranse
### Tabell 1: krav mot status
Én rad per konkret strategi, krav eller planlagt agent (helst 30–60 rader, gruppert per område: triage, kvalifikasjon, kravuttrekk, prising, tilbudsskriving, red team/challenge, juridisk/KOFA, markedsdata/konkurrenter, læring/kalibrering, bedriftsautomatisering, møte/innboks):
| område | krav/strategi (kort) | kilde (fil:avsnitt) | hvor det skulle vært implementert | hva som faktisk finnes (fil:linje) | status |
Status er én av: `agent` (Claude med verktøy/flere steg) · `enkelt-LLM-kall` · `forenklet til heuristikk` · `ikke implementert` · `implementert men ikke kjørende` (flagg av, aldri planlagt, mangler nøkkel; si hvilken) · `UNKNOWN`.
Sjekk implementasjonen i projects/anbud/crm/src (jobs/tasks, lib, config) og i jobs/registry.ts for planlegging. Et flagg teller som «ikke kjørende» bare hvis standarden i koden er av. Hva som faktisk er satt i prod, vet du ikke. Skriv det.

### Avsnitt 2: hva strategien sier agentene skal være
Siter (kort) det strategien sier om agentisk arbeid: «AI proposes, humans decide», eventuelle lister over agenter, modellvalg, budsjett og evalkrav. Hva er lovet, og hva er levert?

### Avsnitt 3: de største gapene
Fem til ti gap mellom lovet og levert, rangert etter betydning for å **vinne anbud**, med kilde.
