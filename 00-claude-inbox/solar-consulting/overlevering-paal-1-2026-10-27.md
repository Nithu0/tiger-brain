# Overlevering paal-1, 27.10.2026

Bygger på `overlevering-paal-1-2026-10-22.md`. Tallene er målt read-only mot prod.

## Gjort siden sist

- #299 (IT-regel), #300 (eval natt 1+2) og #308 (DPS: generiske ESPD-poster er egenerklæring) er alle **merget** med grønne sjekker. DPS_AGENT_ENABLED står av.
- Historikkfyllet er **ferdig**. Natt 4 (22.10) tok de siste 3 958 anskaffelsene. Fra 23.10 er det bare vanlig drift.
- Dekning etter ferdig historikk (26.10): 38 339 tildelinger. contractEnd 27,3 %, verdi 76,8 %, org.nr. 87,8 %. IT: 25,2 / 83,0 / 85,0 %. Leverandører uten org.nr. 25,9 %.
- Kryssdubletten (1 av 38 339) er forklart: anskaffelse 11665, Sikkerhetsmakulering AS, med LOT-0000 i én kunngjøring og ingen delkontrakt-ID i en kunngjøring fra samme dag. Dataene er ikke rørt.

## Åpent

1. **Push:** `wip/paal-1-natt3` i `~/code/Veldora-sc02` har to lokale eval-commits (natt 3 og historikk ferdig). Bare eval-filer. De er ikke pushet og venter på godkjenning.
2. **Kryssdubletten:** mulig planner-regel om at «MISSING» slås sammen med den eneste reelle delkontrakten når anskaffelsen bare har én. Den er ikke laget. Rådata mangler for å bekrefte at det er riktig.
3. **contractEnd stopper på ~10 400** fordi bare 1 098 av 22 165 anskaffelser har varighet. Neste løft må komme fra TED-varighet eller dokumentene, ikke fra flere kunngjøringer.
4. **DPS:** de 10 radene i `eval/DPS-VURDERINGER-2026-10-21.md` venter på menneskelig kontroll før flagget kan slås på.

## Neste steg

- Push wip-grenen som eval-PR når det er godkjent.
- Sjekk at radar-expiry etter #299 har flyttet de 18 ikke-IT-radene ut av IT (read-only: `vertical='it' and rank is not null` skal ikke lenger ha NTNU campussamling).

## Hvor ting ligger

- Read-only-spørringer mot prod: `scratchpad/ro.sh <fil.sql>` (nekter uten READ ONLY). Det samme mønsteret finnes i `scripts/baseline/run-awards-dekning.sh`.
- Lokal Postgres `sc02-pg18` er stoppet (db `dpsmig` med DPS-kopi fra 21.10).
