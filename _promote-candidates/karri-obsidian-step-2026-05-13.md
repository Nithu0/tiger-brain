---
tags: [meta, karri, message]
type: draft
created: 2026-05-13
---

# Karri: Obsidian step (paste til din Claude)

Send dette til Claude'en din i Ubuntu (Bash-tool):

```text
Hei Claude — installer Linux Obsidian + Obsidian Git auto-sync. Kjør i Bash-tool, WSL Ubuntu.

1. Verifiser WSLg/GUI-støtte:
bash $HOME/Obsidian/Brain/scripts/check-wslg.sh

2. Hvis GREEN: installer Obsidian:
bash $HOME/Obsidian/Brain/scripts/install-obsidian-linux.sh --yes

3. Verifiser:
ls $HOME/.local/bin/Obsidian.AppImage

4. Pull siste config (Obsidian Git plugin config er allerede i repoen):
cd $HOME/Obsidian/Brain && git pull

5. Når dette er done — IKKE kjør obsidian via Bash-tool (krever GUI). Si ifra, så starter operator selv via Start-menyen eller terminalen min.

Rapporter output av check-wslg.sh først.
```

Sist oppdatert: 2026-05-13
