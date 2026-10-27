# tools-1 onboarding v2 — full analyse (2026-07-28)

Rolle: tools-1 (verktøysjef; arver thesis-1, pensjonert — fresh sesjon, ingen migrert historikk).
CWD: `~/code/command-center`. Ordre: orchestrator-1 dispatch 2026-07-28T15:03Z + F1-ordren (2026-07-27, merget fra thesis-1-inbox).
Metode: 3 parallelle subagenter (repo-kartlegging, toolbox-doc-kartlegging, live read-only-inventar). Ingen filer endret utenom firm-bus/agents/tools-1/ + denne rapporten.

## 1. Repo-tilstand (command-center)

- **Branch:** `feat/firm-v2-rollout` (finnes på origin). Rent tre bortsett fra to utrackede filer (se §5).
- **Siste døgn:** F1 (rolle-migrering + launcher v3 + 24/7 executors, `0330f69`) og F2 (kontrollplan: intake-idempotens, dead-letter, task-envelope, `b160e3a`) er landet. data-1 har startet F4a (facets, `047a7fc`).
- **`project_state.md` er utdatert** (2026-06-19, pre-v2): beskriver C1-9/eval-recall-målene, ikke FIRM v2-fasene. Autoritativ per MEMORY-OS-AUDIT §5/§13, så den bør refreshes — men den deles av flere lanes; jeg flagger heller enn å overta.
- **Branch-gjeld:** ~135 branches, dominert av v1-æraens `code-1/*`, `code-2/*`, `pr-1..17`. Ikke min lane (orchestrator-1/infra-1).
- **TODO/FIXME i kode: nesten null** (5 treff, hvorav 2 i eksempelfil, 1 domenebegrep). Gjeld spores i project_state/UNRESOLVED/inbox — bra hygiene.

## 2. Mitt mandat (FIRM-V2-SPEC)

- **§1:** tools-1 = MCP/CLI/skills-register, capability discovery, sandbox-test, standardisering. Modell-baseline Opus + Haiku-subagenter. Pane: topprad kol. 3.
- **§10 F3 (min hovedleveranse):** capability registry v1 — *alle MCP/CLI/skills testet* — + modellrutings-policy (§5) inn i `FIRM-OPERATING-MODE.md`.
- **§9 Docker-strategi:** MCP-er velges på MERITT uansett kilde; Docker-katalogen SKAL gjennomgås aktivt; container-sandbox = standard testbenk; `docker mcp secret` (OS-keychain) der det passer; gateway kun for servere som faktisk kjøres derfra. Registry = kanonisk serverliste med kilde + kjøremodus. infra-1 verifiserer boot-persistens (24/7 uten Docker Desktop-GUI).
- **Grensesnitt:** orchestrator-1 ruter via agent_tasks+inbox · infra-1 eier runtime/boot/secrets-policy · data-1 eier masterarkiv/RAG (registry-data bør bli søkbart der) · learning-1/trading-1 er konsumenter.
- codex-1..8-speiling ble bevisst utsatt til F3 (ROLE-MAP) — kan lande på mitt bord.

## 3. Live verktøyflate (testet i dag, read-only)

**MCP (9 registrert i Claude Code):**

| Server | Status |
|---|---|
| github (HTTP api.githubcopilot.com) | Connected |
| playwright, obsidian, filesystem (npx) | Connected |
| ClickUp, Gmail, Google Drive (claude.ai HTTP) | Connected |
| **fetch** (uvx mcp-server-fetch) | **NEDE** — -32000 Connection closed |
| **ms365** (claude.ai HTTP) | **Needs re-auth** — operatør-handling |

Merk: `claude mcp list` bruker ~60s (live health-checks) — uegnet i hot-path-scripts uten timeout. Denne sesjonen eksponerer dessuten ikke filesystem/fetch/obsidian-verktøyene selv om de står i user-scope — verdt å forstå i registry-arbeidet.

**CLI:** gh 2.92.0 (auth OK, konto Nithu0), railway 4.44.0, vastai 1.1.1, yt-dlp 2026.03.17, docker 29.1.3 (daemon oppe), node v24.15.0/npm/pnpm/npx, python3 3.12, pipx, uv 0.11.8, jq, rg, zellij 0.44.1, litestream (kjører som service), ollama 0.30.8. **Mangler:** wrangler (npx-bar), fzf, sqlite3-CLI (better-sqlite3 finnes i node; CLI kunne vært nyttig for db-feilsøking — operatørvalg).

**Docker MCP Toolkit:** v0.43.1 installert; `catalog list` = tom (aldri tatt i bruk); `gateway run` + `secret set/ls/rm` finnes. Status: «installert, ubrukt» — F1-ordren min er å endre det.

**systemd --user (kjører):** 8× `firm-remote-executor@` (alle v2-roller), `firm-remote-verdict-watch`, `brain-orchestrator` + `brain-worker`, `hermes-gateway`, `litestream`.

**Subagenter:** 10 i `~/.claude/agents/` (stemmer med docs — eneste inventar som gjør det). **Skills:** humanizer + trading-knowledge (user), superpowers-suite + 7 plugins enabled. **Plugins live: 8 unike** (docs sier 3).

## 4. Dokumentasjonsgjeld — kjernefunnet

11 toolbox-relaterte docs i `docs/ops/` + `_bin/tools-roster.txt` + `Brain/03-skills/TOOLBOX-MOC.md`. Vurdering:

- **Kanon å bygge videre på:** TOOLBOX-MOC (rikeste skjema: vet-status LIVE/NEEDS-AUTH/PROPOSED/REJECT), toolbox-inventory.md (faktisk-tilstand-kontrakt), tools-roster.txt (eneste kanal som automatisk når alle sesjoner), toolbox-catalog.md + per-project-tool-map.md (ruting/PII-aksen — moden, gjenbrukes som felt).
- **Historiske run-rapporter som forurenser bildet:** TOOLBOX-REPORT, TOOLBOX-DISTRIBUTION-REPORT, TOOL-DISTRIBUTION-2026-06-24 → bør arkiveres (flytting foreslås, ikke utført).
- **Delvis utdatert, unik verdi:** TOOLBOX.md (eneste daemon/RAM-doc, men feil MCP-tabell), TOOL-CATALOG-FULL.md (mest komplett, men Karri-vendt).

**≥10 konkrete sprik verifisert**, bl.a.: obsidian-MCP har tre ulike statuser i tre docs fra samme dag (live: Connected); github-MCP står som PROPOSED men er wired og grønn; superpowers-docs sier 6.0.3/project-scope, live er 6.2.0 user+project; `_bin`-antall oppgis som ~40/58 — live er 84 filer (~15 udokumenterte scripts siden 24.06); **Gmail-MCP er i drift men nevnt i null dokumenter**; hele korpuset bruker pensjonerte v1-rollenavn.

**Rot-årsak:** ingen per-oppføring `last_verified`, ingen maskinlesbar kilde, tre parallelle vedlikeholdspunkter («oppdater alle tre i samme sesjon»-regelen ble ikke fulgt). Konsekvens for registry v1: den må bli den ENE kilden, med testkommando + statusfelt per oppføring, og roster bør genereres fra den — ellers blir registryet sprik #11.

## 5. Avvik/risiko flagget til orchestrator-1/infra-1

1. **pnpm-artefakt:** `pnpm-lock.yaml` + `pnpm-workspace.yaml` utracket i repo-roten, mtime 27.07 22:52. Ingen besluttet pnpm-migrering finnes (ingen commits/docs nevner pnpm); workspace-fila er en ugyldig stub uten `packages:`; lockfila dekker bare rot-devDeps. Trolig etterlatt av en agent som kjørte `pnpm install`. Anbefaling: ikke commit; slett eller .gitignore (sletting = operatør-gate). Reell pnpm-migrering ville vært et eget infra-løp.
2. **fetch-MCP nede** — eneste røde server; uv finnes, trolig spawn-/pakkefeil. Tas i registry-arbeidet.
3. **ms365 re-auth** — operatør-handling.
4. **`claude mcp list` 60s** — ikke bruk i hooks/hot-path uten timeout.
5. `firm-task-{claim,complete}.sh` refereres fortsatt i MOC/inventory men finnes ikke på HEAD (kjent fra CLAUDE.md — bekreftet igjen).

## 6. Plan (aktivt mål)

**CAPABILITY-REGISTRY v1** → `docs/ops/CAPABILITY-REGISTRY.md`: alt inventert med live-testet status, `last_verified` per rad, kilde+kjøremodus per MCP, feilmoduser, eier/lane remappet til v2-roller; Docker MCP-katalog gjennomgås (init + vurder servere på meritt); gh-søk → 5 kandidater → topp-3-anbefaling i feed; TOOLBOX-MOC oppdateres. Deretter (neste mål): modellrutings-policy inn i FIRM-OPERATING-MODE.md + roster-generator. Detaljer i `agents/tools-1/GOALS.md`.

— tools-1, 2026-07-28. Ingen push (OK kjør-gaten).
