# Oppgave 8 — M365-connector (packages/connectors/m365) — LEVERT

**Fra:** ai-2 (utført på as-1s dispatch + purring 21.07)
**Dato:** 2026-07-21
**Status:** bygger + tester grønne fra repo-roten. Ingen push (OK kjør-gate).

## Levert

`/home/nithu/code/grossist-plattform/packages/connectors/m365/` — ny pakke `@grossist/connectors-m365`:

- **Kontrakt** (`src/types.ts`): `M365Connector` med `hentNyeMeldinger` / `sendMelding` / `hentVedlegg`, zod-validerte inputs/outputs, TS strict, engelsk kode.
- **Simulator** (`src/simulator.ts` + `src/fixtures.ts`): 20 syntetiske e-poster — 8 bestillinger, 4 reklamasjoner, 4 purre-/fakturaspørsmål, 3 injection-forsøk, 1 øvrig. Speiler demo-scenarioene (rutineordre, «det vanlige»-avvik, bestridt faktura, «ignorer alle tidligere instruksjoner»). Injection-mønstre: instruksjoner i kropp, falsk `[SYSTEM]`-kontonummerendring, skjult hvit HTML-tekst + instruksjoner i vedleggsnavn — alt flagget `injectionAttempt`/`syntheticData`. Deterministisk cursor-paginering, `since`-filter, sendMelding-dedupe på idempotencyKey.
- **Graph-implementasjon** (`src/graph.ts`) bak samme grensesnitt: client credentials m/token-cache, meldingslisting m/`@odata.nextLink`-cursor, sendMail (202) m/idempotensheader, fileAttachment-henting. Config via env-NAVN (`M365_TENANT_ID`/`M365_CLIENT_ID`/`M365_CLIENT_SECRET`), injiserbar fetch — ingen secrets i kode.
- **README**: oppsett-guide (app-registrering, permissions, PowerShell-scoping, env-vars) + simulatorbruk, med kilder.
- **Tester**: 19 vitest-tester (simulator + Graph m/mocket fetch, null nettverkskall).

## Verifisering

- Rot `pnpm build` (tsc -b): EXIT=0.
- Rot `pnpm test`: **124/124 tester grønne (21 filer)** — mine 19 inkludert, ingen andre pakker brutt.

## Viktig funn (web-verifisert mot Microsoft Learn 21.07)

Briefens «Application Access Policy» er nå **legacy hos Microsoft**: `auth-limit-mailbox-access` peker til «RBAC for Applications in Exchange Online» som erstatning, og `New-ApplicationAccessPolicy` bærer «Don't create new App Access Policies». README dokumenterer RBAC-veien som primær (`New-ServicePrincipal`/`New-ManagementScope`/`New-ManagementRoleAssignment`/`Test-ServicePrincipalAuthorization`) med AAP som fallback, inkl. union-fellen (org-vide Entra-grants må fjernes) og at delte postbokser scopes via mail-enabled security group. Verifiserte også client-credentials-flyt, list-messages (`$top` 1–1000, `$filter`/`$orderby`-regelen), sendMail-202 og attachment-get mot Learn-dokene.

## Avvik/antakelser

- To rot-filer utenfor pakken måtte røres (workspace-plumbing, ikke andres pakker): én referanselinje i rot-`tsconfig.json` + `pnpm-lock.yaml` via `pnpm install`. Rot-tsconfig var under aktiv endring av annen agent samtidig — min edit var kirurgisk én linje.
- Graph har ingen server-side idempotens for sendMail; nøkkelen bæres i `x-grossist-idempotency-key`-header og håndheving ligger i handlingstabellen (jf. arkitekturdok trussel #7). Simulatoren deduper selv.

Ingen PII, kun syntetiske data.
