# Cockpit — hva flaten skal vise

Samlet av orchestrator-1 fra panenes wrap-svar 14.10. Dette er **råmateriale for en PRD**, ikke
en plan. Regelen panene fikk: hva hører hjemme på en flate, og hva er bevis som hører i en rapport.

Operatørens egne krav: *«effektivt og ai smart dashboard … en personlig assistent vi kan prate med
å sparre med til en hver tid … omnigent for oversikten og se hvordan ai agentene jobber i bakgrunn,
en slags cockpit … ikke for mye støy men vi får all infoen vi vil fram og illustrert på en fin måte
når vi vil ha det.»*

## Konvergens — nevnt uavhengig av flere paner

### 1. Åpne gater, med eier og ALDER
Begge som har svart satte denne først. Operatøren ba bokstavelig om «hva venter på dem».

learning-1s presisering, som er designkravet og ikke en detalj: **en gate som har stått i 30 timer
skal se annerledes ut enn en som ble åpnet i dag.** I dag finnes lista bare som avsnitt spredt i
syv inbokser, og alder finnes ingen steder.

Kjente gater akkurat nå: Actions spending limit · fire portalvilkår som må åpnes i nettleser ·
hyyr har ingen publiserte vilkår (risikoavgjørelse, ikke lesing) · `ivalua.com` som egen vert ·
vaktpost-variant A/B/C · regenerering av de 34 dokumentene · compare-brief-models · de 13 briefene ·
sletting av seks landede grener.

### 2. «Startet jobben i det hele tatt?» — kontodetektoren
Begge nevnte den. **RETTELSE 13:04Z: den er ikke hjemløs — tools-1 har bygget den.**
`_bin/ci-guard.sh` + `_bin/tests/ci-guard.sh`, commit `ed933d7`.

tools-1 tok learning-1s signatur og **skjerpet den på ett punkt som betyr noe:** nekt må måles på
**jobbnivå, ikke kjøringsnivå.** Run `38567566333` varte 14 s (kø-tid) mens jobben varte 2 s med
null steg — «varighet < 3 s» på kjøringen ville bommet. **Det som bærer alene er
`steps.length == 0` på en jobb med `conclusion = failure`.** Frisk sammenligning: run
`38540282483` har 10 steg.

Målt mot levende data: **22 nektede jobber** — command-center 6, Veldora 13, aslisten-crm 3.
ai-assistent hadde ingen feilede kjøringer. Første nekt i aslisten 11:27:21Z, altså etter
09:50-bruddet: taket holdt seg nådd.

Designvalg tools-1 tok, og som bør overleve inn i flaten: **exit 2 ved «kunne ikke måle», ikke 0.**
En kanal som ikke klarer å måle skal ikke være uskillbar fra en som måler «alt bra».

Som tile: «CI nektet start siden 09:50Z — fakturering».

Hvorfor den er prinsipiell og ikke en bugfiks: **en tjeneste som er oppe men ikke kan betale ser ut
som en tjeneste som er oppe.** To tomme kontoer på én dag, begge funnet ved flaks.

### 3. PR-liste med dom og ærlig årsak
`PRList` finnes allerede i `apps/web`. Begge påpekte at en liste uten dom er støy.
- paal-1: #38 landbar · #35/#36/#37 trenger arbeid, én linje hver. Fire PR-er har ligget siden
  28.08 uten at det er synlig noe sted.
- learning-1: **en flate som viser rødt uten å si at rødt i dag betyr fakturering, er verre enn
  ingen flate.**

## Enkeltbidrag

- **Backup-helse, én rute** (paal-1): siste kjøring, exit-kode, og om avvikssettet er DET KJENTE
  eller noe nytt. Kilde: `systemctl --user show aslisten-crm-backup.service` + `x-backup-sammendrag`.
  Merk: først verdt å ha **etter** PR #46 — før den kunne ruten bare vise rødt, og en rute som
  alltid er rød er en rute ingen ser på.
- **Triage-beslutningstall** (learning-1): AUC 0,577/0,549/0,575 mot `scope_score` 0,678 ·
  verdidekning 50,9 % · 13 av 30 ja er førkonkurranse-dialog · `documents` = 0 rader.
  Ligger i en markdown-fil i en gren, der de leses én gang.
- **Én avledet rad fra portalarbeidet** (learning-1, mot det orchestrator gjettet): «dokumentdekning
  0 av 1184 — høyst 70,3 % lovlig mulig, 0 % klarert». Resten av vilkårsarbeidet hører IKKE på en
  flate: det er en engangsklarering, ikke en tilstand.

## Hører IKKE på flaten

Riggkjøringer · heygen-transportanalysen · designnotaters A/B/C-drøfting · vilkårsresonnementet.
Det er bevis og resonnement, og hører i rapporten de står i. Fra heygen hører én linje:
«venter operatørvalg: OAuth-kobling».

## Dør stille hvis ingen plukker det opp

| Sak | Eier i dag | Hvorfor det dør |
|---|---|---|
| **7 saker `READY_FOR_ALTINN` uten at dokumentene finnes** | ingen, siden 12.09 | ser grønt ut der det vises; kan treffe en ekte kunde (Pål i Brønnøysund) |
| `issues/054` målvariabelen | ingen, siden 13.10 | gater ALT rangeringsarbeid; HITL fordi det handler om hvorfor operatøren sa ja |
| ~~Kontodetektoren~~ | **tools-1, `ed933d7`** | ~~hjemløs~~ — bygget og målt 13:04Z, signaturen skjerpet til jobbnivå |
| `issues/055` `profileN` | code-1s lane | vet ikke om den lane har utfører |
| Vaktpost-variant A/B/C | paal-1 venter | **rekkefølge betyr noe**: velges A etter at regenerering har startet, melder vaktposten grønt på et nytt tap |
| Måleriggen `run-triage-baseline.sh` | learning-1 | krever Railway-innlogging, kjørt av én person — «en oppskrift ingen har prøvd», ikke reproduserbarhet |

## Flaten som finnes

`command-center/apps/web` — 18 komponenter, **siste endring 13. juni 2026**, kjører ikke.
`OrchestratorPanel` · `TerminalConsole` · `BrainPanel` · `BrainHealthPanel` · `PRList` ·
`DeskStatus` · `RouterPanel` · `AuditTrail` · `PushControls` · `ProjectActivity` · `CommitSuggest` ·
`IssueDraft` · `MobileTabBar` · `EngineSelector` · `OperatorSelector` · `AuthGate` · `InstallPrompt` ·
`SwRegister`.

Avstanden til det operatøren beskrev er ikke 18 komponenter. Den er: slå den på, koble den til
dagens virkelighet, legg til alder på gater, og gi den en samtaleflate.

## Tillegg 13:04Z — de 13 briefløse, målt av tools-1

- **Alle 13 har `status = screening`.** Statusleddet utelukker altså ingen — beslutningsleddet gjør
  hele jobben. admin-1s felle 1 bekreftet, felle 2 utløses ikke for disse.
- **9 av 13 har `tenders.deadline = NULL`**, så et frist-ledd ville utelukket dem også.
- 23 flere besluttede mangler brief, men alle er `NO_BID`/`declined` og holdt utenfor.

Fiksen i `brief-coverage.ts:39` er tools-1s, og ventes til CI er tilbake.

## Tillegg 13:14Z — DATAKILDEFELLE som ville gjort cockpiten løgnaktig

tools-1 rettet seg selv, og rettelsen er viktigere enn feilen. Dette er et **designkrav for flaten**,
ikke en bugrapport.

**I `payload_jobs` overlever bare feilene.** `payload 3.90.2` defaulter `deleteJobOnComplete: true`
(`dist/config/defaults.js:64` og `:135`), og CRM-en overstyrer det ikke
(`payload.config.ts:199-203` setter bare `tasks` og `access`). En jobb som lykkes blir slettet.

Tre konsekvenser, alle målt:

1. **«331 åpne jobber» er ikke et etterslep.** Det er oppbrukte lik — mulighetene deres har brief nå.
   Tallene gjennom dagen (301 → 332 → 437) var riktig merket, men lette å lese som ventende arbeid.
   **En tile på det tallet lyver**, og den ville lyvd verre jo bedre systemet gikk.
2. **Gjennomstrømning kan ikke måles fra tabellen.** Spørringen «hvor mange brief-jobber fullførte i
   dag» gir **0 rader** — samtidig som 83 modellkall lyktes og 65 briefer ble skrevet. Alt som bygges
   på `payload_jobs` ser en verden der alt feiler.
3. **Suksess må måles i `llm_usage` (`ok = true`) og `briefs`.** Det er de to kildene som stemte hele
   dagen.

**Regel for cockpiten, utledet:** hver tile skal oppgi hvilken tabell den leser, og den som bygger
tilen skal svare på ett spørsmål før den landes — *overlever suksess i denne kilden, eller bare feil?*
En kilde der bare feil overlever kan brukes til å telle feil, aldri til å måle helse.

Rammer også data-1, som bygger retry-arbeid på samme antakelse.

---

## Utledet av orchestrator-1 fra rapportene til de fire som ikke rakk å svare

**Merknad om kilde:** dette er mitt utdrag fra `infra-1`, `trading-1`, `admin-1` og `data-1` sine
leveranser i dag — ikke deres egne svar på wrap-spørsmålet. De gikk stille etter 13:14Z. Behandle
det som en hypotese om hva de ville sagt, og la dem korrigere det før noe bygges.

### infra-1
- **Produksjonsvakt-status.** `anbud-vakt.service` kjører og har vært stille siden 15:00 i går.
  En vakt som er stille og en vakt som er død ser likt ut på en flate uten tidsstempel for *siste
  vellykkede sjekk*. Det er samme feilmodus som morgenbriefen som ikke fyrte.
- **Avledet kravliste per PR.** `expected-checks.py` regner ut hvilke sjekker en PR *skal* ha.
  På flaten: «denne PR-en krever crm, migrasjonssnapshot, royktest, dashboard, schemas, website».
  Verdt å vise fordi en prosa-setning avvæpnet porten én gang i dag (#165).
- Hører IKKE på flaten: unionskjøringens logg, fixturtabellene for leak-scan.

### trading-1
- **Direkte pusher til main.** `8ba6192` gikk inn 12:51Z uten PR og uten checks. Dette er en tile:
  «commits på main som ikke passerte porten, siste 7 dager». Oppdaget i dag kun fordi noen så etter.
- **Røyktest-portens tilstand:** rådgivende eller blokkerende, og når den sist faktisk kjørte.
- Hører IKKE på flaten: de tre unionskjøringene, Node-versjonsmatrisen.

### admin-1
- **Juristgater som påvirker utfall, ikke kode.** `data/legal/terskelverdier.json` er tom;
  `LIK_TERSKEL_ER_OVER` og `FRIST_REGEL.hjemmel` er `ANTAKELSE`. De endrer ikke oppførsel i dag,
  men de betyr at `vurderPart` svarer `ukjent`. På flaten: «2 juridiske forutsetninger uverifiserte».
- **Fristkvalitet per anbud:** `consistent` / `mismatch` / `insufficient`. Maskineriet finnes og
  varsler nå, men tilstanden vises ikke samlet noe sted.

### data-1
- **Destilleringsdekning.** 52 rader over 10 dager udestillert; 2 dager dødbrev på `attempts 3/3`.
  På flaten: «hjernen har ikke lest 2 av de siste 10 dagene» — det er det operatøren faktisk bryr
  seg om, ikke radtallet.
- **Hva natten kostet.** Kan ikke besvares i dag: `usage` fra API-svaret kastes uten å lagres, og
  cost-guard melder «meter pending». **Det er en manglende tile og en manglende kilde på én gang.**

---

## Oppsummert: de åtte tilene materialet peker på

| Tile | Kilde | Status på kilden |
|---|---|---|
| Åpne gater, med eier og **alder** | finnes ikke — må bygges fra bussen | mangler |
| Nektet CI-jobb (fakturering o.l.) | `_bin/ci-guard.sh` `ed933d7` | **bygget i dag** |
| PR-er med dom og ærlig årsak | `PRList` finnes i `apps/web` | finnes, vises ikke |
| Kontosaldo / tjeneste kan betale | ingen | mangler |
| Backup-helse (kjent avvik vs nytt) | `systemctl show` + `x-backup-sammendrag` | finnes etter #46 |
| Hjernens dekning (dager ulest) | `memory.db` | finnes |
| Brief-dekning og gjennomstrømning | `llm_usage` + `briefs` — **ikke `payload_jobs`** | finnes |
| Commits på main utenom porten | `git log` + PR-kobling | finnes |

Og den niende, som operatøren ba om og som ingen av panene nevnte fordi den ikke er en tile:
**en samtaleflate å sparre med**, med HeyGen-avatar som ansikt. Den er ikke avledet av dagens
arbeid — den er grunnen til at de åtte over skal være *spørsmålsbare* og ikke bare synlige.

### Tillegg 14:41Z — samme felle, andre form: `payload_jobs` duger ikke som LIVSTEGN

tools-1 ble bitt av sin egen rettelse. Prod hadde ikke gjort et modellkall på to timer, så de
spurte om planleggeren køet noe i det hele tatt: **ingen jobb opprettet siden `10:00:06Z`** — fire
timer og førti minutter. Det ser ut som en død scheduler.

Den var frisk. `tenders` har rader så sent som `13:30:04Z`, tre og en halv time etter siste
overlevende jobbrad. Jobbene kjøres, lykkes og slettes; de eneste radene igjen er likene fra
kredittstansen, alle fra før 10:00.

**`max(created_at)` i `payload_jobs` er ubrukelig som livstegn** — og det er den naturlige tabellen
å velge. En «lever prod?»-tile bygget på den rapporterer **død siden 10:00 mens alt er friskt**.
tools-1 var to spørringer fra å melde nettopp det.

**Livstegn måles på kjeden:** `tenders` → `opportunities` → `briefs`, pluss `llm_usage` for
modellbruk. De fire holdt hele dagen.

Dette er andre gang samme kilde produserer en motsatt løgn: først «331 jobber venter» (de er døde),
nå «ingenting har skjedd siden 10:00» (alt har skjedd). **En kilde der bare feil overlever lyver i
begge retninger** — den overdriver arbeidsmengden og underdriver aktiviteten samtidig.

---

## Ekte svar fra data-1, infra-1 og trading-1 (17:05Z) — erstatter mitt utdrag for disse tre

Mitt utdrag lenger oppe var en hypotese. Tre av fire panene har nå svart selv, og **de rettet meg
på to punkter.** admin-1 står fortsatt ute.

### data-1 retter min tile-formulering

Jeg skrev tilen som «hjernen har ikke lest 2 av de siste 10 dagene». **Feil, og den lyver i motsatt
retning av `payload_jobs`:** 456 av 457 rader for 13.10 **er** lest. Dagen mangler én rad.

> **Tell rader, ikke dager.** En tile som teller dager overdriver tapet like grovt som «331 jobber
> venter» overdrev arbeidsmengden.

Riktig tall: **2 enkeltrader døde + 49 rader spredt i åtte delvise juni/juli-dager.**

**Kildetesten anvendt på egen lane:** `verbatim LEFT JOIN memory_objects` består — suksess overlever
som egen rad, og `verbatim_no_delete` aborterer DELETE. Men **`agent_tasks` består ikke**: den prunes
etter `BRAIN_TASK_RETENTION_DAYS` (default 7) for *både* `done` og `failed`. Derfor kunne
juni/juli-dødbrevene ikke diagnostiseres i dag — **årsaken var slettet.** Feilhistorikk som fordamper
er samme klasse som en logg i `/tmp`.

**Forbehold med tenner:** en task som destillerte 456 av 457 står som `failed 3/3`, fordi
`executors.ts` kaster så snart `errors.length > 0`. **En statustile på den kilden viser rødt på
99,8 % suksess.** Fiksen må inn før tilen, ikke etter.

**Og en kanal må logge sin egen fyring et sted som overlever:** hook-loggen ligger i `/tmp` og tømmes
ved boot. Beviset på at varslingen ikke nådde fram i natt fantes bare til neste omstart.

### infra-1 — og svaret på agent-skippene er verre enn antatt

Tiler de vil ha, med kilde: nektet CI-jobb · åpne operatørgater (`gh pr list` + `git log origin/<gren>..<gren>`)
· **siste ekte portkjøring med steg-antall** («steg-antall er det som skiller ekte grønn fra nektet
grønn — uten det lyver tilen») · UDEKKET per port · **prod-modellkall siste døgn** (`llm_usage.error_code`
— «dette er tilen som ville tatt 26-timers-stansen»).

**Q1 — er agent-skippene med vilje? NEI.** `ANTHROPIC_API_KEY` **finnes som repo-secret** i
Solar-Consulting (opprettet 30.08) og brukes alt av `agents.yml:390`. `anbud.yml`s royktest-jobb
sender den bare ikke videre. **En utelatelse, ikke en kostnadsbeslutning** — og usynlig fordi testen
blir grønn. Én linje i jobbens `env:` lukker den; *da* blir kostnadsspørsmålet en ekte operatørbeslutning.

**Q3 — omfang: 11 tasks degraderer stille, kjørt av 10 av de 27 grønne testene.** Ikke bare `smoke-brief`.

**Q2 — deres løsning:** ikke la testen feile, men **ikke la den være grønn stille**. En test som
degraderer skal skrive et UDEKKET-felt i oppsummeringen, samme mønster som porten alt bruker.

### trading-1 — porten etterprøvd, og én ubehagelig mekanisme

504 s veggklokke på runner (mot 640 s margin). Fire kjøringer: 261 s (Node 22) · 340 s (Node 24) ·
400 s (infra-1) · 504 s (runner) — **alle 27/0/3, exit 0.**

> **#162 ble merget mens dens egne sjekker var røde.** De fire 2-sekunders faktureringsfeilene sto
> på PR-en, og den ble merget likevel. Den første blokkerende porten gatet altså ikke sin egen PR.

Utfallet er riktig — etterprøvingen på main er grønn — men mekanismen står: **en obligatorisk check
som var rød kunne merges i dag.** Push-veien til main var heller ikke fail-closed (`8ba6192`), mens
PR-veien var det.

### Ny tile som følger av dette

| Tile | Kilde | Hvorfor |
|---|---|---|
| **Merget med rød/manglende obligatorisk check** | `gh pr list --state merged` + `statusCheckRollup` | skjedde i dag på selve portens egen PR |
| **Commits på main uten PR** | `git log origin/main` + PR-kobling | `8ba6192`, 12:51Z |
