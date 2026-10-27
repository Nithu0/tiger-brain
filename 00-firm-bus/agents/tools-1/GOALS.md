# tools-1 — GOALS

## PARKERT 2026-10-13 (Veldora strategiråd runde 1)
- **Hadde i gang:** tools-doctor guard-fiks er FERDIG og committed (`fee21a7` på `tools-1/doctor-guard-aware`) — ingen halvferdig state, ingenting farlig å etterlate.
- **MÅ gjøres før noe annet:** ingenting i min lane blokkerer. Begrunnelse: alle åpne spor er operatør-gatede (yq-install, Twelve Data/Context7-nøkler, telegram-konto/session/systemd) eller venter OK kjør-gaten (7 upushede grener/commits: `34df302`..`ed7ec6e` på main, `e06bbda` på tools-1/f2-gates, `fee21a7` på tools-1/doctor-guard-aware).
- **Trygt parkert:** registry §1/§2 re-verifisering (krever interaktiv sesjon), F2-kull rest, arkiv-degradering av run-rapporter.

## Aktivt mål (ETT)
**F2-kull rest:** yq (operatør-gate på install). Twelve Data + Context7-gatene lukket 2026-09-28 (`e06bbda` på `tools-1/f2-gates`, upushet) — begge venter API-nøkkel fra operatør. DBHub kun hvis lanene faktisk trenger MCP-flate etter db-query.sh-piloten (re-vurderingstrigger i §9b #6-raden).

## PARKERT 2026-10-13 — Veldora strategiråd (operatør-ordre via orchestrator-1)

**Hadde i gang:** F2-kull rest (yq, operatør-gate på install); Twelve Data + Context7 ferdigvurdert men venter API-nøkkel.

**MÅ gjøres før noe annet (begrunnelse):**
1. **Push-gate på 8 upushede commits** (`34df302`..`ed7ec6e` på main + `fee21a7` på `tools-1/doctor-guard-aware` + `e06bbda` på `tools-1/f2-gates` + 3 på `feat/muse-engine`). Ikke farlig, men arbeid som står og råtner lokalt på én maskin = eneste kopi. Operatør-gate, ikke min.
2. **Registry §1+§2 `last_verified` er 77d gammel på 20 rader.** Blir det tatt som sannhet i strategirådet, bygger panelet på utdatert verktøystatus. Jeg flagger dette eksplisitt i rapporten min.

**Trygt å parke:** yq-install, DBHub-revurdering, telegram-mcp-pilot (scaffold klart, venter bare operatør-gates), degradering av gamle run-rapporter.

**Halvferdig og farlig å etterlate:** Ingenting. Alt arbeid er committet lokalt, arbeidstreet er rent bortsett fra untracked `_bin/ralph-*.sh`, `_bin/omni-firm.sh`, `omnigent/`, `body.txt` — ikke mine, ikke committet, ikke i veien.

## Levert
- ✅ 2026-10-13: **tools-doctor guard-fiks** (`fee21a7` på `tools-1/doctor-guard-aware`, upushet): doctoren meldte FAIL på hver remote-run fordi firm-exec-guard-shimene svarer exit 1 også på read-only `gh auth status`/`--version` (railway ble samtidig meldt grønn som "versjon ukjent" = usjekket). Ny SKIP-status + `_bin/tests/doctor-guard.sh` (9 asserts, verifisert at den feiler mot pre-fiks). 39G/8W/1F → 37G/8W/0F/3SKIP. Funn ikke fikset: ekte MCP-drift + 20 registry-rader 77d uverifisert — §1 krever interaktiv sesjon (headless skjuler connector-status).
- ✅ 2026-09-28: **F2-gater Twelve Data + Context7** (`e06bbda`): XAU/USD = Basic-plan (gratis), verifisert via API `show_plan`; lisens non-commercial → kun intern nexus-analyse. Context7 nøkkelløst = 200 kall/mnd per IP (for tynt) → pilot kun med gratis nøkkel.
- ✅ 2026-09-25/26: **muse-engine** (`feat/muse-engine`, 3 commits) + **fix/git-index-lock** (`c272040`) — ligger hos orchestrator-1 for push.
- ✅ 2026-08-19: **sqlite-utils sandbox-test → PILOT** + `_bin/db-query.sh` (obligatorisk read-only-wrapper; python3 backup fra mode=ro → uvx pinnet 4.2.1). Premiss delvis snudd: python3 stdlib dekker ad-hoc, sqlite-utils = UX-gevinst. Review high: 4/10 funn mine, fikset (immutable-fella, DEAD-synlighet i doctor, §6-detalj, pinning); 6 handoff't (infra-1/orchestrator-1). Doctor 44G/3W/0F.
- ✅ 2026-08-19: **F2-kandidatjakt** (`ed7ec6e`): behovsdrevet sweep (4 researchers) → §9b-kull (sqlite-utils/DBHub/Twelve Data/Context7/yq + bekreftede 0-funn); fetch+fetch-docker DEPRECATED etter premiss-sjekk (21 kall noensinne, null avhengigheter) — overstyrte planlagt LIVE-flip; toolkit LIVE (infra-1s reparasjon verifisert); karri-bootstrap-fix. Doctor 44G/1W/0F.
- ✅ 2026-08-18: **SANDBOX-TEST-PROTOCOL.md** (`ea2d188`): harde rammer + 6 faser (premiss-sjekk først — snudde 2 av 4 verdicts) + a-h-rapportformat + verdict-nivåer m/krav. Siste punkt fra registry §Vedlikehold lukket.
- ✅ 2026-08-17: **Roster/doctor-generator** (`0250a03`+`e594047`): gen-tools-roster.sh genererer roster+expected fra registryet; doctor sourcer expected + kjører --check-drift (§6); code-review high — 8/10 funn fikset, regresjonstestet. Bonus-funn: docker-mcp-plugin borte → fetch-docker NEDE, reparasjon hos infra-1.
- ✅ 2026-08-17: **WhisperX-sandbox-test**: AVVENT (captions-only-premiss avdekket, CPU saktere enn realtime, diarisering token-gated; re-vurder på GPU-boks). Registry §9 komplett — alle 5 F1-kandidater ferdigvurdert (commit `34df302` på main).
- ✅ 2026-08-16: **codex-1..8-speiling vurdert** (F3-restpunkt): anbefaler IKKE 1:1-speiling (grid sovende, 0 reell bruk); re-pek codex-5, behold codex-6..8, executor-beslutning → orchestrator-1. Rapport + handoff levert.
- ✅ 2026-08-14: **Verktøybrief til alle roller** (operatør-ordre): skreddersydd brief i alle 7 v2-inboxer + FIRM-TOOLBOX.md synket mot CAPABILITY-REGISTRY (commit `c1ac88b`).
- ✅ 2026-08-09: **Sandbox-verdicts topp-3** (commit `443666d`): telegram-mcp=PILOT (read-only-gating verifisert), SkyPilot=AVVENT, OpenFGA=vent-til-første-kunde.
- ✅ 2026-07-28: **F3 del 2** (commit `f9d9af1`): modellrutings-policy inn i FIRM-OPERATING-MODE.md; `_bin/tools-doctor.sh`; tools-roster synket.
- ✅ 2026-07-28: **CAPABILITY-REGISTRY v1** (commit `416d3d4`): alt inventert m/live-testet status; Docker MCP-katalog gjennomgått; topp-3-anbefalinger meldt.

## Neste (etter aktivt mål, ikke startet)
- Re-verifiser registry §1+§2 og oppdater `last_verified` på de 20 radene (77d). MCP-delen krever operatør-/interaktiv sesjon — `claude mcp list` headless deaktiverer claude.ai-connectors (ANTHROPIC_API_KEY tar presedens).
- F2-kull videre: Twelve Data (gate: XAU/USD i gratis-tier?), Context7, yq — sandbox/pilot etter sqlite-lanen.
- telegram-mcp-pilot aktivering — venter KUN operatør-gates (dedikert konto, session-string, systemd-enable). Scaffold klart på `tools-1/telegram-mcp-pilot`.
- Degrader run-rapportene (TOOLBOX-REPORT/-DISTRIBUTION/TOOL-DISTRIBUTION-2026-06-24) til arkiv — operatør-nær flytting, foreslås, ikke utføres ensidig.

## Venter på andre (ikke mine gates)
- Operatør: 6 commits på main upushet (`34df302`..`ed7ec6e`) — OK kjør-gate. ms365 re-auth. Opprydding etter fetch-DEPRECATED: to rader i `~/.claude.json`, profiler cc-fetch/cc_test_fetch, image mcp/fetch 433 MB (operatørvalg).
