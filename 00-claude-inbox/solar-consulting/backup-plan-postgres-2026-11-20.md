# Backup-plan: nattlig pg_dump av Postgres for horizon og plattform

2026-11-20, infra-1s hjelper. Bare lesing mot Railway og GitHub; ingenting er endret. Merking: `FACT` (sjekket i dag), `ASSUMPTION`, `UNKNOWN`, `DECISION` (Nithu avgjør).

## 1. Hva som finnes i dag

**horizon (Railway-prosjekt `anbud`, bare miljøet `production`)**

- `FACT`: Railway har `Postgres` (image `postgres-ssl:18`), `crm` og `worker`. Ingen `backup`-tjeneste og ingen buckets. Ingen preview-miljø.
- `FACT`: `.railway/railway.ts` på `origin/main` (94a6f67) definerer cron-tjenesten `backup` (00:47 UTC, `restartPolicyType: NEVER`), bygget fra `backup/` (port av Nithu0/Solar-Consulting#355, commit a7e1132, 30.10). Den er aldri tatt i bruk (`config apply` er ikke kjørt).
- `FACT`: `backup/` er ferdig kode: `pg-backup.sh` (pg_dump 18 i én `REPEATABLE READ`-snapshot, radtall-manifest, `--format=custom --compress=6`, age-kryptert til offentlig nøkkel, S3-opplasting via curl SigV4, månedskopi), `pg-restore-check.sh` (sha256, dekrypter, restore til tom PG18, sammenlign radtall), `s3.sh`, `Dockerfile` (`postgres:18-trixie` + age + curl). Testet lokalt 30.10 mot moto, ikke mot ekte leverandør eller Railway.
- `FACT`: Volumer: `postgres-volume` 3,9 GB brukt, `crm-volume` 1,3 GB (filer og CV-er; de er ikke med i dumpen).
- `FACT`: Postgres har ingen `DATABASE_PUBLIC_URL`, så den nås bare over det private nettet. Backupen må kjøre inne i prosjektet.
- **`FACT`, blokkerer: `railway config plan` i dag gir `1 to add (backup), 2 to change, 1 to destroy`. Slettingen er `crm.LEGAL_MCP_TOKEN`** (juridisk MCP, horizon#11), fordi variabelen finnes på Railway men ikke i `railway.ts`, og variablene styres av fila (`variables: managed`). Kjøres `config apply` slik koden står, slutter juridisk-MCP-en å virke. Det samme gjelder alle valgfrie backup-variabler som settes i dashbordet uten å stå i fila (`BACKUP_PREFIX` og `BACKUP_HEARTBEAT_URL` står i README, men ikke i `railway.ts`).
- `FACT`: drift#107 (åpen) ber om ukentlig dump og minst 5 ukers oppbevaring. README-en har eierens beslutning fra 30.10 om daglig dump (RPO 24 t). Oppbevaringen i README er 35 dager daglig + 400 dager månedlig, ikke 7+4.
- `UNKNOWN`: om Railways egne volumbackuper er slått på for `postgres-volume` (vises ikke i CLI-en). Sjekk under Postgres → Backups i dashbordet.

**plattform (Railway-prosjekt `plattform`)**

- `FACT`: `production` har `web` og `Postgres` (`postgres-ssl:18`, EU West), volum 1,1 GB brukt. `preview` (fra plattform#46, B5) har `preview-web`, `preview-idp` (begge SLEEPING) og `Postgres-PsU8` (0,9 GB, bare oppdiktede data, beskyttet av `scripts/preview-vern.mjs`).
- `FACT`: Ingen backup-kode, ingen `.railway/railway.ts`, ingen buckets. Railway-oppsettet er gjort i dashbordet. `CLAUDE.md` sier «ingenting Railway-spesifikt i koden».
- `FACT`: To databaseroller. `web` har `DATABASE_URL` (approllen, bare DML i `public`) og `MIGRATE_DATABASE_URL` (eier). `scripts/migrer.mjs` lager approllen på nytt fra `APP_DB_PASSWORD` og gir den tilgang ved oppstart. En restore med `--no-owner --no-acl` fungerer derfor når appen starter etterpå (`ASSUMPTION` for revisjonsskjemaets egne grants, ikke sjekket).
- `UNKNOWN`: om PR-miljøer er slått på og bygger på `preview`. I så fall kopieres en backup-tjeneste i `preview` til hvert PR-miljø.

**Lagring**

- `FACT`: Ingen lagring er valgt. drift#107 peker på Azure Blob i Norway East, men det venter på drift#47 (Azure-abonnement, åpen, ikke opprettet). `FACT` fra README: Azure Blob er ikke S3-kompatibelt, så `s3.sh` må få en Blob-variant hvis valget blir Azure.

## 2. Foreslått løsning (lik for begge apper)

Én kodebase (`horizon/backup/`), to tjenester per miljø:

1. **`backup`** (cron daglig): dagens `pg-backup.sh`. pg_dump 18, custom-format med innebygd zlib-komprimering (`--compress=6`, samme algoritme som gzip). Jeg foreslår custom-format framfor `.sql.gz`, fordi `pg_restore --list` kan sjekke fila og man kan hente ut enkelttabeller. Fila krypteres med age og legges i en bucket utenfor Railway.
2. **`backup-verify`** (cron ukentlig, ny): henter `latest` med en lesenøkkel, sjekker sha256, dekrypterer, starter en **engangs-Postgres 18 inne i containeren** (`initdb` i `/tmp`, unix-socket, ingen ekstra databasetjeneste), kjører `pg-restore-check.sh` og sammenligner radtallene med manifestet. Den sender heartbeat bare når alt stemmer. Den rapporterer og retter ikke opp noe selv.

**Tidspunkt**: horizon 00:47 UTC (som i koden). plattform 01:17 UTC, så de ikke kjører samtidig. Verify søndag 03:30 UTC (horizon) og 04:00 UTC (plattform).

**Oppbevaring** ligger i bucketens lifecycle-regler, ikke i koden, så skrivenøkkelen trenger ikke slette-rett:

| Prefiks | Utløper etter | Gir |
|---|---|---|
| `<app>/daily/` | 8 dager | 7 daglige |
| `<app>/weekly/` | 36 dager | 5 ukentlige (første vellykkede dump i ISO-uka) |
| ikke-gjeldende versjoner | 7 dager | overskrevet objekt kan hentes i en uke |

`DECISION`: oppdraget sa 4 ukentlige (29 dager). Det er under kravet i drift#107 om minst 5 uker, så jeg foreslår 5. Velg 4 eller 5, og om månedskopiene (400 dager) skal beholdes i tillegg. Fjernes de, forsvinner det ene gjenopprettingspunktet som er eldre enn en måned. Slår leverandøren på object lock, bør `daily/` og `weekly/` ha compliance mode i hele perioden.

**Kryptering**: age til to offentlige nøkler (Nithu + én person til, private nøkler i passordhåndtereren), pluss én egen verify-nøkkel. `DECISION`: verify-tjenesten trenger en privat nøkkel på Railway, og det bryter README-regelen om at ingen privat nøkkel er der. Argumentet for: ROS H-01 handler om å miste Railway, og den som får tak i Railway-kontoen har prod-databasen uansett. Alternativet er at verify kjører ukentlig via en systemd-timer på PC-en eller noden, men den maskinen går ikke 24/7. I tillegg tester et menneske restore én gang i måneden med sin egen nøkkel (README-oppskriften), så det er sikkert at nøkkelen i passordhåndtereren faktisk virker.

**Lagringssted** (`DECISION`, blokkerer alt annet):

| Valg | Kode | Merknad |
|---|---|---|
| A. Azure Blob, Norway East | `s3.sh` → Blob-PUT med SAS (create/write, ingen delete), ~30 linjer | følger ADR-0024, men venter på drift#47 |
| B. S3-kompatibel EU-leverandør (f.eks. Hetzner, Scaleway, Backblaze EU, Cloudflare R2 med EU-jurisdiksjon) | ingen, koden er klar | ny underleverandør: DPA og drift#19/#20 |
| C. Railway Bucket | ingen | samme leverandør, så det oppfyller ikke ROS H-01. Bare som midlertidig løsning. `UNKNOWN`: støtte for lifecycle |

Anbefaling: blir ikke drift#47 løst innen en uke, ta B nå og flytt til A senere. Bruk én bucket per app og miljø (`horizon-prod`, `plattform-prod`, `plattform-preview`), så hver nøkkel bare når sin egen bucket.

**Varsling**: `BACKUP_HEARTBEAT_URL` og `BACKUP_VERIFY_HEARTBEAT_URL` peker på en dead-man's switch, for eksempel healthchecks.io med 25 t for backup og 8 d for verify. Den sender varsel til Slack eller e-post når pingen uteblir. En feilet kjøring gir exit ≠ 0 og vises på Railway. `UNKNOWN`: om Railway varsler om feilede cron-kjøringer uten at noen ser i dashbordet.

**Plattform-spesifikt**

- `DECISION`: tjenesten bygges fra `Solar-Consulting/horizon` med `rootDirectory: backup`. Da finnes koden ett sted, og plattform-repoet slipper Railway-spesifikk kode, slik `CLAUDE.md` krever. Ulempen er at en endring i horizon/backup også redeployer plattform-backupen. Alternativet er å kopiere `backup/` til plattform.
- Bruk `DATABASE_URL = ${{Postgres.DATABASE_URL}}` (superbruker) i production og `${{Postgres-PsU8.DATABASE_URL}}` i preview, ikke `web` sin `DATABASE_URL`, fordi approllen ikke ser alt. En egen rolle med bare `pg_read_all_data` er bedre, men krever en endring i databasen og er dermed operatør-gated. Det kan komme senere.

## 3. Vises i preview først

1. **plattform `preview`** først. Det er det eneste preview-miljøet, og basen har bare oppdiktede data. Legg til `backup` og `backup-verify` med bucket `plattform-preview`, kjør begge manuelt, og sjekk at loggen slutter med `ferdig` og `OK: N tabeller`. Det tester imaget, Railway-cron, bucket, lifecycle og verify mot ekte leverandør, uten persondata.
2. Kontroller at PR-miljøer ikke arver tjenesten. Den nye miljøsjekken (`BACKUP_ALLOWED_ENVS`, se §6) gjør at den uansett logger «av» der.
3. **horizon** har ikke preview. Rekkefølge der: `railway config plan` (skal vise `1 to add` og **0 to destroy**) → `config apply` uten `BACKUP_ENABLED`, så første kjøring logger «av» → én kjøring med `BACKUP_PREFIX=horizon-proeve` → restore-test lokalt etter README → bytt til `horizon`.
4. **plattform production** sist, med samme rekkefølge.

## 4. Variabler og hemmeligheter Nithu må sette (bare navn)

Utenfor Railway: bucket(er) med versjonering og lifecycle; én skrivenøkkel per bucket (Put+Get, ikke Delete/List); én lesenøkkel per bucket (Get+List); age-nøkkelpar (personlige og verify); heartbeat-sjekker. Hemmeligheter skrives inn i Railway-dashbordet, aldri i chat eller fil.

| Tjeneste | Variabler (hemmelig = *) |
|---|---|
| `backup` (alle tre miljøer) | `BACKUP_ENABLED`, `DATABASE_URL`* (referanse), `BACKUP_AGE_RECIPIENTS`, `BACKUP_S3_ENDPOINT`, `BACKUP_S3_BUCKET`, `BACKUP_S3_REGION`, `BACKUP_S3_ACCESS_KEY_ID`*, `BACKUP_S3_SECRET_ACCESS_KEY`*, `BACKUP_PREFIX`, `BACKUP_HEARTBEAT_URL`, `BACKUP_ALLOWED_ENVS` (ny) |
| `backup-verify` (ny) | `BACKUP_VERIFY_ENABLED`, `BACKUP_S3_ENDPOINT`, `BACKUP_S3_BUCKET`, `BACKUP_S3_REGION`, `BACKUP_S3_ACCESS_KEY_ID`* og `BACKUP_S3_SECRET_ACCESS_KEY`* (lesenøkkelen), `BACKUP_PREFIX`, `BACKUP_VERIFY_AGE_IDENTITY`*, `BACKUP_VERIFY_HEARTBEAT_URL`, `BACKUP_ALLOWED_ENVS` |
| horizon `crm` | ingen ny verdi. `LEGAL_MCP_TOKEN` må bare inn i `railway.ts` som `preserve()` før apply |

Velges Azure (A), erstattes `BACKUP_S3_*` med én SAS-URL per tjeneste (navn settes i den PR-en).

## 5. Kost (`ASSUMPTION`, listepriser etter hukommelsen, ikke sjekket)

- Railway-compute: noen minutter per kjøring, ca. 1 vCPU / 1–2 GB → under 1 USD i måneden per app. Verify bruker mest RAM og disk, men bare én gang i uka.
- Egress fra Railway (ca. 0,05 USD/GB): med en daglig dump på 1 GB blir det ca. 30 GB → 1,5 USD i måneden. `UNKNOWN`: faktisk dumpstørrelse.
- Lagring: 12 kopier à ≤ 1 GB → under 1 USD i måneden hos alle valgene.
- Totalt omtrent 2–5 USD i måneden for begge appene.

## 6. Risiko

- **`config apply` sletter `LEGAL_MCP_TOKEN`** og alle backup-variabler som ikke står i `railway.ts`. Les alltid `plan` før `apply`, og kjør ikke apply når den viser `to destroy` > 0.
- `UNKNOWN` størrelse. Én PUT har et tak på 5 GB, og skriptet stopper høylytt hvis dumpen er større. Mål før påslag: `railway ssh -s Postgres -- sh -c 'psql "$DATABASE_URL" -XAtc "select pg_size_pretty(pg_database_size(current_database()))"'` (`ASSUMPTION`: at `railway ssh` virker mot Postgres-tjenesten).
- Verify restorer inne i containeren, så den trenger midlertidig disk på 2–3 ganger dumpen. `UNKNOWN`: Railways tak for midlertidig disk.
- Den private verify-nøkkelen ligger på Railway (se §2, `DECISION`).
- PR-miljøer i plattform kan arve tjenesten (`UNKNOWN`). Miljøsjekken stopper det.
- Restore gir ikke tilbake roller og grants. I plattform lager `migrer.mjs` dem ved oppstart. I horizon kjører `crm` migreringer ved start. Filene på `crm-volume` er ikke med (egen `TODO` i README).
- Lagringsvalget krever en DPA. Persondata i en ny underleverandør er et juridisk spørsmål (drift#19/#20), ikke et teknisk.

**Tilbakerulling**: fjern `BACKUP_ENABLED` / `BACKUP_VERIFY_ENABLED`, så logger neste kjøring «av». Tjenestene skriver aldri til databasen. Å fjerne en tjeneste helt (ut av `railway.ts` + apply, eller via dashbordet) er operatør-gated. Gamle objekter i bucketen utløper av seg selv via lifecycle.

## 7. Kodeendringer (én PR per repo, ikke laget)

**Solar-Consulting/horizon**

- `.railway/railway.ts`: `LEGAL_MCP_TOKEN: preserve()` på `crm` (må med først). `BACKUP_PREFIX`, `BACKUP_HEARTBEAT_URL` og `BACKUP_ALLOWED_ENVS` på `backup`. Ny tjeneste `backup-verify` (samme kilde, `cronSchedule: "30 3 * * 0"`, `NEVER`). Ta gjerne med `restartPolicy`-driften `plan` viser på `crm`/`worker`.
- `backup/pg-backup.sh`: ukentlig kopi med markør per ISO-uke (`weekly/YYYY-Www/DONE`), som erstatter eller kommer i tillegg til månedskopien (`DECISION`). Filnavn fra prefikset i stedet for hardkodet `horizon-`. Stopp hvis `RAILWAY_ENVIRONMENT_NAME` ikke står i `BACKUP_ALLOWED_ENVS`.
- `backup/pg-verify.sh` (ny): `initdb` + `pg_ctl` på socket i `/tmp`, identiteten fra `BACKUP_VERIFY_AGE_IDENTITY` skrives til en 0600-fil, så `pg-restore-check.sh s3:latest`, så heartbeat. Exit ≠ 0 ved avvik.
- `backup/Dockerfile`: `COPY pg-verify.sh`.
- `backup/README.md`: ny oppbevaringstabell, verify-tjenesten, bruk fra plattform, retting av «drift#47 (lagringssted)» (#47 er Azure-abonnementet).
- Bare hvis Azure (A): `backup/blob.sh` (PUT/HEAD/GET med SAS), og valg mellom S3 og Blob i begge skriptene.
- Test: samme oppsett som 30.10 (PG18 + moto) for ukemarkøren, miljøsjekken og `pg-verify.sh`, pluss `shellcheck`.

**Solar-Consulting/plattform**

- Ingen endringer i appen.
- `docs/backup.md` (ny): hvor dumpen ligger, at koden er `horizon/backup`, Railway-oppsett for `backup`/`backup-verify` i `preview` og `production` (dashbordet, siden repoet ikke har IaC), og restore: tom PG18 → `pg-restore-check.sh` → pek `MIGRATE_DATABASE_URL`/`DATABASE_URL` dit → `migrer.mjs` lager approllen på nytt.
- `docs/flytt-til-azure.md` steg 2: datatrekket kan bruke siste backup.
- `DECISION`: vil dere ha IaC, kan `.railway/railway.ts` lages via `railway config pull`. Velger dere å kopiere koden, kommer `backup/` i tillegg.

## Ikke gjort

Ingen `apply`, deploy, variabler eller endringer i noe miljø. `config plan` ble kjørt fra en kopi i scratch med midlertidig link, og linkene er fjernet. Variabler er lest bare som navn. Dumpstørrelsen er ikke målt.
