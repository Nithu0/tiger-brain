---
title: Nexus platform status — navigation hub
type: status
created: 2026-05-21
tags: [nexus, platform, status]
---

# Nexus platform status — navigation hub

Single place to see what the trading platform actually shows, what is real vs
broken vs missing, and how Claude's learning loop works. Maintained by Claude;
operator can edit freely. Last updated: 2026-05-21.

> Honesty rule: this hub states the *verified* truth, not the *claimed* truth.
> If something says "code-complete, not verified" it means exactly that — nobody
> has confirmed it works for a real user yet.

## Dashboard graphs — what is actually up

Verified 2026-05-21 by hitting the deployed dashboard + live DB.

| Graph | Data exists? | Status | Note |
|---|---|---|---|
| Equity / drawdown / win-rate / trade distribution | Yes — 165 closed demo trades | Renders real data once auth works | Real book is **−$10,507** — that is the true number |
| Strategy comparison | Partial — 80/166 attributed | Renders, 52% missing strategy_id | attribution gap |
| Agent debate | Yes — 6/10 agents active | Renders real data | — |
| Live action feed | Yes — blackboard fresh to the minute | Code-complete 2026-05-21, NOT yet verified | new `/firm/activity-feed` + LiveActivityFeed.tsx |
| Prediction-vs-actual | Broken→fixed join; predictor degenerate | Code-complete, NOT verified | join fixed (0→5 pairs); predictor still emits `predicted_r=0` |
| Backtest equity curve | Runner built 2026-05-21, never run | Code-complete, NOT verified | operator must POST /backtest once |

### The root cause of "no graphs"

The dashboard fetched the API directly from the browser with a build-time
`NEXT_PUBLIC_API_KEY`. If that key was missing/stale on the Railway build,
**every** endpoint 401'd and the whole dashboard went blank. Fixed 2026-05-21:
all fetches now go through a server-side proxy (`/api/proxy`) — the key never
reaches the browser. **Operator action:** set plain `API_KEY` on the Railway
*dashboard* service (not `NEXT_PUBLIC_*`).

## Learning loop — how Claude carries knowledge

Built 2026-05-21 because fixes kept getting marked "done" without verification.

- **Ledger:** `docs/ops/learning-ledger.md` (in the repo) — every fix needing
  confirmation has a `VERIFY-BY` date; failed ones sit in REOPENED.
- **Session-start hook** surfaces overdue verifications + stale memory every
  session, so nothing is silently forgotten.
- **REOPENED right now:** `agent_lessons` (0 rows — Railway env), `risk_events`
  (NEWS_BLACKOUT dead path).

## What needs the operator

1. Railway *dashboard* service: set `API_KEY` (plain). Unblocks all graphs.
2. Railway *worker* service: `AGENT_LESSONS_ENABLED` / `LESSON_DERIVATION_ENABLED` / `DATABASE_URL`. Unblocks agent_lessons.
3. POST `/backtest` once to trigger the first real backtest run.
4. 3 stray `agent_lessons` rows (id 1-3) — keep or delete.
5. ~16 unreviewed Karri strategy proposals in `docs/strategy/proposals/`.

## Pointers (repo)

- `docs/ops/learning-ledger.md` — closed-loop verification tracker
- `docs/ops/known-failures.md` — failure-mode catalog (incl. agent_lessons + risk_events diagnoses)
- `docs/ops/phase-status.md` — sprint state, single source of truth
- `docs/memory/README.md` — memory lifecycle + closed-loop section
- Dashboard: https://dashboard-production-f342.up.railway.app — `/`, `/charts`, `/validation`
