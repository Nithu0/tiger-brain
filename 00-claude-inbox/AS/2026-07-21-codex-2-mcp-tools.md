# codex-2 rapport — oppgave 5 mcp-tools

- Levert `packages/mcp-tools` med faste verktøy: get_customer, get_customer_history, check_stock, get_product_price, create_order_draft, prepare_email, send_approved_email, get_invoice_status, prepare_payment_reminder, create_internal_task.
- Tenant hentes fra `caseContext` og sendes videre til repository-port; ingen generiske tenant-/SQL-verktøy.
- Write-operasjoner går via `PolicyPort`; fixture-policy og syntetisk fixture-repo er med for test fram til db/policy-pakkene lander.
- Verifisert: `corepack pnpm --filter @grossist/mcp-tools build`, `corepack pnpm --filter @grossist/mcp-tools test`, `./node_modules/.bin/eslint packages/mcp-tools/src --ext .ts`.
- Root `pnpm build` er grønn. Root `pnpm test` feiler i eksisterende `packages/license`/`infra/license-server`; root `pnpm lint` feiler i eksisterende web/connectors/db/policy-konfig. Ikke rørt andre eieres pakker.
