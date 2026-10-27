# trading-1 — overlevering til orchestrator-1 (2026-10-18)

Alt jeg har levert, alt som er åpent, og det jeg har lært, samlet ett sted. Repo: Solar-Consulting (Veldora). Tilstand
sjekket med `gh pr list` og `git status` i hvert worktree da fila ble skrevet.

## 1. Levert og merget

| PR | Hva | Status |
|---|---|---|
| #186 (SC-01b) | Lesere av tenders tåler 130x: scan-news fra åpne muligheter, verdi-jobbene ser 365 d / ACTIVE. Målt mot PG18 med 272k rader: scan-news krasj → 0,26 s | merget |
| #195 | `requeue:failed -- --task <slug>` for døde LLM-jobber (tender-brief, assess, extract) | merget |
| #198 | Konkurransegrunnlag som rene funksjoner + forhåndsregistrering for red team | merget |
| #202 | Red team nivå A-datasett: 20 ekte eForm-kriterier, 20 SYNTETISKE svar, 80 par | merget |
| #234 | Overvåker 3.2: B (radar.expiring) og C (tender.similar), bak MONITOR_AGENT_ENABLED | merget |
| #238 | Konkurranseagenten 2.3 (sløyfe, fakta fra verktøyene, tall i kode) + migrering (task-slug) | merget |
| #241 | Eval overvåker C: holder ikke (recall 4/8), C av (SIMILAR_BANDS=null) | merget |
| #248 | Eval konkurranseagenten: presisjon 1,00 (kildekontroll v3), negativ kontroll 6 % | merget |
| #263 | «Realistisk å vinne» | **lukket som duplikat** av #262 (tools-1) |

SC-01 (historikk-backfill) ble overtatt av infra-1 16.10. Mine data og funn er overlevert der.

## 2. Åpne tråder (venter på andre)

1. **Merkeark A** (overvåker strøm A): `00-claude-inbox/solar-consulting/OVERVAKER-A-MERKEARK.md`, 30 rader. Operatøren merker
   relevant ja/nei + grunn (~20 min). Først da kan A bygges og evalueres (presisjon og recall ≥ 0,80).
2. **Stikkprøve B23-eval:** resultatet er ASSUMPTION til et menneske har åpnet 5 av de 43 v1-avvikene
   (`TIL_MENNESKE` i `crm/eval/konkurranse-kilde-v1-2026-10-18.txt`) og sett verdien i kilden (~5 min).
   Begrunnelse: kontrollskriptet ble rettet etter kjøringen (avvik fra forhåndsregistreringen, står i resultatfila).
3. **Godkjenning red team nivå A:** `crm/eval/redteam/nivaa-a/GODKJENNING.md`. En eier godkjenner de 20 syntetiske svarene
   før settet fryses og nivå A kan kjøres (~17 USD, tak avtales).
4. **Skyggemodus B ca. 2026-11-01:** tell `radar.expiring.shadow`, sjekk hver mot `retender-predictions` og kilden, og avgjør påslag.
   **Jeg har ingen planlegger som overlever sesjonen: minn meg på det i innboksen eller GOALS.**
5. **Overvåker C parkert:** ny eval først når beslutningsloggen er lengre (dev: 32/62 rader uten tidligere beslutning), med
   nytt testsett og ny forhåndsregistrering. Aldri justering mot det gamle testsettet.
6. **Input-hull i kompetansebanken:** 0 fakta om leveranse, prosjekter, metode eller resultater (23 fakta, alle om tilbudsflyt).
   Tilbudsskriveren og red team nivå B trenger CV, prosjekter med kunde/år/verdi/rolle, referansepersoner, sertifiseringer og metode per eier
   (`BOLGE2-DESIGN.md`). Dette er den viktigste flaskehalsen for bølge 2.
7. **Red team nivå B:** krever tilbudstekst med kjent poeng. Kilden er innsyn i vinnerens tilbud (issue 057, HITL, jurist-sjekk av malen er UNKNOWN).
8. **Funn til paal-1** (allerede videresendt): `down()` i `20261017_151211_sc02_tildelinger.ts` feiler når alle migreringer rulles ned som
   én batch (constraint `…retender_predictions_fk` finnes ikke). Det rammer ikke prod, men en rollback av SC-02 vil feile.
9. **Issue 056:** kjøpertidslinjen kuttes ved 500 kunngjøringer (`anbud.ts`, ikke rørt av meg).

## 3. Worktrees og grener

Alle mine worktrees er rene og pushet: Veldora-sc01b, -requeue, -b2, -b2rt, -b23 (b23-eval), -b23b (b23b-realistisk, **ikke rør**:
duplikat av #262), -b32 (b32-bands). De kan fjernes når du vil (`git worktree remove`, operatørgatet sletting).
`Veldora-sc01` (sc-01-historikk) har 4 ucommittede filer, men det er infra-1 sitt worktree. Jeg har ikke rørt det.
Ingen engangsbaser kjører.

## 4. Lærdom (lagret i minnet mitt, gjelder fra nå)

- **Monitor og innboks:** to ganger har jeg misset meldinger (16.10 overtakelse SC-01, 18.10 b23b). Den siste gangen var
  årsaken lange blokkerende forgrunnskommandoer under load ~41. Nå: ingen forgrunnskommando over ~5 min, tunge kjøringer i bakgrunnen,
  `tail` av innboksen før hver commit og push, STATUS hver 30. min ved venting.
- **Actions-minutter:** én push når jeg er ferdig, main-merge bare ved CONFLICTING, aldri rerun uten å ha lest loggen.
- **Git:** aldri `checkout <ref> -- .` (overskrev b23-worktreet 18.10, ingen tap). Bruk `git show ref:path` eller `git restore --source` på enkeltfiler.
- **`railway ssh` fjerner anførselstegn:** `sh -c '…'` blir splittet. Bruk kommandoer uten anførselstegn (`test -f …`).
- **Eval-disiplin:** forhåndsregistrering i egen commit før kjøring. Rett kontrollverktøy åpent og skriv det som avvik.
  Bruk negative kontroller for å vise at et kontrollskript ikke er for slapt. Skriv «lest av trading-1», ikke «av et menneske», når det er meg.

## 5. Tall jeg målte (FACT, dato og kilde i eval-filene)

- Prod 16.10: tenders 2 102 (alle 2026), awards 642, DOFFIN_API_KEY MISSING. Doffin webklient 160 100 treff fra 2017, TED buyer-country=NOR 111 062 fra 2016-10.
- Bølge 2-dekning 17.10: 15/50 muligheter med nok data fra awards, 36/50 fra RESULT-kunngjøringer etter steg 1 (delvis).
- Overvåker-grunnlag 18.10: 8,7 tidlige kunngjøringer per døgn, 126 på 30 d hos 23 av 42 kjøpere. Radar 22 (12 innen 6 mnd). Modellkost 0,6–2,4 USD per døgn.
- Konkurranseagenten i prod: 10/10, 234 fakta, 0,46 USD, presisjon 1,00 (v3).
- Overvåker C test: recall 0,50 (4/8), C2 0,286 = nøkkelord.
