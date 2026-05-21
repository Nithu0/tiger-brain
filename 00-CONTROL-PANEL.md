---
tags: [dashboard, control-panel, firm-bus]
date: 2026-05-14
type: control-panel
owner: operator
status: mvp
related:
  - "[[_decisions/2026-05-14-control-plane-proposal]]"
  - "[[_runbooks/dashboard-runbook]]"
  - "[[00-firm-bus/README]]"
  - "[[00-firm-bus/roster]]"
---

# Control panel

> **MVP — Obsidian Dataview**. Per-maskin state-filer (ikke pushet til Git).
> Refresh: Dataview kjører automatisk; git-snapshot oppdateres av cron.
> Hvis seksjoner er tomme: kjør runbook-stegene i [[_runbooks/dashboard-runbook]].

---

## 1. Aktive paner

Leser `00-firm-bus/pane-status/<role>.md` (frontmatter via Dataview).
"Stale" = siste heartbeat > 5 min siden.

```dataview
TABLE WITHOUT ID
  role AS "Role",
  project AS "Project",
  hostname AS "Host",
  last_heartbeat AS "Last HB",
  (choice(date(now) - date(last_heartbeat) > dur("5 min"), "stale", "live")) AS "State",
  cwd AS "CWD"
FROM "00-firm-bus/pane-status"
WHERE type = "pane-status"
SORT last_heartbeat DESC
```

> Tips: hvis Dataview viser tom tabell, sjekk at `firm-heartbeat.sh` har kjørt
> i hver pane. Per [[_runbooks/dashboard-runbook]].

---

## 2. Inbox-status

Leser `00-firm-bus/inbox/*.md`. Vis filer med innhold (size > 0) først.

```dataviewjs
const folder = "00-firm-bus/inbox";
const pages = dv.pages(`"${folder}"`)
  .where(p => !p.file.path.includes(".archive"));

const rows = pages.map(p => {
  const size = p.file.size ?? 0;
  const mtime = p.file.mtime;
  const role = p.file.name;
  const unread = size > 0 ? "UNREAD" : "empty";
  return [role, size, mtime, unread];
});

// Sorter: ulest først, deretter etter mtime desc
rows.sort((a, b) => {
  if ((a[3] === "UNREAD") !== (b[3] === "UNREAD")) {
    return a[3] === "UNREAD" ? -1 : 1;
  }
  return (b[2]?.ts ?? 0) - (a[2]?.ts ?? 0);
});

dv.table(["Role", "Size (bytes)", "Modified", "State"], rows);
```

---

## 3. Live feed (embedded)

Append-only logg fra `00-firm-bus/feed.md`. Embed viser hele filen — bruk
Ctrl+End for å scrolle til bunn. Hvis feed.md vokser store, vurder rotasjon
(se [[_runbooks/dashboard-runbook]]).

> **Advarsel**: hele `feed.md` embeddes under. Kan bli lang. Hvis det blir
> upraktisk: åpne filen direkte istedet → [[00-firm-bus/feed]].

![[00-firm-bus/feed]]

---

## 4. Git-status

Read fra `00-firm-bus/git-snapshot.json` (oppdateres av
`_bin/firm-git-snapshot.sh` via cron). Obsidian renderer JSON som code-block;
**ikke live**, men reflekterer siste cron-run.

```dataviewjs
const path = "00-firm-bus/git-snapshot.json";
try {
  const raw = await app.vault.adapter.read(path);
  const data = JSON.parse(raw);
  dv.paragraph(`**Generated**: ${data.generated_at}`);
  const rows = (data.repos || []).map(r => [
    r.name ?? "?",
    r.branch ?? "?",
    `${r.ahead ?? 0}/${r.behind ?? 0}`,
    r.uncommitted ?? 0,
    r.last_short ?? "?",
    `${r.age_minutes ?? "?"} min`,
    r.last_msg ?? ""
  ]);
  dv.table(
    ["Repo", "Branch", "Ahead/Behind", "Uncommitted", "Last", "Age", "Message"],
    rows
  );
} catch (err) {
  dv.paragraph(`*git-snapshot.json ikke funnet eller invalid: ${err.message}*`);
  dv.paragraph("Kjør \`_bin/firm-git-snapshot.sh\` manuelt for å generere.");
}
```

For refresh: kjør `~/code/_bin/firm-git-snapshot.sh` i en hvilken som helst
pane, eller vent på neste cron-tick (anbefalt: hvert 2.–5. minutt).

---

## 5. Hurtig-handlinger

Vanlige operasjoner — klikk for å hoppe til relevant fil.

- **Inbox-er** (per pane):
  - [[00-firm-bus/inbox/code-1]]
  - [[00-firm-bus/inbox/code-2]]
  - [[00-firm-bus/inbox/ai-1]]
  - [[00-firm-bus/inbox/ai-2]]
  - [[00-firm-bus/inbox/ai-3]]
  - [[00-firm-bus/inbox/ai-4]]
  - [[00-firm-bus/inbox/thesis-1]]
  - [[00-firm-bus/inbox/thesis-2]]
- **Feed & roster**:
  - [[00-firm-bus/feed]] — append-only event-logg
  - [[00-firm-bus/roster]] — pane → prosjekt-mapping
  - [[00-firm-bus/PRESENCE]] — operatør+Karri presence
- **Runbooks**:
  - [[_runbooks/dashboard-runbook]] — denne kontroll-planet
  - [[_runbooks/firm-launcher]] — 8-pane launcher
  - [[_runbooks/Runbook-Obsidian-Git-Sync]] — push/pull av Brain
  - [[00-command-center/README]] — Workspace-wide control plane (Next.js+Fastify+SQLite at /home/nithu/code/command-center)

---

*Auto-generert layout. Last opprettet: 2026-05-14. Eier: operatør.*
