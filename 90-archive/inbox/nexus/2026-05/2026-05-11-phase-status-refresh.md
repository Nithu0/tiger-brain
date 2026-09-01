# Phase-status refresh — 11.5 (mandag uke-åpning)

**Commit:** `134c779`
**File:** `/home/nithu/code/ai-assistent/docs/ops/phase-status.md`
**Push:** ikke gjort — venter "OK kjør"

## Sections updated

1. **Header** — "Sist oppdatert" → 2026-05-11
2. **Live MCP roster** — bumpet til "per 11.5", `nexus-pg-rw` renset for "lagt til 08.5"-parantes + restart-caveat (allerede live), obsidian ✓ uendret
3. **Foundation gate** — full statusoverhaling (se under)
4. **Operator-beslutninger 04.5–11.5** — ny `### 11.5` underseksjon med 5 entries (gate flip, metadata-fix, env-sync, Karri-proposals, PnL-dashboard filter); eksisterende 04.5–08.5 flyttet til underseksjon
5. **Åpne problemer** — lagt til "Metadata-strip backfill needed" rad (138 historiske rader, MEDIUM)

## Foundation gate before → after

| Regel | Before (08.5) | After (11.5) |
|---|---|---|
| 1 KRITISKE problemer | 🟢 | 🟢 |
| 2 POSITION_MANAGEMENT_ENABLED | 🟢 | 🟡 (funksjonelt restituert i dag via `0ad348f`) |
| 3 Build OK | 🟢 | 🟢 |
| 4 Gate evals 7×50 | 🔴 (14d gap) | 🟢 (resumed, 1951+ evals; GREEN 18.5 hvis 7 sammenhengende dager kreves) |
| 5 Forfalne followups | 🔴 (≥5) | 🟡 (2 overdue; 1 unna grønn via supersede) |

Net: én rød → grønn (regel 4), én rød → gul (regel 5), én grønn → gul (regel 2). Foundation samlet: 🟡 GUL.

## Verification

- `tsc` skipped — docs-only diff
- File renders (33 lines changed, +24/-9)
- Commit hooks passed

## Next checkpoint

- 18.5: regel 4 GREEN-måldato (7 sammenhengende dager gate-data)
- 12–13.5: regel 2 24-48h runtime-watch på metadata-fix
- Karri-reviews venter på 3 proposals
