# Hvorfor snapshot.summary er tom: rotårsak

data-1, 2026-10-16. Kun lesing: kode på `origin/main` 342d332, prod målt read-only 09:06Z.
SQL og artefakter ligger på branch `sc-04-modell` (74501f4):
`crm/scripts/baseline/snapshot-summary{,-errors}.sql` og `crm/eval/snapshot-summary{,-errors}-2026-10-16.txt`.
Reproduser: `./scripts/baseline/run-triage-baseline.sh --sql snapshot-summary.sql`.

## Kort svar

Feltet blir kopiert. Det fantes bare aldri. Snapshotet tar `opportunity.summary` som det står
(`crm/src/lib/triage.ts:199`), og det feltet skrives bare av `extract-requirements` når LLM-kallet
lykkes (`jobs/tasks/extract-requirements.ts:200-201`). Tom summary betyr at den jobben aldri ga et sammendrag.

## Målt (siste beslutning per mulighet, UNDECIDED utelatt)

| Klasse | dev | test | har summary i dag |
|---|---|---|---|
| Totalt / tomme | 115 / 33 | 24 / 14 | |
| **LLM-feil før beslutningen**: «Your credit balance is too low to access the Anthropic API» | **15** | **8** | 1 av 23 |
| fit < 40, så aldri køet (`extract-requirements` køes bare ved fit ≥ 40 eller ved dokumentopplasting) | 8 | 5 | 0 |
| fit ≥ 40, ingen jobb funnet | 10 | 1 | 0 |

`FACT`: Alle 35 feilede `extract-requirements`-jobber har samme feilmelding om at kreditten er brukt opp.
De står på `total_tried = 3` og blir aldri prøvd igjen (første 08.10 07:30Z, siste 14.10 07:30Z).
22 av 23 av disse mulighetene har **fortsatt** tom summary. Hullet er permanent, ikke bare en forsinkelse.

`FACT`: `llm_usage` viser at HTTP 400 begynte 08.10 og toppet seg 14.10 med 875 feil på haiku-4-5.
`agent_runs` har ok-kjøringer igjen 15.10.

`FACT`: Payload sletter vellykkede jobber (0 vellykkede beholdt i `payload_jobs`). Klassen «ingen jobb
funnet» kan derfor være jobber som ble hoppet over, og så ferdigmeldt og slettet. Status `skipped`
betyr «Ingen tekst å analysere», altså ingen beskrivelse og ingen dokumenttekst
(`extract-requirements.ts:150-153`). Det skiller jeg ikke fra «aldri køet» med disse dataene. `UNKNOWN`.

Tidsforskyvning, der briefen kom etter beslutningen: 1 rad av 47. Det er ikke hovedårsaken.

## Konsekvens

- SC-04: scope regnet fra snapshotet blir 0 der summary mangler, og det forklarer testkollapsen (17 av 18).
- Snapshot v2 (SC-03): summary er en jobbavhengig LLM-utgang, ikke et kunngjøringsfelt. Den deterministiske
  teksten (`tender.description`) bør snapshottes ved siden av, så snapshotet ikke arver LLM-tilgjengelighet.
  Det er et forslag. Admin-1 eier valget.
- Drift (operatør, ikke endret): 23 muligheter har døde extract-requirements-jobber som ikke retries
  av seg selv. Kreditten er tilbake (ok-kjøringer 15.10), men jobbene må køes på nytt manuelt.
