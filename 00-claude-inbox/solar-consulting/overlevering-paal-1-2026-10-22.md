# Overlevering paal-1 (SC-02 m.fl.)

Skrevet ved PAUSE fra orchestrator-1. Alle tall er målt read-only mot prod, med mindre noe annet står.

## Gjort og pushet

| PR | Hva | Status ved pause |
|---|---|---|
| #282 | Gjenkjøpssignal (r:-rader) | Merget, flagget PÅ. Verifisert 20.10: 202 prediksjoner, 72 innen 3 mnd, linja står i morgenbriefen |
| #289 | «Systemskifte»-seksjon på /marked/gjenutlysning | Merget. Prod har 41 s:-rader, 0 uten kilde (etter data-1s #287) |
| #299 | IT-regel: svake IT-koder (72224000) teller ikke i flertallet under ikke-IT hovedkode | Pushet. 18 av 1010 IT-rader går ut, alle sjekket for hånd, ingen ekte IT |
| #300 | Eval: dekningsmåling etter historikk natt 1 og natt 2 | Pushet |
| #308 | DPS: generiske ESPD-poster er egenerklæring, ikke mangler | Pushet. mangler 56 → 31, ukjent 21 → 46. Ny eval `eval/DPS-VURDERINGER-2026-10-21.md` |

## Historikkfyllet (awards-backfill, tak 8000 per natt)

| Natt | Nye tildelinger | Prognose | Totalt | contractEnd | Verdi | Org.nr. | Kryssdubletter |
|---|---|---|---|---|---|---|---|
| 1 | +5 461 | ~5 400 | 5 829 | 42,5 % | 38,9 % | 92,9 % | 0 |
| 2 | +14 195 | ~20 000 (−29 %, prognosefeil) | 20 021 | 51,2 % | 59,4 % | 90,1 % | 0 |
| 3 | +12 103 | ~13 200 (−8,3 %, innenfor) | 32 117 | 32,2 % | 73,2 % | 88,1 % | **1** |

Natt 3: contractEnd økte bare fra 10 245 til 10 356 i antall. De eldre kunngjøringene mangler varighet. Andelen leverandører uten org.nr. falt fra 34,6 % til 29,2 %, fordi Brreg tar 1000 per natt.

## Åpent

1. **DUP_CROSS_NOTICE = 1 etter natt 3** (`DUP_COMBO doffin:RESULT 1`). Den første kryssdubletten siden dedup-en er ikke undersøkt. Neste steg er å finne raden: samme root + leverandørnøkkel fra to kunngjøringer, med SQL-en i `scripts/baseline/awards-dekning.sql`. Deretter må det avgjøres om det er reroot-tilfellet (#281) eller noe nytt. Ikke rør dataene før årsaken er kjent.
2. **Natt 3-artefaktet** er committet lokalt som WIP: `wip/paal-1-natt3` (6349bb5) i `~/code/Veldora-sc02`. Det er ikke pushet. Det kan pushes sammen med en senere eval-PR.
3. **Natt 4-prognose:** ~1,5 tildelinger per anskaffelse × 8000 ≈ 12 000. Natt 3 ga 1,51. Stopp ved ±10 %.
4. **DPS_AGENT_ENABLED** står av til et menneske har sjekket de 10 radene i `eval/DPS-VURDERINGER-2026-10-21.md`.
5. **Merge-kø:** #299, #300 og #308 venter på merge. Etter #299 flytter radar-expiry (03:15) 18 rader ut av IT, og det bør sjekkes neste natt.

## Hvor ting ligger

- Kode: `~/code/Veldora-sc02/projects/anbud/crm` (worktree). Prod er bare tilgjengelig read-only via `railway ssh --service Postgres` med base64-SQL og `SET TRANSACTION READ ONLY`, kjørt fra den mappen.
- Måling: `scripts/baseline/run-awards-dekning.sh <etikett>`.
- Lokale engangs-Postgres: `sc02-pg18` (db `dpsmig` har fersk DPS-kopi fra 21.10, `hist` har historikk). Den er stoppet, ikke slettet.
- Lokale hjelpeskript (ikke innsjekket): `.sc02-runjob.mts`, `.sc02-mkuser.mts`, `.sc02-skifte.mts`. De nekter å kjøre mot annet enn localhost:5544x.
- Tidligere rapporter: `00-claude-inbox/solar-consulting/SC-02-*.md` og `strategi-2026-10-19/paal-1.md`.
