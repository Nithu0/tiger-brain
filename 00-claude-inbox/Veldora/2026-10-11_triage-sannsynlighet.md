# Triage-kortet lest med traderøyne: vinnsjanse og forventet verdi

trading-1, 2026-10-11. Lest på `feat/anbud-triage-veiledning` (`~/code/Veldora-triage-c`). Report-only, ingen kode rørt. Full verifiseringskjede og lane-split ligger i `00-firm-bus/inbox/orchestrator-1.md`.

**Kort svar:** regnestykket er ryddig, presentasjonen er ikke ærlig, og forventet verdi mangler helt. Det siste er alvorligst, for EV er det eneste som avgjør om vi skal bruke en uke på et tilbud.

## 1. Vinnsjansen er riktig regnet og uærlig vist

Koden er ærlig der brukeren ikke ser den. `crm/src/config/model.ts:4` sier at de seks vektene er førstegangs gjetninger som skal tunes mot `predictions` når utfall finnes, og ingenting leser utfall tilbake i vektene. Det finnes ingen backtest eller kryssvalidering i prosjektet. Kalibreringssiden ber leseren lese tallene som en retning, ikke en fasit. Kortet sier ingenting: `TriageCard.tsx:117` → `bits.tsx:64` skriver «38 %» uten utvalgsstørrelse, modellversjon eller ordet anslag. Prisvekt-chippen rett ved siden av har forbehold i tooltip. Det tyngste tallet på kortet har ingen.

`ADR-0014` lovet det motsatte: tidlige vinnsjanser blir dårlig kalibrerte, og dashbordet skal si det. Kalibreringssiden sier det, kortet ikke. Mønsteret finnes dessuten alt i kodebasen: det lærte forslaget er sperret bak «Systemet lærer (n=X av 30)». Vinnsjansen hviler på null avgjorte konkurranser og vises uten reservasjon.

- **Utgangspunktet degraderer stille.** Ingen tildelinger i klyngen gir hardkodet fallback på fire tilbydere, altså flat 25 % for alt (`baseRates.ts:110`), mens forklaringsteksten hevder måling: «i snitt rundt 4 tilbydere» (`win.ts:75`). `expectedBidders` returnerer `n` og `source`, og `score.ts:251` lagrer dem i `predictions.features`, men `winBreakdown` tar bare tallet (`winProbability.ts:46`). Grensesnittet *kan* ikke ta forbehold. Billig fiks: ta `n` og `source` inn i breakdownen.
- **Hele prioren hviler på ett ikke-verifisert felt.** `awards.bidderCount` kommer fra `receivedTenders` i resultatkunngjøringen, og rader uten tallet forkastes stille (`baseRates.ts:91`).
- **Kortet skjuler utgangspunktet.** `TriageFremgang.tsx:34-38` viser topp fire bidrag i prosentpoeng og filtrerer prioren ut. Leseren ser «Fit opp +4,2 pp» og får aldri vite at grunnmuren er en antakelse. Bidragene er marginale og ikke addative, uten at noe sier det.
- **Tom kunnskap leses som 50/50.** Manglende fit og ingen vurderte skal-krav settes begge til 0,5 (`winProbability.ts:28`), numerisk umulig å skille fra «målt og midt på treet». Prioritetsmodellen gjør det riktig og sier at p er ukjent.
- **Anbefalingen stoler på fallbacken.** `brief.ts:363` slår «by» ved fit ≥ 60, dekning ≥ 0,8 og p ≥ 0,25. Fallback-prioren alene oppfyller p-kravet, så et anbud uten ett datapunkt om konkurransen kan få «by» som råd.
- **Kalibreringsløkken henger på én env-variabel.** Utfall settes bare for status `bidding`/`submitted`, og bare hvis `OUR_ORG_NUMBERS` er satt (`postmortem.ts:30-35`). `README.md:182` og `:207` hevder at den *er* satt i prod, Brønnøysund-verifisert. Det er en sjekkliste, ikke en live-lesning, og fire smoke-scripts setter variabelen selv når den mangler, så grønn smoke beviser ingenting. Merk at variabelen bare bærer utfallsveien: for kvalifisering er subjektet primært `supplier-profile.orgnr` (`ARCHITECTURE.md:258`, `:1157`).
- **Samme variabel treffer vinnmodellen, gjennom to innganger.** `ourOrgNumbers()` gir tom liste på tom env (`verticals.ts:192-197`), og da blir eksklusjonsfilteret i `findIncumbent` alltid sant (`score.ts:114`): vår egen tildeling returneres som incumbent. Den manuelle grenen feiler uavhengig av dette (`score.ts:184`), og `opp.incumbent` er en fri relasjon til `suppliers` (`Opportunities.ts:146`) som ingenting hindrer å peke på vår egen rad. Størrelsen bør oppgis som bidrag, ikke vekt: på rå vekt er incumbent fjerde, men fit og dekning er sentrert rundt 0,5 og kan maksimalt flytte ±0,60 og ±0,50, mens incumbent er et helt steg på 0,80 i én retning. Målt i avvik fra nøytral er rekkefølgen hard port 2,0, incumbent 0,8, så fit 0,6. I prosentpoeng koster leddet 12 pp ved p på 25 %, altså omtrent en halvering (0,52×), og rundt 19 pp nær 50 %, der sjansen faller til knapt to tredeler (0,62×). Award-grenen er tom til vi vinner noe, men den manuelle grenen kan fyre i dag.
- **Mindre funn:** overskriftsprosenten er beslutningstidens snapshot mens prosentpoengene regnes fra en `winBreakdown` som rescores hver natt (`TriageFremgang.tsx:34`), så de kan være fra to kjøringer. Bidrag vises med én desimal på et ukalibrert tall. Taket er 0,95. p gjenbrukes som signalkonfidens (`score.ts:279`), og `Forventede seire (Σp)` summerer ukalibrerte sannsynligheter og leser uscorede muligheter som 0.

Hva tallet blir i dag, fire forventede tilbydere der annet ikke er sagt:

| Situasjon | Vist vinnsjanse |
|---|---|
| Fit 50, dekning 50, ingen relasjon | 25 % |
| Fit 70, dekning 70 | 34 % |
| Fit 90, dekning 90, kunde hos oss | 59 % |
| Fit 90, ingen krav vurdert ennå | 50 % |
| Alt på maks, to tilbydere | 85 % |

Foreslått tekst under tallet: «Anslag fra wp-2. Sjansen hvis vi leverer tilbud. Ikke kalibrert: 0 avgjorte konkurranser. Utgangspunkt basert på N tildelinger» (eller «ingen data, antar 4 tilbydere»). Og tak 0,60 til kalibreringen har data.

## 2. Forventet verdi mangler

Kortet har fem felt: verdi, frist, fit, vinnsjanse, prisvekt. Innsats er ikke ett av dem, og leseren ganger verdi med sjanse i hodet. Det er der beslutninger går feil. `Σp` på forsiden er antall seire, ikke kroner mot kostnad. Ingen steder i repoet finnes `p × verdi`, dekningsbidrag eller netto.

Tre linjer som bør stå på kortet:

1. **Tilbudskostnad** i dager og kroner. Finnes ikke. `effort` (`scoring/priority.ts:165-221`) er ordinal, brukes bare som divisor i køsortering og vises ikke på kortet. `effortEstimateDays` er leveransens størrelse, ikke kostnaden for å skrive tilbudet. Det mangler én dagsrate og en oversettelse fra effort-score til dager.
2. **Break-even-vinnsjanse** = tilbudskostnad / (verdi × dekningsbidrag). Det ærligste tallet på kortet, for det krever ikke at p er kalibrert.
3. **Forventet dekningsbidrag** = p × verdi × DB − tilbudskostnad, merket anslag, med DB synlig som antakelse.

Regnet på 5 MNOK, 12 % dekningsbidrag og 120 timer til 1100 kr (illustrasjon, firmaet setter tallene): break-even 22 %. Ved p på 25 % er gevinsten 18 000 kr, altså omtrent null. Ved 40 % er den 108 000 kr. Uten break-even-linjen ser 25 % og 40 % nesten like ut på kortet, mens det ene er en bortkastet uke.

Fire ting til, fra nexus-logikken:

- **Rangér på kroner per innsatsdag, ikke på p.** Kapasiteten er bindende. `CAPACITY` har bare kontraktstørrelse og prosedyre, ingen timer.
- **Verdien er total, ikke årlig,** og ingenting deler på kontraktslengden. `format.ts:22-24` tolererer valutatekst som «NOK/år», så en årlig sum blir stille lest som totalverdi.
- **Rammeavtaler overvurderes systematisk** på rå totalverdi: delt på flere leverandører, ingen kjøpsgaranti. EV må bruke vår andel og avropssannsynlighet. Lot-verdier summeres ikke.
- **Vi lærer aldri kostnadssiden.** Avvisningsgrunnene har ingen kode for «for dyrt å by».

## Tre live-sjekker står igjen

1. Er `OUR_ORG_NUMBERS` faktisk satt på Railway? Dokumentasjonen sier ja, koden kan ikke bekrefte det, smoke maskerer forskjellen. Infra-1 eller operatøren.
2. Hvor mange `awards`-rader har `bidderCount` > 0, globalt og per CPV-klynge? Avgjør om prioren er empiri eller en konstant. Data-1.
3. Finnes det en opportunity der `incumbent` peker på vår egen supplier-rad? Avgjør om incumbent-feilen er latent eller aktiv i dag. Samme tilgang som punkt 2.

Korreksjonene på env-variabelen og presiseringen av incumbent-leddet kom fra admin-1s to gjennomganger 2026-10-11, hver etterprøvd av meg i kode.
