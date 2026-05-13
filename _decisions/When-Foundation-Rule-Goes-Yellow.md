---
type: decision-tree
trigger: one of the 5 foundation-gate rules in docs/ops/new-strategy-gate.md flips from green to yellow or red
autonomy_level: report
---
# When Foundation Rule Goes Yellow

## Trigger
A daily check or audit flips one of the five rules in `docs/ops/new-strategy-gate.md` from green to yellow/red. Foundation-first is operator-prinsipp 4: **no new strategy work until all 5 green**. So a yellow rule is a hard block on strategy delivery, but not necessarily on bug fixes / observability.

The 5 rules (canonical names in [[Foundation-Gate]]):
1. Metadata stamping coverage
2. Reconciliation drift ≤ threshold
3. Position-management observability
4. Gate-decisions data maturity
5. Postmortem write rate

## Diagnose order
1. **Confirm which rule + how yellow**: pull the rule's specific check. Each rule has a SQL/endpoint check defined in `new-strategy-gate.md`. Yellow = degraded, red = broken.
2. **Time-window**: is this a flap (1 sample crossing threshold) or sustained (≥3 samples or ≥1 hour)? Flaps usually self-resolve.
3. **Identify owner**: rules 1-3 are typically Claude-fixable (observability + plumbing). Rules 4-5 may need Karri input (strategy / classification logic).
4. **Reversibility check**: is the fix reversible (code change, can revert in 30s) or irreversible (data migration, threshold change, agent activation)?

## Action by classification
- **Reversible code fix** (rules 1-3, e.g. metadata stamp missing on new code path) → fix locally + commit + push. Report green-flip after deploy verified. [[Runbook-Post-Deploy-Verification]].
- **Reversible env-var flip** (e.g. flag for an observability surface needs turning on) → operator-only on Railway. Report the proposed flag + flip with `docs/ref/env-vars.md` reference.
- **Threshold change** (e.g. "let's loosen rule 2 reconciliation threshold from $50 to $100") → STRATEGY-TOUCH. File proposal, Karri. [[When-Strategy-Change-Tempting]].
- **Rule 4 specifically** (gate-decisions data maturity): historically this was red for 14 days due to [[gate-silence-2026-05-08]]. If yellow because of data-volume → wait for it to mature. If yellow because of fresh silence → see [[When-Gate-Goes-Silent]].
- **Rule 5 specifically** (postmortem write rate): if Atlas is stalling → [[When-Agent-Stalls]].
- **Irreversible** (data deletion, table truncation to fix) → "OK kjør"-gate REQUIRED.

## What never auto-fires
- Loosening the gate to flip it back green ([[Operator-Principles]] rule 1, 4). Green by-cheating is worse than yellow honest.
- Auto-activation of dormant strategies even if all rules go green ([[Decision-No-Auto-Activation]]).

## Examples from past sessions
- **Rule 4 RED for 14 days** (gate-silence): root cause was env-var visibility, not gate logic. Code-side fix shipped same-day-as-diagnosis.
- **Rule 1 metadata stamping** (2026-05-11): all 28 trades had NULL `strategy_id`. Code fix in commit f551c17 stopped silent-skip of strategies. Rule flipped green after deploy + 24h of fresh trades.
- **Rule 2 YELLOW → GREEN same-day** (2026-05-11): metadata-strip fix `0ad348f` deployed in the morning; rule 2 had been yellow because `simulated_orders` INSERT was dropping `strategy_id` / `execution_source` / `atr_at_entry` / `entry_conviction_score` / `portfolio_regime_at_entry`. By 13:33Z three post-deploy trades (`205dd6ad`, `02d3d403`, `f64feec4`) came in fully stamped → rule 2 verified green → **foundation-gate 5/5 first time**. Pattern: code-side fix + wait for first real trade post-deploy. See [[scalp-overlap-losses-2026-05-11]] for the three trades themselves.

## Linked
[[Operator-Principles]] · [[Foundation-Gate]] · [[Truth-Hierarchy]] · [[Karri]] · [[When-Strategy-Change-Tempting]] · [[When-Gate-Goes-Silent]] · [[When-Agent-Stalls]] · [[Runbook-Post-Deploy-Verification]]
