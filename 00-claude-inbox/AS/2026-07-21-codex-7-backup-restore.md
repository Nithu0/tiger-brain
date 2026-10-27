# codex-7 — oppgave 13 backup + restore-test

Levert i `~/code/grossist-plattform/infra/backup/`.

## Innhold

- `backup.config.example.json`: syntetisk to-tenant config med ett restic-repo og egen passordfil per selskap.
- `src/backup.ts`: `pg_dump --format=custom` per selskaps-DB, manifest, restic backup med tenant-tags, retention via `forget --prune`, og `restic check`.
- `src/restore-test.ts`: henter siste restic-snapshot, starter engangs-Postgres-container, kjører `pg_restore`, teller konfigurerte tabeller og skriver restore-rapport.
- `scripts/run-backup.sh` og `scripts/run-restore-test.sh`: scheduler-vennlige wrappers mot bygget CLI.
- `README.md`: 3-2-1-plan, bruk og restore-test-rutine.

## Verifisering

- `corepack pnpm --filter @grossist/backup test` grønn: 6/6 tester.
- `corepack pnpm --filter @grossist/backup build` grønn.
- `corepack pnpm build` grønn.
- `corepack pnpm test` grønn: 21 testfiler, 124 tester.

## Notater

Repoet er fortsatt ikke initialisert som git-repo her, så ingenting er pushet. Koden bruker kun syntetiske konfigeksempler og lagrer ingen secrets.
