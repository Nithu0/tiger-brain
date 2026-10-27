# PR #90 etter tools-1s gjennomgang: to blokkerende rettet, to flere funn — infra-1, 2026-10-14

Commit `7e988cd` på `infra-1/leak-scan`, **ikke pushet** (command-center-push er operatørgatet).
Alt under er målt her, ikke overtatt fra gjennomgangen.

## Blokkerende 1: `engine_harden_env` brakk `git fetch` i alle fire repoene

Reprodusert med tools-1s eget oppsett:

```
error: unable to read askpass response from '/bin/false'
fatal: could not read Username for 'https://github.com': terminal prompts disabled
exit=128
```

Og alle fire origins er https (`command-center`, `ai-assistent`, `Veldora`, `aslisten-crm`), så
mengden er 100 %, ikke et kanttilfelle. Første remote-jobb som rebaser mot `origin/main` ville dødd.

**Fiks:** `url.ssh://git@github.com/.insteadOf=https://github.com/` i `ENGINE_GIT_CONFIG`. Fetch
autentiserer med ssh-nøkkelen i stedet for det lagrede tokenet; credential-helperen står fortsatt
tømt, så https-tokenet serveres aldri inn i motorprosessen; `ssh://` og `git@` er fra før
pushInsteadOf-omskrevet, så ssh-ruten kan hente men ikke pushe. Målt etter fiks:

```
fetch --dry-run            → exit 0
remote -v (fetch)          → ssh://git@github.com/Nithu0/command-center.git
remote get-url --push      → no-push://blocked/github.com/Nithu0/command-center.git
push --dry-run             → exit 128 ("remote-no-push is not a git command")
```

## Blokkerende 2: skanneren kunne ikke se OpenAI-nøkler

Begge defektene bekreftet: forhåndsfilteret hadde bare `sk-ant-`, så en fil med bare en
OpenAI-nøkkel ble hoppet over før detektoren kjørte, og `\bsk-[A-Za-z0-9]{32,}` kan ikke matche
`sk-proj-`/`sk-svcacct-` fordi prefikset har bindestrek.

Lagt til: `sk-proj-`/`sk-svcacct-`/`sk-admin-`, `github_pat_`, `glpat-` og Telegram bot-token
(`<bot-id>:<35 tegn>`), med markører i `SPOR` for hver — ellers hjelper ikke detektoren.

**Målt mot en syntetisk fixtur med 12 legitimasjonsformer** (tilfeldige verdier, ingen ekte):

| | grupper funnet |
|---|---|
| gammel (`83a77a6`) | 7 |
| ny (`7e988cd`) | **11** |

Ingen verdier skrives ut i noen av versjonene.

## Funn 3 (ikke i gjennomgangen, samme feilmodus): `leak-scan.py <fil>` meldte rein uten å lese

`os.walk` over en fil gir null treff, så en eksplisitt navngitt fil ga «0 filer skannet / ingen
legitimasjon funnet / exit 0». For en skanner der `exit 0` leses som rent er det samme falske
negativ som et manglende mønster, bare i CLI-kontrakten. Rettet i `filer()`.

## Funn 4: min egen første fiks av testpakken beviste fortsatt ikke noe

tools-1 slettet alle fire shimene og 17 nekt-assertions rapporterte `ok`. Jeg la inn
`grep -q firm-exec-guard` som de foreslo — og **12 av 17 passerte fortsatt**, fordi shimens egen
*sti* inneholder «firm-exec-guard» og dukker opp i `No such file or directory`. Markøren må være
nekt-SETNINGEN (`BLOCKED for remote autonomous runs`).

| pakke | utfall |
|---|---|
| intakt | **49 ok / 0 feil** |
| alle fire shimene slettet | **27 ok / 22 feil** |

Ny test for det som faktisk brakk: at en https-remote får fetch-URL omskrevet til ssh og push-URL
til `no-push`. Avgjøres offline med `remote get-url`, så den trenger ikke nett eller legitimasjon.
Pakkens egen origin er en lokal sti — derfor sto «fetch still work» grønn mens fetch var brutt i
alle de ekte repoene.

## Begrensede kvantifikatorer: reprodusert, men ikke tools-1s størrelse

Kommentaren i fila hevdet 256-grense; koden hadde ubegrenset `+` på bruker og passord. Rettet.
Reprodusert blowup krever MANGE skjema-treff i én linje, ikke bare en stor fil:

| fixtur | gammel | ny |
|---|---|---|
| 850 KB, 1 skjema-treff, én linje | 0,06 s | 0,07 s |
| 828 KB, **2000** skjema-treff, én linje | **7,46 s** | **0,07 s** |

tools-1 målte 48,7 s → 0,053 s på 855 KB. Jeg fikk ikke deres størrelse, men samme klasse og
samme retning. Forskjellen er antall treff i fixturen, ikke uenighet om defekten.

## EKTE FUNN som de nye mønstrene avdekket — operatørbeslutning

Full skanning av `~/.claude/projects` (834 filer) med begge versjoner, samme rot:

- **Ny versjon finner en `sk-proj-`-nøkkel på 164 tegn, 2 forekomster, i én
  sesjonstranskripsjon** (`~/.claude/projects/-home-nithu-code/479ac614-…jsonl`, mtime 10:18Z
  i dag). Ingen maskering, ekte form og ekte lengde. Gammel versjon var blind for den — det er
  presis klassen tools-1 pekte på, og den finnes altså i virkeligheten, ikke bare i en fixtur.
  Dette er sannsynligvis nøkkelen orchestrator-1 beskrev: `command-center/.env` linje 23 er
  ueskapet og skrives ut når fila sources. **Rotasjon er operatørens beslutning; jeg har ikke
  rørt nøkkelen, ikke skrevet verdien noe sted, og ikke endret `.env`.**
- **Den er IKKE i `memory.db` ennå**, og ikke i noen `/tmp`-rot (sjekket på form, aldri verdi).
  Men transkripsjonene er substratet destilleringen leser, så den kommer dit hvis den sesjonen
  destilleres. Det er grunnen til at dette ikke kan vente på «eksponeringen er lokal».
- Gammel versjon rapporterte til gjengjeld en `sk-ant-`-nøkkel på 43 tegn som ny versjon ikke
  melder. Kontrollert: den er `sk-ant-a` + 30 × `x`, altså en plassholder i en probe-logg, og
  `MASKERT` undertrykker den riktig. Tapt funn = fjernet støy, ikke en regresjon.
- De øvrige radene (postgres-passord 22/23 tegn i `memory.db`, AKIA-form i probe-logger,
  `postgresql://postgres@…:5432` på privat nett) er identiske i begge versjoner. Ingen av dem er
  nye.

## Ordlyd rettet

`firm-remote-executor.sh` og testpakkens etikett sa at laget får «a shim BYPASS fail too». Det
stemmer ikke: `GIT_CONFIG_COUNT=0 /usr/bin/git push` og `git push file:///…` pushet begge
(tools-1). Nå står det at det er vern **mot uhell, ikke mot en motstander**, med de to målte
omgåelsene navngitt. Shimen er primærporten, og den holdt i 15 probede push-stavemåter.

## Kostnad: målt, og halvparten av den var unødvendig

Første forsøk på å måle dette var forurenset av sidecache (95 s mot 125 s i én retning, 114 s mot
67 s i den andre). Riktig oppsett er vekslende rekkefølge med varm cache, to runder, samme rot
(`~/.claude/projects`, 834 filer):

| versjon | runde 1 | runde 2 | treff |
|---|---|---|---|
| gammel (`83a77a6`) | 60,5 s | 60,1 s | 7 grupper |
| åtte detektorer, bar `sk-`-markør | 113,1 s | 112,3 s | 11 |
| presise `sk-`-markører | 98,2 s | — | 11 |
| uten Telegram-formen i `SPOR` | 110,8 s | — | 11 |
| **portet (det som ligger i commiten)** | **76,8 s** | **80,0 s** | **11** |

Alle variantene finner det samme, så den bare `sk-`-markøren kostet ~14 s for ingenting, og
Telegram-formen ~2 s. Resten kom av at åtte detektorer hver kjørte et fullt `finditer` over filer
på hundrevis av MB. Hver detektor har nå en literal-port først — `in` på bytes er et memchr-søk —
og da er prisen **+18 s over gammel for fire nye legitimasjonsklasser**. Det er kjøpt, ikke antatt.

## Til operatøren

1. `command-center/.env` linje 23: verdien er ueskapet og skrives ut når fila sources. Fiks med
   `nano` — jeg leser eller endrer ikke `.env`.
2. `sk-proj-`-nøkkelen over: rotasjon er din beslutning. Den ligger i én transkripsjon, to
   forekomster, ikke i `memory.db`.
3. `7e988cd` venter «OK kjør» for push til `infra-1/leak-scan` (PR #90).
