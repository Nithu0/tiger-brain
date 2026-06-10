# Norwegian retail investor — constraints reference

**Sist verifisert:** 2026-05-27
**Kilde:** Skatteetaten, Nordnet support, Norges Bank, agent-research

---

## Aksjesparekonto (ASK) — kritisk for skatt

**Hva:** Norsk skattemekanisme. Utsetter skatt på gevinst inntil uttak overstiger innskudd. Effektiv 0% skatt mens posisjon holdes innenfor.

**Skattesats 2026:** 22% × 1,72 oppjustering = **37,84% effektiv** på realisert gevinst (samme for utbytte).

**Hva som er ASK-eligible (binding):**

| Børs / domisil | ASK-eligible? |
|---|---|
| Oslo Børs (NO) | ✅ JA |
| EU/EØS-børs (Sverige, Tyskland, Frankrike, NL, Finland, etc.) | ✅ JA |
| UK (post-Brexit, IKKE EØS) | ❌ NEI — løpende 37,84% skatt |
| US (NYSE, Nasdaq, OTC ADRs) | ❌ NEI |
| Sveits (IKKE EØS) | ❌ NEI |
| Canada, Japan, Korea, Taiwan, HK, Singapore, Sydney | ❌ NEI |
| UCITS ETF (Irland/Luxembourg-domisilert) | ✅ JA |
| Non-UCITS ETF (US-domisilert, f.eks. QTUM, SPY direct) | ❌ NEI |

**Konsekvens for research:**
- Default bias mot EØS-listede + UCITS ETF
- US-aksjer kan anbefales hvis edge er stor nok til å absorbere 37,84% skatte-drag
- Asia-aksjer = automatisk skatte-drag (ingen ASK)

---

## Valuta / FX-konsekvenser (per 2026-05-27)

**Spot:**
- USD/NOK: 9,27 (NOK +9% mot USD siste 12 mnd)
- EUR/NOK: ~11,5 (relativt stabil)
- DKK/NOK: ~1,55 (DKK pegget til EUR — minimal NOK-risiko)
- SEK/NOK: ~1,02 (begge nordiske, korrelert)

**Historisk:**
- USD/NOK 12-mnd vol: 8-15% typisk
- NOK styrking trend H2 2025 → H1 2026 etter Norges Bank +25bp surprise mai 2026

**Implikasjon:**
- En US-aksje må gå +25-30% i USD for å bli +20% i NOK hvis NOK styrker seg videre
- DKK/EUR/SEK = lavest FX-risiko mot NOK
- Hedge-ETFs finnes men er sjeldent verdt det på <100k NOK

---

## Broker-tilgang (Nordnet Norge — det største retail-meglerhuset)

**Hva Nordnet Norge støtter (verifisert 2026-05-27):**
- ✅ Norge, Sverige, Danmark, Finland
- ✅ Tyskland (Xetra), UK (LSE), Frankrike, Belgia, Nederland, Portugal, Irland, Italia, Sveits, Østerrike
- ✅ USA (NYSE, Nasdaq, AMEX, OTC pinks for ADR-er)
- ✅ Canada (TSX)
- ❌ **INGEN Asia direkte** (verken Tokyo, Hong Kong, Stock Connect, Korea, Taiwan, Singapore, Sydney)

**Asia-eksponering for Nordnet-bruker:**
- Asia-aksjer må kjøpes som **ADR på NYSE** (TSM for TSMC, SSNHZ for Samsung, HXSCL/SKHNY for SK Hynix)
- ELLER **UCITS ETF med Asia-eksponering** (iShares MSCI Japan, Korea, Taiwan-kapped, etc.)
- ELLER bytte til Saxo/IBKR for ekte direkte-tilgang (krever ny konto, 2-3 dagers oppsett)

**Kurtasje + spread (Nordnet 2026):**
- Norske aksjer: ~39-99 NOK per ordre
- Utenlandske aksjer: ~0,15-0,25% av handelsbeløp
- Valuta-veksling: 0,25% auto (0,15% med valutakonto)
- Total roundtrip for 40k NOK trade: ~200-400 NOK = 0,5-1% (trivielt)

---

## Lot-størrelser (kjente fallgruver)

**Tokyo Stock Exchange (TSE):** Standard **100-share lots** for de fleste aksjer. Hvis aksjen koster ¥27 000 (Advantest), én lot = ¥2,7M = ~160 000 NOK = **for stor for 40k NOK**. Sjekk lot-størrelse FØR du foreslår japansk pick. Aksjer som passer 40k:
- ¥3 000-5 000 per aksje = 1 lot rundt 18-30k NOK (Fujitsu, NEC, Renesas)

**Korea (KRX):** Variabelt. Samsung Electronics handles vanligvis i 1-share lots via Nordnet OTC ADR.

**Taiwan (TWSE):** 1000-share lots på TWSE, men ADR (TSM) handles per aksje.

**US, EU:** Per aksje. Ingen lot-constraint.

---

## Kildeskatt på utbytte (Norsk skatte-treaty)

| Land | Withholding (etter treaty) |
|---|---|
| USA | 15% |
| Storbritannia | 0% |
| Sverige | 15% |
| Tyskland | 15% |
| Frankrike | 15% |
| Danmark | 15% |
| Sveits | 15% |
| Japan | 15,315% |
| Korea | 15% |
| Taiwan | 21% (ingen treaty) |
| Hong Kong | 0% |
| Kina | 10% |

Nordnet bistår vanligvis med treaty-rate via W-8BEN. Manglende treaty (Taiwan) = full lokal sats.

---

## Vanlige rebalansering / re-verifisering

Denne fila må re-verifiseres når:
- Skatteetaten endrer ASK-regler eller skattesats (årlig sjekk, statsbudsjettet okt)
- Nordnet utvider/endrer markeds-tilbud (sjekk pressemeldinger kvartalsvis)
- NOK svinger >15% mot USD/EUR (FX-tabellen blir stale)
- Norges Bank skifter rente-bane vesentlig

Sist verifisert: 2026-05-27 av ai-1 via 21+ subagent-research + Nordnet support-sider.
