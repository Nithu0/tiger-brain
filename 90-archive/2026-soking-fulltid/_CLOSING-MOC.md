---
tags: [moc, archive, career, job-search, retired]
type: closing-moc
status: RETIRED
archived: 2026-07-27
archived_by: data-1
outcome: landed-role
---

# Avslutnings-MOC — Søking fulltid (aktiv jobbsøking 2026)

> **RETIRED 2026-07-27.** Jobbsøket er avsluttet med resultat: **fast rolle sikret hos Ambita** (AI-ingeniør, ProspektAI/Prosper-produktet). Denne mappa er arkivert av data-1 under FIRM v2-migreringen. Archive-don't-delete — alt ligger intakt.

## Utfall

Nithusan sikret **AI-ingeniør-rolle hos Ambita** etter en to-runders prosess (uformell kaffeprat → 90-min teknisk fagsamtale med det tekniske teamet, inkl. en PhD i AI). Rollen er på ProspektAI/Prosper — RAG + dokumentekstraksjon over eiendomsdata (Infoland), grounding/sporbarhet på juridisk forpliktende salgsoppgaver. Tilgjengelig fra september 2026.

## Hva ble levert (prosjektets output)

- **Scanner-pipeline** (`Søking fulltid/agent/`): arbeidsplassen.no (NAV ES-proxy, ingen auth) + finn.no (HTML-parsing), ML-skåring (`match_score.py`), manuell enrichment, daglig dagsrapport. Containerisert for 24/7-noden (#23).
- **CRM**: `leads/stillinger.xlsx` (Excel m/dropdowns) + read-only Streamlit Phase-3 CRM (`crm/app.py`, Tailscale-bound, 19 tester).
- **Søknadsagent** (`/soknad`-skill + `agent/soknad/render_letter.py`): krav→bevis-metode, ærlig dom, Times-husstil, PDF/Word-render. ~70 søknader arkivert historisk.
- **Intervju-forberedelse** (`Søking fulltid/intervju/`): Ambita-prep (kaffeprat + fagsamtale), strategisk diskusjonsdok (modellvalg, EU-residens-nyanse, grounding-granularitet), verktøy-cheatsheet, presentasjon.

## Hvor ligger alt (pekere — ikke kopiert hit)

| Innhold | Kanonisk plassering |
|---|---|
| Kode + scanner + CRM + agent | `~/code/Søking fulltid/` (repo, branch `feat/soknadsagent`) |
| Prosjektstatus (nå RETIRED) | `~/code/Søking fulltid/project_state.md` + `GOALS.md` |
| Profil / CV / preferanser (PII — lokalt, ikke pushet) | `~/code/Søking fulltid/profil/` |
| Sendt-arkiv (~70 søknader) | `~/code/Søking fulltid/sendt/` |
| Intervju-materiale (Ambita) | `~/code/Søking fulltid/intervju/` |
| Agent-minne | `~/.claude/projects/-home-nithu-code-S-king-fulltid/memory/` |

## Arkiverte strategi-noter (flyttet hit)

- [[Active-Job-Search-MOC]] — den gamle aktive huben (status-bar, maler, profil-ankre).
- [[Job-Search-Status]] — status-flagget (var `active` fra 2026-05-14; nå RETIRED).

Bredere karriere-hub [[Career-MOC]] **beholdes** i `04-career/` — karriere-domenet lever videre (ny rolle, ny fase); kun det aktive søket er arkivert.

## Lærdom verdt å ta med

- Differensiatoren som vant Ambita: hybrid **ingeniør × ML × salg** + at grounding/sporbarhet fra masteren traff produktets kjernebehov direkte.
- Ærlig bredde slår falsk dybde i intervju — «kjenner + ville brukt» framfor påstått prod-erfaring.
