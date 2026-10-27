# paal-1 — GOALS

## Aktivt mål (forslag, satt ved onboarding 2026-07-28)

**Pilot-klar aslisten-crm.** — STATUS 28.07 kveld: punkt 1 og 2 LEVERT
(branch `fix/prod-blokkere` 9385e19, upushet; deploy-anbefaling i
docs/deploy-anbefaling.md). Punkt 3 var allerede oppfylt (malmotor verifisert
m/testmal). Gjenstår kun operatør: OK kjør på push + deploy-valg.
Ferdig når:
1. De 4 prod-blokkerne er fikset m/tester: `/api/inbound` fail-closed, WAL-checkpoint + backup-rutine, fnr-maskering før LLM-kall, `/api/health` uten saksantall.
2. Deploy-beslutning (Railway vs. lokal+named tunnel hos Pål) forelagt operatør m/anbefaling — selve deployen er operatør-gated.
3. Malpakke-flyt klar til å ta imot Påls ekte Word-maler (motoren finnes; verifisert med testmal).

Begrunnelse: hele kommersialiseringstrappa (utvidelse → standardisering → multi-tenant) står bak «stabil intern drift hos Pål». Detaljer + produktkart: `00-claude-inbox/aslisten-crm/2026-07-28_paal-1-onboarding.md` §4-5.

## Kø (ikke aktivt)
- grossist: commit utracket kode + .gitignore-fiks (lokalt); remote/push operatør-gated.
- refi-doc-agent: git init + første commit (ren staging).
- Purring/frist-motor i CRM (gjenbruk policy-mønster fra grossist packages/policy).

---

## PARKERT 2026-10-13 — Veldora strategiråd

**Hva jeg hadde i gang:** aslisten-crm, branch `feat/jobbko-saksloft` (HEAD 4b73ebd,
«Gjennomgang av PR #61: ni feil rettet»). To utrackede endringer i arbeidstreet:
`scripts/fetch-backup.sh` og `scripts/vaktpost-oppsett.sh` (M, ikke commitet).

**MÅ gjøres før noe annet (når rådet er over):**
1. Commit eller forkast de to script-endringene. Begrunnelse: `fetch-backup.sh` rører
   backup-henting av prod-data. Uklar/halvferdig tilstand her er den ene tingen i min
   lane som kan koste ekte data. Ikke farlig å LA LIGGE (den kjører ikke av seg selv,
   backup-timeren 03:30 bruker committet versjon), men farlig å GLEMME.
2. Operatør-gate: `feat/jobbko-saksloft` + `fix/prod-blokkere` (9385e19) er fortsatt
   upushet. Ingenting av dette er i prod. Pål kjører fortsatt på forrige deploy.

**Trygt å parkere:** grossist-commit, refi-doc-agent git init, purre-/fristmotor.
Alt er kø-arbeid uten tidskritikk og uten delt state.

**Ingenting halvferdig som er farlig å etterlate.** Ingen migrasjoner i flight,
ingen deploy i flight, ingen prod-endringer gjort.
