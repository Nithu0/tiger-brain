# 06-investment-research

**Etablert:** 2026-05-27 av ai-1 etter operator-instruks "ha denne typer analyse av markedet lagret som et minne... vi kommer til å gå dypere for hver gang og du får flere tilganger osv. dette er noe vi kommer til å bygge ut platformen med i framtiden."

**Hva dette er:** dedikert kunnskaps-/runbook-domene for aksje-, ETF- og makro-research. Separat fra Nexus (`01-nexus/`). Brukes når operator ber om investerings-research for seg selv, vennen sin, eller noen andre.

**Hva dette IKKE er:** ikke en del av Nexus trading-firm. Ingen automatisering, ingen execution, ingen kobling til OANDA. Rent research-arbeid.

---

## Struktur

| Mappe | Innhold |
|---|---|
| `_runbooks/` | Hvordan dispatche multi-agent screens (sektor, bear-case, broker-mekanikk, synthesis) |
| `_reference/` | Stabile fakta som ikke endrer seg ofte: Norwegian retail constraints (ASK, skatt, Nordnet), broker capabilities, FX-considerations, ETF-eligibility-regler |
| `sessions/` | Historiske research-sessions med dato. Ikke memory — historikk |

---

## Aktive runbooks

- [[2026-05-27-multi-round-research-pattern]] — kjernemønsteret for hvordan dispatche 15-25 parallelle agenter på en aksje-research-oppgave. 4-runde-modell med operator-pivot.

## Aktive referanse-dokumenter

- [[norwegian-retail-investor-constraints]] — ASK-regler, skatt (37,84%), Nordnet-begrensninger, FX-friction, lot-størrelser
- [[broker-capabilities-comparison]] — Nordnet vs Saxo vs IBKR vs DNB Aksjer for hva som faktisk er tradable
- [[available-research-apis]] — hva som finnes (WebSearch, WebFetch, SEC EDGAR free), hva som mangler (Finnhub, FRED, Bloomberg), prioritert ønskeliste for operator

## Sessions

- [[sessions/2026-05-27-40k-nok-friend]] — første full sweep. Startet med "single stock", pivoterte gjennom quantum + Asia. Genererte 3 forskjellige Messenger-rapporter etterhvert som mandat endret seg.

---

## Framtidig utbygging (operator-uttrykt)

> "vi kommer til å gå dypere for hver gang og du får flere tilganger osv."

Sannsynlige neste steg:
- API-tilganger: Finnhub, FRED, Alpha Vantage (operator sa han skulle prøve å fikse)
- Bloomberg/Refinitiv hvis kostnad rettferdiggjøres
- TradingView Pro (operator har antydet han kan gi tilgang senere)
- Direkte broker-integrasjon (Saxo OpenAPI? IBKR Client Portal?)
- Watchlist + auto-refresh av tidligere picks
- Egen Discord-channel for investment-research-leveranser

---

## Kobling til Nexus

Ingen direkte. Men noen patterns overføres:
- Multi-agent fan-out (samme som Nexus firm-bus)
- Bear-case discipline (samme som strategy-critic-agent)
- Operator-gated execution (operator beslutter alltid hva som flippes/kjøpes)
- ASK-konto-kunnskap kan komme til nytte hvis Nexus skal håndtere norske retail-kunder framtid

---

**Vedlikehold:** når operator gir nye API-tilganger, oppdater `_reference/available-research-apis.md`. Når nye brokere brukes, oppdater `_reference/broker-capabilities-comparison.md`. Når nye runbooks utvikles, lenk fra denne README.
