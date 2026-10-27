# Grossist-plattform oppgave 4: policy-motor

Status: ferdig 2026-07-21T23:06:38+02:00

## Levert

- `packages/policy`: deterministisk regelmotor for risikonivå 1-4 med stabile reason-codes, dispositions og hard stops.
- Sideeffekter er bundet til tenant, proposal/revisjon, payload, subject, lokalt faktasnapshot, mottaker, policyrevisjon og regelbundle.
- Nivå-3-grants er datert og scopet til grant-ID, tenant, handling, NOK-valuta og beløpsgrense. Pilot har ingen grants.
- Binding-aware execution-gate krever aktuell `PolicyExecutionAttempt`; kun `disposition === allow` kan utføres.
- Norske 2026-regler som effektivt daterte data: H1 12,00 prosent/NOK 460, H2 12,25 prosent/NOK 430, purre- og inkassovarselgebyr NOK 38, 14-dagersfrister og produktløp 1 purring + inkassovarsel.
- Juridisk form, pålitelig skriftlig levering, rentegrunnlag/periodisering og kostnadsavregning må være lokalt verifisert. Ekstern inkasso er ubetinget blokkert.
- Alle 14 trusler i arkitektur paragraf 6 er dekket av golden-matrise med forventet level/disposition/blocked/retryable og konkrete eksterne evidensreferanser.
- `packages/policy` er lagt til rotens TypeScript-prosjektgraf.

## Verifisering

- Policy: 82/82 tester bestått; build, lint og `git diff --check` bestått.
- Workspace: `pnpm build` bestått; 230 tester bestått, 13 Postgres-integrasjonstester hoppet over fordi testvert ikke var konfigurert.
- Workspace-lint er fortsatt rød på 12 samtidige/eksterne feil i `apps/web/.next`, `apps/web`, `packages/audit` og `packages/db`; policy-lint er grønn.
- To uavhengige exact-tree-reviews fant ingen gjenværende in-package bypass eller kontraktfeil.

## Handoff og restpunkter

- Høy ekstern integrasjonsrisiko: `packages/mcp-tools` modellerer ikke canonical disposition og sjekker bare blocked. Krav og oppdatert attempt-signatur er sendt til codex-2. Plattformen må ikke koble MCP til sideeffekter før adapteren bruker canonical `PolicyDecision` og binding-aware execution-gate.
- Ny inkassolov var fortsatt ikke i kraft 21. juli 2026. Regelmotoren feiler derfor lukket for utsendelser fra 22. juli til juridisk status er verifisert og datasettet oppdatert.
- `packages/domain` mangler fortsatt; lokale boundary-typer er isolert for senere alignment.
- Git-repoet har ingen konfigurert remote, så ingen push ble utført. Arbeidstreet inneholder også samtidige endringer eid av andre agenter.

## Primarkilder

- Finanstilsynet: forsinkelsesrente og standardkompensasjon.
- Finanstilsynet: utenrettslige inndrivingskostnader 2026.
- Lovdata: inkassoloven 1988, inkassoforskriften og LOV-2026-05-22-19 status.
