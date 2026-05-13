# Thesis-quality wire-through verification — 2026-05-11

**Commit verified at deploy**: `a2f1cbc8` (matches commit `a2f1cbc` in round-12 push)
**Verification window**: 2026-05-11T14:12Z to 2026-05-11T14:19Z (post-redeploy)
**Verdict**: **PARTIALLY VERIFIED — regime_at_entry wired, thesis/conviction wired but starved (synthesis topic dormant)**

## Findings

### Build state
- `/health.build.commit` = `a2f1cbc8` confirmed live on Railway.
- HEAD locally is `6bdd38a` (2 commits ahead: 6bdd38a postmortem-classifier, d81af0e macro-event Discord). Not relevant to this verification.

### Trades since deploy
Two new firm_strategy trades after 13:33Z baseline:

| opened_at | id | strategy | thesis_quality | conviction_total | regime_at_entry | risk_level (entry_conviction) |
|---|---|---|---|---|---|---|
| 14:00:30Z | ef9b3382 | xau-volatility-expansion | NULL | NULL | NULL | 0.8 |
| 14:12:41Z | 2320fd49 | xau-volatility-expansion | NULL | NULL | **high** | 0.8 |

### 24h aggregate
```
total           = 9
with_thesis     = 0
with_conviction = 0
with_regime     = 1   ← only the 14:12 trade
```

### Why thesis/conviction still NULL
The wire-through code at `apps/worker/src/firm/strategy-execution.ts:493` reads `xauusd.manager.synthesis` with 600s freshness window. **That topic does not exist in blackboard history** (checked last 30 min + full table scan for synthesis-like topics — only `xauusd.manager.decisions` and `xauusd.manager.execution` present).

The synthesis producer (`managers.ts:257` → `prismSynthesis`) is bypassed when `ORB_ONLY_MODE=true` (orchestrator.ts:459-463). TIER 3 strategy execution (firm_strategy source) runs in parallel to the Prism→Blade decision path and doesn't drive synthesis publication. Result: the side-channel observability write has no data source to read from.

### Why regime_at_entry IS populated on 14:12 (but not 14:00)
`regimeAtEntry` is COALESCEd from `riskLevelAtEntry` which is read from `xauusd.analysis.risk` topic at line 471. Both trades are post-deploy with the new code path, but the 14:00 trade's risk message was stale (>300s freshness) or missing; the 14:12 trade caught a fresh `analysis.risk` and stamped `high`. Behavior matches code (NULL when stale, per operator-prinsipp 1).

## Verdict

- **regime_at_entry wire-through**: VERIFIED. Field populates when source topic is fresh.
- **thesis_quality_score + conviction_total wire-through**: CODE CORRECT, DATA STARVED. The wire-through is functioning as designed (NULL when synthesis topic absent), but the synthesis topic is dormant — likely because `ORB_ONLY_MODE=true` is bypassing Prism. Not a regression.

## Recommendation for operator

Two paths to populate thesis_quality + conviction_total:

1. **If Prism should publish during ORB_ONLY**: file a strategy proposal to invoke `prismSynthesis` even in ORB_ONLY_MODE as observability-only (no decision impact). Karri review.
2. **If ORB_ONLY_MODE is no longer needed**: flip `ORB_ONLY_MODE=false` on Railway — TIER 3 strategies will still execute (separate path), but Prism will publish synthesis so wire-through populates.

No code change required to commit a2f1cbc — it works exactly as specified. The gap is data-source availability, not the wire-through.

## Reference

- Code: `apps/worker/src/firm/strategy-execution.ts:485-510`
- Producer: `apps/worker/src/firm/managers.ts:257` (gated by ORB_ONLY_MODE at orchestrator.ts:459)
- Pre-commit baseline trades (still NULL, expected): 13:14, 13:20, 13:33Z — confirmed unchanged.
