# admin-1 — STATE

_Oppdatert 2026-08-19 (august-pakken). Autoritativ prosjektstatus = `<repo>/project_state.md` (PATH-MAP.md)._
_Full analyse: `00-claude-inbox/workspace/2026-07-28_admin-1-onboarding.md`_

## Statuskart (kort)

| Flate | Status | Neste |
|---|---|---|
| **AS/ (eget ENK-regnskap)** | AKTIVT + fristdrevet. NB: entiteten er ENK (Kukaraja Sikkerhet), ikke AS. Fiken = sannhetskilde, avstemming ferskest 20.07 (drift-VARSEL: 3 terminer avviker mot lokal katalog). | **Frist 31.08: MVA termin 3/2026 — grunnlag KLART 19.08** (netto 20 982,41, `AS/docs/mva-termin3-2026-grunnlag.md`); levering = operatør. Juli-lønn LUKKET (faktura 10017 utstedt 31.07). Juni-faktura 10016 utstedt. Altinn-status fortsatt UVERIFISERT — sjekkliste klar i grunnlag-doc (ID-porten = operatør). |
| **call-center-ai-demo (salg)** | Demobar offline (mock-providere, 13 no-samtaler, 19 testfiler). Halvt dvalende: siste commit 23.06 er UPUSHET; project_state.md ucommittet. Strategisk gjenbruk i produkt A1/Sales-Training. | Push-beslutning (OK kjør-gate). Sikkerhetsflagg LUKKET 14.08: infra-1 verifiserte `HARD_LOCAL_PATHS` fail-closed (e39e27d) + herdet `callcenter`-fragment for søsterrepoet; pushet på feat/firm-v2-rollout (operatør-OK). |
| **Personlig** | Verktøylag ferdig+testet (dashboard/aggregering/path-guard), datalag DØDT (1 ekte logg, 68 dager stille). Sikkerhet SOLID: 07-personlig aldri i tiger-brain-historikk, gitignore verifisert. | Blokker i 4 filer: operatør må definere mål/mat-fase/trenings-split. Branch `node-migration-personlig` umerget forbi main. |
| **Søking fulltid** | ARKIVERT — mål nådd (rolle sikret, Ambita). conductor.timer IKKE installert (verifisert 28.07) — ingen løpende forpliktelser. | Arv usikret: voice-agent + intervju-prep + CV-generatorer ligger kun ucommittet i arbeidstre, ingen remote. Bevaringsbeslutning trengs. |

## MCP-tilgang (F1-sjekk 28.07)

- Gmail ✔ / ClickUp ✔ / Google Drive ✔ tilkoblet (CLI-nivå; ikke eksponert i panens verktøyliste — kan kreve sesjonsrestart for bruk)
- **ms365: trenger re-auth** (operatør: `/mcp`-auth) — samsvarer med tools-1 sitt inventar
- fetch-MCP nede (tools-1 har den i sitt inventar også)

## PII-regel (bindende for hele lanen)

Alt admin-1-materiale er PII-tungt: lokal prosessering, aldri leid GPU. Helsedata (Personlig) aldri i Brain-synkede filer. Regnskaps-PDF-innhold aldri til Obsidian/memory.
