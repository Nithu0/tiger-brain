# 2026-07-21 — codex-4: oppgave 9 Visma Global connector

Leveranse i `~/code/grossist-plattform/packages/connectors/visma-global`.

## Hva som er levert

- TypeScript-grensesnitt for Visma Global-boundary:
  - kunder
  - varer
  - åpne poster
  - ordreutkast
- Fixture-basert simulator med kun syntetiske grossistdata.
- Read-only SQL-adapter som eksplisitt er en ikke-koblet skisse:
  - `health()` returnerer `not_connected` eller `partner_clarification_required`
  - lesemetoder kaster tydelig "not connected"
  - ordre-skrivevei er hardt deaktivert til BAPI/partneravklaring er gjort
- README med status: simulert-only, ingen secrets, ingen ekte integrasjon.
- Root `tsconfig.json` og `eslint.config.js` oppdatert slik at pakken bygges/lintes i workspace.

## Validering

- `corepack pnpm --filter @grossist/connectors-visma-global test` — grønn, 6/6 tester.
- `corepack pnpm --filter @grossist/connectors-visma-global build` — grønn.
- `corepack pnpm exec eslint packages/connectors/visma-global/src` — grønn.
- `corepack pnpm build` — grønn.

## Workspace-status

`corepack pnpm test` er ikke grønn på hele repoet, men feilene er utenfor Visma-pakken:

- `packages/license/src/signing.ts`: Ed25519-test feiler med public/private key object mismatch.
- `infra/license-server/src/__tests__/app.test.ts`: klarer ikke resolve `@grossist/license`.
- `packages/mcp-tools/src/server.ts`: mangler `@modelcontextprotocol/sdk/server/mcp.js`.

Jeg rørte ikke disse pakkene på grunn av en-eier-per-pakke-regelen.

Ingen push utført.
