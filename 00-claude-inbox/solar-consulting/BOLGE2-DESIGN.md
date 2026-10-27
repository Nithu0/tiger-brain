# BØLGE 2 — design og datagrunnlag (2.3 konkurranse/pris, 2.2 red team)

trading-1, 2026-10-17. Oppdrag fra orchestrator-1 (18:3x). Bygger på
[AGENT-GRANSKNING.md](AGENT-GRANSKNING.md) §5 bølge 2, §6.3 og §6.5, og på agentstandarden
(`projects/anbud/docs/agenter.md`, PR #193, ikke merget). Kode: gren `b2-konkurransegrunnlag`
(worktree `~/code/Veldora-b2`, fra `origin/main` c3abdb4). Prod er bare lest, med skriptfil
(`crm/scripts/baseline/bolge2-dekning.sql`, resultat `crm/eval/bolge2-dekning-2026-10-17.txt`).

## Kort

- **2.3 trenger ingen ny datamodell.** Det meste finnes som rene funksjoner i `lib/radar/`
  (`whoWeMeet`, `benchmark`). Det som manglet var kjøperens egen tildelingshistorikk med kilde og
  break-even. Det er lagt til i `lib/konkurranse/grunnlag.ts` (rent, 7 tester). Agenten blir en tynn sløyfe
  som forteller om tallene og velger sammenlignbare saker. Den endrer aldri et tall og gir **aldri en pris**.
- **Dekning (FACT, prod 17.10):** 50 muligheter er besluttet STRONG_BID/BID/INVESTIGATE (25/15/10).
  Med dagens `awards` har **15 av 50** nok på alle tre målene (kjøper, tilbydere, pris). Fra
  RESULT-kunngjøringene backfillen har hentet til nå har **36 av 50** det. Det er før steg 1 er ferdig, og
  før awards er bygget fra dem (venter på SC-02-nøkkelen).
- **Break-even kan ikke regnes for noen sak i dag.** Timepris, fakturerbare timer og tilbudstimer er
  `UNKNOWN` i `prismodell.json` (#189). Funksjonen sier hvilket tall som mangler, i stedet for å gjette.
- **Red team har ingen fasit i prod.** `evaluation_lessons` = 0 rader, `klage_documents` = 0,
  `bid_sections` = 6 rader på 1 mulighet. Rangkorrelasjon mot nemnda (standardens krav) kan ikke måles ennå.
  Jeg foreslår derfor en forhåndsregistrert eval i to nivåer: A (følsomhet, kan kjøres nå) og B
  (kalibrering mot nemnd, når ≥ 20 rader med tekst fra ≥ 5 konkurranser finnes).

## 2.3 Konkurranse- og prisgrunnlag

### Hva agenten gir per mulighet

| Del | Kilde i koden | Basis |
|---|---|---|
| Kjøperens siste tildelinger (≤ 10, siste 5 år): vinner, org.nr, antall tilbydere, tildelt verdi, kontraktsslutt, lenke til resultatkunngjøringen | `buyerHistory` (ny) | FACT per rad. Sammendrag (vinnere, median tilbydere) bare fra n ≥ 3, ellers UNKNOWN |
| Hvem vi møter: sittende leverandør, sannsynlige konkurrenter, partnerkandidater, forventet antall tilbydere | `whoWeMeet` (finnes) | FACT/UNKNOWN per felt |
| Prisspenn på lignende tildelinger: p25/median/p75 i samme CPV5, ellers divisjon, siste 3 år, og kjøperens egne. Estimat mot tildelt (forhold) | `benchmark` (finnes) | Kvantiler bare fra n ≥ 5 |
| Break-even-vinnsjanse | `breakEvenWinProbability` (ny) | ASSUMPTION (modellforutsetning), UNKNOWN når en input mangler |

Break-even: tilbudskost = tilbudstimer × timepris (alternativkost). Dekningsbidrag = V × (1 − kostpris/timepris),
der kostpris = faste kostnader / fakturerbare timer (#189). p* = tilbudskost / dekningsbidrag.
V er kunngjøringens estimat, ellers median av sammenlignbare tildelinger. Kilden står i output
(`breakEvenValueSource`). `ASSUMPTION`: vi leverer hele V selv til egen timepris. Det holder ikke for
rammeavtaler med tak eller for underleveranser. Begge flagges i notatet når funksjonen kalles.

**Aldri en pris** håndheves på tre måter: output har ingen prisfelt (test), break-even gir en
sannsynlighet og ikke et beløp, og timeprisen er en input som et menneske setter.

### Form (når 0.1 og 1.4 finnes)

Sløyfe, Sonnet 5.5 `medium`, maks 8 steg, hendelsesdrevet på STRONG_BID/BID/INVESTIGATE.
Verktøyene er tools-1s `get_awards`, `get_buyer`, `search_tenders` og `get_tender`. Funksjonene her er det
`get_awards`/`get_buyer` bør returnere (formen er `Radar*`-typene, så REST, Local API og testlitteraler virker).
Modellen velger 3–10 sammenlignbare saker utover CPV-treffet og skriver et kort notat med
kilde-id per påstand. Alle tall kommer fra funksjonene. Notatet sjekkes av `verify.ts` på samme måte som briefen.

### Dekning (FACT, `eval/bolge2-dekning-2026-10-17.txt`, målt 2026-10-17 ~18:45)

Terskler fra koden, valgt før målingen: kjøper ≥ 3 tildelinger siste 5 år, tilbydere ≥ 3 med antall,
pris ≥ 5 med verdi i CPV5 eller divisjon siste 3 år.

| Mål (av 50) | awards i dag | RESULT-kunngjøringer nå |
|---|---|---|
| kjøper | 15 | 40 |
| tilbydere | 15 | 37 |
| pris CPV5 | 37 | 49 |
| pris CPV5 eller divisjon | 49 | 50 |
| **alle tre** | **15** | **36** |

- awards: 661 rader, alle tildelt i 2026, 83 med verdi.
- Backfill når målingen ble tatt: Doffin `result` 84 vinduer ferdige (2023-05-28..2025-01-04), 426 venter.
  TED `result` 130 venter. tenders: Doffin 2023 3 059 og 2024 4 442 (nesten bare RESULT).
- Forbehold for RESULT-kolonnen: «verdi» der teller kunngjøringens estimat også, ikke bare tildelt verdi
  (`ASSUMPTION`: overvurderer prisdekningen). Doffin- og TED-kopien av samme kunngjøring kan telles to ganger
  på kjøper. Awards bygget med SC-02-nøkkelen fjerner begge deler.
- `UNKNOWN`: tallene etter at steg 1 er ferdig. Kjør samme fil igjen
  (`./scripts/baseline/run-triage-baseline.sh --sql bolge2-dekning.sql`, fra en Railway-lenket katalog).

## 2.2 Red team: eval-design

Forhåndsregistreringen ligger i repoet: `crm/eval/redteam/FORHANDSREGISTRERING.md` (låses når du godkjenner).

- **Nivå A, følsomhet (kan kjøres nå):** 20 menneskeskrevne seksjonssvar mot ekte tildelingskriterier
  (eForm, `tenders.awardCriteria`), 4 forverringer per svar (uten bevis, vag, delvis, feil kriterium) = 80 par.
  Halvparten er dev og halvparten test, med frø 20261017.
  Porter på test: parvis rekkefølge ≥ 0,85, «ikke besvart» på feil kriterium = 1,00, sitatkontroll ≥ 0,95,
  spredning over 3 kjøringer ≤ 1,5 poeng. Holder alle: prod, merket «ikke kalibrert mot nemnd».
- **Nivå B, kalibrering:** fasit er `evaluation_lessons` med verifisert poeng **og** teksten som ble scoret
  (vårt tilbud, eller vinnerens tilbud fått ved innsyn). Spearman ρ, bootstrap over konkurranser.
  Port: L > 0,3 og ρ ≥ 0,5. Krever n ≥ 20 rader fra ≥ 5 konkurranser. Til da: «ikke målbart».
- **Kost:** nivå A på test ≈ 70 kall ≈ 17 USD (`ASSUMPTION`, 0,24 USD per kall). Avtales med operatør.

**Det evalen ikke løser (CLAUDE.md §8):** nivå B trenger tilbudstekst med kjent poeng. Den får vi bare
ved å levere tilbud og få tildelingsbrev, eller ved å begjære innsyn i vinnerens tilbud. Begge krever
et menneske. Uten det kan red team aldri påstå at den scorer som nemnda. Forslag: når SC-07 registrerer et
tildelingsbrev, oppretter den en oppgave «begjær innsyn i vinnerens tilbud» (HITL). Det er den billigste
kilden til fasit vi har.

## Leveranse og hva som gjenstår

- PR (liten, ingen migrering, push med `hold`): `lib/konkurranse/grunnlag.ts` + test, `scripts/baseline/bolge2-dekning.sql`,
  `eval/bolge2-dekning-2026-10-17.txt`, `eval/redteam/FORHANDSREGISTRERING.md`.
- Gjenstår for 2.3-agenten: 0.1 (sløyfe) og 1.4 (verktøy). Operatøren må sette timepris, fakturerbare timer og standard
  tilbudstimer før break-even gir tall.
- Gjenstår for 2.2: godkjent forhåndsregistrering → nivå A-settet (20 svar fra et menneske) → prompt (v2 fra #193) → kjøring.

## Viktigste input-hull: kompetansebanken har ingen leveransefakta (tillegg 2026-10-17 19:xx)

`FACT` (prod 17.10, `crm/eval/redteam-nivaa-a-raamateriale-2026-10-17.txt`): `capability_facts` har 23 rader, alle fra
intervjuet «Tilbudsflyt – oppstart» (vedlegg, varsler, tone, prising, foretrukne oppdragstyper), og 13 av dem er «lack»/UNKNOWN.
**0 fakta om hva vi har levert, for hvem, med hvilket resultat.** Det eneste tilbudsutkastet (Statnett) sier selv: «Ingen
referanser i kompetansebanken matcher kravene».

Tildelingskriteriene i de ekte kunngjøringene vi trakk (nivå A-utvalget) spør nesten alltid om det samme: tilbudt personells
kompetanse og erfaring, referanseprosjekter av sammenlignbart omfang, metode og gjennomføringsevne. Tilbudsskriveren (2.1) kan
bare skrive det banken har kilde til. Med dagens bank blir hver slik seksjon «Mangler dokumentasjon». Det er riktig output, men det
vinner ingen konkurranser.

**Hva tilbudsskriveren trenger, per eier** (operatøren eier innsamlingen):

| Fakta | Felt | Hvorfor |
|---|---|---|
| CV | utdanning (grad, år), sertifiseringer med gyldighet, år med relevant erfaring per fagområde, språk | Kvalifikasjonskrav og «kompetanse og erfaring»-kriterier (f.eks. «≥ 10 år, hvorav 5 de siste 7»). Samtykke til bruk i tilbud (finnes i `people`) |
| Prosjekter | kunde (org.nr), år fra–til, verdi (NOK), vår rolle, eierens rolle, omfang i timer, leveranse, resultat med tall, offentlig/privat | Referanseprosjekter vurderes på «omfang og sammenlignbarhet». Uten verdi og år kan ikke en nemnd vurdere dem |
| Referansepersoner | navn, rolle, kontaktinfo, samtykke, sist bekreftet | Kreves ofte i tilbudet («oppgi kontaktperson for hvert oppdrag»). Lagres som referanse, ikke som kontaktperson på en kunngjøring |
| Sertifiseringer og selskapsfakta | ISO, Miljøfyrtårn, forsikringer, HMS-kort | Kvalifikasjonskrav og miljøkriterier (miljø har ofte 30 %) |
| Metodebeskrivelser | prosjektmetode, kvalitetssikring, gjennomføringsplanmal | «Metode og gjennomføring» er nesten alltid et kriterium |

`ASSUMPTION`: 2–3 timer per eier for CV og 3–5 prosjekter. Det er sannsynligvis den innsatsen i bølge 2 som gir mest per time.
Utfordring (CLAUDE.md §8): for IT-oppdrag kan svaret være at vi mangler referanser (ADR-0015). Da er spørsmålet partnere, ikke tekst.

## Nivå A-datasettet (status 17.10)

Gren `b2-redteam-datasett` (worktree `~/code/Veldora-b2rt`): 20 ekte kriterier (eForm, prod, frø 20261017), 20 SYNTETISKE
originalsvar for fiktive leverandører, 80 par fra deterministiske forverringer (test 40), og `GODKJENNING.md` til eierne.
Tillegget i forhåndsregistreringen er datert og står før noen kjøring. Innsynsoppgaven er issue 057.
