# Overlevering 2026-10-17 kveld: orchestrator-1 (SC / anbudsplattform)

Operatøren tar pause og tar opp jobben om et par timer. Tavla: `00-claude-inbox/solar-consulting/SC-TAVLE.md` (seksjon «Etter backfill steg 1» er neste kjøreplan).

## I prod i dag
#173 SC-03, #174 SC-04, #175 SC-06, #176 SC-07+056, #177, #178 SC-05, #179 lovdata, #180 plassholdere, #181 pref-2, #182/#183 eval, #185 CLI, #186 SC-01b, #187 SC-01, #190 instruksfiler (CLAUDE.md for anbud/crm/dashboard + AGENTS.md), #191 hyyr, #192 menyen kan lukkes (operatørens UI-ønske).
Prod-handlinger: requeue 34 extract (alle har summary), learn-preferences (pref-2, n=78), ingest-lovdata force, fix:placeholders (Multiconsult/Volvo), DOKUMENTARKIV_ENABLED=true (39 KOFA-PDF-er natt 1), Google-token fornyet (sync-workspace ok).

## Pågår
- **Backfill steg 1** (RESULT 2021–2024, jobb via queue:job, infra-1 overvåker). Stoppet én gang etter deploy-restart, gjenopptatt. **Mergefrys (`hold`) til steg 1 er ferdig.** Env-endringer redeployer worker, så de venter også.
- Agentbølger (AGENT-GRANSKNING.md): bølge 0 #197 (sløyfe/effort/priser) + #199 (caching/kostnadsvakt, døgntak 20 USD) · 1.4 verktøylag #201 · 1.3 triage-vurderer #200 (eval spor A kjører) · 1.1 dokumentlos (tools-1, under arbeid) · bølge 2 forarbeid #198 + red team-datasett #202 · stale-vakt #196 · requeue:failed #195 · SC-02 #194 · agentstandard #193 · prismodell #189 (draft).

## Venter på operatøren
1. Prismodell #189: timepris, fakturerbare timer per eier, timer per tilbud (eller «bruk median 1 240 og 40»).
2. Konkurransegrunnlag: Mercell/TendSign-kontoer eller manuell opplasting (50 BID/INVESTIGATE har 0 dokumenter; største input-hull).
3. Kompetansebanken har 0 leveransefakta → «intervju» av eierne.
4. Les `HAIKU-55-brief-side-om-side.md` (5 min) og `eval/redteam/nivaa-a/GODKJENNING.md` på grenen b2-redteam-datasett (10 min).
5. TypeSafe-nøkkel gir 401 (fornyes hos TypeSafe). Tre-scopes-forslaget har frist 19.10.

## Regler lært i dag (står i projects/anbud/CLAUDE.md)
Main er prod. Én migrering om gangen. Prod bare via innsjekket CLI med tørrkjøring. `railway run` med `env -u DATABASE_URL`. Ingen npx utenfor package.json. Ingen sed -i på bussfiler. Kommandoer i PR-tekster kjøres mot engangs-PG18 først. Claude i Chrome virker ikke fra WSL; portal-Chrome via WSLg-profil `~/.config/sc-portal-chrome` (CDP 9333).
