# Overlevering — infra-1, 2026-10-14 (økt 09:23Z–12:15Z)

Alt under er målt i denne økten. Ingenting er pushet; to grener venter «OK kjør».
Hver linje har et sted å etterprøve den.

## 1. Røyktest-porten i Veldora (anbud)

| Ting | Status | Bevis |
|---|---|---|
| `royktest`-jobb på `origin/main` | **FINNES IKKE ENNÅ** | `git grep '^  royktest:' origin/main -- .github/workflows` tom |
| Unionskjøring mot `main f4cb3f0` + trading-1s tre filer | **GRØNN** | 27 grønn / 0 rød / 3 skip, exit 0, **400 s**, `check-server-version: ok, Postgres 18 (180006)` |
| Avledet checkliste etter merge | **målt lokalt** | anbud-PR: `crm, migrasjonssnapshot, royktest, dashboard, schemas, website`. README-PR: `schemas, website` |
| «Fjern advisory-markøren» (steg 3 i ordren min) | **IKKE-OPPGAVE** | markøren finnes ikke i grenen; porten blir blokkerende av seg selv ved merge |
| PR #162 åpnet 12:02:13Z | **ALLE 6 CHECKS RØDE** | ikke kode: GitHub Actions blokkert på fakturering |
| Verifisering steg 1 (`royktest` i check-runs) | **DELVIS JA** | navnet vises som eget check-run på PR-en — avledningen virker |
| Verifisering steg 2 (Postgres 18 i ekte CI-logg) | **UMULIG NÅ** | jobben startet ikke, det finnes ingen logg |

**Faktureringsstoppen, målt:** siste vellykkede Actions-kjøring `agents` **09:22:22Z**, første
feilende **09:50:08Z**, alt siden feilet. Annotasjon: *«The job was not started because recent
account payments have failed or your spending limit needs to be increased.»* Alle seks jobbene
feilet i 2 sekunder uten å starte, og `Auto-merge` feiler også. Andre faktureringsstopp samme dag
(tools-1 fant anbud-CRM prod nede i 26 timer på `http_400 credit balance`).

**Anbefaling (min, ikke avgjort):** ikke land #162 før Actions kjører igjen. `royktest` blir
obligatorisk i samme øyeblikk den står på main, og en obligatorisk check som ikke kan bli grønn
stopper hver framtidige PR — mens auto-merge-boten heller ikke kan kjøre.

**Sendt til trading-1 før PR-en ble åpnet** (de rettet det ikke i #162, så det står igjen):
tre foreldede tekststeder som sier porten har 4 skip og at agent-guard ikke er selvforsynt —
`anbud.yml:57`, `anbud.yml:61-63`, `royktest.sh:46-49`. Reelt er det 27/0/3.

**Rigg som står igjen:** `~/code/Veldora-union` (worktree, lokal gren
`infra-1/union-verify-f4cb3f0` = main f4cb3f0 + trading-1s tre filer). Den er klar til å kjøre
verifiseringen på ~10 min når CI lever. `node_modules` er symlenket fra `Veldora-radar`.

**Rapporter:** `00-claude-inbox/Veldora/2026-10-14_infra-1_unionskjoring-f4cb3f0.md` + `.rawlog.txt`.

## 2. PR #90 i command-center (leak-scan + push-porten)

Commit **`9212775`** på `infra-1/leak-scan`. **Ikke pushet** — venter «OK kjør».
Testpakken: **49 ok / 0 feil**.

| Funn | Hvem | Status |
|---|---|---|
| `engine_harden_env` brakk `git fetch` i alle fire repoene (alle https-origin) | tools-1, reprodusert av meg (exit 128) | **RETTET**: github-fetch rutes over ssh; helperen står tømt, push-URL → `no-push://blocked/…` |
| `leak-scan.py` så ikke OpenAI-nøkler (`sk-proj-`, og `SPOR` manglet markør) | tools-1 | **RETTET**: + `sk-proj/svcacct/admin`, `github_pat_`, `glpat-`, Telegram bot-token |
| Ubegrenset `+` i URL-mønsteret mens kommentaren hevdet 256 | tools-1 | **RETTET**: reprodusert 7,46 s → 0,07 s (828 KB, 2000 skjema-treff i én linje) |
| `expect nz` kunne ikke skille nekt fra exit 127 | tools-1 | **RETTET, men ikke slik de foreslo** (se under) |
| `leak-scan.py <fil>` skannet 0 filer og meldte «ingen legitimasjon funnet», exit 0 | **meg** | **RETTET** |
| «a shim BYPASS fail too» var feil ordlyd | tools-1 | **RETTET**: vern mot uhell, ikke mot motstander |

**Det tools-1s foreslåtte fiks ikke fanget:** `grep -q firm-exec-guard` matcher shimens egen *sti*
i «No such file or directory», så **12 av 17 nekt-assertions passerte fortsatt** med alle fire
shimene slettet. Markøren må være nekt-SETNINGEN. Nå: intakt pakke 49 ok / 0 feil, alle fire
shimene slettet **22 feil**.

**Ny test for det som faktisk brakk:** at en https-remote får fetch-URL omskrevet til ssh og
push-URL til `no-push`. Avgjøres offline med `remote get-url`. Pakkens egen origin er en lokal sti
— det er grunnen til at «fetch still work» sto grønn mens fetch var brutt i alle de ekte repoene.

**Kostnad, målt i vekslende rekkefølge med varm cache (834 filer, `~/.claude/projects`):**

| versjon | runde 1 | runde 2 | treff |
|---|---|---|---|
| gammel | 60,5 s | 60,1 s | 7 grupper |
| åtte detektorer, bar `sk-`-markør | 113,1 s | 112,3 s | 11 |
| **portet (i commiten)** | **76,8 s** | **80,0 s** | **11** |

Første kostnadstall jeg oppga (+31 %) var forurenset av sidecache. Rettet selv.

**Rapport:** `00-claude-inbox/command-center/2026-10-14_infra-1_pr90-retting.md`.

## 3. Sikkerhetsfunn som venter på operatøren

1. **Umaskert `sk-proj-`-nøkkel, 164 tegn, 2 forekomster, i én sesjonstranskripsjon**
   (`~/.claude/projects/-home-nithu-code/479ac614-…jsonl`, mtime 10:18Z i dag). Funnet av de nye
   mønstrene; gammel versjon var blind for den. **Ikke** i `memory.db` og ikke i noen `/tmp`-rot
   (sjekket på form, aldri verdi). Men transkripsjonene er substratet destilleringen leser, så den
   havner i et søkbart korpus hvis den sesjonen destilleres. Rotasjon er operatørens beslutning;
   jeg har ikke rørt nøkkelen.
2. **`command-center/.env` linje 23** er ueskapet og skrives ut når fila sources (orchestrator-1s
   funn). Fiks med `nano`. Jeg leser ikke `.env`.
3. **GitHub-fakturering** blokkerer all CI. Jeg kan ikke lese billing-API-et uten å utvide
   `gh`-scopet, og det er operatørgatet.

## 3b. PUSHET 13:05Z — og en gate-defekt i min egen avleder (NY)

Operatøren ga «ok kjør» på inboksen i panet mitt, og orchestrator relécet operatørens verbatim
«wrap opp og push alt ut». Pushet i egen lane; ingenting merget, ingen gren slettet.

| Hva | Hvor | Verifisert |
|---|---|---|
| `9212775` | command-center PR **#90** (kommentar med alle tall lagt på PR-en) | testpakke 49/0 lokalt |
| `56681ef` | Veldora PR **#165** (ny) | 20/20 tester, 2 av dem røde på forrige versjon |

**PR #165 er det viktigste funnet i denne runden, og det var trading-1 som fant det i MIN fil.**
En kommentar som bare *forklarte* advisory-markøren gjorde jobben rådgivende:

```yaml
  # Jobben under er blokkerende. Skal den gjøres rådgivende, legges markøren
  # `# auto-merge: advisory` over jobbnøkkelen (ADR-0012).
  royktest:
```

`ADVISORY_MARKER.search()` lette etter strengen hvor som helst i en kommentarlinje på
jobbnøkkel-innrykk — og dokumentasjonskommentarer står nettopp der. Enhver ADR-referanse eller TODO
som nevnte markøren slo av den jobben. Reprodusert med og uten setningen før retting:

```
med setningen:  crm, migrasjonssnapshot, dashboard, schemas, website
uten setningen: crm, migrasjonssnapshot, royktest, dashboard, schemas, website
```

Samme feilklasse som den håndholdte `REQUIRED`-lista ble fjernet for — en port som slutter å kreve
noe uten at noen bestemte det — bare stillere. Ankret til at kommentaren må VÆRE markøren.

**Rekkefølge:** #165 bør landes sammen med eller før #162, ellers lander porten med en avleder som
kan avvæpnes av en kommentar. #162 er alt renset for markørstrengen, så det er hygiene, ikke akutt.

**Egen slurv rettet:** jeg oppga tidligere `git grep "auto-merge: advisory"` som kommandoen bak
påstanden om trading-1s gren. Det jeg kjørte var `git grep "advisory"`. Konklusjonen holdt,
kommandoen jeg oppga gjorde ikke.

## 4. Operatørgater — hva som venter på «OK kjør»

| Hva | Hvor | Konsekvens av å vente |
|---|---|---|
| ~~Push `9212775` (PR #90)~~ | **PUSHET 13:05Z** | — |
| GitHub-fakturering | kontoinnstillinger | all CI står; #162 kan ikke verifiseres eller landes trygt |
| Merge #162 | Veldora | min anbefaling: vent til Actions lever |
| `infra-1/pg-backup-restore` (`209eff8`) | Veldora, bare lokal | backup/restore er fortsatt uverifisert i drift |
| Feed-korrupsjonsfiksen (`$`-tall i `_bin`-skript) | command-center `_bin` | tall i feeden er fortsatt «målt, men ødelagt i transport» |

## 4b. `main` flyttet 12:55Z — unionsmålingen står likevel

`origin/main` er ikke lenger `f4cb3f0`: **`8ba6192`** ble pushet **direkte til main** 12:55:13Z
(«feat(dashboard): Interne dokumenter med mappen Maler»), altså utenom PR-flyten mens CI er død.
Kontrollert hva det betyr for porten: commiten rører **0 filer under `projects/anbud/crm`** — bare
dashboard, maler og en test der. Røyktestene leser `crm/src`, så **unionskjøringen min (27/0/3,
400 s) gjelder fortsatt**. Jeg kjører den om hvis noe treffer `crm/` før porten landes.

Og en ting jeg trodde var en defekt i min egen vokter, men ikke var: den logget `main=f4cb3f0`
kl. 12:53:55Z mens en annen sjekk viste `8ba6192`. Commiten er datert 12:55:13Z — altså etter
pollen. Vokteren hadde rett, mistanken min var feil, og `git fetch` i den returnerer exit 0 både
med og uten TTY (målt).

## 4c. LUKKET 15:05Z — porten er verifisert på main, og det finnes et fjerde hull

Operatøren fikset faktureringen (hevet taket), orchestrator re-kjørte, og porten kjørte ekte på
main. **Bekreftet med min egen måling, ikke relékert:** `origin/main` = `cd497ba`, `royktest:` står
i `anbud.yml:85`, `grep -c "auto-merge: advisory"` = 0, og jobben:

```
royktest success steg=10 14:56:46Z→15:05:10Z (8 min 24 s)
27 grønn / 0 rød / 3 skip — identisk med alle tre lokale unionskjøringene
check-server-version: ok, Postgres 18 (180006) som første linje
```

**Verifiseringssteget er dermed lukket.** Det var orchestrator som utførte det mens jeg sto på
vokteren; jeg etterprøvde det.

**Og orchestrator fant et fjerde hull i de GRØNNE testene:** tre AI-agenter i `smoke-brief.ts`
hopper over seg selv fordi `ANTHROPIC_API_KEY` mangler i CI, og testen melder grønt. Jeg målte
omfanget og svarte på de tre spørsmålene deres:

- **Det er ikke med vilje.** `ANTHROPIC_API_KEY` **finnes som repo-secret** (30.08.2026) og brukes
  alt av `agents.yml:390`. `anbud.yml`s royktest-jobb sender den bare ikke videre. Én linje i
  `env:` lukker den — og **da** blir kostnaden en ekte beslutning (modellkall på hver PR), som er
  operatørens.
- **Omfanget er 11 tasks, kjørt av 10 av de 27 grønne testene**, ikke tre agenter i én test:
  `assess-requirements`, `challenge`, `extract-requirements`, `tender-brief`, `contract-review`,
  `draft-bid`, `red-team`, `draft-reply`, `ingest-answer`, `parse-cv`, `qualify-requirements`.
  **Øvre grense** — metoden er strengmatch av task-navn i smoke-skriptene krysset med
  `isLlmEnabled` i task-fila, så hver rad må bekreftes per test før tallet havner i en ADR.
- **Forslag:** en degradert test skal ikke feile, men den skal skrive et UDEKKET-felt i
  oppsummeringen. Et skip inne i en grønn logg er usynlig; et skip i UDEKKET-lista er synlig uten
  at en manglende nøkkel stopper porten.

## 5. Vokter som går

**FERDIG.** `watch-royktest2.sh` traff **14:31:51Z** på at `royktest` dukket opp på `origin/main`
(`d4ce342`) og stoppet selv. Logg: `scratchpad/watch-royktest.log`, 70 pollinger over 2,5 time.
Ingen vokter kjører nå.


---

# TILLEGG 2026-10-15 — infra-1 lukker ned

## Landet

| PR | Hva | Bevis |
|---|---|---|
| SC **#165** | advisory-ankeret (en prosa-setning avvæpnet porten) | merget 14.10 14:31:55Z |
| SC **#168** | verifiser-før-deploy: `workflow_dispatch` i `anbud.yml` + `anbud`-dispatch før deploy | merget av **boten** 15.10 06:41:55Z, alle 7 checks grønne først: `royktest success, 10 steg, 8 min 20 s, 28/0/2, Postgres 18 (180006)` |

## Venter merge

**CC #90** (`9212775`) — fetch-fiksen (alle fire repoene hadde brutt `git fetch` i motoren), fire nye
nøkkelklasser i skanneren, og en testpakke som faktisk beviser porten (49/0 intakt, 22 feil med
shimene slettet).

## RETTELSE til orchestrators overtakelsesdokument

Overtakelsen sier «Auto-merge-porten merget fire PR-er på røde sjekker. Bekreftet.» **Det stemmer
ikke.** `merged_by` på alle fire:

```
#162 Nithu0  14:31:21Z     #163 Nithu0  14:31:34Z
#164 Nithu0  14:31:45Z     #165 Nithu0  14:31:55Z
```

Operatøren merget dem manuelt, 13-21 sekunder fra hverandre. **Boten merget dem ikke** — derfor
fantes det ingen kjøretidslinjer i botens logger.

Botens nekt-logikk er intakt og målt: `auto-merge.yml:166-168` blokkerer på `conclusion != success`,
`:157-159` er fail-closed på manglende check. De to PR-ene boten faktisk merget var grønne — **#167**
hadde alle sju grønne, siste fullført 05:59:38Z, merget 05:59:54Z (16 sekunder etter), og **#168**
hadde null ikke-success.

**Den ekte tråden:** fire PR-er landet uverifisert fordi et menneske merget dem mens
faktureringsveggen gjorde alle sjekker meningsløse. #162 og #165 er siden dekket indirekte av grønne
main-kjøringer. **#163 (`cc6b283`) og #164 (`7577098`) kan være de eneste to som aldri har hatt en
ekte kjøring på treet som landet.**

## Siste utestede antakelse i portpakken

#168 ble merget av boten, men boten kjørte den GAMLE koden (den sjekker ut main; fiksen var selve
PR-en). Derfor finnes ingen `anbud`-kjøring på `fae0ddd` — bare `deploy` 06:41:58Z. **Første
bot-merge etter #168** blir den første med ny kode, og beviset er én linje: det skal finnes en
`anbud`-kjøring på merge-SHA-en i `gh run list`. Ingen bot-merge har skjedd siden.

## Står igjen etter meg

- **Worktrees** (sletting er operatørgatet): `~/code/Veldora-union` (unionsriggen, klar til bruk),
  `~/code/Veldora-checks`, `~/code/cc-leakscan`.
- **Halvferdig, eier meg:** denied-job-detektoren (spesifisert, signatur verifisert, ingen kode) og
  session-start-hookens 10 s-tak (6,97 s målt, sprekker med åtte paner).
- **Halvferdig, ingen eier:** `infra-1/pg-backup-restore` (`209eff8`, bare lokal — dør stillest) og
  feed-`$`-korrupsjonen i `_bin`-skriptene.
- **Minne lagret:** `feedback_billing_before_debugging` — alt rødt samtidig betyr sjekk fakturering
  før kode, med dagens to stopp som bevis.
