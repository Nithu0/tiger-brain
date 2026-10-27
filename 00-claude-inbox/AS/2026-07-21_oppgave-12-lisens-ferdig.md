# Oppgave 12 — Lisensklient + lisensserver-skisse — FERDIG

**Fra:** soking-1 · **Til:** as-1 / operatør · **Dato:** 2026-07-21T22:18+02:00
**Repo:** `~/code/grossist-plattform` (git ikke init ennå — venter på fase 0 / oppgave 1, codex-6)
**Pakker jeg eier:** `packages/license` + `infra/license-server`. Rørte ingen andres pakker.

## Status: grønt

- `@grossist/license`: **13/13 tester**, `tsc` bygger rent.
- `@grossist/license-server`: **4/4 tester**, `tsc` bygger rent.
- Lint rent på begge. Node 24, pnpm 9.15.4, vitest 3.
- Kun syntetiske data. Ingen secrets i repo. Ingen push (venter «OK kjør»).

## Hva som er levert (mot rapport §10)

- **Ed25519-signert lisensfil** via Node native `crypto` (ingen avhengigheter): `signing.ts` (`signLicense`/`verifyLicenseSignature`) over kanonisk JSON (`canonical-json.ts`).
- **Zod-skjema** for lisens-payload, signert lisens og heartbeat-metadata — alle `.strict()`: `schema.ts`.
- **Håndhevelsestrapp** (`enforcement.ts`): `valid → warn → grace → restricted (stopp nivå 2-3) → read_only`. `canReadExistingData` er en literal `true` overalt — **kundedata låses/slettes aldri**, eksport er alltid mulig (kontraktsfestet i §10).
- **Heartbeat kun metadata** (`heartbeat.ts`): hostnavn SHA256-hashes, connectors sorteres deterministisk, ingen kundenavn/e-post/orgnr/tall. Serveren avviser ekstra felt (`.strict()`).
- **Hono+SQLite-server** (`infra/license-server/`): `GET /healthz`, `POST /licenses` (signer+lagre), `GET /licenses/:id`, `POST /heartbeats`. Parameteriserte prepared statements — ingen injeksjon.

## Bug-fikser før grønt (code-review-pass, 10 funn adversarielt)

Src var påbegynt men hadde reelle feil. Fikset:

1. **Signatur-verifisering feilet på gyldige lisenser** (`signing.ts`, CRITICAL for funksjon): `createPublicKey()`-wrapper kastet på public KeyObject («expected private»). Fjernet — `verify()` tar public-nøkkel direkte. → signing-testene grønne.
2. **CRITICAL — usignert signeringsorakel på `0.0.0.0`** (`app.ts`/`server.ts`): `POST /licenses` signerte vilkårlig payload med vendor-privatnøkkelen uten auth, bundet til alle interfaces. Én forfalsket enterprise-lisens ville verifisert `true` overalt (public-nøkkel bakt inn i alle klienter). Fikset: **admin-bearer-token påkrevd** (fail-closed ved oppstart) + **binder til loopback** som standard. Ny 401-test.
3. **`restricted` kunne gi mer tilgang enn lisensen** (`enforcement.ts`): hardkodet `[1,4]` ignorerte `allowedRiskLevels` → en lisens uten nivå 4 fikk plutselig nivå 4 etter utløp (privilege-eskalering). Fikset til snitt `{1,4} ∩ grant`. Ny non-exceed-test.
4. **Klokke-tukling manglet helt** (`enforcement.ts`, spec §1.5 krevde det): la til valgfri `maxTimeSeen`-high-water-mark → bakover-hopp > 24t degraderer til **grace** («ukjent tid»), ikke hard stopp. Ny test + tolerance-test.
5. **`not_yet_valid` kunne flagge heartbeat-due** som heartbeat-skjemaet ikke kan kode → runtime-kast. Fikset til `heartbeatDue: false`.
6. **Duplikat `licenseId` → 500**: nå ren **409**. Ny test.
7. Deterministisk nøkkel-sortering i kanonisk JSON (var `localeCompare`, ICU/locale-avhengig → kunne brutt signaturer på tvers av maskiner). Fikset til kodepunkt-orden.

## Bevisst utsatt (dokumentert, ikke blokkerende for skissen)

- **keyId/algorithm/version utenfor signaturen** — ufarlig nå (verify ignorerer keyId, algoritme utledes av nøkkeltype), men bør bindes inn hvis nøkkelrotasjon/multi-keyId innføres.
- **`heartbeat.graceHours`** valideres men er ikke koblet inn i «due»-logikken ennå — reservert felt.
- **`GET /licenses/:id`** returnerer kundenavn til den som har lisens-ID-en (kundens eget navn; lisens-ID = kapabilitet). Bør bak samme proxy/auth i prod.
- **Anti-rollback trenger persistent signert `maxTimeSeen`** på klientsiden — motoren støtter det nå, men lagrings-/signeringslaget hører til klient-integrasjonen (oppgave 11/dashboard).

## Neste

Klar for fase 0 (oppgave 1: git init + workspace-CI). Når CI finnes bør `m365`-connectoren (oppgave 8) få minst én testfil — den bryter i dag `pnpm -r test` (mangler testfiler → exit 1), som er hvorfor jeg kjørte scoped på mine to pakker.

— soking-1
