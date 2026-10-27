# Firm-revisjon 2026-10-03 (read-only, 5 parallelle agenter)

Ingen endringer gjort, bortsett fra stopgap `~/.local/bin/codex` → nvm v24.15.0 codex.

## P0 — gjør nå
1. **aslisten-crm prod-backup død siden 2026-09-12** (siste gode: `~/backups/aslisten-crm/aslisten-20260912.zip`, ~21 d). `scripts/fetch-backup.sh` + `vaktpost-oppsett.sh` har mistet +x og fått CRLF (Windows-verktøy skrev via \wsl.localhost; skjult av core.fileMode=false). Fiks: `sed -i 's/\r$//'` + `chmod +x` + manuell `systemctl --user start aslisten-crm-backup.service`. Varsling er bare en markørfil → bør til Telegram. CRLF ligger på mange andre filer i treet også.
2. **callcenter.js-mcp/config.json.save** har passord + OpenAI-nøkkel, ikke gitignorert. Slett/ignorer + roter nøkkel.
3. **Push-gate-hull** (command-center): guard-shim sjekker kun `$1` (`git -C x push` slipper gjennom, `_bin/firm-exec-guard/git:31-33`); gh/vercel/railway på executor-PATH med skip-permissions; Telegram-regex `^(approve|godkjenn)` matcher fritekst (`~/.hermes/agent-hooks/firm-intake.sh:48`); Hermes-LLM kan selv skrive approve (`firm-terminal-guard.sh:23`); verify pusher branch-tip, ikke registrert `.head` (`firm-remote-verify.sh:113`). 2 stale jobber (2026-09-21 admin1/data1) venter verify.

## P1 — infra-robusthet
4. **PATH/node:** nvm default `lts/*` → v24.20.0 ikke installert → N/A. Alle CLI-er kun i nvm v24.15.0, units har versjonen hardkodet, `.nvmrc`=20. Fiks: `nvm alias default 24.15.0`, felles `~/.firm/env` (FIRM_NODE_BIN) for units+tab-init, `command -v`-sjekk før exec, logg «online» først etter sjekk.
5. **Executors deler checkout med interaktive paner** uten lås → bør kjøre i per-jobb worktree.
6. **Rollelås:** ikke-atomisk; bytt til `flock` på fd arvet over exec.
7. **Inbox/feed vokser uten rotasjon** (tools-1 283 KB, feed 296 KB, ~60 % «online»-støy); stale juli-briefer vises ved hver oppstart. Fiks: ack-cursor per rolle + ukentlig arkiv-timer; presence ut av feed.
8. `agent_tasks`-mirror oppdaterer aldri status (9 rader evig `queued`); codex-roller har ingen executor-units men er med i `@all`.

## grossist-plattform (codex-1..8, sist endret 2026-07-23, ~10 uker ucommittet)
- Bygger, typesjekker, 255 tester grønne. eslint 12 feil (apps utenfor parserOptions).
- **KRITISK:** mcp-tools ignorerer policy-kontrakten (ingen avhengighet til @grossist/policy, `assertAllowed` sjekker kun `blocked`, `allowReadOnlyPolicy` eksportert og fail-open, `sendApprovedEmail` sjekker ikke approvalId). codex-1 varslet codex-2 2026-07-21 — ikke fulgt opp.
- **HØY:** modellen velger tenant (`caseContext` i tool-input) og kan overstyre pris — bryter låst arkitektur. `.next/` (100 MB) + tsbuildinfo tracket i git. Fase 0 ufullført (Dockerfiler mangler, ingen CI).
- MED: API på 0.0.0.0 + CORS true + ingen auth; apps utenfor build-grafen; pakkene er øyer (ingen wiring); grensebrudd license-server → license/src/__tests__.
- Plan: gitignore-hygiene-commit → én commit per eier-pakke i avhengighetsrekkefølge → squash cfe8080 før første push → CI.

## Nexus / ai-assistent
- Ingen strategi/risiko-endringer uten proposal. Worker 1743/1743 grønne. Ingen reelle secrets.
- **HØY:** stagede reverteringer i worktrees `wf_9f403c2c-165-1` (gjeninnfører awaited getOandaSpread før ordre, opptil 8 s forsinkelse) og `wf_9f403c2c-165-4` (feil corrupt-stop-regel) — må forkastes, ikke committes.
- **HØY:** unike commits kun lokalt: HLE-branch (2), lokal main (4), worktree-commits 631cc5b, 4b8b444, 20515cc, 6622dad, 41dd662.
- Sprawl: 47 worktrees (31 trygge å prune), 271 brancher (231 merget). 5 proposals aldri committet; 2 stale proposal-kopier ville regresse status. Thesis-PDF-er/.playwright-mcp lekket inn i repoet.

## Veldora-anbud (prod, auto-deploy fra main)
- Commit 333050c (kompetansebank) koherent, tsc grønn. **Migrasjon `20261003_131234_kompetanse` kjører automatisk mot prod ved merge** (additiv). Deploy web før worker. Rebase på origin/main og dropp 13f3133 (duplikat av #33).
- GDPR: CV-er lesbare for alle innloggede; `parse-cv` sender CV-tekst til Anthropic uten consent-sjekk. Avgjør før ekte CV-er importeres.
- Veldora-gws redigeres aktivt, mangler migrasjon, vil konflikte med anbud i payload.config.ts/registry.ts/migrations/index.ts.

## Øvrig
- AS: ikke-ignorerte zip-er (Proff API m/ mulig «Token»), `.playwright-mcp/`, `fiken-innskudd.py` med 11-sifrede tall (konto/fnr?) — ikke commit blindt.
- research-os: db-wal/shm + 16 MB OCR-backups ikke ignorert. call-center-ai-demo 551f852 klar for push-godkjenning. command-center/body.txt søppel.
