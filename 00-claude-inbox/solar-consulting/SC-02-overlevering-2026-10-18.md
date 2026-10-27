# SC-02 — overlevering til orchestrator-1

paal-1, 2026-10-18 ~23:30 CEST. Alt som står åpent i SC-02, med kommandoer og tall. Alle tall er
`FACT` med kilde der det står prod, og `ASSUMPTION` der det står anslag.

## 1. Status i prod nå

| | Tall | Kilde |
|---|---|---|
| Tildelinger | 387 (384 med dedupKey; 262/263/264 beholdt uten nøkkel med vilje) | read-only 18.10 |
| Dobbelttellinger | 0 | `run-awards-dekning.sh` |
| contractEnd | 209 / 387 (54,0 %), 112 `FACT_DATE`; IT 30 / 62 | etter `raa-arkiv:hent` 18.10 |
| org.nr. | 363 / 387 (93,8 %) | etter første Brreg-natt |
| Radar | 22 innen 12 mnd, 3 IT | `radar-expiry` 18.10 |
| Historikk i tenders | 107 925 av 110 059 (ingestedBy = history-backfill) | read-only 18.10 ~21Z |
| Historikk-tildelinger | 0 (sperren åpnet 12:04, første kjøring i natt) | |

Env i prod (worker + crm, satt av orchestrator-1): `AWARDS_DEDUP_APPLY=1`, `AWARDS_INCLUDE_HISTORY=true`,
`AWARDS_HISTORY_MAX_PER_RUN=2000`.

## 2. Merget i SC-02

#194 dedup + radar + Brreg · #210/#224 eval · #212 `raa-arkiv:hent` · #221 historikk-sperre (env, tak,
tilbakerulling) · #225 passert sluttdato = «Sjekk» · #229 IT = hoved-CPV · #233 rammeavtale-tak ·
#239 `down()` SC-02 + SC-07 · #251 Brreg 1 000 per natt.

## 3. Åpent: måling av historikk-natt 1 (den eneste aktive oppgaven)

`awards-backfill` kjører 02:00 Europe/Oslo (00:00Z), `supplier-brreg-match` 02:20, og `radar-expiry` 03:15.

**Forventet:** +~5 400 tildelinger (`ASSUMPTION` fra kopien: 2 000 anskaffelser ga 5 411). **Stopp ved
avvik over ±10 %.** Utvalget går nyeste først, og historikken er nå 3× større enn kopien, så fordelingen kan
avvike de første nettene.

En bakgrunnsjobb i paal-1 venter på kjøringen og måler automatisk. Hvis paal-1 er stengt, gjør dette
(read-only, fra `projects/anbud/crm`, med `railway link --project anbud --environment production`):

```
./scripts/baseline/run-awards-dekning.sh ETTER-historikk-natt1
```

Det skriver `crm/eval/sc02-awards-dekning-ETTER-historikk-natt1-<dato>.txt`. Sammenlign `AWARDS_TOTAL` med
387 + ~5 400. Sjekk også kjøremeldingen:

```sql
select agent, started_at, status, message from agent_runs
where agent in ('awards-backfill','supplier-brreg-match','radar-expiry') and started_at > '2026-10-18 23:30'
order by started_at;
```

**Tilbakerulling ved avvik:** lukk sperren først (fjern `AWARDS_INCLUDE_HISTORY` på worker og crm), så
`npm run awards:historikk-tilbake` (tørrkjøring) og deretter `-- --apply`. Hver rad arkiveres i
`award-merges` med snapshot. Testet på kopien: 27 638 rader tilbake til nøyaktig 387 på 30 min.

## 4. Relink-sjekken i kveld (avsluttet, ingen tiltak)

- Koden nøkler på roten ved kjøretid. En rad med gammel nøkkel arkiveres som dublett før raden med ny nøkkel lages.
- Read-only: 0 av 384 nøkler avviker fra dagens rot. Procedure_id fordelt på flere røtter: 0 av 59 992 (0 av 15 931 historiske med vinner).
- infra-1 målte det samme.

## 5. Kjente forbehold (står i koden og i #221-planen)

- 1 382 av 1 537 IT-rader i full historikk (kopi) har passert sluttdato og merkes «Sjekk». Bare ~155 er reelt kommende.
- 575 av 1 537 IT-rader har rammeavtale-tak og dempes i `importance` (0,5, `ASSUMPTION`).
- IT etter hoved-CPV tar 105 av 1 537 rader ut av IT. De fleste er bygg/rådgivning, men noen er grensetilfeller (PLS, medisineringsstøtte, kontaktsenter).
- Brreg-kontrollkøen kan bli ~450 (anslag, ligger på operatørlista). Fra natt til 19.10 behandles 1 000 per natt.
- contractEnd for historikken er bare ~10 % på kopien (mangler signeringsdato, og TED-historikken har ingen datoer).

## 6. Data-funn uten eier (meldt tidligere)

- Leverandør #92 «Multiconsult» heter `__NEEDS_TRANSLATION_5f59ebb__` i prod (på tavla).
- aslisten-crm-backup: manifestet melder manglende/endrede filer i prod (16.10 og 18.10). Trolig de 35 kjente tapte dokumentfilene fra o10. Det er en rapport, ingen handling.

## 7. Lokalt i paal-1 (ingenting her trengs i prod)

- Worktree `~/code/Veldora-sc02`. Grener: alle SC-02-grener er pushet og merget. `sc-02-historikk-natt1` er en tom målegren.
- Docker: `sc02-pg` (PG16) og `sc02-pg18` (PG18, base `hist` = prod-kopi med full historikk fra 18.10 00:35, `downtest`). Kan stoppes.
- Ukommitert hjelpeskript `projects/anbud/crm/.sc02-runjob.mts` (kjører én jobb mot lokal base). Ikke innsjekket med vilje.
