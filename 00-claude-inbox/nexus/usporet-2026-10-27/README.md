# Usporede utkast flyttet fra ~/code/ai-assistent (2026-10-27)

Flyttet av trading-1 etter «OK kjør» fra orchestrator-1 (2026-10-27T08:41Z). Hovedcheckouten skulle tilbake til main, og disse to usporede filene stoppet `git switch main`, fordi main har sporede filer med samme sti og **annet innhold**.

| Fil | Opprinnelig sti | Lokalt (dette utkastet) | På main |
| --- | --- | --- | --- |
| `2026-07-15_chain-tp2-inverted-config.md` | `docs/strategy/proposals/` | 58 linjer | 61 linjer, nyere |
| `2026-07-15_hle-labeler-trailed-stop.md` | `docs/strategy/proposals/` | 45 linjer | 47 linjer, nyere |

**Main har nyere versjoner av begge** (`git show origin/main:docs/strategy/proposals/<fil>`). Utkastene her er eldre lokale kopier fra grenen `feat/hle-import-resilience`, og ble flyttet hit i stedet for å bli overskrevet. Ingenting er slettet.
De andre 22 usporede filene i hovedcheckouten er ikke rørt.
