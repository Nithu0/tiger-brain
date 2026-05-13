---
type: tool
status: live
created: 2026-05-11
---
# Gemini

Google Gemini API (gemini-2.5-flash) used by Cipher department for research-synthesis. Tier-1 paid as of 2026-05-11 — failure rate 53% → 0%.

## Used by
- market-research agent
- narrative agent
- macro-event agent
- research-drainer task processor

## Env vars
- `GEMINI_API_KEY` (or `GOOGLE_API_KEY` fallback)
- `GEMINI_DEFAULT_MODEL=gemini-2.5-flash`
- `GEMINI_QUOTA_PAUSE_THRESHOLD=3` (soft rate-limit gate, default off)

## Cost
$0.075/1M input, $0.30/1M output (paid Tier-1). Free tier was daily-cap-hitting.

## Failure mode
Soft rate-limit gate in research-drainer (commit a301b8b) emits `xauusd.research.quota_paused` on 3+ consecutive 429s — REPORT-only, never auto-disable per [[Operator-Principles]].

Linked to: [[Tools-MOC]], [[gemini-pipeline-state]], [[When-Quota-Blocks-Pipeline]], [[Operator-Pays-Premium]]
