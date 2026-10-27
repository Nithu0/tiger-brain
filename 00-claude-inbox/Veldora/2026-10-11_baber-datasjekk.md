---
date: 2026-10-11
project: Veldora-radar / projects/anbud/crm
subject: Produksjonssjekk — baber.a@solarconsulting.no, kommentar-vurderinger
status: FACT (read-only query mot produksjons-Postgres via `railway ssh --service crm`)
---

# Datasjekk: baber.a@solarconsulting.no — 2026-10-11

Operatørens spørsmål: er noe av det juristen la inn i dag gått tapt, gitt kontraktsavviket
infra-1 meldte på PR #112/#113 (POST `/anbud/kommentar/:rowId/vurder` svarer med en konvolutt
`{saved, row, counts}`, dashboardet leser en rad)?

Metode: lest produksjons-Postgres (Railway-prosjekt `anbud`, service `crm`) read-only via
`railway ssh --service crm` + `pg`-klienten som allerede ligger i det kjørende image-et (kun
`SELECT`, ingen skriving/migrering). Ingen `.env`-verdier printet; DATABASE_URL ble aldri
vist, bare injisert i subprosessen.

## a) Rolle

FACT — bruker finnes: id 3, e-post `baber.a@solarconsulting.no`, navn «Baber», **rolle
`member`** (ikke admin, ikke viewer/«reader»). `created_at` 2026-10-09T13:14, siste
`updated_at` på brukerraden 2026-10-11T08:45:42Z (ikke et eksplisitt last-login-felt —
Payload sporer ikke innlogging som eget felt i dette schemaet, kun `updated_at` på raden).

Med rolle `member` har han skriverett til `kommentar-vurderinger` — både collection-access
(`create/update: isMemberOrAdmin`) og endepunktets egen sjekk (`role === 'admin' || role
=== 'member'`) lar ham skrive. Rollen er altså IKKE problemet.

## b) Antall rader / tidsrom

FACT — `kommentar_vurderinger`-tabellen i produksjon har **0 rader, globalt** (ikke bare for
ham — for alle, hele tiden). `kommentar_vurderinger_log` (sub-tabellen for historikk) er
tilsvarende tom. `legal_questions` og `klage_cases` har heller ingen rader knyttet til ham
(`asked_by_id` / `created_by_id`).

Det han faktisk har produsert i dag: **16 rader i `activities`** (8 par
`decision`+`status-change`, auto-genererte audit-rader fra triage/kvalifikasjon-flyten, IKKE
fra Juristvurderinger), tidsstemplet 2026-10-11T08:46:56Z → 10:44:27Z. Ingen av disse ser
halvferdige ut (ingen tomme påkrevde felter — de er server-genererte audit-rader uten
brukerinnhold å mangle).

HTTP-logger for de deployene jeg kunne hente (live 09:36:55–10:36 og 10:38:27→nå) viser kun
200-OK-kall fra dashbord-backend-trafikken hans (`/api/anbud/triage/*`, `/api/opportunities`,
`/api/users/me` osv.) — **ingen kall til `/api/anbud/kommentar` eller `/vurder` i det hele
tatt** i de loggvinduene jeg fikk tak i. Tre eldre deploy-ID-er (de som var live
08:46–09:36, dvs. da hans første aktivitet skjedde) har ingen HTTP-logger igjen i Railway
(0 linjer tilbake — sannsynlig retention/garbage-collection på fjernede deploys). For det
vinduet er jeg UNKNOWN på hva han så.

## c) Er noe tapt? — FACT: Nei, ikke i `kommentar-vurderinger`

**FACT**: Ingenting er tapt der, fordi ingenting ble lagret der i utgangspunktet — tabellen
er tom. Kontraktsavviket infra-1 fant (konvolutt vs. rad) er reelt i koden, men det oppstår
*etter* at `payload.create`/`payload.update` allerede har kjørt i endepunktet — en
vellykket POST persisterer alltid raden først, før svaret bygges. Siden tabellen er tom,
har INGEN POST til dette endepunktet noensinne fullført i produksjon — verken for Baber
eller andre. Konvolutt-bugen i seg selv forårsaker aldri datatap; den gjør i beste fall at
en reell lagring ser ubekreftet ut.

Hans 16 `activities`-rader fra triage/kvalifikasjon-arbeidet i dag er alle intakte — ingen
indikasjon på tap der.

**Mulig forklaring (ikke bekreftet — merk som ASSUMPTION):** migreringen som la til
`kommentar-vurderinger` (`20261011_095127_juristvurderinger`) gikk først live i produksjon
kl. **10:38:27Z i dag** (bekreftet i `payload_migrations`-tabellen). Hvis Baber var inne på
juristsiden/`/kommentar`-visningen tidligere på morgenen (08:46–10:36), eksisterte
funksjonen ikke i den da-kjørende koden — noe som kan ha gitt en feil (404/manglende
endepunkt) uavhengig av konvolutt-bugen. Dette er ASSUMPTION, ikke verifisert — HTTP-loggene
for det vinduet er borte.

## d) Feilmeldingen

UNKNOWN — fant ikke en konkret feilmelding knyttet til `/anbud/kommentar` i de HTTP-loggene
jeg fikk tak i (kun infra-1s egne curl-smoketest-kall rundt deploy-tidspunktet 10:38:51–52,
som får 401 fordi de ikke sender et gyldig token — det er forventet smoke-test-oppførsel,
ikke et symptom hos Baber). Sjekket `agent_runs` for feilede jobber i dag: tre typer feiler
gjentatt (`sync-workspace` — Google-token invalid_grant, kjent/pre-eksisterende;
`assess-requirements`; `tender-brief`) — ingen av dem er koblet til ham eller til
kommentar-funksjonen.

## Konklusjon til operatør

- Rolle: `member` — har skriverett, rolle er ikke årsaken.
- 0 rader i `kommentar-vurderinger` i produksjon, for alle brukere. Hans eneste fotavtrykk i
  dag er 16 intakte triage/kvalifikasjon-audit-rader (08:46–10:44).
- Er noe tapt? **FACT: Nei** — i `kommentar-vurderinger` finnes det ingenting å tape; en
  vellykket lagring ville alltid landet i databasen før konvolutt-bugen kunne vise seg.
  Kontraktsavviket er en bekreftelses-/visningsbug, ikke et datatap-scenario.
- Den konkrete feilmeldingen han så: UNKNOWN. Beste kandidat (ASSUMPTION): han kan ha prøvd
  juristsiden før kl. 10:38:27 da funksjonen ennå ikke var live.

## Metodenotat (for etterprøving)

- `railway link -p 2675f463-91bf-4a31-94b9-e9978e73de4c -e production` (prosjekt `anbud`),
  deretter `railway ssh --service crm -- ...` for read-only SQL (pg-driver i det kjørende
  image-et) og `railway logs <deployment-id> --service crm --http --json --lines 500` for
  HTTP-logger. Unlinket igjen etter jobben (`railway unlink --yes`). Ingen migrasjoner, ingen
  writes, ingen `.env`-verdier printet.
