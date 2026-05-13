---
tags: [meta, operator, migration]
type: guide
created: 2026-05-13
status: optional
---

# Migrate Obsidian fra Windows til Linux (inni WSL)

Guide for å flytte operator sin Obsidian-installasjon fra Windows-siden til Linux-siden inni WSL — samme oppsett som Karri kjører.

## 1. Hvorfor migrere

- Paritet med Karri sitt oppsett (begge på Linux Obsidian) — felles instans-modell for auto-sync funker likt på begge maskiner.
- Ingen `\\wsl$\`-bro lenger — direkte filsystem-tilgang i Linux er raskere og mer stabilt.
- Obsidian Git-plugin auto-sync funker identisk på begge maskiner uten plattform-spesifikke quirks.
- Én vault-sti (`~/Obsidian/Brain`) — slutt på Windows-vs-WSL path-forvirring i scripts og hooks.

## 2. Hva du beholder / mister

**Beholder:**
- Vault-innhold — ligger allerede i `~/Obsidian/Brain/` (samme sti, filsystemet er delt via WSL).
- ALL config i `.obsidian/` — følger med fordi vault-pathen er identisk fra både Windows- og Linux-instansene.

**Mister:**
- Windows-spesifikk Obsidian-state (`workspace.json` osv) — men disse er gitignored uansett.
- Windows desktop-launcher — erstattes med Linux-launcher (script under).

**NB sikkerhet:** den lekkede `obsidian-local-rest-api/data.json` ble allerede purget. Etter migrering MÅ operator rotere API-nøkkelen på nytt fra Linux Obsidian.

## 3. Migrasjons-steg (~10 min)

```bash
# 1. Lukk Windows Obsidian først (unngå lock files)

# 2. Verifiser at WSLg funker
bash ~/Obsidian/Brain/scripts/check-wslg.sh

# 3. Installer Linux Obsidian
bash ~/Obsidian/Brain/scripts/install-obsidian-linux.sh --yes

# 4. Start opp
bash ~/Obsidian/Brain/scripts/launch-obsidian.sh

# 5. Første gang: "Open folder as vault" → ~/Obsidian/Brain
#    Alle eksisterende notater + .obsidian/ config følger med automatisk

# 6. (Valgfritt) Avinstaller Windows Obsidian via Settings → Apps for å frigjøre plass
```

## 4. Etter migrering

- Åpne Settings → Community plugins → sjekk at Obsidian Git er lastet (config ligger allerede i repo).
- Restart Obsidian — auto-sync starter innen 2 min.
- Verifiser at sync funker:
  ```bash
  git log --grep "auto-sync" -3
  ```
  Skal vise nylige commits.

## 5. Rollback (om Linux Obsidian ikke funker)

- Windows Obsidian ligger fortsatt installert (med mindre du avinstallerte i steg 6).
- Re-åpne `\\wsl$\Ubuntu\home\nithu\Obsidian\Brain` i Windows Obsidian.
- **Viktig:** disable Obsidian Git i Linux Obsidian FØRST for å unngå sync-konflikter mellom to instanser.

## 6. Vanlige WSLg-gotchas (Win11)

- WSLg krever WSL 2+ — sjekk:
  ```powershell
  wsl -l -v
  ```
- Hardware-akselerasjon: Windows GPU-drivere må være oppdatert.
- Om GUI ikke dukker opp: kjør `wsl --shutdown` fra PowerShell, deretter restart WSL.

---

Sist oppdatert: 2026-05-13
