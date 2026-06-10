# Bok fanget: Advanced Futures Trading Strategies (Robert Carver)

- **Fil:** `~/Obsidian/Brain/14-books/_queue/Advanced+Futures+Trading+Strategies...epub` (25MB, 62 kapitler, gitignored — aldri i repo)
- **Lagt til av operator 2026-06-09** for kunnskaps-mating av Nexus.
- **Boundary (bindende):** dette er en STRATEGI/RISK-bok. Å ingest-e som kunnskap (distill→Brain→RAG) er infra (Claude/ai-2). Å ADOPTERE en strategi herfra inn i Nexus' faktiske trade-regler går gjennom Karri. Boka er et kunnskaps-verktøy, ikke en regel-endring.

## De 30 strategiene (taksonomi)
Buy&hold (1-4, m/ risk-scaling) · Slow/Fast trend following (5-9) · Carry (10-11,15) · Adjusted/Spot/Normalised trend (12-14,17) · Trend+carry regimes/allocation (13,16) · Trend by asset class (18) · Cross-sectional momentum/carry (19-20) · Breakout (21) · Value (22) · Acceleration (23) · Skew (24) · Dynamic optimisation (25) · Fast mean reversion (26-27) · Cross-instrument spreads/triplets (28-29) · Calendar (30).

## Nexus-relevans (hva som er verdt mest)
- Nexus kjører ALLEREDE familier herfra: trend-following, mean-reversion, breakout, vol-expansion. Boka gir testet rammeverk for disse.
- **HØYEST verdi for vårt aktuelle problem:** Carvers **vol-targeting / risk-scaling / posisjons-sizing**-rammeverk er direkte relevant for sizing-/blowup-funnet vårt (04-21: oversizing pga trang SL × %risk uten vol-justering). Carvers tilnærming (size ∝ mål-volatilitet / instrument-vol) er nettopp motgiften. → Karri-relevant for sizing-policy.
- NB: boka er FUTURES (Nexus = XAUUSD spot/CFD på OANDA) — konseptene transfererer, men instrument-spesifikke detaljer (carry/calendar/cross-instrument) er mindre direkte anvendbare.

## Plan for distillering (forslag)
1. **Fokusert høy-verdi NÅ:** distill risk-scaling/vol-targeting + de strategi-familiene Nexus kjører → konsept-noter i Brain (ingen verbatim). Knytt vol-targeting til sizing-proposalen for Karri.
2. **Progressivt:** resten distilleres kapittel-for-kapittel via de autonome 2t-syklusene (DEL B), én om gangen, inn i Brain-RAG.
3. **Automatisert:** @cc/book-ingest-pipelinen (bygget, default-OFF) aktiveres når embedder (Ollama bge-m3) står — da auto-distilleres _queue/.
