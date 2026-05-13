---
type: runbook
---
# Quota Upgrade — Operator Steps

1. Open provider dashboard (Google AI Studio / Anthropic Console / OpenAI Platform)
2. Navigate to billing / plan / tier
3. Enable billing on the project linked to the API key in use
4. Verify tier upgrade in dashboard (may take 5-10 min)
5. Wait 24h, query failure-rate post-upgrade to confirm
6. Set monthly budget cap in provider's billing alerts

## Per-provider links
- Gemini: https://aistudio.google.com/apikey
- Anthropic: https://console.anthropic.com/settings/billing
- OpenAI: https://platform.openai.com/account/billing

## Verification SQL (Gemini example)
```sql
SELECT status, COUNT(*) FROM agent_tasks WHERE role='research' AND created_at > NOW() - INTERVAL '24 hours' GROUP BY status;
```

Linked to: [[When-Quota-Blocks-Pipeline]], [[gemini-pipeline-state]], [[Operator-Principles]] (prinsipp 5: operator-only flip), [[Truth-Hierarchy]] (provider dashboard ranks above this doc when they disagree)
