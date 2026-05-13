---
date: 2026-05-13
type: discord-draft
target: karri
status: ready-to-send
---

# Karri-pings: 08.mai-cluster (5 dager ventet)

To proposals fra 08.5 trenger din review. Operator kopierer hver blokk inn i Discord under.

---

## Ping 1 — BE trigger 1.0R -> 0.5R

```
**Forslag: Senke BREAK_EVEN_TRIGGER_R fra 1.0 -> 0.5**
TL;DR: Stale-exit dreper vinnerne. 14 stale-exits siste 22 dager, 8 var vinnere med snitt +$104. De satt på 0.15-0.3R da stale-exit fyrte, nådde aldri 1R-triggeren som ville aktivert exempt-logikken.
Evidens: $833 realisert tap-til-vinner, annualisert ~$3.3-6.6k/år. Verste case: ticket 61830f24 stengt +$160 ved 90.4 min, 0.01 ATR fra trygg sone.
Risk: best = mer rom for vinnere å nå TP. Worst = whipsaw/lav-vol kan BE'e ut for tidlig på små bevegelser, men tapet er null (kun opportunity-cost).
Rollback: env-flag, ingen code-revert. Sample = 14 trades / 22d (under 30d-prinsippet — derfor spør jeg deg eksplisitt).
Verifiserer du dette? Eller foreslår du 0.6/0.7R som mellom-steg?
https://github.com/Nithu0/ai-assistent/blob/main/docs/strategy/proposals/2026-05-08_break_even_trigger_lower.md
```

---

## Ping 2 — Deprecate simulated_orders.desk

```
**Forslag: Deprecate `simulated_orders.desk`-kolonnen (revidert 11.5)**
TL;DR: `desk`-kolonnen har 0 av 150 rader populert noen gang. `strategy_id`-halvdelen av forslaget er kansellert (44% populert etter 0ad348f-fix + backfill). Kun `desk` gjenstår.
Evidens: ingen INSERT-path skriver `desk`. Konseptet er heller ikke definert noe sted — er det regime-basert gruppering, operator-vs-firm, noe annet?
Risk: Phase 1 = bare doc-merking, ingen DDL. Phase 2 = ALTER TABLE DROP COLUMN, separat migrasjon senere. Backwards-compat OK begge faser.
Worst case: hvis vi senere trenger desk-attribuering, må vi re-introdusere kolonnen (trivielt).
Verifiserer du dette? Spesielt: har du en plan for hva `desk` skulle vært, eller er drop trygt?
https://github.com/Nithu0/ai-assistent/blob/main/docs/strategy/proposals/2026-05-08_deprecate_simulated_orders_strategy_id_desk.md
```
