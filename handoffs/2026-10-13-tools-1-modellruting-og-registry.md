# Handoff 2026-10-13 — tools-1: modellrutingen, det juridiske gulvet og registryet

**Alt er committet, ingenting er pushet.** To grener, seks nye commits. Ingen skitne filer i noen
av repoene, ingen containere startet, ingen prod-skriving. All prod-kontakt var read-only SQL med
`SET default_transaction_read_only = on`.

## Rettelse av min egen rapportering først

Jeg meldte «seks grener» i feeden og i flere meldinger til orchestrator-1 i dag. **Det er feil.**
Det er seks commits fordelt på **to** grener, og den ene bærer i tillegg to commits som fantes før
denne sesjonen. Riktig bilde:

| Gren | Repo | Mine commits | Arvet |
|---|---|---|---|
| `tools-1/model-routing-defaults` | Veldora (worktree `~/code/Veldora-ruting`) | `6d1547a` → `908e619` → `9c05119` → `ad3c34b` | – |
| `tools-1/registry-reverify-1013` | command-center | `0ba52f9` → `62060a1` | **`871a291`** (push-gate-herding, fra før sesjonen) + **`fee21a7`** (doctor guard-fiks, i morges) |

**Konsekvens for landing:** lander du `tools-1/registry-reverify-1013`, lander du samtidig
`871a291` og `fee21a7`. Det er antakelig ønsket — `fee21a7` er doctor-fiksen som gjør at
`tools-doctor.sh` slutter å melde FAIL på guard-blokkerte CLI-er — men du skal vite det før du
sier OK kjør, ikke etterpå.

## Veldora-grenen: `tools-1/model-routing-defaults`

Rekkefølgen er intern i grenen, så den landes som én enhet. Null filoverlapp med andre roller.

1. **`6d1547a` — modellruting.** `TASK_MODEL_DEFAULTS` har stått tom siden den ble innført, så alle
   24 oppgavetypene kjørte på `LLM_MODEL` (sonnet-5-5 i prod). Nå 11 rader. Målt mot 7 døgns
   prod-logg: **$8,92/uke spart, 40,6 %** ≈ $38/mnd.
2. **`908e619` — juridisk gulv.** En juridisk konklusjon kan ikke lenger rutes nedover. Var bare
   konvensjon; `LLM_MODEL=claude-haiku-4-5` ville sendt juridiske svar til Haiku uten protest.
   Håndheves nå ved ruting. Hardt krav fra admin-1.
3. **`9c05119` — slutt å spørre modellen om det koden alt finner.** `findContractTypes` plukker
   SSA-x/NS 84xx ut av kildeteksten med regex og overstyrer modellen uansett; prompten ba likevel
   om det samme «slik kilden sier det». Resultat: 67 skrivemåter av samme svar.
4. **`ad3c34b` — låser taket** orchestrator-1 satte som betingelse: ett kontraktsform-spørsmål,
   aldri ett per underfelt, batchbart.

**Verifisering:** 1 864 tester i suiten. `documents.test.ts` feiler 3–5 tester i full-suite men
passerer 6/6 alene — jeg kjørte en kontroll **uten** mine endringer og den feiler likt
(`Test timed out in 5000ms`), så det er en eksisterende flake under last, ikke rutingen. Fila
importerer ingenting modell- eller rutingsrelatert.

**NB om worktreet:** `~/code/Veldora-ruting/projects/anbud/crm/node_modules` er en **symlenke** til
`Veldora-dok` sin (identisk `package.json` bortsett fra én ekstra avhengighet der, altså et
supersett). Lenken er ikke committet. Ryddes worktreet, ryddes lenken med.

## command-center-grenen: `tools-1/registry-reverify-1013`

5. **`0ba52f9` — MCP-status settes fra en handshake, ikke fra en tilkoblingsfeil.** Dette er den
   viktigste av de to, og den er metodisk: registryet hadde **ingen definert måling**, så en
   tilkoblingsfeil kunne bli en dødsattest. I dag feilet det i begge retninger samtidig —
   sesjonsstarten meldte at alle fem MCP-er timet ut, mens registryet påsto at `fetch` hadde vært
   «død ved spawn siden juli». En direkte JSON-RPC `initialize` viste at fire av fem svarer
   (obsidian 20,8 s, filesystem 4,0 s, fetch 2,2 s, playwright 2,9 s); bare `fetch-docker` er nede.
   Målemetoden ligger nå i repoet som **`_bin/mcp-probe.py`**, så påstanden kan etterprøves.
6. **`62060a1` — stale 13 → 0.** Ni CLI-rader var målt tidligere samme dag uten at datoen ble
   flyttet; en halvferdig re-verifisering er samme løgn som en gammel, bare ferskere.

## Hva som er rettet i registryet (for den som leser det i morgen)

- **`github`-MCP er borte fra konfigen** (`grep -c githubcopilot ~/.claude.json` → 0). Sto som LIVE
  siden 28.07. Gjeninnføring er et valg, ikke en reparasjon.
- **Gmail sto som LIVE, men eksponerer kun `authenticate`** ⇒ NEEDS-AUTH. Krever operatør.
- **Claude Docs var ikke i registeret i det hele tatt.** Lagt inn.
- `sqlite3`-CLI sto som MANGLER med «installasjon = operatørvalg» — den er installert (3.45.1).
  Gaten er altså lukket, og `_bin/db-query.sh` kan bruke CLI-en direkte framfor python3-omveien.
- node/npm er 24.21.0/11.19.0 (sto 24.15.0/11.12.1). **`pnpm` ligger fortsatt i
  `~/.nvm/versions/node/v24.15.0/bin`** mens `node` er v24.21.0 fra `~/.local/bin` — pnpm kjører på
  en node-installasjon systemet ellers har forlatt. Harmløst i dag (npm-workspaces), men det råtner.
- `nexus-pg-rw` er fortsatt wired på prosjekt-scope ai-assistent til tross for DEPRECATED siden juni.
- §6 sa 81 `_bin`-filer; det er 109.
- **obsidian-MCP svarer på 20,8 s mot en 30 s-grense.** Det forklarer flakiness-historikken: den er
  ikke ustabil, den er for sen under last. Timer ut ved boot-storm, virker ellers.

## Åpne operatør-gater

| Gate | Hva som venter |
|---|---|
| **OK kjør** | De to grenene over |
| **Kvalitetssjekk før deploy** | `generate.brief` er rutet til Haiku. Det er 80 % av modellregningen og halverer den, men ingen har sammenlignet Haiku- og Sonnet-briefer på ekte anbud. `LLM_MODEL_GENERATE_BRIEF=claude-sonnet-5-5` reverserer. Sammenligningen koster API-kreditter |
| **API-kjøring** | Jeg anslo under $1 for å måle om de 1 802 genererte ut-tokenene mot ~700 lagrede faktisk er sløsing. Orchestrator-1 ba meg **ikke** bygge på tallet før det er målt. Det står umålt |
| **Nøkler/install** | Twelve Data + Context7 (API-nøkler), `yq` (install) — uendret fra før |
| **telegram-mcp** | Konto + session-string + systemd-enable. Scaffold klart på `tools-1/telegram-mcp-pilot` |
| **HeyGen-opprydding** | Slett 2 duplikater + `.tmp`-kopien, behold `heygen-translate`, stram `allowed-tools`. Lisens mangler i 3 av 4 installasjoner |
| **ms365 re-auth** | Uendret i 77 dager |

## Tildelt meg, ikke startet

**`llm_usage`-nøkkelen (bølge 2).** orchestrator-1 tildelte den til meg og sa den blir bølge 2. Jeg
spurte 13:04Z om jeg kunne starte og fikk ikke svar. Sizingen er målt: ikke «én kolonne pluss et
felt», men Payload-felt (= **migrasjon, operatør-gated**) + felt på `CompleteArgs` + tråding gjennom
**27 kallsteder i 21 filer**. Designfelle som må med: kolonnen må være **nullbar**, fordi 3 % av
forbruket ($0,66 av $21,99) kommer fra oppgaver som ikke har noe anbud — nyhetsbrief, juridiske svar,
live-hjelperen, ruting, de to kompetansebank-oppgavene. `tenant_id` bør vente på en tenant-tabell;
en streng på usage-raden blir en falsk nøkkel vi må migrere bort fra.

## Driftstilstand ved dagens slutt

- **24/7-autonomien er AV.** Alle åtte `firm-remote-executor@*` er `inactive dead` siden ~11:31Z,
  etter 6 døgns oppetid samme morgen. orchestrator-1 bekreftet at det var tilsiktet og
  operatørgodkjent (de kjører på betalt API, og dobbeltkjøring kostet oss tre rapportstier på
  formiddagen). De er **ikke disablet** — de kommer tilbake ved neste boot.
- **`firm-remote-verdict-watch` kjører alene** og har aldri behandlet én verdict (tom journal, tom
  `jobs/verdicts/done/`). Med executorene nede poller den en kø ingen fyller. Stopp krever operatør.
- `tools-doctor.sh`: **37 GREEN / 4 WARN / 8 FAIL**. De 8 FAIL er de stoppede executorene. Jeg lot
  dem være høye framfor å gjette at nedstengingen er permanent; er den det, hører det en
  expected-state-bryter i doctoren, ikke en dempet sjekk.
- `aslisten-crm-backup.service` sto `failed` i morges og ingen meldte det. Ikke min lane.

## Det jeg tok feil om i dag, så neste sesjon ikke bygger på det

1. **Jeg overskrev en peers rapport.** Den headless tools-1-executoren skrev 159 linjer til
   `00-claude-inbox/Veldora/rad/2026-10-13_tools-1.md` kl. 10:25; min Write 10:29:44 tok den. Ikke
   gjenopprettbar (utracket i Brain-git, ingen trash, ingen recovery-plugin). Executorens bevarte
   sammendrag ligger nå på den stien; mitt pane-arbeid ligger på `..._tools-1-pane.md`. **Regelen
   nå: pane skriver `..._<rolle>-pane.md`, headless skriver `..._<rolle>.md`, og den som finner
   stien tatt skal legge et tillegg ved siden av, ikke overskrive.**
2. **Jeg anbefalte å kutte fire brief-felt med 0,1–4,5 % treffrate, og trakk det selv.** Fraværet er
   produktet: `clarify.ts:100-112` gjør et manglende felt om til et avklaringsspørsmål til
   oppdragsgiver, og `tilbudsfrist` er én av to kilder i `compareDeadlines`' mismatch-sjekk
   (`deadlines.ts:41-76`), som faller til `insufficient` under to kilder. Tallene var riktige,
   slutningen feil. **Ikke kutt de feltene.**
3. **Sitathypotesen falt.** Jeg trodde ut-tokenene gikk til avskrift av sitater; målt er sitater
   8,2 % av lagret utdata.
4. **«Seks grener» var feil** — to grener, se tabellen øverst.
5. Jeg satte statusen `BORTE` i registryet, som fikk roster-generatoren til å hoppe over raden i
   stillhet. Statuskolonnen er maskinlesbar; nyansen hører i noten. Raden bruker nå `NEDE`.

## Korreksjoner fra andre som gjelder videre

- orchestrator-1 trakk «learning-1s innvendinger var målt feil» — **code-1s triage-tall er
  bekreftet** mot prod. Bygg på learning-1 sine tall.
- orchestrator-1 trakk koblingen «admin-1 gjør fristen autoritativ + tools-1 fjerner
  modellkandidaten». **Fristen skal ha flere kilder, ikke én autoritativ.**
- `tenders.notice_type` er COMPETITION/RESULT/PLANNING/CHANGE — Doffins **kunngjøringstype**, ikke
  kontraktstype. Ikke bytt `kontraktstype` mot den.
- Worktree-flommen i Veldora: 39 → 42 på åtte minutter, 134 → 137 grener, 4,5 G. **Ingenting
  slettet** — sletting er operatør-gated, og minst én worktree har upushet arbeid.
