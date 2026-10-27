# Overlevering 2026-10-16 — orchestrator-1 (cockpit, Omnigent, Star)

Skrevet ved sesjonsslutt. Operatøren starter ny sesjon på Opus 5.5.
Forrige dokument i kjeden: `2026-10-16-WRAPUP-alle-paner.md` (restlageret fra
alle åtte panene — les det for alt som IKKE handler om cockpiten).

## Landet og verifisert i dag

**PR #96 — cockpiten kommer opp ved oppstart.** MERGET som `55be5cf`.
`cc-api.service` (Fastify 127.0.0.1:3100, tsx fra `src/`) + `cc-web.service`
(Next.js 127.0.0.1:3200, `next dev`) + `cockpit.target`
(`WantedBy=default.target`, Linger=yes).

**PR #97 — Omnigent-firmaet + Star av flaten.** GRØNN, `mergeState=CLEAN`,
IKKE MERGET da sesjonen ble avsluttet. Verify + smoke-test pass på begge
kjøringene. Gren: `orchestrator-1/omnigent-autostart`.
Legger til `cc-omnigent.service` (serveren, startet med `--agent omnigent/firm`)
og `cc-omnigent-host.service` (host-daemonen), begge på `cockpit.target`.

**Omnigent 0.17.0 → 0.18.0** (bygget 2026-10-13). Oppgradert etter at unitene
var stoppet, siden `omnigent upgrade` selv tar ned server + host-daemon og
`Restart=always` ellers ville kollidert med installasjonen. Verifisert etter:
`firm` fortsatt registrert, host online, cockpitens tile leser 0.18-API-et
uendret (kostnad + hosts + sesjoner), ingen advarsler i serverloggen, de syv
sesjonene i `chat.db` intakte. Symlinken `~/.local/bin/omnigent` peker på
uv-tool-katalogen og overlevde, så unitens hardkodede ExecStart stemmer fortsatt.

**Claude Code 2.1.278 → 2.1.301.** `~/.claude/settings.json`: `model` gikk fra
`opus[1m]` til `claude-opus-5-5[1m]`. Verifisert mot Models-API-et at 5.5 har
1M inn / 128k ut før `[1m]` ble satt. Backup av gammel settings lå i
scratchpad — den forsvinner med sesjonen, men diffen er én linje.

## Tilstanden på maskinen nå

`cockpit.target` eier fire units, alle `enabled` + `active`, `NRestarts=0`:

| Unit | Hva | Verifisert |
|---|---|---|
| `cc-api` | Fastify :3100 | `/api/health` ok på db/firmBus/brain/workspace |
| `cc-web` | Next.js :3200 | `GET /` 200, 15 prosjekter i `/api/projects` |
| `cc-omnigent` | Omnigent-server :6767 | `firm` i `/v1/agents` |
| `cc-omnigent-host` | host-daemon | `/v1/hosts` → online |

Boot-stien er testet for seg: alle fire stoppet, deretter **bare**
`systemctl --user start cockpit.target` → alle fire oppe, 3200 svarte 200 på
~4 sekunder.

**Enhetene eier portene 3100/3200/6767.** Skal du kjøre `npm run dev` eller
`omnigent run --server local` i en pane: `systemctl --user stop cockpit.target`
først, ellers EADDRINUSE.

Installere (idempotente, versjonerte):
`_bin/cockpit-install-systemd.sh` og `_bin/omnigent-install-systemd.sh`.

## Omnigent — hva som var galt, og hva som gjenstår

Serveren svarte 200 hele dagen mens firmaet var nede. Årsak: den var startet
**uten `--agent`**, så `/v1/agents` inneholdt bare innebygde agenter (jcode,
debby, polly, `*-native-ui`). `firm` fantes utelukkende som et agent-id i gamle
sesjonsrader. Lærdommen: sjekk at **agenten** finnes, ikke at porten svarer.

Nå registrert: `firm`, agent-id `6346614472294e32bed58ccd556c657f`, harness
claude-sdk, skills dispatch + cross-review + brain-handoff, MCP fetch +
playwright, 1M kontekstvindu.

En sesjon er opprettet og venter: **«2026-10-16 command-center firm oppstart
(omnigent 0.18)»**, id `e1ed1495858948ee85dc0eddcfcb0c61`, workspace
`/home/nithu/code`. Status `idle`, `runner_online: true` — ingen melding er sendt.

(Den første sesjonen jeg laget, `651904a0`, ble slettet: Omnigent ble oppgradert
0.17.0 → 0.18.0 etterpå, og dens runner sto igjen på gammel kode med
`runner_online: false`. Den var tom, så ingenting gikk tapt.)

**GJENSTÅR, og det er det neste å gjøre:** send førstemeldingen. Det finnes
INGEN REST-rute for en brukermelding — `POST /v1/sessions` oppretter sesjonen,
men meldinger går over sesjonskanalen fra en klient. Så det må skje fra
web-UI-et på http://localhost:6767 eller fra en pane (`omnigent run -c` for å
fortsette denne sesjonen; `default_agent` er satt på bruker-nivå til
firm-katalogen, så `omnigent run` uten argumenter starter firmaet).

Forrige firm-sesjon døde med «I need clarification… what dispatch mechanism
should I use?». Den kjørte mot en server der dispatch-skillen ikke var
registrert. Nå er den det, så førstemeldingen er testen. Lim inn:

```
Oppstartssjekk. Ikke dispatch noe ennå, ikke rør shell.
Svar kort på tre ting:
1. Hvilke lane-agenter ser du, med prosjekt-cwd per lane?
2. Hvilke skills har du tilgjengelig?
3. Hvilket verktøy bruker du for å sende et oppdrag til én lane — nevn navnet.
```

Svarer den på alle tre: rammeverket er reelt oppe, og dispatch-problemet var
manglende agent-registrering. Spør den «hvilken mekanisme?» igjen: da er hullet
i harness-prompten `omnigent/firm/prompts/orchestrator-1.md`.

Én ting jeg ikke fikk verifisert: `/v1/agents` rapporterer `policies: 0` for
firm, mens `config.yaml` definerer tre guardrails (blast_radius med
gate_pushes, spawn_bounds med maks 10 dispatcher per tur,
headless_subagent_purpose_guard). Serverloggen klaget ikke. Det kan være at
API-et ikke eksponerer function-policies i det feltet — men det er UVERIFISERT,
og det er push-gaten som står på spill. Sjekk før du stoler på den.

## Star — lagt på is, og hvorfor

Operatørens beslutning etter måling: **legg på is.**

Live-knappen i `StarPanel.tsx` kalte LiveAvatar og lovet Star. Den ga
**«Emma (Friendly)»** — `LIVEAVATAR_AVATAR_ID` i `.env` slår opp som en preset
fra LiveAvatars eget bibliotek. Knappen er fjernet (PR #97), inntakskanalen
står (den virker — Påls testbeskjed ligger i `inbox/orchestrator-1.md`).

Star kan ikke streames i det hele tatt: hun er en `photo_avatar` på HeyGen-siden
(motorene `avatar_v/iv/iii`, rene videorender-motorer), HeyGens gamle
streaming-API er avslått siden 2026-03-31, og LiveAvatar er en annen plattform
med andre modeller, eget abonnement og ingen norske stemmer blant 97 presets.
Ekte sanntid: 99 USD/mnd, Star må lages på nytt som image-avatar fra et
1920x1080-bilde (dagens `star.jpg` er 256x256), og hun mister den norske
stemmen. Full vurdering med priser og belegg:
`00-claude-inbox/command-center/2026-10-16_star-live-avatar-muligheter.md`

HeyGen-abonnementet er **ikke** bortkastet, men det er et videoproduksjons-
abonnement: plan creator, 480 premium-kreditter, nullstilles 2026-11-15, ~4
kreditter per klipp ≈ 120 klipp i måneden. Det er det eneste stedet Star finnes
med norsk stemme. CLI-en gir `video-agent` (klipp fra tekst), `template`
(personaliserte klipp i bulk), `voice speech create` (stemmen som ren lyd),
`video-translate` (dubbing med stemmekloning), `lipsync`, `ai-clipping`,
`brand`. LiveAvatar-kontoen koster ingenting — den står på gratisnivå (10
kreditter).

KJØR ALDRI `heygen auth login`: den erstatter lagret OAuth med API-nøkkel og
flytter kontoen fra abonnement til API-kreditter. Status nå: OAuth, konto
kontakt@solarconsulting.no, gyldig til 2026-10-25, fornybar.

## Neste tre ting, i rekkefølge

1. **Merge PR #97** (grønn, CLEAN) — ellers overlever Omnigent-unitene ikke maskinen.
2. **Send førstemeldingen til firm-sesjonen** (teksten over) og avgjør om
   dispatch virker.
3. **Verifiser guardrails** — `policies: 0` på firm-agenten er uavklart, og
   push-gaten henger på den.

Alt annet som står åpent i firmaet: `2026-10-16-WRAPUP-alle-paner.md` §3 og §4.
Øverst der: Altinn-dokumentgapet (sju saker siden 12.09, ingen eier).
