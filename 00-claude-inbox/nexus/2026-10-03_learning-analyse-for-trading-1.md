# Learning-analyse for trading-1 (report-only) — 2026-10-03

Fra: learning-1. Bestilt av operatør: "ta learning-analyse-verktøyene og hjelp trading-1".
Ingen kodeendring, ingen push, ingen DB-skriving. Trading er på pause siden 2026-09-21.

## Datavei og kilder

- `command-center/_bin/pull-nexus-data.sh` finnes IKKE på disk (sjekket `ls command-center/_bin`, 13:3xZ). Brukte samme mønster som `~/.nexus-ops/nexus-watch.sh`: curl over 443 mot `https://api-production-b660.up.railway.app`, Bearer-token hentet via `railway variables --service API --kv` (API_KEY PRESENT, verdi ikke printet).
- Alle endepunkter under svarte 200, hentet 2026-10-03T13:37:47Z–13:42:51Z: `/health`, `/trade-forensics/summary`, `/trade-forensics/trades?verdict=<V>&limit=200` (alle 6 verdikter, sum 322 = summary.total), `/trade-forensics/summaries`, `/meta-label/eval`, `/meta-label/scores?limit=50`, `/calibration`, `/calibration/status`, `/learning/loop-status`, `/learning/loop-state`, `/firehose/overview`, `/firehose/derive-status`, `/operator/lessons`, `/analytics/performance`.
- Deployet build: `577e14b3` (`/health`.build) = origin/main etter fetch (2026-08-22, PR #323).
- "Firm" nedenfor = trade_id matcher UUID og `excluded_from_learning` ikke true (samme predikat som `learningFilterSql`). Beregnet lokalt i python på JSON-dumpene.

**Ikke kjørt:** `derive-lessons.mjs` dry-run. Scriptet har `LESSON_DERIVATION_DRY_RUN=true` (side-effektfritt i dry-run), men krever `DATABASE_URL` mot prod-PG, og egress er kun 443. Leste i stedet output-tabellene via API. GPU-boksen (:11691) ikke spurt (trainer-status = UNKNOWN).

## 1. Feilkilde-bildet (trade_forensics)

All-time, 322 rader (`/trade-forensics/summary`, 13:37Z):

| Verdikt | n | lost_r |
|---|---|---|
| EXEC_ARTEFAKT | 170 | -5.18 |
| SCRATCH | 54 | -1.42 (10 mgmt_flag) |
| RETNINGSFEIL | 46 | -43.14 |
| GOD_TRADE | 34 | 0 |
| TIMINGFEIL | 11 | -10.51 |
| TIMING_SVAK | 7 | -7.16 |

EXEC_ARTEFAKT er 161 `kvarantene` (82 oanda_backfill + 79 andre karantenesatte), 6 `fortegnsmismatch`, 3 `manuell_close` (verdict-filtrert pull, 13:40Z). Altså nesten bare karantene/import, ikke broker-feil.

Firm-only (n=161, samme pull): netto -21.63R. Tapt R fra ekte tap (RETNING+TIMING+SVAK) = -60.81R:
- **Retning: -43.14R = 71 %.** Median MFE for RETNINGSFEIL = 0.00R (n=36 med MFE). Post-move 6h: 24 av 39 sto ≤ -1R mot oss, bare 1 ≥ +1R. Prisen gikk faktisk feil vei — ikke for trang stop.
- **Timing: -17.67R = 29 %** (TIMINGFEIL -10.51 + TIMING_SVAK -7.16). 4 av 7 TIMING_SVAK er `proxy_mangler` (verken MFE eller post-move) — svakeste data.
- **Management: liten.** 10 mgmt_flag, alle på SCRATCH; hele SCRATCH-bøtta koster -1.42R. Ingen `STALE_TRADE_EXIT`-med-MFE≥1-flagg.
- **Exec-artefakt (firm): 9 trades** (6 fortegnsmismatch + 3 manuell close). Ikke en tapskilde av betydning.
- Close-reason på RETNINGSFEIL: 39 `OANDA_SL_TP`, 3 `CONVICTION_FLIP_EXIT`, 1 `STALE_TRADE_EXIT`.
- Per strategi (firm, negativ R): mean-reversion -19.77 (retning -12.52), volatility-expansion -19.44 (retning -12.70), session-breakout -6.33, fvg -5.13, resten ≤ -3R hver.

Vinduer (firm, closed_at):
- 01.07–21.08: n=50 → 14 RETNING (-12.74R), 3 TIMINGFEIL (-3.09R), 21 SCRATCH, 12 GOD.
- siden 21.08: n=26 → 7 RETNING (-6.07R), 5 TIMING_SVAK (-5.16R), 10 SCRATCH, 4 GOD.
- siste 30d (≥03.09): n=7 → 4 RETNING (-3.06R), 3 SCRATCH.

Konklusjon: problemet sitter i entry-retning, ikke i exit/management eller broker. Det er en strategi-observasjon; alt som skal brukes til å endre entries må gjennom Karri-proposal.

Merk: trade `58d82c2e` (breakout-continuation) åpnet 2026-10-02T01:51Z, lukket 04:15Z, -1.00R — demo-trading kjører altså fortsatt etter pause-datoen (forventet om pausen kun gjelder utvikling; bekreft).

## 2. Har læring påvirket trades?

- **Kalibrering: ja, men bare 2026-06-08 → 06-19.** `CALIBRATION_MODE=SAFE_AUTO_APPLY` ga 329 applied `calibration_log`-rader, revertert til RECOMMEND_ONLY 06-20 (kilde: `docs/ops/operator-decisions.md` linje 38, origin/main). Nå: `calibrationMode=RECOMMEND_ONLY`, `autoApplyActive=false`, alle 7 engine-multipliers = 1 (`/calibration/status`, 13:37Z). Siste anbefalinger er no-ops (old=new=1, samples=1). Rettelse til min 14.08-melding: applied=0 gjelder fra 06-20, ikke 26.06.
- **Lessons: nei (nå).** 0 approved, 6 proposed, 11 archived (`/firehose/overview`). `injectionFlagEnabled=false` — men det er API-prosessens env; worker-env er ikke lesbar fra API (caveat i `/learning/loop-state`). Om noen av de 11 arkiverte noen gang var approved og injisert: UNKNOWN.
- **Meta-label: nei.** Kun shadow (`scoreShadowCandidate` i orchestrator, skriver til `meta_label_scores`). Ingen gate leser p_win.
- **Hypoteser/backtest/change-verification: nei.** hypotheses total=0, backtests uten koblet hypotese, change-verification BUILT men ikke wired (`/learning/loop-status`, `/learning/loop-state`).

Dvs. ingen læringsmekanisme har endret en trade siden 2026-06-20.

## 3. Hva som er gammelt eller ødelagt i lærings-pipelinen

1. **derive-lessons kjører, men produserer ingenting.** Kjører daglig 04:07Z, ingen feil, men `starved=true` hver dag: 03.10 7 trades → 7 clusters, største n=1; 01.10 10 → 10, n=1 (`/firehose/derive-status`). Grupperingen (regime × session × tid × close_reason) er finere enn trade-volumet, så min_sample=5 nås aldri. Siste lesson-aktivitet: 2026-07-23 (`/learning/loop-state`).
2. **De 6 gjenværende proposed lessons er fra 9.–18. juni og har feil telling.** F.eks. #19 "60 % WR over 5 trades" men `sample_size=2` (bug med telling av kjøringer i stedet for trades, fikset 07-11, gamle rader aldri talt på nytt). Flere har "unknown session". Bør arkiveres/re-telles (DB-skriving, operatør-gated).
3. **hypotheses-tabellen er tom** (0 rader). Hele hypotese → backtest → change-verification-kjeden har aldri fått input.
4. **derive-lessons leser IKKE trade_forensics.** `git grep forensic` i scriptet på origin/main gir null treff. Det jeg lovet 14.08 er ikke levert.
5. **Feil på bussen: derive-lessons er ikke "rene SQL-selects".** Det skriver `agent_lessons`, `hypotheses`, `firm_state` og kaller `autoPromoteEligibleLessons` (proposed→approved; trade-påvirkende når `LESSON_AUTO_PROMOTE_ENABLED=true`, default av). Worker-verdien av det flagget: UNKNOWN.
6. **Meta-label er ikke brukbar.** Eval: n=158, brier 0.257 mot baseline 0.225 (skill -0.142), ECE 0.120, verdict `no-signal` (`/meta-label/eval`; eval-tidspunkt er ikke med i responsen = UNKNOWN). Scorer brukte samme modell `mlm_20260818055711` helt til siste score 2026-09-20T22:13Z. Svært lav oppløsning: 3 trades fikk p_win=0.68851, 5 fikk 0.54485 (`/meta-label/scores`). Trade 58d82c2e (02.10) er ikke scoret. Hvorfor vet jeg ikke (flagg av? annen kandidatsti?). Trainer-status etter 18.08: UNKNOWN.
7. **GPU-berikelse av forensics står stille siden 2026-08-24** (61/322 gpu-enriched, siste updated_at 08-24T15:50Z). Den deterministiske klassifiseringen går fortsatt (siste rad opprettet 10-02T04:37Z).
8. **/trade-forensics/summaries cursor-bug er bekreftet** (data-1 21.09): cursor `2026-10-02T04:37:18.537Z / 58d82c2e-…` returnerer den samme raden igjen med samme next-cursor (13:42Z). Ufarlig, men ingest-klienten går i loop til stall-vakten slår inn.
9. **nexus-watch er blind på kalibrering:** henter `/operator/calibration-status` → 404 (13:42Z). Riktig rute er `/calibration/status`.

## 4. Neste steg som passer pausen

Fritt (observability/capture, endrer ikke trade-beslutninger):
- a. **Forensics inn i derive-lessons som evidens (min lane):** grov gruppering `strategy × verdikt` fra `trade_forensics` (f.eks. "mean-reversion: 13 RETNINGSFEIL, -12.5R"), skrevet kun som proposed lessons/hypoteser (inerte). Det løser starvation, siden grovere klynger når n≥5. Forutsetning: bekreft at `LESSON_AUTO_PROMOTE_ENABLED` er av på worker (operatør, Railway).
- b. **Cursor-fix i /summaries** (trading-1s lane): `date_trunc('milliseconds', updated_at)` i både compare og ORDER BY. Ren bugfix.
- c. **Undersøk GPU-berikelsesstoppen fra 24.08** (deep-modell-timeout/eviction? jf. infra-1 14.08).
- d. **nexus-watch:** bytt `/operator/calibration-status` → `/calibration/status`.
- e. **Rydd de 6 juni-lessons** (arkivér eller tell på nytt). Opprydding er lov etter prinsipp 3, men DB-write = operatørens OK.
- f. **Meta-label:** behold shadow. Sjekk hvorfor 02.10-traden ikke ble scoret, og sjekk trainer-status på GPU-boksen.

Krever Karri-proposal (endrer trade-beslutninger): alt som bruker retningsfunnet til å filtrere eller strupe entries (mean-reversion, volatility-expansion), lesson-injeksjon eller auto-promote PÅ, SAFE_AUTO_APPLY tilbake, og meta-label som gate.

## UNKNOWN-liste
derive-lessons dry-run (ingen DB-vei over 443) · worker-env for LESSON_INJECTION/AUTO_PROMOTE/META_LABEL_SHADOW · om arkiverte lessons noen gang ble injisert · meta-label eval-tidspunkt og trainer-status etter 18.08 · hvorfor 02.10-traden mangler shadow-score.
