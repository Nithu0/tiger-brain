
## 2026-07-21T20:53:52+02:00 — fra as-1: grossist-plattform, oppgave 5 (operatør-trigget utsending)

**Din oppgave:** MCP-verktøylag (packages/mcp-tools): avgrensede verktøy via offisiell TS-SDK, tenant fra sakskontekst. Venter på oppgave 2/3.

**Obligatorisk før start:** les `~/code/AS/docs/grossist-nisje/agent-oppgaver-plattform.md`
(din brief = oppgave 5) og `~/code/AS/docs/grossist-nisje/2026-07-21-plattform-arkitektur.md`
(låste valg — ikke omkamp). Kode i `~/code/grossist-plattform/` — ALDRI i AS-mappen (PII).
Kun syntetiske data. Ingen secrets. Én eier per pakke — rør ikke andres pakker.
Verktøy: du har subagenter (opptil 10), web-søk for verifisering, og code-review-skill før
ferdigmelding. Done = bygger + tester grønne + én linje på feed.md + kort rapport til
`~/Obsidian/Brain/00-claude-inbox/AS/` (uten PII). Ingen push uten operatørens «OK kjør».

## 2026-07-21T21:56:27+02:00 — fra as-1: PURRING oppgave 5 (packages/mcp-tools): ingenting levert. Start med verktøy-signaturene + policy-grensesnittet mot fixtures; koble mot db-laget når det lander.

## 2026-07-21T22:48:30+02:00 — fra codex-1: policy-adapter handoff
- packages/policy er nå root-integrert. Viktig: kun `decision.disposition === "allow" && !decision.blocked` kan eksekveres. `require_approval` har med vilje `blocked:false`, men må IKKE utføres.
- Bruk eksportert `isPolicyExecutionAllowed`/`assertPolicyExecutionAllowed`; bind proposal/payload/tenant/subject/facts/recipient/policyRevision gjennom adapteren. Nåværende mcp-tools `assertAllowed` som bare sjekker blocked er inkompatibel og fail-open.
- Oppdatering 23:04: helperne krever nå `(decision, executionAttempt)`. Attempt må komme fra faktisk payload og inkluderer binding, effectiveOn, policyRevision, ruleBundleId, appliedAutomationGrantIds og appliedRuleSetIds; alle sammenlignes før allow.

> 2026-10-03: alle juli-PURRINGer over denne linjen er erstattet av auditbriefen under / er historiske.

## 2026-10-03T14:20:00Z — fra operator-audit: KRITISK — mcp-tools ignorerer policy-kontrakten (packages/mcp-tools)

**Mål:** `@grossist/mcp-tools` skal bruke den ekte policy-kontrakten fra `@grossist/policy`, ikke en lokal fail-open-kopi. Ingen skrivende handler får utføre noe uten `assertPolicyExecutionAllowed(decision, executionAttempt)`, og tenant skal komme fra serveren, aldri fra modellen. Låst arkitektur: §6 «Topp 5» #1 Policy ETTER modell (arkitektur-doc l.337) og #2 Tenant-fiksering (l.342), §3.3 To-selskaps-separasjon (l.207-208), stack-tabellen MCP-raden (l.259).

**KRITISK — policy-kontrakt:**
1. Legg til `"@grossist/policy": "workspace:*"` i `packages/mcp-tools/package.json` (dependencies) + project reference i `packages/mcp-tools/tsconfig.json`.
2. Fjern lokal `PolicyDecision` (`src/types.ts:114-118`), `PolicyPort`/`PolicyAction` (`src/types.ts:120-129`) og `assertAllowed` (`src/policy.ts:48-52`, sjekker bare `blocked` → fail-open). Bruk `PolicyDecision`/`evaluatePolicy` (`packages/policy/src/evaluate.ts:882`, typer i `packages/policy/src/types.ts:194,200`) og `assertPolicyExecutionAllowed` / `PolicyExecutionAttempt` (`packages/policy/src/execution.ts:3,48`).
3. `executionAttempt` bygges i handleren fra den FAKTISKE payloaden som skal utføres (binding: proposalId, proposalRevision, payloadHash, tenantId, subjectId, factSnapshotHash, recipientHash + effectiveOn, policyRevision, ruleBundleId, appliedAutomationGrantIds, appliedRuleSetIds) — aldri kopiert fra decision-objektet.
4. Alle skrivende handlere gates: create_order_draft, prepare_email, send_approved_email, prepare_payment_reminder, create_internal_task (`src/handlers.ts:53,82,102,119,136` — dagens `assertAllowed`-kall på l.58,87,107,123,142).
5. `require_approval` skal ALDRI utføres (den har `blocked:false` med vilje — se codex-1 sin handoff lenger opp i denne innboksen).
6. `sendApprovedEmail` må verifisere at `approvalId` finnes, gjelder denne e-posten/tenant og er godkjent — i dag setter den bare feltet (`src/fixtures/repository.ts:81-93`).
7. Fjern `allowReadOnlyPolicy` (`src/policy.ts:9`) og `export * from "./fixtures/repository.js"` (`src/index.ts:6`) fra public barrel. Flytt til en egen test-only entry (f.eks. `./testing` i package.json `exports`, eller kun importert fra `__tests__`).

**HIGH — tenant server-side:**
- Fjern `caseContext`/`toolCaseContextSchema` fra ALLE tool-inputSchemas (`src/schemas.ts:5-55`; kilde `src/types.ts:6-15`). Tenant/case/actor injiseres av serveren (`createToolHandlers`, `src/handlers.ts:27`) fra sakskonteksten, ikke som modellparameter.
- Fjern `unitPriceOverrideOre` (`src/types.ts:20`, brukt `src/handlers.ts:62`), eller gate den eksplisitt via policy (pris-avvik = egen faktaverdi i bindingen).

**Akseptkriterier (tester som MÅ finnes og være grønne):**
- [ ] fail-closed: manglende/undefined decision → ingen repository-skriving, kaster.
- [ ] `disposition: "require_approval"` → handler utfører ikke (repository-spy kalles 0 ganger).
- [ ] manipulert executionAttempt (endret payloadHash / tenantId / recipientHash / policyRevision) → avvist.
- [ ] modell-levert tenant umulig: input med `caseContext`/`tenantId` avvises av `.strict()`-skjemaet, og injisert tenant brukes uansett.
- [ ] `send_approved_email` med ukjent/feil approvalId → avvist.
- [ ] public barrel (`import * from "@grossist/mcp-tools"`) eksporterer ikke `allowReadOnlyPolicy` eller fixtures-repository.
- [ ] `pnpm --filter @grossist/mcp-tools build && test` grønt + rot-build grønn.

Koordinering: codex-1 eier `packages/policy` — trenger du ny eksport/test-fixture der, be codex-1 via `inbox/codex-1.md`, ikke rediger policy selv. Be codex-1 om review når integrasjonen er committet.

**Regler:** kun syntetiske data · én eier per pakke (du: `packages/mcp-tools`) · commit lokalt · ingen push uten operatørens «OK kjør» · done = build + tester grønne + én linje på feed.md + kort rapport (uten PII) til `~/Obsidian/Brain/00-claude-inbox/AS/`.
