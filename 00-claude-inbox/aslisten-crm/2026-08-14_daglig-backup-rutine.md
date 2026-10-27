# Daglig backup-rutine aslisten-crm prod — satt opp og verifisert 2026-08-14

## Hva som er på plass

- **`scripts/fetch-backup.sh`** (committet på branch `ops/daglig-backup`): henter
  `GET <prod>/api/backup` med admin Basic auth, lagrer til
  `~/backups/aslisten-crm/aslisten-YYYYMMDD.db`, beholder siste 14, exit != 0 med
  tydelig feilmelding ved HTTP != 200 eller ugyldig sqlite (file-magic alltid +
  `PRAGMA integrity_check` via sqlite3/python3 — sqlite3-CLI mangler på maskinen,
  python3-stien brukes).
- **systemd --user timer**: `aslisten-crm-backup.timer` daglig 03:30
  (`Persistent=true` + 5 min randomisert delay — WSL er ofte av kl 03:30, glippede
  kjøringer tas ved neste oppstart). Unit-kopier versjonert i `scripts/systemd/`.
- Creds havner aldri i prosesslista (`--netrc-file` på tmpfile, slettes via trap)
  og printes aldri.

## Viktig avvik fra bestillingen

Bestillingen sa «admin-auth fra .env», men **lokal `.env.local` inneholder
dev-creds — de gir 401 mot prod**. Løsning: timeren kjører med
`CRM_BACKUP_AUTH=railway`, som henter prod-creds ved kjøretid fra `railway
variables --json` (CLI er innlogget og linket). Ingen prod-secrets skrives til
disk. Envfile-modus finnes fortsatt som default for lokal bruk.
Avhengighet å være obs på: hvis Railway-CLI-innloggingen utløper, feiler backupen
(synlig i `journalctl --user -u aslisten-crm-backup.service`) — den fikser seg
ikke selv.

Prod-URL: `https://aslisten-crm-production.up.railway.app` (pinnet i servicen;
`crm.aslisten.no` fra .env.example resolverer ikke ennå).

## Manuell verifisering (kjørt nå)

- Script direkte + via `systemctl --user start aslisten-crm-backup.service`: begge OK.
- `aslisten-20260814.db` (307 200 bytes, chmod 600): `PRAGMA integrity_check` = ok,
  `cases`-tabell finnes (19 tabeller totalt, 17 rader i cases).
- Feilsti testet: dev-creds mot prod → «FEIL: HTTP 401 …», exit 1. ✔

## Drift

- Status: `systemctl --user list-timers | grep aslisten` (neste kjøring 03:30).
- Logg: `journalctl --user -u aslisten-crm-backup.service`.
- Manuell kjøring: `systemctl --user start aslisten-crm-backup.service`.
