# Veldora strategiråd — programplan

**Eier:** orchestrator-1 · **Startet:** 2026-10-13 10:05 CEST · **Arbeidsflate:** `~/code/Veldora-rad` (worktree, branch `strategy/ai-plattform-rad`, fra `origin/main` @ `6cc89c2`)

Operatørens ordre i én setning: gjør Veldora om fra anbudsdashboard til en proaktiv, personalisert AI-plattform for offentlige anskaffelser — med en samlet, live agentflate i stedet for 16 paner — og bruk 90 % av tokenbudsjettet på produksjon, ikke på rapporter.

## Målet vi måles på

> Hvor mye bedre hjelper Veldora brukeren å **oppdage**, **prioritere** og **vinne** riktige oppdrag?

Ikke antall agenter, modellkall, faner eller funksjoner. Det er operatørens eksplisitte krav og det overstyrer alle delmål under.

## Syv faser

| Fase | Hva | Hvem | Status |
|---|---|---|---|
| 0 | Recon + arbeidsflate | orchestrator-1 | FERDIG |
| 1 | Parkering av pågående arbeid + vekking av alle roller | 7 firm-paner (headless) | KJØRER |
| 2 | Discovery: kodegrunnlag + ekstern research + UX-forslag | 12 workflow-agenter | KJØRER |
| 3 | Nedbrytning til WBS med avhengigheter + completeness-kritikk | 2 workflow-agenter | KØET bak fase 2 |
| 4 | Runde 2–3: uavhengige forslag + red-team | rådet, ny workflow | IKKE STARTET |
| 5 | Runde 4–5: beslutningsmatrise, ADR-er, konsensus + veikart | orchestrator-1 + workflow | IKKE STARTET |
| 6 | Verifisering av alle påstander + stor `/grill-me` med operatøren | orchestrator-1 | IKKE STARTET |
| 7 | Bygging, bølge 1 | alle lanes | IKKE STARTET |

Faseportene er bevisste: ingenting bygges før fase 6 er lukket, og ingen push uten «OK kjør».

## Rollefordeling i rådet

Ni ekspertroller, fordelt på det panene faktisk kan:

| Rådsrolle | Pane | Hvorfor den |
|---|---|---|
| Chief Product Architect (orkestrator) | orchestrator-1 | eier programmet, beslutningsmatrisen og ADR-ene |
| Azure Cloud Architect + FinOps & Security | infra-1 | eier Railway/Vercel/GCP i dag, har gjort kostnads- og secrets-arbeidet |
| AI Agent Systems Engineer | tools-1 | eier capability-registryet, omnigent-harnesset, MCP-flåten, heygen-vurderingen |
| Procurement Intelligence (data) | data-1 | eier innhenting, dedup, dokumentdekning, Myhre-korpuset |
| ML & Recommender Engineer | learning-1 | eier rangering, feedback, evaluering |
| Staff Software Engineer | trading-1 | har bygget i plattformen (PR #140), eier migreringsplan og API-kontrakter |
| Chief Product Strategist | paal-1 | sitter nærmest en reell kunde, eier forretningsmodell og differensiering |
| Legal & Regulatory Analyst | admin-1 | eier regelverk, KOFA, GDPR, kildehierarkiet |
| Senior UX/UI Designer | workflow-agent (`frontend-craft`) | ingen pane er designer; rollen kjøres som agent |

Codex-panene holdes utenfor runde 1 med vilje. De brukes som uavhengig red-team i fase 4, der det er en fordel at de ikke har vært med på å forme forslagene.

## Fem problemstillinger fra operatøren, pluss én

- **A. Radikalt bedre brukeropplevelse.** Tre alternativer (enklere dashboard / agent-first / hybrid), alle skal utfordres. Chat erstatter ikke gode visuelle kontroller før oppgaveeffektivitet viser det.
- **B. Selvlærende anbefalingsmotor.** Harde filtre → hybrid retrieval → forklarbar rangering → eksplisitt feedback → læring fra utfall. LLM skal ikke være eneste rangeringsmotor.
- **C. Procurement market intelligence.** Doffin/TED, tildelinger, budsjetter, KOFA, Myhre, foa.no. Kommentar skal aldri fremstå som bindende rett.
- **D. Agentbasert produktarkitektur.** Åtte foreslåtte agentroller — men spørsmålet er om de bør være åtte agenter eller færre tjenester med gode verktøy.
- **E. Produktøkonomi.** MVP / 10 kunder / 100 kunder, faste mot variable kostnader, med oppdaterte priser og dokumenterte antakelser.
- **F. Konsolidering av agentflåten.** Operatørens egen smerte: «16 paner er uryddig. Alt kan komprimeres og jeg kan fortsatt være like effektiv, spesielt om jeg kan snakke med agentene og ha ting kjørende live.» Hen sier dette er verdt å investere i og kan være nyttig for andre — altså potensielt produkt, ikke bare internt verktøy. Lagt til som egen problemstilling fordi den ellers faller mellom D og E.

## Rammer som gjelder alle agenter

- Maks ~10 minutter per agent, ingen looper, lever delvis arbeid framfor å henge.
- `FACT` / `IMPL` / `FORESLÅTT` / `ANTAKELSE` på hver påstand, med fil:linje, kommando+output eller URL. Udokumenterte påstander strykes i red-team-runden.
- Les-only i `Veldora-rad`. Ingen push, ingen prod-endringer, ingen Azure-deploy, ingen betalte skykall.
- Produksjonen er i bruk LIVE til å vurdere anbud akkurat nå. Ingenting fjernes.
- Deterministiske regler for kritiske avgjørelser; menneskelig godkjenning ved juridiske, økonomiske og eksterne handlinger.

## Leveranser i fase 5

Åtte dokumenter: `PRODUCT_VISION`, `AI_RECOMMENDATION_ENGINE`, `PROCUREMENT_INTELLIGENCE`, `AGENT_ARCHITECTURE`, `AZURE_COST_MODEL`, `UX_REDESIGN`, `EXECUTION_ROADMAP`, `COUNCIL_DECISIONS`. Plasseringen avgjøres i fase 3 — repoet bruker i dag `strategy/`, `decisions/`, `prd/` og `issues/` i roten, mens bestillingen ber om `docs/`-stier, og vi skal ikke ende med to konkurrerende konvensjoner.

Hvert dokument skiller eksplisitt mellom **allerede implementert**, **foreslått** og **verifisert fungerende**.

## Kjente åpne operatør-gater (fra i går, ikke lukket)

Disse står i veien uavhengig av dette programmet, og fase 3 avgjør hvilke som er blokkerende:

1. Rotasjon av node-stackens passord (to reelle funn i memory.db).
2. `infra-1/leak-scan` i command-center.
3. Preview-beskyttelse i Vercel.
4. Prod-legitimasjon til paal-1.
5. Strategiforslaget `strategy/proposals/2026-10-12-tre-scopes.md`, frist 19.10.
6. De fire ja-ene utenfor uttalt scope — er scopet for smalt, eller var ja-ene feil?
7. Oppbevaringstid for intern chat er ikke satt; uten regel beholdes alt.
8. Slack-speiling (`channels:history`) og AI-uttrekk fra chat — spesifisert, ikke bygget.

## Panestatus 2026-10-13 10:20

Seks synlige paner: orchestrator-1, infra-1, tools-1, learning-1, trading-1, admin-1. **data-1 og paal-1 har ikke synlig pane**, men begge kjører rådsordren headless via sin `firm-remote-executor`-unit — verifisert med claim-logg 10:17:37 og levende `claude -p`-prosess. Arbeidet er altså ikke tapt; det er bare ikke synlig for operatøren.
