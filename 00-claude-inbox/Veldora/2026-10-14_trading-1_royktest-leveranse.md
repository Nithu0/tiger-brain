# trading-1 — leveranse 2026-10-14: røyktest-porten

Sesjon: `session_01Uq23U7DLkFuJ4CcUu7vcHk` · rolle `trading-1` · worktree `~/code/Veldora-ci`
Oppdrag: orchestrator-1 06:05Z — «LUKK RØYKTEST-PORTEN. Den falt på gulvet i går, steg 2 av 2.»

## Status i én linje

Porten er bygget, målt, pushet og oppe som **PR #162**. Den kan ikke merges, fordi GitHub Actions
er avskrudd for manglende betaling. Ingen kode gjenstår.

---

## 1. Hva som er levert

**Gren `trading-1/crm-ci-royktest` — 6 commits over `f4cb3f0`, +294 linjer i 3 filer, pushet.**

| Commit | Hva |
|---|---|
| `06ed613` | bygg crm i CI + kjør røyktestene mot en migrert base |
| `09b7335` | porten validerte migrasjonene mot Postgres 16 — prod er 18 |
| `7006914` | porten sier hva den IKKE dekker, og lyver ikke grønt på tom kjøring |
| `4f4b5dd` | porten beviser serverversjonen hver kjøring; agent-guard skipper ikke lenger |
| `02c66f4` | porten beskriver sin egen dekning riktig etter at agent-guard ble selvforsynt |
| `5caae3e` | **en setning OM markøren avvæpnet porten** — nå står den ikke i kommentaren |

Filer: `.github/workflows/anbud.yml` (+70), `projects/anbud/crm/scripts/royktest.sh` (+130),
`projects/anbud/crm/scripts/smoke-scope-backfill.ts` (+94).

**PR #162:** https://github.com/Nithu0/Solar-Consulting/pull/162 — åpen, korrekt, venter på CI.

Hva porten gjør: kjører `scripts/smoke-*.ts` mot en migrert, bruk-og-kast Postgres 18 i CI. Fram til
nå har de 30 røyktestene bare kjørt når noen husket det for hånd — `npm test` er `vitest run` og
rører dem ikke. To av de tre leveransene 12.10 som var grønne i CI og døde i produksjon feilet på
skjema/enum, altså presis det disse fanger.

## 2. Målinger (ikke antagelser)

| Kjøring | Node | Grønn | Rød | Skip | Exit | Veggklokke |
|---|---|---|---|---|---|---|
| trading-1 CI-paritet | 22.23.2 | 27 | 0 | 3 | 0 | **261 s** |
| trading-1 kontroll | 24.21.0 | 27 | 0 | 3 | 0 | 340 s |
| infra-1 uavhengig | — | 27 | 0 | 3 | 0 | 400 s |

Alle mot fersk, tom `postgres:18-alpine` (0 tabeller verifisert før start). Identisk testsett i mine
to kjøringer, verifisert med diff. **640 s brukt som CI-margin** i jobbteksten — det var
førstegangskjøringen på samme maskin, og en GitHub-runner er tregere.

Porten beviser majoren selv, hver kjøring, som første linje:
`check-server-version: ok, Postgres 18 (180006)`

**Hva porten ikke dekker — 3 skip, hver med UDEKKET-felt i oppsummeringen:**
- `smoke-market.ts` — markeds- og kjøperberikelse (krever innhentede kunngjøringer)
- `smoke-legal.ts` — rettskildeoppslag mot anskaffelsesloven og FOA (krever ingestet korpus)
- `smoke-requalify.ts` — at endret registerfakta flytter fingeravtrykket (grønn isolert, rød i delt
  base på `payload_jobs`-kontaminering; suitens feil, ikke testens)

`smoke-agent-guard.ts` skipper ikke lenger — infra-1 gjorde den selvforsynt i #157, og den er grønn
også i delt base.

## 3. Tre funn

**A. En prosasetning avvæpnet porten. (Mitt eget, fanget før push.)**
Jeg skrev en kommentar over `royktest:` som forklarte hvordan jobben gjøres rådgivende, og siterte
markørstrengen i klartekst. `advisory_jobs()` i `.github/scripts/expected-checks.py` gjør
`ADVISORY_MARKER.search(stripped)` på hver kommentarlinje med jobbnøkkel-innrykk, så setningen slo
av porten. Målt mot avlederen, samme filsett, eneste forskjell den ene setningen:

```
med setningen:  crm, migrasjonssnapshot, dashboard, schemas, website  (+ADVARSEL: royktest rådgivende)
uten setningen: crm, migrasjonssnapshot, royktest, dashboard, schemas, website
```

Hullet er generelt: enhver kommentar over en jobbnøkkel som *nevner* markøren slår av den jobben.
Meldt infra-1 med forslag om å ankre matchen til en linje som ER markøren
(`^#\s*auto-merge:\s*advisory\s*$`). Deres fil, deres avgjørelse — jeg rørte den ikke.

**B. GitHub Actions er dødt i hele repoet. (Operatør-gatet.)**
Alle seks checks på #162 feilet på 2 sekunder med null steg — også `schemas`, `website` og
`dashboard`, som diffen ikke rører. Annotasjonen: *«The job was not started because recent account
payments have failed or your spending limit needs to be increased.»*

- Siste suksessfulle run i repoet: **2026-10-14T09:22:38Z**. Første feil ~09:50Z.
- Gjelder alt: `anbud`, `validate`, planlagt `agents`, og `Auto-merge`.
- **Feilretningen er lukket:** `Auto-merge` feiler selv, så ingenting slipper gjennom uten checks.
- `#158`–`#161` merget 13.10 kl. 19:01–19:06Z, før utfallet. **Main er CI-verifisert.**
- Ingen varsling fyrte. Oppdaget fordi jeg leste annotasjonen framfor å konkludere «seks røde tester».

**C. Repoet har flyttet.** Pushen svarte `This repository moved. Please use the new location:
https://github.com/Nithu0/Solar-Consulting.git`. Den gikk gjennom via omdirigering, og PR-en ble
opprettet på `Solar-Consulting`. Lokale remotes peker fortsatt på `Veldora` i alle worktrees. Verdt
å oppdatere før en omdirigering slutter å virke — infra-1s lane, ikke rørt.

## 4. To feil jeg gjorde, og hva de kostet

1. **Redigerte `royktest.sh` mens suiten kjørte den.** Bash leser skript etter byte-offset, så den
   gjenopptok på feil sted og døde med syntaksfeil, exit 2. De 27 testene hadde rapportert grønt,
   men kjøringens konklusjon var verdiløs. Kjørte om på committet, urørt fil. Kostet én kjøring.
2. **Påsto Node 22 før jeg hadde det.** `nvm use 22` meldte at den byttet, mens `~/.local/bin/node`
   (v24.21.0) skygget den i PATH. Fanget det i etterkant og kjørte om med binæren direkte. Begge
   majors ga samme utfall, så konklusjonen sto — men påstanden var usikret da jeg først skrev den.
   Kostet én kjøring.

Også: commit-meldingen til `02c66f4` påsto «ingen oppførselsendring: bare kommentarer». Det var feil
— se funn A. `5caae3e` retter både koden og påstanden.

## 5. Push-gaten

Orchestrator-1 meldte to ganger at operatøren hadde gitt «OK kjør» (08:20Z og 08:35Z). Jeg holdt
pushen, fordi operatøren satt i sesjonen min, ble spurt direkte, og svarte med en annen instruks.
En relé kan ikke være kilden til gaten når kilden er i rommet. Operatøren ga `OK kjør` direkte
11:0xZ, og pushen gikk i samme minutt.

Orchestrator-1 09:05Z: *«Da er gaten ikke gitt, og du har lest regelen riktigere enn jeg gjorde da
jeg videreformidlet den.»* De tar reléspørsmålet til operatøren som egen sak.

**Dette var ikke prosedyre for prosedyrens skyld:** hadde jeg pushet på reléet 08:20Z, ville
`5caae3e`-feilen landet — en blokkerende port som ikke blokkerer, grønn PR, ingen krav.

## 6. Hva som står åpent

| Sak | Eier | Tilstand |
|---|---|---|
| **#162 kan ikke merges** | operatør | Actions avskrudd. `royktest` er obligatorisk og kan ikke bli grønn. Fiks: GitHub → Settings → Billing & plans på `Nithu0` |
| Advisory-markøren matcher prosa | infra-1 | meldt med forslag, ikke rørt |
| `royktest` vs `smoke` navnesprik | orchestrator-1 | ordren sa `smoke`, koden sier `royktest`; avlederen er strukturell så det er kosmetisk. Står i PR-teksten |
| `smoke-requalify` isolasjon | trading-1 | egen skive, ikke startet |
| `smoke-market` / `smoke-legal` seeding | — | egen skive, ikke startet |
| `trading-1/dokument-pipe` (`173bdb0`) | trading-1 | **urørt, bølge 2.** Henter over nett fra hyyr.no med hardkodet konkurranse-id. `royktest.sh` globber `ls smoke-*.ts`, så den plukkes opp automatisk når den landes — med blokkerende port blir en tredjeparts oppetid merge-blokker. `skip_reason`-oppføringen hører i DEN PR-en |
| Død CI melder seg ikke selv | orchestrator-1 | foreslått som egen sak. «Grønn port» og «ingen port» er samme skjermbilde i dag |
| `rea` (MCP reverse engineering) | trading-1 | tildelt 08:45Z, motpart learning-1. Ikke startet — orchestrator sa «neste, ikke nå». Grense kvittert: MCP-server, ingen autentiserte økter i runde 1, offentlige sider først, learning-1s vilkårsgate står |

## 7. Kommunikasjon

7 meldinger til `inbox/orchestrator-1.md`, 1 til `inbox/infra-1.md`, 7 linjer i `feed.md`.
Logger: `royktest-union-node22.log`, `royktest-union-clean.log` i sesjonens scratchpad.

---
*trading-1, 2026-10-14*
