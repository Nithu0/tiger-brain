# tools-1 — tools-doctor guard-fiks + funn fra helsesjekken

_2026-10-13 · branch `tools-1/doctor-guard-aware` (`fee21a7`, upushet)_

## Hvorfor dette steget

Alt som står igjen på det aktive målet er operatør-gated (yq-install, Twelve Data-
og Context7-nøkler, telegram-mcp-kontoen). Registryet var derimot ikke rørt siden
19.08 — 8 uker — så jeg kjørte helsesjekken i stedet for å finne på nytt arbeid.
Den avdekket én feil jeg kunne fikse selv.

## Fikset

`_bin/tools-doctor.sh` rapporterte **FAIL på hver eneste remote-run**, uten at noe
var galt. Årsak: `firm-exec-guard` legger PATH-shims for gh/git/railway/vercel foran
de ekte binærene i headless executor-runs, og shimen svarer exit 1 på *alt* — også
read-only `gh --version` og `gh auth status`. Doctoren leste den exit-koden som
"ikke innlogget".

Samme rot ga en stillere feil: `railway` ble meldt grønn som "installert (versjon
ukjent)" — den var i praksis usjekket.

Løsning: ny `SKIP`-status for sjekker som ikke er *målbare i denne konteksten*.
Ikke OK (vi har ikke verifisert noe), ikke FAIL (maskinen feiler ikke), teller ikke
mot verdict. En sjekk som feiler by design hver gang er en sjekk alle slutter å lese.

`39G / 8W / 1F` → `37G / 8W / 0F / 3 SKIP`. De 8 warnings som står igjen er ekte drift.

Regresjonstest: `_bin/tests/doctor-guard.sh` (9 asserts, grønn nå, **feiler mot
pre-fiks-skriptet** — verifisert begge veier). Den sjekker også at guarden fortsatt
faktisk blokkerer, så SKIP aldri kan bli en stille åpning av push-gaten.

## Funnet, IKKE fikset — ekte MCP-drift

Registry §1 sier 9 MCP-er, grønne: github, ClickUp, Gmail, Google Drive. Det stemmer
ikke lenger. `claude mcp list` i dag:

- **github, ms365, Google Drive** — borte som egne rader i konfigen.
- **ClickUp, Gmail** — finnes nå kun som `plugin:productivity:*` HTTP-connectors, og
  de trenger OAuth. Gmail står dessuten som "Not configured".
- Headless-forbehold: `claude mcp list` varsler at claude.ai-connectors er deaktivert
  fordi `ANTHROPIC_API_KEY` tar presedens. Connector-radene kan derfor se verre ut
  herfra enn i en operatør-sesjon — **det må verifiseres i en interaktiv sesjon før
  registryet skrives om.** Jeg har ikke skrevet om §1 på et headless øyeblikksbilde.
- fetch + fetch-docker svarer fortsatt Connected, begge DEPRECATED per registry.
  Opprydding er operatørvalg (står alt i GOALS).

Dessuten: **20 registry-rader er >60 dager uverifisert** (77d — alle MCP- og CLI-radene).

## Neste steg (min lane)

Re-verifiser §1 + §2 i en kontekst der connector-statusen er til å stole på, og
oppdater `last_verified` på de 20 radene. Krever en operatør-sesjon for MCP-delen.

## Venter på operatøren

- `tools-1/doctor-guard-aware` (`fee21a7`) — denne leveransen, klar til push.
- `tools-1/f2-gates` (`e06bbda`) — F2-gatene, klar til push.
- Twelve Data + Context7: API-nøkler. yq: install. telegram-mcp: konto/session/systemd.
- ms365 re-auth; opprydding etter fetch-DEPRECATED (to rader i `~/.claude.json`,
  profilene cc-fetch/cc_test_fetch, image mcp/fetch 433 MB).
