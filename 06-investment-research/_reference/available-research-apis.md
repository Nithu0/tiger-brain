# Available research APIs + tools

**Sist oppdatert:** 2026-05-27
**Eier:** operator (han fikser tilganger). ai-1 holder denne fila i sync.

---

## Hva ai-1 har akkurat nå

| Tool | Status | Bruk |
|---|---|---|
| **WebSearch** | ✅ Aktiv | Live data etter knowledge-cutoff (jan 2026). Tvunget å bruke for alt etter den datoen. |
| **WebFetch** | ✅ Aktiv | Henter spesifikke URL-er — Yahoo Finance, TradingView public pages, justETF, OpenInsider, SEC EDGAR, Nordnet support pages. |
| **SEC EDGAR** | ✅ Fritt (via WebFetch) | Form 4 (insider), 10-K/10-Q (fundamentals), 13F (institusjoner). Ingen API-key. |
| **Yahoo Finance** | ✅ Fritt (via WebFetch) | Live priser, analyst targets, kort fundamentals. Begrenset historikk. |
| **TradingView (public)** | ✅ Fritt (via WebFetch) | Daglige charts + ofte teknisk-indikator-tabell. Begrenset uten Pro-konto. |
| **OpenInsider** | ✅ Fritt | Insider Form 4-aktivitet for US-listede selskaper. |
| **justETF** | ✅ Fritt | ETF holdings, AUM, TER, ISIN. God for UCITS-screening. |
| **Stockanalysis.com, GuruFocus, MarketBeat, TipRanks** | ✅ Fritt (med begrensninger) | Forward P/E, analyst-consensus, PT-revisjoner. |
| **Nordnet support pages** | ✅ Fritt | Hva som er tradable, kurtasje, valuta-spread. |
| **Skatteetaten** | ✅ Fritt | ASK-regler, skattesatser, treaty-rates. |

---

## Hva operator har autorisert men ai-1 ikke har nøkkel for

**Operator sa 2026-05-27: "kjør på med finnhub du har fred og".**

Status: Verken `FINNHUB_API_KEY` eller `FRED_API_KEY` er satt i shell eller `.env.local`. Operator må enten:
1. Paste nøklene i en sesjon
2. Sette `export FINNHUB_API_KEY=...` i sin bashrc
3. Legge dem i `.env.local` for ai-assistent-prosjektet (selv om Nexus-bruk er primær)

**Hva som ville blitt mulig med Finnhub:**
- Sanntids-priser (ingen 15-min delay som Yahoo)
- EPS estimates + revisjons-historikk
- Insider Form 4 i strukturert format
- Earnings calendar
- Recommendation trends
- Free tier: 60 calls/min, dekker en research-sesjon greit

**Hva som ville blitt mulig med FRED:**
- Makro-data direkte (rente, CPI, GDP, M2, yield curve, unemployment)
- Bedre enn å WebSearche etter Atlanta Fed GDPNow hver gang
- Free tier: rikelig

---

## Hva operator har lovet kommer (uten ETA)

> "bruk tradingview kan gi deg tilgang til bloomberg senere"

| Tool | Forventet | Verdi når tilgjengelig |
|---|---|---|
| **TradingView Pro / Premium** | TBD | Real-time API, alle indikatorer scrappable, intraday-data, alerts |
| **Bloomberg Terminal** | "senere" | Sanntids alt, news-feed, earnings whisper, options-chain, analyst-consensus i one-place. Dyrt — ~$25k/år. |

---

## Hva ai-1 IKKE har men kunne brukt godt

| Tool | Hvorfor det er ønskelig | Kostnad |
|---|---|---|
| Alpha Vantage / Polygon / Tiingo | Strukturerte historiske priser, OHLCV, fundamentals | Gratis tier 5/min eller $50-100/mnd Pro |
| Refinitiv (LSEG) | Bloomberg-konkurrent, sanntids alt | $20k+/år |
| Koyfin | Quant-screen, fundamentals, watchlist | $50-200/mnd |
| Stockanalysis.com Pro | Bedre screen-verktøy enn gratis-versjonen | ~$200/år |
| ClickUp (har MCP-tilgang) | Kunne tracke watchlist + entries + exits over tid | Allerede tilgjengelig — bruk hvis operator vil ha tracking |
| Saxo Bank API / IBKR Client Portal | Ekte broker-mekanikk — sjekke om en pick er tradable for operator | Krever broker-konto |

---

## Eksplisitt IKKE for denne folderen

- Nexus trading-firm sin nexus-pg / nexus-pg-rw MCP — ren Nexus, ingen overlapp
- n8n MCP — Nexus-orchestration
- Discord Karri webhook — kan brukes for showcase men ikke for å skyte ut konkrete picks (ikke hans rolle)

---

## Update-rytme

Når operator gir ny tilgang → oppdater denne fila + minne-pointer (`reference_investment_research_capability.md` i auto-memory). Når et nytt tool brukes for første gang i en research-sesjon, dokumenter learnings.
