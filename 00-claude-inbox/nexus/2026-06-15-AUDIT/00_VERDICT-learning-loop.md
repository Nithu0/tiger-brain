# Nexus læringsloop — konsolidert revisjonsdom (2026-06-15)

> **STATUS-OPPDATERING 2026-06-15:** Foundation bygd på branch `infra/learning-loop-foundation` (15 commits, 1427/1427 worker grønt, alt default-OFF). Tasks 1-7 i 7-dagersplanen levert i én ultracode-økt: lineage-join, strategy_versions, hypotheses+strukturert derive, verifikasjons-arm, meta-label firma-filter, management-skip-tripwire, backup-script. Venter operator OK-kjør for push. Gjenstår: backtest-kjerne (ai-2), backtest-gate-wiring, autotune no-op-fix (Karri-gate), operator-provisjonering (backup-bøtte) + DB-repair (historiske u-attribuerte rader).



10-agent evidens-revisjon. DB var nåbar → rad-tall er ekte, ikke antatt.
Live build på revisjonstidspunkt: `01912d60`.

---

## 1. HOVEDDOM

**Systemet KJØRER og MÅLER. Det LÆRER ikke.**

Loopens første halvdel er ekte wired og live:
`market data → signal → paper trade → result logging → evaluation` — alt fungerer, skriver til DB, oppdateres i dag.

Loopens andre halvdel er død/stubbet/av:
`hypothesis → backtest → strategy version → comparison → task → implementation → verification` — ingen av disse lenkene bærer last.

Konsekvensen: systemet kan **observere** at det taper, men kan ikke **endre seg målt og bekrefte at endringen hjalp**. Operatørens frykt ("den lærer ved at agentene tenker mer, ikke ved målt feedback") er **bekreftet og korrekt**. Den ene ekte statistiske feedback-motoren (calibration) skriver til en logg ingenting leser tilbake; den eneste kode-komplette auto-loopen er input-sultet av ORB_ONLY_MODE; lekser blir tekst i LLM-prompter uten måling av om de hjalp; en verifikasjons-arm finnes ikke.

Karakter: **5/13 lenker wired, 4 partial, 4 døde.** Et system med halve loopen i drift lærer ikke — det samler bevis det ikke kan handle på.

---

## 2. ARKITEKTURSTATUS (lenke-for-lenke, med bevis)

| # | Lenke | Dom | Bevis |
|---|---|---|---|
| 1 | data → signal | WIRED | ohlcv_candles 15min fresh (3472 rader), shadow_signals 478 (fired+blocked) |
| 2 | signal → paper trade | WIRED | simulated_orders, OANDA practice |
| 3 | trade → result logging | WIRED-men-WEAK | 209 trades, pnl/close 100% — men result_r 64% NULL, regime 90% NULL, atr 88% NULL |
| 4 | result → evaluation | WIRED | postmortems 1185, engine_scores 26k, analytics-endepunkter live |
| 5 | evaluation → hypothesis | PARTIAL/OFF | derive-lessons leser rå WR-clusters, IKKE postmortem-output; default-OFF; 0 approved |
| 6 | hypothesis → backtest | DEAD | lekser promoteres på sample-size alene; backtest er kun manuell HTTP, ORB-only |
| 7 | backtest → version | DEAD | ingen strategy_version-objekt eksisterer |
| 8 | version → comparison | DEAD | ingenting å sammenligne; `version`-kolonne frosset på 1 for alle 8 strategier |
| 9 | comparison → live | DEAD/manuell | endringer skipper via env-flag-flip; lekser injiseres utestet |
| 10 | evaluation → daily report | PARTIAL | daily-journal + operator-brief gir narrativ + 3 oppgaver (ekte), men ikke køede tasks |
| 11 | report → agent tasks | PARTIAL/OFF | agent_tasks-generator finnes (471 rader!) men default-OFF + ai-1/ai-2 jobber fra markdown, ikke køen |
| 12 | task → implementation | PARTIAL/OFF | eneste ekte kodesti ender i åpen PR (aldri auto-merge, by design) |
| 13 | implementation → verification | DEAD | ingenting re-måler om en endring hjalp neste syklus |
| 14 | (skjult) calibration → live thresholds | DEAD | 158 "applied" calibration_log-rader; `getActiveProfile()` er en stub som returnerer hardkodet baseline — autotune justerer og glemmer |

---

## 3. KRITISKE HULL (rangert etter hva som blokkerer læring mest)

1. **Strategi-versjonering finnes ikke (keystone).** Ingen `strategy_versions`-tabell. Params er env-vars overskrevet på stedet uten historikk. `version`-kolonnen er frosset på 1. Kan ikke svare "slo v2 v1?". Uten dette er HELE andre halvdel av loopen umulig.

2. **Autotune er en strukturell no-op.** Den ene auto-loopen som finnes muterer `engine_multipliers:current` og skriver 158 "applied"-rader — men `getActiveProfile()` leser dem aldri tilbake (eksplisitt stub: "When SAFE_AUTO_APPLY is active, this WOULD query..."). Den justerer og glemmer. Vi TROR vi har autotune; vi har ikke.

3. **Evaluerings-data er statistisk meningsløst per strategi.** result_r NULL på flertallet, regime/atr/session ~85-90% NULL, n per strategi 5-44, **41% av trades er u-attribuerbare (~$8.5k tap uten strateginavn)**. Selv den wired evalueringen kan ikke konkludere. Garbage-in.

4. **"Hypoteser" er ikke hypoteser.** derive-lessons gir 2-verdi loss-clusters (reject/favor) + template-tekst. Ingen foreslått endring, forventet effekt, testmetode, suksesskriterium, rollback. Ingen `hypotheses`-tabell. Mater kun prompt-injeksjon → akkurat "lær ved å tenke mer".

5. **Ingen backtest-gate før endringer.** Backtest er ORB-only, re-implementerer live-logikk (ikke delt kode → resultater forutsier ikke live), kun manuell HTTP. Hypoteser blir aldri testet før de shipper.

6. **Ingen verifikasjons-arm.** Når en endring shipper, re-måler ingenting om den faktisk forbedret metrikker. Fire-and-forget. Loopen lukker aldri.

7. **Ingen DB-backup.** Den uerstattelige ressursen (alle trading-data) har null backup/pg_dump/PITR i repo+docs. Eksistensiell infra-risiko — ett uhell og 2 måneders kalibreringsdata er borte.

8. **Brutt cycle-id-join.** shadow_signals.cycle_id → market_snapshots = 0 treff (verifisert live). Orchestrator minter to UUID-rom. Signal kan ikke kobles til markedstilstand uten skjør timestamp-nærhet.

9. **Skjøre in-process crons.** Alle jobber er setInterval anker til boot, dør ved restart, ingen catch-up. 04:00 derive er stille hoppbar (17-dagers crash-presedens). Kun derive er overvåket; ~6 andre jobber er blindsoner.

10. **Task-generator frakoblet.** agent_tasks genererer 471 datadrevne rader — men ai-1/ai-2 jobber fra håndkuratert markdown (inbox/feed/KARRI-DISPATCH), ikke køen. En generert task ble aldri en kode-endring.

---

## 4. GPU/PC-DOM

**Ikke kjøp GPU eller PC. Det løser ingenting av det ovenfor.** Hvert eneste kritiske hull er data-disiplin, schema og loop-wiring — ikke regnekraft. Systemet kjører allerede 24/7 på Railway uten ressursproblem. GPU blir først relevant HVIS vi senere trener egne ML-modeller på et RENT, attribuert, versjonert datasett — og vi har ikke det datasettet ennå. Å kjøpe GPU nå er å kjøpe en racerbil før vi har lagt asfalt. Bygg loopen først; vurder GPU tidligst etter at strategy_versions + ren attribusjon har kjørt i måneder.

---

## 5. MINIMUM LÆRINGSLOOP — hva MÅ finnes

Operatørens 9 påkrevde tabeller, mot virkeligheten:

| Påkrevd | Status nå | Tiltak |
|---|---|---|
| market_data | ✅ ohlcv_candles + market_snapshots | behold; fiks cycle-id-join |
| signals | ✅ shadow_signals (fired+blocked, m/ utfall) | behold; konsolider de 3 parallelle signal-lagrene |
| paper_trades | ⚠️ simulated_orders finnes men metadata NULL | fyll result_r/regime/atr/session ved skriving |
| strategy_versions | ❌ MANGLER | **BYGG — keystone** |
| evaluations | ⚠️ spredt, motstridende formler, ingen per-versjon | konsolider til én scorecard per (strategi,versjon) |
| hypotheses | ❌ MANGLER (lever som agent_lessons free-text) | **BYGG strukturert tabell** |
| backtest_results | ⚠️ `backtests` finnes, ORB-only, re-impl | del kjerne live==backtest; per-strategi dispatch |
| agent_tasks | ✅ finnes (471 rader) men frakoblet + mangler felt | legg til acceptance/test/rollback; koble drainer |
| daily_reports | ⚠️ lever i agent_artifacts (journal/brief) | gi egen tabell + signal/strategi-tellinger |

---

## 6. FØRSTE 10 KONKRETE TASKS (datadrevet, akseptanskriterier)

Eierskap-skille (bindende): **læringsinfra = Claude (jeg bygger fritt). Trade-alterende logikk = Karri-gate.** Alle 10 under er INFRA — de måler/lagrer/tester, de endrer ikke en eneste trade-beslutning. Derfor kan de bygges autonomt.

1. **Backup først (infra, eksistensielt).** Daglig pg_dump av Nexus-Postgres til objektlager + dokumentert restore-test. Accept: én vellykket restore til scratch-DB bevist. Rollback: trivielt (les-only jobb).

2. **Fyll trade-metadata ved skriving.** Skriv result_r, regime_at_entry, atr_at_entry, session på ALLE simulated_orders-rader i begge eksekverings-stier (ikke bare firm_strategy-stien). Accept: nye trades har <5% NULL på disse feltene over 48t. Test: SELECT NULL-rate siste 48t.

3. **Reparer historiske u-attribuerte rader (operatør-gated SQL).** De 11 OANDA_EXTERNAL + relevante OANDA_BACKFILL der blade_match finnes. Accept: u-attribuerbar andel faller fra 41% mot <15%. (Krever nexus-pg-rw — kjøres med din OK.)

4. **`strategy_versions`-tabell (keystone).** Append-only: (strategy, version, params_json, created_at, retired_at, performance_json). Stamp hver trade med strategy_version. Accept: en param-endring skaper ny rad + gamle trades beholder sin versjon. Ingen atferdsendring — kun journalføring.

5. **Koble autotune til live (fiks no-op).** Implementer `getActiveProfile()` til faktisk å lese siste applied calibration-rad. Accept: en applied-rad endrer en lest terskel, bevist i logg. **NB: dette ER trade-alterende → Karri-gate før aktivering; jeg bygger lese-stien default-OFF.**

6. **`hypotheses`-tabell + strukturert derive-output.** Hver hypotese: problem, støttende data (SQL), foreslått endring, forventet effekt, testmetode, suksesskriterium, rollback. derive-lessons skriver hit i stedet for 2-verdi clusters. Accept: neste 04:00-kjøring produserer ≥1 full-felts hypotese.

7. **Delt backtest-kjerne (live == backtest).** Trekk ut strategi-logikken til en ren funksjon brukt av BÅDE live og backtest; dispatch på strategy_name (ikke ORB-only). Accept: backtest av en strategi over periode X reproduserer live-signalene for samme periode innen toleranse.

8. **Backtest-gate proposed→approved.** En hypotese kan ikke promoteres uten en backtest-kjøring som møter suksesskriteriet. Accept: en hypotese uten bestått backtest forblir `proposed`.

9. **Fiks cycle-id-join.** Én cycle-id delt mellom shadow_signals/gate_decisions/market_snapshots. Accept: signal→markedstilstand-join gir >95% treff.

10. **Verifikasjons-arm.** Hver implementert endring får parent_task_id + en før/etter-metrikk-sjekk N sykluser senere. Accept: en landet endring genererer automatisk en "hjalp/hjalp-ikke"-rad. Lukker loopen.

---

## 7. HVA DU IKKE SKAL BRUKE TID/PENGER PÅ NÅ

- **GPU/PC** — løser ingenting av hullene (se §4).
- **Nye strategimoduler / flere bok→AI-agenter** — du har 8 strategier du ikke kan evaluere ennå. Flere strategier = mer u-målbar støy.
- **Flere LLM-agenter som "tenker"** — selve anti-mønsteret. Loopen mangler måling, ikke tenkning.
- **Aktivere flere money-near flagg** — før attribusjon + versjonering er på plass er enhver aktivering blind.
- **Live kapital** — paper-loggingen er ikke solid nok (metadata-NULL). Ikke i nærheten.
- **Rydde 217 env-vars akkurat nå** — verdifullt men ikke blokkerende; gjør det etter §1-2.

---

## 8. 7-DAGERS PLAN (fra "stagnerer" til "måler og forbedrer seg")

- **Dag 1 — Stopp blødningen av data-integritet.** Task 1 (backup) + Task 2 (metadata ved skriving). Uten disse to er alt annet bygd på sand.
- **Dag 2 — Rens fundamentet.** Task 3 (reparer historiske rader, din OK på SQL) + Task 9 (cycle-id-join). Nå er datasettet attribuert og koblet.
- **Dag 3 — Keystone.** Task 4 (strategy_versions + trade-stamping). Nå finnes det versjoner å sammenligne.
- **Dag 4 — Ekte hypoteser.** Task 6 (hypotheses-tabell + strukturert derive). Nå produserer systemet testbare påstander, ikke prompt-tekst.
- **Dag 5 — Ekte backtest.** Task 7 (delt kjerne, per-strategi). Nå kan en hypotese faktisk testes.
- **Dag 6 — Lukk gaten.** Task 8 (backtest-gate proposed→approved) + Task 5 lese-sti (autotune no-op fix, default-OFF, Karri-gate for aktivering).
- **Dag 7 — Lukk loopen.** Task 10 (verifikasjons-arm). Nå: hypotese → backtest → versjon → live → re-måling → ny hypotese. Loopen lukker.

Etter dag 7: systemet kan for første gang si, med tall, "denne endringen gjorde strategien bedre/dårligere" — og forkaste det som ikke slår forrige versjon. Det er forskjellen på en bot og en læringsmotor.

---

## Detaljrapporter
01_market-data-signals · 02_paper-trade-logging · 03_evaluation-metrics · 04_strategy-versioning · 05_hypothesis-generation · 06_backtesting · 07_daily-report · 08_agent-task-generation · 09_railway-ops · 10_loop-closure
