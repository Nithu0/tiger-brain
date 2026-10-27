
---
### 2026-06-30T15:10:59Z — DISPATCH fra code-2 (bro-test)
**TEST — bekreft at firm-bus→pane-broen funker.** Svar i denne panen med:
`echo "codex-1 live: $FIRM_ROLE @ $(pwd) — bro OK"`
Ingen videre handling. Dette er en manuell verifikasjon av dispatch-kanalen (samme kanal Hermes/Telegram bruker).

## 2026-07-21T20:53:52+02:00 — fra as-1: grossist-plattform, oppgave 4 (operatør-trigget utsending)

**Din oppgave:** Policy-motor (packages/policy): regelmotor med risikonivå 1–4, purreregler 2026 som data, golden-tests. Venter på oppgave 2 (domain-typene).

**Obligatorisk før start:** les `~/code/AS/docs/grossist-nisje/agent-oppgaver-plattform.md`
(din brief = oppgave 4) og `~/code/AS/docs/grossist-nisje/2026-07-21-plattform-arkitektur.md`
(låste valg — ikke omkamp). Kode i `~/code/grossist-plattform/` — ALDRI i AS-mappen (PII).
Kun syntetiske data. Ingen secrets. Én eier per pakke — rør ikke andres pakker.
Verktøy: du har subagenter (opptil 10), web-søk for verifisering, og code-review-skill før
ferdigmelding. Done = bygger + tester grønne + én linje på feed.md + kort rapport til
`~/Obsidian/Brain/00-claude-inbox/AS/` (uten PII). Ingen push uten operatørens «OK kjør».

## 2026-07-21T21:56:27+02:00 — fra as-1: PURRING oppgave 4 (packages/policy): ingenting levert. Regelmotoren er ren TS uten infra-avhengigheter — ikke vent på fase 0. Definer forslags-typene lokalt hvis domain-pakken (code-1) ikke er klar, og aligner etterpå.

> 2026-10-03: alle juli-PURRINGer over denne linjen er erstattet av auditbriefen under / er historiske.

## 2026-10-03T14:20:00Z — fra operator-audit: støtt codex-2s policy-integrasjon + rydd emit-layout (packages/policy)

**Mål:** codex-2 kobler nå `@grossist/mcp-tools` på den ekte policy-kontrakten (se `inbox/codex-2.md`, samme tidsstempel). Du er støtte + reviewer, og rydder policy-pakkens build-utdata. Låst arkitektur: §6 «Topp 5» #1 Policy ETTER modell (arkitektur-doc l.337), MCP-raden i stack-tabellen (l.259).

**Oppgaver:**
1. Bekreft at eksportert API holder for codex-2: `evaluatePolicy` (`src/evaluate.ts:882`), `PolicyDecision`/`PolicyEvaluationInput` (`src/types.ts:194,200`), `PolicyExecutionAttempt`/`isPolicyExecutionAllowed`/`assertPolicyExecutionAllowed` (`src/execution.ts:3,21,48`), barrel `src/index.ts:1-8`. Mangler noe (f.eks. helper for å bygge `binding`/payloadHash deterministisk), eksporter det — svar codex-2 i `inbox/codex-2.md`.
2. Om codex-2 trenger syntetiske decisions/proposals i tester: eksporter en egen test-fixture-entry (f.eks. `"./testing"` i package.json `exports`, basert på `test/helpers.ts`) — ikke i hoved-barrelen.
3. Review codex-2s integrasjon når den lander (fokus: attempt bygges fra faktisk payload, `require_approval` utføres aldri, fail-closed).
4. Emit-layout: `tsconfig.json` har `rootDir: "."` + `include` med `test/**/*.ts` → tester shippes i `dist/` og `main` peker på `dist/src/index.js`. Skill ut: `rootDir: "src"`, kun `src/**` i build-tsconfig (egen `tsconfig.test.json`/vitest for test), oppdater `main`/`types`/`exports` i `package.json` til `dist/index.*`.
5. `package.json` mangler `devDependencies` — deklarer `typescript`, `vitest`, `eslint` (+ `@types/node` om brukt) eksplisitt.

**Akseptkriterier:**
- [ ] `pnpm --filter @grossist/policy build` gir `dist/` uten `test/`-filer (sjekk: `find dist -path '*test*'` tom).
- [ ] alle eksisterende policy-tester grønne (`test/*.test.ts`, inkl. `threat-model.golden.test.ts`).
- [ ] mcp-tools bygger mot ny `exports`-sti (koordiner med codex-2 — ikke rediger mcp-tools selv).
- [ ] evt. test-fixture-entry er ikke tilgjengelig fra `"."`-barrelen.
- [ ] review-notat til codex-2 levert.

**Regler:** kun syntetiske data · én eier per pakke (du: `packages/policy`) · commit lokalt · ingen push uten operatørens «OK kjør» · done = build + tester grønne + én linje på feed.md + kort rapport (uten PII) til `~/Obsidian/Brain/00-claude-inbox/AS/`.
