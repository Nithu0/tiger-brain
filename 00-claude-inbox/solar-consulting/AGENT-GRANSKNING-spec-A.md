# Spec A: inventar av modellkall og heuristikker i anbudsplattformen

Repo (les, ikke endre): /home/nithu/code/Veldora-sc04-agenter (worktree av origin/main 1f8d131). Plattformen: projects/anbud/crm (Payload 3, jobber i src/jobs/tasks/, registrert i src/jobs/registry.ts) og projects/anbud/dashboard.
Les først projects/anbud/crm/src/lib/llm.ts og src/lib/agentRun.ts.

## Regler
- Bare lesing. Ingen filendringer i repoet, ingen git-kommandoer som endrer noe, ingen nettverkskall, ingen prod-tilgang, ingen `npx`.
- Hver påstand skal ha fil:linje. Kan du ikke se noe i koden, skriv UNKNOWN. Ikke gjett.
- Skriv resultatet til /tmp/claude-1000/-home-nithu-code-command-center/7c13bcf7-5023-4133-a8ac-8980f6dfe1d0/scratchpad/granskning/A-inventar.md

## Leveranse
### Tabell 1: hvert modellkall
Én rad per kallsted (grep etter completeJson, complete(, llm, anthropic, embed, judge og lignende i crm/src og dashboard/src):
| task/modul | fil:linje | modell (konkret id eller rutingsnøkkel `task:` → hvilken modell, se ruting i llm.ts/config) | prompt (fil:linje) | kontekst agenten får (hvilke felt/dokumenter, trunkering) | enkeltkall / fast kjede (n steg) / agentsløyfe | verktøy (tool use? søk/oppslag/dokumenter?) | selvkontroll (dobbel lesing, sitatsjekk, judge) | cron/trigger (registry.ts:linje) | flagg/env som må være satt |
Ta med maxTokens, om prompt-caching brukes, og om data-policy-porten blokkerer noe.

### Tabell 2: beslutninger som tas med heuristikk der en agent kunne vært smartere
| beslutning | fil:linje | regel/vekter/terskler (konkret) | merket ASSUMPTION/gjetning i koden? | hva en agent kunne gjort i stedet |
Dekk minst: config/model.ts (winProbability-vekter), lib/scoring/* (fit, priority, scope, gates, baseRates), config/tracks.ts og verticals.ts, lib/learning/adjust.ts, brief-anbefalingen (brief.ts), kvalifikasjon (lib/qualification), prising (prising), relevance.ts, dedup og klassifisering, og eventuell red team/challenge.

### Avsnitt 3: agentinfrastruktur
Finnes det tool use, MCP, flerstegsløkker, minne/retrieval (legal/retrieve.ts, bank.ts), triageAgents.ts, eller automation/agents/*.json på rotnivå? Hvordan kjøres de (GitHub Actions .github/workflows/agents.yml)? Hva er modell og verktøy for hver?

### Avsnitt 4: fem til ti observasjoner
Det viktigste du fant, kort og med fil:linje. Typisk: «agent X er bare ett JSON-kall uten verktøy», «Y er aldri planlagt», «Z ligger bak et flagg».
