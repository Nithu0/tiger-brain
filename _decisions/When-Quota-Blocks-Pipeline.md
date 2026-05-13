---
type: decision-tree
trigger: API quota / rate-limit causing >10% pipeline failure
autonomy_level: fix-locally + propose-paid-upgrade
---
# When Quota Blocks Pipeline

## Trigger
- >10% failure rate on an LLM / API pipeline
- Errors classify as 429/quota/limit

## Diagnose order
1. Confirm error class via stderr / API response headers
2. Check if free-tier daily/minute cap is hit
3. Calculate current monthly volume vs paid-tier breakeven
4. Check whether retries can self-heal (e.g., next-day quota reset)

## Action by classification
- **Free-tier daily cap, low volume:** propose paid upgrade. Operator pays per `feedback_operator_pays_premium.md`.
- **Free-tier daily cap, high volume:** paid upgrade + add caching to reduce calls.
- **Per-minute rate limit:** add backoff + small concurrency cap. No upgrade needed.
- **Hard limit even on paid:** retry queue + offline processing.

## Implementation pattern
1. Defensive code first (soft rate-limit gate, observable)
2. Documented upgrade-guide (operator-facing)
3. Cost-cap (set monthly budget alerts in provider dashboard)

## Examples
- **Gemini quota 2026-05-11 — full path concrete**: 77.8% of 18 failures were 429s on free-tier daily cap. Step 1 (defensive): commit `a301b8b` added soft rate-limit gate + Tier-1 upgrade guide (`docs/ops/gemini-tier1-upgrade.md`). Step 2 (operator pays): operator authorised via *"JEG KAN BETALE HVIS DET TRENGS SÅ BARE KJØR PÅ"* → billing flipped same session. Step 3 (verify): Tier-1 LIVE; `tier_verified: 2026-05-11` in [[gemini-pipeline-state]]. Total time-to-unblock: same session. **Template**: defensive code commit FIRST (so we don't regress when the limit returns), upgrade-guide doc, operator clicks pay, verify in living-state.

Linked to: [[Operator-Principles]], [[Operator-Pays-Premium]], [[gemini-pipeline-state]], [[Foundation-Gate]] (rule 4 yellow on quota-driven data gap), [[Truth-Hierarchy]] (provider dashboard truth above this doc), [[Runbook-Quota-Upgrade|Quota-Upgrade]], [[Karri]] (notify only if change has money-impact)
