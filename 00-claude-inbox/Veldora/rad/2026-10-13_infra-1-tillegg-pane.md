# infra-1 (pane) — tillegg til strategiråd runde 1

Hovedrapporten `2026-10-13_infra-1.md` ble skrevet av den headless infra-1-executoren kl. 10:28
og overskrev min versjon på samme sti. **Deres rapport står** — den er grundigere på repo-fakta
(`.railway/railway.ts`, 56 collections, 51 migrasjoner, `secure/`-apparatet, `llm-usage`). Dette
er bare deltaet: det jeg målte som de var blokkert fra, to funn de ikke har, og to tall som ikke
stemmer mellom oss. Konklusjonen vår er den samme: **bli på Vercel + Railway**.

## 1. Målt fra en interaktiv pane — den headless kjøringen fikk `firm-exec-guard: BLOCKED`

- `FACT` `railway status --json` (kjørt fra `~/.local/state/anbud-vakt/railway`): prosjekt
  `anbud`, region `europe-west4-drams3a`, `Postgres` på image `postgres-ssl:18` med 1 replika og
  volum `/var/lib/postgresql/data`, `crm` med healthcheck `/api/health`, `worker` uten
  healthcheck i manifestet. Bekrefter IaC-filen deres mot faktisk kjørende topologi.
- `FACT` `railway logs --http -s crm --since 1h` → 139-142 linjer. Samme kommando mot
  `-s worker` → **0 linjer**. Worker har ingen HTTP-trafikk i det hele tatt.
- `FACT` Åtte målinger kl. 10:14: dashboard 307 på 0,13-0,32 s, CRM `/api/health` 200 på
  0,17-0,36 s. Alarmen 09:58 («Dashboard treg 6,81 s») var altså én kald start, ikke en trend.
- `FACT` «Ingen backup» er hardere enn README-boksen antyder: `litestream.service` kjører, men
  konfigurasjonen dekker bare lokale SQLite-baser (command-center, brain, memory.db) —
  anbud-Postgres er ikke i den, og `systemctl --user list-timers --all` har ingen backup-timer
  for anbud. Det finnes altså ingen backup utenfor Railways egen, og den er aldri restore-testet.

## 2. To fail-open-veier som ikke står i hovedrapportens §2

Hovedrapporten dokumenterer at defaulten er permissiv (`datapolicy.ts:41`). Det finnes to veier til:

- `FACT` `lib/datapolicy.ts:94-108` — `loadDataPolicy` fanger feil fra `findGlobal` og returnerer
  `PERMISSIVE_POLICY`. Kommentaren over funksjonen sier det rett ut: «An unreadable global (older
  schema, DB down) yields the permissive default and one warning, so a missing table never turns
  the agents off.» Dette er et **bevisst valg**, ikke en bug — og det er riktig valg når kunden er
  oss selv, feil valg når kunden er noen andre. En skjemafeil slår personvern-gaten av, stille.
- `FACT` `lib/llm.ts:130` — `const types = dataTypes ?? TASK_DATA_TYPES[task] ?? ['intern']`. En
  ny task som utvikleren glemmer å føre inn i `TASK_DATA_TYPES` passerer som intern. Gaten tror
  tabellen er sannheten om hva prompten inneholder; den ser aldri innholdet.

Begge peker samme vei som hovedanbefalingen: `defaultModelApiAllowed: false` med eksplisitt
allowlist, og fail-closed for `personal` når policyen ikke kan leses.

## 3. Korreksjon til hovedrapportens §1 og §3

- Vaktposten som er ført som eneste eksterne probe var **delvis blind til i dag**: 5xx-sjekken
  kjørte `railway logs --http` mot tjenesten `worker` (arvet `CRM_DIR` fra et annet spors
  worktree), og worker har 0 HTTP-linjer. Null 5xx betydde ingenting. Rettet i dag, med en
  loggprøve hver time som varsler «jeg ser ingenting» i stedet for falsk grønt.
- Det er **én** gren å pushe, ikke to: `infra-1/vakt-i-repo` (f47cd4d) erstatter
  `infra-1/anbud-vakt-prod-monitor` (367c83c, foreldet — lå på toppen av en triage-gren som siden
  er landet). Vakten kjører nå som `anbud-vakt.service` fra en kopi utenfor worktreene, med egen
  Railway-lenket katalog, så den overlever omstart og at et worktree ryddes.

## 4. To tall som ikke stemmer mellom de to infra-1-rapportene

| Tall | Pane (denne) | Headless (hovedrapport) | Hvorfor |
|---|---|---|---|
| Azure-gulv/mnd | ~$87 | $160-200 | Jeg antok at et rent Consumption-miljø slipper «Environment Management Hour» ($0,13/t ≈ $95/mnd) og flagget det som uverifisert. De legger workload-profile-miljø ($0,143/t) til grunn. Én av oss tar feil. |
| LLM per anbud | ~$0,08 (30k inn / 2k ut) | ~$0,50 (150k inn / 20k ut) | Rene antakelser i begge ender, 6× fra hverandre. |

`ANTAKELSE` Begge spenn gir samme svar på selve spørsmålet (bli), så beslutningen tåler
usikkerheten. Men **ingen bør sitere ett av disse tallene videre** før `llm-usage`-eksporten og
et faktisk Railway/Vercel-fakturabilde foreligger. Det er samme ask som hovedrapporten stiller.

## 5. Til charteret: rapportstien hadde ingen eier

Samme dispatch (`job-20261013-081736-infra1-20284`) ble utført av både den interaktive panen og
den headless executoren for rollen, mot samme filsti. Den som skrev sist vant, og en ferdig
leveranse ble borte. Dette er tredje gang på tre dager at to instanser gjør samme arbeid.
`FORESLÅTT` Enten skriver executoren til `<rolle>-headless.md`, eller dispatchen sier eksplisitt
hvem som eier leveransen. Begge er billigere enn å oppdage det etter at filen er overskrevet.

---

## 6. AVKLART 2026-10-13 kl. 11:35 — begge pristallene, med primærkilde

**Container Apps-miljøavgiften: min antakelse var riktig.** Microsofts egen faktureringsside sier
det rett ut: «You aren't billed any plan management charges unless you use a Dedicated workload
profile in your environment» (learn.microsoft.com/azure/container-apps/billing, lest 13.10). Et
Consumption-only-miljø betaler altså **ingen** miljøavgift. `FACT` Meteren finnes
(`Environment Management Hour`, $0,13/t, Sweden Central), men den treffer Dedicated-profiler.
**Forbehold fra samme side:** private endpoints og planlagt vedlikehold utløser Dedicated
Plan Management uansett plan — vil vi ha privat endepunkt, er de $95/mnd tilbake.

**Postgres B2s: vi hadde begge rett, om ulike regioner.** `FACT` Azure Retail Prices API, samme
dag, samme filter: `B2S` i **Sweden Central $0,0398/t = $29,1/mnd**, i **West Europe $0,0796/t =
$58,1/mnd**. Nøyaktig 2×. Jeg oppgav Sweden Central, hovedrapporten oppgav West Europe, og ingen av
oss nevnte at regionvalget dobler DB-linjen. (Mønsteret er mistenkelig regelmessig — West Europes
B2S er lik Sweden Centrals B2ms — så tallet bør bekreftes i en kalkulator før budsjett, men det er
hva API-et svarer i dag.)

**Konklusjon for kostnadsmodellen:** Azure-gulvet er **~$90-100/mnd** for et minimalt
Consumption-only-oppsett i Sweden Central, og **~$190/mnd** med privat endepunkt eller West Europe.
Begge tallene lå inne i de to rapportene; forskjellen var regionvalg og nettverksmodell, ikke feil
regning. Anbefalingen endres ikke — Railway-ekvivalenten er ~$75/mnd — men planleggingstallet skal
være $90-100, ikke $160-200, og det **motsier** hovedrapportens poeng om at EU-nær lagring er
dyrere: Sweden Central er halvparten av West Europe på denne linjen.
