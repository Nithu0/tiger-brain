# rea og Superset mot Omnigent (2026-10-25)

Kilde: researcher-agent a78aa928e56a4274a. Tallene for innsats er agentens anslag.

## Konklusjon

- `morluto/rea` er et verktøy for reverse engineering: en MCP-server og CLI rundt Ghidra, Frida, apktool og lignende. Den har ingen funksjoner for arbeidsområder, paner eller oppgaver, så det er ingenting å kopiere derfra. Lisens MIT.
- Superset (Elastic License 2.0) er riktig forbilde. Bruk CLI-vokabularet dens som spesifikasjon (`snapshot`, `agents wait/explain`, `ws create --agent --prompt`) og skriv koden selv. Ikke kopier koden deres.

## Hva vi har i dag

- Omnigent 0.18.0 kjører på :6767 med orchestrator, 7 lanes, 10 spesialister og codex-reviewer. Push, merge og deploy krever godkjenning via et ASK-kort.
- Cockpit (web :3200, api :3100) har:
  - fanene oversikt, github, aktivitet, brain, terminaler og feed
  - en godkjenningskø
  - PWA med push-varsler
  - aggregatoren `apps/api/src/routes/omnigent.ts`
- Worktrees finnes bare som skript (`_bin/firm-worktree-spawn.sh`, `-list.sh` og `-cleanup.sh`). Repolisten i dem er hardkodet.

## Hva vi bør bygge, i rekkefølge

1. **Hoved-fane** (3–5 dager). Samler det operatøren må gjøre, godkjenninger med filer og diff, og alle aktive agenter med tilstand og kostnad. Bygges på `/api/omnigent`, godkjenningskøen og `agent_tasks`.
2. **Agenttilstand med årsak** (1 dag). Viser om agenten jobber, er blokkert eller står ledig, og hvorfor. Bygges i aggregatoren.
3. **Worktree via API og UI** (1–2 dager). Gjør repolisten dynamisk. Legg til et skjema for å starte agenter (prosjekt, oppgave, motor) med maks ca. 8 agenter, som er grensen for RAM.
4. **Mobilvisning over Tailscale** med `AUTH_SECRET` (2–3 dager). Telegram beholdes for utsending av oppgaver.
5. **Automasjoner** til slutt (2 dager). En tynn visning over triggerne vi har fra før.

Hoppes over: skripting av paneloppsett, nettleser i appen, editor og Linear-synk.

## Ikke verifisert

- Prisen på Superset og hvordan mobilappen deres fungerer.
- Om Omnigent-UI-et på :6767 allerede dekker deler av punkt 1.
- Om Omnigent har innebygde worktrees. CLI-hjelpen viser ingen.
