---
tags: [nexus, module, prism, fact-agents]
type: atomic
created: 2026-05-08
---

# Module-Fact-And-Analysis-Agents

Owner: Prism. Pulls raw data from external sources, processes into typed analyses, publishes to [[Module-Blackboard]].

## What it does

**Fact agents** (`fact-agents.ts`) — pull raw data: price, indicators, OHLCV candles, news, sentiment, per-subreddit reddit, cross-asset (EUR/USD, TLT, SPY, USO, Silver). No interpretation.

**Analysis agents** (`analysis-agents.ts`) — turn raw data into typed analyses (regime classification, narrative pulse, market posture). Subscribes to fact-agent topics, publishes analysis topics.

**Conviction extension** (`conviction/`) — standardized engine interface, tiered scoring, regime weight maps, performance multipliers. Currently observation-only. FASE 6 (hard control) is deferred until ≥100 logged trades with `conviction_total`.

## Key files

- `apps/worker/src/firm/fact-agents.ts`
- `apps/worker/src/firm/analysis-agents.ts`
- `apps/worker/src/firm/conviction/`
- `apps/worker/src/firm/raw-data-persistence.ts` — append-only snapshots every cycle (training-ready tables)

## Operator-principle 2 binding

Data must never be stopped. Even during memory-layer cleanups (TTL, dedupe), fact agents + analysis agents + persistence tables keep writing. Cleanup decides which types are kept, never whether anything is written. See [[Operator-Principles]].

## Inputs / outputs

- **Reads**: external APIs (Twelve Data, OANDA, news feeds, reddit), env keys
- **Writes**: blackboard topics + `raw_data_persistence` tables

## Related

- [[Module-Orchestrator]] — calls fact then analysis steps every cycle
- [[Module-Blackboard]] — destination for typed analyses
- [[Strategy-ORB]] — consumes range / momentum / pre-move analyses
- [[Module-Postmortem]] — reads regime-at-entry from analysis snapshots
- [[Operator-Principles]] — prinsipp 2 binding
