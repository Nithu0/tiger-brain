# 00 — BLEED VERDICT (synthesis)

**Date:** 2026-06-15
**Author:** Claude (synthesis judge, READ/ANALYSIS ONLY — no flags flipped, no trades touched)
**Inputs:** `01_recent-bleed.md`, `03_edge-existence.md`, `04_gate-effectiveness.md` (sibling diagnoses, 2026-06-15) + `data/pull/performance.json` + prior `2026-06-13/{01_recon, 02_gate-loosening-verdict}` + `2026-06-14/verify-sweep`.
**Note:** `02_loss-anatomy.md` had not been written at synthesis time; this verdict stands on the other three + performance.json, which already converge hard. Revisit if 02 contradicts.

---

## THE BLUNT VERDICT

**The system is NOT bleeding the way the headline says, and the recent firm work is not why it looks bad. Two separate truths:**

1. **The cumulative −$11.2k is ~97% a single old artifact, not ongoing strategy bleed.**
   The April 21–22 blowup is −$10,841 (18 trades, PF 0.22). Strip it and the entire 130-trade firm-attributed book is **−$360 total (−$2.77/trade) — essentially flat.** The dashboard headline (−$11k, PF 0.69, exp −$53) is dominated by dead history + 79 `OANDA_BACKFILL` import rows (sized up to 106 lots, no strategy logic, −$10.8k). It is a measurement artifact contaminating every aggregate.

2. **The part that IS still bleeding NOW is NOT the firm's gated path — it's an ungated legacy/External path the safety rails never see.**
   Post-06-04 (post circuit-breaker + regime-gate + ATR fixes):
   - **Firm's own execution path (`XAUUSD Auto`, gated): +$458 net, and +$96 even in the "worst" Asian session.** The breaker / regime gates / ATR fix are HOLDING on the path they control.
   - **The bleed is `External (OANDA)` / `no_signal` rows: −$1,428 post-fix, −$2,580 over 21d.** Large size (47–158 units, vs firm-typical ~25–35), 1–4 minute holds, stopped out, mostly Asian session. **These have `bot_id IS NULL` / `signal_id NULL` — they never entered the firm decision/execution path, so the circuit breaker and gates never saw them.**

So: **the recent work worked on what it controls. The account keeps dropping because money is leaking through a door the firm doesn't guard.** That door — not the strategies, not the gates — is the live bleed.

Live state corroborates: balance −$1,157.57 (from $10k start), and the 18:00Z watch fired a dailyLoss alarm at 81.6% of the $500 limit, driven by a fresh −$312 External row opened 17:34Z today.

---

## WAS THE RECENT FIRM WORK ABOUT EDGE? (honest answer)

**No — and that's correct, not a failure.** The circuit-breaker, regime/ATR gates, learning loop, and book→AI modules were about **preventing repeat blowups + observability**. They are loss-*truncation* and *measurement* infrastructure. None of them creates *edge*. The operator's frustration ("still loses despite all the work") is the predictable result of expecting prevention-infra to produce profit. It can't, and was never going to.

The good news from `03`: stripped of the artifact, the firm path is roughly break-even with *coherent positive subsets* (vol-expansion shorts +$93/trade n=28; mean-reversion longs +$108/trade n=15). So the underlying strategies are **not structurally negative** — they're flat-with-promising-pockets at low n, where every CI still straddles zero. This is a "pre-edge demo, learning phase" situation, not a "scrap and rewrite" situation.

---

## INFRA (ai-1 / Claude) vs STRATEGY/RISK (Karri)

| Finding | Class | Owner | Why |
|---|---|---|---|
| **Ungated External/legacy "XAUUSD Auto" path leaking −$2.5k** | INFRA | ai-1 / operator | Routing/plumbing bug or orphaned-execution issue. Closing/routing a bypass path is not a strategy change. THE bleed. |
| OANDA_BACKFILL artifact contaminating headline PnL/dashboards | INFRA | ai-1 | Pure observability/data-hygiene. Exclude from aggregates. No behavior change. |
| Session/regime metadata NULL on 60–90% of rows → slices unusable | INFRA | ai-1 | Backfill `session_at_entry`/`regime_at_entry`. Data hygiene. |
| `mean_revert` gate rejecting net WINNERS (+77R blocked, 49 tp vs 7 sl) | STRATEGY/RISK | **Karri** | Re-calibrating a gate that alters trade decisions. Trade-altering → gated. |
| `risk_level` "high" tier clipping winning breakouts (+31R blocked, 20 tp vs 6 sl) | STRATEGY/RISK | **Karri** | Same — gate logic change. |
| Cut/tighten xau-orb (0% WR, −$1,300) + review xau-fvg (−$2,208, Karri WIP) | STRATEGY/RISK | **Karri** | Strategy enable/disable = money-impact. |
| Directional bias (vol-expansion→shorts, mean-reversion→longs) | STRATEGY/RISK | **Karri** | Directional gate = trade-altering. |

**Critical nuance: the gate-recalibration (Karri's items) does NOT fix the bleed.** Per `04`, the gates are HARMFUL on the firm path (blocking winners) but **IRRELEVANT to the loss** — the loss bypasses them entirely. Fixing the gates would improve the *already-positive* firm path; it would do nothing about the −$2.5k leak. Don't let the (real, interesting) inverted-gate finding distract from the actual hole.

---

## THE SINGLE HIGHEST-LEVERAGE ACTION

**Find and close the ungated External / `no_signal` / "XAUUSD Auto" execution path. This is INFRA, ai-1/operator, and it is where 100% of the live net loss lives.**

The data behind it:
- 21d: gated firm path = **+$2,147** (5 trades, caps held, max 79u). Ungated path = **−$2,580** (34 trades, max 158u, breaker never saw them).
- Post-06-04: firm path **+$458** vs External **−$1,428**.
- The leaking rows: `bot_id IS NULL` / `signal_id NULL`, sizes 47–158 (well above firm-typical), 1–4 min holds, stopped out, Asian-heavy. Worst cell: **External × Asian = −$943 over 5 trades.**

Concretely, ai-1 should:
1. `SELECT * FROM simulated_orders WHERE bot_id IS NULL AND opened_at >= '2026-06-01'` — match each against firm signals/cycle ids.
2. Decide which case it is: **(a)** firm orders losing their `bot_id` in `oanda-sync` (a tagging/plumbing bug — the breaker *did* size them, we just can't attribute), or **(b)** genuinely external orders something else is opening on the OANDA account (a rogue/legacy executor — far worse, unmanaged).
3. If (b): check `LEGACY_XAUUSD_EXECUTION_ENABLED` / the "XAUUSD Auto" bot and route it through the firm gate stack or disable it (operator-gated).
4. Cross-check the still-open **−$544.67 (and growing) recon delta** from `2026-06-13/01_recon` handoff #2 against OANDA `/openTrades` — the orphan-position hypothesis and this leak may be the same root cause.

Until this is identified, **the account keeps bleeding regardless of how well the firm gates behave.** Nothing else on the list matters as much.

---

## THE KARRI HANDOFF (strategy/risk, with numbers)

Route via `docs/strategy/proposals/`. These are real edge-improvements on the firm path, but **secondary** to the leak above. Two gates are inverted for the current TRENDING-UP regime (gold ~$4,200, ADX 32.9, vol normal):

1. **`mean_revert` gate — recalibrate or regime-gate it. (highest gate-priority)**
   - It is mis-named: it's a *continuation-blocker* (blocks signals aligned with a ≥2-ATR/90min impulse on a "reversion ahead" thesis).
   - In the current trending regime that cohort (session-breakout aligned with impulse) shadow-tracked **102 tp / 16 sl / 54 expired ≈ 86% win** over 21d; 14d cross-ref: **49 winners vs 7 losers rejected, +77R of would-be edge blocked.** The impulse *continued*, it didn't revert. The premise is backwards for trend.
   - Proposal: gate it on regime — only block counter-trend in RANGING; do not block continuation in TRENDING. **Caution from `2026-06-13/02_gate-loosening-verdict`:** this is the 04-21-blowup gate. Its aggregate edge CI straddles break-even and the "+R" is concentrated on session-breakout (a continuation strat where it mis-fires), NOT on the mean-reversion strat where blocking was *correctly* saving losses. So **regime-conditional, not global loosening** — and shadow-A/B first, since shadow ignores the exact spread/slippage these gates exist for.

2. **`risk_level` "high" tier — re-examine post-ATR-fix.**
   - "high" is firing on normal-vol trend conditions (gold $4,200) and clipping winning breakouts: **20 tp / 6 sl rejected, +31R blocked**, dominated by session-breakout 18tp/0sl.
   - Per `2026-06-13/02` this one's shadow CI floor (63% WR) is well above break-even and is the cleaner, smaller-blast-radius A/B. **Do this one FIRST and alone**, shadow-arm (already running, zero live change), decide in 2–3 weeks at n~35.

3. **Strategy cull / directional bias (lower urgency, low n — flag don't rush):**
   - Cut/hard-gate **xau-orb**: n=5, 0% WR, −$1,300, PF 0.00 (shadow agrees, fired −0.80R).
   - Review **xau-fvg**: −$2,208, PF 0.43, worst real-strategy bleeder — but **Karri WIP per memory, do NOT unilaterally cut.**
   - Directional asymmetry is real in the live book: **vol-expansion SHORT +$2,600/28 (vs LONG −$323/16); mean-reversion LONG +$1,621/15 (vs SHORT −$352/1).** Candidate for a directional gate — but all CIs straddle zero, so this is "lean, don't bet capital."

**Sequencing for Karri:** `risk_level` shadow-A/B first (cleanest) → then regime-condition `mean_revert` → strategy cull last. Never two gate changes at once (attribution loss if daily-cap/breaker fires). And **none of this is a substitute for closing the External-path leak** — that's ai-1's job and it comes first.

---

## ONE-LINE SUMMARY FOR THE OPERATOR

The −$11k is 97% the dead April blowup; the firm's *gated* path is net-positive since the fixes (+$458). The account is still dropping because large, fast, ungated "External OANDA" trades (−$2.5k) bypass the breaker entirely — **that leak is the #1 fix, it's infra (ai-1), and recalibrating gates won't touch it.** The strategies aren't structurally broken — they're flat-with-promising-subsets at low n; the recent work was blowup-prevention, not edge-creation, so "it still loses" is expected, not a regression.
