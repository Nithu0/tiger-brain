# Nexus — "still bleeding?" recent-window decomposition

**Date:** 2026-06-15
**Question:** Is the system still bleeding NOW (post circuit-breaker + regime-gate + ATR fixes that landed ~06-04→06-13), or is the bad cumulative number dragged by the old April blowup?
**Data:** live `/analytics/performance` (windowed `from`/`to`) + `/analytics/export` CSV, pulled fresh 2026-06-15 20:03. 209 closed trades, range 2026-04-16 → 2026-06-15. Account balance now **−$1,157.57** (started $10,000).

---

## Window decomposition

| Window | N | WR% | PF | Expectancy | PnL |
|---|---:|---:|---:|---:|---:|
| ALL-time | 209 | 36.8 | 0.69 | −53.39 | −11,157.57 |
| BLOWUP only (4/21–4/22) | 18 | 22.2 | 0.22 | −602.30 | −10,841.42 |
| EX-blowup (from 4/23) | 130 | 37.7 | 0.98 | −2.77 | −360.27 |
| **POST-06-04 (post-fix)** | **18** | **27.8** | **0.56** | **−53.92** | **−970.48** |
| LAST-14d (from 6/01) | 28 | 35.7 | 0.97 | −5.34 | −149.54 |
| LAST-7d (from 6/08) | 10 | 20.0 | 0.26 | −117.79 | −1,177.94 |

Cumulative −$11k is ~97% the April 21–22 blowup (−$10,841). Ex-blowup the book is essentially flat. So the headline number is NOT representative of current behaviour. **But the recent windows are negative**, so the answer isn't a clean "no."

---

## Pre-fix vs post-fix trajectory (both ex-blowup)

| Window | N | WR% | PF | Expectancy | PnL |
|---|---:|---:|---:|---:|---:|
| PRE-fix ex-blowup (→6/04) | 173 | 39.3 | 1.03 | +3.78 | +654.33 |
| POST-fix (6/04→) | 18 | 27.8 | 0.56 | −53.92 | −970.48 |

On its face: the fixes did NOT improve the trajectory — pre-fix was marginally profitable (PF 1.03), post-fix flipped to PF 0.56. **However** — see attribution below; this flip is not the firm's execution path.

---

## Where the recent bleed is — by session (POST-06-04)

| Session | N | WR% | PnL |
|---|---:|---:|---:|
| Asian | 12 | 33.3 | −847.25 |
| New York | 1 | 0 | −312.33 |
| London-NY Overlap | 1 | 0 | −172.88 |
| London | 4 | 25 | +361.98 |

Bleed is concentrated in the **Asian session**.

## Decisive attribution — by bot (POST-06-04)

| Bot | N | PnL |
|---|---:|---:|
| **External (OANDA)** | 7 | **−1,428.47** |
| XAUUSD Auto (firm path) | 11 | **+457.99** |

Asian × bot (post-06-04):
- Asian × External (OANDA): n=5, **−943.26**
- Asian × XAUUSD Auto (firm): n=7, **+96.01**

**The firm's own execution path (`XAUUSD Auto`) is POSITIVE post-fix (+$458), including positive in the Asian session (+$96).** The entire post-fix bleed is `External (OANDA)` trades — rows with `bot_id IS NULL` that `oanda-sync` backfilled from the OANDA account, i.e. positions the firm did NOT book through its decision/execution path and therefore the circuit breaker / regime gates never saw.

Strategy-level decomposition is not possible at finer grain: 191 of 209 trades are lumped as `auto-managed` (firm path doesn't tag per-strategy bot id on the `bots` join), and the bleeding rows have no bot at all.

---

## The External (OANDA) rows — signature

All 11 ever; the recent ones share a striking profile (held 1–4 min, large size, all losing):

| opened | held | dir | size | pnl |
|---|---|---|---:|---:|
| 2026-06-01 00:13 | ~2 min | short | 158 | −456.34 |
| 2026-06-05 02:31 | ~4 min | long | 47 | −129.97 |
| 2026-06-09 14:16 | ~1 min | long | 51 | −172.88 |
| 2026-06-11 01:02 | <1 min | short | 65 | −174.04 |
| 2026-06-11 02:03 | ~1 min | short | 65 | −309.69 |
| 2026-06-12 00:52 | <1 min | short | 63 | −109.99 |
| 2026-06-12 01:53 | ~2 min | long | 63 | −219.57 |
| 2026-06-15 17:34 | ~2 min | long | 61 | −312.33 |

These are large-size positions stopped out within minutes, mostly Asian session, all negative. **This is the live bleed.** They are unattributed to the firm path. Either (a) the firm is opening them but they're being orphaned (`bot_id` lost) before sync, or (b) something else is opening positions on the OANDA account. Needs operator/code investigation — this is the single most important follow-up.

Note also the size escalation: avg position size went 1 → 50 (W17 blowup) → settled ~25–35 → climbing again to ~46–61 in W23–25. The bleeding external rows are at the top of that range.

---

## VERDICT

**Is it still bleeding post-fix? YES — but not where you'd think.**

- The firm's own gated execution path (`XAUUSD Auto`) is **net positive post-06-04 (+$458, and +$96 in the Asian session that's nominally the worst)**. The circuit breaker / regime gates / ATR fixes appear to be holding on the path they control.
- The recent loss (−$970 post-06-04, −$1,178 last-7d) is **almost entirely `External (OANDA)` backfilled trades (−$1,428)** — large-size (47–158), 1–4 minute holds, mostly Asian session, that the firm did not book through its decision path and the breaker never saw.
- **Rate of bleed (the part to worry about):** the External rows are running ~−$200 to −$300 per losing trade, ~1–2 per active day in June. Last-7d total −$1,178.
- **Single worst strategy × session in the recent window:** **External-(OANDA) × Asian session, −$943 over 5 trades.** (Within the firm's own path, no session is materially bleeding post-fix.)

**Action for operator:** the fixes worked on the firm path. The open question is what is opening these orphaned large-size 1-minute Asian-session OANDA positions. Until that's identified, the account keeps bleeding regardless of how well the firm gates behave. Recommend: (1) pull `simulated_orders WHERE bot_id IS NULL AND opened_at >= '2026-06-01'` and check for matching firm signals/cycle ids; (2) check whether these are firm orders losing their bot_id in oanda-sync, vs genuinely external; (3) review the size-ladder — sizes 61–158 on these rows are well above the firm's typical.
