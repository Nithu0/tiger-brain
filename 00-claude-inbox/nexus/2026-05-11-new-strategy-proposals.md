# 3 nye strategy proposals filed + auto-sendt til Karri

**Dato:** 2026-05-11 (14:21 CEST, innenfor work-hours auto-send)
**Commit:** `d47ef7a`
**Reviewer:** Karri
**Status:** alle 3 = proposed (awaiting Karri)

## Hva ble valgt

Av operator's 5 forslagskandidater valgte jeg disse 3 fordi de komplementerer hverandre:

1. **#1 Vol-expansion proposal-throttle review** — 11% conversion er det skarpeste tall-signalet i audit-en.
2. **#4 Postmortem-driven size-down feedback loop** — bleed-feedback (taper-siden), bygger på 16/16 RIGHT_THESIS-tagging.
3. **#5 Conviction-quartile position-sizing** — sizing-amplifier (vinner-siden), naturlig next-step etter metadata-fix.

**Forkastet (denne runden):**
- #2 ORB session-window (7 signals / 30d er for tynt grunnlag for en separat proposal — kan rulles inn under et eventuelt #1-resultat).
- #3 Scalp-overlap entry-threshold (5 signals / 30d, samme tynne-grunnlag-problem; for konservativ-spørsmålet kan vente til Karri har sett funnel-data).

## Filed proposals

| Slug | TL;DR |
|---|---|
| `2026-05-11_vol_expansion_throttle_review.md` | 11% conv + 100% win-rate motstridende → instrumenter rejection_reason (5 stages) i 14d før vi rør floor. Ingen threshold-endring nå. |
| `2026-05-11_postmortem_size_down_feedback.md` | Auto-tag eksisterer men konsumeres ikke. 3-fase: streak-tabell → shadow-mode (log-only) → live scale-down 0.5x ved streak≥2 RIGHT_THESIS. Reset på 1 WIN / 24h. |
| `2026-05-11_conviction_quartile_position_sizing.md` | entry_conviction_score nå stamped (post-fix). Pre-commitment: 30d observasjon → per-strategi quartile-kalibrering → `{Q1:0.5, Q2:0.75, Q3:1.0, Q4:1.25}` multiplier bak env-flag. |

## Discord-sends (auto-send per `feedback_auto_send_karri.md`)

| Proposal | Color | HTTP |
|---|---|---|
| Vol-expansion (msg #1, med greeting + batch-context) | 3447003 blue | 204 |
| Postmortem feedback (msg #2, continuation) | 16776960 yellow | 204 |
| Conviction-sizing (msg #3, med queue-count footer) | 3066993 green | 204 |

Alle 8 binding-seksjoner per embed: Hva data viser, Root cause, Forslag, Alternativer forkastet, Strategisk vurdering, Spørsmål til deg, Rollback, Full doc-link.

## Karri's open queue (nå)

| # | Dato | Title | Status |
|---|---|---|---|
| 1 | 2026-05-08 | Lower BREAK_EVEN_TRIGGER_R 1.0→0.5 | proposed |
| 2 | 2026-05-08 | Risk-pct clamp | proposed |
| 3 | 2026-05-08 | Deprecate simulated-orders strategy_id desk | (check status) |
| 4 | 2026-05-11 | Funnel-drain unprocessed proposals | proposed (impl off) |
| 5 | 2026-05-11 | Vol-expansion throttle review | proposed (NEW) |
| 6 | 2026-05-11 | Postmortem size-down feedback | proposed (NEW) |
| 7 | 2026-05-11 | Conviction-quartile sizing | proposed (NEW) |

**= 7 open proposals.** Karri varsles om batch-review pace i msg #3.

## Operator todo

- Push: `git push origin main` (commit d47ef7a)
- Ingen implementasjon kan starte før Karri-OK per proposal.

## Sanity-flags

- Ingen kode-endring foretatt i denne sesjonen (kun docs + Discord-sends).
- Bemerk: untracked changes i `apps/worker/src/index.ts`, `packages/shared/src/index.ts`, `packages/shared/src/constants.ts` lå allerede i tree FØR denne sesjonen — IKKE rørt eller staged.
- Alle 3 proposals følger 8-section binding embed structure + 30+ dag sample-size caveat per operator-prinsipp #6.
