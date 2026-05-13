---
type: runbook
trigger: a strategy-touch proposal is filed and ready to send Karri
autonomy_level: send-to-karri (during work hours only)
---
# Runbook: Karri-Proposal-Send

How to ship a strategy/risk proposal to [[Karri]] via Discord webhook. Combines [[When-Strategy-Change-Tempting]] + [[Decision-Strategy-Review-Pipeline]] + `feedback_auto_send_karri.md`.

## Preconditions
1. Proposal file exists at `/home/nithu/code/ai-assistent/docs/strategy/proposals/YYYY-MM-DD_<slug>.md`.
2. Uses template from `docs/strategy/proposals/README.md`.
3. `Reviewer: Karri` set in frontmatter.
4. `Status: proposed`.
5. Money-impact estimate present (rough +/- $/week).
6. Rollback plan present (env-var, revertable in 30s).
7. Current time is **09:00 – 17:00 CET** on a weekday. Outside this window: hold, do NOT page.

If any precondition fails → fix proposal first OR wait for the work-hour window.

## Send sequence
1. **Stage the message**. Format:
   ```
   New strategy proposal: <title>
   Path: docs/strategy/proposals/YYYY-MM-DD_<slug>.md
   Money-impact: <+/- $/week estimate>
   Rollback: <env-var name + flip-to-old>
   Summary: <1-2 sentences of WHAT changes and WHY>
   Linked context: <PR / commit / inbox-note URL if any>
   ```
   Keep under 1500 chars to fit Discord embed clean.

2. **Webhook URL**: read from memory `reference_strategy_reviewer.md`. NEVER paste the URL into vault, transcript, or commit.

3. **Send via curl**:
   ```bash
   curl -X POST -H "Content-Type: application/json" \
     -d '{"content": "<message>"}' \
     "$KARRI_WEBHOOK_URL"
   ```
   Capture HTTP status. Expected: `204 No Content`.

4. **Verify HTTP 204**: anything else → DO NOT mark as sent. Re-check URL / payload / rate-limit. If 429: backoff 60s + retry once. If 4xx: surface error to operator, do not retry blindly.

5. **Update proposal frontmatter**:
   - `sent_to_reviewer: 2026-05-11T<hh:mm>+02:00`
   - `sent_via: discord-webhook`
   - Append a note to the proposal body: "Sent to Karri YYYY-MM-DD via Discord webhook (HTTP 204)."

6. **Log the send**: commit the proposal update with message `docs(strategy): send <slug> to Karri for review`. This becomes the audit trail.

## After send — what happens next
- Karri may reply in Discord. Operator forwards approval to Claude.
- On approval: implement, update proposal `Status: implemented (commit: <SHA>)`, archive to `docs/strategy/proposals/archived/`.
- On reject or revise: hold implementation, file revised proposal as new dated file linking back to original.

## What never auto-fires
- Sending outside the 09-17 CET window (operator explicitly said: hold until next morning).
- Sending without a money-impact estimate.
- Implementing the proposed change before approval (unless operator inline-overrode with "bare fix det").
- Pasting webhook URL or proposal content into other channels.

## Examples from past sessions
- Operator authorised auto-send 2026-05-11 (`feedback_auto_send_karri.md`). Before that date, every proposal required explicit operator handoff.

## Linked
[[Karri]] · [[Decision-Strategy-Review-Pipeline]] · [[When-Strategy-Change-Tempting]] · [[Strategy-Proposal-Workflow]] · [[Operator-Principles]]
