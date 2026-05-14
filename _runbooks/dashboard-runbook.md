---
tags: [runbook, dashboard, control-panel, firm-bus]
date: 2026-05-14
type: runbook
owner: operator
related:
  - "[[00-CONTROL-PANEL]]"
  - "[[_decisions/2026-05-14-control-plane-proposal]]"
  - "[[reference_firm_launcher]]"
---

# Runbook: Control panel / dashboard

Hvordan kjøre, tolke og feilsøke `00-CONTROL-PANEL.md` (Obsidian Dataview MVP).

## Komponenter

| Komponent | Sti | Hvem skriver |
|---|---|---|
| Master-note | `~/Obsidian/Brain/00-CONTROL-PANEL.md` | Statisk (Dataview rendrer dynamisk) |
| Pane-status (JSON) | `~/Obsidian/Brain/00-firm-bus/pane-status/<role>.json` | `_bin/firm-heartbeat.sh` |
| Pane-status (md) | `~/Obsidian/Brain/00-firm-bus/pane-status/<role>.md` | `_bin/firm-heartbeat.sh` |
| Git-snapshot | `~/Obsidian/Brain/00-firm-bus/git-snapshot.json` | `_bin/firm-git-snapshot.sh` (cron) |

JSON-fil + md-fil er **samme data**, dual-skrevet: JSON for V2-scripts, md med
frontmatter for Dataview (Dataview kan ikke lese JSON via `dv.pages`, men kan
lese frontmatter; DataviewJS kan lese JSON via `app.vault.adapter.read`).

## 1. Heartbeat — starte per pane

`firm-heartbeat.sh` tar ingen args; leser `$FIRM_ROLE` etc. fra miljøet.
Sett av `firm-tab-init.sh` ved pane-oppstart (allerede deployed av BUILD-1).
Denne MVP-en **endrer ikke** `firm-tab-init.sh`. Heartbeat trigges separat:

### Alternativ A — manuell trigger (enklest, anbefalt for første test)

I hver pane, kjør:

```bash
~/code/_bin/firm-heartbeat.sh
```

Sjekk at fil ble skrevet:

```bash
ls -la ~/Obsidian/Brain/00-firm-bus/pane-status/
cat ~/Obsidian/Brain/00-firm-bus/pane-status/${FIRM_ROLE}.json
```

### Alternativ B — bakgrunns-loop per pane

Legg dette inn i `_bin/firm-session-context.sh` (eller en wrapper kalt av
`firm-tab-init.sh`); kjør i bakgrunnen så lenge panen lever:

```bash
(
  while true; do
    ~/code/_bin/firm-heartbeat.sh || true
    sleep 60
  done
) &
```

Husk å la `firm-tab-init.sh` eier `FIRM_ROLE`-eksport før loopen starter.

### Alternativ C — cron (per maskin)

```cron
*/1 * * * * FIRM_ROLE=ai-1 FIRM_PROJECT=nexus /home/nithu/code/_bin/firm-heartbeat.sh
```

Krever én cron-linje per pane og at `$FIRM_ROLE` er kjent på forhånd —
upraktisk for ad-hoc-paner. Anbefales kun for *long-lived* paner.

## 2. Git-snapshot — cron-oppsett

Anbefalt: hvert 2.–5. minutt. Legg til i `crontab -e`:

```cron
*/2 * * * * /home/nithu/code/_bin/firm-git-snapshot.sh >/dev/null 2>&1
```

Manuell refresh:

```bash
~/code/_bin/firm-git-snapshot.sh
jq '.generated_at, (.repos | map(.name))' ~/Obsidian/Brain/00-firm-bus/git-snapshot.json
```

## 3. Tolke dashboardet

Åpne `00-CONTROL-PANEL.md` i Obsidian. Forventet visning:

1. **Aktive paner**: én rad per pane med heartbeat innenfor 5 min.
   - "stale" betyr at panen ikke har skrevet heartbeat på en stund —
     enten lukket eller idle.
   - Mangler en pane helt: heartbeat har aldri kjørt der.

2. **Inbox-status**: filer i `00-firm-bus/inbox/` sortert ulest-først.
   - "UNREAD" = filsize > 0.
   - "empty" = ingen meldinger.

3. **Live feed**: hele `feed.md` embedded. Scroll ned for siste linjer.
   - Hvis veldig stor: åpne [[00-firm-bus/feed]] direkte.

4. **Git-status**: per-repo branch, ahead/behind, uncommitted, siste commit.
   - `generated_at` viser når snapshot ble laget — sjekk at det er ferskt.

5. **Hurtig-handlinger**: lenker til inbox-er, feed, roster, runbooks.

## 4. Troubleshooting

| Symptom | Sjekk | Fiks |
|---|---|---|
| Aktive paner tom | `ls ~/Obsidian/Brain/00-firm-bus/pane-status/` | Kjør `firm-heartbeat.sh` i hver pane (med `FIRM_ROLE` satt). |
| Pane vises som "stale" | `cat ~/Obsidian/Brain/00-firm-bus/pane-status/<role>.json` | Hvis `last_heartbeat` er gammel: re-kjør heartbeat eller restart bakgrunns-loopen. |
| Git-status sier "missing" / "ikke funnet" | `ls ~/Obsidian/Brain/00-firm-bus/git-snapshot.json` | Kjør `firm-git-snapshot.sh` manuelt; sjekk cron-logs (`grep CRON /var/log/syslog`). |
| Dataview-tabell rendrer ikke | Dataview-plugin aktiv? "JS Queries" aktivert i Dataview-settings? | Settings → Community plugins → Dataview → enable JS Queries. |
| `git-snapshot.json` har gammelt timestamp | `date -u`; `~/code/_bin/firm-git-snapshot.sh` | Re-kjør manuelt; sjekk at cron faktisk treffer. |
| .gitignore blokkerer ikke pane-status | `cd ~/Obsidian/Brain && git check-ignore -v 00-firm-bus/pane-status/ai-1.md` | Verifiser at `.gitignore` har linjene fra MVP. |
| Heartbeat exit-0 stille uten output | Sjekk `$FIRM_ROLE` | Heartbeat-scriptet exit'er 0 stille hvis `FIRM_ROLE` ikke satt — by design. Kjør `FIRM_ROLE=ai-1 firm-heartbeat.sh` for å overstyre. |

## 5. Hva endre / utvide

MVP er minimalt. Kandidater for V1.5 / V2 (per
[[_decisions/2026-05-14-control-plane-proposal]] roadmap):

- Discord-spool seksjon i `00-CONTROL-PANEL.md`.
- Broadcast-template + handoff-template som hurtignoter.
- Python `textual` TUI som leser samme state-filer (V2).
- Read-markers i inbox-frontmatter (`last_read:`).
- Cross-machine pane-status (krever push-bus — V3).

## 6. Hva IKKE å gjøre

- **Ikke commit `pane-status/*` eller `git-snapshot.json`** — per-maskin
  state, vil gi merge-konflikter for Karri. `.gitignore` håndterer det.
- **Ikke modifiser `firm-tab-init.sh`** for å legge inn heartbeat-loop direkte
  uten å koordinere med BUILD-1.
- **Ikke kjør `firm-git-snapshot.sh` oftere enn hvert minutt** — `jq`-kall +
  git-status på flere repos er ikke gratis.
- **Ikke parse `feed.md` med strenge regexer i Dataview** — feed er fri tekst,
  formatet kan endre seg. Embed-en i seksjon 3 er trygt nok.

---

*Sist oppdatert 2026-05-14 — MVP build.*
