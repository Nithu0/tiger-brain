# Operatøren: det bare du kan gjøre (27.10)

Agentene har forberedt alt. Listen over Solar Consulting står i
https://github.com/Solar-Consulting/drift/issues/126 (avkrysning, vises også i cockpit-fanen «Hoved»).
Det som ikke hører til Solar Consulting, står her.

## Nexus
Lagt på is (27.10). Funnene ligger i `00-claude-inbox/nexus/2026-10-27/` hvis den tas opp igjen.

## Brain (tiger-brain)
- [ ] OPERATOR-APPROVED på https://github.com/Nithu0/tiger-brain/pull/1. Den synker alt siden 13.07, og 46 beskyttede filer er med.
- [ ] OPERATOR-APPROVED for rettingen av gitleaks-skannet i `.github`. Skannet har aldri kjørt.
- Bakgrunn: `00-claude-inbox/command-center/2026-10-27_brain-sync-rotarsak.md`. Synken går nå automatisk hvert 15. minutt til grenen `sync/NithuPC`.

## aslisten-crm
- [ ] Flytting til EU: kjører i dag i us-west2. Plan i `aslisten-crm/docs/flytt-til-eu.md` (#66/#67). Avgjør nedetid og vindu.
- [ ] Send Pål: `aslisten-crm/docs/oppgaver/nytt-for-paal-2026-10-27.md`. Han må godkjenne spørsmålsteksten, dele skjermen ved én Altinn-innsending og avgjøre automatisk «Registrert».

## Repoer
- [ ] Se gjennom og merge https://github.com/Nithu0/grossist-plattform/pull/1 og https://github.com/Nithu0/call-center-ai-demo/pull/1.
- [ ] Veldora hovedcheckout (`~/code/Veldora`) står på `feat/secure-age`. Den har 2 commits som aldri er pushet, blant annet en kryptert Veldora.pdf, og 7 filer som ikke er committet (research). Push, committ eller la ligge.

## Flytting til ny PC
- [ ] Kjør `~/code/command-center/_bin/preflight-old-machine.sh --apply` når du er klar. Du blir bedt om en passphrase til den krypterte bundelen. Noter den. Se `00-claude-inbox/workstation/klar-for-flytting-2026-10-27.md`.

## Cockpit (etter flytting)
- [ ] Ja eller nei til Tailscale. Plan: `command-center/docs/ops/COCKPIT-TAILSCALE-PLAN.md`.
