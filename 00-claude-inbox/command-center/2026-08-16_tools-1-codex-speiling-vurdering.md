# tools-1: codex-1..8-speiling — F3-vurdering (2026-08-16)

Utsatt fra F1 («speiling vurderes F3», firm-roles.sh). Spørsmål: skal codex-1..8 re-mappes til å speile v2-rollene 1:1?

## Faktagrunnlag (verifisert i dag)

- codex-cli 0.144.6 installert og fungerende; `@cc/engines` har OpenAIEngine wired med auto-fallback til claude i remote-executoren (`FIRM_EXEC_NO_FALLBACK=1` for å skru av).
- **Gridden er sovende:** codex-panene var sist online ved v2-launch (28.07, launcher-test). Siste reelle inbox-dispatch til noen codex-rolle: 21.07 (pre-v2).
- **Headless codex-bruk siden v2: null.** 7 REMOTE JOBs totalt i bus-historikken: 5 claude, 2 codex — begge codex-jobbene var infrastruktur-tester («fallback-e2e», «hook-test») til codex-3, uten claim/DONE-appends. 0 forekomster av `fallback-fra-codex` noe sted.
- **Ingen codex-executors:** systemd kjører 8× `firm-remote-executor@` — alle claude-roller. Codex-jobber har i praksis ingen plukker i dag.
- Policy-rammen (spec §5 + operatør 27.07): codex er laveste sub-tier, holdes wired men er IKKE default — kun eksplisitt ruting ved ledig kapasitet.
- Stale mapping i `firm-roles.sh`: codex-5 → Master-oppgave (**arkivert** prosjekt); codex-6..8 → AS/Søking/Personlig (levende prosjekter som IKKE har egen v2 Claude-rolle).

## Vurdering

**1:1-speiling anbefales IKKE.** Den ville gitt navnesymmetri og ingenting annet: bruken er null, policyen sier eksplisitt-ruting-kun, og en speiling koster migreringsstøy (firm-roles.sh, launchers, inbox-migrering, ROLE-MAP) for en grid ingen dispatcher til. Symmetri er ikke et behov før volumet finnes.

**Anbefalt: behold gridden som spare-capacity-pool, med to små fikser:**
1. **codex-5 re-pekes** fra arkivert Master-oppgave → `command-center` (eller workspace). Eneste objektivt stale rad.
2. **codex-6..8 beholdes** på AS/Søking/Personlig — det er i dag eneste pane-dekning for de tre prosjektene (ingen v2 Claude-rolle eier dem). Å fjerne dem reduserer dekning; å speile dem fjerner den helt.

Valgfritt (kost/nytte-avveining for orchestrator): én `firm-remote-executor@codex-N`-unit hvis headless codex-kapasitet faktisk ønskes brukt — i dag er «kept wired» reelt «kept installert»: en dispatch til codex-rollene blir liggende uplukket. Alternativt er det ærligere å dokumentere at codex kun nås via engine-feltet i claude-rollenes executor-kjede (fallback-mekanismen), ikke via codex-rollene.

## Berørte filer ved beslutning (ikke min lane — handoff)

`_bin/firm-roles.sh` (codex-5-raden) + evt. `codex-tab-init.sh`/launchers + `migration/ROLE-MAP.md`-notat. Eier: infra-1/orchestrator-1.

— tools-1, 2026-08-16
