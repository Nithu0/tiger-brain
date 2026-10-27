---
tags: [command-center, brain, distill, data-1, maaling]
type: verification-log
role: data-1
pane: synlig
dato: 2026-10-14
---

# Distill-hullet — målt, ikke antatt

**Målt 2026-10-14T09:28:49Z, command-center HEAD `12612b4`.** Alle tall under er fra
read-only-spørringer (`PRAGMA query_only=1`, `mode=ro`) mot
`~/.claude/projects/-home-nithu-code/state/memory.db` og
`command-center/data/brain-orchestrator.db`. SQL ligger i
`/tmp/claude-1000/.../scratchpad/distill-gap/` (q1-q3 + final.txt).
Ingenting er kjørt som koster penger, og ingen retry er startet.

## Kortversjonen

1. **Hullet er 518 rader fordelt på 10 dager** — ikke 457 på én. 467 av dem (13.10 + 14.10)
   er hele-dags-hull som catch-upen henter selv. De resterende 51, spredt over åtte dager
   fra juni til 12.10, blir **aldri** retryet av dagens kode. Det er med vilje, og det er
   grunnen til at de har ligget der i tre og en halv måned.
2. **Ja, det har feilet stille før — fire netter på rad i oktober.** 08., 09., 10. og 11.10
   feilet alle på `credit balance is too low`. 12.10 gikk gjennom (kontoen var fylt på), og
   så gikk den tom igjen. Natt til 14.10 er den femte, ikke den første.
3. **Varslingen finnes — i to kanaler — og begge sviktet i dag, hver av strukturelle grunner.**
   Det er funnet, ikke de 457 radene. Radene er en regning; den blinde flekken er en feil.
4. **Retry av alt koster USD 1,7 (anslag, spenn 1,5-2,5).** Hele hullet. Kostnaden er ikke
   argumentet mot å gjøre det.

## 1. Omfanget

| dag | udistillert | av totalt | klasse |
|---|---|---|---|
| 2026-06-13 | 3 | 11 295 | delvis |
| 2026-06-19 | 11 | 352 | delvis |
| 2026-06-21 | 3 | 51 | delvis |
| 2026-06-23 | 1 | 395 | delvis |
| 2026-07-01 | 4 | 33 | delvis |
| 2026-07-02 | 27 | 34 | delvis |
| 2026-07-13 | 1 | 64 | delvis |
| 2026-10-12 | 1 | 100 | delvis |
| **2026-10-13** | **457** | **457** | **HELE-DAGS-HULL** |
| 2026-10-14 | 10 | 10 | HELE-DAGS-HULL (i dag, i arbeid) |

Totalt: 15 516 verbatim, 14 998 objekter, **518 udistillert**. Én verbatim-rad gir nøyaktig
ett objekt (14 998 = antall distinkte `verbatim_row_id`), så differansen ER hullet — ingen
skjult dobbelttelling.

**Dager maskinen har vært av er IKKE problemet.** Den åpne posten i workspace-CLAUDE.md
(«distill-catch-up for dager maskinen er av») beskriver en risiko som koden alt har lukket:
`NightlyDistillTrigger` har en catch-up med 30 dagers tilbakeblikk og tak på 7 datoer per
fyring (`nightly-distill.ts:27-29`), og den har bevist at den virker — 07., 08., 09. og
11.10 ble hentet inn 12.10 som `catch-up day-hole`-tasks med prioritet 90. Posten kan
lukkes; det som gjenstår er noe annet.

## 2. To klasser hull, to helt ulike årsaker

**Hele-dags-hull** (457 + 10): catch-upen ser dem (`n = undistilled`) og retryer dem ved
neste nattlige fyring. Krever bare at API-kontoen har dekning.

**Delvise hull** (51 rader, 8 dager): catch-upen hopper over dem **med vilje** —
kommentaren i `nightly-distill.ts:176-182` sier det rett ut: en delvis destillert dag må
ikke utløse ny betaling hver natt, og «null back-refs» er den eneste signaturen som
beviselig betyr at hele dagen gikk tapt. Avveiningen er riktig for kostnad og feil for
dekning: 51 rader er nå permanent usynlige for recall med mindre noen kjører dem manuelt.

Minst én av dem er ikke et pengeproblem i det hele tatt. Raden fra 12.10 feiler på
validering, ikke på kreditt:

```
distillReal: MemoryObject failed validation: room_assignments[].type: invalid "feature"
```

Distilleren ber om `file | concept | workflow` (`distill-real.ts` SYSTEM_PROMPT pkt. 3),
LLM-en svarte «feature», og `distill.ts:148` avviser hele objektet. Kallet er betalt,
raden er tapt, og fordi den gjør dagen *delvis* vil catch-upen aldri prøve igjen. Det er
samme feilmodus som pay-and-discard-buggen fra 19.06-revisjonen
(`project_memory_loop_closed.md`, bug 3) — bare med en annen valideringsregel som gulv.

## 3. Har G4 feilet stille før? Ja — og varslingen er ikke fraværende, den er utett

Alle distill-tasks i `agent_tasks` (hele historikken; terminale rader prunes etter 7d, så
dette er alt som finnes):

| natt | dato distillert | status | forsøk | årsak |
|---|---|---|---|---|
| 08.10 | 07.10 | failed | 3 | credit balance too low |
| 09.10 | 07.10, 08.10 | failed | 3 | credit balance too low |
| 10.10 | 07.10, 08.10, 09.10 | failed | 3 | credit balance too low |
| 11.10 | 07.10, 08.10, 09.10 | failed | 3 | credit balance too low |
| 11.10 | 10.10 | **done** | 1 | (tom dag) |
| 12.10 | 07.10, 08.10, 09.10, 11.10 | **done** | 1-2 | kontoen hadde dekning |
| 13.10 | 12.10 | failed | 3 | `room_assignments[].type: invalid "feature"` (1 av 100) |
| 14.10 | 13.10 | failed | 3 | credit balance too low (457 av 457) |

Fire netter på rad feilet på tom konto før 12.10 reddet dem. Natt til 14.10 er femte
kreditt-feil, ikke første.

**Varslingskanalene finnes.** CLAUDE.md fører «failed-task-varsling (report-only)» som
gjenstående; det er ikke helt riktig. Det finnes to kanaler, og de gjorde begge jobben sin
dårlig i dag:

- **`_bin/morgenbrief.sh`** (crontab 07:30, Telegram via hermes) rapporterer
  `tasks: N done totalt, M failed totalt`. Den sendte brief 08., 09., 11. og 13.10 — altså
  nøyaktig de morgenene det hadde feilet — men linja sier bare et tall, aldri hva som
  feilet eller hvorfor. **I dag fyrte den ikke i det hele tatt.** Loggen
  (`~/.local/state/morgenbrief.log`) har ingen 14.10-rad, og heller ikke 10.10 eller 12.10.
  Cron har ingen catch-up: maskinen bootet ~07:45 i dag (backup-timeren fyrte 07:50), så
  07:30-jobben forsvant uten spor. Mønsteret er stabilt — de tre dagene uten brief er tre
  dager med sen boot.
- **`_bin/global-session-context.sh`** skriver en `BRAIN-VARSEL`-linje inn i session-start.
  Den virker: jeg kjørte den nå, og den printer
  `BRAIN-VARSEL (report-only): 1 failed agent_task(s) — kjør _bin/brain-doctor.sh`.
  **Men ingen pane fikk den i dag.** `/tmp/firm-hook-session-start.log` har sju linjer
  `global-session-context failed/timed out` kl. 07:52:34-07:52:41. Scriptet tar 6,97 s alene
  (`/usr/bin/time`), hook-taket i `firm-hook-session-start.sh` er `timeout 10`, og når åtte
  paner starter samtidig og slåss om node + better-sqlite3 + ollama, ryker taket. Da faller
  **hele** orienteringsblokken bort, ikke bare varsellinja.

Begge kanalene er report-only og det skal de være. Poenget er at natt til 14.10 ga null
operatør-synlig signal: ingen Telegram, ingen session-start-linje i noen pane.

**To blinde flekker til, verdt å kjenne:**

- `brain-doctor.sh` sier `distill day-holes OK ingen (30d)` akkurat nå, med 457 udistillerte
  rader fra i går i basen. Hull-sjekken ekskluderer i går med vilje (i går er nattens
  primærjobb, og ville ellers vist falskt hull hver morgen før 03-kjøringen). Resultatet er
  at den høyeste linja om et 457-raders hull er `agent_tasks WARN 2 FAILED`.
- Session-start-varselet teller **1** failed, doctoren teller **2**. Forskjellen er
  recovery-regelen: session-context demper en failed distill-rad så snart datoen ikke lenger
  er et *helt* hull, doctoren krever at datoen er *fullt* destillert. Giftraden fra 12.10
  faller derfor ut av det varselet operatøren faktisk ser ved session-start, permanent.

## 4. Retry-veien (skrevet, ikke kjørt)

Alle tre alternativene er idempotente: `distillDay` forhåndsfiltrerer rader som alt har et
`memory_objects`-backref med samme `source_type` + `prompt_version`, så en re-kjøring betaler
**bare** for de feilede radene. Ingen av dem kan dobbelt-destillere.

**Forutsetning for alle tre: API-kontoen må ha dekning.** Det er operatør-gaten. Uten
påfylling feiler de likt, bare raskere.

### A — gjør ingenting (anbefalt for de 467)

Neste nattlige fyring (≥03:00 UTC, dvs. natt til 15.10 — `nightly-distill:last_fired` er
alt stemplet `"2026-10-14"`) publiserer av seg selv:

- `distill yesterday` for 14.10, prioritet 100
- `catch-up day-hole` for 13.10, prioritet 90 (hele-dags-hull, innenfor 30 dager)

Ingen kommandoer, ingen risiko, ~USD 1,5. Dette er sporet catch-upen ble bygget for, og det
er bevist i drift (12.10).

### B — lukk 13.10 i dag, uten å vente på natta

Re-kø den feilede raden i min egen lane (`brain-orchestrator.db`). Worker-en claimer
`status='queued'` på neste syklus (heartbeat 0m nå):

```sql
-- IKKE KJØRT. Krever at kontoen har dekning først.
UPDATE agent_tasks
   SET status='queued', attempts=0, claimed_by=NULL, claimed_at=NULL,
       lease_expires_at=NULL, last_error=NULL,
       updated_at=strftime('%Y-%m-%dT%H:%M:%fZ','now')
 WHERE id='50ddb502-2628-4ee8-babd-40c8b71d5a54';   -- {"date":"2026-10-13"}
```

Verifisering etterpå, ikke på statuskode: `SELECT count(*) FROM verbatim_exchanges v WHERE
substr(v.created_at,1,10)='2026-10-13' AND NOT EXISTS (SELECT 1 FROM memory_objects m WHERE
m.verbatim_row_id=v.id);` skal gå fra 457 til 0.

### C — de 51 permanent tapte radene (eget valg)

Disse kommer aldri av seg selv. De åtte datoene må køes eksplisitt; `distillDay` betaler da
kun for de 51 radene, ikke for de ~12 300 som alt er destillerte på samme dager:

```sql
-- IKKE KJØRT. Én rad per dato; worker-en plukker dem i prioritetsrekkefølge.
INSERT INTO agent_tasks (id, role, department, prompt, payload, priority, sla_seconds, status)
SELECT lower(hex(randomblob(4)))||'-catchup-'||d, 'distill', 'brain',
       'distill manual backfill (delvis hull)', json_object('date', d), 50, 3600, 'queued'
  FROM (SELECT '2026-06-13' d UNION ALL SELECT '2026-06-19' UNION ALL SELECT '2026-06-21'
        UNION ALL SELECT '2026-06-23' UNION ALL SELECT '2026-07-01' UNION ALL SELECT '2026-07-02'
        UNION ALL SELECT '2026-07-13' UNION ALL SELECT '2026-10-12');
```

Forventet utfall: ~50 av 51 lander. Minst **én vil feile igjen** — giftraden fra 12.10
(verbatim id 14960) feiler på validering, ikke kreditt, og gjør det hver gang til
`distill.ts:148` tåler en ukjent romtype. Noen av juni/juli-radene kan ha samme årsak; det
vet jeg ikke, fordi `last_error` for de nettene er prunet bort for lenge siden.

## 5. Kostnad

Haiku 4.5 (`claude-haiku-4-5`, `max_tokens: 1024`, ingen prompt-caching — systemprompten på
~1,6k tegn er under minste cachebare prefiks), USD 1,00/MTok inn og 5,00/MTok ut.
Kropp trunkeres til 4 000 tegn (`TRUNCATE_CHARS`), så lange rader koster ikke mer enn taket.

| post | mengde | USD |
|---|---|---|
| input, kropp (140,4 ktok) + prompt-overhead (359 ktok) | 500 ktok | 0,50 |
| output, 518 × ~450 tok (målt snitt 1 268 tegn lagret felt) | 233 ktok | 1,17 |
| **sum, alle 518 rader** | | **≈ 1,7** |
| herav 13.10 + 14.10 (467 rader, spor A/B) | | ≈ 1,5 |
| herav de 51 delvise (spor C) | | ≈ 0,17 |

**Kryss-sjekk mot målt historikk:** juni-backfillen kostet USD 42 for 11 295 rader =
0,0037/rad (`project_memory_loop_closed.md`). 518 × 0,0037 = **USD 1,92**. To uavhengige
metoder innenfor 15 % av hverandre. Jeg vil regne med **1,5-2,5** og ikke mer.

Anslaget er mitt eget, i min egen enhet. tools-1 sine 0,016-0,05 er per anbud i Veldora og
gjelder en annen oppgavetype med annen modell — tallene kan ikke sammenlignes.

## 6. Det som egentlig bør gjøres noe med

Rangert etter hvor mye framtidig tap det stopper, ikke etter hvor lett det er:

1. **Hook-taket på 10 s.** Åtte paner × 7 s script = orienteringsblokken faller bort for
   alle, inkludert varsellinja. Dette er kanalen som skal fange nettopp slike netter, og i
   dag fanget den ingenting. (`_bin/firm-hook-session-start.sh` — tools-1/infra-1 sin lane,
   ikke min; jeg har ikke rørt `_bin/`.)
2. **Morgenbriefen har ingen catch-up.** Cron 07:30 + sen boot = ingen brief, ingen spor
   bortsett fra en manglende loggrad. Tre av de siste fem dagene. En systemd-timer med
   `Persistent=true` ville fyrt ved boot i stedet.
3. **Giftrad-mønsteret.** Én validert-bort rad gjør dagen delvis, og delvise dager retryes
   aldri. Det er den strukturelle måten rader går tapt permanent — uavhengig av kreditt.
   Minste fiks: la `distill.ts:148` degradere ukjent `type` til `"concept"` i stedet for å
   kaste hele objektet. Det er en kodeendring, ikke dagens oppdrag, men den ligger i min lane.
4. **Briefen sier tall, ikke årsak.** `M failed totalt` er ikke handlingsbart. `last_error`
   finnes i basen; den første linja av den er det som trengs.

Og det underliggende, som jeg er enig i: 13.10 er fanget verbatim og ingenting er tapt av
rådata. Men læringsloopen leverte ikke på den tetteste dagen vi har hatt, og den hadde
feilet fire netter før det uten at noen så det. Catch-upen er grunnen til at vi ikke har
mistet mer — den er det som faktisk har virket her.

## 7. Kilder

- `q1-daily-gap.sql`, `q2-totals.sql`, `q3-cost.sql`, `final.txt` i scratchpad
  `/tmp/claude-1000/-home-nithu-code-command-center/369c4bbc-.../scratchpad/distill-gap/`
- `agent_tasks`-historikk: `sqlite3 "file:data/brain-orchestrator.db?mode=ro" "SELECT created_at,status,payload,attempts,last_error FROM agent_tasks WHERE role='distill' ORDER BY created_at DESC"`
- `journalctl --user -u brain-worker --since "2026-10-14 00:00"` (457 per-rad-feil + task-failed-linja 05:54:37.932Z)
- `packages/brain-orchestrator/src/triggers/nightly-distill.ts:27-29, 176-182` (catch-up-grenser + hvorfor delvise dager hoppes over)
- `packages/memory-engine/src/distill-day.ts` (idempotens-forhåndsfilter), `distill-real.ts:130` (`TRUNCATE_CHARS`), `distill.ts:148` (romtype-validering)
- `packages/memory-engine/src/distiller/haiku-distiller.ts:27,34` (modell + `max_tokens`)
- `_bin/morgenbrief.sh:28-57` + `~/.local/state/morgenbrief.log` (ingen 14.10/12.10/10.10)
- `_bin/global-session-context.sh:294-350` (BRAIN-VARSEL), `/tmp/firm-hook-session-start.log` (7 × timeout 07:52)
- `_bin/brain-doctor.sh:100-170` + kjøring 2026-10-14T09:26Z (`WARN 2 FAILED`, `day-holes OK`)
- `_bin/rag-recall.sh command-center "<veldora-spørring>"` → nyeste treff er 2026-10-12; 13.10 er usynlig for recall
- Prising: Haiku 4.5 USD 1,00/5,00 per MTok (claude-api-skillen, modelltabell)
- `project_memory_loop_closed.md` (19.06: pay-and-discard, USD 42 / 11 295 rader, durable verdicts)

— data-1 (synlig pane), 2026-10-14

---

# RESULTAT — spor B kjørt 10:13-10:55Z

Operatøren fylte på kontoen. Task `50ddb502` re-køet (ikke ny rad), claimet av
`brain-worker:3506` innen 12 s, kjørte 42 min på ~11-13 rader/min.
`extendLease` holdt leaset friskt hele veien, så reaperen rørte den ikke.

**456 av 457 rader for 13.10 er destillert.** Verifisert mot virkeligheten, ikke mot
statuskode: `rag-recall.sh command-center` med Veldora-spørring returnerer nå innholdet fra
13.10 (bølge-0-ordren, `documentsUrl`-funnet, rapportstiene). Før kjøringen var nyeste
treff 12.10. Gårsdagen er lært.

**Én rad står igjen, og den feilet ikke på kreditt.** Verbatim id `15061`, 4 708 byte,
`conversation 0dbd7d6e`, ply 1-2 — selve VELDORA STRATEGIRÅD-ordren («LETSGOOOO KJØØØØØR»),
dagens tetteste og mest kontekstbærende rad:

```
haiku-distiller: LLM did not return valid JSON (SyntaxError: Unexpected end of JSON input)
```

Tre forsøk, samme feil, deterministisk. Mest sannsynlig årsak er `max_tokens: 1024`
(`haiku-distiller.ts:34`): en tett, strukturert ordre med sju seksjoner gir en lang
`entities`/`decisions`/`next_actions`-liste, svaret kuttes midt i JSON-en, og parseren
ser bare «uventet slutt». Jeg kan ikke skille trunkering fra søppel ut fra feilmeldingen,
**fordi `stop_reason` aldri leses** — `haiku-distiller.ts:123-124` går rett fra
`extractText` til `parseDistilledFields`. Det er derfor diagnosen koster en ny kjøring
hver gang i stedet for å stå i loggen.

**Dette er giftrad-mønsteret, nå bekreftet i to varianter:** 12.10 feiler på validering
(`room_assignments[].type: invalid "feature"`), 13.10 på trunkert JSON. Begge er
pay-and-discard, begge gjør dagen *delvis*, og delvise dager retryes aldri. Mønsteret er
ikke kreditt — det er at distilleren mangler gulv for to normale LLM-utfall.

**Status etter kjøringen** (målt 2026-10-14T10:56Z):

| dag | udistillert | kommentar |
|---|---|---|
| 13.10 | **1** | giftrad 15061, trenger kodefiks, ikke ny kø |
| 12.10 | 1 | giftrad 14960 (validering) |
| 8 dager juni-juli | 49 | spor C, urørt |
| 14.10 | 99 | i dag, tas av nattens ordinære kjøring |

15 605 verbatim / 15 454 objekter. Faktisk forbruk for 456 rader ligger på linje med
anslaget (USD ~1,5); ingen overraskelse mot budsjettet.

**To fikser, begge små, begge i min lane — ikke startet:**

1. `distill.ts:148` degraderer ukjent `room_assignments[].type` til `"concept"` i stedet
   for å kaste hele objektet. Lukker 12.10-varianten.
2. `haiku-distiller.ts` leser `message.stop_reason`; er den `"max_tokens"`, prøv én gang
   med dobbelt tak og si det i feilmeldingen ellers. Lukker 13.10-varianten og gjør
   framtidige trunkeringer lesbare uten å betale for en ny kjøring.

Begge er testbare mot de to kjente radene — de er en gratis regresjonssuite som alt ligger
i basen.

**Liten vorte verdt å kjenne:** `rag-recall` merker treff med `memory_objects.created_at`,
altså destilleringstidspunktet. Alt fra 13.10 vises nå som `[2026-10-14]`. Innholdet er
riktig, datostempelet villeder — relevant for enhver som leser recall-output som en
tidslinje.
