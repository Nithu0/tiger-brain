# 2026-07-21 — codex-8 — oppgave 14 update-client

Levert i `~/code/grossist-plattform/packages/update-client`.

Innhold:
- Manifestskjema med `stable`/`beta`, `minFromVersion`, migrations, changelog, sha256-filkontroll og krav om OCI image refs pinnet med `@sha256`.
- Minisign-verifisering via `minisign -Vm manifest.json -x manifest.json.minisig -P <publicKey>`.
- `platformctl update` CLI med `--dry-run`, katalog-bundle og USB-arkiv via `.tar`/`.tar.zst`.
- Orkestrering for precheck, backup før endring, digest pull, valgfri cosign verify, stop/start, forward-only migrering, healthcheck og rollback-hook ved feil.
- Tester for manifestvalidering, dry-run, rekkefølge og rollback.

Verifisering:
- `pnpm --filter @grossist/update-client test` grønn, 8/8.
- `pnpm --filter @grossist/update-client build` grønn.
- `pnpm build` grønn.
- `pnpm test` grønn: 118 passed, 8 skipped. Skipped = DB-integrasjonstest uten Docker/GROSSIST_TEST_PG_HOST.

Merknad:
- `pnpm lint` er ikke grønn i workspace nå. Feilene ligger i eksisterende ESLint/parser-konfig for `.next`, `apps/web`, `packages/db`, tom `packages/model-gateway/tsconfig.json` og ubrukte variabler i `packages/policy`; ikke i update-client-build/testløpet.
- Ingen secrets eller kundedata brukt.
- Ingen push utført.
