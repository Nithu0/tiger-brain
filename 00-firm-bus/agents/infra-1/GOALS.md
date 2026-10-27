# infra-1 — GOALS.md

## Parkert 2026-10-13T08:20Z for Veldora strategiråd runde 1

### Hva jeg hadde i gang
- **Produksjonsvakten for anbud-appen** (gren `infra-1/vakt-i-repo`, f47cd4d, av main).
  Ferdig, etterprøvd og INSTALLERT på verten: `anbud-vakt.service` kjører, logg-sjekken ser
  trafikk fra riktig Railway-tjeneste, tregvarsel krever tre strake runder.
  Rettet tre reelle feil: 5xx-sjekken leste tjenesten `worker` (ingen HTTP-trafikk → blind),
  tregvarsel fyrte på ett måleresultat, skriptet lå utenfor repoet.
- **Lekkasje-porten** `_bin/leak-scan.py` i command-center (gren `infra-1/leak-scan`, 83a77a6).
  Rapport-only, ferdig fra 11.10.

### MÅ gjøres før noe annet
Ingenting. Begge leveransene er ferdige og venter kun på operatør-gate (push = merge til main
i Veldora-repoet; command-center-push er gated). Vakten kjører allerede i drift fra den
installerte kopien, så parkering endrer ikke overvåkingen.

### Trygt å parkere
- Push av `infra-1/vakt-i-repo` (venter OK kjør).
- Push av `infra-1/leak-scan` (venter OK kjør).
- Uforklarte 000-vinduer 12.10 (16:58/18:50/19:08): kan ikke etterprøves, Railways deploy-logg
  rekker bare tilbake til containeren fra 12.10 21:21 UTC. Loggsjekken ser dem hvis de gjentar seg.

### Halvferdig og farlig å etterlate
Ingenting. Ingen prod-endringer åpne, ingen migreringer ventende fra meg, ingen prosesser
startet som ikke er under systemd.

### Operatør-gater i mitt domene (uendret)
1. Rotasjon av node-stackens to passord (ekte funn i memory.db 13.06, verbatim 2264/2323).
2. OK kjør på `infra-1/vakt-i-repo` og `infra-1/leak-scan`.

## PARKERT 2026-10-13 — Veldora strategiråd runde 1 (operatør-ordre via orchestrator-1)

**Hva jeg hadde i gang (Veldora/anbud-infra, ikke GPU-målet over — det er eldre kontekst):**
- `infra-1/vakt-i-repo` (worktree `/tmp/.../scratchpad/wt-vakt`, 1 commit `f47cd4d` på toppen av main 6cc89c2): vaktposten lagt i repoet som tjeneste + loggsjekk. Committed lokalt, **ikke pushet**.
- `infra-1/anbud-vakt-prod-monitor` (worktree `.../wt-vakt-fix`, `367c83c`+`d37577c`): vakt.sh prod-overvåking av CRM+dashboard, krever tre strake feil før varsel. Committed lokalt, **ikke pushet**.
- Begge arbeidstrær er rene (`git status --porcelain` tomt) — ingen halvferdig state, ingenting farlig å etterlate.

**MÅ gjøres før noe annet:**
- Ingenting teknisk blokkerende. De to vakt-grenene er rene commits og venter kun på operatør-push ("OK kjør"-gaten).
- Begrunnelse: vakten overvåker prod men er ikke selv i prod ennå — fravær av den endrer ingenting fra dagens tilstand (prod har ingen uptime-overvåking i dag uansett).

**Trygt å parke:** alt. GPU-ROI-sporet, WSL-dockerd-resten og vakt-grenene tåler å ligge.

**Farlig å etterlate:** nei. Ingen av grenene rører prod, migrasjoner eller secrets.
