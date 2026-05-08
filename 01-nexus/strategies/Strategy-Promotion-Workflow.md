---
tags: [nexus, strategy, promotion-workflow]
type: atomic
created: 2026-05-08
---

# Strategy-Promotion-Workflow

How a strategy graduates from idea → shadow → live. Stub-grade, the canonical path is encoded in [[Foundation-Gate]] and [[Strategy-Proposal-Workflow]].

## The canonical path

1. **Proposal** — Claude writes `docs/strategy/proposals/YYYY-MM-DD_<slug>.md` per the template. [[Karri]] reviews. Operator confirms approval. See [[Strategy-Proposal-Workflow]].
2. **Foundation gate** — all 5 rules in [[Foundation-Gate]] must be green. If any are red: STOP. No exceptions.
3. **Add as PAUSED bot** — never RUNNING on first deploy.
4. **Shadow mode** — minimum 14 days of observation. Behaviour is gated by env flag, default OFF.
5. **Acceptance criteria** — strategy must have defined: WR, PF, max DD targets surfaced in morning briefing as "shadow-kandidat".
6. **Live activation** — explicit operator OK kjør (see [[OK-Kjor-Gate]]) plus 2 weeks of data with the strategy in shadow.

## What is NOT covered by the gate

- Tuning thresholds on existing strategies (allowed but needs its own observation round + OK)
- Activating an existing gate (e.g. flipping `RISK_LEVEL_HARD_GATE_ENABLED`) — allowed when data supports
- **Disabling** a strategy — always allowed without gate-check (safety first)
- Bug fixes on existing strategies — allowed via diagnose-template

## Strategies and where they sit on this path

- [[Strategy-ORB]] — LIVE since 2026-04-25
- [[Strategy-Scalp-Overlap]] — TIER 3 deploy 2026-04-26, awaiting activation
- [[Strategy-Session-Breakout]] — TIER 3 deploy 2026-04-26, awaiting activation
- [[Strategy-Vol-Expansion]] — observe-only, 0 closed trades

## Related

- [[Foundation-Gate]] — the five rules
- [[Strategy-Proposal-Workflow]] — Karri-review path
- [[OK-Kjor-Gate]] — final activation gate
- [[Operator-Principles]] — prinsipp 4 (foundation-først) binds this workflow
- [[Nexus-MOC]]
