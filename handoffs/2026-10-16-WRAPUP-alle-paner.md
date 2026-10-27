# WRAP-UP 2026-10-16 — alt som sto åpent i de åtte panene

Høstet 06:20–06:40Z av orchestrator-1, åtte parallelle lesinger av
`00-firm-bus/inbox/<rolle>.md` + handoffs + `gh` + maskinens egen tilstand.
Alle påstander under er sjekket mot KODEN/CI/DB, ikke mot forrige overlevering —
fem påstander fra 15.10 viste seg utdaterte og står under §1.

Cockpiten på `localhost:3200` er samtidig gjort til en tjeneste som kommer opp
ved oppstart (§5). Det var den ene tingen operatøren ba om å få landet.

---

## 1. Lukket siden sist — IKKE bygg disse på nytt

| Påstand fra 15.10 | Hva som faktisk gjelder |
|---|---|
| «Hovedsjekkouten står på `tools-1/anbud-modell-vakt`, fiksen i #94 er ikke i drift» | Sjekkouten står på **main** (`4dd9f2b`), ff-only pull 15.10 kl 23:07:53. `git status` clean. |
| «Boten merget fire PR-er på røde sjekker» | Nei. `merged_by` på #162–#165 er Nithu0, manuelt. Botens nekt-logikk er intakt (#167 merget 16 s etter siste grønne check, #168 med null ikke-success). |
| «infra-1s leak-mønstre fanger ikke glpat/telegram» | Trukket tilbake av tools-1 selv: deres egne prøvetokens hadde feil lengde. Alle ti tokenformer fanges, 49/0 tester. |
| «#92 (nekt-jobb-detektoren) må bygges» | Allerede på main, funnet under rebase. |
| «sk-proj-nøkkelen må roteres» | Operatøren vurderte det unødvendig: 0 rader i memory.db, 2 i én transkripsjon. |
| «Prod er rammet av dedupliseringsfeilen» | Prod er IKKE rammet: 23 fakta, 0 eksakte duplikater, 16 «ekstra» er reelt ulike fakta, lest for hånd. Fiksen (PR #170) er merget. |

## 2. Hva natten faktisk gjorde (og ikke gjorde)

`brain-worker` + `brain-orchestrator` ble startet 14.10 07:48 og **restartet ikke
før 16.10 08:06 CEST**. `nightly-distill`-triggeren fyrte ikke én gang mellom
15.10 05:04Z og 16.10 06:07Z — 27 timer uten kjøring. Natten var ikke «gammel
kode», den var **stille**. Maskinen sto av.

Det som berget det: catch-up ved oppstart i morges bygde mot main (ny fil
`dist/storage/deadletters.js`, mtime 16.10 08:07:01) og destillerte 15.10
komplett — 0 gap, 0 dødbrev. **Fiksen fra #94 er i drift nå**, men fordi maskinen
ble slått på, ikke fordi mekanismen virket.

Hullet som gjenstår: ingenting overvåker «tjenesten kjørte i 48 timer uten å
bygge nytt main», og ingenting varsler at nattens vindu ble hoppet over fordi
maskinen var av. Sjette natt gjentar mønsteret hvis maskinen står av igjen.

## 3. Åpent uten eier — rangert

1. **Altinn-dokumentgapet** (aslisten-crm). Sju saker står `READY_FOR_ALTINN`
   uten vedlegg siden 12.09. Ser grønt ut i admin, ingen flate viser det, kan
   treffe Pål og kunden i Brønnøysund. paal-1 ba om en navngitt eier 15.10
   kl 12:57 — ingen har svart. **Høyest risiko av alt på denne listen.**
2. **PR #164 har aldri hatt en ekte CI-kjøring på treet som landet.** Spørsmålet
   fra 15.10 er nå besvart med hard bevisføring: #163 (`4a75c892`) fikk royktest
   success 14.10 14:56:46Z på landet SHA; #164 (`d4ce3429`) har seks check-runs,
   alle failure 14:31:49, aldri rekjørt, og det finnes ingen push-kjøring for
   `d4ce3429` eller `cd497ba` i hele repo-historien. #162 likeså. NB:
   SHA-ene i OVERTAKELSE-handoffen (`cc6b283`, `7577098`) er feil og finnes ikke.
3. **PR #166 har stått rød i to døgn** (`smoke-konfig.ts`, GRØNN 26 / RØD 1 /
   SKIP 3, kjøring 14.10 17:23Z) og er tre commits bak main — den røde
   royktesten der er bevis for buggen #170 fikset, ikke en dom over fiksen.
   Rebase + ny kjøring før noen tolker rødt som «fortsatt ødelagt».
4. **aslisten #46 → #62 venter merge+deploy.** Begge CLEAN, CI SUCCESS 14.10.
   Konsekvens av å vente: backup-varselet («manifestet melder manglende eller
   endrede filer») fyrer på hver kjøring — det er de samme 35 kjente tapte
   filene fra 26.08-hendelsen, flagget på nytt hver gang fordi `fetch-backup.sh`
   ikke har en baseline. Baseline-bevisstheten ligger nettopp i #46.
5. **Dødbrev er usynlige i helsesjekkene.** `grep distill_deadletters` i
   `_bin/brain-doctor.sh` og `_bin/global-session-context.sh` gir 0 treff. Én
   `SELECT COUNT(*) ... WHERE resolved_at IS NULL` i hver.
6. **50 juni/juli-rader er permanent usynlige for recall** til noen kjører
   engangsinnsettingen (`agent_tasks`-INSERT i `2026-10-14_distill-gap.md` §4
   spor C). Catch-up henter dem aldri — bevisst valg i `nightly-distill.ts:176-182`.
7. **`brief-coverage.ts:39`** (Veldora/anbud/crm) ble dispatchet til tools-1
   15.10 13:10 og aldri utført — ingen commit på filen i noen av de ti
   Veldora-worktreene siden 11.10. De 13 besluttede uten brief står også urørt
   (koster under én krone å kjøre).
8. **12 gamle command-center-PR-er** (#6, #48–#57, #63, #64, #69) — CI lever
   igjen, ingen har vurdert dem.
9. **aslisten #35/#36/#37** har ferdige arbeidslister, #38 er landbar. Uten eier
   siden paal-1 overdro.
10. **learning-1-restene:** issue 054 (målvariabelen blander «vil by på» med
    «verdt å svare i dialog», én linje i `learnableRecords`) og issue 055
    (`profileN` teller feil mot 30-terskelen, `endpoints/triage.ts:305`).
11. **admin-1-residuet:** `legal/terskel.ts` er uwiret mens ADR-0018 kan leses
    som at den er i drift; `klage/deadlines.ts:111` hardkoder 30 dagers
    søksmålsfrist mot korpus-leses-regelen; `deadlineCheck.status` (`types.ts:51`)
    når ikke lister/header — ti kallsteder, ingen logikk.
12. **Jev-reranking** i `legal/retrieve.ts`: målt +0,12–0,16 MRR over 860 kall,
    0 feil, ingen gate. Og `probeVector()` mot prod via `/juridisk/kilder` —
    ett kall avgjør issue 019.
13. **Opprydding:** 6 landede grener + worktrees (bevist trygt), paal-1s fire
    worktree-rester, 120+ grener / 46 worktrees totalt.
14. **Heygen auth-fellen:** `HEYGEN_NONINTERACTIVE` defaulter til API-nøkkel og
    **erstatter lagret OAuth stille** — en executor kan rive operatørens
    kreditt-sesjon. Ingen eier.

## 4. Venter på operatøren

- **Altinn-saken**: gi den en eier (se §3.1).
- **#164**: `workflow_dispatch` på tilsvarende commit, eller aksepter risikoen.
- **aslisten #46 → #62**: merge + deploy, i den rekkefølgen.
- **PR #170s migrasjon mot prod** + evt. backfill av `ingest_input_hash` —
  inntil sju engangs-duplikater kan oppstå på NULL-hash ved første re-ingest.
- **Legal-engine, fem beslutninger** (B1 er besvart: internt verktøy først):
  B2 rettighetsmatrise (12/14 UNKNOWN), B3 KOFA-rettighetsgrunnlag, B4 juristens
  59 ASSUMPTION-rader + tom `terskelverdier.json`, B5 portaltilgang (ToS
  Mercell/TendSign/EU-Supply/Ivalua). Pluss: koble `eval/legal-gold.json`
  (45 spørsmål) til CI — i dag fanges feil hjemmel ikke.
- **Portal-ToS krever et menneske i nettleser** (TendSign + Ivalua har
  `Disallow:/` også på vilkårssiden). Spesifisert 14.10, ingen svar.
- **Sletting** av 6 grener + worktrees, og paal-1s fire rester.
- **Heygen**: bruksvalg + `auth login --oauth`/`--device`. VoiceStudio-samtykke.
- **`compare-brief-models.ts`** — kvaliteten på haiku-briefen (61 % kortere) er
  aldri sammenlignet.
- **Kjedevakt** (tenders → opportunities → briefs) — spesifisert 14.10, ikke bygget.
- **Node-stacken**: rotasjon av to passord, forbrukstall Railway/Vercel,
  DPA Anthropic/Google — fra 13.10, ingen bevist fremdrift.

## 5. Cockpiten starter nå ved oppstart

`_bin/cockpit-install-systemd.sh` (ny) skriver tre enheter:

- `cc-api.service` — Fastify på `127.0.0.1:3100`, kjørt med **tsx fra `src/`**
- `cc-web.service` — Next.js på `127.0.0.1:3200`, `next dev`
- `cockpit.target` — én bryter, `WantedBy=default.target`, Linger=yes

Hvorfor dev-modus og ikke produksjonsbygg: `apps/web/.next` har ingen `BUILD_ID`
— flaten operatøren verifiserte i DOM 15.10 var et `next dev`-bygg, og
`apps/api/dist/index.js` er fra 23. juni. `node dist/index.js` ville servert fire
måneder gammel API bak dagens flate. Et fullt `npm run build` er 25 pakker og kan
feile ved boot; da står cockpiten mørk, som er tilstanden uniten skal fjerne.
Prisen er at første GET etter boot kompilerer i noen sekunder.

Verifisert, ikke antatt:

- `systemctl --user stop cc-api cc-web` → `start cockpit.target` (boot-stien,
  ingen eksplisitt service-start): begge `active`, `GET /` på 3200 svarte 200
  etter ~4 sekunder.
- `/api/health` → `{"status":"ok"}` med db/firmBus/brain/workspace alle ok.
- `/api/projects` → 15 prosjekter, Solar Consulting inkludert.
- `NRestarts=0` på begge, auth er `authDisabled: true` (ingen `AUTH_SECRET`),
  så flaten åpner direkte uten innlogging.
- Same-origin-proxyen gjennom web (`:3200/api/*`) svarer 200.

Tre feller fanget under arbeidet, verdt å kjenne:

1. Backticks i en ikke-quotet heredoc kjørte `systemctl stop` som
   kommando-substitusjon midt i installasjonen («Too few arguments.»).
2. `tsx` og `next dev` avslutter med 143 på SIGTERM, så hver ryddige
   `systemctl stop` leste som `failed` til `SuccessExitStatus=143 SIGTERM` kom inn
   — det ville fått helsesjekker som teller feilede units til å rapportere en
   feil som ikke finnes.
3. `StartLimitBurst=10` per 10 min betyr at to-tre re-kjøringer av installeren
   treffer `start-limit-hit`; installeren gjør nå `reset-failed` først.

Service-worker-fellen fra 15.10 står fortsatt: cachen `cc-v1` kan servere gammel
bundel offline-først. Ser du ikke ny kode — hard reload, eller unregister SW.

**Enhetene eier portene 3100/3200.** Skal du kjøre `npm run dev` i en pane:
`systemctl --user stop cockpit.target` først, ellers EADDRINUSE.

---

Kilder: `00-firm-bus/inbox/{infra,tools,data,trading,learning,paal,admin,orchestrator}-1.md`,
`handoffs/2026-10-15-orchestrator-1-OVERTAKELSE.md` + 2026-10-13/14-handoffene,
`00-claude-inbox/{Veldora,aslisten-crm,command-center}/`, `gh` mot
Nithu0/{Solar-Consulting,command-center,aslisten-crm,Veldora}, `journalctl --user`,
og `sqlite3 -readonly` mot memory.db.
