---
type: recon
project: nexus
created: 2026-05-13
round: 6
owner: "Claude (Opus 4.7 1M)"
status: silent-as-expected
---

# T+2h re-check — Karri reply + ENTRY_STACK_COOLDOWN + A2 histogram

## TL;DR

**T+2h status: silent — gate dormant, no trades, A2 still single-bucket.** Nothing has fired since the round-5 baseline. This is the expected read on a quiet RANGING day, not a regression.

## Window

- **Send-time:** 2026-05-13 07:36Z (~09:36 CET) — 4 proposals to Karri.
- **Cooldown flip:** 2026-05-13 08:07Z (~10:07 CET) — `ENTRY_STACK_COOLDOWN_ENABLED=true`.
- **DB-now (this check):** 2026-05-13 09:28Z. Send +1h52m. Flip +1h21m.
- **Last blackboard write:** 09:27:38Z — worker fully live, 30s silent (in-cycle).

## 1. Karri reply

**No reply detected.** Same 5 signal-paths as round 5 scanned:

- `~/Obsidian/Brain/00-firm-bus/inbox/*` — all 10 files still 0 bytes (no operator paste).
- `~/Obsidian/Brain/00-firm-bus/feed.md` — no entries past `07:43:41Z` boot.
- `git log --since="2026-05-13 09:36"` — only `f0a25c0` (zellij) and `5c07156` (phase-status). No `approved-verbally` / Karri commits.
- `docs/strategy/proposals/2026-05-13_*.md` — the 4 round-5 files were modified ~11:22–11:26 CET, but Status changes are **Claude-authored Round-5 addenda** (needs-scope-down / needs-pivot / needs-precursor-sanity-check / data-paper-not-proposal), not Karri replies. `postmortem_risk_feedback` Status header still reads `proposed` with an addendum below.
- No new files in `00-claude-inbox/nexus/2026-05-13/round5/` or `01-nexus/` since round-5.

Inside historical 24–72h SLA. Next check: 14.5 morning per handoff.

## 2. ENTRY_STACK_COOLDOWN — gate firings

```sql
SELECT count(*), max(recorded_at) FROM gate_decisions
WHERE gate_name='entry_stack_cooldown' AND recorded_at > '2026-05-13T08:07:00Z';
-- firings=0, last_seen=null
```

**Caveat (more important than the zero):** `gate_decisions` table last row is **2026-05-12T17:35:53Z**. Zero rows have been written on 13.5 at all — not just zero `entry_stack_cooldown`. Either:
(a) the gate-persist pipeline broke after 12.5 EOD,
(b) `GATE_PERSIST_ENABLED` isn't on in production despite round-3 instrumentation, or
(c) no signal has reached the gate-stack on 13.5 (consistent with 970 `signal.rejected` events upstream).

Worth flagging to operator separately — round-3 observability may be inert. Not blocking, but the cooldown can't be empirically verified until at least one trade tries to stack.

## 3. Trade activity

```sql
SELECT count(*), max(opened_at) FROM simulated_orders
WHERE opened_at > now() - interval '4 hours';
-- new_trades=0, last_open=null
```

Zero new opens in the last 4h. Consistent with: 100% RANGING regime since A2 deploy, 970 rejections in the same 4h window, S4 mean-reversion's counter-trend bias also held back by RANGING-only context.

## 4. A2 reason histogram (post-A2 → now, ~95 min)

| reason | regime | direction | n | last |
|---|---|---|---:|---|
| `not_trending` | RANGING | null | 86 | 09:27:38Z |

**Still 100% single-bucket.** Up from 78/78 in round 5 to 86/86 now — only 8 new portfolio.context rows in ~10 min of additional data, and zero TRENDING regime fired in the gap. None of the 9 instrumented paths (`flat_close_move`, `candles_empty`, `fetch_error`, `non_finite_close`, `candles_too_short_*`, etc.) have been exercised. The C1 thesis remains untestable from live data; the bug-fix-already-landed conclusion stands.

## Recommendation

- Hold all 4 proposals as-is. SLA-window still open.
- Surface the `gate_decisions` 12.5-EOD write-stop to operator — separate from Karri's review path, but blocks our ability to confirm ENTRY_STACK_COOLDOWN behavior empirically.
- Next re-poll: 14.5 morning checklist.
