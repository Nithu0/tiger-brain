---
to: karri
from: code-2
date: 2026-06-24T11:05:10Z
---
# Hele verktøykassa er pushet — replikér lokalt

command-center main (commit 41f39f9) har nå full, secret-fri tool-distribusjon:

1. **Pull** command-center (du deler GitHub).
2. **Katalog**: `docs/ops/TOOL-CATALOG-FULL.md` — alt vi har (MCPs, 58 _bin-scripts, 23 packages inkl. brain-engine, subagenter, skills, GPU/Vast). Names + kommandoer, ingen secrets.
3. **Bootstrap**: kjør `_bin/karri-bootstrap.sh` på fersk maskin — installerer CLIs (node, yt-dlp, vastai, ollama+bge-m3/deepseek), bygger command-center-workspacene (brain-engine), legger _bin på PATH, og skriver MCP-config-MALER du fyller med dine egne nøkler lokalt (nano). Idempotent, ingen blinde destruktive steg, curl|sh er prompt-gated.
4. Secrets fyller du selv lokalt — scriptet skriver ALDRI ekte nøkler.

Da bygger du med nøyaktig samme verktøy som oss. Spør i firm-bus om noe mangler.

## OPPDATERT 2026-06-24T11:19:55Z — nå AUTOMATISK i firm
Du trenger ikke kjøre bootstrap manuelt lenger. Etter at du puller command-center (commit 36c5f1c):
1. Bare kjør **`firm`** på den ferske maskinen. Første launch laster ned + bygger HELE verktøykassa i bakgrunnen automatisk (npm-build, yt-dlp/vastai via pipx, PATH, MCP-config-maler). Kun ÉN av de 8 panene gjør jobben (single-flight); ingen pane blokkeres.
2. Hver Claude-sesjon får full-katalogen (`TOOL-CATALOG-FULL.md`) servert ved session-start — sesjonen kan handle direkte med full instruks uten at noen forklarer.
3. Det ENESTE som ikke kjøres automatisk er ollama-installeren (curl|sh = operatør-gated av sikkerhet). Kjør den med: `FIRM_TOOLSET_FULL=1 ~/code/command-center/_bin/firm-ensure-toolset.sh` (eller bare `karri-bootstrap.sh`). Secrets fyller du fortsatt selv lokalt (nano) — scriptet skriver aldri ekte nøkler.
Logg: `~/.config/command-center/toolset-setup.log`. Marker: `.toolset-ready` (slett den for å re-provisjonere).
