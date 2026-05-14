---
tags: [career, job-search]
type: status
status: active
created: 2026-05-08
activated: 2026-05-14
---

# Job-Search-Status

Status-flagg for aktivt jobbsøk.

## What

- **Status** — `not-searching` | `passive` | `active`. Currently: `active` (var: not-searching frem til 2026-05-14).
- **Aktiv siden**: 2026-05-14
- **Target roles**: ML engineer, data scientist, MLE, materials informatics, R&D engineer (battery/hydrogen/materials)
- **Target tier-1 geografi**: Trondheim, Oslo, Bergen, Stavanger
- **Tilgjengelig fra**: september 2026 (etter MSc juni 2026)
- **Pipeline**: TODO — fylles ut etter hvert som søknader sendes (speiles fra `leads/stillinger.xlsx`).

## Why

A clear status flag prevents drift between "kind of looking" and "actually applying". Ambiguity costs months.

## Next steps

- (a) Kjør job-scraper daglig — se [[runbook]] (`agent/daily.py` via cron, 08:00 man–fre).
- (b) Ukentlig CRM-review hver søndag — gå gjennom `leads/stillinger.xlsx`, oppdater statuser, identifisér stale leads.
- (c) Responstid på leads < 72 timer — fra Ny → vurderer/ikke aktuell, og fra positiv respons → svar.

## Related

- [[Career-MOC]]
- [[Resume-Updates]]
- [[Long-Term-Vision]]
- [[Network]]
