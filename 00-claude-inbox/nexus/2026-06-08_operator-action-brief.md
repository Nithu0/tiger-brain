# Operator action brief — alt som venter på Nithu/Karri (2026-06-08)

> Kopi av `ai-assistent/docs/ops/2026-06-08_operator-action-brief.md`. Kilde-of-truth = repo-fila.
> Alt under er operator-gated; ingen flagg flippet av Claude. Hver env-flip er rollback ~30s.
> Proposals i seksjon 1 + 5 er Karri-godkjent, kode på `main`, default-OFF.

## 1. ENV-FLIPS KLARE NÅ (Karri-godkjent, ingen kode) — Railway worker

| Flag | Verdi | Impact | Rollback |
|---|---|---|---|
| `LESSON_INJECTION_ENABLED` | `true` | Injiserer approved lessons i agent-prompts. Trygt nå: 0 approved → ingenting injiseres før manuell/auto-godkjenning. | `=false` |
| `AGENT_LESSONS_ENABLED` | `true` | Master-gate for lessons-loopen. | `=false` |
| `CALIBRATION_MODE` | `SAFE_AUTO_APPLY` | Autotune anvender engine-multipliers. Bundet ≥30 samples + ±20% (PR #68). | `=RECOMMEND_ONLY` |
| `RISK_LEVEL_HARD_GATE_ENABLED` | `true` | Blokkerer [elevated,high,extreme] (~46% cycles). risk_level backfilt (PR #69). | `=false` |
| `SCALP_RISK_PCT` (valgfri) | `1.0` | Scalp-risk eksakt 1.0%. | unset |
| `VOL_EXP_NO_CHASE_ENABLED` | `true` | Chase-filter vol-exp (+$977 backtest @1.0 ATR). Krever `VOL_EXPANSION_ENABLED=true`. | `=false` |
| `VOL_EXP_NO_CHASE_ATR_MULT` | `1.0` | Konservativ terskel (0.5 = mest edge). | `=2.0` |
| `ORB_ENABLED` | `false` | ORB observe-only (0/3 WR). | `=true` |
| `SCALP_OVERLAP_ENABLED` | `false` | Scalp-overlap observe-only (25% WR). | `=true` |

Valgfri: `LESSON_AUTO_PROMOTE_ENABLED=true` — auto proposed→approved @ 20 obs / 0.8 consistency / cap 3 (PR #73, default-OFF).

## 2. RAILWAY WORKER ENV — agent_lessons (operator)
derive-lessons-cron: 0 nye rader siden 2026-05-21 (18 dager). Bekreft på worker:
- [ ] `AGENT_LESSONS_ENABLED=true`
- [ ] `LESSON_DERIVATION_ENABLED=true`
- [ ] `DATABASE_URL` til stede
- [ ] 04:00 UTC cron schedulert + kjører
Verifiser: neste tick skriver success-marker + agent_lessons vokser forbi 3 manuelle rader.

## 3. CONFIRM-VALUES (operator)
- [ ] Circuit-breaker caps `MAX_NOTIONAL_PCT=300` / `MAX_UNITS_PER_TRADE=80` (live PR #61+#67, data-kalibrert 173 trades) — OK eller andre tall?
- [ ] `STRATEGY_BLADE_ENABLED=true` intensjonelt? (NEWS_BLACKOUT-write 2026-06-02 impliserer på.)

## 4. TERSKLER FRA NITHU
- [ ] Autotune auto-apply: bekreft ≥30 samples + ±20% (PR #68) eller egne tall.
- [ ] Lessons auto-promo: bekreft 20/0.8/3 (PR #73) + om `LESSON_AUTO_PROMOTE_ENABLED=true` flippes nå.

## 5. READY-TO-PUSH — venter "OK kjør"
- [ ] `2026-05-29_tf_m1_reversal_confirm` — TF entry-timing fix (−$854 29.5), env-flag, risk none.
- [ ] `2026-06-01_oanda_backfill_blade_attribution` — observability, FVG feilattribuert.
- [ ] `2026-06-01_position_mgmt_oanda_import_attribution` — kritisk: BE/trail/TP1 hopper over live-import trader. Karri godkjent.

## 6. FOUNDATION GATE — GUL
`reddit_posts` stale siden 2026-05-27 → blokkerer NYE strategier (regel 4). Påvirker ikke seksjon 1/5.
