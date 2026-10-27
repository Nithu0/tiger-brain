# Ruteinventar — Anbud-dashboard (src/app/(app)/)

Kartlegging før menyrevisjon: operatøren vil fra lang toppmeny til ett flytende
dashboard. Mål: se hva som faktisk finnes, hva som brukes, hva som overlapper,
før noe rives. Ingen endringer gjort — ren kartlegging.

Kilder: `projects/anbud/dashboard/src/app/(app)/**/page.tsx`,
`src/components/NavLinks.tsx`, `src/lib/nav.ts`, `src/components/nav.module.css`,
`projects/anbud/ARCHITECTURE.md` §8, samt grep for interne `<Link href="/...">`
på tvers av dashboardet (for å finne foreldreløse ruter — reachable kun via meny).

## Menyen (`src/lib/nav.ts`, brukt av `NavLinks.tsx`)

- **Ingen rollestyring i menyen.** `NAV_LINKS` er en statisk liste på 22
  lenker, rendret likt for alle (viewer/member/admin). Rollesjekk skjer per
  CMS-endepunkt (knapper skjules i selve siden), ikke i navigasjonen.
- Rekkefølge i `NAV_LINKS` (= desktop-meny og «Mer»-skuffen på mobil):
  Oversikt, Pipeline, Til godkjenning, Salg, Innboks, Økonomi, Rapport,
  Intervju, Kompetanse, Bevis, Juridisk, Juristvurderinger, Kunngjøringer,
  Triage, Møtemodus, Marked, Statistikk, Nyheter, Forventede anbud, Agenter,
  AI-bruk, Kalibrering.
- Mobil (`TabBar`, < 768 px): kun 4 faste faner — Oversikt, Triage (med
  tallmerke), Pipeline, Marked — pluss «Mer» som åpner et skjermbilde med hele
  listen over + «Varsler» (`MORE_LINKS = NAV_LINKS + Varsler`).
- `/innstillinger/varsler` («Varsler») ligger **ikke** i `NAV_LINKS`, bare i
  headeren (desktop) og i «Mer»-skuffen (mobil) — den er allerede halvveis ute
  av hovedmenyen.
- Mange detaljsider (`/opportunities/[id]`, `/salg/[id]`, `/oppdrag/[id]`,
  `/innboks/[id]`, `/kompetanse/person/[id]` osv.) ligger **ikke** i menyen i
  det hele tatt — de nås ved å klikke fra en listeside. Meny-rydding handler
  altså om 22 toppnivå-lenker, ikke om de ~16 detaljrutene under dem.

## Tabell: alle 38 ruter

Sortert slik at «ren backend» og foreldreløse ruter kommer først (kandidater
for å forsvinne fra menyen).

| Rute | Hva den gjør | Bøtte | Begrunnelse |
|---|---|---|---|
| `/ai` | Viser token-/kostnadsforbruk per LLM-kall, fordelt på modell og datatype. | **Ren backend** | Rent observability-dashboard over kostnad, ingen beslutning tas her. Foreldreløs — ingen annen side lenker inn, kun menyen. Kunne vært et API/rapport, eller slått sammen med «Agenter»/«Kalibrering» til ett systempanel. |
| `/agents` | Siste kjøring per agent-slug, feil siste 24 t, worker-heartbeat-alder. | **Ren backend** | Driftsovervåking av bakgrunnsjobber, ikke en vurderingsflate. Lenkes inn fra `/` («Agent-helse»-lenke), men er i praksis en logg en operatør sjekker ved feil — hører hjemme som alert/API, ikke egen menypost. |
| `/calibration` | Brier-score, reliability-bøtter og siste prediksjoner for vinnsannsynlighetsmodellen. | **Ren backend** | Modell-kvalitetsmåling, ingen sak vurderes. Lenkes inn fra `/statistikk` (undermeny), ikke fra menyen i praktisk bruk — kandidat til å bli en fane under Statistikk i stedet for egen toppnivålenke. |
| `/opportunities/[id]/tilbud/utskrift` | Utskriftsvennlig versjon av tilbudsutkastet (app-kromme skjult i print). | **Ren backend** | Ikke en side et menneske navigerer til for å «se» noe — det er en renderingsmål for utskrift, nådd via en knapp inne i `/opportunities/[id]`. Riktig sted: fortsatt en lenke fra saken, aldri i menyen (og er det heller ikke i dag). |
| `/jurist` | Ren redirect til `/juridisk` («det finnes ikke lenger en jurist-rolle»). | **Ren backend** | Dokumentert dødt alias i koden selv («Old address»). Kan fjernes helt når ingen eksterne bokmerker peker dit lenger. |
| `/rapport` | Ukesrapport mot 90-dagersplanen; kjør rapport nå, foreslå styrenotat, last ned .docx. | **Administrasjon** (foreldreløs) | Ingen annen side lenker inn — kun nådd via menyen. Brukes sjelden (ukentlig rutine for ledelsen), passer som admin-/rapportfunksjon, ikke i et operativt dashboard. |
| `/nyheter` | Ukentlig nyhetsdigest (markedshendelser) med kategorifilter. | **Oppslag** (foreldreløs) | Ingen intern side lenker til `/nyheter` — kun menyen. Slås opp av og til («hva skjedde denne uken»), egner seg bak søk/skuff heller enn fast menypunkt. |
| `/okonomi` | Fakturaoversikt, avstemming per periode, kø for fakturakladd. | **Administrasjon** (foreldreløs) | Ingen side lenker *til* `/okonomi` (selve siden lenker *ut* til `/oppdrag/[id]`), kun menyen. Regnskaps-/avstemmingsarbeid — adminflate, sjelden besøkt mellom periodeavslutninger. |
| `/tenders/triage/historikk` | Logg over triage-avgjørelser med angre-knapp per rad. | **Oppslag** | Nådd via lenke fra `/tenders/triage` (ikke foreldreløs), men er en revisjonslogg man slår opp ved behov («hvem avgjorde dette»), ikke en vurderingsflate i seg selv. |
| `/innstillinger/varsler` | E-post- og push-varselinnstillinger for den innloggede brukeren. | **Administrasjon** | Rent oppsett, ikke sakrelatert. Allerede delvis ute av hovedmenyen (kun header/«Mer») — naturlig admin-side bak et innstillinger-ikon i det nye dashboardet. |
| `/juridisk/kilder` | Søk/oppslag i juridisk kildekorpus (lovtekst, KOFA-avgjørelser). | **Oppslag** | Referanseoppslag, ikke en konkret sak. Lenkes inn fra `/juridisk/assistent` m.fl. — brukes av og til, passer bak søk. |
| `/juridisk/assistent` | «Spør rettskildene» — kildebundet LLM-spørsmål/svar mot lovtekst. | **Oppslag** | Ad-hoc oppslag («hva sier forskriften om X»), ikke vurdering av en konkret sak selv om den kan åpnes med saks-kontekst. Lenkes inn fra `/juridisk`. |
| `/forventet` | Liste over forventede/varslede anbud (vaktliste), med status og treff. | **Oppslag** | «Se hva som kan komme» — slås opp periodisk, ikke en daglig vurderingsflate. Lenkes inn fra ≥3 steder (ikke foreldreløs), men naturlig hjemme i en skuff. |
| `/forventet/ny` | Opprett et nytt forventet-anbud-oppslag (skjema). | **Oppslag** | Oppsett/registrering tilhørende `/forventet`-familien; samme bøtte som lista. |
| `/forventet/[id]` | Detalj/rediger ett forventet anbud. | **Oppslag** | Samme familie som over. |
| `/kompetanse` | Kompetansebank: personer, referanser, kunder, fakta (faner). | **Oppslag** | Slås opp når man bygger en sak (krav-dekning, CV, referanser), ikke en daglig vurderingsside i seg selv. Godt lenket fra `/opportunities/[id]` (krav-fanen). |
| `/kompetanse/person/[id]` | Én persons CV, ferdigheter, referanser. | **Oppslag** | Detaljoppslag i kompetansebanken. |
| `/kompetanse/referanse/[id]` | Én kundereferanse i detalj. | **Oppslag** | Samme familie. |
| `/bevis` | Bevisarkiv: selskapsfakta, dokumenter/attester, kompetansebevis med bekreftelsesstatus. | **Oppslag** | Oppslag/bekreftelse av bevis brukt i kvalifikasjon — gjøres av og til (admin bekrefter), ikke løpende saksvurdering. |
| `/marked` | Markedsoversikt: bransjesegmenter, konkurrenter, volumer. | **Oppslag** | Markedsintelligens man slår opp, ikke en sak. Er i mobil-fanebaren (høy bruksfrekvens antatt), men innholdsmessig et oppslagsverktøy. |
| `/marked/kjoper/[id]` | Én oppdragsgivers historikk/tidslinje. | **Oppslag** | Detaljoppslag under Marked. |
| `/marked/leverandor/[id]` | Én leverandørs/konkurrents profil. | **Oppslag** | Detaljoppslag under Marked; lenker tilbake til `/statistikk`. |
| `/statistikk` | Nøkkeltall: pipeline-funnel, segmentstatistikk, leverandørrader. | **Oppslag** | Overlapper sterkt med `/marked` (samme CSS-modul, samme `barPct`/`formatMnok`-funksjoner) — se overlapp-avsnitt. Slås opp periodisk. |
| `/juridisk/kommentarer` | «Juristvurderinger» — liste over juridiske kommentarer/merknader på tilbud, filtrert på status. | **Vurderingsflate** | Del av den faktiske saksbehandlingen (juridisk kvalitetssikring av tilbud), men er i praksis en egen meny-post for noe som også vises inne i `/opportunities/[id]?fane=tilbud`. Sterk overlapp-kandidat. |
| `/juridisk/feilsjekk/[id]` | Full feilsjekk-rapport av konkurransegrunnlag for én sak (lovtekst + modellens forklaringer). | **Vurderingsflate** | Konkret saksvurdering, lenket fra `/juridisk`. |
| `/juridisk` | Delt oversikt: saker til juridisk gjennomgang, åpne kontraktsflagg, forbehold, frister. | **Vurderingsflate** | Kjernearbeidsflate for juridisk kvalitetssikring over flere saker — hører hjemme i det nye dashboardet, men bør vurderes samlet med `/juridisk/kommentarer` og `/juridisk/feilsjekk`. |
| `/intervju` | Spørsmålsrunder (onboarding + per-sak), ubesvarte og nylig besvarte spørsmål. | **Vurderingsflate** | Operativ arbeidskø — besvare spørsmål knyttet til konkrete saker/onboarding. |
| `/innboks/[id]` | Behandle én innkommende melding (e-post/WhatsApp/kontaktformular): kategoriser, svarutkast, godkjenn. | **Vurderingsflate** | Konkret sak å håndtere per melding. |
| `/innboks` | Liste over innkommende meldinger med kategori, hastighet, svarutkast-status. | **Vurderingsflate** | Overlapper med forsidens («/») signal-innboks — se overlapp-avsnitt. |
| `/godkjenning` | Én godkjenningskø tvers over alle grener (agent-forslag → menneske avgjør). | **Vurderingsflate** | Kjerneflate: mennesker tar beslutninger på agent-forslag. Lenket fra flere sider (oppdrag, økonomi). |
| `/salg` | Ringeliste/kvalifisering av prospekter, prioritert. | **Vurderingsflate** | Operativt salgsarbeid på konkrete prospekter. |
| `/salg/[id]` | Ett salgstilbud/prospekt i detalj — fremdrift, signatur, oppstart. | **Vurderingsflate** | Saksbehandling av ett salgsobjekt. |
| `/oppdrag/[id]` | Leveranseside for ett oppdrag: KS-sjekkliste, timer, faktura, energidata-rapport. | **Vurderingsflate** | Operativ leveranseoppfølging per oppdrag. |
| `/opportunities/[id]` | Hovedsiden for én anbudssak: oversikt, krav, kvalifikasjon, brief, tilbud, arbeid (faner). | **Vurderingsflate** | **Dette er kjerneflaten** — den tyngste og mest detaljerte siden i hele appen (se ARCHITECTURE.md §8). Naturlig kjerne i det nye flytende dashboardet; ikke i toppmenyen i dag (nås via klikk fra liste), så den er allerede «dashboard-aktig». |
| `/tenders/triage` | Avgjør relevans (fit/ikke-fit) på kunngjøringer i kø, med tallmerke i menyen. | **Vurderingsflate** | Daglig beslutningsarbeid — høy reell bruk (tallmerke på «Triage» i både desktop- og mobilmeny, og egen fane i den begrensede 4-fane mobilbaren). |
| `/mote/kjor` | Kjør møtemodus: gå gjennom en frosset liste av saker i møte, én om én. | **Vurderingsflate** | Operativt møteverktøy, lenket fra `/mote`. |
| `/mote/referat` | Møtereferat/oppsummering etter kjørt møte, med åpne handlinger. | **Vurderingsflate** | Samme familie, lenket fra `/mote/kjor`-flyten. |
| `/mote` | «Møtemodus» — team + jurist går gjennom saker sammen, bygger listen som kjøres i `/mote/kjor`. | **Vurderingsflate** | Operativ møteforberedelse. |
| `/pipeline` | Kanban over saker etter status, drag-and-drop, prioritet/verdi/effort-chips. | **Vurderingsflate** | Kjerneflate for porteføljeoversikt — sterk overlapp med `/tenders` og `/` (se overlapp-avsnitt). |
| `/tenders` | Søkbar/filtrerbar tabell over alle kunngjøringer, med triage-knapp. | **Oppslag/Vurderingsflate (grense)** | Primært et søk/filter-oppslag over kunngjøringer, men med en tydelig handling («Start triage») inn i vurderingsflyten. Overlapper mye med `/pipeline` og `/`. |
| `/` | Forsiden: KPI-rad, innboks av signaler/handlinger, frister, agent-helse, prioriterte saker. | **Vurderingsflate** | Dette *er* allerede et dashboard — operatørens ønskede sluttilstand ligner mest på denne siden utvidet, ikke en ny ting fra scratch. |

## Overlapp — ruter som viser mye av det samme

1. **`/` vs. `/innboks`** — forsiden bygger sin innboks-sekson fra samme
   signalgrunnlag som `/innboks` (`inboxFromSignals` som fallback når
   dedikert endepunkt svikter). To ulike "innboks"-konsepter (system-signaler
   vs. meldinger fra omverdenen) som ser identiske ut for brukeren.
2. **`/` vs. `/pipeline` vs. `/tenders`** — tre visninger av samme
   sak-populasjon (prioriterte saker / kanban / tabell), med delvis samme
   filterregler (fit ≥ 40, `urealistisk`-skjuling, `priorityScore`-sortering).
   Kandidat for å bli faner/visningsmodi i ett dashboard-widget, ikke tre
   menypunkter.
3. **`/statistikk` vs. `/marked`** — deler CSS-modul (`market.module.css`) og
   hjelpefunksjoner (`barPct`, `formatMnok`); begge er "tall om markedet og
   leverandører", bare med ulik inngang. `/marked/leverandor/[id]` lenker
   tilbake til `/statistikk`, som igjen lenker til `/calibration`.
4. **`/agents` vs. `/ai` vs. `/calibration`** — alle tre er
   observability-paneler over det automatiserte laget (jobbkjøringer,
   LLM-kostnad, modellkalibrering). Naturlige kandidater til ett samlet
   "systemstatus"-panel i stedet for tre separate menyvalg.
5. **`/juridisk` vs. `/juridisk/kommentarer` vs. `/juridisk/feilsjekk/[id]`**
   — alle tre er juridisk kvalitetssikring av tilbud, og deler mye innhold
   med tilbuds-fanen på `/opportunities/[id]?fane=tilbud` (kontraktsflagg,
   forbehold, juridisk merknad). Fire steder viser delvis samme juridiske
   status på en sak.
6. **`/godkjenning` vs. handlinger inne i `/oppdrag/[id]` og `/okonomi`** —
   godkjenningskøen er «én kø tvers over alle grener», men oppdrag/økonomi
   har egne lokale godkjennings-knapper (KS-avgjørelse, fakturastatus) som i
   praksis er samme mønster (agent foreslår → menneske avgjør) implementert
   flere steder.

## De ti viktigste linjene (for svaret til brukeren)

Levert i fil: `~/Obsidian/Brain/00-claude-inbox/Veldora/2026-10-11_ruteinventar.md`
