# Referanse-inventar 2026-06-09 (kode-repoer + PDF)

**Lokasjon:** kode-referanser i `~/code/_refs/` (UTENFOR Nexus-repo + utenfor vault-sync). Bøker/PDF i `~/Obsidian/Brain/14-books/_queue/`.
**Boundary (bindende):** alt er LESE/distiller-referanse for å hjelpe Karri tenke riktig. Integrer ALDRI fremmed kode i Nexus (lisens + arkitektur = Karri/operator-beslutning). pysystemtrade er GPL v3 → å kopiere kode derfra ville tvinge Nexus til GPL. Kun konsept-læring i egne ord.

## Vurdering (operator pastet 6 repoer + 1 PDF)
| Kilde | Verdi for Nexus | Handling |
|---|---|---|
| **pysystemtrade** (Carver) | HØY — kanonisk kode-impl av vol-targeting + forecast-kombinering (akkurat det vi distillerte + sizing-fiksen) | KLONET (GPL=read-only). Distiller sizing-approach i egne ord. |
| **Successful Algorithmic Trading** PDF (Halls-Moore/QuantStart) | MEDIUM — praktisk backtest-metodikk + execution + risk (våre gap) | KØET, distilleres neste syklus |
| skyte/momentum (Clenow stocks-screener) | LAV — stock-momentum-screener (1500 aksjer), Nexus = enkelt-instrument XAU | hoppet over |
| blazecolby/Financial-Machine-Learning | LAV-MED — én persons notater på López de Prado; sekundært til selve boka (anbefalt) | hoppet over (skaff boka) |
| Tikam02/TechnicalAnalysis | LAV — uflokusert TA-grab-bag + bokliste | hoppet over |
| letianzj/QuantResearch | LAV-MED — bred quant-kode + bokliste, lite Nexus-fokusert | hoppet over |
| Upties/decision-analyst-agent | LAV (for Nexus) — generisk beslutnings-agent (EV/Bayes/Kelly), ikke trading-lib | hoppet over (evt. eget generelt verktøy) |

**Konklusjon:** kun pysystemtrade var verdt nedlasting for Nexus (kvalitet > kvantitet, som du sa). Resten er enten feil instrument (aksjer) eller uflokusert. PDF-en distilleres som Carver-boka.

## Oppdatering 2026-06-09 (multi-instrument-fremtid + 2 nye kloner)
Operator: platformen utvides etterhvert utover gull → multi-asset-referanser blir mer relevante NÅ. Firecrawl: ingen abo (WebSearch/WebFetch dekker web).
Klonet (read-only ref, ~/code/_refs/):
- **awesome-systematic-trading** (672K, katalog) — min discovery-index; mine den for nye Nexus/multi-asset-repoer i autonome sykluser.
- **nautilus_trader** (204M, LGPL) — event-drevet backtest **+ live uten kode-endring** = vårt paper-vs-live-fidelity-gap; multi-asset/multi-venue-arkitektur = mal for expansion. Distilleres (fidelity-tilnærming + slippage/fill-modell) i egne ord, advisory.
- pysystemtrade er 878M (tungt) — disk-bevisst: kloner ikke alt, kun det jeg faktisk distillerer.
Re-prioritert for multi-asset (hent on-demand når expansion-arbeid starter): vectorbt (rask multi-asset backtest), Qlib (ML multi-asset). Ikke klonet ennå — katalogen + nautilus dekker behovet nå.
