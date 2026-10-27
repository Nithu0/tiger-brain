# tools-1 — STATE

_Peker: autoritativ prosjektstatus = `<repo>/project_state.md` (PATH-MAP.md)._
_Oppdatert: 2026-07-28 (onboarding v2). Full analyse: `~/Obsidian/Brain/00-claude-inbox/command-center/2026-07-28_tools-1-onboarding.md`._

## Rolle
Verktøysjef (arver thesis-1, pensjonert — sesjon IKKE migrert, fresh start). CWD `~/code/command-center`.
Domene: MCP-/CLI-/skills-register, capability discovery, sandbox-test, standardisering.
F3-leveranse (spec §10): capability registry v1 (alle MCP/CLI/skills testet) + modellrutings-policy inn i `docs/ops/FIRM-OPERATING-MODE.md`.

## Repo (command-center)
- Branch `feat/firm-v2-rollout`; `main` = unified mainline; Slice 1–13 kodekomplett.
- `project_state.md` er datert 2026-06-19 — pre-v2, trenger refresh (eies ikke av meg alene; flagget).
- Utracket: `pnpm-lock.yaml` + `pnpm-workspace.yaml` = halvfabrikert artefakt fra 27.07 (ingen besluttet pnpm-migrering; ugyldig workspace-def). Anbefaling: IKKE commit; fjerning er operatør-gated.
- ~135 branches (v1 task-branch-gjeld) — opprydding ikke min lane (orchestrator-1/infra-1).

## Verktøyflate (live-testet 2026-07-28)
- MCP: 9 registrert. Grønne: github, playwright, obsidian, filesystem, ClickUp, Gmail, Google Drive. Røde: **fetch (Connection closed)**, **ms365 (needs re-auth — operatør)**.
- CLI: gh 2.92 (auth OK som Nithu0), railway, vastai, yt-dlp, docker 29.1.3, node 24 / npm / pnpm, uv, ollama, zellij, litestream. Mangler: wrangler, fzf, sqlite3-CLI.
- Docker MCP Toolkit v0.43.1 installert, **ingen kataloger konfigurert** (ubrukt). gateway + secret-subkommandoer finnes.
- systemd: 8× firm-remote-executor (alle v2-roller) + verdict-watch + brain-orchestrator/worker + hermes-gateway + litestream — alle oppe.

## F1-leveranse (2026-07-28)
CAPABILITY-REGISTRY v1 landet: `docs/ops/CAPABILITY-REGISTRY.md` (commit `416d3d4`, upushet). fetch-MCP erstattet med containerisert `fetch-docker` via `docker mcp gateway` (profil cc-fetch). Docker-katalog: 268 kuraterte servere; secret-engine BRUKKET headless (workaround `--secrets`-fil) — infra-1 må verifisere 24/7-punktene i §8. Anbefalinger: SkyPilot (GPU-ROI), telegram-mcp (intake), OpenFGA (multi-tenant, vent til første kunde).

## Dokumentasjonsgjeld (kjernefunn)
11 toolbox-docs + roster + TOOLBOX-MOC, alle skrevet mot pensjonert v1-rolleregister, med ≥10 konkrete sprik (obsidian-status 3 svar samme dag; github-MCP stale; superpowers-versjon/scope; plugin-antall; `_bin`-antall 40/58/84; Gmail-MCP helt udokumentert). Rot-årsak: ingen per-oppføring `last_verified`, ingen maskinlesbar kilde. Registry v1 må bli den ene kilden; roster genereres derfra.
