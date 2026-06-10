# Multi-round investment-research pattern

**Etablert:** 2026-05-27 (første gang kjørt: [[sessions/2026-05-27-40k-nok-friend]])
**Forfatter:** ai-1
**Status:** v1 — utvikles over tid

---

## Når brukes dette

Når operator ber om aksje-/ETF-/makro-research for en konkret investeringsbeslutning. Eksempel: "kompis vil putte X NOK i én aksje, Y mnd horisont, Z% best case."

---

## Kjernemønster: 4 runder

### Runde 1 — Bred screen (10 parallelle agenter)

Dispatch én agent per **disjoint vinkel** så ingen overlapp:

1. Makro-bakgrunn (Fed/ECB/Norges Bank, recession-risk, sektor-rotasjon, USD/NOK)
2. Mega-cap tech (Mag7 + tier-2 hvis relevant)
3. Mid-cap quality compounders (ROIC>15%, FCF-margin>20%)
4. AI infrastructure / picks-and-shovels
5. Healthcare / biotech med katalysator i vinduet
6. Fintech / consumer-tech
7. European tech (excl. sektorer operator har ekskludert)
8. Nordic / Norwegian (for ASK-fordel)
9. Catalyst-kalender for vinduet
10. Risk + FX + ASK-eligibility framework

Hver agent får: WebSearch + WebFetch, ASK om EØS-bias, output-format <250 ord, sitater + URL-er.

**Anti-pattern:** ikke gi alle agenter samme prompt — det dupliserer arbeid. Hvert dispatch må ha tydelig mandat.

### Runde 2 — Bear-case / counter-screen (4-5 agenter)

Runde 1 har bull-bias bygget inn ("find me 3 picks"). Runde 2 må eksplisitt motvirke det:

1. **Bear-case / devil's advocate** mot top-3 fra runde 1 — finn det som vil få operator til å AVVISE picken
2. **Technical setup** (TradingView/Yahoo: 50/200 MA, RSI, MACD, support/resistance, entry/stop/target)
3. **Insider + analyst-flow** (OpenInsider, SEC Form 4, Oslo Børs PDMR notifikasjoner, PT-revisjoner siste 90d)
4. **Earnings-whisper** for neste rapport i vinduet (consensus, beat-and-raise-odds, sell-the-news-risk)
5. **Defensiv + wildcard alternativ** (én lav-risk-pick + én asymmetri-pick som backup)

Bear-case-agenten er den viktigste. Den fanget i 2026-05-27-sesjonen:
- NOVO CagriSema-miss feb '26 + Goldman PT-kutt $63→$41 (bull-runden hadde missed det)
- TOMRA Q1 katastrofe — Recycling -19%, EBITA-tap, ingen vekst-guide 2026
- Begge ble nedgradert ut av top-3 etter denne runden

**Bull-runden alene vil systematisk over-anbefale.** Bear-runden er ikke valgfri.

### Runde 3 — Tematisk pivot (når operator endrer fokus)

Operator vil typisk pivotere etter Runde 2: "kompis sa han er interessert i quantum/AI/biotech/X". Da:

1. Deep-dive på den spesifikke produktet operator nevnte (en ETF, en aksje)
2. Markedets-intel for det temaet (events, kommersielle avtaler, regulatorisk)
3. Pure-play-kandidater
4. ETF-alternativer for samme tema
5. Single-stock-alternativer for samme tema
6. **ETF vs single-stock framework** (matematikken på +20%-mandat, behavioral risk, tax)

Denne runden gjenbruker noen elementer fra Runde 1 (sektor-spesifikt) men er fokusert på operator's nye uttrykte interesse.

### Runde 4 — Praktisk mekanikk (når operator vil execute)

Operator: "han vil kjøpe nå". KRITISK runde — det er her drømme-picks møter virkelighet:

1. **Broker-kapabilitet** for den valgte aksjen (Nordnet/DNB/Saxo)
2. **Lot-størrelser** (TSE 100-share lots blokkerer Advantest/Tokyo Electron for <50k NOK)
3. **Asia-tilgang** (Nordnet har INGEN direkte Asia — alt via ADR på NYSE)
4. **Markedstider** (Asia 02-08 CET, Europa 09-17, US 15:30-22:15)
5. **Limit-ordre-strategi** (overnight queueing, gap-risk-mitigation, hva som faktisk er tradable)
6. **Skatte-implikasjon** (ASK-eligible? withholding tax på dividender?)

**Lessons learned 2026-05-27:** Antok at "limit-ordre i kveld på Asia-aksje" var trivielt. Det var det IKKE — Nordnet har null Asia-direkte. Måtte pivotere til ADR-route. **Sjekk broker-mekanikk TIDLIG, ikke til slutt.**

---

## Synthesis-format

Etter alle runder:
1. Dokument-versjon i Obsidian (full rapport, alle sitater, ~700 linjer)
2. Messenger-versjon for forwarding (~3-5 skjermer, ingen tabeller, mobile-readable)
3. Discord-versjon for Karri-style audit/showcase hvis relevant

---

## Anti-patterns lært i v1

- ❌ Skip bear-round — vil over-anbefale
- ❌ Anta broker har eksotisk markedstilgang — sjekk først
- ❌ Bruk stale priser fra training data — VERIFY ALT via WebSearch (NOVO 290 DKK, ikke 340 DKK)
- ❌ Foreslå US-aksjer uten å flagge ASK-tap (37,84% skatt-fordel)
- ❌ Ignorere lot-størrelse (TSE-aksjer >¥40k krever >100k NOK for én lot)
- ❌ Glemme NOK-styrkning som FX-headwind på USD-eksponering

## Best practices

- ✅ TaskCreate FØR dispatch — gir operator synlighet på hva som kjøres
- ✅ Mark task complete etterhvert som agenter returnerer
- ✅ Marker "MIKE TIL ALLE — XYZ-funn er stort" når en agent finner noe som endrer ranking
- ✅ Tellereste rangering: når bear/flow/technical/earnings alle peker samme retning = high conviction
- ✅ Eksplisitt skille: "min anbefaling" vs "alternativer"
- ✅ Lagre Messenger-versjon til `~/Obsidian/Brain/00-claude-inbox/investment-research/` for operator-forwarding

---

## Tilbake-pekere

- Forrige sesjon: [[sessions/2026-05-27-40k-nok-friend]]
- Reference: [[_reference/norwegian-retail-investor-constraints]]
- Reference: [[_reference/broker-capabilities-comparison]]
- Reference: [[_reference/available-research-apis]]
